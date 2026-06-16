import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player.dart';
import 'platform.dart';
import 'coin.dart';
import 'enemy.dart';
import 'potion.dart';
import 'chest.dart';
import 'goal.dart';
import 'decoration.dart';

class EndlessRunnerGame extends FlameGame with HasCollisionDetection, TapCallbacks, KeyboardEvents {
  late Player player;
  late TextComponent scoreText;
  late TextComponent coinText;
  late TextComponent livesText;
  late TextComponent timeText;

  int lives = 3;
  int score = 0;
  int coinCount = 0;
  bool isGameOver = false;
  bool isStarted = false;
  double elapsedTime = 0.0;
  double _maxPlayerX = 0;

  int selectedMap = 1;

  double horizontalInput = 0;
  final math.Random _random = math.Random();

  ParallaxComponent? parallaxBackground;
  double _lastGeneratedX = 0;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    await _setupBackground();

    player = Player();
    world.add(player);
    camera.follow(player);

    _setupUI();

    overlays.add('main_menu');
  }

  Future<void> _setupBackground() async {
    // Each map uses its own single opaque image — stacking them hides all but the top one.
    final imageFile = switch (selectedMap) {
      2 => 'bg_layer_2.png',
      3 => 'bg_layer_3.png',
      _ => 'bg_layer_1.png',
    };

    try {
      parallaxBackground = await loadParallaxComponent(
        [ParallaxImageData(imageFile)],
        baseVelocity: Vector2(20, 0),
        velocityMultiplierDelta: Vector2(1.0, 0),
      );
      if (parallaxBackground != null) {
        parallaxBackground!.priority = -10;
        world.add(parallaxBackground!);
      }
    } catch (e) {
      debugPrint("Parallax background load failed: $e");
    }
  }

  void _setupUI() {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
      shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
    );
    final textPaint = TextPaint(style: textStyle);

    livesText = TextComponent(
      text: '❤️❤️❤️',
      position: Vector2(20, 20),
      textRenderer: textPaint,
    );
    camera.viewport.add(livesText);

    final coinIcon = CircleComponent(
      radius: 10,
      position: Vector2(35, 60),
      paint: Paint()..color = Colors.yellow,
      anchor: Anchor.center,
    );
    camera.viewport.add(coinIcon);

    coinText = TextComponent(
      text: '0',
      position: Vector2(60, 50),
      textRenderer: textPaint,
    );
    camera.viewport.add(coinText);

    timeText = TextComponent(
      text: 'TIME: 0s',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: textPaint,
    );
    camera.viewport.add(timeText);

    scoreText = TextComponent(
      text: 'SCORE: 0000',
      position: Vector2(size.x - 20, 20),
      anchor: Anchor.topRight,
      textRenderer: textPaint,
    );
    camera.viewport.add(scoreText);
  }

  Future<void> selectMap(int mapIndex) async {
    selectedMap = mapIndex;
    await startGame();
  }

  Future<void> startGame() async {
    overlays.remove('main_menu');
    overlays.remove('map_select');
    overlays.remove('game_over');

    lives = 3;
    score = 0;
    coinCount = 0;
    elapsedTime = 0;
    isGameOver = false;
    horizontalInput = 0;

    parallaxBackground?.removeFromParent();
    parallaxBackground = null;
    // Yield one event-loop turn so Flame's lifecycle can remove the old component
    // before the new one is added in _setupBackground().
    await Future.delayed(Duration.zero);
    await _setupBackground();

    isStarted = true;
    _startLevel();
  }

  void resetToMenu() {
    overlays.remove('game_over');
    overlays.add('main_menu');

    isGameOver = false;
    isStarted = false;
    horizontalInput = 0;

    lives = 3;
    score = 0;
    coinCount = 0;
    elapsedTime = 0;
    _maxPlayerX = 0;
  }

  void _startLevel() {
    player.resetPlayer();
    player.position = Vector2(100, size.y - 100 - player.size.y / 2);
    _maxPlayerX = 0;

    world.children.whereType<Platform>().forEach((p) => p.removeFromParent());
    world.children.whereType<Coin>().forEach((c) => c.removeFromParent());
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<Goal>().forEach((g) => g.removeFromParent());
    world.children.whereType<Potion>().forEach((p) => p.removeFromParent());
    world.children.whereType<Chest>().forEach((c) => c.removeFromParent());
    world.children.whereType<GameDecoration>().forEach((d) => d.removeFromParent());

    _lastGeneratedX = 0;
    _generateNextChunk(2000);
  }

  void _generateNextChunk(double targetX) {
    while (_lastGeneratedX < targetX) {
      world.add(Platform(
        position: Vector2(_lastGeneratedX, size.y - 100),
        size: Vector2(400, 100),
        isGround: true,
      ));

      if (_lastGeneratedX > 200 && _random.nextDouble() > 0.45) {
        final groundDecoTypes = [DecorationType.mushroom, DecorationType.rock, DecorationType.bush];
        final type = groundDecoTypes[_random.nextInt(groundDecoTypes.length)];
        world.add(GameDecoration(
          position: Vector2(_lastGeneratedX + 30 + _random.nextDouble() * 320, size.y - 140),
          size: Vector2(40, 40),
          type: type,
        ));
      }

      if (_random.nextDouble() > 0.5) {
        world.add(GameDecoration(
          position: Vector2(_lastGeneratedX + _random.nextDouble() * 400, size.y * 0.1 + _random.nextDouble() * 100),
          size: Vector2(90, 45),
          type: DecorationType.cloud,
        ));
      }

      if (_lastGeneratedX > 400) {
        final y = size.y - 200 - _random.nextInt(150).toDouble();
        final w = 150 + _random.nextInt(150).toDouble();
        world.add(Platform(position: Vector2(_lastGeneratedX + 100, y), size: Vector2(w, 40)));

        if (_random.nextDouble() > 0.4) {
          world.add(Coin(position: Vector2(_lastGeneratedX + 100 + w / 2, y - 40)));
        }
        if (_random.nextDouble() > 0.6) {
          world.add(Enemy(
            position: Vector2(_lastGeneratedX + 100 + w / 2, y - 40),
            type: _random.nextBool() ? EnemyType.walking : EnemyType.flying,
          ));
        }
        if (_random.nextDouble() > 0.8) {
          world.add(Potion(
            position: Vector2(_lastGeneratedX + 100 + _random.nextDouble() * w, y - 50),
            type: _random.nextBool() ? PotionType.health : PotionType.invincibility,
          ));
        }
        if (_random.nextDouble() > 0.92) {
          world.add(Chest(position: Vector2(_lastGeneratedX + 100 + w / 2, y - 60)));
        }
      }

      _lastGeneratedX += 400;
    }
  }

  @override
  void update(double dt) {
    if (!isStarted || isGameOver) return;
    super.update(dt);
    elapsedTime += dt;

    if (player.position.x > _maxPlayerX) _maxPlayerX = player.position.x;
    score = (_maxPlayerX / 10).toInt() + coinCount * 10;

    livesText.text = '❤️' * (lives > 0 ? lives : 0);
    coinText.text = '$coinCount';
    timeText.text = 'TIME: ${elapsedTime.toInt()}s';
    scoreText.text = 'SCORE: ${score.toString().padLeft(4, '0')}';

    if (player.position.x + 1500 > _lastGeneratedX) {
      _generateNextChunk(player.position.x + 2000);
    }

    if (parallaxBackground != null) {
      parallaxBackground!.position = camera.viewfinder.position - size / 2;
      if (parallaxBackground!.parallax != null) {
        parallaxBackground!.parallax!.baseVelocity.x = player.velocity.x / 20;
      }
    }
  }

  @override
  Color backgroundColor() {
    switch (selectedMap) {
      case 2:
        // Forest: warm blue sky → golden afternoon → deep orange dusk
        const sky = Color(0xFF87CEEB);
        const golden = Color(0xFFFFB74D);
        const dusk = Color(0xFFE64A19);
        if (_maxPlayerX < 4000) {
          return Color.lerp(sky, golden, _maxPlayerX / 4000)!;
        }
        return Color.lerp(golden, dusk, ((_maxPlayerX - 4000) / 6000).clamp(0.0, 1.0))!;

      case 3:
        // Valley: clear blue → warm amber → dusky pink
        const clear = Color(0xFF81D4FA);
        const amber = Color(0xFFFFCC02);
        const pink = Color(0xFFE91E63);
        if (_maxPlayerX < 5000) {
          return Color.lerp(clear, amber, _maxPlayerX / 5000)!;
        }
        return Color.lerp(amber, pink, ((_maxPlayerX - 5000) / 5000).clamp(0.0, 1.0))!;

      default:
        // Mountains (map 1): deep purple twilight → midnight blue
        const twilight = Color(0xFF4A148C);
        const night = Color(0xFF0D1B4B);
        return Color.lerp(twilight, night, (_maxPlayerX / 10000).clamp(0.0, 1.0))!;
    }
  }

  void nextLevel() {}

  void gameOver() {
    isGameOver = true;
    overlays.add('game_over');
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isStarted || isGameOver) {
      if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.space)) {
        overlays.remove('main_menu');
        overlays.remove('game_over');
        overlays.add('map_select');
      }
      return KeyEventResult.handled;
    }

    horizontalInput = 0;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) horizontalInput -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) horizontalInput += 1;

    if (keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
      if (event is KeyDownEvent) player.jump();
    }

    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isStarted || isGameOver) return;
    player.attack();
  }
}

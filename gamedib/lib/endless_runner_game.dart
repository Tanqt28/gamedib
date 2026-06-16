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
import 'decoration.dart';

class EndlessRunnerGame extends FlameGame with HasCollisionDetection, TapCallbacks, KeyboardEvents {
  late Player player;
  late TextComponent scoreText;
  late TextComponent coinText;
  late TextComponent livesText;
  late TextComponent timeText;
  TextComponent? _gameOverText;

  int lives = 3;
  int score = 0;
  int coinCount = 0;
  bool isGameOver = false;
  double elapsedTime = 0.0;
  double _maxPlayerX = 0;

  double horizontalInput = 0;
  final math.Random _random = math.Random();

  late ParallaxComponent parallaxBackground;
  double _lastGeneratedX = 0;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    await _setupBackground();

    player = Player();
    world.add(player);
    camera.follow(player);

    _setupUI();
    _startLevel();
  }

  Future<void> _setupBackground() async {
    try {
      parallaxBackground = await loadParallaxComponent(
        [
          ParallaxImageData('bg_layer_1.png'),
          ParallaxImageData('bg_layer_2.png'),
          ParallaxImageData('bg_layer_3.png'),
        ],
        baseVelocity: Vector2(0, 0),
        velocityMultiplierDelta: Vector2(1.2, 0),
      );
      world.add(parallaxBackground);
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
      text: '❤️' * lives,
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

  void _startLevel() {
    player.resetPlayer();
    // Spawn player just above the ground (size.y - 100 is ground top)
    player.position = Vector2(100, size.y - 100 - player.size.y / 2);
    _maxPlayerX = 0;

    world.children.whereType<Platform>().forEach((p) => p.removeFromParent());
    world.children.whereType<Coin>().forEach((c) => c.removeFromParent());
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<Potion>().forEach((p) => p.removeFromParent());
    world.children.whereType<Chest>().forEach((c) => c.removeFromParent());
    world.children.whereType<GameDecoration>().forEach((d) => d.removeFromParent());

    _lastGeneratedX = 0;
    _generateNextChunk(2000);
  }

  void _generateNextChunk(double targetX) {
    while (_lastGeneratedX < targetX) {
      // Ground
      world.add(Platform(
        position: Vector2(_lastGeneratedX, size.y - 100),
        size: Vector2(400, 100),
        isGround: true,
      ));

      // Ground decorations
      if (_lastGeneratedX > 200 && _random.nextDouble() > 0.45) {
        final groundDecoTypes = [DecorationType.mushroom, DecorationType.rock, DecorationType.bush];
        final type = groundDecoTypes[_random.nextInt(groundDecoTypes.length)];
        world.add(GameDecoration(
          position: Vector2(_lastGeneratedX + 30 + _random.nextDouble() * 320, size.y - 140),
          size: Vector2(40, 40),
          type: type,
        ));
      }

      // Clouds
      if (_random.nextDouble() > 0.5) {
        world.add(GameDecoration(
          position: Vector2(_lastGeneratedX + _random.nextDouble() * 400, size.y * 0.1 + _random.nextDouble() * 100),
          size: Vector2(90, 45),
          type: DecorationType.cloud,
        ));
      }

      // Floating platforms
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
    if (isGameOver) return;
    super.update(dt);
    elapsedTime += dt;

    if (player.position.x > _maxPlayerX) _maxPlayerX = player.position.x;
    score = (_maxPlayerX / 10).toInt() + coinCount * 10;

    livesText.text = '❤️' * (lives > 0 ? lives : 0);
    coinText.text = '$coinCount';
    timeText.text = 'TIME: ${elapsedTime.toInt()}s';
    scoreText.text = 'SCORE: ${score.toString().padLeft(4, '0')}';

    // Always generate ahead of the player
    if (player.position.x + 1500 > _lastGeneratedX) {
      _generateNextChunk(player.position.x + 2000);
    }

    parallaxBackground.position = camera.viewfinder.position - size / 2;
    if (parallaxBackground.parallax != null) {
      parallaxBackground.parallax!.baseVelocity.x = horizontalInput * player.moveSpeed / 15;
    }
  }

  @override
  Color backgroundColor() {
    const day = Color(0xFF87CEEB);      // sky blue
    const sunset = Color(0xFFFF7043);  // deep orange
    const dusk = Color(0xFF7B1FA2);    // purple
    const night = Color(0xFF0D1B4B);   // dark navy

    if (_maxPlayerX < 3000) {
      return Color.lerp(day, sunset, _maxPlayerX / 3000)!;
    } else if (_maxPlayerX < 7000) {
      return Color.lerp(sunset, dusk, (_maxPlayerX - 3000) / 4000)!;
    } else {
      return Color.lerp(dusk, night, ((_maxPlayerX - 7000) / 5000).clamp(0.0, 1.0))!;
    }
  }

  // Kept for compatibility with goal.dart
  void nextLevel() {}

  void gameOver() {
    isGameOver = true;
    _gameOverText = TextComponent(
      text: 'GAME OVER\nSCORE: $score\nPress Space to Restart',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2))],
        ),
      ),
    );
    camera.viewport.add(_gameOverText!);
  }

  void resetGame() {
    lives = 3;
    score = 0;
    coinCount = 0;
    elapsedTime = 0;
    isGameOver = false;
    horizontalInput = 0;

    _gameOverText?.removeFromParent();
    _gameOverText = null;

    _startLevel();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isGameOver) {
      if (keysPressed.contains(LogicalKeyboardKey.space)) resetGame();
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
    if (isGameOver) {
      resetGame();
    } else {
      player.attack();
    }
  }
}

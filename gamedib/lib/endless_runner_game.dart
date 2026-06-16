import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame_audio/flame_audio.dart';
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
  late TextComponent levelText;
  late TextComponent objectiveText;

  int lives = 3;
  int score = 0;
  int coinCount = 0;
  bool isGameOver = false;
  bool isStarted = false; 
  double elapsedTime = 0.0;
  int currentLevel = 1;
  final int maxLevels = 3;

  double levelLength = 5000.0; 
  bool goalSpawned = false;

  double horizontalInput = 0;
  double verticalInput = 0; 
  final math.Random _random = math.Random();

  ParallaxComponent? parallaxBackground; 
  double _lastGeneratedX = 0;
  
  final List<Platform> platforms = [];

  int selectedMapIndex = 1;
  final Map<int, List<String>> mapBackgrounds = {
    1: ['bg_layer_1.png', 'bg_layer_2.png', 'bg_layer_3.png'],
    2: ['bg_layer_1.png', 'bg_layer_2.png', 'bg_layer_3.png'], 
    3: ['bg_layer_1.png', 'bg_layer_2.png', 'bg_layer_3.png'],
  };

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;

    player = Player();
    world.add(player);
    camera.follow(player);

    _setupUI();
    
    await selectMap(1); 
    
    // Start background music loop
    FlameAudio.bgm.initialize();
  }

  Future<void> _setupBackground() async {
    if (parallaxBackground != null) {
      parallaxBackground!.removeFromParent();
    }
    
    try {
      final images = mapBackgrounds[selectedMapIndex] ?? mapBackgrounds[1]!;
      parallaxBackground = await loadParallaxComponent(
        images.map((img) => ParallaxImageData(img)).toList(),
        baseVelocity: Vector2(0, 0),
        velocityMultiplierDelta: Vector2(1.2, 0),
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

    levelText = TextComponent(
      text: 'LEVEL: $currentLevel',
      position: Vector2(size.x - 20, 50),
      anchor: Anchor.topRight,
      textRenderer: textPaint,
    );
    camera.viewport.add(levelText);

    scoreText = TextComponent(
      text: 'SCORE: 0000',
      position: Vector2(size.x - 20, 20),
      anchor: Anchor.topRight,
      textRenderer: textPaint,
    );
    camera.viewport.add(scoreText);

    objectiveText = TextComponent(
      text: 'Objective: Reach the flag!',
      position: Vector2(size.x / 2, 60),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(style: textStyle.copyWith(fontSize: 16, color: Colors.yellowAccent)),
    );
    camera.viewport.add(objectiveText);
    
    _setUIVisibility(false);
  }

  void _setUIVisibility(bool visible) {
    livesText.opacity = visible ? 1 : 0;
    coinText.opacity = visible ? 1 : 0;
    timeText.opacity = visible ? 1 : 0;
    levelText.opacity = visible ? 1 : 0;
    scoreText.opacity = visible ? 1 : 0;
    objectiveText.opacity = visible ? 1 : 0;
  }

  void startGame() {
    isStarted = true;
    isGameOver = false;
    lives = 3;
    score = 0;
    coinCount = 0;
    currentLevel = 1;
    elapsedTime = 0;
    
    overlays.remove('main_menu');
    overlays.remove('map_select');
    overlays.remove('game_over');
    overlays.remove('pause_menu');
    
    _setUIVisibility(true);
    resumeEngine();
    _startLevel();
    
    FlameAudio.play('400 Sounds Pack/Musical Effects/8_bit_level_start.wav');
    
    // Play BGM
    FlameAudio.bgm.play('400 Sounds Pack/Musical Effects/8_bit_inn.wav');
  }

  Future<void> selectMap(int mapIndex) async {
    selectedMapIndex = mapIndex;
    await _setupBackground();
    FlameAudio.play('400 Sounds Pack/UI/select_2.wav');
    if (!isStarted) {
      overlays.remove('map_select');
      overlays.add('main_menu');
    } else {
      startGame();
    }
  }

  void resetToMenu() {
    isStarted = false;
    isGameOver = false;
    pauseEngine();
    overlays.clear();
    overlays.add('main_menu');
    _setUIVisibility(false);
    FlameAudio.bgm.stop();
    FlameAudio.play('400 Sounds Pack/UI/cancel.wav');
  }

  void resumeGame() {
    overlays.remove('pause_menu');
    resumeEngine();
    FlameAudio.play('400 Sounds Pack/UI/select_1.wav');
  }

  void pauseGame() {
    overlays.add('pause_menu');
    pauseEngine();
    FlameAudio.play('400 Sounds Pack/UI/select_4.wav');
  }

  void _startLevel() {
    goalSpawned = false;
    player.resetPlayer();
    
    platforms.clear();
    world.children.whereType<Platform>().forEach((p) => p.removeFromParent());
    world.children.whereType<Coin>().forEach((c) => c.removeFromParent());
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<Goal>().forEach((g) => g.removeFromParent());
    world.children.whereType<Potion>().forEach((p) => p.removeFromParent());
    world.children.whereType<Chest>().forEach((c) => c.removeFromParent());
    world.children.whereType<GameDecoration>().forEach((d) => d.removeFromParent());

    levelLength = 4000.0 + (currentLevel * 2000.0);
    _lastGeneratedX = 0;
    _generateNextChunk(2000);
  }

  void _generateNextChunk(double targetX) {
    while (_lastGeneratedX < targetX && _lastGeneratedX < levelLength + 1000) {
      final p = Platform(position: Vector2(_lastGeneratedX, size.y - 100), size: Vector2(400, 100), isGround: true);
      world.add(p);
      platforms.add(p);
      
      if (_lastGeneratedX > 400 && _lastGeneratedX < levelLength) {
        double y = size.y - 200 - _random.nextInt(150).toDouble();
        double w = 150 + _random.nextInt(150).toDouble();
        final fp = Platform(position: Vector2(_lastGeneratedX + 100, y), size: Vector2(w, 40));
        world.add(fp);
        platforms.add(fp);

        if (_random.nextDouble() > 0.4) {
          world.add(Coin(position: Vector2(_lastGeneratedX + 100 + w / 2, y - 40)));
        }
        if (_random.nextDouble() > 0.6) {
          world.add(Enemy(position: Vector2(_lastGeneratedX + 100 + w / 2, y - 40), type: _random.nextBool() ? EnemyType.walking : EnemyType.flying));
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

    livesText.text = '❤️' * (lives > 0 ? lives : 0);
    coinText.text = '$coinCount';
    timeText.text = 'TIME: ${elapsedTime.toInt()}s';
    scoreText.text = 'SCORE: ${score.toString().padLeft(4, '0')}';
    levelText.text = 'LEVEL: $currentLevel';

    if (player.position.x + 1500 > _lastGeneratedX && _lastGeneratedX < levelLength + 1000) {
      _generateNextChunk(player.position.x + 2000);
    }

    if (parallaxBackground != null) {
      parallaxBackground!.position = camera.viewfinder.position - Vector2(size.x / 2, size.y / 2);
      if (parallaxBackground!.parallax != null) {
        parallaxBackground!.parallax!.baseVelocity.x = player.velocity.x / 20;
      }
    }

    if (!goalSpawned && player.position.x > levelLength) {
      world.add(Goal(position: Vector2(levelLength + 300, size.y - 180)));
      goalSpawned = true;
    }
  }

  void nextLevel() {
    if (currentLevel < maxLevels) {
      currentLevel++;
      _startLevel();
      objectiveText.text = 'Level $currentLevel: Find the Flag!';
      FlameAudio.play('400 Sounds Pack/Musical Effects/8_bit_level_start.wav');
    } else {
      victory();
    }
  }

  void victory() {
    isGameOver = true;
    objectiveText.text = 'ALL LEVELS CLEARED!';
    scoreText.text = 'FINAL SCORE: $score';
    scoreText.position = size / 2;
    scoreText.anchor = Anchor.center;
    FlameAudio.bgm.stop();
    FlameAudio.play('400 Sounds Pack/Musical Effects/8_bit_level_complete.wav');
    overlays.add('game_over');
  }

  void gameOver() {
    isGameOver = true;
    objectiveText.text = 'GAME OVER';
    scoreText.text = 'FINAL SCORE: $score';
    scoreText.position = size / 2;
    scoreText.anchor = Anchor.center;
    FlameAudio.bgm.stop();
    FlameAudio.play('400 Sounds Pack/Retro/lose.wav');
    overlays.add('game_over');
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isStarted) return KeyEventResult.ignored;

    if (keysPressed.contains(LogicalKeyboardKey.escape) && event is KeyDownEvent) {
      pauseGame();
      return KeyEventResult.handled;
    }

    if (isGameOver) {
      return KeyEventResult.handled;
    }

    horizontalInput = 0;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) horizontalInput -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) horizontalInput += 1;

    verticalInput = 0;
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) verticalInput -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) verticalInput += 1;

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      if (event is KeyDownEvent) player.jump();
    }

    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isStarted) return;
    if (!isGameOver) {
      player.attack();
    }
  }
}

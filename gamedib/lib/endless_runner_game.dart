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
  double elapsedTime = 0.0;
  int currentLevel = 1;
  final int maxLevels = 3;

  double levelLength = 5000.0; 
  bool goalSpawned = false;

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
          ParallaxImageData('bg_layer_1.jpeg'),
          ParallaxImageData('bg_layer_2.jpeg'),
          ParallaxImageData('bg_layer_3.jpg'),
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
  }

  void _startLevel() {
    goalSpawned = false;
    player.resetPlayer();
    
    // Clear old stuff from world
    world.children.whereType<Platform>().forEach((p) => p.removeFromParent());
    world.children.whereType<Coin>().forEach((c) => c.removeFromParent());
    world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    world.children.whereType<Goal>().forEach((g) => g.removeFromParent());
    world.children.whereType<Potion>().forEach((p) => p.removeFromParent());
    world.children.whereType<Chest>().forEach((c) => c.removeFromParent());

    levelLength = 4000.0 + (currentLevel * 2000.0);
    _lastGeneratedX = 0;
    _generateNextChunk(2000);
  }

  void _generateNextChunk(double targetX) {
    while (_lastGeneratedX < targetX && _lastGeneratedX < levelLength + 1000) {
      // Ground
      world.add(Platform(position: Vector2(_lastGeneratedX, size.y - 100), size: Vector2(400, 100), isGround: true));
      
      // Floating platforms
      if (_lastGeneratedX > 400 && _lastGeneratedX < levelLength) {
        double y = size.y - 200 - _random.nextInt(150).toDouble();
        double w = 150 + _random.nextInt(150).toDouble();
        world.add(Platform(position: Vector2(_lastGeneratedX + 100, y), size: Vector2(w, 40)));

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
    if (isGameOver) return;
    super.update(dt);
    elapsedTime += dt;

    // Update UI
    livesText.text = '❤️' * (lives > 0 ? lives : 0);
    coinText.text = '$coinCount';
    timeText.text = 'TIME: ${elapsedTime.toInt()}s';
    scoreText.text = 'SCORE: ${score.toString().padLeft(4, '0')}';
    levelText.text = 'LEVEL: $currentLevel';

    // Endless generation ahead of player
    if (player.position.x + 1500 > _lastGeneratedX && _lastGeneratedX < levelLength + 1000) {
      _generateNextChunk(player.position.x + 2000);
    }

    // Parallax background movement based on player velocity
    if (parallaxBackground.parallax != null) {
      parallaxBackground.parallax!.baseVelocity.x = player.velocity.x / 15;
    }

    // Spawn goal at the end
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
  }

  void gameOver() {
    isGameOver = true;
    objectiveText.text = 'GAME OVER - Press Space to Restart';
    scoreText.text = 'FINAL SCORE: $score';
    scoreText.position = size / 2;
    scoreText.anchor = Anchor.center;
  }

  void resetGame() {
    lives = 3;
    score = 0;
    coinCount = 0;
    currentLevel = 1;
    elapsedTime = 0;
    isGameOver = false;
    horizontalInput = 0;
    
    scoreText.position = Vector2(size.x - 20, 20);
    scoreText.anchor = Anchor.topRight;
    
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

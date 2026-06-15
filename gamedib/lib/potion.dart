import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

enum PotionType { health, invincibility }

class Potion extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  final PotionType type;

  Potion({required Vector2 position, required this.type}) : super(position: position, size: Vector2(25, 35));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final color = type == PotionType.health ? Colors.red : Colors.blue;
    final paint = Paint()..color = color;
    
    // Bottle shape
    canvas.drawRect(Rect.fromLTWH(5, 10, 15, 20), paint);
    canvas.drawRect(Rect.fromLTWH(8, 5, 9, 5), Paint()..color = Colors.white70); // Neck
    canvas.drawRect(Rect.fromLTWH(6, 2, 13, 3), Paint()..color = Colors.brown); // Cork
    
    // Shine
    canvas.drawRect(Rect.fromLTWH(7, 12, 3, 10), Paint()..color = Colors.white38);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.player.position.x - position.x > 1200) {
      removeFromParent();
    }
  }

  void collect() {
    if (type == PotionType.health) {
      if (gameRef.lives < 3) gameRef.lives++;
    } else {
      gameRef.player.isInvulnerable = true;
      gameRef.player.invulnerableTimer = 5.0; // 5 seconds for blue potion
    }
    removeFromParent();
  }
}

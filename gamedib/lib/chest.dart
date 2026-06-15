import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

class Chest extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  Chest({required Vector2 position}) : super(position: position, size: Vector2(50, 40));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final bodyPaint = Paint()..color = Colors.brown[700]!;
    final trimPaint = Paint()..color = Colors.orange;
    
    // Main box
    canvas.drawRect(size.toRect(), bodyPaint);
    // Lid line
    canvas.drawRect(Rect.fromLTWH(0, 10, size.x, 3), Paint()..color = Colors.black);
    // Lock/Trim
    canvas.drawRect(Rect.fromLTWH(size.x/2 - 5, 8, 10, 8), trimPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 5, size.y), trimPaint);
    canvas.drawRect(Rect.fromLTWH(size.x - 5, 0, 5, size.y), trimPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Chest is now static in the world coordinate system.
  }

  void collect() {
    gameRef.score += 2000;
    gameRef.lives = 3; // Refill lives
    removeFromParent();
  }
}

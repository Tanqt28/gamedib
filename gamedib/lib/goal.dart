import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

class Goal extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  Goal({required Vector2 position}) : super(position: position, size: Vector2(60, 80));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Draw a flag or a castle gate
    final polePaint = Paint()..color = Colors.grey[400]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, 10, size.y), polePaint);
    
    final flagPaint = Paint()..color = Colors.blue;
    final path = Path()
      ..moveTo(10, 0)
      ..lineTo(size.x, 20)
      ..lineTo(10, 40)
      ..close();
    canvas.drawPath(path, flagPaint);
  }

  void reach() {
    gameRef.nextLevel();
    removeFromParent();
  }
}

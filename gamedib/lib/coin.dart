import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

class Coin extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  Coin({required Vector2 position}) : super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    
    final borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, borderPaint);
  }

  void collect() {
    gameRef.score += 100;
    gameRef.coinCount += 1;
    removeFromParent();
  }
}

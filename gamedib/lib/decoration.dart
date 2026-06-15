import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

enum DecorationType { mushroom, rock, bush, cloud }

class GameDecoration extends PositionComponent with HasGameRef<EndlessRunnerGame> {
  final DecorationType type;

  GameDecoration({
    required Vector2 position,
    required Vector2 size,
    required this.type,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    switch (type) {
      case DecorationType.mushroom:
        _drawMushroom(canvas);
        break;
      case DecorationType.rock:
        _drawRock(canvas);
        break;
      case DecorationType.bush:
        _drawBush(canvas);
        break;
      case DecorationType.cloud:
        _drawCloud(canvas);
        break;
    }
  }

  void _drawMushroom(Canvas canvas) {
    // Stem
    canvas.drawRect(Rect.fromLTWH(size.x * 0.4, size.y * 0.6, size.x * 0.2, size.y * 0.4), Paint()..color = Colors.white);
    // Cap
    final capPaint = Paint()..color = Colors.red;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.y * 0.2, size.x, size.y * 0.5), Radius.circular(size.x / 2)), capPaint);
    // Dots
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 3, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.45), 2, Paint()..color = Colors.white);
  }

  void _drawRock(Canvas canvas) {
    final paint = Paint()..color = Colors.grey;
    final path = Path()
      ..moveTo(0, size.y)
      ..lineTo(size.x * 0.2, size.y * 0.2)
      ..lineTo(size.x * 0.8, 0)
      ..lineTo(size.x, size.y)
      ..close();
    canvas.drawPath(path, paint);
    // Shadow/Detail
    canvas.drawPath(path, Paint()..color = Colors.black26);
  }

  void _drawBush(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.7), size.x * 0.3, paint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.7), size.x * 0.3, paint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.4), size.x * 0.4, paint);
  }

  void _drawCloud(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.5), size.y * 0.4, paint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.5), size.y * 0.4, paint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.3), size.y * 0.4, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Decorations are now static in world coordinates.
    // Parallax background handles clouds if they are in the background layers.
    // If these are clouds as components, we could move them slowly, but let's keep it simple for now.
    
    // Cull if way behind camera
    if (gameRef.camera.viewfinder.position.x - position.x > 1500) {
      removeFromParent();
    }
  }
}

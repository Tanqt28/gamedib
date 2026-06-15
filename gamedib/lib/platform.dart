import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

class Platform extends PositionComponent with HasGameRef<EndlessRunnerGame> {
  final bool isGround;

  Platform({
    required Vector2 position,
    required Vector2 size,
    this.isGround = false,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    
    // 1. Dirt Base (Brown)
    final dirtPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRect(rect, dirtPaint);
    
    // 2. Grass Top (Bright green)
    final grassHeight = isGround ? 30.0 : 20.0;
    final grassPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, grassHeight), grassPaint);
    
    // 3. Grass "Drips" (Pixelated edge)
    final darkGrassPaint = Paint()..color = const Color(0xFF388E3C);
    double step = 10.0;
    for (double i = 0; i < size.x; i += step) {
      double dripHeight = (i % (step * 2) == 0) ? 8.0 : 4.0;
      canvas.drawRect(Rect.fromLTWH(i, grassHeight, step / 2, dripHeight), darkGrassPaint);
    }

    // 4. Dirt Texture (Pebbles)
    final detailPaint = Paint()..color = const Color(0xFF5D4037);
    if (size.x > 40) {
      canvas.drawRect(Rect.fromLTWH(size.x * 0.2, size.y * 0.5, 6, 4), detailPaint);
      canvas.drawRect(Rect.fromLTWH(size.x * 0.7, size.y * 0.4, 4, 3), detailPaint);
    }
    
    // 5. Borders for depth
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);
    
    // 6. Floating platform "rounded" look at bottom (pixel style)
    if (!isGround) {
      final cornerPaint = Paint()..color = Colors.black26;
      canvas.drawRect(Rect.fromLTWH(0, size.y - 5, 5, 5), cornerPaint);
      canvas.drawRect(Rect.fromLTWH(size.x - 5, size.y - 5, 5, 5), cornerPaint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Removed auto-scroll logic. Platform stays in world coordinates.
    
    // Optional: Cull platforms that are way behind the camera if needed for performance,
    // but for discrete levels, we can just keep them or cull by distance from player.
    if (gameRef.player.position.x - position.x > 1500) {
      //removeFromParent(); // Only if we want true infinite generation
    }
  }
}

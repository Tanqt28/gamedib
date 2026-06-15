import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';

enum EnemyType { flying, walking }

class Enemy extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  final EnemyType type;
  double speed = 100.0;
  int direction = -1; // 1 for right, -1 for left
  double patrolRange = 150.0;
  late double startX;
  bool isDead = false;
  int health = 3;
  int _flashFrames = 0;

  Enemy({required Vector2 position, required this.type}) : super(position: position, size: Vector2(40, 40)) {
    startX = position.x;
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (isDead) return;
    if (_flashFrames > 0 && _flashFrames % 2 == 0) return;

    if (type == EnemyType.flying) {
      // Flying Eye-Bat
      final bodyPaint = Paint()..color = Colors.purple;
      canvas.drawRect(Rect.fromLTWH(0, 10, 15, 10), bodyPaint);
      canvas.drawRect(Rect.fromLTWH(25, 10, 15, 10), bodyPaint);
      canvas.drawCircle(Offset(20, 20), 15, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(20, 20), 7, Paint()..color = Colors.red);
      canvas.drawCircle(Offset(20, 20), 3, Paint()..color = Colors.black);
    } else {
      // Skeleton
      final bonePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(10, 0, 20, 20), bonePaint);
      canvas.drawRect(Rect.fromLTWH(12, 12, 5, 5), Paint()..color = Colors.black);
      canvas.drawRect(Rect.fromLTWH(23, 12, 5, 5), Paint()..color = Colors.black);
      canvas.drawRect(Rect.fromLTWH(15, 20, 10, 15), bonePaint);
      canvas.drawRect(Rect.fromLTWH(10, 25, 20, 2), Paint()..color = Colors.black);
      canvas.drawRect(Rect.fromLTWH(30, 15, 15, 5), Paint()..color = Colors.grey);
    }

    // Health bar above enemy
    final barWidth = size.x;
    final healthPercent = health / 3.0;
    canvas.drawRect(Rect.fromLTWH(0, -10, barWidth, 4), Paint()..color = Colors.black45);
    canvas.drawRect(Rect.fromLTWH(0, -10, barWidth * healthPercent, 4), Paint()..color = Colors.red);
  }

  @override
  void update(double dt) {
    if (gameRef.isGameOver || isDead) return;
    super.update(dt);
    if (_flashFrames > 0) _flashFrames--;
    if (gameRef.player.position.x - position.x > 1200) {
      removeFromParent();
      return;
    }

    if (type == EnemyType.walking) {
      position.x += direction * speed * dt;
      if ((position.x - startX).abs() > patrolRange) {
        direction *= -1;
      }
    } else {
      // Flying wave pattern
      position.x += direction * (speed * 0.5) * dt;
      position.y += math.sin(gameRef.elapsedTime * 5) * 2;
      if ((position.x - startX).abs() > patrolRange * 1.5) {
        direction *= -1;
      }
    }
  }

  void takeDamage() {
    if (isDead) return;
    health--;
    if (health <= 0) {
      die();
    } else {
      _flashFrames = 8;
    }
  }

  void die() {
    if (isDead) return;
    isDead = true;
    gameRef.score += 500;
    removeFromParent();
  }
}

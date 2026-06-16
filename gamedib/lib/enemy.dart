import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';
import 'platform.dart';

enum EnemyType { flying, walking }

class Enemy extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  final EnemyType type;
  double speed = 120.0;
  int direction = -1; // 1 for right, -1 for left
  bool isDead = false;
  int health = 3;
  int _flashFrames = 0;

  // Physics for walking enemies
  final double gravity = 1500.0;
  Vector2 velocity = Vector2.zero();
  bool isGrounded = false;

  Enemy({required Vector2 position, required this.type}) : super(position: position, size: Vector2(40, 40)) {
    anchor = Anchor.center;
    this.position = position;
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
      canvas.drawRect(Rect.fromLTWH(-15, -10, 15, 10), bodyPaint);
      canvas.drawRect(Rect.fromLTWH(0, -10, 15, 10), bodyPaint);
      canvas.drawCircle(Offset(0, 0), 15, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(0, 0), 7, Paint()..color = Colors.red);
      canvas.drawCircle(Offset(0, 0), 3, Paint()..color = Colors.black);
    } else {
      // Skeleton
      final bonePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(-10, -20, 20, 20), bonePaint); // Skull
      canvas.drawRect(Rect.fromLTWH(-8, -8, 5, 5), Paint()..color = Colors.black); // Eye
      canvas.drawRect(Rect.fromLTWH(3, -8, 5, 5), Paint()..color = Colors.black); // Eye
      canvas.drawRect(Rect.fromLTWH(-5, 0, 10, 15), bonePaint); // Body
      canvas.drawRect(Rect.fromLTWH(-10, 5, 20, 2), Paint()..color = Colors.black); // Ribs
      canvas.drawRect(Rect.fromLTWH(10, -5, 15, 5), Paint()..color = Colors.grey); // Sword
    }

    // Health bar
    final barWidth = size.x;
    final healthPercent = health / 3.0;
    canvas.drawRect(Rect.fromLTWH(-barWidth / 2, -30, barWidth, 4), Paint()..color = Colors.black45);
    canvas.drawRect(Rect.fromLTWH(-barWidth / 2, -30, barWidth * healthPercent, 4), Paint()..color = Colors.red);
  }

  @override
  void update(double dt) {
    if (gameRef.isGameOver || isDead) return;
    super.update(dt);
    
    if (_flashFrames > 0) _flashFrames--;

    if (type == EnemyType.walking) {
      // Apply gravity
      if (!isGrounded) {
        velocity.y += gravity * dt;
      } else {
        velocity.y = 0;
      }
      position.y += velocity.y * dt;

      // Horizontal Movement
      position.x += direction * speed * dt;
      
      // Face direction
      if (direction > 0) {
        if (scale.x < 0) scale.x = scale.x.abs();
      } else {
        if (scale.x > 0) scale.x = -scale.x.abs();
      }

      // Death by falling into pits
      if (position.y > 1000) {
        removeFromParent();
      }
    } else {
      // Flying Eye-Bat: Fluctuating movement
      position.x += direction * (speed * 0.6) * dt;
      position.y += math.sin(gameRef.elapsedTime * 4) * 1.5;
      
      // Basic bound check for flying (optional)
      if (position.y < 50) position.y = 50;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Platform) {
      if (type == EnemyType.walking) {
        final enemyBottom = position.y + size.y / 2;
        final platformTop = other.position.y; // Platform anchor is topLeft

        // Check if landing on top
        if (velocity.y >= 0 && enemyBottom >= platformTop && (enemyBottom - platformTop) < 25) {
          position.y = platformTop - size.y / 2;
          velocity.y = 0;
          isGrounded = true;
        } else {
          // Hit side - change direction
          if (intersectionPoints.first.x < position.x && direction < 0) {
            direction = 1;
          } else if (intersectionPoints.first.x > position.x && direction > 0) {
            direction = -1;
          }
        }
      } else if (type == EnemyType.flying) {
        // Flying bats just turn around on collision with platforms
        direction *= -1;
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Platform) {
      isGrounded = false;
    }
  }

  void takeDamage() {
    if (isDead) return;
    health--;
    if (health <= 0) {
      die();
    } else {
      _flashFrames = 10;
    }
  }

  void die() {
    if (isDead) return;
    isDead = true;
    gameRef.score += 500;
    removeFromParent();
  }
}

import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';
import 'platform.dart';
import 'coin.dart';
import 'enemy.dart';
import 'potion.dart';
import 'chest.dart';
import 'goal.dart';

class Player extends PositionComponent with HasGameRef<EndlessRunnerGame>, CollisionCallbacks {
  final double gravity = 1500.0;
  final double jumpVelocity = -650.0;
  final double moveSpeed = 350.0;

  Vector2 velocity = Vector2.zero();
  bool isGrounded = false;
  int jumpCount = 0;
  final int maxJumps = 1;

  bool isAttacking = false;
  double attackDuration = 0.25;
  double attackTimer = 0;
  final Set<Enemy> _hitThisAttack = {};

  bool isInvulnerable = false;
  double invulnerableDuration = 1.5;
  double invulnerableTimer = 0;

  bool isFlashed = false;
  double flashTimer = 0;

  Player() {
    position = Vector2(100, 400);
    size = Vector2(45, 55);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (isFlashed && (flashTimer * 10).toInt() % 2 == 0) return;

    // Body (Tunic)
    final bodyPaint = Paint()..color = isInvulnerable ? Colors.blue : Colors.green;
    canvas.drawRect(Rect.fromLTWH(-15, -10, 30, 35), bodyPaint);
    
    // Head
    final headPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(Rect.fromLTWH(-12, -27, 24, 20), headPaint);
    
    // Hair
    final hairPaint = Paint()..color = Colors.brown;
    canvas.drawRect(Rect.fromLTWH(-12, -27, 24, 6), hairPaint);
    
    // Sword
    final swordPaint = Paint()..color = Colors.grey;
    if (isAttacking) {
      canvas.save();
      canvas.translate(15, 0);
      canvas.rotate(0.5);
      canvas.drawRect(Rect.fromLTWH(0, -5, 40, 10), swordPaint);
      canvas.drawRect(Rect.fromLTWH(0, -5, 45, 12), Paint()..color = Colors.white.withOpacity(0.4));
      canvas.restore();
    } else {
      canvas.drawRect(Rect.fromLTWH(15, 5, 20, 5), swordPaint);
    }
  }

  @override
  void update(double dt) {
    if (gameRef.isGameOver) return;
    super.update(dt);

    // Apply manual movement
    position.x += gameRef.horizontalInput * moveSpeed * dt;

    // Apply gravity
    velocity.y += gravity * dt;
    position.y += velocity.y * dt;

    if (isAttacking) {
      attackTimer -= dt;
      if (attackTimer <= 0) {
        isAttacking = false;
        _hitThisAttack.clear();
      }
    }

    if (invulnerableTimer > 0) {
      invulnerableTimer -= dt;
      flashTimer += dt;
      if (invulnerableTimer <= 0) {
        isInvulnerable = false;
        isFlashed = false;
      }
    }

    // Fell off the world
    if (position.y > 1200) {
      gameRef.lives--;
      if (gameRef.lives <= 0) {
        gameRef.gameOver();
      } else {
        position.x = (gameRef.camera.viewfinder.position.x - 300).clamp(100.0, double.maxFinite);
        position.y = 300;
        velocity = Vector2.zero();
        isGrounded = false;
        isInvulnerable = true;
        isFlashed = true;
        invulnerableTimer = invulnerableDuration;
        flashTimer = 0;
      }
    }

    if (position.x < 20) position.x = 20;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Platform) {
      if (velocity.y > 0 && (position.y + size.y / 2 - velocity.y * 0.2) <= other.position.y - other.size.y / 2) {
        position.y = other.position.y - other.size.y / 2 - size.y / 2;
        velocity.y = 0;
        isGrounded = true;
        jumpCount = 0;
      }
    } else if (other is Coin) {
      other.collect();
    } else if (other is Enemy) {
      if (isAttacking) {
        if (!_hitThisAttack.contains(other)) {
          other.takeDamage();
          other.position.x += 150;
          _hitThisAttack.add(other);
        }
      } else if (velocity.y > 0 && (position.y + size.y / 2) < other.position.y) {
        other.die();
        velocity.y = jumpVelocity * 0.7;
      } else {
        takeDamage();
      }
    } else if (other is Potion) {
      other.collect();
    } else if (other is Chest) {
      other.collect();
    } else if (other is Goal) {
      other.reach();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Platform) {
      isGrounded = false;
    }
  }

  void jump() {
    if (isGrounded || jumpCount < maxJumps) {
      velocity.y = jumpVelocity;
      jumpCount++;
      isGrounded = false;
    }
  }

  void attack() {
    if (!isAttacking) {
      isAttacking = true;
      attackTimer = attackDuration;
      _hitThisAttack.clear();
    }
  }

  void takeDamage() {
    if (isInvulnerable) return;

    gameRef.lives--;
    if (gameRef.lives <= 0) {
      gameRef.gameOver();
    } else {
      isInvulnerable = true;
      isFlashed = true;
      invulnerableTimer = invulnerableDuration;
      flashTimer = 0;
      position.x -= 50;
      velocity.y = -400;
    }
  }

  void resetPlayer() {
    position = Vector2(100, 400);
    velocity = Vector2.zero();
    isGrounded = false;
    isAttacking = false;
    isInvulnerable = false;
    isFlashed = false;
    jumpCount = 0;
  }
}

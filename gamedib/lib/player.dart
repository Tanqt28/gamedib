import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'endless_runner_game.dart';
import 'platform.dart';
import 'coin.dart';
import 'enemy.dart';
import 'potion.dart';
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
    canvas.drawRect(Rect.fromLTWH(-17.5, -12.5, 35, 40), bodyPaint);
    
    // Head
    final headPaint = Paint()..color = const Color(0xFFFFDBAC);
    canvas.drawRect(Rect.fromLTWH(-12.5, -27.5, 25, 20), headPaint);
    
    // Hair
    final hairPaint = Paint()..color = Colors.brown;
    canvas.drawRect(Rect.fromLTWH(-12.5, -27.5, 25, 5), hairPaint);
    
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

    // Horizontal Movement (A/D)
    position.x += gameRef.horizontalInput * moveSpeed * dt;

    // Face the direction of movement (A/D)
    if (gameRef.horizontalInput > 0) {
      if (scale.x < 0) scale.x = scale.x.abs();
    } else if (gameRef.horizontalInput < 0) {
      if (scale.x > 0) scale.x = -scale.x.abs();
    }

    // Vertical Movement (W/S) - Manual Up/Down
    if (gameRef.verticalInput != 0) {
      position.y += gameRef.verticalInput * moveSpeed * dt;
      isGrounded = false; 
    }

    // Apply gravity only if not grounded and not moving manually up
    if (!isGrounded && gameRef.verticalInput == 0) {
      velocity.y += gravity * dt;
    } else if (isGrounded) {
      velocity.y = 0;
    }
    
    // Cap vertical velocity to prevent falling through platforms
    if (velocity.y > 1000) velocity.y = 1000;
    
    position.y += velocity.y * dt;

    // Manual Floor Check to prevent falling through when high speed
    _checkGroundCollisions();

    if (isAttacking) {
      attackTimer -= dt;
      if (attackTimer <= 0) {
        isAttacking = false;
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

    // Death by falling
    if (position.y > 1500) { 
      gameRef.gameOver();
    }

    if (position.x < size.x / 2) position.x = size.x / 2;
  }

  void _checkGroundCollisions() {
    // Only check if we are moving down
    if (velocity.y < 0 && gameRef.verticalInput >= 0) return;
    
    final playerBottom = position.y + size.y / 2;
    final playerLeft = position.x - size.x / 2;
    final playerRight = position.x + size.x / 2;

    bool foundGround = false;

    for (final platform in gameRef.platforms) {
      final platformTop = platform.position.y;
      final platformBottom = platform.position.y + platform.size.y;
      final platformLeft = platform.position.x;
      final platformRight = platform.position.x + platform.size.x;

      // Check if player is horizontally over the platform
      if (playerRight > platformLeft && playerLeft < platformRight) {
        // Check if player bottom is crossing the platform top
        if (playerBottom >= platformTop && playerBottom <= platformTop + 40) {
          position.y = platformTop - size.y / 2;
          velocity.y = 0;
          isGrounded = true;
          jumpCount = 0;
          foundGround = true;
          break;
        }
      }
    }

    if (!foundGround && gameRef.verticalInput == 0) {
      isGrounded = false;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Coin) {
      other.collect();
    } else if (other is Enemy) {
      if (isAttacking) {
        other.takeDamage();
        other.position.x += (scale.x > 0 ? 50 : -50);
      } else if (velocity.y > 0 && (position.y + size.y / 2) < other.position.y) {
        other.die();
        velocity.y = jumpVelocity * 0.7; 
        isGrounded = false;
      } else {
        takeDamage();
      }
    } else if (other is Potion) {
      other.collect();
    } else if (other is Goal) {
      other.reach();
    }
  }

  void jump() {
    if (isGrounded) {
      velocity.y = jumpVelocity;
      isGrounded = false;
      jumpCount = 1;
    }
  }

  void attack() {
    if (!isAttacking) {
      isAttacking = true;
      attackTimer = attackDuration;
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
      
      position.x -= (scale.x > 0 ? 60 : -60);
      velocity.y = -400;
      isGrounded = false;
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
    scale.x = scale.x.abs();
  }
}

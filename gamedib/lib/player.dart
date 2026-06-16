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

  // Track active platform collisions to handle grounding accurately
  final Set<Platform> _groundedPlatforms = {};

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

    final rect = Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y);
    
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

    isGrounded = _groundedPlatforms.isNotEmpty;

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
      if (gameRef.verticalInput < 0) {
        isGrounded = false;
        _groundedPlatforms.clear();
      }
    }

    // Apply gravity
    if (!isGrounded && gameRef.verticalInput == 0) {
      velocity.y += gravity * dt;
    } else if (isGrounded) {
      velocity.y = 0;
    }
    
    position.y += velocity.y * dt;

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
    if (position.y > 1000) { 
      gameRef.gameOver();
    }

    // World bounds
    if (position.x < size.x / 2) position.x = size.x / 2;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Platform) {
      // Landing logic: Fixed the bouncing by ensuring a stable snap
      if (velocity.y >= 0 || gameRef.verticalInput > 0) {
        final playerBottom = position.y + size.y / 2;
        final platformTop = other.position.y; // Platform anchor is topLeft
        
        // If the player's bottom is roughly at the platform's top and moving down.
        if (playerBottom >= platformTop && (playerBottom - platformTop) < 30) {
           // Snap exactly to top, with a 1.0px overlap to ensure collision stays active
           position.y = platformTop - size.y / 2 + 1.0;
           velocity.y = 0;
           _groundedPlatforms.add(other);
           isGrounded = true;
           jumpCount = 0;
        }
      }
    } else if (other is Coin) {
      other.collect();
    } else if (other is Enemy) {
      if (isAttacking) {
        other.takeDamage();
        other.position.x += (scale.x > 0 ? 50 : -50);
      } else if (velocity.y > 0 && (position.y + size.y / 2) < other.position.y) {
        // Stomp kill
        other.die();
        velocity.y = jumpVelocity * 0.7; 
        isGrounded = false;
        _groundedPlatforms.clear();
      } else {
        takeDamage();
      }
    } else if (other is Potion) {
      other.collect();
    } else if (other is Goal) {
      other.reach();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Platform) {
      _groundedPlatforms.remove(other);
    }
  }

  void jump() {
    if (isGrounded) {
      velocity.y = jumpVelocity;
      jumpCount = 1;
      isGrounded = false;
      _groundedPlatforms.clear();
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
      
      // Player knockback
      position.x -= (scale.x > 0 ? 60 : -60);
      velocity.y = -400;
      isGrounded = false;
      _groundedPlatforms.clear();
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
    _groundedPlatforms.clear();
  }
}

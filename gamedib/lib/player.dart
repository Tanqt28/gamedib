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

    // Flame positions the render canvas at the component's top-left even when
    // anchor = Anchor.center. Shift to center so all draw calls use center-relative coords.
    canvas.translate(size.x / 2, size.y / 2);

    final skin      = Paint()..color = const Color(0xFFFFDBAC);
    final hair      = Paint()..color = const Color(0xFF3E2000);
    final tunic     = Paint()..color = isInvulnerable ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final pants     = Paint()..color = const Color(0xFF1A237E);
    final boot      = Paint()..color = const Color(0xFF3E2723);
    final belt      = Paint()..color = const Color(0xFF6D4C41);
    final eye       = Paint()..color = const Color(0xFF212121);
    final blade     = Paint()..color = const Color(0xFFCFD8DC);
    final handle    = Paint()..color = const Color(0xFF795548);
    final guard     = Paint()..color = const Color(0xFFFDD835);
    final shine     = Paint()..color = Colors.white.withOpacity(0.55);

    // Head  (top aligned to hitbox top: -27.5)
    canvas.drawRect(Rect.fromLTWH(-9, -27.5, 18, 16.5), skin);
    // Hair (fills hitbox top)
    canvas.drawRect(Rect.fromLTWH(-9, -27.5, 18, 6.5), hair);
    // Side hair
    canvas.drawRect(Rect.fromLTWH(-9, -21, 3, 5), hair);
    // Eyes
    canvas.drawRect(Rect.fromLTWH(-7, -20, 4, 3), eye);
    canvas.drawRect(Rect.fromLTWH(3,  -20, 4, 3), eye);
    canvas.drawRect(Rect.fromLTWH(-6, -20, 1, 1), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(4,  -20, 1, 1), Paint()..color = Colors.white);

    // Tunic / body
    canvas.drawRect(Rect.fromLTWH(-11, -11, 22, 20), tunic);
    // Neck seam
    canvas.drawRect(Rect.fromLTWH(-4, -11, 8, 3), skin);

    // Belt
    canvas.drawRect(Rect.fromLTWH(-11, 7, 22, 4), belt);
    // Belt buckle
    canvas.drawRect(Rect.fromLTWH(-3, 7, 6, 4), guard);

    // Legs
    canvas.drawRect(Rect.fromLTWH(-11, 11, 9, 11), pants);
    canvas.drawRect(Rect.fromLTWH(2,   11, 9, 11), pants);

    // Boots (bottom exactly at hitbox bottom: y = 27.5 = size.y/2)
    canvas.drawRect(Rect.fromLTWH(-12, 20, 10, 7.5), boot);
    canvas.drawRect(Rect.fromLTWH(2,   20, 10, 7.5), boot);
    // Boot highlight
    canvas.drawRect(Rect.fromLTWH(-11, 21, 3, 2), Paint()..color = Colors.white.withOpacity(0.3));
    canvas.drawRect(Rect.fromLTWH(3,   21, 3, 2), Paint()..color = Colors.white.withOpacity(0.3));

    // Sword
    if (isAttacking) {
      canvas.save();
      canvas.translate(13, 0);
      canvas.rotate(0.45);
      canvas.drawRect(Rect.fromLTWH(0, -3, 38, 5), blade);   // blade
      canvas.drawRect(Rect.fromLTWH(-4, -6, 6, 11), guard);  // guard
      canvas.drawRect(Rect.fromLTWH(-9, -3, 7, 5), handle);  // handle
      canvas.drawRect(Rect.fromLTWH(1, -2, 34, 2), shine);   // edge shine
      canvas.restore();
    } else {
      // Vertical resting position
      canvas.drawRect(Rect.fromLTWH(12, -16, 5, 27), blade);
      canvas.drawRect(Rect.fromLTWH(9,   4,  11, 4), guard);
      canvas.drawRect(Rect.fromLTWH(13,  8,  4,  9), handle);
      canvas.drawRect(Rect.fromLTWH(13, -16, 1, 20), shine);
    }
  }

  @override
  void update(double dt) {
    if (gameRef.isGameOver) return;
    super.update(dt);

    position.x += gameRef.horizontalInput * moveSpeed * dt;

    if (gameRef.horizontalInput > 0) {
      if (scale.x < 0) scale.x = scale.x.abs();
    } else if (gameRef.horizontalInput < 0) {
      if (scale.x > 0) scale.x = -scale.x.abs();
    }

    if (!isGrounded) {
      velocity.y += gravity * dt;
    } else {
      velocity.y = 0;
    }

    position.y += velocity.y * dt;

    // Direct AABB ground check — more reliable than collision callbacks
    _resolveGrounding();

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

    if (position.y > 1200) {
      gameRef.lives--;
      if (gameRef.lives <= 0) {
        gameRef.gameOver();
      } else {
        position.x = (gameRef.camera.viewfinder.position.x - 300).clamp(100.0, double.maxFinite);
        position.y = gameRef.size.y - 100 - size.y / 2;
        velocity = Vector2.zero();
        isGrounded = false;
        isInvulnerable = true;
        isFlashed = true;
        invulnerableTimer = invulnerableDuration;
        flashTimer = 0;
      }
    }

    if (position.x < size.x / 2) position.x = size.x / 2;
  }

  // Per-frame AABB collision resolution against the explicit platforms list.
  // Handles both ground and floating platforms — ground tiles are included so
  // the snap always uses the actual platform.position.y rather than the
  // potentially stale gameRef.size.y value.
  void _resolveGrounding() {
    final playerTop    = position.y - size.y / 2;
    final playerBottom = position.y + size.y / 2;
    final playerLeft   = position.x - size.x / 2;
    final playerRight  = position.x + size.x / 2;

    isGrounded = false;

    for (final platform in gameRef.platforms) {
      final platLeft   = platform.position.x;
      final platRight  = platform.position.x + platform.size.x;
      final platTop    = platform.position.y;
      final platBottom = platform.position.y + platform.size.y;

      if (playerRight <= platLeft || playerLeft >= platRight) continue;

      // Land on top (falling down onto platform)
      if (velocity.y >= 0 && playerBottom >= platTop && playerBottom <= platBottom) {
        position.y = platTop - size.y / 2;
        velocity.y = 0;
        isGrounded = true;
        jumpCount = 0;
        return;
      }

      // Bounce off underside — only for floating platforms, not the solid ground
      if (!platform.isGround && velocity.y < 0 && playerTop >= platTop && playerTop <= platBottom) {
        position.y = platBottom + size.y / 2;
        velocity.y = 0;
        return;
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Platform grounding is handled by _resolveGrounding(); only handle collectibles/enemies here
    if (other is Coin) {
      other.collect();
    } else if (other is Enemy) {
      if (isAttacking) {
        other.takeDamage();
        if (!other.isDead) other.position.x += (scale.x > 0 ? 50 : -50);
      } else if (velocity.y > 0 && (position.y + size.y / 2) < other.position.y) {
        other.die();
        velocity.y = jumpVelocity * 0.7;
        isGrounded = false;
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

  void jump() {
    if (isGrounded) {
      velocity.y = jumpVelocity;
      jumpCount = 1;
      isGrounded = false;
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

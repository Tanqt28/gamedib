// lib/components/pipe_group.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flappy_bird/components/pipe.dart';
import 'package:flappy_bird/game/configuration.dart';
import 'package:flappy_bird/game/flappy_bird_game.dart';
import 'package:flappy_bird/game/pipe_position.dart';
import 'package:flutter/cupertino.dart';
import '../game/assets.dart';

class PipeGroup extends PositionComponent with HasGameReference<FlappyBirdGame> {
  PipeGroup();

  final _random = Random();

  @override
  Future<void> onLoad() async {
    position.x = game.size.x;
    final heightMinusGround = game.size.y - Config.groundHeight;
    final spacing = 100 + _random.nextDouble() * (heightMinusGround / 4);
    final centerY = spacing + _random.nextDouble() * (heightMinusGround - spacing);

    addAll([
      Pipe(pipePosition: PipePosition.top, height: centerY - spacing / 2),
      Pipe(pipePosition: PipePosition.bottom, height: heightMinusGround - (centerY + spacing / 2)),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= Config.gameSpeed * dt;

    if (position.x < -50) {
      removeFromParent();
      updateScore();
    }

    if (game.isHit) {
      removeFromParent();
      game.isHit = false;
    }
  }

  void updateScore() {
    game.bird.score++;
    FlameAudio.play(Assets.point);
  }
}
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:candy_crush/game/candy_type.dart';
import 'package:candy_crush/game/candy_crush_game.dart';
import 'package:flutter/animation.dart';

class Candy extends SpriteComponent with HasGameReference<CandyCrushGame> {
  int gridX;
  int gridY;
  final CandyType type;

  Candy({required this.gridX, required this.gridY, required this.type});

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(type.asset);
    anchor = Anchor.center;
  }

  void moveTo(int x, int y) {
    gridX = x;
    gridY = y;
    add(MoveEffect.to(
      game.gridToPosition(x, y),
      EffectController(duration: 0.3, curve: Curves.easeInOut),
    ));
  }
}
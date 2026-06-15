import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:candy_crush/game/candy_type.dart';
import 'package:candy_crush/components/candy.dart';
import 'package:flutter/material.dart';

class LevelData {
  final int targetScore;
  final int moves;
  final String objective;

  LevelData({required this.targetScore, required this.moves, required this.objective});
}

class CandyCrushGame extends FlameGame {
  static const int rows = 8;
  static const int cols = 8;
  static const double tileSize = 50.0; // Increased for better visibility

  late List<List<Candy?>> board;
  Candy? selectedCandy;

  int score = 0;
  int movesLeft = 0;
  int currentLevelIndex = 1;
  bool isProcessing = false;

  final Map<int, LevelData> levels = {
    1: LevelData(targetScore: 500, moves: 20, objective: 'Reach 500 points'),
    2: LevelData(targetScore: 1200, moves: 25, objective: 'Reach 1200 points'),
    3: LevelData(targetScore: 2500, moves: 30, objective: 'Reach 2500 points'),
  };

  @override
  Color backgroundColor() => const Color(0x00000000); // Transparent background

  @override
  Future<void> onLoad() async {
    Flame.images.prefix = 'lib/icons/';
    FlameAudio.audioCache.prefix = 'lib/audio/';
    board = List.generate(rows, (_) => List.filled(cols, null));
  }

  void handleTap(Offset localPosition) {
    if (isProcessing || movesLeft <= 0) return;

    final boardWidth = cols * tileSize;
    final boardHeight = rows * tileSize;
    
    // Offset calculation for the 150px sidebar
    final startX = (size.x + 150 - boardWidth) / 2;
    final startY = (size.y - boardHeight) / 2;

    final x = ((localPosition.dx - startX) / tileSize).floor();
    final y = ((localPosition.dy - startY) / tileSize).floor();

    if (x >= 0 && x < cols && y >= 0 && y < rows) {
      final candy = board[y][x];
      if (candy != null) {
        onCandyTapped(candy);
      }
    }
  }

  void startLevel(int level) {
    currentLevelIndex = level;
    final data = levels[level]!;
    score = 0;
    movesLeft = data.moves;
    isProcessing = false;

    children.whereType<Candy>().forEach((c) => c.removeFromParent());
    board = List.generate(rows, (_) => List.filled(cols, null));

    generateBoard();
    overlays.remove('mainMenu');
    overlays.remove('gameOver');
    overlays.remove('victory');
    resumeEngine();
  }

  void generateBoard() {
    final random = Random();
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        CandyType type;
        do {
          type = CandyType.values[random.nextInt(CandyType.values.length)];
        } while (willCreateMatch(i, j, type));
        spawnCandy(i, j, type);
      }
    }
  }

  bool willCreateMatch(int r, int c, CandyType type) {
    if (r >= 2 && board[r-1][c]?.type == type && board[r-2][c]?.type == type) return true;
    if (c >= 2 && board[r][c-1]?.type == type && board[r][c-2]?.type == type) return true;
    return false;
  }

  void spawnCandy(int r, int c, CandyType type) {
    final candy = Candy(gridX: c, gridY: r, type: type);
    candy.size = Vector2.all(tileSize * 0.9);
    candy.position = gridToPosition(c, r);
    board[r][c] = candy;
    add(candy);
  }

  Vector2 gridToPosition(int x, int y) {
    final boardWidth = cols * tileSize;
    final boardHeight = rows * tileSize;
    final startX = (size.x + 150 - boardWidth) / 2 + tileSize / 2;
    final startY = (size.y - boardHeight) / 2 + tileSize / 2;
    return Vector2(startX + x * tileSize, startY + y * tileSize);
  }

  void onCandyTapped(Candy candy) {
    if (selectedCandy == null) {
      selectedCandy = candy;
      candy.add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.1)));
    } else {
      if (selectedCandy == candy) {
        candy.add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
        selectedCandy = null;
        return;
      }

      if (isAdjacent(selectedCandy!, candy)) {
        swapCandies(selectedCandy!, candy);
      } else {
        selectedCandy!.add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
        selectedCandy = candy;
        candy.add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.1)));
      }
    }
  }

  bool isAdjacent(Candy c1, Candy c2) {
    return (c1.gridX - c2.gridX).abs() + (c1.gridY - c2.gridY).abs() == 1;
  }

  void swapCandies(Candy c1, Candy c2) async {
    isProcessing = true;
    movesLeft--;

    int x1 = c1.gridX, y1 = c1.gridY;
    int x2 = c2.gridX, y2 = c2.gridY;

    board[y1][x1] = c2;
    board[y2][x2] = c1;

    c1.moveTo(x2, y2);
    c2.moveTo(x1, y1);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!checkMatches()) {
      board[y1][x1] = c1;
      board[y2][x2] = c2;
      c1.moveTo(x1, y1);
      c2.moveTo(x2, y2);
      await Future.delayed(const Duration(milliseconds: 400));
      isProcessing = false;
      movesLeft++;
    } else {
      resolveMatches();
    }

    selectedCandy?.add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
    selectedCandy = null;
  }

  bool checkMatches() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (getMatchAt(i, j).length >= 3) return true;
      }
    }
    return false;
  }

  List<Candy> getMatchAt(int r, int c) {
    CandyType? type = board[r][c]?.type;
    if (type == null) return [];

    List<Candy> horizontal = [board[r][c]!];
    for (int j = c + 1; j < cols && board[r][j]?.type == type; j++) horizontal.add(board[r][j]!);
    for (int j = c - 1; j >= 0 && board[r][j]?.type == type; j--) horizontal.add(board[r][j]!);

    List<Candy> vertical = [board[r][c]!];
    for (int i = r + 1; i < rows && board[i][c]?.type == type; i++) vertical.add(board[i][c]!);
    for (int i = r - 1; i >= 0 && board[i][c]?.type == type; i--) vertical.add(board[i][c]!);

    List<Candy> result = [];
    if (horizontal.length >= 3) result.addAll(horizontal);
    if (vertical.length >= 3) result.addAll(vertical);

    return result.toSet().toList();
  }

  void resolveMatches() async {
    List<Candy> allToRemove = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final matches = getMatchAt(i, j);
        if (matches.length >= 3) allToRemove.addAll(matches);
      }
    }

    if (allToRemove.isEmpty) {
      isProcessing = false;
      checkGameStatus();
      return;
    }

    allToRemove = allToRemove.toSet().toList();
    for (var candy in allToRemove) {
      board[candy.gridY][candy.gridX] = null;
      candy.add(OpacityEffect.fadeOut(EffectController(duration: 0.3), onComplete: () => candy.removeFromParent()));
      score += 10;
    }

    try { await FlameAudio.play('match.wav'); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));

    applyGravity();
  }

  void applyGravity() async {
    for (int j = 0; j < cols; j++) {
      int emptySpots = 0;
      for (int i = rows - 1; i >= 0; i--) {
        if (board[i][j] == null) {
          emptySpots++;
        } else if (emptySpots > 0) {
          final candy = board[i][j]!;
          board[i + emptySpots][j] = candy;
          board[i][j] = null;
          candy.moveTo(j, i + emptySpots);
        }
      }
      for (int i = 0; i < emptySpots; i++) {
        final type = CandyType.values[Random().nextInt(CandyType.values.length)];
        final candy = Candy(gridX: j, gridY: i, type: type);
        candy.size = Vector2.all(tileSize * 0.9);
        candy.position = gridToPosition(j, i - emptySpots);
        board[i][j] = candy;
        add(candy);
        candy.moveTo(j, i);
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    resolveMatches();
  }

  void checkGameStatus() {
    if (score >= levels[currentLevelIndex]!.targetScore) {
      pauseEngine();
      overlays.add('victory');
    } else if (movesLeft <= 0) {
      pauseEngine();
      overlays.add('gameOver');
    }
  }
}

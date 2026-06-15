import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:candy_crush/game/candy_crush_game.dart';
import 'dart:math' as math;

void main() {
  final game = CandyCrushGame();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Verdana',
      ),
      home: Scaffold(
        body: Stack(
          children: [
            // Shared cosmic background gradient
            const BackgroundLayer(),
            GestureDetector(
              onTapDown: (details) => game.handleTap(details.localPosition),
              child: GameWidget(
                game: game,
                overlayBuilderMap: {
                  'mainMenu': (context, _) => MainMenuOverlay(game: game),
                  'gameOver': (context, _) => GameOverOverlay(game: game),
                  'victory': (context, _) => VictoryOverlay(game: game),
                  'ui': (context, _) => GameUI(game: game),
                },
                initialActiveOverlays: const ['mainMenu'],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8ED6FF), Color(0xFFC0E8FF)],
        ),
      ),
      child: Stack(
        children: [
          // Background clouds visible during game
          Positioned(top: 50, right: 100, child: Opacity(opacity: 0.4, child: Icon(Icons.cloud, size: 100, color: Colors.white))),
          Positioned(top: 150, left: 200, child: Opacity(opacity: 0.3, child: Icon(Icons.cloud, size: 80, color: Colors.white))),
        ],
      ),
    );
  }
}

class MainMenuOverlay extends StatelessWidget {
  final CandyCrushGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8ED6FF), // Sky Blue
            Color(0xFFC0E8FF), // Lighter Sky
            Color(0xFF76C442), // Hill Top
            Color(0xFF4C9D2F), // Hill Bottom
          ],
          stops: [0.0, 0.45, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Clouds
          Positioned(top: 80, left: 30, child: _cloud(70)),
          Positioned(top: 140, right: 40, child: _cloud(90)),
          Positioned(top: 220, left: 150, child: _cloud(60)),

          // Decorative Candies on Hills (piles)
          Positioned(bottom: 120, left: 10, child: _candyDecor('lib/icons/ballsprinkle.png', 90)),
          Positioned(bottom: 80, left: 80, child: _candyDecor('lib/icons/cherry.png', 70)),
          Positioned(bottom: 30, left: 110, child: _candyDecor('lib/icons/chocolate.png', 110)),
          Positioned(bottom: 50, right: 130, child: _candyDecor('lib/icons/jellybean.png', 75)),
          Positioned(bottom: 110, left: 230, child: _candyDecor('lib/icons/star.png', 80)),
          Positioned(bottom: 10, right: -10, child: _candyDecor('lib/icons/sun.png', 100)),
          Positioned(bottom: 0, left: 50, child: _candyDecor('lib/icons/cherry_c.png', 60)),

          // Character area (Simulated Tiffi character)
          Positioned(
            bottom: 60,
            left: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                  ),
                  child: const Text("Sweet!",
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.pink, fontSize: 18)),
                ),
                const SizedBox(height: 5),
                const Icon(Icons.face_retouching_natural, size: 150, color: Colors.pinkAccent),
              ],
            ),
          ),

          Center(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Hanging Rope
                Container(width: 4, height: 65, color: Colors.brown[400]),
                // Hanging Logo Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEB3B).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.brown[800]!, width: 5),
                    boxShadow: const [BoxShadow(blurRadius: 20, offset: Offset(0, 10), color: Colors.black45)],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Candy',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          shadows: const [Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 2)],
                        ),
                      ),
                      Text(
                        'Crush',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          shadows: const [Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 2)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black26)],
                        ),
                        child: const Text('SAGA',
                            style: TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
                // Styled Buttons
                _actionButton(
                  text: 'Play!',
                  color: Colors.pinkAccent,
                  onPressed: () {
                    game.overlays.add('ui');
                    game.startLevel(1);
                  },
                ),
                const SizedBox(height: 25),
                _actionButton(
                  text: 'Retrieve My Progress',
                  color: Colors.blueAccent,
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Settings Button (Bottom Left)
          Positioned(
            bottom: 30,
            left: 30,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
              ),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.pinkAccent,
                child: Icon(Icons.settings, color: Colors.white, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloud(double size) => Icon(Icons.cloud, size: size, color: Colors.white.withOpacity(0.95));

  Widget _candyDecor(String asset, double size) {
    return Transform.rotate(
      angle: math.Random().nextDouble() * 0.6 - 0.3,
      child: Image.asset(asset, width: size, height: size),
    );
  }

  Widget _actionButton({required String text, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: 280,
      height: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: const BorderSide(color: Colors.white, width: 5),
          ),
          elevation: 0,
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
      ),
    );
  }
}

class GameUI extends StatefulWidget {
  final CandyCrushGame game;
  const GameUI({super.key, required this.game});

  @override
  State<GameUI> createState() => _GameUIState();
}

class _GameUIState extends State<GameUI> {
  @override
  Widget build(BuildContext context) {
    final currentLevelData = widget.game.levels[widget.game.currentLevelIndex];
    final targetScore = currentLevelData?.targetScore ?? 1;

    return Stack(
      children: [
        // Left Sidebar mimicking the Candy Crush UI (Reference 2)
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          width: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8BBD0), Color(0xFFFCE4EC)],
              ),
              border: const Border(right: BorderSide(color: Colors.pink, width: 4)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Booster place holders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _boosterIcon(Icons.brush, Colors.orange),
                    _boosterIcon(Icons.auto_awesome, Colors.purple),
                    _boosterIcon(Icons.shopping_basket, Colors.green),
                  ],
                ),
                const SizedBox(height: 35),
                // Target Display
                _sidebarBox('Target:', targetScore.toString(), const Color(0xFFF48FB1)),
                const SizedBox(height: 25),
                // Moves Display
                _sidebarBox(
                    'Moves:',
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(milliseconds: 200)),
                      builder: (context, _) => Text(widget.game.movesLeft.toString(),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
                    ),
                    Colors.white),

                const Spacer(),

                // Vertical Score Progress
                const Text('SCORE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.pink)),
                const SizedBox(height: 8),
                _scoreLiquidBar(targetScore),
                const SizedBox(height: 12),
                StreamBuilder(
                    stream: Stream.periodic(const Duration(milliseconds: 200)),
                    builder: (context, _) => Text(widget.game.score.toString(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)))),
                const SizedBox(height: 15),
                // Level label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Text('Level ${widget.game.currentLevelIndex}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _boosterIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26, offset: Offset(0, 3))]),
      child: Icon(icon, size: 24, color: color),
    );
  }

  Widget _sidebarBox(String label, dynamic value, Color bgColor) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink[300]!, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF4E342E))),
          if (value is String)
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4E342E)))
          else
            value,
        ],
      ),
    );
  }

  Widget _scoreLiquidBar(int target) {
    return Container(
      height: 280,
      width: 45,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF06292),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: StreamBuilder(
          stream: Stream.periodic(const Duration(milliseconds: 200)),
          builder: (context, _) {
            double progress = (widget.game.score / target).clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Golden Score Liquid
                Container(
                  width: double.infinity,
                  height: progress * 268,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEE58), Color(0xFFFBC02D), Color(0xFFF57F17)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                // Goal Markers
                Positioned(bottom: 80, child: _scoreMarker()),
                Positioned(bottom: 160, child: _scoreMarker()),
                Positioned(bottom: 240, child: _scoreMarker()),
                if (progress >= 1.0) const Positioned(top: 15, child: Icon(Icons.star, color: Colors.yellow, size: 30)),
              ],
            );
          }),
    );
  }

  Widget _scoreMarker() => Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(2)),
      );
}

class GameOverOverlay extends StatelessWidget {
  final CandyCrushGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(45),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.pink, width: 10),
            boxShadow: const [BoxShadow(blurRadius: 25, color: Colors.black54)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('OUT OF MOVES!',
                  style: TextStyle(color: Colors.red, fontSize: 42, fontWeight: FontWeight.w900)),
              const SizedBox(height: 25),
              Text('Score: ${game.score}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => game.startLevel(game.currentLevelIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  shape: const StadiumBorder(),
                  elevation: 15,
                ),
                child: const Text('RETRY LEVEL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VictoryOverlay extends StatelessWidget {
  final CandyCrushGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFEB3B)]),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white, width: 10),
            boxShadow: const [BoxShadow(blurRadius: 30, color: Colors.black38)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SUGAR CRUSH!',
                  style: TextStyle(
                      color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              const SizedBox(height: 15),
              const Text('LEVEL COMPLETED!',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => game.startLevel(game.currentLevelIndex + 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 22),
                  shape: const StadiumBorder(),
                  elevation: 15,
                ),
                child: const Text('NEXT LEVEL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'endless_runner_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final game = EndlessRunnerGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget<EndlessRunnerGame>(
          game: game,
          overlayBuilderMap: {
            'main_menu': (context, game) => _MainMenuOverlay(game: game),
            'map_select': (context, game) => _MapSelectOverlay(game: game),
            'game_over': (context, game) => _GameOverOverlay(game: game),
            'pause_menu': (context, game) => _PauseMenuOverlay(game: game),
          },
          initialActiveOverlays: const ['main_menu'],
        ),
      ),
    ),
  );
}

class _MainMenuOverlay extends StatelessWidget {
  final EndlessRunnerGame game;
  const _MainMenuOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ENDLESS RUNNER',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 4,
                shadows: [
                  Shadow(color: Colors.green, blurRadius: 20),
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(3, 3)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Run. Jump. Fight. Survive.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white60,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            _MenuButton(
              label: '▶   PLAY',
              color: Colors.green[600]!,
              onPressed: () {
                game.overlays.remove('main_menu');
                game.overlays.add('map_select');
              },
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'A / D  —  Move        W / Space  —  Jump        Tap / Click  —  Attack',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSelectOverlay extends StatelessWidget {
  final EndlessRunnerGame game;
  const _MapSelectOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.82),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SELECT MAP',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 4,
                shadows: [
                  Shadow(color: Colors.blueAccent, blurRadius: 20),
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MapCard(
                  game: game,
                  mapIndex: 1,
                  name: 'MOUNTAINS',
                  description: 'Purple twilight',
                  imageAsset: 'assets/images/bg_layer_1.png',
                  accentColor: Colors.purple[300]!,
                ),
                const SizedBox(width: 24),
                _MapCard(
                  game: game,
                  mapIndex: 2,
                  name: 'FOREST',
                  description: 'Ancient trees',
                  imageAsset: 'assets/images/bg_layer_2.png',
                  accentColor: Colors.green[400]!,
                ),
                const SizedBox(width: 24),
                _MapCard(
                  game: game,
                  mapIndex: 3,
                  name: 'VALLEY',
                  description: 'Rolling hills',
                  imageAsset: 'assets/images/bg_layer_3.png',
                  accentColor: Colors.teal[300]!,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _MenuButton(
              label: '← BACK',
              color: Colors.grey[700]!,
              onPressed: () {
                game.overlays.remove('map_select');
                game.overlays.add('main_menu');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final EndlessRunnerGame game;
  final int mapIndex;
  final String name;
  final String description;
  final String imageAsset;
  final Color accentColor;

  const _MapCard({
    required this.game,
    required this.mapIndex,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => game.selectMap(mapIndex),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          border: Border.all(color: accentColor, width: 3),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black54,
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: Image.asset(
                imageAsset,
                height: 110,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  color: accentColor.withOpacity(0.15),
                  child: Icon(Icons.landscape, color: accentColor, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => game.selectMap(mapIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('SELECT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final EndlessRunnerGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFamily: 'monospace',
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Colors.redAccent, blurRadius: 24),
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(3, 3)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SCORE: ${game.score}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TIME: ${game.elapsedTime.toInt()}s  •  COINS: ${game.coinCount}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuButton(
                  label: '▶   PLAY AGAIN',
                  color: Colors.green[600]!,
                  onPressed: () => game.startGame(),
                ),
                const SizedBox(width: 16),
                _MenuButton(
                  label: '⇄   CHANGE MAP',
                  color: Colors.blue[700]!,
                  onPressed: () {
                    game.overlays.remove('game_over');
                    game.overlays.add('map_select');
                  },
                ),
                const SizedBox(width: 16),
                _MenuButton(
                  label: '⌂   MAIN MENU',
                  color: Colors.indigo[600]!,
                  onPressed: () => game.resetToMenu(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseMenuOverlay extends StatelessWidget {
  final EndlessRunnerGame game;
  const _PauseMenuOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Colors.blueAccent, blurRadius: 20),
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(3, 3)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _MenuButton(
              label: '▶   RESUME',
              color: Colors.green[600]!,
              onPressed: () => game.resumeGame(),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: '↺   PLAY AGAIN',
              color: Colors.orange[700]!,
              onPressed: () {
                game.resumeGame();
                game.startGame();
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: '⇄   CHANGE MAP',
              color: Colors.blue[700]!,
              onPressed: () {
                game.resumeGame();
                game.overlays.remove('main_menu');
                game.isStarted = false;
                game.overlays.add('map_select');
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: '⌂   MAIN MENU',
              color: Colors.indigo[600]!,
              onPressed: () => game.resetToMenu(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 8,
        shadowColor: Colors.black54,
      ),
      child: Text(label),
    );
  }
}

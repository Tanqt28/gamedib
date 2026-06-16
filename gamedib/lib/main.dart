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
            'game_over': (context, game) => _GameOverOverlay(game: game),
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
            // Title
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
            // Play button
            _MenuButton(
              label: '▶   PLAY',
              color: Colors.green[600]!,
              onPressed: () => game.startGame(),
            ),
            const SizedBox(height: 40),
            // Controls hint
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
                const SizedBox(width: 24),
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

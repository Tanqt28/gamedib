import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'endless_runner_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forces landscape layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hides top and bottom phone status bars
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: EndlessRunnerGame(),
        ),
      ),
    ),
  );
}
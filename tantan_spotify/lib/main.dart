import 'package:flutter/material.dart';
import 'spotify_home.dart';

void main() {
  runApp(const Spotitan());
}

class Spotitan extends StatelessWidget {
  const Spotitan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotitan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const SpotifyHome(),
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const MemoryGameApp());
}

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Memoria',
      theme: ThemeData(
        // 1. CAMBIO AQUÍ: Para que el tema general sea azulito
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
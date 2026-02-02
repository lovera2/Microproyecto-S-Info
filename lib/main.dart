import 'package:flutter/material.dart';

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
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Memoria 6x6"),
          // 2. CAMBIO AQUÍ: El color de la barra
          backgroundColor: Colors.lightBlue, 
          foregroundColor: Colors.white, // Letras blancas
        ),
        body: const Center(child: Text("Tablero de Juego")),
      ),
    );
  }
}
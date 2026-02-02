import 'package:flutter/material.dart';
import '../models/game_card.dart'; // Importamos tu modelo (El molde)

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Aquí guardaremos las 36 cartas en memoria
  List<GameCard> cards = [];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  // Lógica para preparar la partida
  void _initializeGame() {
    // 1. Elegimos 18 emojis (Instrucción: 18 pares = 36 cartas)
    List<String> icons = [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', 
      '🐻', '🐼', '🐨', '🐯', '🦁', '🐮',
      '🐷', '🐸', '🐵', '🐔', '🐧', '🐦',
    ];

    // 2. Duplicamos la lista para tener las parejas
    List<String> deck = [...icons, ...icons];

    // 3. Barajamos las cartas
    deck.shuffle();

    // 4. Creamos las 36 "galletas" usando tu molde GameCard
    setState(() {
      cards = List.generate(36, (index) {
        return GameCard(
          id: index,
          content: deck[index],
          isFlipped: false,
          isMatched: false,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos el color celeste del tema
      backgroundColor: Colors.blue.shade50, 
      appBar: AppBar(
        title: const Text('Memorys den'),
        actions: [
          // Botón para reiniciar (útil para pruebas)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        // GridView: El componente mágico para hacer rejillas
        child: GridView.builder(
          // INSTRUCCIÓN CUMPLIDA: Grid 6x6
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6, // 6 columnas
            crossAxisSpacing: 8, // Espacio horizontal entre cartas
            mainAxisSpacing: 8,  // Espacio vertical entre cartas
            childAspectRatio: 0.8, // Las hace un poco más altas que anchas
          ),
          itemCount: cards.length, // 36 items
          itemBuilder: (context, index) {
            return _buildCardItem(cards[index]);
          },
        ),
      ),
    );
  }

  // Esta función dibuja cada cuadrito individual
  Widget _buildCardItem(GameCard card) {
    return GestureDetector(
      onTap: () {
        // Lógica visual temporal: solo voltea la carta al tocarla
        setState(() {
          card.isFlipped = !card.isFlipped;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          // Si está volteada es Blanca, si no, es Celeste Fuerte
          color: card.isFlipped ? Colors.white : Colors.lightBlue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: card.isFlipped
              ? Text(card.content, style: const TextStyle(fontSize: 26)) // Muestra Emoji
              : const SizedBox(), // No muestra nada si está boca abajo
        ),
      ),
    );
  }
}
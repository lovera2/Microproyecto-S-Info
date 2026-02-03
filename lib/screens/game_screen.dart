import 'package:flutter/material.dart';
import '../models/game_card.dart'; // Importamos el molde
import 'dart:async'; // lo utilizaremos para esperar 1 seg antes de voltear las cartas again 

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Aquí guardaremos las 36 cartas en memoria
  List<GameCard> cards = [];
// Variables para la lógica del juego
  List<int> flippedIndices = []; // Guarda cuáles cartas están boca arriba
  bool isProcessing = false;     // Bloquea la pantalla mientras espera
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

    // 4. Creamos las 36 "tarjetas" usando el molde GameCard
    setState(() {
      flippedIndices.clear();
      isProcessing = false;
      
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
        title: const Text("Memory's Den"),
        actions: [
          // Botón para reiniciar (útil para pruebas)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
          ),
        ],
      ),
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: AspectRatio(
            //Fuerza un tablero cuadrado
            aspectRatio: 1,
            child: GridView.builder(
              // Bloqueamos el scroll porque va a caber perfecto
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, // 6 columnas
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, //Cartas cuadradas
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return _buildCardItem(index);
              },
            ),
          ),
        ),
      ),
    );
  }

void _onCardTap(int index) {
    // Si está pensando, o la carta ya está volteada/emparejada, no hacemos nada
    if (isProcessing || cards[index].isFlipped || cards[index].isMatched) return;

    setState(() {
      cards[index].isFlipped = true; // Volteamos la carta
      flippedIndices.add(index);     // La anotamos
    });

    // Si ya hay 2 cartas levantadas, verificamos
    if (flippedIndices.length == 2) {
      isProcessing = true; // Bloqueamos la pantalla
      _checkForMatch();
    }
  }

  void _checkForMatch() async {
    // Esperamos 1 segundo
    await Future.delayed(const Duration(seconds: 1));

    int index1 = flippedIndices[0];
    int index2 = flippedIndices[1];

    // Comparamos el contenido
    if (cards[index1].content == cards[index2].content) {
      //SON PAREJA
      setState(() {
        cards[index1].isMatched = true;
        cards[index2].isMatched = true;
      });
    } else {
      // FALLASTE (Las escondemos)
      setState(() {
        cards[index1].isFlipped = false;
        cards[index2].isFlipped = false;
      });
    }

    // Limpiamos para el siguiente turno
    flippedIndices.clear();
    isProcessing = false;
  }

  // Esta función dibuja cada cuadrito individual
  Widget _buildCardItem(int index) {
    GameCard card = cards[index]; 

    // PARTE 1: Decidimos el color con calma aquí arriba
    Color cardColor;
    if (card.isFlipped || card.isMatched) {
      cardColor = Colors.white;
    } else {
      cardColor = Colors.lightBlue;
    }

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor, // PARTE 2: Aquí solo usamos el resultado
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
          child: (card.isFlipped || card.isMatched)
              ? Text(card.content, style: const TextStyle(fontSize: 24))
              : const SizedBox(),
        ),
      ),
    );
  }
}
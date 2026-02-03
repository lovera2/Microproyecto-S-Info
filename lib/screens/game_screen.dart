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

  int attempts = 0;          // Contador de intentos
  int matchedPairs = 0;      // Para saber cuándo llegamos a 18
  int secondsElapsed = 0;    // El reloj
  Timer? gameTimer;          // El motor del tiempo
  bool gameStarted = false;  // Para que el tiempo no corra solo

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
      _resetStats();
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

  void _resetStats() {
    gameTimer?.cancel();
    attempts = 0;
    secondsElapsed = 0;
    matchedPairs = 0;
    gameStarted = false;
    flippedIndices.clear();
    isProcessing = false;
  }

  void startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed++;
      });
    });
  }

  void _onCardTap(int index) {
    if (isProcessing || cards[index].isFlipped || cards[index].isMatched) return;

    // Si es el primer click de la partida, arranca el cronómetro
    if (!gameStarted) {
      gameStarted = true;
      startTimer();
    }

    setState(() {
      cards[index].isFlipped = true;
      flippedIndices.add(index);
    });

    if (flippedIndices.length == 2) {
      setState(() => attempts++); // Sumamos un intento
      isProcessing = true;
      _checkForMatch();
    }
  }

  void _checkForMatch() async {
    await Future.delayed(const Duration(seconds: 1));

    int index1 = flippedIndices[0];
    int index2 = flippedIndices[1];

    if (cards[index1].content == cards[index2].content) {
      setState(() {
        cards[index1].isMatched = true;
        cards[index2].isMatched = true;
        matchedPairs++;
      });

      // SISTEMA DE VICTORIA (18 parejas para un 6x6)
      if (matchedPairs == 18) {
        gameTimer?.cancel(); // Detenemos el reloj
        _showVictoryDialog();
      }
    } else {
      setState(() {
        cards[index1].isFlipped = false;
        cards[index2].isFlipped = false;
      });
    }

    flippedIndices.clear();
    isProcessing = false;
  }

  // Aqui creamos la interfaz de usuario

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("¡Victoria! 🎉", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Has encontrado todas las parejas."),
            const SizedBox(height: 10),
            Text("Intentos: $attempts", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Tiempo: $secondsElapsed segundos", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            child: const Text("Jugar de nuevo"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Memory's Den"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // FILA DE ESTADÍSTICAS (Puntos 1 y 2 del plan)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox("Intentos", attempts.toString(), Icons.touch_app),
                _buildStatBox("Tiempo", "${secondsElapsed}s", Icons.timer),
              ],
            ),
          ),
          // TABLERO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) => _buildCardItem(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(int index) {
    GameCard card = cards[index];
    bool isVisible = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: isVisible ? Colors.white : Colors.lightBlue,
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
          child: isVisible
              ? Text(card.content, style: const TextStyle(fontSize: 22))
              : const SizedBox(),
        ),
      ),
    );
  }
}
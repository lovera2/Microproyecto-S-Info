import 'package:flutter/material.dart';
import '../models/game_card.dart'; // Importamos el molde
import 'dart:async'; // lo utilizaremos para esperar 1 seg antes de voltear las cartas again 
import 'dart:math' as math; //para animación 3D (flip)
import 'package:shared_preferences/shared_preferences.dart'; //para guardar el mejor puntaje localmente


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

  int attempts=0;           // Contador de intentos
  int matchedPairs=0;       // Para saber cuándo llegamos a 18
  int secondsElapsed=0;     // El reloj
  Timer? gameTimer;         // El motor del tiempo
  bool gameStarted=false;   // Para que el tiempo no corra solo
  int bestAttempts=0;       // Mejor intento guardado
  int bestTime=0;           // Mejor tiempo guardado
  Set<int> celebrando = {}; // Índices con efecto de celebración

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _loadHighScore();
  }

  // Lógica para preparar la partida
  void _initializeGame() {
    // 1. Elegimos 18 emojis
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

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestAttempts = prefs.getInt('bestAttempts') ?? 0;
      bestTime = prefs.getInt('bestTime') ?? 0;
    });
  }

  Future<void> _saveHighScore(int attemptsNow, int timeNow) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bestAttempts', attemptsNow);
    await prefs.setInt('bestTime', timeNow);
  }

  void startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed++;
      });
    });
  }

  void _onCardTap(int index) {
    if (isProcessing || flippedIndices.length == 2 || cards[index].isFlipped || cards[index].isMatched) return;

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
        celebrando.add(index1);
        celebrando.add(index2);
      });

      //Manejo del efecto de brillo/celebración
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          celebrando.remove(index1);
          celebrando.remove(index2);
        });
      });

      // SISTEMA DE VICTORIA (18 parejas para un 6x6)
      if (matchedPairs == 18) {
        gameTimer?.cancel(); // Detenemos el reloj

        bool nuevoRecord=false;
        if(bestAttempts==0){
          nuevoRecord=true;
        }else if(attempts<bestAttempts){
          nuevoRecord=true;
        }else if(attempts==bestAttempts && secondsElapsed<bestTime){
          nuevoRecord=true;
        }

        if(nuevoRecord){
          setState(() {
            bestAttempts=attempts;
            bestTime=secondsElapsed;
          });
          await _saveHighScore(bestAttempts, bestTime);
        }

        _showVictoryDialog(nuevoRecord);
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

  void _showVictoryDialog(bool nuevoRecord){
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
            const SizedBox(height: 10),
            Text(
              nuevoRecord ? "¡Nuevo récord! 🏆" : "Récord actual: $bestAttempts intentos / ${bestTime}s",
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
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
        title: const Text("Juego de Memoria"),
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
                _buildStatBox(
                  "Mejor",
                  bestAttempts == 0 ? "-" : "$bestAttempts / ${bestTime}s",
                  Icons.emoji_events,
                ),
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
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0, end: isVisible ? 1 : 0),
        builder: (context, value, child) {
          final angle = value * math.pi;
          final showingFront = value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) //generacion de perspectiva
              ..rotateY(angle),
            child: showingFront
                ? _buildCardFront(card, celebrando.contains(index))
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: const Center(child: SizedBox()),
    );
  }

  Widget _buildCardFront(GameCard card, bool glow) {

    //Animación cuando una carta queda emparejada.
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      tween: Tween<double>(end: glow ? 1 : 0),
      builder: (context, t, child) {
        final scale = glow ? (1 + 0.06 * math.sin(t * math.pi)) : 1.0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateY(math.pi)
            ..scale(scale),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: glow
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
              boxShadow: [
                // Sombra normal
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
                if (glow)
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.content,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
}
}
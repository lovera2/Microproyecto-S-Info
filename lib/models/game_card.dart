//Modelo de la carta del juego

class GameCard {
  final int id;
  final String content; 
  bool isFlipped;
  bool isMatched;

  GameCard({
    required this.id,
    required this.content,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
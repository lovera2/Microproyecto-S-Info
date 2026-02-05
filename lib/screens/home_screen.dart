import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Historial

// Key donde guardo/leo el historial
class _HomeScreenState extends State<HomeScreen> {
  static const String historyKey = 'gameHistory';
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // Formatea fecha legible
  String prettyDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(historyKey);

    if (raw == null || raw.trim().isEmpty) {
      setState(() => history = []);
      return;
    }

    // Manejo de errores
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = <Map<String, dynamic>>[];

      for (final item in list) {
        if (item is Map) {
          parsed.add(Map<String, dynamic>.from(item));
        }
      }

      setState(() => history = parsed);
    } catch (_) {
      setState(() => history = []);
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(historyKey);
    setState(() => history = []);
  }

  // Juego

  // Pide nombre y empieza el juego
  Future<void> startGame() async {
    final name = await askPlayerName();
    if (!mounted || name == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(playerName: name)),
    );

    await loadHistory(); // refrescar historial al volver
  }

  Future<String?> askPlayerName() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Cómo te llamas?'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Ej: Andrés'),
            onSubmitted: (_) {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) return;
                Navigator.pop(context, v);
              },
              child: const Text('Jugar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Microproyecto de Sist. de Información'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Borrar historial',
            onPressed: history.isEmpty
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Borrar historial'),
                        content: const Text('¿Seguro que quieres borrar todas las partidas guardadas?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Borrar'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await clearHistory();
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade200,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Stack(
                    children: [
                      // Fondo de emojis
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.08,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const emojis = ['🐶', '🐱', '🐻', '🐼', '🦊', '🐸', '🐵', '🐧'];
                                const double fontSize = 22;
                                const double spacing = 18;
                                final double cellW = fontSize + spacing;
                                final double cellH = fontSize + spacing;
                                final int cols = (constraints.maxWidth / cellW).ceil() + 2;
                                final int rows = (constraints.maxHeight / cellH).ceil() + 2;
                                final int total = (cols * rows).clamp(120, 2000);
                                return Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: List.generate(
                                      total,
                                      (i) => Text(
                                        emojis[i % emojis.length],
                                        style: const TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Contenido centrado
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Card(
                                  elevation: 0,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 74,
                                          height: 74,
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlue.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(22),
                                          ),
                                          child: const Center(
                                            child: Text('🐾', style: TextStyle(fontSize: 34)),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Juego de Memoria',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Encuentra las 18 parejas con el menor número de intentos y el menor tiempo.',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            height: 1.3,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        // Botón principal
                                        SizedBox(
                                          width: 360,
                                          child: FilledButton.icon(
                                            onPressed: startGame,
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text('Jugar'),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Tip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlue.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Tip: primero explora, luego empareja 🧠',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Cómo jugar
                                Card(
                                  elevation: 0,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: ExpansionTile(
                                    initiallyExpanded: false,
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    title: const Text(
                                      'Cómo jugar',
                                      style: TextStyle(fontWeight: FontWeight.w900),
                                      textAlign: TextAlign.center,
                                    ),
                                    subtitle: const Text(
                                      'Reglas rápidas (máximo 2 cartas volteadas)',
                                      textAlign: TextAlign.center,
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    children: [
                                      _howToRow(
                                        icon: Icons.touch_app,
                                        title: 'Voltea cartas',
                                        text: 'Toca una carta para verla. Solo 2 pueden estar volteadas a la vez.',
                                      ),
                                      const SizedBox(height: 10),
                                      _howToRow(
                                        icon: Icons.check_circle_outline,
                                        title: 'Haz parejas',
                                        text: 'Si coinciden, se quedan. Si no, se voltean solas luego de 1 segundo.',
                                      ),
                                      const SizedBox(height: 10),
                                      _howToRow(
                                        icon: Icons.emoji_events,
                                        title: 'Gana',
                                        text: 'Completa las 18 parejas. El récord se mide por intentos y tiempo.',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Historial
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.history),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Historial',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    if (history.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlue.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${history.length}',
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (history.isEmpty)
                                  Card(
                                    elevation: 0,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 54,
                                            height: 54,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(Icons.history, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Aún no hay partidas guardadas.',
                                            style: TextStyle(fontWeight: FontWeight.w900),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Juega una partida y aquí aparecerá tu historial.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey.shade800),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    itemCount: history.length,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final h = history[i];
                                      final player = (h['player'] ?? 'Jugador').toString();
                                      final attempts = (h['attempts'] ?? 0).toString();
                                      final time = (h['time'] ?? 0).toString();
                                      final date = (h['date'] ?? '').toString();
                                      return Card(
                                        elevation: 0,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          leading: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.lightBlue.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Center(
                                              child: Text('🧩', style: TextStyle(fontSize: 22)),
                                            ),
                                          ),
                                          title: Text(
                                            player,
                                            style: const TextStyle(fontWeight: FontWeight.w900),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Intentos: $attempts  •  Tiempo: ${time}s'),
                                                if (date.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      prettyDate(date),
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Icon(Icons.check, size: 18, color: Colors.green),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 18),

                                // Créditos
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Elaborado por: María Victoria Almonte - Luis Mariano Lovera - Sebastián Marval',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _howToRow({required IconData icon, required String title, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.lightBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: Colors.lightBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
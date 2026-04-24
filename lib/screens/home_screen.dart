import 'package:flutter/material.dart';
import 'sport_menu.dart';
import 'cricket.dart';
import 'football.dart';
import 'badminton.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EZZE SPORTS HUB')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Select a Sport", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).primaryColor, letterSpacing: 0.5)),
            const SizedBox(height: 25),

            _buildSportCard(
              context: context, title: "Cricket", icon: Icons.sports_cricket,
              colors: [const Color(0xFF059669), const Color(0xFF10B981)], // Emerald Gradient
              gameScreen: const CricketScreen(),
            ),
            const SizedBox(height: 15),

            _buildSportCard(
              context: context, title: "Football", icon: Icons.sports_soccer,
              colors: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)], // Blue Gradient
              gameScreen: const FootballScreen(),
            ),
            const SizedBox(height: 15),

            _buildSportCard(
              context: context, title: "Badminton", icon: Icons.sports_tennis,
              colors: [const Color(0xFFEA580C), const Color(0xFFF97316)], // Orange Gradient
              gameScreen: const BadmintonScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportCard({required BuildContext context, required String title, required IconData icon, required List<Color> colors, required Widget gameScreen}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: colors.last.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white24,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SportMenuScreen(sportName: title, newGameScreen: gameScreen))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 70, color: Colors.white),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
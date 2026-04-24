// lib/screens/home_screen.dart
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ezze Sports Hub', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select a Sport", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 20),

            // 1. Cricket Card
            _buildSportCard(
              context: context,
              title: "Cricket",
              icon: Icons.sports_cricket,
              color: Colors.green.shade600,
              gameScreen: const CricketScreen(),
            ),
            const SizedBox(height: 15),

            // 2. Football Card
            _buildSportCard(
              context: context,
              title: "Football",
              icon: Icons.sports_soccer,
              color: Colors.blue.shade600,
              gameScreen: const FootballScreen(),
            ),
            const SizedBox(height: 15),

            // 3. Badminton Card
            _buildSportCard(
              context: context,
              title: "Badminton",
              icon: Icons.sports_tennis,
              color: Colors.orange.shade600,
              gameScreen: const BadmintonScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // A reusable function to build beautiful menu cards
  Widget _buildSportCard({required BuildContext context, required String title, required IconData icon, required Color color, required Widget gameScreen}) {
    return Expanded(
      child: Card(
        color: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // This smartly passes the correct Sport and Screen to your SportMenu Hub!
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => SportMenuScreen(sportName: title, newGameScreen: gameScreen)
            ));
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 70, color: Colors.white),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
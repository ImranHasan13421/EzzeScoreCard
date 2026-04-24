// lib/main.dart
import 'package:flutter/material.dart';

// Screens
import 'screens/cricket.dart';
import 'screens/badminton.dart';
import 'screens/football.dart';
import 'screens/sport_menu.dart'; // NEW IMPORT

void main() {
  runApp(const EzzeScoreCardApp());
}

class EzzeScoreCardApp extends StatelessWidget {
  const EzzeScoreCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EzzeScoreCard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('EzzeScoreCard Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modified to route to SportMenuScreen instead of the raw games
            _buildSportCard(
                context,
                'Cricket',
                Icons.sports_cricket,
                const SportMenuScreen(sportName: 'Cricket', newGameScreen: CricketScreen())
            ),
            _buildSportCard(
                context,
                'Badminton',
                Icons.sports_tennis,
                const SportMenuScreen(sportName: 'Badminton', newGameScreen: BadmintonScreen())
            ),
            _buildSportCard(
                context,
                'Football',
                Icons.sports_soccer,
                const SportMenuScreen(sportName: 'Football', newGameScreen: FootballScreen())
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportCard(BuildContext context, String title, IconData icon, Widget destination) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.teal),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
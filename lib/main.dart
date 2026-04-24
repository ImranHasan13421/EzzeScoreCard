// lib/main.dart
import 'package:flutter/material.dart';

// Importing the exact filenames from your structure
import 'screens/cricket.dart';
import 'screens/badminton.dart';
import 'screens/football.dart';

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
        title: const Text('EzzeScoreCard Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSportCard(context, 'Cricket Scorecard', Icons.sports_cricket, const CricketScreen()),
            _buildSportCard(context, 'Badminton Scorecard', Icons.sports_tennis, const BadmintonScreen()),
            _buildSportCard(context, 'Football Scorecard', Icons.sports_soccer, const FootballScreen()),
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
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
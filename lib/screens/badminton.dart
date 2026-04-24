// lib/screens/badminton.dart
import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class BadmintonScreen extends StatefulWidget {
  const BadmintonScreen({super.key});

  @override
  State<BadmintonScreen> createState() => _BadmintonScreenState();
}

class _BadmintonScreenState extends State<BadmintonScreen> {
  int teamA = 0;
  int teamB = 0;

  void _saveMatch() async {
    final match = BadmintonMatch(matchName: "Badminton_Match_${DateTime.now().millisecondsSinceEpoch}", teamAScore: teamA, teamBScore: teamB);
    await FileManager.saveMatchFile('Badminton', match.matchName, match.toJson());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match Saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badminton Score'), actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: _saveMatch),
      ]),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTeamScorer('Team A', teamA, () => setState(() => teamA++), () => setState(() { if (teamA > 0) teamA--; })),
          _buildTeamScorer('Team B', teamB, () => setState(() => teamB++), () => setState(() { if (teamB > 0) teamB--; })),
        ],
      ),
    );
  }

  Widget _buildTeamScorer(String teamName, int score, VoidCallback onAdd, VoidCallback onSub) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(teamName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('$score', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
        Row(
          children: [
            IconButton(onPressed: onSub, icon: const Icon(Icons.remove_circle, size: 40, color: Colors.red)),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle, size: 40, color: Colors.green)),
          ],
        )
      ],
    );
  }
}
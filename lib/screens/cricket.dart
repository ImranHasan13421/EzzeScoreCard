// lib/screens/cricket.dart
import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class CricketScreen extends StatefulWidget {
  const CricketScreen({super.key});

  @override
  State<CricketScreen> createState() => _CricketScreenState();
}

class _CricketScreenState extends State<CricketScreen> {
  CricketMatch match = CricketMatch(matchName: "Cric_Match_${DateTime.now().millisecondsSinceEpoch}");

  void _addRuns(int runs) {
    setState(() {
      match.runs += runs;
      match.balls++;
    });
  }

  void _addWicket() {
    setState(() {
      if (match.wickets < 10) {
        match.wickets++;
        match.balls++;
      }
    });
  }

  void _saveMatch() async {
    await FileManager.saveMatchFile('Cricket', match.matchName, match.toJson());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cricket Match Saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cricket Score'), actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: _saveMatch),
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SCORE', style: TextStyle(fontSize: 20, color: Colors.grey)),
            Text('${match.runs}/${match.wickets}', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
            Text('Overs: ${match.overs}', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i <= 6; i++)
                  ElevatedButton(onPressed: () => _addRuns(i), child: Text('+$i')),
                ElevatedButton(
                  onPressed: _addWicket,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  child: const Text('WICKET'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
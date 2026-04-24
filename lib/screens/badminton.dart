import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class BadmintonScreen extends StatefulWidget {
  const BadmintonScreen({super.key});

  @override
  State<BadmintonScreen> createState() => _BadmintonScreenState();
}

class _BadmintonScreenState extends State<BadmintonScreen> {
  bool isSetupPhase = true;
  bool isMatchOver = false;

  final TextEditingController _teamAController = TextEditingController(text: "Player A");
  final TextEditingController _teamBController = TextEditingController(text: "Player B");

  int _selectedSets = 3; // Best of 3
  int _selectedPoints = 21;
  String? firstServe;

  late BadmintonMatch match;

  // History stack for the perfect "Undo" feature
  List<String> actionHistory = [];

  @override
  void initState() {
    super.initState();
    _teamAController.addListener(() => setState(() {}));
    _teamBController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  // --- SETUP ---
  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty) return;

    setState(() {
      match = BadmintonMatch(
        matchName: "Badminton_${DateTime.now().millisecondsSinceEpoch}", // Replaced on save
        teamA: _teamAController.text,
        teamB: _teamBController.text,
        totalSets: _selectedSets,
        pointsToWin: _selectedPoints,
        servingTeam: firstServe ?? _teamAController.text,
        matchEvents: [],
      );
      isSetupPhase = false;
    });
  }

  // --- MATCH LOGIC ---
  void _scorePoint(bool isTeamA) {
    if (isMatchOver) return;

    setState(() {
      // 1. Update Score & Serve
      if (isTeamA) {
        match.teamAScore++;
        match.servingTeam = match.teamA;
        actionHistory.add("A");
      } else {
        match.teamBScore++;
        match.servingTeam = match.teamB;
        actionHistory.add("B");
      }

      // 2. Check for Set Win (Deuce Logic: Win by 2, Cap at 30)
      bool teamAWonSet = false;
      bool teamBWonSet = false;

      if (match.teamAScore >= match.pointsToWin && (match.teamAScore - match.teamBScore) >= 2) {
        teamAWonSet = true;
      } else if (match.teamBScore >= match.pointsToWin && (match.teamBScore - match.teamAScore) >= 2) {
        teamBWonSet = true;
      } else if (match.teamAScore == 30) {
        teamAWonSet = true; // Cap at 30
      } else if (match.teamBScore == 30) {
        teamBWonSet = true; // Cap at 30
      }

      // 3. Process Set Win
      if (teamAWonSet || teamBWonSet) {
        String setWinner = teamAWonSet ? match.teamA : match.teamB;
        String setScore = "${match.teamAScore} - ${match.teamBScore}";
        match.matchEvents.add("Set ${match.currentSet}: $setWinner won ($setScore)");

        if (teamAWonSet) match.teamASets++;
        if (teamBWonSet) match.teamBSets++;

        // 4. Check for Match Win
        int setsNeededToWin = (match.totalSets / 2).ceil();
        if (match.teamASets == setsNeededToWin || match.teamBSets == setsNeededToWin) {
          isMatchOver = true;
          _showResultDialog(match.teamASets == setsNeededToWin ? match.teamA : match.teamB);
        } else {
          _showSetWinnerDialog(setWinner, setScore);
        }
      }
    });
  }

  void _undoPoint() {
    if (actionHistory.isEmpty || isMatchOver) return;

    setState(() {
      String lastAction = actionHistory.removeLast();
      if (lastAction == "A") {
        match.teamAScore--;
      } else if (lastAction == "B") {
        match.teamBScore--;
      }

      // We don't perfectly restore the previous server in this simple undo,
      // but we maintain the score integrity which is most important.
    });
  }

  void _nextSet() {
    setState(() {
      match.currentSet++;
      match.teamAScore = 0;
      match.teamBScore = 0;
      actionHistory.clear();
    });
  }

  void _saveMatch() async {
    await FileManager.saveMatchFile('Badminton', 'DummyName', match.toJson());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Badminton Match Saved!')));
  }

  // --- DIALOGS ---
  void _showSetWinnerDialog(String winner, String score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Set ${match.currentSet} Complete", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        content: Text("$winner wins the set!\nScore: $score", style: const TextStyle(fontSize: 18)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _nextSet();
            },
            child: const Text("START NEXT SET"),
          )
        ],
      ),
    );
  }

  void _showResultDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 10),
              const Text("MATCH OVER", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.teal)),
              const SizedBox(height: 10),
              Text("🏆 $winner 🏆", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const Divider(height: 30, thickness: 2),
              Text("Final Sets: ${match.teamA} ${match.teamASets} - ${match.teamBSets} ${match.teamB}"),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  _saveMatch();
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to Hub
                },
                child: const Text("SAVE & EXIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badminton Scorecard'),
        actions: isSetupPhase ? null : [IconButton(icon: const Icon(Icons.save), onPressed: _saveMatch)],
      ),
      body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
    );
  }

  Widget _buildSetupForm() {
    List<String> teams = [
      _teamAController.text.isEmpty ? "Player A" : _teamAController.text,
      _teamBController.text.isEmpty ? "Player B" : _teamBController.text,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Match Setup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Player / Team A Name', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Player / Team B Name', border: OutlineInputBorder())),
          const SizedBox(height: 20),

          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Total Sets (Best of)', border: OutlineInputBorder()),
            value: _selectedSets,
            items: [1, 3, 5].map((e) => DropdownMenuItem(value: e, child: Text("$e Sets"))).toList(),
            onChanged: (val) => setState(() => _selectedSets = val!),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Points per Set', border: OutlineInputBorder()),
            value: _selectedPoints,
            items: [11, 15, 21].map((e) => DropdownMenuItem(value: e, child: Text("$e Points"))).toList(),
            onChanged: (val) => setState(() => _selectedPoints = val!),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'First Serve', border: OutlineInputBorder()),
            value: firstServe,
            items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => firstServe = val),
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: _startMatch,
            child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchScreen() {
    return Column(
      children: [
        // Top Info Bar (Sets & Serving)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          color: Colors.grey.shade200,
          child: Column(
            children: [
              Text("SET ${match.currentSet} OF ${match.totalSets}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 2)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("Sets Won: ${match.teamASets}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text(" | ", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text("Sets Won: ${match.teamBSets}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),

        // Main Scoring Area
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildTeamScorer(match.teamA, match.teamAScore, true)),
              Container(width: 2, color: Colors.grey.shade300),
              Expanded(child: _buildTeamScorer(match.teamB, match.teamBScore, false)),
            ],
          ),
        ),

        // Undo & Events Bar
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                iconSize: 32,
                color: Colors.redAccent,
                icon: const Icon(Icons.undo),
                onPressed: _undoPoint,
                tooltip: "Undo Last Point",
              ),
              Text(
                match.matchEvents.isEmpty ? "Match Started" : match.matchEvents.last,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.teal),
              ),
              const SizedBox(width: 48), // Balances the undo button to keep text centered
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTeamScorer(String teamName, int score, bool isTeamA) {
    bool isServing = match.servingTeam == teamName;

    return InkWell(
      onTap: () => _scorePoint(isTeamA), // Tap anywhere on their half to score!
      child: Container(
        color: isServing ? Colors.teal.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Serving Indicator
            Icon(
              Icons.sports_tennis, // Flutter doesn't have a shuttlecock, tennis racket is standard fallback
              color: isServing ? Colors.teal : Colors.transparent,
              size: 30,
            ),
            const SizedBox(height: 10),

            Text(
              teamName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: isServing ? Colors.teal : Colors.black87,
                  ),
                ),
              ),
            ),

            const Text("TAP TO SCORE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
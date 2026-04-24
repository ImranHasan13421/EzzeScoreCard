import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class BadmintonScreen extends StatefulWidget {
  final Map<String, dynamic>? pausedMatchData;
  const BadmintonScreen({super.key, this.pausedMatchData});

  @override
  State<BadmintonScreen> createState() => _BadmintonScreenState();
}

class _BadmintonScreenState extends State<BadmintonScreen> {
  bool isSetupPhase = true; bool isMatchOver = false;
  final TextEditingController _teamAController = TextEditingController(text: "Player A");
  final TextEditingController _teamBController = TextEditingController(text: "Player B");
  int _selectedSets = 3; int _selectedPoints = 21; String? firstServe;
  late BadmintonMatch match; List<String> actionHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.pausedMatchData != null) {
      isSetupPhase = false; var data = widget.pausedMatchData!;
      match = BadmintonMatch(matchName: data['match_name'] ?? '', teamA: data['team_a'] ?? 'Player A', teamB: data['team_b'] ?? 'Player B', totalSets: data['total_sets'] ?? 3, pointsToWin: data['ui_pointsToWin'] ?? 21, matchEvents: List<String>.from(data['match_events'] ?? []));
      match.teamAScore = data['ui_teamAScore'] ?? 0; match.teamBScore = data['ui_teamBScore'] ?? 0; match.teamASets = data['ui_teamASets'] ?? 0; match.teamBSets = data['ui_teamBSets'] ?? 0; match.currentSet = data['ui_currentSet'] ?? 1; match.servingTeam = data['ui_servingTeam'] ?? match.teamA;
      actionHistory = List<String>.from(data['ui_actionHistory'] ?? []); isMatchOver = data['ui_isMatchOver'] ?? false;
    }
    _teamAController.addListener(() => setState(() {})); _teamBController.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _teamAController.dispose(); _teamBController.dispose(); super.dispose(); }

  Future<void> _saveMatchState({required bool isComplete}) async {
    Map<String, dynamic> data = match.toJson();
    data['isComplete'] = isComplete; data['ui_teamAScore'] = match.teamAScore; data['ui_teamBScore'] = match.teamBScore; data['ui_teamASets'] = match.teamASets; data['ui_teamBSets'] = match.teamBSets; data['ui_currentSet'] = match.currentSet; data['ui_servingTeam'] = match.servingTeam; data['ui_actionHistory'] = actionHistory; data['ui_isMatchOver'] = isMatchOver; data['ui_pointsToWin'] = match.pointsToWin;
    if (widget.pausedMatchData != null && widget.pausedMatchData!['file_path'] != null) data['file_path'] = widget.pausedMatchData!['file_path'];
    await FileManager.saveMatchFile('Badminton', data);
  }

  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty) return;
    setState(() { match = BadmintonMatch(matchName: "Bad_${DateTime.now().millisecondsSinceEpoch}", teamA: _teamAController.text, teamB: _teamBController.text, totalSets: _selectedSets, pointsToWin: _selectedPoints, servingTeam: firstServe ?? _teamAController.text, matchEvents: []); isSetupPhase = false; });
  }

  void _scorePoint(bool isTeamA) {
    if (isMatchOver) return;
    setState(() {
      if (isTeamA) { match.teamAScore++; match.servingTeam = match.teamA; actionHistory.add("A"); } else { match.teamBScore++; match.servingTeam = match.teamB; actionHistory.add("B"); }
      bool teamAWonSet = false; bool teamBWonSet = false;
      if (match.teamAScore >= match.pointsToWin && (match.teamAScore - match.teamBScore) >= 2) teamAWonSet = true; else if (match.teamBScore >= match.pointsToWin && (match.teamBScore - match.teamAScore) >= 2) teamBWonSet = true; else if (match.teamAScore == 30) teamAWonSet = true; else if (match.teamBScore == 30) teamBWonSet = true;
      if (teamAWonSet || teamBWonSet) {
        String setWinner = teamAWonSet ? match.teamA : match.teamB; String setScore = "${match.teamAScore} - ${match.teamBScore}";
        match.matchEvents.add("Set ${match.currentSet}: $setWinner won ($setScore)");
        if (teamAWonSet) match.teamASets++; if (teamBWonSet) match.teamBSets++;
        int setsNeededToWin = (match.totalSets / 2).ceil();
        if (match.teamASets == setsNeededToWin || match.teamBSets == setsNeededToWin) { isMatchOver = true; _showResultDialog(match.teamASets == setsNeededToWin ? match.teamA : match.teamB); } else _showSetWinnerDialog(setWinner, setScore);
      }
    });
  }

  void _undoPoint() {
    if (actionHistory.isEmpty || isMatchOver) return;
    setState(() { String lastAction = actionHistory.removeLast(); if (lastAction == "A") match.teamAScore--; else if (lastAction == "B") match.teamBScore--; });
  }

  void _nextSet() { setState(() { match.currentSet++; match.teamAScore = 0; match.teamBScore = 0; actionHistory.clear(); }); }

  void _showSetWinnerDialog(String winner, String score) {
    showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: Text("Set ${match.currentSet} Complete", style: const TextStyle(fontWeight: FontWeight.w900)),
            content: Text("$winner wins the set!\nScore: $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            actions: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // FIX
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () { Navigator.pop(context); _nextSet(); },
                  child: const Text("NEXT SET")
              )
            ]
        )
    );
  }

  void _showResultDialog(String winner) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => Dialog(child: Padding(padding: const EdgeInsets.all(30.0), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.emoji_events, size: 80, color: Color(0xFFF59E0B)), const SizedBox(height: 15), const Text("MATCH OVER", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.5)), const SizedBox(height: 10), Text("🏆 $winner 🏆", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const Divider(height: 30, thickness: 2), Text("Final Sets: ${match.teamA} ${match.teamASets} - ${match.teamBSets} ${match.teamB}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 30), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)), onPressed: () async { await _saveMatchState(isComplete: true); if (mounted) { Navigator.pop(context); Navigator.pop(context); } }, child: const Text("SAVE & EXIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]))));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isSetupPhase || isMatchOver) return true;
        bool? exit = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                title: const Text("Want to quit match?", style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text("Save progress and resume later."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("NO, CONTINUE", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold))
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // FIX
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async { await _saveMatchState(isComplete: false); if (mounted) Navigator.of(context).pop(true); },
                      child: const Text("SAVE & EXIT")
                  )
                ]
            )
        );
        return exit ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // FIX: Completely locks screen from shrinking
        appBar: AppBar(title: const Text('BADMINTON'), actions: isSetupPhase ? null : [IconButton(icon: const Icon(Icons.save), onPressed: () => _saveMatchState(isComplete: false))]),
        body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
      ),
    );
  }

  Widget _buildSetupForm() {
    List<String> teams = [_teamAController.text.isEmpty ? "Player A" : _teamAController.text, _teamBController.text.isEmpty ? "Player B" : _teamBController.text];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Match Setup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))), const SizedBox(height: 20),
          TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Player A Name')), const SizedBox(height: 16),
          TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Player B Name')), const SizedBox(height: 24),
          const Text("Rules & Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))), const SizedBox(height: 16),
          DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Total Sets (Best of)'), value: _selectedSets, items: [1, 3, 5].map((e) => DropdownMenuItem(value: e, child: Text("$e Sets"))).toList(), onChanged: (val) => setState(() => _selectedSets = val!)), const SizedBox(height: 16),
          DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Points per Set'), value: _selectedPoints, items: [11, 15, 21].map((e) => DropdownMenuItem(value: e, child: Text("$e Points"))).toList(), onChanged: (val) => setState(() => _selectedPoints = val!)), const SizedBox(height: 16),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'First Serve'), value: firstServe, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => firstServe = val)), const SizedBox(height: 40),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)), onPressed: _startMatch, child: const Text("START MATCH", style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildMatchScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), color: const Color(0xFF0F172A),
          child: Column(
            children: [
              Text("SET ${match.currentSet} OF ${match.totalSets}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), letterSpacing: 2)), const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ Text("SETS: ${match.teamASets}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)), const Text(" | ", style: TextStyle(fontSize: 20, color: Colors.grey)), Text("SETS: ${match.teamBSets}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)) ]),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildTeamScorer(match.teamA, match.teamAScore, true)),
              Container(width: 4, color: const Color(0xFF0F172A)),
              Expanded(child: _buildTeamScorer(match.teamB, match.teamBScore, false)),
            ],
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(iconSize: 36, color: const Color(0xFFEF4444), icon: const Icon(Icons.undo), onPressed: _undoPoint, tooltip: "Undo"),
                Expanded(child: Text(match.matchEvents.isEmpty ? "Match Started" : match.matchEvents.last, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569), fontSize: 13))),
                const SizedBox(width: 52), // Balance for centering
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTeamScorer(String teamName, int score, bool isTeamA) {
    bool isServing = match.servingTeam == teamName;
    return Material(
      color: isServing ? const Color(0xFFEFF6FF) : Colors.white,
      child: InkWell(
        onTap: () => _scorePoint(isTeamA),
        child: Container(
          decoration: BoxDecoration(border: isServing ? Border.all(color: const Color(0xFF3B82F6), width: 4) : null),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isServing) Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(20)), child: const Text("SERVING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))) else const SizedBox(height: 28),
              const Spacer(),
              Text(teamName.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              FittedBox(fit: BoxFit.scaleDown, child: Text('$score', style: TextStyle(fontSize: 150, fontWeight: FontWeight.w900, color: isServing ? const Color(0xFF2563EB) : const Color(0xFF0F172A), height: 1.1))),
              const Spacer(),
              const Text("TAP TO SCORE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
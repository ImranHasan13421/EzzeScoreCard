import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class FootballScreen extends StatefulWidget {
  final Map<String, dynamic>? pausedMatchData;
  const FootballScreen({super.key, this.pausedMatchData});

  @override
  State<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen> {
  bool isSetupPhase = true;

  final TextEditingController _teamAController = TextEditingController(text: "Team A");
  final TextEditingController _teamBController = TextEditingController(text: "Team B");
  final TextEditingController _timeController = TextEditingController(text: "30");

  String? tossWinner; String? ballWinner; String? barWinner;
  late FootballMatch match;

  final Stopwatch _stopwatch = Stopwatch();
  int _elapsedOffset = 0; Timer? _uiTimer; int matchPhase = 1;
  bool isExtraTime = false; int extraTimeSecondsRemaining = 0; Timer? _extraTimer;

  @override
  void initState() {
    super.initState();
    if (widget.pausedMatchData != null) {
      isSetupPhase = false; var data = widget.pausedMatchData!;
      match = FootballMatch(matchName: data['match_name'] ?? '', teamA: data['team_a'] ?? 'Team A', teamB: data['team_b'] ?? 'Team B', tossWonBy: data['toss_won_by'] ?? 'None', ball: data['ball'] ?? 'None', bar: data['bar'] ?? 'None', totalTimeMinutes: data['total_time_minutes'] ?? 30, teamAEvents: List<String>.from(data['team_a_events'] ?? []), teamBEvents: List<String>.from(data['team_b_events'] ?? []));
      match.teamAGoals = data['team_a_goals'] ?? 0; match.teamBGoals = data['team_b_goals'] ?? 0;
      matchPhase = data['ui_matchPhase'] ?? 1; isExtraTime = data['ui_isExtraTime'] ?? false; extraTimeSecondsRemaining = data['ui_extraTimeSecs'] ?? 0; _elapsedOffset = data['ui_elapsedMillis'] ?? 0;
    }
    _teamAController.addListener(() => setState(() {})); _teamBController.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _teamAController.dispose(); _teamBController.dispose(); _timeController.dispose(); _uiTimer?.cancel(); _extraTimer?.cancel(); super.dispose(); }

  Future<void> _saveMatchState({required bool isComplete}) async {
    match.finalTime = formattedTime; Map<String, dynamic> data = match.toJson();
    data['isComplete'] = isComplete; data['ui_matchPhase'] = matchPhase; data['ui_isExtraTime'] = isExtraTime; data['ui_extraTimeSecs'] = extraTimeSecondsRemaining; data['ui_elapsedMillis'] = _stopwatch.elapsedMilliseconds + _elapsedOffset;
    if (widget.pausedMatchData != null && widget.pausedMatchData!['file_path'] != null) data['file_path'] = widget.pausedMatchData!['file_path'];
    await FileManager.saveMatchFile('Football', data);
  }

  String get formattedTime {
    final int millis = _stopwatch.elapsedMilliseconds + _elapsedOffset;
    final int minutes = (millis ~/ 60000); final int seconds = (millis % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedExtraTime {
    final int minutes = extraTimeSecondsRemaining ~/ 60; final int seconds = extraTimeSecondsRemaining % 60;
    return '+ ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleTimer() {
    if (matchPhase == 3) return;
    if (isExtraTime) { if (_extraTimer?.isActive ?? false) _extraTimer?.cancel(); else _startExtraTimerCountdown(); setState(() {}); return; }
    if (_stopwatch.isRunning) { _stopwatch.stop(); _uiTimer?.cancel(); setState(() {}); }
    else {
      _stopwatch.start();
      _uiTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        int elapsed = _stopwatch.elapsedMilliseconds + _elapsedOffset; int halfMs = (match.totalTimeMinutes * 60 * 1000) ~/ 2; int fullMs = match.totalTimeMinutes * 60 * 1000;
        if (matchPhase == 1 && elapsed >= halfMs) { _stopwatch.stop(); _uiTimer?.cancel(); _promptExtraTime("Half Time Reached"); }
        else if (matchPhase == 2 && elapsed >= fullMs) { _stopwatch.stop(); _uiTimer?.cancel(); _promptExtraTime("Full Time Reached"); }
        setState(() {});
      });
    }
  }

  void _promptExtraTime(String title) {
    showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: const Text("Is additional time required?"),
            actions: [
              TextButton(
                  onPressed: () { Navigator.pop(context); _endPhase(); },
                  child: const Text("NO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // FIX
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () { Navigator.pop(context); _askExtraTimeMinutes(); },
                  child: const Text("YES")
              )
            ]
        )
    );
  }

  void _askExtraTimeMinutes() {
    TextEditingController minController = TextEditingController();
    showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: const Text("Add Extra Time", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(child: TextField(controller: minController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Minutes (e.g., 5)"), autofocus: true)),
            actions: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // FIX
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () { int mins = int.tryParse(minController.text) ?? 0; Navigator.pop(context); if (mins > 0) { setState(() { isExtraTime = true; extraTimeSecondsRemaining = mins * 60; }); _startExtraTimerCountdown(); } else _endPhase(); },
                  child: const Text("START")
              )
            ]
        )
    );
  }

  void _startExtraTimerCountdown() { _extraTimer = Timer.periodic(const Duration(seconds: 1), (timer) { setState(() { if (extraTimeSecondsRemaining > 0) extraTimeSecondsRemaining--; else { timer.cancel(); isExtraTime = false; _endPhase(); } }); }); }

  void _endPhase() { setState(() { if (matchPhase == 1) { matchPhase = 2; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Half Time! Ready for 2nd Half.'))); } else if (matchPhase == 2) { matchPhase = 3; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full Time! Match Over.'))); _showMatchResultDialog(); } }); }

  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || _timeController.text.isEmpty) return;
    setState(() { match = FootballMatch(matchName: "Foot_${DateTime.now().millisecondsSinceEpoch}", teamA: _teamAController.text, teamB: _teamBController.text, tossWonBy: tossWinner ?? "None", ball: ballWinner ?? "None", bar: barWinner ?? "None", totalTimeMinutes: int.parse(_timeController.text), teamAEvents: [], teamBEvents: []); isSetupPhase = false; });
  }

  void _recordGoal(bool isTeamA) {
    final TextEditingController playerController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text("GOAL FOR ${isTeamA ? match.teamA.toUpperCase() : match.teamB.toUpperCase()}!", style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(child: TextField(controller: playerController, decoration: const InputDecoration(labelText: "Scorer Name"), autofocus: true)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), // FIX
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () { if (playerController.text.isNotEmpty) { setState(() { String eventTime = isExtraTime ? "$formattedTime $formattedExtraTime" : formattedTime; if (isTeamA) { match.teamAGoals++; match.teamAEvents.add("⚽ ${playerController.text} ($eventTime)"); } else { match.teamBGoals++; match.teamBEvents.add("⚽ ${playerController.text} ($eventTime)"); } }); Navigator.pop(context); } },
                  child: const Text("OK")
              )
            ]
        )
    );
  }

  void _showCardBottomSheet() {
    String selectedTeam = match.teamA; String selectedCard = "Yellow Card"; final TextEditingController playerController = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
      return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 30), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("ISSUE A CARD", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 20), DropdownButtonFormField<String>(value: selectedTeam, items: [match.teamA, match.teamB].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setSheetState(() => selectedTeam = v!), decoration: const InputDecoration(labelText: "Team")), const SizedBox(height: 16), DropdownButtonFormField<String>(value: selectedCard, items: ["Yellow Card", "Red Card"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setSheetState(() => selectedCard = v!), decoration: const InputDecoration(labelText: "Card Type")), const SizedBox(height: 16), TextField(controller: playerController, decoration: const InputDecoration(labelText: "Player Name")), const SizedBox(height: 30), ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white), onPressed: () { if (playerController.text.isNotEmpty) { setState(() { String icon = selectedCard == "Yellow Card" ? "🟨" : "🟥"; String eventTime = isExtraTime ? "$formattedTime $formattedExtraTime" : formattedTime; String eventText = "$icon ${playerController.text} ($eventTime)"; if (selectedTeam == match.teamA) match.teamAEvents.add(eventText); else match.teamBEvents.add(eventText); }); Navigator.pop(context); } }, child: const Text("SAVE EVENT")), const SizedBox(height: 20)]));
    }));
  }

  void _showMatchResultDialog() {
    String winnerText; Color winnerColor;
    if (match.teamAGoals > match.teamBGoals) { winnerText = "🏆 ${match.teamA} 🏆"; winnerColor = const Color(0xFFF59E0B); } else if (match.teamBGoals > match.teamAGoals) { winnerText = "🏆 ${match.teamB} 🏆"; winnerColor = const Color(0xFFF59E0B); } else { winnerText = "🤝 MATCH DRAW 🤝"; winnerColor = Colors.grey.shade600; }
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) {
      return Dialog(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(winnerColor == const Color(0xFFF59E0B) ? Icons.emoji_events : Icons.handshake, size: 80, color: winnerColor), const SizedBox(height: 15), const Text("FULL TIME", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF0F172A))), const SizedBox(height: 10), Text(winnerText, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900), textAlign: TextAlign.center), const Divider(height: 30, thickness: 2), Text("Final Score: ${match.teamA} ${match.teamAGoals} - ${match.teamBGoals} ${match.teamB}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87), textAlign: TextAlign.center), const SizedBox(height: 30), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)), onPressed: () async { _stopwatch.stop(); _uiTimer?.cancel(); await _saveMatchState(isComplete: true); if (mounted) { Navigator.pop(context); Navigator.pop(context); } }, child: const Text("SAVE & EXIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)))])));
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isSetupPhase || matchPhase == 3) return true;
        bool? exit = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                title: const Text("Want to quit match?", style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text("Your match is still running. Save progress and resume later."),
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
                      onPressed: () async { _stopwatch.stop(); _uiTimer?.cancel(); await _saveMatchState(isComplete: false); if (mounted) Navigator.of(context).pop(true); },
                      child: const Text("SAVE & EXIT")
                  )
                ]
            )
        );
        if (exit == null && !_stopwatch.isRunning && matchPhase != 3) _toggleTimer();
        return exit ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // FIX: Completely locks screen from shrinking to prevent yellow tape
        appBar: AppBar(title: const Text('FOOTBALL'), actions: isSetupPhase ? null : [IconButton(icon: const Icon(Icons.save), onPressed: () => _saveMatchState(isComplete: false))]),
        body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
        floatingActionButton: isSetupPhase || matchPhase == 3 ? null : FloatingActionButton.extended(onPressed: _showCardBottomSheet, backgroundColor: const Color(0xFF0F172A), icon: const Icon(Icons.style, color: Colors.white), label: const Text("CARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildSetupForm() {
    List<String> teams = [_teamAController.text.isEmpty ? "Team A" : _teamAController.text, _teamBController.text.isEmpty ? "Team B" : _teamBController.text];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Match Setup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))), const SizedBox(height: 20),
          TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Team A Name')), const SizedBox(height: 16),
          TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Team B Name')), const SizedBox(height: 16),
          TextField(controller: _timeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Match Time (Minutes)', prefixIcon: Icon(Icons.timer))), const SizedBox(height: 24),
          const Text("Match Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))), const SizedBox(height: 16),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Toss Won By'), value: tossWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => tossWinner = val)), const SizedBox(height: 16),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Ball'), value: ballWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { setState(() { ballWinner = val; barWinner = (val == teams[0]) ? teams[1] : teams[0]; }); }), const SizedBox(height: 16),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Bar'), value: barWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { setState(() { barWinner = val; ballWinner = (val == teams[0]) ? teams[1] : teams[0]; }); }), const SizedBox(height: 40),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)), onPressed: _startMatch, child: const Text("START MATCH", style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildMatchScreen() {
    String phaseText = matchPhase == 1 ? "1ST HALF" : matchPhase == 2 ? "2ND HALF" : "FULL TIME";
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), color: const Color(0xFF0F172A),
          child: Column(
            children: [
              Text(phaseText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), letterSpacing: 2)), const SizedBox(height: 10),
              Text(formattedTime, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.white, height: 1.0)),
              if (isExtraTime) Text(formattedExtraTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              const SizedBox(height: 20),
              if (matchPhase != 3) IconButton(iconSize: 64, icon: Icon((isExtraTime ? _extraTimer?.isActive : _stopwatch.isRunning) ?? false ? Icons.pause_circle_filled : Icons.play_circle_fill), color: (isExtraTime ? _extraTimer?.isActive : _stopwatch.isRunning) ?? false ? const Color(0xFFF59E0B) : const Color(0xFF10B981), onPressed: _toggleTimer),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildTeamScorer(match.teamA, match.teamAGoals, true)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.grey))),
              Expanded(child: _buildTeamScorer(match.teamB, match.teamBGoals, false)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, -2))]),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.all(16.0), child: Text("MATCH LOG", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2))),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ Expanded(child: _buildEventList(match.teamAEvents)), Container(width: 1, color: Colors.grey.shade200), Expanded(child: _buildEventList(match.teamBEvents)) ],
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTeamScorer(String teamName, int goals, bool isTeamA) {
    return Column(
      children: [
        Text(teamName.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text('$goals', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), height: 1.0)),
        const SizedBox(height: 12),
        if (matchPhase != 3) ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), onPressed: () => _recordGoal(isTeamA), child: const Text('⚽ GOAL', style: TextStyle(fontWeight: FontWeight.w900))),
      ],
    );
  }

  Widget _buildEventList(List<String> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), itemCount: events.length,
      itemBuilder: (context, index) { return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(events[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)))); },
    );
  }
}
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

  String? tossWinner;
  String? ballWinner;
  String? barWinner;

  late FootballMatch match;

  final Stopwatch _stopwatch = Stopwatch();
  int _elapsedOffset = 0; // NEW: Solves the Pause/Resume Timer Issue
  Timer? _uiTimer;
  int matchPhase = 1;

  bool isExtraTime = false;
  int extraTimeSecondsRemaining = 0;
  Timer? _extraTimer;

  @override
  void initState() {
    super.initState();

    // --- RESUME MATCH LOGIC ---
    if (widget.pausedMatchData != null) {
      isSetupPhase = false;
      var data = widget.pausedMatchData!;

      match = FootballMatch(
        matchName: data['match_name'] ?? '',
        teamA: data['team_a'] ?? 'Team A',
        teamB: data['team_b'] ?? 'Team B',
        tossWonBy: data['toss_won_by'] ?? 'None',
        ball: data['ball'] ?? 'None',
        bar: data['bar'] ?? 'None',
        totalTimeMinutes: data['total_time_minutes'] ?? 30,
        teamAEvents: List<String>.from(data['team_a_events'] ?? []),
        teamBEvents: List<String>.from(data['team_b_events'] ?? []),
      );
      match.teamAGoals = data['team_a_goals'] ?? 0;
      match.teamBGoals = data['team_b_goals'] ?? 0;

      // Restore the UI state and Timer offsets
      matchPhase = data['ui_matchPhase'] ?? 1;
      isExtraTime = data['ui_isExtraTime'] ?? false;
      extraTimeSecondsRemaining = data['ui_extraTimeSecs'] ?? 0;
      _elapsedOffset = data['ui_elapsedMillis'] ?? 0; // Loads the frozen time!
    }

    _teamAController.addListener(() => setState(() {}));
    _teamBController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _timeController.dispose();
    _uiTimer?.cancel();
    _extraTimer?.cancel();
    super.dispose();
  }

  // --- CORE SAVE METHOD ---
  Future<void> _saveMatchState({required bool isComplete}) async {
    match.finalTime = formattedTime;
    Map<String, dynamic> data = match.toJson();
    data['isComplete'] = isComplete;

    // Save UI & Timer states
    data['ui_matchPhase'] = matchPhase;
    data['ui_isExtraTime'] = isExtraTime;
    data['ui_extraTimeSecs'] = extraTimeSecondsRemaining;
    data['ui_elapsedMillis'] = _stopwatch.elapsedMilliseconds + _elapsedOffset;

    if (widget.pausedMatchData != null && widget.pausedMatchData!['file_path'] != null) {
      data['file_path'] = widget.pausedMatchData!['file_path'];
    }

    await FileManager.saveMatchFile('Football', data);
  }

  // Uses the _elapsedOffset to pick up right where it left off
  String get formattedTime {
    final int millis = _stopwatch.elapsedMilliseconds + _elapsedOffset;
    final int minutes = (millis ~/ 60000);
    final int seconds = (millis % 60000) ~/ 1000;
    final int hundreds = (millis % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${hundreds.toString().padLeft(2, '0')}';
  }

  String get formattedExtraTime {
    final int minutes = extraTimeSecondsRemaining ~/ 60;
    final int seconds = extraTimeSecondsRemaining % 60;
    return '+ ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleTimer() {
    if (matchPhase == 3) return;

    if (isExtraTime) {
      if (_extraTimer?.isActive ?? false) _extraTimer?.cancel();
      else _startExtraTimerCountdown();
      setState(() {});
      return;
    }

    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _uiTimer?.cancel();
      setState(() {});
    } else {
      _stopwatch.start();
      _uiTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        int elapsed = _stopwatch.elapsedMilliseconds + _elapsedOffset;
        int halfMs = (match.totalTimeMinutes * 60 * 1000) ~/ 2;
        int fullMs = match.totalTimeMinutes * 60 * 1000;

        if (matchPhase == 1 && elapsed >= halfMs) {
          _stopwatch.stop(); _uiTimer?.cancel(); _promptExtraTime("Half Time Reached");
        }
        else if (matchPhase == 2 && elapsed >= fullMs) {
          _stopwatch.stop(); _uiTimer?.cancel(); _promptExtraTime("Full Time Reached");
        }
        setState(() {});
      });
    }
  }

  void _promptExtraTime(String title) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Is additional time required?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _endPhase(); }, child: const Text("NO")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), onPressed: () { Navigator.pop(context); _askExtraTimeMinutes(); }, child: const Text("YES")),
        ],
      ),
    );
  }

  void _askExtraTimeMinutes() {
    TextEditingController minController = TextEditingController();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Add Extra Time"),
        content: TextField(controller: minController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Minutes (e.g., 5)", border: OutlineInputBorder()), autofocus: true),
        actions: [
          ElevatedButton(
            onPressed: () {
              int mins = int.tryParse(minController.text) ?? 0;
              Navigator.pop(context);
              if (mins > 0) {
                setState(() { isExtraTime = true; extraTimeSecondsRemaining = mins * 60; });
                _startExtraTimerCountdown();
              } else _endPhase();
            },
            child: const Text("START REVERSE TIMER"),
          )
        ],
      ),
    );
  }

  void _startExtraTimerCountdown() {
    _extraTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (extraTimeSecondsRemaining > 0) extraTimeSecondsRemaining--;
        else { timer.cancel(); isExtraTime = false; _endPhase(); }
      });
    });
  }

  void _endPhase() {
    setState(() {
      if (matchPhase == 1) {
        matchPhase = 2;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Half Time! Ready for 2nd Half.')));
      } else if (matchPhase == 2) {
        matchPhase = 3;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full Time! Match Over.')));
        _showMatchResultDialog();
      }
    });
  }

  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || _timeController.text.isEmpty) return;
    setState(() {
      match = FootballMatch(
        matchName: "Foot_${DateTime.now().millisecondsSinceEpoch}",
        teamA: _teamAController.text, teamB: _teamBController.text,
        tossWonBy: tossWinner ?? "None", ball: ballWinner ?? "None", bar: barWinner ?? "None",
        totalTimeMinutes: int.parse(_timeController.text),
        teamAEvents: [], teamBEvents: [],
      );
      isSetupPhase = false;
    });
  }

  void _recordGoal(bool isTeamA) {
    final TextEditingController playerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Goal Scorer (${isTeamA ? match.teamA : match.teamB})"),
        content: TextField(controller: playerController, decoration: const InputDecoration(hintText: "Enter Player Name", border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (playerController.text.isNotEmpty) {
                setState(() {
                  String eventTime = isExtraTime ? "$formattedTime $formattedExtraTime" : formattedTime;
                  if (isTeamA) { match.teamAGoals++; match.teamAEvents.add("⚽ ${playerController.text} ($eventTime)"); }
                  else { match.teamBGoals++; match.teamBEvents.add("⚽ ${playerController.text} ($eventTime)"); }
                });
                Navigator.pop(context);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showCardBottomSheet() {
    String selectedTeam = match.teamA; String selectedCard = "Yellow Card";
    final TextEditingController playerController = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Issue a Card", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: selectedTeam, items: [match.teamA, match.teamB].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setSheetState(() => selectedTeam = v!), decoration: const InputDecoration(labelText: "Team")), const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: selectedCard, items: ["Yellow Card", "Red Card"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setSheetState(() => selectedCard = v!), decoration: const InputDecoration(labelText: "Card Type")), const SizedBox(height: 10),
                TextField(controller: playerController, decoration: const InputDecoration(labelText: "Player Name")), const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (playerController.text.isNotEmpty) {
                      setState(() {
                        String icon = selectedCard == "Yellow Card" ? "🟨" : "🟥";
                        String eventTime = isExtraTime ? "$formattedTime $formattedExtraTime" : formattedTime;
                        String eventText = "$icon ${playerController.text} ($eventTime)";
                        if (selectedTeam == match.teamA) match.teamAEvents.add(eventText);
                        else match.teamBEvents.add(eventText);
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save Event"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMatchResultDialog() {
    String winnerText; Color winnerColor;
    if (match.teamAGoals > match.teamBGoals) { winnerText = "🏆 ${match.teamA} 🏆"; winnerColor = Colors.amber; }
    else if (match.teamBGoals > match.teamAGoals) { winnerText = "🏆 ${match.teamB} 🏆"; winnerColor = Colors.amber; }
    else { winnerText = "🤝 MATCH DRAW 🤝"; winnerColor = Colors.orange.shade400; }

    showDialog(
      context: context, barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), elevation: 10, backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(winnerColor == Colors.amber ? Icons.emoji_events : Icons.handshake, size: 80, color: winnerColor),
                const SizedBox(height: 10),
                const Text("FULL TIME", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.teal)),
                const SizedBox(height: 10),
                Text(winnerText, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const Divider(height: 30, thickness: 2),
                Text("Final Score: ${match.teamA} ${match.teamAGoals} - ${match.teamBGoals} ${match.teamB}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                const Text("MATCH DETAILS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: match.teamAEvents.isEmpty ? [const Text("No events", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))] : match.teamAEvents.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList())),
                        Container(height: 80, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 10)),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: match.teamBEvents.isEmpty ? [const Text("No events", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))] : match.teamBEvents.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList())),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 3),
                  onPressed: () async {
                    _stopwatch.stop(); _uiTimer?.cancel();
                    await _saveMatchState(isComplete: true); // FINISH MATCH!
                    if (mounted) { Navigator.pop(context); Navigator.pop(context); }
                  },
                  child: const Text("SAVE & EXIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                )
              ],
            ),
          ),
        );
      },
    );
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
              content: const Text("Your match is still running. You can save your progress and resume later from the History screen."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("NO, CONTINUE GAME", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    _stopwatch.stop(); _uiTimer?.cancel();
                    await _saveMatchState(isComplete: false); // SAVE PAUSED!
                    if (mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text("SAVE PROGRESS & EXIT"),
                )
              ],
            )
        );
        // If they click outside the box, resume the timer if it was running
        if (exit == null && !_stopwatch.isRunning && matchPhase != 3) {
          _toggleTimer();
        }
        return exit ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Football Scorecard'),
          actions: isSetupPhase ? null : [IconButton(icon: const Icon(Icons.save), onPressed: () => _saveMatchState(isComplete: false))],
        ),
        body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
        floatingActionButton: isSetupPhase || matchPhase == 3
            ? null
            : FloatingActionButton(onPressed: _showCardBottomSheet, backgroundColor: Colors.teal, child: const Icon(Icons.style, color: Colors.white)),
      ),
    );
  }

  Widget _buildSetupForm() {
    List<String> teams = [_teamAController.text.isEmpty ? "Team A" : _teamAController.text, _teamBController.text.isEmpty ? "Team B" : _teamBController.text];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Match Setup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
          TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Team A Name', border: OutlineInputBorder())), const SizedBox(height: 15),
          TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Team B Name', border: OutlineInputBorder())), const SizedBox(height: 15),
          TextField(controller: _timeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Match Time (Minutes)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer))), const SizedBox(height: 20),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Toss Won By', border: OutlineInputBorder()), value: tossWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => tossWinner = val)), const SizedBox(height: 15),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Ball', border: OutlineInputBorder()), value: ballWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { setState(() { ballWinner = val; barWinner = (val == teams[0]) ? teams[1] : teams[0]; }); }), const SizedBox(height: 15),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Bar', border: OutlineInputBorder()), value: barWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { setState(() { barWinner = val; ballWinner = (val == teams[0]) ? teams[1] : teams[0]; }); }), const SizedBox(height: 30),
          ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.teal, foregroundColor: Colors.white), onPressed: _startMatch, child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildMatchScreen() {
    String phaseText = matchPhase == 1 ? "1st Half" : matchPhase == 2 ? "2nd Half" : "Full Time";
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10), color: Colors.grey.shade200,
          child: Column(
            children: [
              Text(phaseText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              FittedBox(fit: BoxFit.scaleDown, child: Text(formattedTime, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
              if (isExtraTime) Text(formattedExtraTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              if (matchPhase != 3)
                IconButton(iconSize: 50, icon: Icon((isExtraTime ? _extraTimer?.isActive : _stopwatch.isRunning) ?? false ? Icons.pause_circle_filled : Icons.play_circle_fill), color: (isExtraTime ? _extraTimer?.isActive : _stopwatch.isRunning) ?? false ? Colors.red : Colors.green, onPressed: _toggleTimer),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _buildTeamScorer(match.teamA, match.teamAGoals, true)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0), child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey))),
              Expanded(child: _buildTeamScorer(match.teamB, match.teamBGoals, false)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildEventList(match.teamAEvents)),
              const VerticalDivider(),
              Expanded(child: _buildEventList(match.teamBEvents)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTeamScorer(String teamName, int goals, bool isTeamA) {
    return Column(
      children: [
        Text(teamName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        FittedBox(fit: BoxFit.scaleDown, child: Text('$goals', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold))),
        if (matchPhase != 3) ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), onPressed: () => _recordGoal(isTeamA), child: const Text('⚽ GOAL')),
      ],
    );
  }

  Widget _buildEventList(List<String> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0), itemCount: events.length,
      itemBuilder: (context, index) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(events[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))); },
    );
  }
}
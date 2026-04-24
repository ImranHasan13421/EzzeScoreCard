import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class FootballScreen extends StatefulWidget {
  const FootballScreen({super.key});

  @override
  State<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen> {
  // Phase Control
  bool isSetupPhase = true;

  // Form Controllers
  final TextEditingController _teamAController = TextEditingController(text: "Team A");
  final TextEditingController _teamBController = TextEditingController(text: "Team B");
  final TextEditingController _timeController = TextEditingController(text: "30"); // Default 30 mins

  String? tossWinner;
  String? ballWinner;
  String? barWinner;

  // Match State
  late FootballMatch match;

  // Timer & Match Flow Variables
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  int matchPhase = 1; // 1 = First Half, 2 = Second Half, 3 = Full Time

  // Extra Time Variables
  bool isExtraTime = false;
  int extraTimeSecondsRemaining = 0;
  Timer? _extraTimer;

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
    _timeController.dispose();
    _uiTimer?.cancel();
    _extraTimer?.cancel();
    super.dispose();
  }

  // --- TIMER FORMATTING ---
  String get formattedTime {
    final int millis = _stopwatch.elapsedMilliseconds;
    final int minutes = (millis ~/ 60000);
    final int seconds = (millis % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedExtraTime {
    final int minutes = extraTimeSecondsRemaining ~/ 60;
    final int seconds = extraTimeSecondsRemaining % 60;
    return '+ ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- TIMER LOGIC ---
  void _toggleTimer() {
    if (matchPhase == 3) return; // Match is completely over

    // If Extra Time is currently running, toggle the countdown timer instead
    if (isExtraTime) {
      if (_extraTimer?.isActive ?? false) {
        _extraTimer?.cancel();
      } else {
        _startExtraTimerCountdown();
      }
      setState(() {});
      return;
    }

    // Regular time toggle
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _uiTimer?.cancel();
      setState(() {});
    } else {
      _stopwatch.start();
      _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        int elapsed = _stopwatch.elapsedMilliseconds;
        int halfMs = (match.totalTimeMinutes * 60 * 1000) ~/ 2;
        int fullMs = match.totalTimeMinutes * 60 * 1000;

        // Check if Half-Time is reached
        if (matchPhase == 1 && elapsed >= halfMs) {
          _stopwatch.stop();
          _uiTimer?.cancel();
          _promptExtraTime("Half Time Reached");
        }
        // Check if Full-Time is reached
        else if (matchPhase == 2 && elapsed >= fullMs) {
          _stopwatch.stop();
          _uiTimer?.cancel();
          _promptExtraTime("Full Time Reached");
        }
        setState(() {});
      });
    }
  }

  // --- EXTRA TIME DIALOGS & LOGIC ---
  void _promptExtraTime(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Is additional time required?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endPhase(); // No extra time, just end the half
            },
            child: const Text("NO"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _askExtraTimeMinutes();
            },
            child: const Text("YES"),
          ),
        ],
      ),
    );
  }

  void _askExtraTimeMinutes() {
    TextEditingController minController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Add Extra Time"),
        content: TextField(
          controller: minController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Minutes (e.g., 5)", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              int mins = int.tryParse(minController.text) ?? 0;
              Navigator.pop(context);
              if (mins > 0) {
                setState(() {
                  isExtraTime = true;
                  extraTimeSecondsRemaining = mins * 60;
                });
                _startExtraTimerCountdown();
              } else {
                _endPhase();
              }
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
        if (extraTimeSecondsRemaining > 0) {
          extraTimeSecondsRemaining--;
        } else {
          // Extra time is finished!
          timer.cancel();
          isExtraTime = false;
          _endPhase();
        }
      });
    });
  }

  void _endPhase() {
    setState(() {
      if (matchPhase == 1) {
        matchPhase = 2; // Move to 2nd Half
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Half Time! Ready for 2nd Half.')));
      } else if (matchPhase == 2) {
        matchPhase = 3; // Match is Over
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full Time! Match Over.')));
      }
    });
  }


  // --- SETUP FORM ACTIONS ---
  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || _timeController.text.isEmpty) return;

    setState(() {
      match = FootballMatch(
        matchName: "Foot_${_teamAController.text}_vs_${_teamBController.text}_${DateTime.now().millisecondsSinceEpoch}",
        teamA: _teamAController.text,
        teamB: _teamBController.text,
        tossWonBy: tossWinner ?? "None",
        ball: ballWinner ?? "None",
        bar: barWinner ?? "None",
        totalTimeMinutes: int.parse(_timeController.text),
        teamAEvents: [],
        teamBEvents: [],
      );
      isSetupPhase = false;
    });
  }

  // --- MATCH ACTIONS ---
  void _saveMatch() async {
    match.finalTime = formattedTime;
    await FileManager.saveMatchFile('Football', match.matchName, match.toJson());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Football Match Saved!')));
  }

  void _promptPlayerName(String title, Function(String) onSave) {
    final TextEditingController playerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: playerController,
          decoration: const InputDecoration(hintText: "Enter Player Name", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (playerController.text.isNotEmpty) {
                onSave(playerController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _recordGoal(bool isTeamA) {
    _promptPlayerName("Goal Scorer (${isTeamA ? match.teamA : match.teamB})", (playerName) {
      setState(() {
        String eventTime = isExtraTime ? "$formattedTime $formattedExtraTime" : formattedTime;
        if (isTeamA) {
          match.teamAGoals++;
          match.teamAEvents.add("⚽ $playerName ($eventTime)");
        } else {
          match.teamBGoals++;
          match.teamBEvents.add("⚽ $playerName ($eventTime)");
        }
      });
    });
  }

  void _showCardBottomSheet() {
    String selectedTeam = match.teamA;
    String selectedCard = "Yellow Card";
    final TextEditingController playerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Issue a Card", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  items: [match.teamA, match.teamB].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setSheetState(() => selectedTeam = v!),
                  decoration: const InputDecoration(labelText: "Team"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCard,
                  items: ["Yellow Card", "Red Card"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setSheetState(() => selectedCard = v!),
                  decoration: const InputDecoration(labelText: "Card Type"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: playerController,
                  decoration: const InputDecoration(labelText: "Player Name"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (playerController.text.isNotEmpty) {
                      setState(() {
                        String icon = selectedCard == "Yellow Card" ? "🟨" : "🟥";
                        String eventTime = isExtraTime ? "$formattedTime $formattedExtraTime" : formattedTime;
                        String eventText = "$icon ${playerController.text} ($eventTime)";

                        if (selectedTeam == match.teamA) {
                          match.teamAEvents.add(eventText);
                        } else {
                          match.teamBEvents.add(eventText);
                        }
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

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Scorecard'),
        actions: isSetupPhase ? null : [IconButton(icon: const Icon(Icons.save), onPressed: _saveMatch)],
      ),
      body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
      floatingActionButton: isSetupPhase || matchPhase == 3
          ? null
          : FloatingActionButton(
        onPressed: _showCardBottomSheet,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.style, color: Colors.white),
      ),
    );
  }

  Widget _buildSetupForm() {
    List<String> teams = [
      _teamAController.text.isEmpty ? "Team A" : _teamAController.text,
      _teamBController.text.isEmpty ? "Team B" : _teamBController.text,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Match Setup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Team A Name', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Team B Name', border: OutlineInputBorder())),
          const SizedBox(height: 15),

          // NEW: Time input field
          TextField(
            controller: _timeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Total Match Time (Minutes)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer)),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Toss Won By', border: OutlineInputBorder()),
            value: tossWinner,
            items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => tossWinner = val),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Ball', border: OutlineInputBorder()),
            value: ballWinner,
            items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              setState(() {
                ballWinner = val;
                barWinner = (val == teams[0]) ? teams[1] : teams[0];
              });
            },
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Bar', border: OutlineInputBorder()),
            value: barWinner,
            items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              setState(() {
                barWinner = val;
                ballWinner = (val == teams[0]) ? teams[1] : teams[0];
              });
            },
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
    String phaseText = matchPhase == 1 ? "1st Half" : matchPhase == 2 ? "2nd Half" : "Full Time";

    return Column(
      children: [
        // Top Timer Module
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: Colors.grey.shade200,
          child: Column(
            children: [
              Text(phaseText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),

              // Standard Clock (Paused exactly at Half-time if Extra Time is running)
              Text(formattedTime, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, fontFamily: 'monospace')),

              // Extra Time Countdown (Appears underneath when active)
              if (isExtraTime)
                Text(formattedExtraTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),

              const SizedBox(height: 10),
              if (matchPhase != 3) // Hide button if match is fully over
                IconButton(
                  iconSize: 50,
                  icon: Icon((isExtraTime ? _extraTimer?.isActive : _stopwatch.isRunning) ?? false
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill),
                  color: (isExtraTime ? _extraTimer?.isActive : _stopwatch.isRunning) ?? false ? Colors.red : Colors.green,
                  onPressed: _toggleTimer,
                ),
            ],
          ),
        ),

        // Score Board
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamScorer(match.teamA, match.teamAGoals, true),
              const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
              _buildTeamScorer(match.teamB, match.teamBGoals, false),
            ],
          ),
        ),
        const Divider(),

        // Events List
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
        Text(teamName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$goals', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
        if (matchPhase != 3) // Disable goals after full time
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => _recordGoal(isTeamA),
            child: const Text('⚽ GOAL'),
          ),
      ],
    );
  }

  Widget _buildEventList(List<String> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(events[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        );
      },
    );
  }
}
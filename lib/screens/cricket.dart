import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class CricketScreen extends StatefulWidget {
  final Map<String, dynamic>? pausedMatchData;
  const CricketScreen({super.key, this.pausedMatchData});

  @override
  State<CricketScreen> createState() => _CricketScreenState();
}

class _CricketScreenState extends State<CricketScreen> {
  bool isSetupPhase = true;

  final _teamAController = TextEditingController(text: "Team A");
  final _teamBController = TextEditingController(text: "Team B");
  final _oversController = TextEditingController(text: "20");
  final _playersController = TextEditingController(text: "11");
  final _umpire1Controller = TextEditingController(text: "Umpire 1");
  final _umpire2Controller = TextEditingController(text: "Umpire 2");

  String? tossWinner;
  String? optDecision;

  late CricketMatch match;

  String striker = "Striker";
  String nonStriker = "Non-Striker";
  String currentBowler = "Bowler";
  List<String> currentOverTimeline = [];

  @override
  void initState() {
    super.initState();

    // --- RESUME MATCH LOGIC ---
    if (widget.pausedMatchData != null) {
      isSetupPhase = false;
      var data = widget.pausedMatchData!;

      // Reconstruct Match Model
      match = CricketMatch(
        matchName: data['match_name'] ?? '',
        teamA: data['team_a'] ?? '',
        teamB: data['team_b'] ?? '',
        totalOvers: data['total_overs'] ?? 20,
        playersPerTeam: data['players_per_team'] ?? 11,
      );
      match.currentInnings = data['current_innings'] ?? 1;
      match.matchResult = data['match_result'] ?? '';

      var in1 = data['innings_1'] ?? {};
      match.battingTeam1 = in1['team'] ?? '';
      match.runs1 = in1['runs'] ?? 0;
      match.wickets1 = in1['wickets'] ?? 0;
      match.balls1 = in1['balls'] ?? 0;
      match.events1 = List<String>.from(in1['events'] ?? []);

      var in2 = data['innings_2'] ?? {};
      match.battingTeam2 = in2['team'] ?? '';
      match.runs2 = in2['runs'] ?? 0;
      match.wickets2 = in2['wickets'] ?? 0;
      match.balls2 = in2['balls'] ?? 0;
      match.events2 = List<String>.from(in2['events'] ?? []);

      // Restore UI State
      striker = data['ui_striker'] ?? "Striker";
      nonStriker = data['ui_nonStriker'] ?? "Non-Striker";
      currentBowler = data['ui_bowler'] ?? "Bowler";
      currentOverTimeline = List<String>.from(data['ui_timeline'] ?? []);
    }

    _teamAController.addListener(() => setState(() {}));
    _teamBController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _oversController.dispose();
    _playersController.dispose();
    _umpire1Controller.dispose();
    _umpire2Controller.dispose();
    super.dispose();
  }

  // --- CORE SAVE METHOD ---
  Future<void> _saveMatchState({required bool isComplete}) async {
    Map<String, dynamic> data = match.toJson();
    data['isComplete'] = isComplete;
    data['current_innings'] = match.currentInnings;

    // Inject UI Variables into the JSON
    data['ui_striker'] = striker;
    data['ui_nonStriker'] = nonStriker;
    data['ui_bowler'] = currentBowler;
    data['ui_timeline'] = currentOverTimeline;

    // Preserve existing file path if we are resuming
    if (widget.pausedMatchData != null && widget.pausedMatchData!['file_path'] != null) {
      data['file_path'] = widget.pausedMatchData!['file_path'];
    }

    await FileManager.saveMatchFile('Cricket', data);
  }

  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || tossWinner == null || optDecision == null) return;
    setState(() {
      String battingFirst = (tossWinner == _teamAController.text && optDecision == "Bat") || (tossWinner != _teamAController.text && optDecision == "Bowl") ? _teamAController.text : _teamBController.text;
      String bowlingFirst = battingFirst == _teamAController.text ? _teamBController.text : _teamAController.text;

      match = CricketMatch(
        matchName: "Cric_${_teamAController.text}_vs_${_teamBController.text}_${DateTime.now().millisecondsSinceEpoch}",
        teamA: _teamAController.text, teamB: _teamBController.text,
        totalOvers: int.tryParse(_oversController.text) ?? 20, playersPerTeam: int.tryParse(_playersController.text) ?? 11,
        umpire1: _umpire1Controller.text, umpire2: _umpire2Controller.text,
        tossWinner: tossWinner!, optDecision: optDecision!,
        battingTeam1: battingFirst, battingTeam2: bowlingFirst,
        events1: [], events2: [],
      );
      isSetupPhase = false;
    });
    _promptNewPlayers(isInningsStart: true);
  }

  bool _addDelivery({required int runsOffBat, int extraRuns = 0, String extraType = "", bool isWicket = false, String wicketType = ""}) {
    if (match.matchResult.isNotEmpty) return true;
    bool statusChanged = false;

    setState(() {
      int totalRunsOnBall = runsOffBat + extraRuns;
      bool isLegalDelivery = extraType != "WD" && extraType != "NB";
      String eventText = "";

      if (match.currentInnings == 1) {
        match.runs1 += totalRunsOnBall;
        if (isLegalDelivery) match.balls1++;
        if (isWicket) match.wickets1++;
      } else {
        match.runs2 += totalRunsOnBall;
        if (isLegalDelivery) match.balls2++;
        if (isWicket) match.wickets2++;
      }

      if (isWicket) eventText = "W";
      else if (extraType.isNotEmpty) eventText = extraType == "WD" || extraType == "NB" ? "$totalRunsOnBall$extraType" : "$extraRuns$extraType";
      else eventText = runsOffBat == 0 ? "•" : "$runsOffBat";

      currentOverTimeline.add(eventText);

      if (runsOffBat % 2 != 0 || (extraRuns > 1 && extraRuns % 2 == 0) || (extraType == "B" || extraType == "LB") && extraRuns % 2 != 0) _rotateStrike();

      statusChanged = _checkInningsStatus();

      int currentBalls = match.currentInnings == 1 ? match.balls1 : match.balls2;
      if (isLegalDelivery && currentBalls % 6 == 0 && currentBalls > 0) {
        _rotateStrike();
        currentOverTimeline.clear();
        if (!statusChanged) _promptNewBowler();
      }
    });
    return statusChanged;
  }

  void _rotateStrike() { String temp = striker; striker = nonStriker; nonStriker = temp; }

  bool _checkInningsStatus() {
    int currentRuns = match.currentInnings == 1 ? match.runs1 : match.runs2;
    int currentWickets = match.currentInnings == 1 ? match.wickets1 : match.wickets2;
    int currentBalls = match.currentInnings == 1 ? match.balls1 : match.balls2;
    int maxBalls = match.totalOvers * 6;
    int allOutWickets = match.playersPerTeam - 1;

    if (match.currentInnings == 1) {
      if (currentWickets >= allOutWickets || currentBalls >= maxBalls) {
        _showInningsBreakDialog();
        return true;
      }
    } else if (match.currentInnings == 2) {
      if (currentRuns > match.runs1) {
        match.matchResult = "${match.battingTeam2} won by ${allOutWickets - currentWickets} wickets";
        _showMatchResultDialog();
        return true;
      } else if (currentWickets >= allOutWickets || currentBalls >= maxBalls) {
        match.matchResult = currentRuns == match.runs1 ? "Match Tied" : "${match.battingTeam1} won by ${match.runs1 - currentRuns} runs";
        _showMatchResultDialog();
        return true;
      }
    }
    return false;
  }

  void _promptNewPlayers({bool isInningsStart = true}) {
    TextEditingController strikerCtrl = TextEditingController();
    TextEditingController nonStrikerCtrl = TextEditingController();
    TextEditingController bowlerCtrl = TextEditingController();

    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isInningsStart ? "Start of Innings" : "New Players"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: strikerCtrl, decoration: const InputDecoration(labelText: "Striker Name")),
              if (isInningsStart) TextField(controller: nonStrikerCtrl, decoration: const InputDecoration(labelText: "Non-Striker Name")),
              if (isInningsStart) TextField(controller: bowlerCtrl, decoration: const InputDecoration(labelText: "Opening Bowler Name")),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (strikerCtrl.text.isNotEmpty) striker = strikerCtrl.text;
                if (isInningsStart && nonStrikerCtrl.text.isNotEmpty) nonStriker = nonStrikerCtrl.text;
                if (isInningsStart && bowlerCtrl.text.isNotEmpty) currentBowler = bowlerCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text("PLAY"),
          )
        ],
      ),
    );
  }

  void _promptNewBatsman(String outgoingPlayerName) {
    TextEditingController newBatCtrl = TextEditingController();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("New Batsman"),
        content: SingleChildScrollView(child: TextField(controller: newBatCtrl, decoration: const InputDecoration(labelText: "Batsman Name"), autofocus: true)),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (newBatCtrl.text.isNotEmpty) {
                setState(() {
                  if (striker == outgoingPlayerName) striker = newBatCtrl.text;
                  else if (nonStriker == outgoingPlayerName) nonStriker = newBatCtrl.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("PLAY"),
          )
        ],
      ),
    );
  }

  void _promptNewBowler() {
    TextEditingController bowlerCtrl = TextEditingController();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("End of Over"),
        content: SingleChildScrollView(child: TextField(controller: bowlerCtrl, decoration: const InputDecoration(labelText: "New Bowler Name"), autofocus: true)),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (bowlerCtrl.text.isNotEmpty) {
                setState(() => currentBowler = bowlerCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("CONFIRM"),
          )
        ],
      ),
    );
  }

  void _showExtraDialog(String extraType) {
    int extraRunsScored = extraType == "WD" || extraType == "NB" ? 1 : 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add $extraType"),
        content: const Text("Did the batsmen run any additional runs off this extra?"),
        actions: [
          for (int i = 0; i <= 4; i++)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addDelivery(runsOffBat: 0, extraRuns: extraRunsScored + i, extraType: extraType);
              },
              child: Text("+$i"),
            )
        ],
      ),
    );
  }

  void _showWicketDialog() {
    String selectedOut = "Bowled";
    String selectedPlayerOut = striker;
    int runsCompleted = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            return AlertDialog(
              title: const Text("Wicket Fall!"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedOut,
                      items: ["Bowled", "Caught", "LBW", "Run Out", "Stumped", "Hit Wicket"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setSheetState(() {
                        selectedOut = v!;
                        if (selectedOut != "Run Out") { selectedPlayerOut = striker; runsCompleted = 0; }
                      }),
                      decoration: const InputDecoration(labelText: "Dismissal Type"),
                    ),
                    if (selectedOut == "Run Out") ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedPlayerOut,
                        items: [striker, nonStriker].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setSheetState(() => selectedPlayerOut = v!),
                        decoration: const InputDecoration(labelText: "Who got out?"),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: runsCompleted,
                        items: [0, 1, 2, 3].map((e) => DropdownMenuItem(value: e, child: Text("$e Runs Completed"))).toList(),
                        onChanged: (v) => setSheetState(() => runsCompleted = v!),
                        decoration: const InputDecoration(labelText: "Runs before Run Out"),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    String playerWhoGotOut = selectedOut == "Run Out" ? selectedPlayerOut : striker;
                    bool isStatusChanged = _addDelivery(runsOffBat: runsCompleted, isWicket: true, wicketType: selectedOut);
                    if (!isStatusChanged) _promptNewBatsman(playerWhoGotOut);
                  },
                  child: const Text("CONFIRM OUT"),
                )
              ],
            );
          }
      ),
    );
  }

  void _showInningsBreakDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.change_circle, size: 80, color: Colors.teal),
              const SizedBox(height: 10),
              const Text("INNINGS BREAK", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.teal, letterSpacing: 1.5)),
              const SizedBox(height: 15),
              Text("Target: ${match.runs1 + 1}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              Text("in ${match.totalOvers} overs", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: () {
                  setState(() {
                    match.currentInnings = 2;
                    striker = ""; nonStriker = ""; currentBowler = ""; currentOverTimeline.clear();
                  });
                  Navigator.pop(context);
                  _promptNewPlayers(isInningsStart: true);
                },
                child: const Text("START 2ND INNINGS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showMatchResultDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 10),
              const Text("MATCH OVER", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.teal, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Text(match.matchResult, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: () async {
                  await _saveMatchState(isComplete: true); // FINISHED MATCH!
                  if (mounted) { Navigator.pop(context); Navigator.pop(context); }
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
    // WILL POP SCOPE: Intercepts the back button to ask if they want to pause the match!
    return WillPopScope(
      onWillPop: () async {
        if (isSetupPhase || match.matchResult.isNotEmpty) return true; // Let them leave if not playing

        bool? exit = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Want to quit match?", style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text("Your match is still running. You can save your progress and resume later from the History screen."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Exits without saving
                  child: const Text("NO, DISCARD", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    await _saveMatchState(isComplete: false); // SAVES PAUSED STATE!
                    if (mounted) Navigator.of(context).pop(true); // Exits screen
                  },
                  child: const Text("SAVE PROGRESS & EXIT"),
                )
              ],
            )
        );
        return exit ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: isSetupPhase ? true : false,
        appBar: AppBar(title: const Text('Cricket Scorecard')),
        body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
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
          const Text("Match Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [ Expanded(child: TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Team A Name', border: OutlineInputBorder()))), const SizedBox(width: 10), Expanded(child: TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Team B Name', border: OutlineInputBorder()))) ]),
          const SizedBox(height: 15),
          Row(children: [ Expanded(child: TextField(controller: _oversController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Overs', border: OutlineInputBorder()))), const SizedBox(width: 10), Expanded(child: TextField(controller: _playersController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Players per Team', border: OutlineInputBorder()))) ]),
          const SizedBox(height: 20),
          const Text("Toss & Umpires", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Toss Won By', border: OutlineInputBorder()), value: tossWinner, items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => tossWinner = val)),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Opted To', border: OutlineInputBorder()), value: optDecision, items: ["Bat", "Bowl"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => optDecision = val)),
          const SizedBox(height: 15),
          Row(children: [ Expanded(child: TextField(controller: _umpire1Controller, decoration: const InputDecoration(labelText: '1st Umpire', border: OutlineInputBorder()))), const SizedBox(width: 10), Expanded(child: TextField(controller: _umpire2Controller, decoration: const InputDecoration(labelText: '2nd Umpire', border: OutlineInputBorder()))) ]),
          const SizedBox(height: 30),
          ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.teal, foregroundColor: Colors.white), onPressed: _startMatch, child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildMatchScreen() {
    int cRuns = match.currentInnings == 1 ? match.runs1 : match.runs2;
    int cWickets = match.currentInnings == 1 ? match.wickets1 : match.wickets2;
    String cOvers = match.currentInnings == 1 ? match.overs1 : match.overs2;
    String cTeam = match.currentInnings == 1 ? match.battingTeam1 : match.battingTeam2;
    double runRate = match.currentInnings == 1 ? (match.balls1 == 0 ? 0 : (match.runs1 / (match.balls1 / 6))) : (match.balls2 == 0 ? 0 : (match.runs2 / (match.balls2 / 6)));

    return Column(
      children: [
        Container(
          width: double.infinity, color: Colors.teal.shade800, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Text(cTeam, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [ Text("$cRuns-$cWickets", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1)), Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 10), child: Text("($cOvers)", style: const TextStyle(fontSize: 24, color: Colors.white70))) ]),
              const SizedBox(height: 5),
              Text("CRR: ${runRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.yellowAccent)),
              if (match.currentInnings == 2) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Target: ${match.runs1 + 1} | Need ${match.runs1 + 1 - cRuns} runs in ${(match.totalOvers * 6) - match.balls2} balls", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15), color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("🏏 $striker *", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)), Text("🏏 $nonStriker", style: const TextStyle(fontSize: 16, color: Colors.black87)) ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [ Text("🎾 $currentBowler", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)) ])
            ],
          ),
        ),
        Container(
          height: 60, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: currentOverTimeline.length,
            itemBuilder: (context, index) {
              String event = currentOverTimeline[index];
              Color circleColor = Colors.grey.shade300; Color textColor = Colors.black;
              if (event == "W") { circleColor = Colors.redAccent; textColor = Colors.white; }
              else if (event == "4" || event == "6") { circleColor = Colors.blueAccent; textColor = Colors.white; }
              else if (event.contains("Wd") || event.contains("NB")) { circleColor = Colors.orangeAccent; }
              return Container(margin: const EdgeInsets.only(right: 8), width: 40, decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle), alignment: Alignment.center, child: Text(event, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)));
            },
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(10), color: Colors.white,
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [0, 1, 2, 3, 4, 6].map((run) => Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: (run == 4 || run == 6) ? Colors.blue.shade50 : Colors.grey.shade200, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _addDelivery(runsOffBat: run), child: Text("$run", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))))).toList()),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ["WD", "NB", "B", "LB"].map((extra) => Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () => _showExtraDialog(extra), child: Text(extra, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)))))).toList()),
              const SizedBox(height: 10),
              Row(children: [ Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: _showWicketDialog, child: const Text("WICKET OUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))) ])
            ],
          ),
        )
      ],
    );
  }
}
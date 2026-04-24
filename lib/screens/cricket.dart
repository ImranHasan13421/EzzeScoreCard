import 'package:flutter/material.dart';
import '../models/match_models.dart';
import '../storage/file_manager.dart';

class CricketScreen extends StatefulWidget {
  const CricketScreen({super.key});

  @override
  State<CricketScreen> createState() => _CricketScreenState();
}

class _CricketScreenState extends State<CricketScreen> {
  bool isSetupPhase = true;

  // Setup Controllers
  final _teamAController = TextEditingController(text: "Team A");
  final _teamBController = TextEditingController(text: "Team B");
  final _oversController = TextEditingController(text: "20");
  final _playersController = TextEditingController(text: "11");
  final _umpire1Controller = TextEditingController(text: "Umpire 1");
  final _umpire2Controller = TextEditingController(text: "Umpire 2");

  String? tossWinner;
  String? optDecision;

  late CricketMatch match;

  // Active Match State Variables
  String striker = "Striker";
  String nonStriker = "Non-Striker";
  String currentBowler = "Bowler";
  List<String> currentOverTimeline = [];

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
    _oversController.dispose();
    _playersController.dispose();
    _umpire1Controller.dispose();
    _umpire2Controller.dispose();
    super.dispose();
  }

  // --- 1. INITIALIZATION ---
  void _startMatch() {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || tossWinner == null || optDecision == null) return;

    setState(() {
      String battingFirst = (tossWinner == _teamAController.text && optDecision == "Bat") ||
          (tossWinner != _teamAController.text && optDecision == "Bowl")
          ? _teamAController.text
          : _teamBController.text;

      String bowlingFirst = battingFirst == _teamAController.text ? _teamBController.text : _teamAController.text;

      match = CricketMatch(
        matchName: "Cric_${_teamAController.text}_vs_${_teamBController.text}_${DateTime.now().millisecondsSinceEpoch}",
        teamA: _teamAController.text,
        teamB: _teamBController.text,
        totalOvers: int.tryParse(_oversController.text) ?? 20,
        playersPerTeam: int.tryParse(_playersController.text) ?? 11,
        umpire1: _umpire1Controller.text,
        umpire2: _umpire2Controller.text,
        tossWinner: tossWinner!,
        optDecision: optDecision!,
        battingTeam1: battingFirst,
        battingTeam2: bowlingFirst,
        events1: [],
        events2: [],
      );
      isSetupPhase = false;
    });

    _promptNewPlayers(isInningsStart: true);
  }

  // --- 2. MATCH ENGINE LOGIC ---
  bool _addDelivery({required int runsOffBat, int extraRuns = 0, String extraType = "", bool isWicket = false, String wicketType = ""}) {
    if (match.matchResult.isNotEmpty) return true; // Match is already over

    bool statusChanged = false;

    setState(() {
      int totalRunsOnBall = runsOffBat + extraRuns;
      bool isLegalDelivery = extraType != "WD" && extraType != "NB";

      String eventText = "";

      // Calculate Runs & Wickets
      if (match.currentInnings == 1) {
        match.runs1 += totalRunsOnBall;
        if (isLegalDelivery) match.balls1++;
        if (isWicket) match.wickets1++;
      } else {
        match.runs2 += totalRunsOnBall;
        if (isLegalDelivery) match.balls2++;
        if (isWicket) match.wickets2++;
      }

      // Generate Timeline Event Text
      if (isWicket) {
        eventText = "W";
      } else if (extraType.isNotEmpty) {
        eventText = extraType == "WD" || extraType == "NB" ? "$totalRunsOnBall$extraType" : "$extraRuns$extraType";
      } else {
        eventText = runsOffBat == 0 ? "•" : "$runsOffBat";
      }

      currentOverTimeline.add(eventText);
      String fullLog = "${match.currentInnings == 1 ? match.overs1 : match.overs2} | $currentBowler to $striker: $eventText ${isWicket ? "($wicketType)" : ""}";

      if (match.currentInnings == 1) {
        match.events1.add(fullLog);
      } else {
        match.events2.add(fullLog);
      }

      // Strike Rotation Check (Odd runs rotate strike)
      if (runsOffBat % 2 != 0 || (extraRuns > 1 && extraRuns % 2 == 0) || (extraType == "B" || extraType == "LB") && extraRuns % 2 != 0) {
        _rotateStrike();
      }

      // Check if the Innings just ended based on this ball
      statusChanged = _checkInningsStatus();

      // End of Over Check
      int currentBalls = match.currentInnings == 1 ? match.balls1 : match.balls2;
      if (isLegalDelivery && currentBalls % 6 == 0 && currentBalls > 0) {
        _rotateStrike(); // Batters switch ends at the end of an over
        currentOverTimeline.clear();

        // Only ask for a new bowler if the innings didn't just end!
        if (!statusChanged) {
          _promptNewBowler();
        }
      }
    });

    return statusChanged;
  }

  void _rotateStrike() {
    String temp = striker;
    striker = nonStriker;
    nonStriker = temp;
  }

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
        if (currentRuns == match.runs1) {
          match.matchResult = "Match Tied";
        } else {
          match.matchResult = "${match.battingTeam1} won by ${match.runs1 - currentRuns} runs";
        }
        _showMatchResultDialog();
        return true;
      }
    }
    return false;
  }

  // --- 3. UMPIRE DIALOGS ---
  void _promptNewPlayers({bool isInningsStart = true}) {
    TextEditingController strikerCtrl = TextEditingController();
    TextEditingController nonStrikerCtrl = TextEditingController();
    TextEditingController bowlerCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
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
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("New Batsman"),
        content: SingleChildScrollView(
          child: TextField(
            controller: newBatCtrl,
            decoration: const InputDecoration(labelText: "Batsman Name"),
            autofocus: true,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (newBatCtrl.text.isNotEmpty) {
                setState(() {
                  // Cleverly replaces the outgoing player wherever they ended up
                  if (striker == outgoingPlayerName) {
                    striker = newBatCtrl.text;
                  } else if (nonStriker == outgoingPlayerName) {
                    nonStriker = newBatCtrl.text;
                  }
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
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("End of Over"),
        content: SingleChildScrollView(
          child: TextField(controller: bowlerCtrl, decoration: const InputDecoration(labelText: "New Bowler Name"), autofocus: true),
        ),
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
                        // Cleanly reset non-striker values if changed away from Run Out
                        if (selectedOut != "Run Out") {
                          selectedPlayerOut = striker;
                          runsCompleted = 0;
                        }
                      }),
                      decoration: const InputDecoration(labelText: "Dismissal Type"),
                    ),

                    // ONLY show these if it is a Run Out
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

                    // Only prompt for a new batsman if the innings didn't just end!
                    if (!isStatusChanged) {
                      _promptNewBatsman(playerWhoGotOut);
                    }
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
      context: context,
      barrierDismissible: false,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 3,
                ),
                onPressed: () {
                  setState(() {
                    match.currentInnings = 2;
                    striker = ""; nonStriker = ""; currentBowler = "";
                    currentOverTimeline.clear();
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
      context: context,
      barrierDismissible: false,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 3,
                ),
                onPressed: () async {
                  await FileManager.saveMatchFile('Cricket', match.matchName, match.toJson());
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: const Text("SAVE & EXIT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: isSetupPhase ? true : false,
      appBar: AppBar(
        title: const Text('Cricket Scorecard'),
        actions: isSetupPhase ? null : [IconButton(icon: const Icon(Icons.save), onPressed: () => FileManager.saveMatchFile('Cricket', match.matchName, match.toJson()))],
      ),
      body: isSetupPhase ? _buildSetupForm() : _buildMatchScreen(),
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
          const Text("Match Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'Team A Name', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'Team B Name', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: TextField(controller: _oversController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Overs', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _playersController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Players per Team', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Toss & Umpires", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Toss Won By', border: OutlineInputBorder()),
            value: tossWinner,
            items: teams.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => tossWinner = val),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Opted To', border: OutlineInputBorder()),
            value: optDecision,
            items: ["Bat", "Bowl"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => optDecision = val),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: TextField(controller: _umpire1Controller, decoration: const InputDecoration(labelText: '1st Umpire', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _umpire2Controller, decoration: const InputDecoration(labelText: '2nd Umpire', border: OutlineInputBorder()))),
            ],
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
    int cRuns = match.currentInnings == 1 ? match.runs1 : match.runs2;
    int cWickets = match.currentInnings == 1 ? match.wickets1 : match.wickets2;
    String cOvers = match.currentInnings == 1 ? match.overs1 : match.overs2;
    String cTeam = match.currentInnings == 1 ? match.battingTeam1 : match.battingTeam2;

    double runRate = match.currentInnings == 1
        ? (match.balls1 == 0 ? 0 : (match.runs1 / (match.balls1 / 6)))
        : (match.balls2 == 0 ? 0 : (match.runs2 / (match.balls2 / 6)));

    return Column(
      children: [
        // 1. TOP SCOREBOARD
        Container(
          width: double.infinity,
          color: Colors.teal.shade800,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Text(cTeam, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$cRuns-$cWickets", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 10),
                    child: Text("($cOvers)", style: const TextStyle(fontSize: 24, color: Colors.white70)),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text("CRR: ${runRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.yellowAccent)),
              if (match.currentInnings == 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Target: ${match.runs1 + 1} | Need ${match.runs1 + 1 - cRuns} runs in ${(match.totalOvers * 6) - match.balls2} balls",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
            ],
          ),
        ),

        // 2. MIDDLE INFO (Batters & Bowler)
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🏏 $striker *", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  Text("🏏 $nonStriker", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("🎾 $currentBowler", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ],
              )
            ],
          ),
        ),

        // 3. CURRENT OVER TIMELINE
        Container(
          height: 60,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: currentOverTimeline.length,
            itemBuilder: (context, index) {
              String event = currentOverTimeline[index];
              Color circleColor = Colors.grey.shade300;
              Color textColor = Colors.black;

              if (event == "W") { circleColor = Colors.redAccent; textColor = Colors.white; }
              else if (event == "4" || event == "6") { circleColor = Colors.blueAccent; textColor = Colors.white; }
              else if (event.contains("Wd") || event.contains("NB")) { circleColor = Colors.orangeAccent; }

              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 40,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(event, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              );
            },
          ),
        ),

        const Spacer(),

        // 4. UMPIRE CONTROL PANEL
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0, 1, 2, 3, 4, 6].map((run) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: (run == 4 || run == 6) ? Colors.blue.shade50 : Colors.grey.shade200,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () => _addDelivery(runsOffBat: run),
                      child: Text("$run", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["WD", "NB", "B", "LB"].map((extra) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () => _showExtraDialog(extra),
                      child: Text(extra, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: _showWicketDialog,
                      child: const Text("WICKET OUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../storage/file_manager.dart';

// Import the sport screens so we can route to them when hitting "RESUME"
import 'cricket.dart';
import 'football.dart';
import 'badminton.dart';

class HistoryScreen extends StatefulWidget {
  final String sportName;
  const HistoryScreen({super.key, required this.sportName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> completedMatches = [];
  List<Map<String, dynamic>> pausedMatches = [];

  @override
  void initState() {
    super.initState();
    _refreshMatches();
  }

  void _refreshMatches() async {
    setState(() => isLoading = true);
    var allMatches = await FileManager.getSavedMatches(widget.sportName);

    setState(() {
      // If 'isComplete' is explicitly false, it goes to paused. Otherwise, assume completed.
      pausedMatches = allMatches.where((m) => m['isComplete'] == false).toList();
      completedMatches = allMatches.where((m) => m['isComplete'] != false).toList();
      isLoading = false;
    });
  }

  void _confirmDelete(String filePath, String matchTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Match?"),
        content: Text("Permanently delete '$matchTitle'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FileManager.deleteMatchFile(filePath);
              _refreshMatches();
            },
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  void _resumeMatch(Map<String, dynamic> matchData) {
    Widget targetScreen;
    if (widget.sportName == 'Cricket') targetScreen = CricketScreen(pausedMatchData: matchData);
    else if (widget.sportName == 'Football') targetScreen = FootballScreen(pausedMatchData: matchData);
    else targetScreen = BadmintonScreen(pausedMatchData: matchData);

    // Navigate to the game screen, and refresh history when returning
    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)).then((_) => _refreshMatches());
  }

  void _markMatchComplete(Map<String, dynamic> matchData) async {
    matchData['isComplete'] = true;
    await FileManager.saveMatchFile(widget.sportName, matchData);
    _refreshMatches();
  }

  // --- UI Helpers ---
  String _getTitle(Map<String, dynamic> m) {
    if (widget.sportName == 'Cricket') return m['match_name'] ?? 'Cricket Match';
    return "${m['team_a'] ?? 'A'} vs ${m['team_b'] ?? 'B'}";
  }

  String _getSubtitle(Map<String, dynamic> m) {
    if (widget.sportName == 'Cricket') return "Score: ${m['runs']}/${m['wickets']} (${m['overs']} Ov)";
    if (widget.sportName == 'Football') return "Score: ${m['team_a_goals'] ?? 0} - ${m['team_b_goals'] ?? 0}";
    return "Sets Won: ${m['team_a_score']} - ${m['team_b_score']}";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.sportName} History'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.yellowAccent,
            tabs: [Tab(text: "COMPLETE MATCHES"), Tab(text: "PAUSED MATCHES")],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildList(completedMatches, false),
            _buildList(pausedMatches, true),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> matches, bool isPausedList) {
    if (matches.isEmpty) return Center(child: Text("No matches found.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return isPausedList ? _buildPausedCard(matches[index]) : _buildCompletedCard(matches[index]);
      },
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> match) {
    String title = _getTitle(match);
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.emoji_events, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_getSubtitle(match), style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(match['file_path'], title)),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedCard(Map<String, dynamic> match) {
    String title = _getTitle(match);
    return Card(
      elevation: 4, margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.shade300, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pause_circle_filled, color: Colors.orange, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              ],
            ),
            const SizedBox(height: 8),
            Text(_getSubtitle(match), style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.teal),
                  label: const Text("RESUME", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  onPressed: () => _resumeMatch(match),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text("FINISH", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  onPressed: () => _markMatchComplete(match),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(match['file_path'], title),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
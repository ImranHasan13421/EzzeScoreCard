import 'package:flutter/material.dart';
import '../storage/file_manager.dart';
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
      pausedMatches = allMatches.where((m) => m['isComplete'] == false).toList();
      completedMatches = allMatches.where((m) => m['isComplete'] != false).toList();
      isLoading = false;
    });
  }

  void _confirmDelete(String filePath, String matchTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Match?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Permanently delete '$matchTitle'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async { Navigator.pop(ctx); await FileManager.deleteMatchFile(filePath); _refreshMatches(); },
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)).then((_) => _refreshMatches());
  }

  void _markMatchComplete(Map<String, dynamic> matchData) async {
    matchData['isComplete'] = true;
    await FileManager.saveMatchFile(widget.sportName, matchData);
    _refreshMatches();
  }

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
          title: Text('${widget.sportName.toUpperCase()} HISTORY'),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Color(0xFF3B82F6),
            indicatorWeight: 4,
            labelColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            unselectedLabelColor: Colors.lightBlue,
            tabs: [Tab(text: "COMPLETE"), Tab(text: "PAUSED")],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_buildList(completedMatches, false), _buildList(pausedMatches, true)]),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> matches, bool isPaused) {
    if (matches.isEmpty) return Center(child: Text("No matches found.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)));
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: matches.length,
      itemBuilder: (context, index) => isPaused ? _buildPausedCard(matches[index]) : _buildCompletedCard(matches[index]),
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> match) {
    String title = _getTitle(match);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_getSubtitle(match), style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(match['file_path'], title)),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedCard(Map<String, dynamic> match) {
    String title = _getTitle(match);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pause_circle_filled, color: Color(0xFF3B82F6), size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)))),
              ],
            ),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.only(left: 40), child: Text(_getSubtitle(match), style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF3B82F6)),
                  label: const Text("RESUME", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w800)),
                  onPressed: () => _resumeMatch(match),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  label: const Text("FINISH", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800)),
                  onPressed: () => _markMatchComplete(match),
                ),
                IconButton(icon: const Icon(Icons.delete, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(match['file_path'], title))
              ],
            )
          ],
        ),
      ),
    );
  }
}
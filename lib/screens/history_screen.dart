// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../storage/file_manager.dart';

class HistoryScreen extends StatefulWidget {
  final String sportName;

  const HistoryScreen({super.key, required this.sportName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMatches();
  }

  // Reloads the list of files from storage
  void _refreshMatches() {
    setState(() {
      _matchesFuture = FileManager.getSavedMatches(widget.sportName);
    });
  }

  // Shows a popup confirming they want to delete the file
  void _confirmDelete(BuildContext context, String filePath, String matchTitle) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Delete Match?"),
          content: Text("Are you sure you want to permanently delete '$matchTitle'?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx); // Close dialog
                bool success = await FileManager.deleteMatchFile(filePath);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match deleted successfully.')));
                  _refreshMatches(); // Refresh the list to remove the deleted card
                }
              },
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sportName} History'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading matches."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No previous ${widget.sportName} matches found.",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final matches = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildMatchCard(match);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    String title = "Match Result";
    String subtitle = "";
    String trailingText = "";

    // Dynamically format the card based on the Sport
    if (widget.sportName == 'Football') {
      title = "${match['team_a']} vs ${match['team_b']}";
      subtitle = "Final Score: ${match['team_a_goals']} - ${match['team_b_goals']}";
      trailingText = match['final_time'] ?? '';
    }
    else if (widget.sportName == 'Cricket') {
      title = match['match_name'] ?? 'Cricket Match';
      subtitle = "Score: ${match['runs']}/${match['wickets']}";
      trailingText = "${match['overs']} Overs";
    }
    else if (widget.sportName == 'Badminton') {
      title = match['match_name'] ?? 'Badminton Match';
      subtitle = "Team A: ${match['team_a_score']}  |  Team B: ${match['team_b_score']}";
      trailingText = "";
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.emoji_events, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
        // Group the original text and the new delete button together
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trailingText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, match['file_path'], title),
            ),
          ],
        ),
      ),
    );
  }
}
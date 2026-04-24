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
      title = "${match['team_a'] ?? 'Player A'} vs ${match['team_b'] ?? 'Player B'}";
      subtitle = "Sets Won: ${match['team_a_score']} - ${match['team_b_score']}";
      trailingText = "Last Pts: ${match['final_set_score'] ?? ''}";
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Trophy Icon
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.teal,
              child: Icon(Icons.emoji_events, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),

            // 2. Middle Text Area (Expanded guarantees it won't overflow the screen)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Adds "..." if names are ridiculously long
                  ),
                  const SizedBox(height: 6),

                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),

                  // Moving the extra info down here fixes the horizontal crowding!
                  if (trailingText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      trailingText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ]
                ],
              ),
            ),

            // 3. Delete Button (Anchored to the right)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
              onPressed: () => _confirmDelete(context, match['file_path'], title),
            ),
          ],
        ),
      ),
    );
  }
}
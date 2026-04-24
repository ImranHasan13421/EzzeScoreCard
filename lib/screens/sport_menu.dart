// lib/screens/sport_menu.dart
import 'package:flutter/material.dart';
import 'history_screen.dart';

class SportMenuScreen extends StatelessWidget {
  final String sportName;
  final Widget newGameScreen;

  const SportMenuScreen({
    super.key,
    required this.sportName,
    required this.newGameScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$sportName Hub'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NEW GAME CARD
            Expanded(
              child: Card(
                color: Colors.teal,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => newGameScreen));
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, size: 80, color: Colors.white),
                      SizedBox(height: 15),
                      Text("NEW GAME", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                      Text("Start a fresh scorecard", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // PREVIOUS GAME CARD
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(sportName: sportName)));
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.teal),
                      SizedBox(height: 15),
                      Text("PREVIOUS GAMES", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.teal, letterSpacing: 1.5)),
                      Text("View saved match results", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/models/match_models.dart

class BadmintonMatch {
  String matchName;
  int teamAScore;
  int teamBScore;
  DateTime date;

  BadmintonMatch({required this.matchName, required this.teamAScore, required this.teamBScore}) : date = DateTime.now();

  Map<String, dynamic> toJson() => {
    'sport': 'Badminton',
    'match_name': matchName,
    'date': date.toIso8601String(),
    'team_a_score': teamAScore,
    'team_b_score': teamBScore,
  };
}

class CricketMatch {
  String matchName;
  int runs;
  int wickets;
  int balls; // Track balls to calculate overs (e.g., 6 balls = 1 over)

  CricketMatch({required this.matchName, this.runs = 0, this.wickets = 0, this.balls = 0});

  String get overs => '${balls ~/ 6}.${balls % 6}';

  Map<String, dynamic> toJson() => {
    'sport': 'Cricket',
    'match_name': matchName,
    'runs': runs,
    'wickets': wickets,
    'overs': overs,
  };
}



class FootballMatch {
  String matchName;
  String teamA;
  String teamB;
  String tossWonBy;
  String ball;
  String bar;
  int teamAGoals;
  int teamBGoals;
  List<String> teamAEvents;
  List<String> teamBEvents;
  String finalTime;
  int totalTimeMinutes; // NEW: Added this

  FootballMatch({
    required this.matchName,
    this.teamA = "Team A",
    this.teamB = "Team B",
    this.tossWonBy = "",
    this.ball = "",
    this.bar = "",
    this.teamAGoals = 0,
    this.teamBGoals = 0,
    this.teamAEvents = const [],
    this.teamBEvents = const [],
    this.finalTime = "00:00:00",
    this.totalTimeMinutes = 90, // Default to 90
  });

  Map<String, dynamic> toJson() => {
    'sport': 'Football',
    'match_name': matchName,
    'team_a': teamA,
    'team_b': teamB,
    'toss_won_by': tossWonBy,
    'ball': ball,
    'bar': bar,
    'team_a_goals': teamAGoals,
    'team_b_goals': teamBGoals,
    'team_a_events': teamAEvents,
    'team_b_events': teamBEvents,
    'final_time': finalTime,
    'total_time_minutes': totalTimeMinutes, // NEW
  };
}
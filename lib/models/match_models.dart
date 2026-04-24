// lib/models/match_models.dart

class BadmintonMatch {
  String matchName;
  String teamA;
  String teamB;
  int teamAScore;
  int teamBScore;
  int teamASets;
  int teamBSets;
  int currentSet;
  int totalSets;
  int pointsToWin;
  String servingTeam;
  List<String> matchEvents;

  BadmintonMatch({
    required this.matchName,
    this.teamA = "Team A",
    this.teamB = "Team B",
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.teamASets = 0,
    this.teamBSets = 0,
    this.currentSet = 1,
    this.totalSets = 3,
    this.pointsToWin = 21,
    this.servingTeam = "",
    this.matchEvents = const [],
  });

  Map<String, dynamic> toJson() => {
    'sport': 'Badminton',
    'match_name': matchName,
    'team_a': teamA,
    'team_b': teamB,
    'team_a_score': teamASets, // Saving sets as the primary score for history
    'team_b_score': teamBSets,
    'final_set_score': '$teamAScore - $teamBScore',
    'total_sets': totalSets,
    'match_events': matchEvents,
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
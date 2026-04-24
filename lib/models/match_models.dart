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
  String teamA;
  String teamB;
  int totalOvers;
  int playersPerTeam;
  String tossWinner;
  String optDecision; // "Bat" or "Bowl"
  String umpire1;
  String umpire2;

  // Innings 1 State
  String battingTeam1;
  int runs1;
  int wickets1;
  int balls1;
  List<String> events1;

  // Innings 2 State
  String battingTeam2;
  int runs2;
  int wickets2;
  int balls2;
  List<String> events2;

  int currentInnings; // 1 or 2
  String matchResult;

  CricketMatch({
    required this.matchName,
    this.teamA = "Team A",
    this.teamB = "Team B",
    this.totalOvers = 20,
    this.playersPerTeam = 11,
    this.tossWinner = "",
    this.optDecision = "",
    this.umpire1 = "",
    this.umpire2 = "",
    this.battingTeam1 = "",
    this.runs1 = 0,
    this.wickets1 = 0,
    this.balls1 = 0,
    this.events1 = const [],
    this.battingTeam2 = "",
    this.runs2 = 0,
    this.wickets2 = 0,
    this.balls2 = 0,
    this.events2 = const [],
    this.currentInnings = 1,
    this.matchResult = "",
  });

  String get overs1 => '${balls1 ~/ 6}.${balls1 % 6}';
  String get overs2 => '${balls2 ~/ 6}.${balls2 % 6}';

  Map<String, dynamic> toJson() => {
    'sport': 'Cricket',
    'match_name': matchName,
    'team_a': teamA,
    'team_b': teamB,
    'total_overs': totalOvers,
    'players_per_team': playersPerTeam,
    'umpire_1': umpire1,
    'umpire_2': umpire2,
    'runs': currentInnings == 1 ? runs1 : runs2,       // For History Screen reading
    'wickets': currentInnings == 1 ? wickets1 : wickets2,
    'overs': currentInnings == 1 ? overs1 : overs2,
    'match_result': matchResult,
    // Full Data for PDF generation later
    'innings_1': {'team': battingTeam1, 'runs': runs1, 'wickets': wickets1, 'balls': balls1, 'events': events1},
    'innings_2': {'team': battingTeam2, 'runs': runs2, 'wickets': wickets2, 'balls': balls2, 'events': events2},
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
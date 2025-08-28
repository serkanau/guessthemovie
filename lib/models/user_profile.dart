class UserProfile {
  final String uid;
  final String name;
  final int gamesPlayed;
  final int correctCount;
  UserProfile({
    required this.uid,
    required this.name,
    this.gamesPlayed = 0,
    this.correctCount = 0,
  });
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'stats': {
      'gamesPlayed': gamesPlayed,
      'correctCount': correctCount,
    },
    'createdAt': DateTime.now().toIso8601String(),
  };
}

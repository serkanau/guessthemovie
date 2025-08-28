import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/movie.dart';

class DbService {
  final _db = FirebaseDatabase.instance.ref();

  Future<List<Movie>> fetchAllMovies() async {
    final snap = await _db.child('movies').get();
    print('Snapshot exists: ${snap.exists}'); // Debug
    print('Snapshot value: ${snap.value}'); // Debug
    if (!snap.exists) return [];
    final data = snap.value as Map<dynamic, dynamic>;
    final movies = <Movie>[];
    data.forEach((key, value) {
      if (value is Map) {
        try {
          movies.add(Movie.fromMap(Map<String, dynamic>.from(value)));
        } catch (e) {
          print('Error parsing movie $key: $e'); // Debug
        }
      }
    });
    print('Parsed movies: ${movies.map((m) => m.id)}'); // Debug
    return movies;
  }

  Future<void> incrementMovieView(String movieId) async {
    final ref = _db.child('movies/$movieId/View');
    await ref.runTransaction((value) {
      final current = (value as int?) ?? 0;
      return Transaction.success(current + 1);
    });
  }

  Future<void> incrementMovieRight(String movieId) async {
    final ref = _db.child('movies/$movieId/Right');
    await ref.runTransaction((value) {
      final current = (value as int?) ?? 0;
      return Transaction.success(current + 1);
    });
  }

  Future<void> incrementUserStats(String uid, {required bool correct}) async {
    final playedRef = _db.child('users/$uid/stats/gamesPlayed');
    await playedRef.runTransaction((value) {
      final current = (value as int?) ?? 0;
      return Transaction.success(current + 1);
    });

    if (correct) {
      final correctRef = _db.child('users/$uid/stats/correctCount');
      await correctRef.runTransaction((value) {
        final current = (value as int?) ?? 0;
        return Transaction.success(current + 1);
      });
    }
  }

  // Rastgele film seçmek için (görülenler hariç)
  Movie? pickRandom(List<Movie> all, Set<String> seenIds) {
    final available = all.where((m) => !seenIds.contains(m.id)).toList();
    if (available.isEmpty) return null;
    available.shuffle(Random());
    return available.first;
  }

  // Firebase’e film ekleme (opsiyonel)
  Future<void> addMovie(Movie movie) async {
    await _db.child('movies/${movie.id}').set(movie.toMap());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.totalScore,
  });

  final String uid;
  final String displayName;
  final int totalScore;
}

class LeaderboardService {
  static const int pageSize = 100;
  static const int pointsPerLevel = 10;

  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  static String get _currentUid {
    final uid = AuthService.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to view the leaderboard.');
    }

    return uid;
  }

  /// Gets the top players directly from the users collection.
  ///
  /// Score = number of completed levels × 10
  static Stream<List<LeaderboardEntry>> watchTopEntries() {
    return _users.snapshots().map((snapshot) {
      final entries = <LeaderboardEntry>[];

      for (final document in snapshot.docs) {
        final data = document.data();

        // Only approved students appear on the leaderboard.
        if (data['role'] != 'student' ||
            data['status'] != 'approved') {
          continue;
        }

        final name = data['name'];

        if (name is! String || name.trim().isEmpty) {
          continue;
        }

        final progress = data['progress'];

        int completedLevelsCount = 0;

        if (progress is Map<String, dynamic>) {
          final completedLevels = progress['completedLevels'];

          if (completedLevels is List) {
            final validLevels = <int>{};

            for (final level in completedLevels) {
              final levelNumber = level is num
                  ? level.toInt()
                  : int.tryParse(level.toString());

              if (levelNumber != null && levelNumber >= 1) {
                validLevels.add(levelNumber);
              }
            }

            completedLevelsCount = validLevels.length;
          }
        }

        final totalScore = completedLevelsCount * pointsPerLevel;

        entries.add(
          LeaderboardEntry(
            uid: document.id,
            displayName: name.trim(),
            totalScore: totalScore,
          ),
        );
      }

      // Highest score first.
      // If scores are tied, sort by UID so the order is consistent.
      entries.sort((a, b) {
        final scoreComparison =
            b.totalScore.compareTo(a.totalScore);

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        return a.uid.compareTo(b.uid);
      });

      // Show only the top 100.
      if (entries.length > pageSize) {
        return entries.sublist(0, pageSize);
      }

      return entries;
    });
  }

  /// Gets the current logged-in user's leaderboard entry.
  static Stream<LeaderboardEntry?> watchCurrentEntry() {
    return _users.doc(_currentUid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null ||
          data['role'] != 'student' ||
          data['status'] != 'approved') {
        return null;
      }

      final name = data['name'];

      if (name is! String || name.trim().isEmpty) {
        return null;
      }

      final progress = data['progress'];

      int completedLevelsCount = 0;

      if (progress is Map<String, dynamic>) {
        final completedLevels = progress['completedLevels'];

        if (completedLevels is List) {
          final validLevels = <int>{};

          for (final level in completedLevels) {
            final levelNumber = level is num
                ? level.toInt()
                : int.tryParse(level.toString());

            if (levelNumber != null && levelNumber >= 1) {
              validLevels.add(levelNumber);
            }
          }

          completedLevelsCount = validLevels.length;
        }
      }

      return LeaderboardEntry(
        uid: snapshot.id,
        displayName: name.trim(),
        totalScore: completedLevelsCount * pointsPerLevel,
      );
    });
  }

  /// Gets the rank of a player from the current leaderboard.
  static Future<int> getRank(LeaderboardEntry entry) async {
    final snapshot = await _users.get();

    final entries = <LeaderboardEntry>[];

    for (final document in snapshot.docs) {
      final data = document.data();

      if (data['role'] != 'student' ||
          data['status'] != 'approved') {
        continue;
      }

      final name = data['name'];

      if (name is! String || name.trim().isEmpty) {
        continue;
      }

      final progress = data['progress'];

      int completedLevelsCount = 0;

      if (progress is Map<String, dynamic>) {
        final completedLevels = progress['completedLevels'];

        if (completedLevels is List) {
          final validLevels = <int>{};

          for (final level in completedLevels) {
            final levelNumber = level is num
                ? level.toInt()
                : int.tryParse(level.toString());

            if (levelNumber != null && levelNumber >= 1) {
              validLevels.add(levelNumber);
            }
          }

          completedLevelsCount = validLevels.length;
        }
      }

      entries.add(
        LeaderboardEntry(
          uid: document.id,
          displayName: name.trim(),
          totalScore: completedLevelsCount * pointsPerLevel,
        ),
      );
    }

    entries.sort((a, b) {
      final scoreComparison =
          b.totalScore.compareTo(a.totalScore);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.uid.compareTo(b.uid);
    });

    final index = entries.indexWhere(
      (item) => item.uid == entry.uid,
    );

    if (index == -1) {
      throw StateError('Player is not on the leaderboard.');
    }

    return index + 1;
  }

  /// No longer needed because we are not using Cloud Functions.
  static Future<void> syncCurrentEntry() async {
    // Nothing to sync.
    //
    // The leaderboard is calculated directly from the
    // users collection.
  }

  /// No longer needed because we are not using Cloud Functions.
  static Future<int> backfillEntries() async {
    // Nothing to backfill.
    //
    // Existing users are automatically included when
    // the leaderboard is loaded.
    final snapshot = await _users.get();

    int processed = 0;

    for (final document in snapshot.docs) {
      final data = document.data();

      if (data['role'] == 'student' &&
          data['status'] == 'approved') {
        processed++;
      }
    }

    return processed;
  }
}
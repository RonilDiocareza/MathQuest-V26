import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProgress {
  static const int npcQuestionCount = 6;

  final List<int> completedLevels;
  final List<int> completedNpcQuestions;
  final int unlockedLevels;
  final int questAttempts;
  final Map<int, int> maxUnlockedSubLevel;

  UserProgress({
    required this.completedLevels,
    required this.completedNpcQuestions,
    required this.unlockedLevels,
    required this.questAttempts,
    required this.maxUnlockedSubLevel,
  });

  int get completedCount => completedLevels.length;

  int get currentNpcQuestionNumber {
    for (var questionNumber = 1;
        questionNumber <= npcQuestionCount;
        questionNumber++) {
      if (!completedNpcQuestions.contains(questionNumber)) {
        return questionNumber;
      }
    }
    return npcQuestionCount;
  }

  bool get areNpcQuestionsCompleted =>
      List.generate(npcQuestionCount, (index) => index + 1)
          .every(completedNpcQuestions.contains);

  int get highestCompletedLevel => completedLevels.isEmpty
      ? 0
      : completedLevels.reduce(max);
}

class UserProgressService {
  static final _users = FirebaseFirestore.instance.collection('users');

  static String _uid([String? uid]) {
    final resolved = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolved == null || resolved.isEmpty) {
      throw StateError('Not signed in.');
    }
    return resolved;
  }

  static UserProgress _fromData(Map<String, dynamic>? data) {
    final progress = data?['progress'] as Map<String, dynamic>? ?? {};
    final completed = (progress['completedLevels'] as List<dynamic>? ?? [])
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    final completedNpcQuestions =
        (progress['completedNpcQuestions'] as List<dynamic>? ?? [])
            .map((value) => int.tryParse(value.toString()))
            .where((value) => value != null && value >= 1 && value <= 8)
            .cast<int>()
            .toSet()
            .toList()
          ..sort();
    final rawSublevels =
        progress['maxUnlockedSubLevel'] as Map<String, dynamic>? ?? {};
    return UserProgress(
      completedLevels: completed,
      completedNpcQuestions: completedNpcQuestions,
      unlockedLevels: (progress['unlockedLevels'] as num?)?.toInt() ?? 1,
      questAttempts: (progress['questAttempts'] as num?)?.toInt() ?? 0,
      maxUnlockedSubLevel: {
        1: (rawSublevels['1'] as num?)?.toInt() ?? 1,
        2: (rawSublevels['2'] as num?)?.toInt() ?? 1,
        3: (rawSublevels['3'] as num?)?.toInt() ?? 1,
      },
    );
  }

  static Future<UserProgress> getProgressForUid(String uid) async {
    final snapshot = await _users.doc(uid).get();
    return _fromData(snapshot.data());
  }

  static Future<UserProgress> getProgressForEmail(String email) async {
    final snapshot =
        await _users.where('email', isEqualTo: email).limit(1).get();
    return snapshot.docs.isEmpty
        ? _fromData(null)
        : _fromData(snapshot.docs.first.data());
  }

  static Future<UserProgress> getCurrentUserProgress() {
    return getProgressForUid(_uid());
  }

  static Future<void> saveLevelCompletion(int level, {String? email}) async {
    final userRef = _users.doc(_uid());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final progress = _fromData(snapshot.data());
      final completed = {...progress.completedLevels, level}.toList()..sort();
      final mainLevel = ((level - 1) ~/ 20) + 1;
      final displayNumber = level % 20 == 0 ? 20 : level % 20;
      final nextSubLevel = displayNumber + 1;
      final sublevels = {...progress.maxUnlockedSubLevel};
      if (nextSubLevel <= 20 && nextSubLevel > (sublevels[mainLevel] ?? 1)) {
        sublevels[mainLevel] = nextSubLevel;
      }
      final unlockedLevels = displayNumber == 20 && mainLevel < 3
          ? max(progress.unlockedLevels, mainLevel + 1)
          : progress.unlockedLevels;
      transaction.set(
        userRef,
        {
          'progress': {
            'completedLevels': completed,
            'unlockedLevels': unlockedLevels,
            'questAttempts': progress.questAttempts,
            'maxUnlockedSubLevel': {
              '1': sublevels[1] ?? 1,
              '2': sublevels[2] ?? 1,
              '3': sublevels[3] ?? 1,
            },
          },
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<bool> completeNpcQuestion(
    int questionNumber, {
    String? uid,
  }) async {
    if (questionNumber < 1 || questionNumber > UserProgress.npcQuestionCount) {
      throw ArgumentError.value(questionNumber, 'questionNumber');
    }

    final userRef = _users.doc(_uid(uid));
    return FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(userRef);
      final progress = _fromData(snapshot.data());
      if (progress.areNpcQuestionsCompleted ||
          progress.currentNpcQuestionNumber != questionNumber) {
        return false;
      }

      final completed = {...progress.completedNpcQuestions, questionNumber}
          .toList()
        ..sort();
      transaction.set(
        userRef,
        {
          'progress': {'completedNpcQuestions': completed},
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  static Future<void> incrementQuestAttempts({String? email}) async {
    final userRef = _users.doc(_uid());
    await userRef.set({
      'progress': {'questAttempts': FieldValue.increment(1)},
    }, SetOptions(merge: true));
  }
}

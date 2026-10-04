import 'package:flame/components.dart';

class QuestionNpcPlacement {
  static const double physicalCollisionRadius = 8;

  final int questionNumber;
  final String questionId;
  final String topic;
  final Vector2 position;
  final String spriteAssetPath;
  final double collisionRadius;

  const QuestionNpcPlacement({
    this.questionNumber = 1,
    required this.questionId,
    required this.topic,
    required this.position,
    this.spriteAssetPath = 'assets/images/npcs/npc1.png',
    this.collisionRadius = physicalCollisionRadius,
  });
}

class NpcQuestion {
  final String id;
  final int questionNumber;
  final String topic;
  final String prompt;
  final List<String> choices;
  final int correctAnswerIndex;

  const NpcQuestion({
    required this.id,
    this.questionNumber = 1,
    required this.topic,
    required this.prompt,
    required this.choices,
    required this.correctAnswerIndex,
  });

  NpcQuestion withTopic(String topic) => NpcQuestion(
        id: id,
        questionNumber: questionNumber,
        topic: topic,
        prompt: prompt,
        choices: choices,
        correctAnswerIndex: correctAnswerIndex,
      );

  static const List<NpcQuestion> all = [
    NpcQuestion(
      id: 'npc_question_1',
      questionNumber: 1,
      topic: 'Variables & Operations',
      prompt: 'In 3x + 5, what is the coefficient of x?',
      choices: ['3', '5', '8'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_2',
      questionNumber: 2,
      topic: 'Solving for an Unknown',
      prompt: 'Solve for x: x + 7 = 12.',
      choices: ['5', '19', '84'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_3',
      questionNumber: 3,
      topic: 'Geometric Relationships',
      prompt: 'A linear pair has one angle of 65°. What is the other angle?',
      choices: ['115°', '25°', '65°'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_4',
      questionNumber: 4,
      topic: 'Polygons & Congruence',
      prompt: 'What is the sum of the interior angles in a triangle?',
      choices: ['180°', '90°', '360°'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_5',
      questionNumber: 5,
      topic: 'Equations',
      prompt: 'Solve for x: 4x = 20.',
      choices: ['5', '16', '80'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_6',
      questionNumber: 6,
      topic: 'Perimeter',
      prompt: 'What is the perimeter of a square with side length 4?',
      choices: ['16', '8', '12'],
      correctAnswerIndex: 0,
    ),
  ];

  // Tiled-world coordinates for the four map entrances, central shrine, and
  // bridge at the end of the southern path.
  static const List<(double, double)> _mapNpcPositions = [
    (535, 285),
    (1062, 340),
    (397, 553),
    (651, 584),
    (1120, 550),
    (265, 720),
  ];

  static const List<String> _npcSpritePaths = [
    'assets/images/npcs/npc1.png',
    'assets/images/npcs/npc2.jfif',
    'assets/images/npcs/npc3.jfif',
    'assets/images/npcs/npc4.jfif',
    'assets/images/npcs/npc5.jfif',
    'assets/images/npcs/npc6.jfif',
  ];

  static List<QuestionNpcPlacement> createNpcPlacements({
    required Vector2 playerSpawn,
    required bool Function(Vector2 center, double radius) canOccupy,
  }) {
    final placements = <QuestionNpcPlacement>[];

    bool isClear(Vector2 feetPosition) {
      final radius = QuestionNpcPlacement.physicalCollisionRadius;
      final center = Vector2(feetPosition.x, feetPosition.y - radius);
      if (!canOccupy(center, radius)) return false;

      final playerFeet = Vector2(playerSpawn.x, playerSpawn.y + 21);
      if (center.distanceTo(playerFeet) < radius * 2 + 4) return false;

      return placements.every((placement) {
        final otherCenter = Vector2(
          placement.position.x,
          placement.position.y - placement.collisionRadius,
        );
        return center.distanceTo(otherCenter) >=
            radius + placement.collisionRadius + 4;
      });
    }

    for (var index = 0; index < _mapNpcPositions.length; index++) {
      final (x, y) = _mapNpcPositions[index];
      final position = Vector2(x, y);
      if (!isClear(position)) {
        throw StateError(
          'Question NPC ${index + 1} cannot be placed safely at its building door.',
        );
      }
      placements.add(_placementAt(index, position));
    }

    if (placements.length != all.length) {
      throw StateError(
        'Only ${placements.length} of ${all.length} NPCs have a safe map location.',
      );
    }

    return placements;
  }

  static QuestionNpcPlacement _placementAt(int index, Vector2 position) {
    final question = all[index];
    return QuestionNpcPlacement(
      questionNumber: question.questionNumber,
      questionId: question.id,
      topic: question.topic,
      position: position,
      spriteAssetPath: _npcSpritePaths[index],
    );
  }

  static NpcQuestion? forPlacement(QuestionNpcPlacement placement) {
    for (final question in all) {
      if (question.id == placement.questionId &&
          question.questionNumber == placement.questionNumber) {
        return question.withTopic(placement.topic);
      }
    }
    return null;
  }
}

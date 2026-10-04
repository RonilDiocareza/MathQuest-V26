import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'math_world_game.dart';
import 'npc_question.dart';

class QuestionNpc extends SpriteComponent with HasGameReference<MathWorldGame> {
  static const double interactionRadius = 34;
  static const double visibleHeight = 40;

  // Pixel bounds of each transparent sprite, with right/bottom excluded.
  static const Map<String, (double, double, double, double)>
      _visibleSpriteBounds = {
    'npc1.png': (456, 151, 810, 1163),
    'npc2.jfif': (342, 122, 759, 964),
    'npc3.jfif': (378, 122, 728, 964),
    'npc4.jfif': (327, 127, 683, 964),
    'npc5.jfif': (363, 127, 647, 964),
    'npc6.jfif': (674, 244, 1345, 1928),
  };

  final NpcQuestion question;
  final String spriteAssetPath;
  bool _wasInRange = false;

  QuestionNpc({
    required this.question,
    required this.spriteAssetPath,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(20, 48),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    try {
      final assetKey = spriteAssetPath.replaceFirst('assets/images/', '');
      final image = await game.images.load(assetKey);
      final bounds = _visibleSpriteBounds[assetKey.split('/').last];
      if (bounds == null) {
        throw StateError('No visible sprite bounds for $spriteAssetPath.');
      }
      final (left, top, right, bottom) = bounds;
      final sourceSize = Vector2(right - left, bottom - top);
      sprite = Sprite(
        image,
        srcPosition: Vector2(left, top),
        srcSize: sourceSize,
      );
      size = Vector2(
        visibleHeight * sourceSize.x / sourceSize.y,
        visibleHeight,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to load NPC sprite $spriteAssetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
      add(
        CircleComponent(
          radius: 10,
          position: Vector2(0, -10),
          paint: Paint()..color = const Color(0xFFFFC107),
          anchor: Anchor.center,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isMovementPaused || !game.isGameLoaded) return;

    final playerFeet = game.player.position + Vector2(0, 21);
    final isInRange = playerFeet.distanceTo(position) <= interactionRadius;
    if (!isInRange) {
      _wasInRange = false;
      return;
    }
    if (_wasInRange) return;

    _wasInRange = true;
    game.interactWithNpc(question);
  }
}

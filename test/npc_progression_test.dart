import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/game/math_world_game.dart';
import 'package:flutter_mathquest/game/question_npc.dart';
import 'package:flutter_mathquest/screens/number_pickup_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a wrong NPC answer costs one heart without unlocking the next',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 450);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NumberPickupGameScreen(
          level: 1,
          problem: '1 + 1 = ?',
          correctAnswer: 2,
        ),
      ),
    );

    for (var attempt = 0;
        attempt < 40 &&
            find.byType(GameWidget<MathWorldGame>).evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final gameWidget = tester.widget<GameWidget<MathWorldGame>>(
      find.byType(GameWidget<MathWorldGame>),
    );
    final game = gameWidget.game!;
    for (var attempt = 0; attempt < 40 && !game.isGameLoaded; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
    }
    expect(game.isGameLoaded, isTrue);
    expect(find.byIcon(Icons.favorite), findsNWidgets(3));
    expect(find.byIcon(Icons.menu_book), findsNothing);

    final firstNpc = game.world.children
        .query<QuestionNpc>()
        .firstWhere((npc) => npc.question.questionNumber == 1);
    game.player.position
        .setValues(firstNpc.position.x, firstNpc.position.y - 21);
    firstNpc.update(0);
    await tester.pump();

    expect(find.text('Question 1'), findsOneWidget);
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    expect(game.currentQuestionNumber, 1);
    expect(game.completedNpcQuestions, isEmpty);
    expect(find.textContaining('Wrong answer'), findsOneWidget);
  });
}

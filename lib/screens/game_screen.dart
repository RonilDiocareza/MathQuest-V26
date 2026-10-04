import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';

import '../game/math_world_game.dart';
import '../game/npc_question.dart';
import '../game/npc_question_dialog.dart';
import '../game/hud.dart';
import '../mobile_dpad_controller.dart';

class GameScreen extends StatefulWidget {
  final int correctAnswer;
  final String problem;
  final int level;

  const GameScreen({
    super.key,
    required this.correctAnswer,
    required this.problem,
    this.level = 1,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MathWorldGame _game;
  int _score = 0;
  final int _health = 3;
  bool _isMusicEnabled = true;
  bool _isLeaving = false;
  late Future<void> _orientationChange;

  @override
  void initState() {
    super.initState();
    _orientationChange = SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _game = MathWorldGame(
      correctAnswer: widget.correctAnswer,
      problem: widget.problem,
      onNumberCollected: _onNumberCollected,
      onNpcQuestion: _onNpcQuestion,
      onNpcQuestionLocked: _showLockedQuestion,
    );
  }

  Future<void> _onNpcQuestion(NpcQuestion question) async {
    final activeGame = _game;
    bool? isCorrect;
    try {
      isCorrect = await showDialog<bool>(
        context: context,
        builder: (_) => NpcQuestionDialog(question: question),
      );
    } finally {
      activeGame.closeNpcQuestion();
    }

    if (!mounted || isCorrect == null) return;

    if (isCorrect) {
      try {
        final saved = await activeGame.completeNpcQuestion(
          question.questionNumber,
        );
        if (!mounted) return;
        if (!saved) {
          _showLockedQuestion(activeGame.currentQuestionNumber);
          return;
        }
        setState(() => _score += 10);
      } catch (error, stackTrace) {
        debugPrint('Unable to save NPC question progress: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your progress. Please try again.'),
          ),
        );
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect
              ? activeGame.allNpcQuestionsCompleted
                  ? 'All six NPC questions are complete.'
                  : 'Question ${question.questionNumber} complete! '
                      'Question ${activeGame.currentQuestionNumber} unlocked.'
              : 'Not quite. Try again when you return.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLockedQuestion(int currentQuestionNumber) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Question locked. Complete Question $currentQuestionNumber first.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onNumberCollected() {
    setState(() {
      _score += 10;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Correct!'),
          content: Text('Problem: ${widget.problem} = ${widget.correctAnswer}'),
          actions: [
            TextButton(
              onPressed: () => _closeDialogAndLeave(context),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _onBackPressed() {
    _leaveScreen();
  }

  Future<void> _closeDialogAndLeave(BuildContext dialogContext) async {
    if (_isLeaving) return;
    _isLeaving = true;
    Navigator.pop(dialogContext);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.of(context).maybePop();
  }

  void _leaveScreen() {
    if (_isLeaving || !mounted) return;
    _isLeaving = true;
    Navigator.of(context).maybePop();
  }

  Future<void> _restoreAppOrientation() async {
    try {
      await _orientationChange;
    } finally {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _onMusicPressed() {
    setState(() {
      _isMusicEnabled = !_isMusicEnabled;
    });
  }

  void _onMenuPressed() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Score: $_score'),
              Text('Health: $_health'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Resume'),
            ),
            TextButton(
              onPressed: () => _closeDialogAndLeave(context),
              child: const Text('Quit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isSmallPhone = screenSize.width < 400;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _leaveScreen(),
      child: Scaffold(
        backgroundColor: const Color(0xFFD09F5C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            SafeArea(
              child: Stack(
                children: [
                  if (isMobile)
                    Positioned(
                      left: isSmallPhone ? 8 : 12,
                      bottom: isSmallPhone ? 16 : 20,
                      child: MobileDpadController(
                        size: isSmallPhone ? 110 : 130,
                        padding: const EdgeInsets.all(0),
                        onMoveUp: _game.startMoveUp,
                        onMoveDown: _game.startMoveDown,
                        onMoveLeft: _game.startMoveLeft,
                        onMoveRight: _game.startMoveRight,
                        onStopMove: _game.stopMove,
                      ),
                    ),
                  GameHUD(
                    score: _score,
                    health: _health,
                    onBackPressed: _onBackPressed,
                    onMusicPressed: _onMusicPressed,
                    onMenuPressed: _onMenuPressed,
                    isMusicEnabled: _isMusicEnabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_restoreAppOrientation());
    _game.removeFromParent();
    super.dispose();
  }
}

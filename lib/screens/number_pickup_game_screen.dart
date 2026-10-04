import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../services/user_progress_service.dart';
import '../game/math_world_game.dart';
import '../game/npc_question.dart';
import '../game/npc_question_dialog.dart';
import '../game/hud.dart';
import '../widgets/game_joystick.dart';

class NumberPickupGameScreen extends StatefulWidget {
  final int level;
  final String problem;
  final int correctAnswer;

  const NumberPickupGameScreen({
    super.key,
    required this.level,
    required this.problem,
    required this.correctAnswer,
  });

  @override
  State<NumberPickupGameScreen> createState() => _NumberPickupGameScreenState();
}

class _NumberPickupGameScreenState extends State<NumberPickupGameScreen> {
  late int currentLevel;
  late String currentProblem;
  late int currentCorrectAnswer;
  late MathWorldGame gameInstance;
  bool levelCompleted = false;
  int score = 0;
  int health = 3;
  bool isMusicEnabled = true;
  bool _isExitDialogOpen = false;
  bool _isLeaving = false;
  late Future<void> _orientationChange;

  @override
  void initState() {
    super.initState();
    _orientationChange = _requestGameOrientation();
    currentLevel = widget.level;
    currentProblem = widget.problem;
    currentCorrectAnswer = widget.correctAnswer;
    gameInstance = MathWorldGame(
      correctAnswer: currentCorrectAnswer,
      problem: currentProblem,
      onNumberCollected: _onCorrectNumberCollected,
      onWrongNumberCollected: _onWrongNumberCollected,
      onNpcQuestion: _onNpcQuestion,
      onNpcQuestionLocked: _showLockedQuestion,
    );
  }

  Future<void> _requestGameOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('Game orientation set to landscape.');
    } catch (error, stackTrace) {
      debugPrint('Unable to set landscape orientation: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _onNpcQuestion(NpcQuestion question) async {
    final activeGame = gameInstance;
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
      final bool saved;
      try {
        saved = await activeGame.completeNpcQuestion(question.questionNumber);
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

      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activeGame.allNpcQuestionsCompleted
                  ? 'All NPC questions are complete.'
                  : 'Complete Question ${activeGame.currentQuestionNumber} first.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      final isFinalQuestion =
          question.questionNumber == NpcQuestion.all.length;
      setState(() {
        score += 10;
        if (isFinalQuestion) levelCompleted = true;
      });
      if (isFinalQuestion) {
        activeGame.pauseWorld();
        final navigator = Navigator.of(context);
        await _showLevelClearedDialog(navigator);
        if (!mounted) return;
        _isLeaving = true;
        navigator.pop(true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Question ${question.questionNumber} complete! '
            'Question ${activeGame.currentQuestionNumber} unlocked.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => health = health > 0 ? health - 1 : 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Wrong answer. You lost 1 heart. $health remaining. Try again.',
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
    if (health == 0) _showGameOverDialog();
  }

  Future<void> _showLevelClearedDialog(NavigatorState navigator) async {
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Level Cleared!'),
        content: Text('You completed all six NPC challenges.'),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    navigator.pop();
    await dialog;
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

  Future<void> _saveLevelProgress(int level) async {
    await UserProgressService.saveLevelCompletion(level);
  }

  Future<void> _onCorrectNumberCollected() async {
    if (!mounted || levelCompleted) return;

    setState(() {
      levelCompleted = true;
      score += 10;
    });

    // Show correct answer indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Correct!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final navigator = Navigator.of(context);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    navigator.pop(); // Close the correct indicator dialog

    await _saveLevelProgress(currentLevel);

    if (!mounted) return;

    if (currentLevel < 60) {
      setState(() {
        currentLevel += 1;
        final next = _generateNewProblem(currentLevel);
        currentProblem = next['problem'] as String;
        currentCorrectAnswer = next['answer'] as int;
        levelCompleted = false;
        gameInstance = MathWorldGame(
          correctAnswer: currentCorrectAnswer,
          problem: currentProblem,
          onNumberCollected: _onCorrectNumberCollected,
          onWrongNumberCollected: _onWrongNumberCollected,
          onNpcQuestion: _onNpcQuestion,
          onNpcQuestionLocked: _showLockedQuestion,
        );
      });
    } else {
      navigator.pop(true);
    }
  }

  Map<String, Object> _generateNewProblem(int level) {
    int maxNum = level * 5;

    int num1 = (1 + (level - 1) * 2) +
        (DateTime.now().millisecondsSinceEpoch % maxNum);

    int num2 = (1 + (level - 1) * 2) +
        (DateTime.now().millisecondsSinceEpoch % maxNum);

    bool isAddition =
        level <= 5 || (DateTime.now().millisecondsSinceEpoch % 2 == 0);

    if (isAddition) {
      return {
        'problem': '$num1 + $num2 = ?',
        'answer': num1 + num2,
      };
    } else {
      if (num1 < num2) {
        final temp = num1;
        num1 = num2;
        num2 = temp;
      }
      return {
        'problem': '$num1 - $num2 = ?',
        'answer': num1 - num2,
      };
    }
  }

  void _onWrongNumberCollected() {
    if (!mounted || levelCompleted) return;

    setState(() {
      health--;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wrong! Lives left: $health ❌'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );

    if (health <= 0) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over! 💀'),
        content:
            Text('You ran out of lives!\nScore: $score\nLevel: $currentLevel'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to previous screen
            },
            child: const Text('Exit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // Restart the level
              setState(() {
                health = 3;
                score = 0;
                levelCompleted = false;
                gameInstance = MathWorldGame(
                  correctAnswer: currentCorrectAnswer,
                  problem: currentProblem,
                  onNumberCollected: _onCorrectNumberCollected,
                  onWrongNumberCollected: _onWrongNumberCollected,
                  onNpcQuestion: _onNpcQuestion,
                  onNpcQuestionLocked: _showLockedQuestion,
                );
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onBackPressed() {
    _showExitDialog();
  }

  void _onMusicPressed() {
    setState(() {
      isMusicEnabled = !isMusicEnabled;
    });
  }

  void _onMenuPressed() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Level: $currentLevel'),
              Text('Score: $score'),
              Text('Health: $health'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Resume'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showExitDialog();
              },
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
    final double minSide = min(screenSize.width, screenSize.height);
    final double edgePadding = (minSide * 0.04).clamp(12.0, 20.0);
    final double directionButtonSize = (minSide * 0.11).clamp(44.0, 56.0);
    final double directionContainerSize =
        (directionButtonSize * 2.1).clamp(110.0, 140.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFD09F5C),
        body: FutureBuilder<void>(
          future: _orientationChange,
          builder: (context, orientationSnapshot) {
            if (orientationSnapshot.connectionState != ConnectionState.done) {
              return _buildLoadingState();
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: GameWidget(
                    game: gameInstance,
                    loadingBuilder: (_) => _buildLoadingState(),
                    errorBuilder: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to load Game Mode.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _showExitDialog,
                              child:
                                  const Text('Return to the previous screen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      GameHUD(
                        score: score,
                        health: health,
                        onBackPressed: _onBackPressed,
                        onMusicPressed: _onMusicPressed,
                        onMenuPressed: _onMenuPressed,
                        isMusicEnabled: isMusicEnabled,
                      ),
                      Positioned(
                        left: edgePadding,
                        bottom: edgePadding,
                        child: GameJoystick(
                          size: directionContainerSize,
                          onJoystickChanged: (offset) {
                            if (offset.dx.abs() > offset.dy.abs()) {
                              gameInstance.stopMove();
                              if (offset.dx > 0.3) {
                                gameInstance.startMoveRight();
                              } else if (offset.dx < -0.3) {
                                gameInstance.startMoveLeft();
                              }
                            } else {
                              gameInstance.stopMove();
                              if (offset.dy > 0.3) {
                                gameInstance.startMoveDown();
                              } else if (offset.dy < -0.3) {
                                gameInstance.startMoveUp();
                              }
                            }
                          },
                          onJoystickEnd: gameInstance.stopMove,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const ColoredBox(
      color: Color(0xFF17202A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading Game...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    if (!mounted || _isExitDialogOpen || _isLeaving) return;
    _isExitDialogOpen = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Level?'),
        content: const Text('Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () {
              _isExitDialogOpen = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _confirmExit(context),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit(BuildContext dialogContext) async {
    if (_isLeaving) return;
    _isLeaving = true;
    _isExitDialogOpen = false;
    final navigator = Navigator.of(context);
    Navigator.pop(dialogContext);
    if (mounted && navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _restoreAppOrientation() async {
    try {
      await _orientationChange;
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      debugPrint('Restored portrait orientation after Game Mode.');
    } catch (error, stackTrace) {
      debugPrint('Unable to restore portrait orientation: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    unawaited(_restoreAppOrientation());
    gameInstance.removeFromParent();
    super.dispose();
  }
}

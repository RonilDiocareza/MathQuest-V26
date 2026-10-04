import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/math_background.dart';
import 'number_pickup_game_screen.dart';

class MathProblemScreen extends StatefulWidget {
  final int level;

  const MathProblemScreen({super.key, required this.level});

  @override
  State<MathProblemScreen> createState() => _MathProblemScreenState();
}

class _MathProblemScreenState extends State<MathProblemScreen> {
  late int currentLevel;
  late String problem;
  late int correctAnswer;

  final TextEditingController answerController = TextEditingController();

  String feedback = '';
  bool isCorrect = false;
  bool isWaitingNextQuestion = false;
  bool _isSubmitting = false;
  bool _isGameModeUnlocked = false;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    generateProblem();
    _loadGameModeAccess();
  }

  Future<void> _loadGameModeAccess() async {
    final progress = await UserProgressService.getCurrentUserProgress();
    if (!mounted) return;
    setState(() {
      _isGameModeUnlocked = progress.completedLevels.contains(currentLevel);
    });
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  void generateProblem() {
    int maxNum = currentLevel * 5;

    int num1 = (1 + (currentLevel - 1) * 2) +
        (DateTime.now().millisecondsSinceEpoch % maxNum);

    int num2 = (1 + (currentLevel - 1) * 2) +
        (DateTime.now().millisecondsSinceEpoch % maxNum);

    bool isAddition =
        currentLevel <= 5 || (DateTime.now().millisecondsSinceEpoch % 2 == 0);

    if (isAddition) {
      problem = '$num1 + $num2 = ?';
      correctAnswer = num1 + num2;
    } else {
      if (num1 < num2) {
        final temp = num1;
        num1 = num2;
        num2 = temp;
      }
      problem = '$num1 - $num2 = ?';
      correctAnswer = num1 - num2;
    }
  }

  Future<void> _saveLevelProgress(int level) async {
    await UserProgressService.saveLevelCompletion(level);
  }

  Future<void> checkAnswer() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final userAnswer = int.tryParse(answerController.text);

    if (userAnswer == null) {
      setState(() {
        feedback = 'Enter number!';
        isCorrect = false;
        _isSubmitting = false;
      });
      return;
    }

    if (userAnswer == correctAnswer) {
      setState(() {
        feedback = 'Correct!';
        isCorrect = true;
        isWaitingNextQuestion = true;
      });

      await _saveLevelProgress(currentLevel);

      if (mounted) {
        setState(() {
          _isGameModeUnlocked = true;
        });
      }

      if (currentLevel < 60) {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return;
        setState(() {
          currentLevel += 1;
          _isGameModeUnlocked = false;
          answerController.clear();
          feedback = '';
          isCorrect = false;
          isWaitingNextQuestion = false;
          _isSubmitting = false;
          generateProblem();
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) Navigator.pop(context, true);
      }
    } else {
      setState(() {
        feedback = 'Wrong!';
        isCorrect = false;
        _isSubmitting = false;
      });
    }
  }

  void _launchGameMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NumberPickupGameScreen(
          level: currentLevel,
          problem: problem,
          correctAnswer: correctAnswer,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  //  BACK BUTTON FUNCTION
  void goBack() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Level?'),
        content: const Text('Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back screen
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                const SizedBox(height: 30),
                Text(
                  'Level $currentLevel',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        problem,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        hint: 'Answer',
                        controller: answerController,
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        text: 'Submit',
                        onPressed: (_isSubmitting || isWaitingNextQuestion) ? null : checkAnswer,
                      ),
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(
                  color: Colors.white,
                  thickness: 2,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Or Play the Game!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🎮 Move around the map and collect the correct number to answer the problem!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                CustomButton(
                  text: 'Play Game Mode',
                  onPressed: _isGameModeUnlocked ? _launchGameMode : null,
                ),
                if (!_isGameModeUnlocked) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Complete this Problem Level to unlock Game Mode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Back',
                  onPressed: goBack,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

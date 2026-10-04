import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';
import '../widgets/math_background.dart';

class BadgeInfo {
  final String id;
  final String title;
  final String description;
  final String lockedHint;
  final IconData icon;
  final Color color;
  final bool Function(BadgeProgress) unlockCondition;

  const BadgeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.lockedHint,
    required this.icon,
    required this.color,
    required this.unlockCondition,
  });
}

class BadgeProgress {
  final int completedLevels;
  final int unlockedLevels;
  final int questAttempts;

  const BadgeProgress({
    required this.completedLevels,
    required this.unlockedLevels,
    required this.questAttempts,
  });
}

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  bool _loading = true;
  late BadgeProgress _progress;

  static final List<BadgeInfo> _badges = [
    BadgeInfo(
      id: 'first_win',
      title: 'First Win',
      description: 'Complete The First Level.',
      lockedHint: 'Complete one level to unlock.',
      icon: Icons.celebration,
      color: Color(0xFF9C27B0),
      unlockCondition: (progress) => progress.completedLevels >= 1,
    ),
    BadgeInfo(
      id: 'math_whiz',
      title: 'Math Whiz',
      description: 'Solve 10 story levels.',
      lockedHint: 'Complete 10 levels to unlock.',
      icon: Icons.star,
      color: Color(0xFFFFC107),
      unlockCondition: (progress) => progress.completedLevels >= 10,
    ),
    BadgeInfo(
      id: 'speed_solver',
      title: 'Speed Solver',
      description: 'Stay active with classroom quests.',
      lockedHint: 'Attempt at least 3 classroom quests.',
      icon: Icons.flash_on,
      color: Color(0xFF4CAF50),
      unlockCondition: (progress) => progress.questAttempts >= 3,
    ),
    BadgeInfo(
      id: 'level_up',
      title: 'Level Up',
      description: 'Unlock a new chapter.',
      lockedHint: 'Unlock Level 2 by finishing all of Level 1.',
      icon: Icons.rocket_launch,
      color: Color(0xFFFF5722),
      unlockCondition: (progress) => progress.unlockedLevels >= 2,
    ),
    BadgeInfo(
      id: 'puzzle_master',
      title: 'Puzzle Master',
      description: 'Complete 20 levels.',
      lockedHint: 'Complete 20 story levels to unlock.',
      icon: Icons.extension,
      color: Color(0xFF2196F3),
      unlockCondition: (progress) => progress.completedLevels >= 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBadgeProgress();
  }

  Future<void> _loadBadgeProgress() async {
    final progress = await UserProgressService.getCurrentUserProgress();

    setState(() {
      _progress = BadgeProgress(
        completedLevels: progress.completedCount,
        unlockedLevels: progress.unlockedLevels,
        questAttempts: progress.questAttempts,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD09F5C),
        title: const Text('Badges'),
        centerTitle: true,
        elevation: 0,
      ),
      body: MathBackground(
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your badge collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    itemCount: _badges.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final badge = _badges[index];
                      final isUnlocked = badge.unlockCondition(_progress);
                      return GestureDetector(
                        onTap: () {
                          final message = isUnlocked
                              ? '${badge.title} is unlocked!'
                              : badge.lockedHint;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: isUnlocked
                                      ? Colors.transparent
                                      : Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? badge.color
                                          : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isUnlocked
                                          ? badge.icon
                                          : Icons.lock,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    badge.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked
                                          ? Colors.black87
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        badge.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isUnlocked
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isUnlocked ? 'Unlocked' : 'Locked',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked
                                          ? Colors.green
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isUnlocked)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.72),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

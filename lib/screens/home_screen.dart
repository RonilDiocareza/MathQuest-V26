import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/math_background.dart';
import '../services/profile_service.dart';
import 'badges_screen.dart';
import 'story_levels_screen.dart';
import 'classroom_quest_screen.dart';
import 'teacher_analytics_screen.dart';
import 'profile_screen.dart';
import 'modules_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ProfileService _profileService;
  Uint8List? _profilePhoto;
  String _userName = '';
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final photoFile = await _profileService.getProfilePhoto();
      final profile = await _profileService.loadProfile();
      if (!mounted) return;
      setState(() {
        _profilePhoto = photoFile;
        _userName = profile['name'] ?? '';
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to load optional home profile data: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildHomeContent(context),
              Positioned(
                top: 18,
                right: 18,
                child: GestureDetector(
                  onTap: () => _openProfileDialog(context),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _profilePhoto != null
                        ? ClipOval(
                            child: Image.memory(
                              _profilePhoto!,
                              fit: BoxFit.cover,
                              width: 54,
                              height: 54,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: const Color(0xFFD09F5C),
                            child: Text(
                              _userName.isEmpty ? 'S' : _userName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileDialog(BuildContext context) {
    if (_isDialogOpen) return; // Prevent multiple dialogs

    _isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ProfileScreen(
          isDialog: true,
          onClose: () {
            Navigator.pop(context);
            _loadProfileData(); // Reload profile data when dialog closes
          },
        ),
      ),
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  Widget _buildHomeContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 72, 20, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 84).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  menuCard(
                    context,
                    Icons.view_module,
                    'Module',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ModulesScreen(),
                      ),
                    ),
                  ),
                  menuCard(
                    context,
                    Icons.menu_book,
                    'Levels',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StoryLevelsScreen(),
                      ),
                    ),
                  ),
                  menuCard(
                    context,
                    Icons.trending_up,
                    'Classroom Quests',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClassroomQuestScreen(),
                      ),
                    ),
                  ),
                  menuCard(
                    context,
                    Icons.bar_chart,
                    'My Progress',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherAnalyticsScreen(),
                      ),
                    ),
                  ),
                  menuCard(
                    context,
                    Icons.emoji_events,
                    'Badges',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BadgesScreen(),
                      ),
                    ),
                  ),
                  menuCard(
                    context,
                    Icons.leaderboard,
                    'Leaderboard',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    ),
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

  Widget menuCard(
    BuildContext context,
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;

    double cardWidth = screenWidth * 0.82;

    if (cardWidth > 720) cardWidth = 720;
    if (cardWidth < 360) cardWidth = screenWidth - 40;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        constraints: const BoxConstraints(minHeight: 72),
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF1D0AD),
          borderRadius: BorderRadius.circular(18),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 42),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/user_account.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../services/user_progress_service.dart';
import '../widgets/math_background.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserAccount> accounts = [];
  Map<String, UserProgress> progressByEmail = {};
  bool isLoading = true;
  bool isBackfillingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => isLoading = true);
    final loaded = await AuthService.loadAccounts();
    final progressEntries = await Future.wait(loaded.map((account) async {
      final progress = await UserProgressService.getProgressForUid(account.uid);
      return MapEntry(account.email, progress);
    }));
    setState(() {
      accounts = loaded;
      progressByEmail = Map.fromEntries(progressEntries);
      isLoading = false;
    });
  }

  Future<void> _approveAccount(UserAccount account) async {
    final updatedAccount = account.copyWith(status: 'approved');
    await AuthService.updateAccount(updatedAccount);
    _loadAccounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Student approved successfully.'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteAccount(UserAccount account) async {
    await AuthService.deleteAccount(account);
    _loadAccounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account deleted.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _backfillLeaderboard() async {
    setState(() => isBackfillingLeaderboard = true);
    try {
      final processed = await LeaderboardService.backfillEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Leaderboard synced for $processed approved students.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not sync the leaderboard: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isBackfillingLeaderboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = accounts.where((a) => a.isPending).toList();
    final approvedStudents =
        accounts.where((a) => !a.isAdmin && a.isApproved).toList();

    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final isSmall = media.size.width < 600; // treat <600px as mobile

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: isBackfillingLeaderboard ? null : _backfillLeaderboard,
            icon: isBackfillingLeaderboard
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync leaderboard entries',
          ),
          IconButton(
            onPressed: () {
              AuthService.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fixed background
          Positioned.fill(
            child: IgnorePointer(
              child: MathBackground(
                child: SizedBox.expand(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          // Scrollable content on top — ensure it fills the viewport
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: screenHeight - kToolbarHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 12.0 : 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Student Signups',
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (pending.isEmpty)
                            Text('No pending signups.',
                                style: TextStyle(color: Colors.white70))
                          else
                            ...pending.map(_buildAccountCard),
                          const SizedBox(height: 24),
                          Text(
                            'Approved Students',
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (approvedStudents.isEmpty)
                            Text('No approved student accounts yet.',
                                style: TextStyle(color: Colors.white70))
                          else
                            ...approvedStudents.map(_buildAccountCard),
                          // add some spacing at the bottom so last card isn't flush to edge
                          SizedBox(height: isSmall ? 24 : 48),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(UserAccount account) {
    final isAdmin = account.isAdmin;
    return GestureDetector(
      onTap: () => _showAccountDetails(account),
      child: Card(
        color: const Color(0xFFF1D0AD),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name.isNotEmpty ? account.name : account.email,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      account.email,
                      style: const TextStyle(color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (!isAdmin)
                      Text(
                        'Progress: ${progressByEmail[account.email]?.completedCount ?? 0} levels completed • Highest Level ${progressByEmail[account.email]?.highestCompletedLevel ?? 0}',
                        style: const TextStyle(color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete account',
                  onPressed: () => _deleteAccount(account),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountDetails(UserAccount account) {
    final isAdmin = account.isAdmin;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(account.name.isNotEmpty ? account.name : account.email),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${account.email}'),
              Text('Role: ${account.role}'),
              Text('Status: ${account.status}'),
              if (account.lrn.isNotEmpty) Text('LRN: ${account.lrn}'),
              if (account.address.isNotEmpty)
                Text('Address: ${account.address}'),
              if (!isAdmin) ...[
                const SizedBox(height: 8),
                Text(
                    'Completed levels: ${progressByEmail[account.email]?.completedCount ?? 0}'),
                Text(
                    'Highest completed level: ${progressByEmail[account.email]?.highestCompletedLevel ?? 0}'),
                Text(
                    'Unlocked chapters: ${progressByEmail[account.email]?.unlockedLevels ?? 1}'),
                Text(
                    'Quest attempts: ${progressByEmail[account.email]?.questAttempts ?? 0}'),
              ],
            ],
          ),
          actions: [
            if (account.isPending && !isAdmin)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _approveAccount(account);
                },
                child: const Text('Approve'),
              ),
            if (!isAdmin)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteAccount(account);
                },
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

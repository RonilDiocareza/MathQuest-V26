import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  StreamSubscription<List<LeaderboardEntry>>? _topSubscription;
  StreamSubscription<LeaderboardEntry?>? _currentSubscription;
  List<LeaderboardEntry> _entries = const [];
  LeaderboardEntry? _currentEntry;
  Object? _streamError;
  Object? _syncError;
  int? _currentRank;
  int _rankRequest = 0;
  bool _loading = true;
  bool _rankLoading = true;

  String? get _uid => AuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _loading = false;
        _streamError = StateError('Sign in to view the leaderboard.');
      });
      return;
    }

    _topSubscription = LeaderboardService.watchTopEntries().listen(
      (entries) {
        if (!mounted) return;
        setState(() {
          _entries = entries;
          _loading = false;
          _streamError = null;
        });
        _refreshRank();
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _streamError = error;
        });
      },
    );
    _currentSubscription = LeaderboardService.watchCurrentEntry().listen(
      (entry) {
        if (!mounted) return;
        setState(() {
          _currentEntry = entry;
          _streamError = null;
        });
        _refreshRank();
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _streamError = error);
      },
    );
    unawaited(_syncCurrentEntry());
  }

  Future<void> _syncCurrentEntry() async {
    try {
      await LeaderboardService.syncCurrentEntry();
      if (mounted) setState(() => _syncError = null);
    } catch (error) {
      if (mounted) setState(() => _syncError = error);
    }
  }

  Future<void> _refreshRank() async {
    final entry = _currentEntry;
    final request = ++_rankRequest;
    if (entry == null) {
      if (mounted) {
        setState(() {
          _currentRank = null;
          _rankLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _rankLoading = true);
    try {
      final rank = await LeaderboardService.getRank(entry);
      if (!mounted || request != _rankRequest) return;
      setState(() {
        _currentRank = rank;
        _rankLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _rankRequest) return;
      setState(() {
        _streamError = error;
        _rankLoading = false;
      });
    }
  }

  Future<void> _retry() async {
    await _topSubscription?.cancel();
    await _currentSubscription?.cancel();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _streamError = null;
      _syncError = null;
    });
    _start();
  }

  @override
  void dispose() {
    _topSubscription?.cancel();
    _currentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final isCurrentInTop = _entries.any((entry) => entry.uid == uid);
    final displayName = _currentEntry?.displayName ?? 'Loading profile...';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFFD09F5C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _streamError != null
            ? _buildError()
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_syncError != null) _buildSyncWarning(),
                      _buildCurrentSummary(displayName),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Text(
                          'TOP ${LeaderboardService.pageSize}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF74512C),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _entries.isEmpty
                            ? const Center(child: Text('No scores yet.'))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount:
                                    _entries.length + (isCurrentInTop ? 0 : 1),
                                itemBuilder: (context, index) {
                                  if (index == _entries.length) {
                                    final entry = _currentEntry;
                                    if (entry == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Column(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Divider(),
                                        ),
                                        _buildEntryRow(
                                          entry,
                                          _currentRank,
                                          isCurrent: true,
                                        ),
                                      ],
                                    );
                                  }
                                  final entry = _entries[index];
                                  return _buildEntryRow(
                                    entry,
                                    index + 1,
                                    isCurrent: entry.uid == uid,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCurrentSummary(String displayName) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: const Color(0xFFFFE4BC),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFD09F5C),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Rank: ${_rankLoading ? '...' : _currentRank == null ? '—' : '#$_currentRank'}',
                  ),
                ],
              ),
            ),
            Text(
              _formatScore(_currentEntry?.totalScore ?? 0),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF744411),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(
    LeaderboardEntry entry,
    int? rank, {
    required bool isCurrent,
  }) {
    final rankLabel = rank == null ? '—' : '$rank';
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isCurrent ? const Color(0xFFFFE4BC) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 55,
              child: Text(
                medal == null ? rankLabel : '$medal $rankLabel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatScore(entry.totalScore),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncWarning() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: const Color(0xFFFFF0D5),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: const Text(
                  'Your score could not be refreshed right now.',
                ),
              ),
              TextButton(
                onPressed: _syncCurrentEntry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load the leaderboard. Please try again.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _retry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }
}

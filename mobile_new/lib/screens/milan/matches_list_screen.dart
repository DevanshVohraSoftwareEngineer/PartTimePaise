import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../managers/matches_provider.dart';
import '../../parts/match_celebration_dialog.dart';
import '../../managers/auth_provider.dart';
import '../../managers/fees_manager.dart';
import '../../services/supabase_service.dart';
import '../../data_types/task_match.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchesProvider.notifier).loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchesState = ref.watch(matchesProvider);
    final currentUser = ref.watch(currentUserProvider);
    return DefaultTabController(
      length: 2, // Always show both: Active Chats and Interested Users
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matches'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Interested'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
             RefreshIndicator(
               onRefresh: () => ref.read(matchesProvider.notifier).loadMatches(),
               child: _buildMatchesList(matchesState, currentUser),
             ),
             RefreshIndicator(
               onRefresh: () => ref.read(matchesProvider.notifier).loadMatches(),
               child: _buildCandidatesList(matchesState),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatesList(MatchesState state) {
    if (state.candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No new interests yet.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.candidates.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final candidate = state.candidates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: candidate['worker_avatar'] != null 
                    ? NetworkImage(candidate['worker_avatar']) 
                    : null,
                  child: candidate['worker_avatar'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate['worker_name'] ?? 'Worker',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Interested in: ${candidate['task_title']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(
                            ' ${candidate['worker_rating']?.toStringAsFixed(1) ?? 'New'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleAcceptCandidate(candidate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.check),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleRejectCandidate(candidate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRejectCandidate(Map<String, dynamic> candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User?'),
        content: const Text('Are you sure you want to remove this user from your interested list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('YES, REMOVE')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(matchesProvider.notifier).rejectCandidate(
        candidate['task_id'], 
        candidate['worker_id']
      );
    }
  }

  void _handleAcceptCandidate(Map<String, dynamic> candidate) async {
    // Show a loading indicator if possible, or just wait
    try {
      // 1. Accept in Backend
      final matchId = await ref.read(matchesProvider.notifier).acceptCandidate(
         candidate['task_id'], 
         candidate['worker_id']
      );
  
      if (matchId == null) {
        if (mounted) {
          final error = ref.read(matchesProvider).error ?? 'Failed to create match. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
        return;
      }
  
      // 2. Show Celebration
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MatchCelebrationDialog(
          avatarUrl1: ref.read(currentUserProvider)?.avatarUrl ?? '',
          avatarUrl2: candidate['worker_avatar'] ?? '',
          onChatPressed: () {
            Navigator.of(context).pop(); // Close dialog first
            context.push('/matches/$matchId/chat');
          },
          onKeepSwipingPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildMatchesList(MatchesState matchesState, dynamic currentUser) {
     if (matchesState.isLoading) {
        return const Center(child: CircularProgressIndicator());
     }
     
      final activeMatches = matchesState.matches.where((m) {
        final status = m.task?.status;
        final isCompleted = status == 'completed' || status == 'cancelled';
        if (isCompleted) return false;
        
        // Active = has a message that isn't the system message
        return m.lastMessage != null && m.lastMessage != "You matched! Start the conversation.";
      }).toList();

      final pendingMatches = matchesState.matches.where((m) {
        final status = m.task?.status;
        final isCompleted = status == 'completed' || status == 'cancelled';
        if (isCompleted) return false;
        
        // New/Pending = only has system message or no message
        return m.lastMessage == null || m.lastMessage == "You matched! Start the conversation.";
      }).toList();

      if (activeMatches.isEmpty && pendingMatches.isEmpty) {
        return _buildEmptyState();
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeMatches.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('ACTIVE CHATS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            ),
            ...activeMatches.map((match) => _buildMatchCard(match, currentUser)),
            const SizedBox(height: 24),
          ],
          if (pendingMatches.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('NEW MATCHES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            ),
            ...pendingMatches.map((match) => _buildMatchCard(match, currentUser)),
          ],
        ],
      );
  }

  Widget _buildMatchCard(TaskMatch match, dynamic currentUser) {
    final isClient = currentUser?.role == 'client';
    final otherUserName = isClient ? match.workerName : match.clientName;
    final otherUserAvatar = isClient ? match.workerAvatar : match.clientAvatar;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.grey200,
          backgroundImage: otherUserAvatar != null
              ? CachedNetworkImageProvider(otherUserAvatar)
              : null,
          child: otherUserAvatar == null
              ? Text(
                  otherUserName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.navyMedium,
                  ),
                )
              : null,
        ),
        title: Text(
          otherUserName ?? 'Unknown User',
          style: AppTheme.heading3,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (match.task != null)
              Text(
                match.task!.title,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.navyMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (match.lastMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                match.lastMessage!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.grey700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (match.lastMessageAt != null)
              Text(
                _formatTime(match.lastMessageAt!),
                style: AppTheme.caption.copyWith(
                  color: AppTheme.grey500,
                ),
              ),
          ],
        ),
        onTap: () {
          context.push('/matches/${match.id}/chat');
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.grey300,
          ),
          const SizedBox(height: 24),
          Text(
            'No chats yet!',
            style: AppTheme.heading2.copyWith(color: AppTheme.grey700),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find work or workers.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey500),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.go('/swipe');
            },
            child: const Text('Start Swiping'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM dd').format(time);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

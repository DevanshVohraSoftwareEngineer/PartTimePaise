import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../managers/matches_provider.dart';
import '../../managers/auth_provider.dart';
import '../../data_types/task_match.dart';
import '../../config/theme.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          title: Text(
            'Chat', // Changed from 'Messages' to clear up space
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          bottom: TabBar(
            indicatorColor: isDark ? Colors.white : Colors.black,
            indicatorWeight: 3,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
            tabs: const [
              Tab(text: 'MESSAGES'),
              Tab(text: 'INTERESTED'),
            ],
          ),
          actions: [
            if (currentUser?.id.startsWith('00000000') ?? false)
              IconButton(
                icon: const Icon(Icons.bolt, color: Colors.amber),
                onPressed: () => ref.read(matchesProvider.notifier).mockIncomingSwipe(),
                tooltip: "MOCK INTEREST",
              ),
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: isDark ? Colors.white : Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // MESSAGES TAB
            RefreshIndicator(
              onRefresh: () => ref.read(matchesProvider.notifier).loadMatches(),
              child: matchesState.matches.isEmpty
                  ? _buildEmptyState(
                      'No conversations yet',
                      Icons.chat_bubble_outline_rounded,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: matchesState.matches.length,
                      itemBuilder: (context, index) {
                        final match = matchesState.matches[index];
                        return _buildConversationItem(match, currentUser);
                      },
                    ),
            ),

            // INTERESTED TAB
            RefreshIndicator(
              onRefresh: () => ref.read(matchesProvider.notifier).loadMatches(),
              child: matchesState.candidates.isEmpty
                  ? _buildEmptyState(
                      'No new interests',
                      Icons.favorite_border_rounded,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: matchesState.candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = matchesState.candidates[index];
                        return _buildInterestedItem(candidate);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestedItem(Map<String, dynamic> candidate) {
    final String taskId = candidate['task_id'] ?? '';
    final String workerId = candidate['worker_id'] ?? '';
    final String workerName = candidate['worker_name'] ?? 'User';
    final String? workerAvatar = candidate['worker_avatar'];
    final double budget = (candidate['task_budget'] ?? 0).toDouble();
    final String taskTitle = candidate['task_title'] ?? 'Task';
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate remaining time
    final createdAt = DateTime.parse(candidate['created_at']);
    final expiry = createdAt.add(const Duration(minutes: 60));
    final remaining = expiry.difference(DateTime.now());
    
    // SAFETY: If already expired, don't show anyway
    if (remaining.isNegative) {
      return const SizedBox.shrink();
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    final bool isExpiringSoon = remaining.inMinutes < 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  backgroundImage: workerAvatar != null ? CachedNetworkImageProvider(workerAvatar) : null,
                  child: workerAvatar == null ? const Icon(Icons.person, size: 30) : null,
                ),
                if (isExpiringSoon)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.nopeRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    taskTitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₹${budget.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Expires in $timeStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: isExpiringSoon ? AppTheme.nopeRed : Colors.grey,
                          fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _handleAccept(taskId, workerId, workerName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _handleIgnore(taskId, workerId),
                  child: Text(
                    'IGNORE',
                    style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleIgnore(String taskId, String workerId) async {
    await ref.read(matchesProvider.notifier).rejectCandidate(taskId, workerId);
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Candidate removed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleAccept(String taskId, String workerId, String name) async {
    final success = await ref.read(matchesProvider.notifier).acceptCandidate(taskId, workerId);
    if (success != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matched with $name! Starting chat...'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // ✨ AUTO-NAVIGATE TO CHAT after acceptance
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.push('/matches/$success/chat?autofocus=true');
        }
      });
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not accept match. Please try again or check connection.'),
          backgroundColor: AppTheme.nopeRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildConversationItem(TaskMatch match, dynamic currentUser) {
    final bool isClient = currentUser?.role == 'client';
    final otherUserName = isClient ? match.workerName : match.clientName;
    final otherUserAvatar = isClient ? match.workerAvatar : match.clientAvatar;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/matches/${match.id}/chat'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: otherUserAvatar != null ? CachedNetworkImageProvider(otherUserAvatar) : null,
              child: otherUserAvatar == null ? Text(otherUserName?[0] ?? '?') : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUserName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatTime(match.lastMessageAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (match.task != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${match.task!.title} • ₹${match.task!.budget.toInt()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF34C759).withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.lastMessage ?? 'Say hello!',
                          style: TextStyle(
                            fontSize: 14,
                            color: match.unreadCount > 0 ? (isDark ? Colors.white : Colors.black) : Colors.grey[500],
                            fontWeight: match.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (match.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0095F6),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            match.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(time);
  }
}


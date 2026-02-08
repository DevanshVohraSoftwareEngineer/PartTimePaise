import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../managers/matches_provider.dart';
import '../../managers/auth_provider.dart';
import '../../parts/chat_bubble.dart';
import 'package:intl/intl.dart';
import '../../data_types/task_match.dart';
import '../../services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final bool autofocus;

  const ChatScreen({
    super.key,
    required this.matchId,
    this.autofocus = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final matchesState = ref.read(matchesProvider);
    final matchIndex = matchesState.matches.indexWhere((m) => m.id == widget.matchId);
    if (matchIndex != -1) {
      final match = matchesState.matches[matchIndex];
      final expiryTime = match.matchedAt.add(const Duration(hours: 24));
      final now = DateTime.now();
      final difference = expiryTime.difference(now);
      
      setState(() {
        _remainingTime = difference.isNegative ? Duration.zero : difference;
      });
      
      if (difference.isNegative && _countdownTimer?.isActive == true) {
        _countdownTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_remainingTime.inSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat expired. You can no longer send messages.')),
      );
      return;
    }
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatProvider(widget.matchId).notifier).sendMessage(content);
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _onMessageChanged(String value) {
    if (_typingTimer == null || !_typingTimer!.isActive) {
      ref.read(chatProvider(widget.matchId).notifier).sendTypingIndicator(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(chatProvider(widget.matchId).notifier).sendTypingIndicator(false);
      }
    });
  }

  Widget _buildExpiryNotice() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withOpacity(0.05) : Colors.orange.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_delete_outlined, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "24H EPHEMERAL CHAT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "For security and privacy, this chat and all its messages will be permanently deleted 24 hours after the match was created.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTag() {
    final bool isExpired = _remainingTime.inSeconds == 0;
    final String hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final String minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isExpired ? Colors.red : Colors.orange, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 10, color: isExpired ? Colors.red : Colors.orange),
          const SizedBox(width: 4),
          Text(
            isExpired ? "EXPIRED" : "$hours:$minutes:$seconds",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isExpired ? Colors.red : Colors.orange,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _handleVideoCall(BuildContext context, String otherUserName) {
    final matchesState = ref.read(matchesProvider);
    final match = matchesState.matches.firstWhere((m) => m.id == widget.matchId);
    final currentUser = ref.read(currentUserProvider);
    final otherUserId = currentUser?.role == 'client' ? match.workerId : match.clientId;

    ref.read(supabaseServiceProvider).sendCallSignal(
      targetUserId: otherUserId,
      matchId: widget.matchId,
      isVoiceOnly: false,
    );

    context.push('/call/${widget.matchId}', extra: {
      'isVoiceOnly': false,
      'otherUserName': otherUserName,
    });
  }

  void _handleVoiceCall(BuildContext context, String otherUserName) {
    final matchesState = ref.read(matchesProvider);
    final match = matchesState.matches.firstWhere((m) => m.id == widget.matchId);
    final currentUser = ref.read(currentUserProvider);
    final otherUserId = currentUser?.role == 'client' ? match.workerId : match.clientId;

    ref.read(supabaseServiceProvider).sendCallSignal(
      targetUserId: otherUserId,
      matchId: widget.matchId,
      isVoiceOnly: true,
    );

    context.push('/call/${widget.matchId}', extra: {
      'isVoiceOnly': true,
      'otherUserName': otherUserName,
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      _sendMediaMessage(File(image.path), 'image');
    }
  }

  Future<void> _sendMediaMessage(File file, String type) async {
    final url = await ref.read(supabaseServiceProvider).uploadChatMedia(widget.matchId, file);
    if (url != null) {
      ref.read(chatProvider(widget.matchId).notifier).sendMessage(url, type: type);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for safety errors and warn the user
    ref.listen<ChatState>(chatProvider(widget.matchId), (previous, next) {
      if (next.error == 'Message contains prohibited content') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Safety Warning', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: const Text(
              'Your message was blocked because it contains prohibited words (sexual, abusive, or illegal).\n\n'
              'Please keep the conversation professional. Continued violations may result in account suspension.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I UNDERSTAND'),
              ),
            ],
          ),
        );
      }
    });

    final chatState = ref.watch(chatProvider(widget.matchId));
    final currentUser = ref.watch(currentUserProvider);
    final matchesState = ref.watch(matchesProvider);
    
    final matchIndex = matchesState.matches.indexWhere((m) => m.id == widget.matchId);
    if (matchIndex == -1) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final match = matchesState.matches[matchIndex];
    final isClient = currentUser?.role == 'client';
    final otherUserName = isClient ? match.workerName : match.clientName;
    final otherUserAvatar = isClient ? match.workerAvatar : match.clientAvatar;
    final otherUserVerified = (isClient ? match.workerVerificationStatus : match.clientVerificationStatus) == 'verified';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: otherUserAvatar != null ? CachedNetworkImageProvider(otherUserAvatar) : null,
              child: otherUserAvatar == null ? Text(otherUserName?[0] ?? '?', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Text(
                         otherUserName ?? 'Unknown',
                         style: TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.bold,
                           color: isDark ? Colors.white : Colors.black87,
                         ),
                       ),
                       if (otherUserVerified) ...[
                         const SizedBox(width: 4),
                         const Icon(Icons.verified, size: 14, color: Color(0xFF0095F6)),
                       ],
                       const SizedBox(width: 8),
                       _buildCountdownTag(),
                     ],
                   ),
                  Text(
                    chatState.isOtherUserOnline ? 'Active now' : 'Active sometime ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: chatState.isOtherUserOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_outlined, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => _handleVoiceCall(context, otherUserName ?? 'User'),
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => _handleVideoCall(context, otherUserName ?? 'User'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Permanent Action Bar (Realtime synced)
          _buildActionOverlay(match, isClient),
          
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: chatState.messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildExpiryNotice();
                      }
                      
                      final message = chatState.messages[index - 1];
                      final isCurrentUser = message.senderId == currentUser?.id;
                      bool showDateHeader = false;
                      String dateLabel = '';
                      if (index == 1) {
                        showDateHeader = true;
                      } else {
                        final prevMessage = chatState.messages[index - 2];
                        if (message.timestamp.day != prevMessage.timestamp.day) {
                          showDateHeader = true;
                        }
                      }

                      if (showDateHeader) {
                        final now = DateTime.now();
                        if (message.timestamp.day == now.day && message.timestamp.month == now.month && message.timestamp.year == now.year) {
                          dateLabel = 'TODAY';
                        } else {
                          dateLabel = DateFormat('MMMM dd').format(message.timestamp).toUpperCase();
                        }
                      }

                      return Column(
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                dateLabel,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                              ),
                            ),
                          ChatBubble(message: message, isCurrentUser: isCurrentUser),
                        ],
                      );
                    },
                  ),
          ),
          if (chatState.isTyping)
             Padding(
               padding: const EdgeInsets.only(left: 20, bottom: 8),
               child: Row(
                 children: [
                   Text('${otherUserName ?? 'Someone'} is typing...', 
                     style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                 ],
               ),
             ),
          _buildPremiumInput(),
        ],
      ),
    );
  }

  Widget _buildActionOverlay(TaskMatch match, bool isClient) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final budget = match.task?.budget ?? 0;
    final isLocked = match.task?.status == 'in_progress';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (match.task?.title ?? 'GIG').toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${budget.toInt()}',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w900, 
                    color: isLocked ? AppTheme.electricMedium : (isDark ? Colors.white : Colors.black)
                  ),
                ),
              ],
            ),
          ),
          if (isClient && !isLocked)
            ElevatedButton(
              onPressed: () => _finalizeDeal(match.taskId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('FINALIZE DEAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: Color(0xFF0EA5E9)),
                  SizedBox(width: 4),
                  Text(
                    'DEAL LOCKED', 
                    style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 11)
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _finalizeDeal(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock this deal?'),
        content: const Text('This will move the task to "In Progress". Both parties will see a confirmed green checkmark.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NOT YET')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CONFIRM')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(supabaseServiceProvider).updateTask(taskId, {'status': 'in_progress'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal Finalized! 🚀'), backgroundColor: Color(0xFF22C55E)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildPremiumInput() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.camera_alt_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                autofocus: widget.autofocus,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onMessageChanged,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              final isNotEmpty = value.text.trim().isNotEmpty;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isNotEmpty
                    ? TextButton(
                        onPressed: _sendMessage,
                        child: const Text(
                          'Send',
                          style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.mic_none_rounded, color: isDark ? Colors.white70 : Colors.black54),
                            onPressed: () {}, 
                          ),
                          IconButton(
                            icon: Icon(Icons.image_outlined, color: isDark ? Colors.white70 : Colors.black54),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}


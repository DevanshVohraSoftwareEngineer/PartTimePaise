import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../managers/matches_provider.dart';
import '../../managers/auth_provider.dart';
import '../../parts/chat_bubble.dart';
import 'package:url_launcher/url_launcher.dart';
import '../kaam/live_tracking_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../data_types/task_match.dart';
import '../../services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data_types/user.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;

  const ChatScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatProvider(widget.matchId).notifier).sendMessage(content);
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  Timer? _typingTimer;

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
      final file = File(image.path);
      _sendMediaMessage(file, 'image');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      _sendMediaMessage(file, 'file');
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
    final chatState = ref.watch(chatProvider(widget.matchId));
    final currentUser = ref.watch(currentUserProvider);

    // Get match details
    final matchesState = ref.watch(matchesProvider);
    final matchIndex = matchesState.matches.indexWhere((m) => m.id == widget.matchId);
    
    if (matchIndex == -1) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final match = matchesState.matches[matchIndex];

    final isClient = currentUser?.role == 'client';
    final otherUserName = isClient ? match.workerName : match.clientName;
    final otherUserAvatar = isClient ? match.workerAvatar : match.clientAvatar;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.grey200,
                  backgroundImage: otherUserAvatar != null
                      ? CachedNetworkImageProvider(otherUserAvatar)
                      : null,
                  child: otherUserAvatar == null
                      ? Text(
                          otherUserName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.navyDark,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (chatState.isOtherUserOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759), // iOS Green
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherUserName ?? 'Unknown User',
                    style: TextStyle(
                      fontSize: 16, 
                      color: isDark ? Colors.white : Colors.black87, 
                      fontWeight: FontWeight.w900
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chatState.isTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        color: Color(0xFFC13584), // Instagram gradient-ish
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (chatState.isOtherUserPresent)
                    const Text(
                      'In Chat',
                      style: TextStyle(color: Color(0xFF34C759), fontSize: 11, fontWeight: FontWeight.bold),
                    )
                  else
                    Text(
                      chatState.isOtherUserOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: chatState.isOtherUserOnline ? const Color(0xFF34C759) : Colors.grey, 
                        fontSize: 11,
                        fontWeight: chatState.isOtherUserOnline ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, size: 22),
            onPressed: () => _handleVoiceCall(context, otherUserName ?? 'User'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => _handleVideoCall(context, otherUserName ?? 'User'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Details
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Trust Panel (KYC) - Refined
          _buildKYCPanel(match, isClient),
          
          // Negotiation Panel - Refined
          _buildNegotiationPanel(match, isClient),

          // Messages list
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      final isCurrentUser =
                          message.senderId == currentUser?.id;

                      // Date Grouping
                      bool showDateHeader = false;
                      String dateLabel = '';
                      if (index == 0) {
                        showDateHeader = true;
                      } else {
                        final prevDate = chatState.messages[index - 1].timestamp;
                        if (message.timestamp.day != prevDate.day ||
                            message.timestamp.month != prevDate.month ||
                            message.timestamp.year != prevDate.year) {
                          showDateHeader = true;
                        }
                      }

                      if (showDateHeader) {
                        final now = DateTime.now();
                        if (message.timestamp.day == now.day && 
                            message.timestamp.month == now.month && 
                            message.timestamp.year == now.year) {
                          dateLabel = 'TODAY';
                        } else if (message.timestamp.day == now.subtract(const Duration(days: 1)).day) {
                          dateLabel = 'YESTERDAY';
                        } else {
                          dateLabel = DateFormat('MMM dd, yyyy').format(message.timestamp).toUpperCase();
                        }
                      }

                      return Column(
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ChatBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Snapchat/Instagram Style Input
          _buildChatInput(context, chatState, currentUser, otherUserName),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context, ChatState chatState, User? currentUser, String? otherUserName) {
    // Logic: Chat is locked if:
    // 1. Current user has sent a message
    // 2. Other user has NOT replied yet
    // Exceptions: First message is always allowed, and system messages don't count as "chats".
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final messagesFromOthers = chatState.messages.where((m) => m.senderId != currentUser?.id && m.type != 'system').toList();
    final messagesFromMe = chatState.messages.where((m) => m.senderId == currentUser?.id && m.type != 'system').toList();
    
    final bool isWaitingForReply = messagesFromMe.isNotEmpty && messagesFromOthers.isEmpty;

    if (isWaitingForReply) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
        ),
        child: Column(
          children: [
            Text(
              'Waiting for $otherUserName to reply',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can send more messages once they respond.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
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
                  if (_messageController.text.trim().isEmpty) ...[
                    IconButton(
                      icon: Icon(Icons.mic_none_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                      onPressed: () {
                        // TODO: Voice message implementation
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.attach_file_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                      onPressed: _pickFile,
                    ),
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ] else
                    TextButton(
                      onPressed: _sendMessage,
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          color: Color(0xFF0095F6), // Instagram Blue
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationPanel(TaskMatch match, bool isClient) {
    if (match.status != 'active') return const SizedBox.shrink();

    final budget = match.task?.budget ?? 0;
    final taskStatus = match.task?.status ?? 'assigned';
    final isFinalized = taskStatus == 'in_progress' || taskStatus == 'completed';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OFFER PRICE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
              ),
              Text(
                '₹${budget.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF075E54)),
              ),
            ],
          ),
          const Spacer(),
          if (isClient && !isFinalized)
            ElevatedButton(
              onPressed: () => _finalizeDeal(match.taskId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('FINALIZE DEAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else if (isFinalized)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E9F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('DEAL LOCKED', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Future<void> _finalizeDeal(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock this deal?'),
        content: const Text('Once finalized, the worker can start the task. The price will be locked for transparency.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NOT YET')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOCK DEAL')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(supabaseServiceProvider).updateTask(taskId, {'status': 'in_progress'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal Finalized! Worker can now start work.'), backgroundColor: Color(0xFF25D366)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildKYCPanel(TaskMatch match, bool isClient) {
    final otherFaceUrl = isClient ? match.workerSelfieUrl : match.clientSelfieUrl;
    final otherIdUrl = isClient ? match.workerIdCardUrl : match.clientIdCardUrl;
    final status = isClient ? match.workerVerificationStatus : match.clientVerificationStatus;
    
    final isVerified = status == 'verified';

    return GestureDetector(
      onTap: () => _showKYCDetails(context, match, isClient),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isVerified ? const Color(0xFF25D366) : Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.gpp_maybe, 
              color: isVerified ? const Color(0xFF25D366) : Colors.orange, 
              size: 20
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Identity Verified' : 'Identity Verification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13, 
                      color: isVerified ? const Color(0xFF075E54) : Colors.orange.shade900
                    ),
                  ),
                  Text(
                    isVerified ? 'Tap to view ID and Face photo' : 'Verification pending or incomplete',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (otherFaceUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: CachedNetworkImageProvider(otherFaceUrl),
              )
            else if (otherIdUrl != null)
              const Icon(Icons.badge, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }

  void _showKYCDetails(BuildContext context, TaskMatch match, bool isClient) {
    final otherFaceUrl = isClient ? match.workerSelfieUrl : match.clientSelfieUrl;
    final otherIdUrl = isClient ? match.workerIdCardUrl : match.clientIdCardUrl;
    final status = isClient ? match.workerVerificationStatus : match.clientVerificationStatus;
    final otherName = isClient ? match.workerName : match.clientName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('User Verification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  status == 'verified' ? Icons.verified : Icons.info_outline,
                  color: status == 'verified' ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'verified' ? 'Trust Score: 100% Verified Profile' : 'Verification status: ${status ?? 'None'}',
                  style: TextStyle(
                    color: status == 'verified' ? Colors.green : Colors.orange, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            
            Text('$otherName\'s Face Photo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: otherFaceUrl != null 
                ? CachedNetworkImage(
                    imageUrl: otherFaceUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 180, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.error))),
                  )
                : Container(height: 180, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.face, size: 50, color: Colors.grey))),
            ),
            
            const SizedBox(height: 24),
            
            Text('$otherName\'s Identity Card', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: otherIdUrl != null
                ? CachedNetworkImage(
                    imageUrl: otherIdUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 180, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.error))),
                  )
                : Container(height: 180, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.badge, size: 50, color: Colors.grey))),
            ),
            
            const Spacer(),
            const Text(
              'User verification records are based on submitted Government/College IDs.\nMisuse of this platform results in permanent ban and legal action.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../config/theme.dart';

class MatchCelebrationDialog extends StatefulWidget {
  final String avatarUrl1;
  final String avatarUrl2;
  final VoidCallback onChatPressed;
  final VoidCallback onKeepSwipingPressed;
  final VoidCallback? onVerifyIdentityPressed; // Added callback

  const MatchCelebrationDialog({
    Key? key,
    required this.avatarUrl1,
    required this.avatarUrl2,
    required this.onChatPressed,
    required this.onKeepSwipingPressed,
    this.onVerifyIdentityPressed,
  }) : super(key: key);

  @override
  State<MatchCelebrationDialog> createState() => _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<MatchCelebrationDialog> {
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 3));
    _controllerCenter.play();
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Overlay
        Container(color: Colors.black87),
        
        // Confetti
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _controllerCenter,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false, 
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ], 
          ),
        ),

        // Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Transform.rotate(
                angle: -5 * pi / 180,
                child: Text(
                  "DEAL ACCEPTED!",
                  style: TextStyle(
                    fontFamily: 'Roboto', // Or custom font
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.likeGreen,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Avatars
              SizedBox(
                height: 160,
                width: 300,
                child: Stack(
                  children: [
                    // Left Avatar
                    Positioned(
                      left: 20,
                      child: _buildAvatar(widget.avatarUrl1, -10),
                    ),
                    // Right Avatar
                    Positioned(
                      right: 20,
                      child: _buildAvatar(widget.avatarUrl2, 10),
                    ),
                    // Work Bag Icon in Center
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.work, color: AppTheme.navyMedium, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "You and your candidate have a deal!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Buttons
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: widget.onChatPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("SEND A MESSAGE"),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 250,
                child: OutlinedButton(
                  onPressed: widget.onKeepSwipingPressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("KEEP SWIPING", style: TextStyle(color: Colors.white)),
                ),
              ),
              if (widget.onVerifyIdentityPressed != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: widget.onVerifyIdentityPressed,
                  icon: const Icon(Icons.verified_user, color: Colors.white70),
                  label: const Text(
                    "Verify Identity",
                    style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String url, double angle) {
    bool isPlaceholder = url.contains('via.placeholder.com') || url.isEmpty;
    
    return Transform.rotate(
      angle: angle * pi / 180,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: !isPlaceholder ? CachedNetworkImageProvider(url) : null,
          child: (isPlaceholder)
              ? Icon(Icons.person, size: 40, color: Colors.grey[400])
              : null,
        ),
      ),
    );
  }
}

class KYCViewerDialog extends StatelessWidget {
  final String idCardUrl;
  final String selfieUrl;

  const KYCViewerDialog({
    super.key,
    required this.idCardUrl,
    required this.selfieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Verified Identity', style: AppTheme.heading3),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                selfieUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 200, 
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Verified Selfie', style: AppTheme.caption),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
             ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                idCardUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                 errorBuilder: (c, e, s) => Container(
                  height: 200, 
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
             const SizedBox(height: 8),
            Text('Government ID', style: AppTheme.caption),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

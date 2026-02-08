import 'package:flutter/material.dart';
// Added for ImageFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../data_types/task.dart';
import '../config/theme.dart';
import '../utils/distance_calculator.dart';
import '../widgets/glass_card.dart';
import '../widgets/countdown_timer.dart';

import '../utils/haptics.dart';

class SwipeCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;

  const SwipeCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3), // Increased from 2 to 3 seconds to reduce CPU usage
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the "Premium" glow
    final bool isHighlyReliable = (widget.task.clientRating ?? 0) >= 4.5;

    return GestureDetector(
      onTap: () {
        AppHaptics.light(); // ⚡ Tactile Tap Feedback
        if (widget.onTap != null) widget.onTap!();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: isHighlyReliable ? [
            BoxShadow(
              color: AppTheme.boostGold.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ] : null,
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderColor: isHighlyReliable 
              ? AppTheme.boostGold.withOpacity(0.5) 
              : Theme.of(context).primaryColor.withOpacity(0.3),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Header area with Authenticity Proofs (Replaces Task Photos)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                            ),
                            itemBuilder: (context, index) => const Icon(Icons.security, color: Colors.white),
                          ),
                        ),
                      ),

                      // Verification Vault UI
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.greenAccent),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user, color: Colors.greenAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'IDENTITY VERIFIED',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 1. Real-time Photo
                                _buildBlurredProof(
                                  label: 'Real-time Photo',
                                  imageUrl: widget.task.clientFaceUrl ?? widget.task.clientAvatar, 
                                  icon: Icons.face,
                                ),
                                const SizedBox(width: 24),
                                // 2. College ID
                                _buildBlurredProof(
                                  label: 'College ID Card',
                                  imageUrl: widget.task.clientIdCardUrl, 
                                  icon: Icons.credit_card,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Authenticity Guaranteed',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Distance badge (Keep this as it's useful context)
                      if (widget.task.distanceMeters != null)
                        Positioned(
                          top: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.navyMedium,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DistanceCalculator.formatDistance(
                                      widget.task.distanceMeters!),
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.navyDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Category Chip (Keep this too)
                        Positioned(
                          bottom: 16,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.superLikeBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.task.category,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content area
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.task.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Expanded(
                        child: Text(
                          widget.task.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bottom info row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Budget
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.likeGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '₹',
                                  style: TextStyle(
                                    color: AppTheme.likeGreen,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.task.budget.toStringAsFixed(0),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.likeGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Deadline / Countdown
                          if (widget.task.deadline != null)
                             Row(
                              children: [
                                if (widget.task.deadline!.difference(DateTime.now()).inHours < 24)
                                  CountdownTimer(
                                    expiresAt: widget.task.deadline!,
                                    textStyle: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.getAdaptiveGrey700(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    urgentColor: Colors.red,
                                    normalColor: Colors.orange,
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: AppTheme.getAdaptiveGrey600(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('MMM dd')
                                            .format(widget.task.deadline!),
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.getAdaptiveGrey700(context),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                          // Client rating
                          if (widget.task.clientRating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppTheme.boostGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.clientRating!.toStringAsFixed(1),
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.getAdaptiveGrey700(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBlurredProof({
    required String label,
    required String? imageUrl,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  )
                else
                  Icon(icon, color: Colors.white38, size: 40),
                
                // ✨ Magic: Translucent overlay instead of blur
                Container(color: Colors.black.withOpacity(0.05)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9), // Improved contrast
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

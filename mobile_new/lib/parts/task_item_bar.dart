import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data_types/task.dart';
import '../config/theme.dart';
import '../utils/distance_calculator.dart';
import '../widgets/glass_card.dart';
import '../services/supabase_service.dart';
import '../widgets/countdown_timer.dart';
import 'package:geolocator/geolocator.dart';

class TaskItemBar extends ConsumerStatefulWidget {
  final Task task;
  final Position? currentPosition;
  final VoidCallback onLike;
  final VoidCallback onNope;

  const TaskItemBar({
    super.key,
    required this.task,
    this.currentPosition,
    required this.onLike,
    required this.onNope,
  });

  @override
  ConsumerState<TaskItemBar> createState() => _TaskItemBarState();
}

class _TaskItemBarState extends ConsumerState<TaskItemBar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Track reach when the item is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supabaseServiceProvider).trackTaskView(widget.task.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    String distance = 'Unknown dist';
    if (widget.currentPosition != null && widget.task.pickupLat != null && widget.task.pickupLng != null) {
      final double distMeters = DistanceCalculator.calculateDistance(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
        widget.task.pickupLat!,
        widget.task.pickupLng!,
      );
      distance = DistanceCalculator.formatDistance(distMeters);
    } else if (widget.task.distanceMeters != null) {
      distance = DistanceCalculator.formatDistance(widget.task.distanceMeters!);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // Collapsed Bar State
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Action - Nope
                      _buildCircleButton(Icons.close, Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, widget.onNope),
                      const SizedBox(width: 8),

                      // Mandatory Selfie
                      if (widget.task.clientFaceUrl != null)
                        GestureDetector(
                          onTap: () => _isExpanded ? null : setState(() => _isExpanded = true),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.electricMedium, width: 2),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(widget.task.clientFaceUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(width: 12),
                      
                      // Title and Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 16, 
                                letterSpacing: -0.8
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                CountdownTimer(
                                  expiresAt: widget.task.effectiveExpiresAt,
                                  textStyle: const TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(width: 3, height: 3, decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12, 
                                  shape: BoxShape.circle
                                )),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    _buildRadarDot(),
                                    const SizedBox(width: 4),
                                    Text(distance.toUpperCase(), style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w800, 
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, 
                                      letterSpacing: 0.8
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount
                      Text(
                        '₹${widget.task.budget.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: Theme.of(context).primaryColor, 
                          fontSize: 20,
                          letterSpacing: -1.2,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      // Action - Like
                      _buildCircleButton(Icons.check_rounded, Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, widget.onLike),
                    ],
                  ),
                ),
                
                // Expanded Details
                if (_isExpanded) _buildExpandedContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onTap) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.black : Colors.white, size: 18),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          Text(
            widget.task.description,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Theme.of(context).primaryColor.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(widget.task.category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Poster Info Header
          Text('POSTED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor.withOpacity(0.3), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
                backgroundImage: widget.task.clientAvatar != null 
                    ? CachedNetworkImageProvider(widget.task.clientAvatar!) 
                    : null,
                child: widget.task.clientAvatar == null ? Icon(Icons.person, color: Theme.of(context).primaryColor.withOpacity(0.3)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.task.clientName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    _buildRatingStars(widget.task.clientRating ?? 0),
                  ],
                ),
              ),
              if (widget.task.clientVerificationStatus == 'verified')
                Icon(Icons.verified, color: Theme.of(context).primaryColor, size: 18),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 🛡️ KYC Privacy: IDs are only shown after matching in the chat.
          // The public feed only shows the mandatory selfie in the circle avatar.
        ],
      ),
    );
  }

  Widget _buildMiniProof(String label, String? url, IconData icon) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url != null 
                ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                : Icon(icon, color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRadarDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppTheme.electricMedium,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricMedium,
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 14,
          color: Colors.amber,
        );
      }),
    );
  }
}

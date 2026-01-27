import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../data_types/task.dart';
import '../config/theme.dart';
import '../utils/distance_calculator.dart';
import '../widgets/glass_card.dart';

class TaskItemBar extends StatefulWidget {
  final Task task;
  final VoidCallback onLike;
  final VoidCallback onNope;

  const TaskItemBar({
    Key? key,
    required this.task,
    required this.onLike,
    required this.onNope,
  }) : super(key: key);

  @override
  State<TaskItemBar> createState() => _TaskItemBarState();
}

class _TaskItemBarState extends State<TaskItemBar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(widget.task.createdAt);
    final distance = widget.task.distanceMeters != null 
        ? DistanceCalculator.formatDistance(widget.task.distanceMeters!) 
        : 'Unknown dist';

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
                      _buildCircleButton(Icons.close, Colors.red, widget.onNope),
                      const SizedBox(width: 12),
                      
                      // Title and Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(width: 8),
                                const Text('•', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text(distance, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount
                      Text(
                        '₹${widget.task.budget.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.likeGreen, fontSize: 18),
                      ),
                      
                      const SizedBox(width: 12),
                      // Action - Like
                      _buildCircleButton(Icons.check, Colors.green, widget.onLike),
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
    return GestureDetector(
      onTap: () {
        // Prevent expansion when clicking action buttons
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
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
              const Icon(Icons.category, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text(widget.task.category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Poster Info Header
          const Text('POSTED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.task.clientAvatar != null 
                    ? CachedNetworkImageProvider(widget.task.clientAvatar!) 
                    : null,
                child: widget.task.clientAvatar == null ? const Icon(Icons.person) : null,
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
                const Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // KYC Proofs Row
          const Text('IDENTITY PROOFS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildMiniProof('Face Photo', widget.task.clientFaceUrl, Icons.face),
              const SizedBox(width: 16),
              _buildMiniProof('College ID', widget.task.clientIdCardUrl, Icons.badge),
            ],
          ),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

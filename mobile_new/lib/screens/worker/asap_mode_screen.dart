import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/earnings_provider.dart';
import '../../services/gig_service.dart';
import '../../utils/haptics.dart';

class ASAPModeScreen extends ConsumerStatefulWidget {
  const ASAPModeScreen({super.key});

  @override
  ConsumerState<ASAPModeScreen> createState() => _ASAPModeScreenState();
}

class _ASAPModeScreenState extends ConsumerState<ASAPModeScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Current user and online status from providers
    final isOnline = ref.watch(isOnlineProvider);
    final todayEarnings = ref.watch(todayEarningsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: _buildStatusPill(isOnline),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.luxeBlack,
              isOnline ? AppTheme.luxeDarkGrey : AppTheme.luxeBlack.withOpacity(0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Center CTA Area
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMainCTA(context, isOnline),
                  const SizedBox(height: 32),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _isProcessing ? 0.3 : 1.0,
                    child: Text(
                      isOnline ? "WAITING FOR GIGS..." : "GO ONLINE TO START EARNING",
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (isOnline) ...[
                    const SizedBox(height: 12),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  
                  // ✨ Smart Shortcut Hub (Below logic)
                  _buildQuickActionHub(context),
                ],
              ),
            ),

            // Bottom Earnings Summary
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildEarningsSummary(todayEarnings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline ? AppTheme.likeGreen.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isOnline ? AppTheme.likeGreen.withOpacity(0.5) : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.likeGreen : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isOnline ? [
                BoxShadow(
                  color: AppTheme.likeGreen.withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : [],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isOnline ? "ONLINE" : "OFFLINE",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCTA(BuildContext context, bool isOnline) {
    return GestureDetector(
      onTap: _isProcessing ? null : () => _toggleOnlineStatus(context, isOnline),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse effect when online
          if (isOnline)
            _PulseCircle(color: AppTheme.nopeRed.withOpacity(0.3)),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCirc,
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppTheme.nopeRed : AppTheme.likeGreen,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? AppTheme.nopeRed : AppTheme.likeGreen).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 4,
              ),
            ),
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 6)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOnline ? Icons.power_settings_new : Icons.flash_on,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOnline ? "GO\nOFFLINE" : "GO\nONLINE",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
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

  Widget _buildEarningsSummary(AsyncValue<double> earnings) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S EARNINGS",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                earnings.when(
                  data: (val) => Text(
                    "₹${val.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.cyanAccent),
                  ),
                  error: (_, __) => const Text("₹--", style: TextStyle(color: Colors.white, fontSize: 32)),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 32),
                onPressed: () {
                  // Navigate to detailed earnings
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleOnlineStatus(BuildContext context, bool currentlyOnline) async {
    setState(() => _isProcessing = true);
    AppHaptics.medium();

    try {
      final gigService = ref.read(gigServiceProvider);
      if (currentlyOnline) {
        await gigService.goOffline();
      } else {
        await gigService.goOnline(context);
      }
      
      // Refresh earnings when status changes
      ref.invalidate(todayEarningsProvider);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.nopeRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildQuickActionHub(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            "NEED SOMETHING ELSE?",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModernActionChip(
                context,
                icon: Icons.search_rounded,
                label: "TASK FEED",
                onTap: () => context.go('/swipe'), // Goes to the Today Mode main feed
              ),
              const SizedBox(width: 12),
              _buildModernActionChip(
                context,
                icon: Icons.add_box_rounded,
                label: "POST GIG",
                onTap: () => context.go('/post-task'),
              ),
              const SizedBox(width: 12),
              _buildModernActionChip(
                context,
                icon: Icons.chat_bubble_rounded,
                label: "CHATS",
                onTap: () => context.go('/matches'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionChip(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  final Color color;
  const _PulseCircle({required this.color});

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 220 + (80 * _controller.value),
          height: 220 + (80 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.3 * (1 - _controller.value)),
          ),
        );
      },
    );
  }
}

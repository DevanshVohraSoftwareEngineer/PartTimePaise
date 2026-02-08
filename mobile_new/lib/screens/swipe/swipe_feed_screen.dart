import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../managers/theme_settings_provider.dart';
import '../../managers/nearby_users_provider.dart';
import '../../services/supabase_service.dart';
import '../../parts/task_item_bar.dart';
import '../../widgets/futuristic_background.dart';
import '../../widgets/glass_card.dart';
import '../../utils/haptics.dart';
import '../../data_types/task.dart';
import '../../managers/auth_provider.dart';
import '../../managers/tasks_provider.dart';
import '../../config/theme.dart';
// Assuming this exists for stabilizedLocationProvider

class SwipeFeedScreen extends ConsumerStatefulWidget {
  const SwipeFeedScreen({super.key});

  @override
  ConsumerState<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends ConsumerState<SwipeFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();

    // ✨ UPDATED: Keep user ACTIVE and ONLINE whenever they are on the Home Feed
    // This ensures they are visible to others for matching/chatting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).toggleOnlineStatus(true);
      ref.read(supabaseServiceProvider).setUserOnline(true);
    });
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Only update if moved 50m
      ),
    ).listen((pos) {
      if (mounted) {
        // Only trigger update if moved significantly to avoid build loops
        if (_currentPosition == null || 
            Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, pos.latitude, pos.longitude) > 10) {
          setState(() => _currentPosition = pos);
          // ref.read(stabilizedLocationProvider.notifier).state = pos; // Commented out if not defined
          // ref.read(presenceProvider.notifier).updateLocation(pos.latitude, pos.longitude); // Commented out if not defined or mocked
        }
      }
    });
  }

  void _onAction(Task task, bool liked) {
    // Optimistic UI update for snappy feel, especially for debug/offline
    ref.read(swipedTaskIdsProvider.notifier).addSwipedIdLocally(task.id);
    
    if (liked) {
      _handleLike(task);
    } else {
      _handleNope(task);
    }
  }

  Future<void> _handleLike(Task task) async {
    AppHaptics.light();
    try {
      await ref.read(supabaseServiceProvider).createSwipe(task.id, 'right');
    } catch (e) {
      print('Swipe error: $e');
    }
  }

  Future<void> _handleNope(Task task) async {
    AppHaptics.light();
    try {
      await ref.read(supabaseServiceProvider).createSwipe(task.id, 'left');
    } catch (e) {
      print('Swipe error: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOnline = currentUser?.isOnline ?? false;
    final tasksState = ref.watch(tasksProvider);
    final swipedIds = ref.watch(swipedTaskIdsProvider);
    
    // ✨ THE MARKETPLACE: Show all available tasks (Regular/Today Gigs)
    // Magic Fix: Filter out ASAP tasks because they are handled strictly via the "Direct Request" Overlay system
    final allMarketplaceTasks = tasksState.tasks.where((t) => 
      (t.status == 'open' || t.status == 'broadcasting') &&
      t.clientId != currentUser?.id &&
      !swipedIds.contains(t.id) &&
      t.urgency != 'asap'
    ).toList();

    // Sorting by proximity
    if (_currentPosition != null) {
      allMarketplaceTasks.sort((a, b) {
        if (a.pickupLat == null || a.pickupLng == null) return 1;
        if (b.pickupLat == null || b.pickupLng == null) return -1;
        
        final distA = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude, 
          a.pickupLat!, a.pickupLng!
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude, 
          b.pickupLat!, b.pickupLng!
        );
        return distA.compareTo(distB);
      });
    }

    // Filter out only those that are NOT already swiped (persisted history)
    final swipedTaskIds = ref.watch(swipedTaskIdsProvider);
    
    final marketplaceTasks = allMarketplaceTasks.where((t) => 
      !swipedTaskIds.contains(t.id)
    ).toList();

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isOnline),
              if (currentUser != null) _buildWalletHeader(currentUser),
              
              const Spacer(),

              // HYBRID UI: Tinder Swiper overlaid on Radar Map
              Expanded(
                flex: 10,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1: Radar Map Background
                    _buildRadarMap(isOnline),

                    // Layer 2: Scrollable Marketplace List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: marketplaceTasks.isEmpty 
                        ? (isOnline ? const SizedBox.shrink() : _buildEmptyState())
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: marketplaceTasks.length,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            itemBuilder: (context, index) {
                              final task = marketplaceTasks[index];
                              return TaskItemBar(
                                task: task,
                                onLike: () => _onAction(task, true),
                                onNope: () => _onAction(task, false),
                              );
                            },
                          ),
                    ),
                  
                    // Layer 3: ASAP Scanning UI (Subtle Indicator - NO OVERLAY)
                    if (isOnline && marketplaceTasks.isEmpty)
                      IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Small, subtle indicators only if truly empty
                              Icon(Icons.radar, size: 48, color: AppTheme.electricMedium.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'SCANNING FOR ASAP GIGS',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? AppTheme.electricMedium.withOpacity(0.5) 
                                      : Colors.black.withOpacity(0.4),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (isOnline) const SizedBox.shrink(),
                  ],
                ),
              ),
              
              _buildFooter(isOnline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isOnline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: -1,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              // Realtime Active Users Status
              StreamBuilder<int>(
                stream: ref.read(supabaseServiceProvider).globalOnlineCountStream,
                initialData: 1,
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${snapshot.data ?? 1} ACTIVE NOW',
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          
          // ✨ Magic: Reload/Refresh
          IconButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).loadTasks();
              AppHaptics.medium();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing marketplace gigs...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              Icons.refresh, 
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
              size: 20
            ),
          ),

          // ✨ Magic: Thunder/Money Theme Toggle
          IconButton(
            onPressed: () {
              ref.read(themeSettingsProvider.notifier).toggleTheme();
              AppHaptics.light();
            },
            icon: Icon(
              ref.watch(themeSettingsProvider).backgroundTheme == BackgroundTheme.thunder 
                  ? Icons.bolt 
                  : Icons.attach_money,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.boostGold : Colors.black,
              size: 20,
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: () {
              context.go('/asap-mode');
              AppHaptics.medium();
            },
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderColor: AppTheme.electricMedium.withOpacity(0.3),
              child: Row(
                children: [
                  _buildScanningDot(),
                  const SizedBox(width: 8),
                  Text(
                    'ASAP',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1,
                      color: isDark ? Colors.white : Colors.black,
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

  Widget _buildScanningDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.greenAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.greenAccent, blurRadius: 4, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildWalletHeader(dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: isDark ? Colors.white : Colors.black, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WALLET BALANCE', 
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  )
                ),
                Text(
                  '₹${user.walletBalance?.toStringAsFixed(2) ?? '0.00'}', 
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarMap(bool isOnline) {
    return Opacity(
      opacity: isOnline ? 0.4 : 0.2,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null 
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
            : const LatLng(28.7041, 77.1025),
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        markers: _buildNearbyMarkers(ref),
        circles: {
          if (isOnline && _currentPosition != null)
            Circle(
              circleId: const CircleId('radar_circle'),
              center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              radius: 1500,
              fillColor: AppTheme.electricMedium.withOpacity(0.05),
              strokeColor: AppTheme.electricMedium.withOpacity(0.1),
              strokeWidth: 1,
            ),
        },
      ),
    );
  }

  Set<Marker> _buildNearbyMarkers(WidgetRef ref) {
    final Set<Marker> markers = {};
    
    // 1. Nearby Workers (Muted Gold Pins)
    final nearbyUsers = ref.watch(nearbyUsersProvider);
    for (var user in nearbyUsers) {
      markers.add(Marker(
        markerId: MarkerId('worker_${user.id}'),
        position: LatLng(user.currentLat ?? 0.0, user.currentLng ?? 0.0),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        alpha: 0.6,
        infoWindow: InfoWindow(title: user.name),
      ));
    }

    // 2. Today Tasks (High-Contrast Red Pins)
    final tasksState = ref.watch(tasksProvider);
    final todayTasks = tasksState.tasks.where((t) => t.urgency == 'today' && t.status == 'open').toList();
    for (var task in todayTasks) {
      if (task.pickupLat != null && task.pickupLng != null) {
        markers.add(Marker(
          markerId: MarkerId('task_${task.id}'),
          position: LatLng(task.pickupLat!, task.pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: task.title,
            snippet: '₹${task.budget.toInt()} • Elite Campus',
          ),
          onTap: () {
            // We could show a bottom sheet here
            AppHaptics.light();
          },
        ));
      }
    }

    return markers;
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 64),
        const SizedBox(height: 16),
        Text(
          'ALL CAUGHT UP', 
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isDark ? Colors.white : Colors.black,
          )
        ),
        const SizedBox(height: 8),
        Text(
          'No campus gigs nearby right now.', 
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w600,
          )
        ),
      ],
    );
  }

  Widget _buildFooter(bool isOnline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: isDark ? Colors.white70 : Colors.black87, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOnline 
                  ? 'ASAP MODE: Active standby for elite campus events.'
                  : 'DISCOVER: Explore premium gigs and university services.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

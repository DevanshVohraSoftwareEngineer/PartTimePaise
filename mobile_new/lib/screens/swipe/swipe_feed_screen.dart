import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import '../../services/gig_service.dart';
import '../../config/theme.dart';
import '../../managers/presence_provider.dart';
import '../../managers/location_provider.dart'; // Assuming this exists for stabilizedLocationProvider

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
    
    // ✨ Magic: Auto-Presence (Always active for trial)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isOnline = ref.read(currentUserProvider)?.isOnline ?? false;
      if (!isOnline) {
        ref.read(authProvider.notifier).toggleOnlineStatus(true);
        ref.read(gigServiceProvider).goOnline(context);
      }
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
    // Note: We don't need to add to a local list anymore as the provider's 
    // stream will update the state once the swipe is created in Supabase.
    // However, for snappy UI, we could keep a local set if real-time is slow.
    // For now, let's keep it simple as the stream is usually fast.
    
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
    
    // ✨ THE MARKETPLACE: Only show 'Today' tasks (swipe through available gigs)
    final allTodayTasks = tasksState.tasks.where((t) => 
      t.urgency == 'today' && 
      (t.status == 'open' || t.status == 'broadcasting') &&
      t.clientId != currentUser?.id
    ).toList();

    // Sorting by proximity
    if (_currentPosition != null) {
      allTodayTasks.sort((a, b) {
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
    
    final todayTasks = allTodayTasks.where((t) => 
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
                      child: todayTasks.isEmpty 
                        ? (isOnline ? const SizedBox.shrink() : _buildEmptyState())
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: todayTasks.length,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            itemBuilder: (context, index) {
                              final task = todayTasks[index];
                              return TaskItemBar(
                                task: task,
                                onLike: () => _onAction(task, true),
                                onNope: () => _onAction(task, false),
                              );
                            },
                          ),
                    ),
                  
                    // Layer 3: ASAP Scanning UI (Subtle Indicator - NO OVERLAY)
                    if (isOnline && todayTasks.isEmpty)
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
                                  color: AppTheme.electricMedium.withOpacity(0.5),
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
    final supabase = ref.read(supabaseServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PartTimePaise',
                style: AppTheme.heading1.copyWith(fontSize: 20, color: AppTheme.electricMedium),
              ),
              // Realtime Active Users Status
              StreamBuilder<int>(
                stream: supabase.globalOnlineCountStream,
                initialData: 1,
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${snapshot.data ?? 1} PLAYERS ONLINE',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
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
              color: AppTheme.boostGold,
              size: 20,
            ),
          ),

          const SizedBox(width: 8),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            borderColor: isOnline ? Colors.green.withOpacity(0.5) : Colors.white.withOpacity(0.2),
            child: Row(
              children: [
                if (isOnline) ...[
                  _buildScanningDot(),
                  const SizedBox(width: 8),
                ],
                Text(
                  isOnline ? 'ASAP ON' : 'TODAY',
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: isOnline ? Colors.green : Theme.of(context).textTheme.bodySmall?.color
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: isOnline,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      final gigService = ref.read(gigServiceProvider);
                      if (val) {
                        gigService.goOnline(context);
                      } else {
                        gigService.goOffline();
                      }
                      if (val) AppHaptics.medium();
                    },
                  ),
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WALLET', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(
                  '₹${user.walletBalance?.toStringAsFixed(2) ?? '0.00'}', 
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
    
    // 1. Nearby Workers (Cyan Dots)
    final nearbyUsers = ref.watch(nearbyUsersProvider);
    for (var user in nearbyUsers) {
      markers.add(Marker(
        markerId: MarkerId('worker_${user.id}'),
        position: LatLng(user.currentLat ?? 0.0, user.currentLng ?? 0.0),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        alpha: 0.5,
        infoWindow: InfoWindow(title: user.name),
      ));
    }

    // 2. Today Tasks (Magic Purple Tool Pins)
    final tasksState = ref.watch(tasksProvider);
    final todayTasks = tasksState.tasks.where((t) => t.urgency == 'today' && t.status == 'open').toList();
    for (var task in todayTasks) {
      if (task.pickupLat != null && task.pickupLng != null) {
        markers.add(Marker(
          markerId: MarkerId('task_${task.id}'),
          position: LatLng(task.pickupLat!, task.pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: task.title,
            snippet: '₹${task.budget.toInt()} - Tap to view',
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.done_all, color: AppTheme.likeGreen, size: 64),
        const SizedBox(height: 16),
        Text(
          'ALL CAUGHT UP!', 
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Text(
          'No marketplace gigs (10hr) nearby right now.', 
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
          )
        ),
      ],
    );
  }

  Widget _buildFooter(bool isOnline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.cyanAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOnline 
                  ? 'ASAP MODE: Stand by for high-urgency alarms. High sound and haptics enabled.'
                  : 'TODAY MODE: Swipe right on marketplace gigs to show interest. Clients pick the best match.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

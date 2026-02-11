import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../managers/theme_settings_provider.dart';
import '../../managers/nearby_users_provider.dart';
import '../../managers/matches_provider.dart'; // Added
import 'package:cached_network_image/cached_network_image.dart'; // Added
import '../../services/supabase_service.dart';
import '../../parts/task_item_bar.dart';
import '../../widgets/futuristic_background.dart';
import '../../widgets/glass_card.dart';
import '../../utils/haptics.dart';
import '../../utils/distance_calculator.dart';
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
      // Auth provider state update remains if helpful for UI, 
      // but remote status is now handled globally by PresenceManager/Lifecycle
      ref.read(authProvider.notifier).toggleOnlineStatus(true);
    });
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // ✨ RADAR MODE: Update every 5m for smooth distance changes
      ),
    ).listen((pos) {
      if (mounted) {
        // Only trigger update if moved significantly to avoid build loops
        if (_currentPosition == null || 
            Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, pos.latitude, pos.longitude) > 5) {
          setState(() => _currentPosition = pos);
          // ref.read(stabilizedLocationProvider.notifier).state = pos; // Commented out if not defined
          // ref.read(presenceProvider.notifier).updateLocation(pos.latitude, pos.longitude); // Commented out if not defined or mocked
        }
      }
    });
  }

  void _onAction(Task task, bool liked) async {
    // Optimistic UI update for snappy feel, especially for debug/offline
    
    if (liked) {
      // ✨ REMOVED: Mandatory Verification Photo for Worker Interest
      // Now acts as an instant accept/interest
      ref.read(swipedTaskIdsProvider.notifier).addSwipedIdLocally(task.id);
      _handleLike(task);
    } else {
      ref.read(swipedTaskIdsProvider.notifier).addSwipedIdLocally(task.id);
      _handleNope(task);
    }
  }

  Future<void> _handleLike(Task task) async {
    AppHaptics.light();
    try {
      final isAsap = task.urgency == 'asap';
      final matchId = await ref.read(supabaseServiceProvider).createSwipe(
        task.id, 
        'right',
        isAsap: isAsap,
      );

      // ✨ MAGIC: If it's an ASAP task and match was created, go to Chat!
      if (isAsap && matchId != null && mounted) {
        context.push('/matches/$matchId/chat?autofocus=true');
      }
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
    // Calculate total unread count (unread messages + new interested candidates)
    final matchesState = ref.watch(matchesProvider);
    final unreadCount = matchesState.matches.fold(0, (sum, m) => sum + m.unreadCount) + matchesState.candidates.length;
    final tasksState = ref.watch(tasksProvider);
    final swipedIds = ref.watch(swipedTaskIdsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Task> prepareTasks(List<Task> tasks) {
      if (_currentPosition == null) return tasks;
      
      return tasks.map((t) {
        if (t.pickupLat != null && t.pickupLng != null) {
          final dist = Geolocator.distanceBetween(
            _currentPosition!.latitude, 
            _currentPosition!.longitude, 
            t.pickupLat!, 
            t.pickupLng!
          );
          return t.copyWith(distanceMeters: dist);
        }
        return t;
      }).toList();
    }

    // Sorting logic 
    int sortByProximity(Task a, Task b) {
        if (a.distanceMeters == null) return 1;
        if (b.distanceMeters == null) return -1;
        return a.distanceMeters!.compareTo(b.distanceMeters!);
    }

    final freelanceTasks = prepareTasks(tasksState.tasks.where((t) => 
      (t.status == 'open' || t.status == 'broadcasting') &&
      t.clientId != currentUser?.id &&
      !swipedIds.contains(t.id) &&
      t.urgency != 'asap' &&
      t.category != 'Buy/Sell (Student OLX)'
    ).toList());

    final asapTasks = prepareTasks(tasksState.tasks.where((t) => 
      (t.status == 'open' || t.status == 'broadcasting') &&
      t.clientId != currentUser?.id &&
      !swipedIds.contains(t.id) &&
      t.urgency == 'asap' &&
      t.category != 'Buy/Sell (Student OLX)'
    ).toList());

    final buySellTasks = prepareTasks(tasksState.tasks.where((t) => 
      (t.status == 'open' || t.status == 'broadcasting') &&
      t.clientId != currentUser?.id &&
      !swipedIds.contains(t.id) &&
      t.category == 'Buy/Sell (Student OLX)'
    ).toList());

    if (_currentPosition != null) {
      freelanceTasks.sort(sortByProximity);
      asapTasks.sort(sortByProximity);
      buySellTasks.sort(sortByProximity);
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: FuturisticBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(isOnline),
                
                // Tab Bar Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                         color: isDark ? Colors.white : Colors.black,
                         borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: isDark ? Colors.black : Colors.white,
                      unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                      tabs: const [
                        Tab(text: 'FREELANCE'),
                        Tab(text: 'ASAP'),
                        Tab(text: 'BUY/SELL'),
                      ],
                    ),
                  ),
                ),

                _buildCalorieScanBar(),
                
                // Content View
                Expanded(
                  child: TabBarView(
                    children: [
                      // FREELANCE GIGS TAB
                      _buildTaskList(freelanceTasks, isOnline, "NO FREELANCE GIGS", "Check back later for tasks."),

                      // ASAP GIGS TAB
                      _buildTaskList(asapTasks, isOnline, "NO ASAP GIGS", "Campus is quiet right now."),

                      // BUY/SELL TAB
                      _buildTaskList(buySellTasks, isOnline, "NO ITEMS FOR SALE", "Students haven't posted anything to sell yet."),
                    ],
                  ),
                ),
                
                
                _buildFooter(isOnline),
              ],
            ),
          ),
        ),
        // ✨ Chat Floating Action Button
        floatingActionButton: Stack(
          alignment: Alignment.topRight,
          children: [
            FloatingActionButton(
              onPressed: () => context.push('/matches'),
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool isOnline, String emptyTitle, String emptyMsg) {
    if (tasks.isEmpty) {
      return Center(
         child: _buildEmptyState(emptyTitle, emptyMsg),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
         // Background Map for context
         _buildRadarMap(isOnline),
         
         // The List
         Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              itemCount: tasks.length,
              padding: const EdgeInsets.symmetric(vertical: 24),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskItemBar(
                  task: task,
                  currentPosition: _currentPosition,
                  onLike: () => _onAction(task, true),
                  onNope: () => _onAction(task, false),
                );
              },
            ),
         ),
      ],
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
          
          // Profile Avatar (Navigates to Profile)
          GestureDetector(
             onTap: () => context.push('/profile'),
             child: Container(
               width: 38,
               height: 38,
               margin: const EdgeInsets.only(right: 12),
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
               ),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(100),
                 child: (ref.watch(currentUserProvider)?.selfieUrl ?? ref.watch(currentUserProvider)?.avatarUrl) != null
                     ? CachedNetworkImage(
                         imageUrl: (ref.watch(currentUserProvider)?.selfieUrl ?? ref.watch(currentUserProvider)!.avatarUrl)!,
                         fit: BoxFit.cover,
                         placeholder: (context, url) => Container(color: Colors.grey.shade200),
                         errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
                       )
                     : const Icon(Icons.person, size: 20, color: Colors.grey),
               ),
             ),
          ),

          // Refresh Button
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

          // Theme Toggle
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
          // User requested removal of ASAP button here
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 64),
        const SizedBox(height: 16),
        Text(
          title, 
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isDark ? Colors.white : Colors.black,
          )
        ),
        const SizedBox(height: 8),
        Text(
          message, 
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w600,
          )
        ),
      ],
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

  Widget _buildCalorieScanBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/calorie-counter'),
        borderRadius: BorderRadius.circular(24),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'LIVE CALORIE SCAN', 
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black, 
                            fontSize: 14, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          )
                        ),
                        const SizedBox(width: 6),
                        _buildScanningDot(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Intelligent Nutrition Analysis', 
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded, 
                color: isDark ? Colors.white24 : Colors.black26, 
                size: 14
              ),
            ],
          ),
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
        infoWindow: InfoWindow(
          title: user.name,
          snippet: '${user.college ?? 'Campus'} • ${user.distanceMeters != null ? DistanceCalculator.formatDistance(user.distanceMeters!) : 'Nearby'}',
        ),
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
        ));
      }
    }

    return markers;
  }
  
  Widget _buildFooter(bool isOnline) {
      // Unused or simplified for this view
      return const SizedBox.shrink();
  }
}

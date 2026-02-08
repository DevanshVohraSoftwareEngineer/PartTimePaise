import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../managers/auth_provider.dart';
import 'swipe/swipe_feed_screen.dart';
import 'worker/asap_mode_screen.dart';

class HomeScreenDecision extends ConsumerWidget {
  const HomeScreenDecision({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (user.role == 'worker') {
      return const ASAPModeScreen();
    } else {
      return const SwipeFeedScreen();
    }
  }
}

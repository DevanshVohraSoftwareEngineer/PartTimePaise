import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
// import '../../managers/distance_preference_provider.dart';
import '../../services/navigation_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/profile/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/profile/edit');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.navyMedium,
                    AppTheme.navyLight,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.grey200,
                      backgroundImage: currentUser.avatarUrl != null
                          ? CachedNetworkImageProvider(currentUser.avatarUrl!)
                          : null,
                      child: currentUser.avatarUrl == null
                          ? Text(
                              currentUser.name.substring(0, 1).toUpperCase(),
                              style: AppTheme.heading1.copyWith(
                                fontSize: 48,
                                color: AppTheme.navyMedium,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    currentUser.name,
                    style: AppTheme.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'USER',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Rating
                  if (currentUser.rating != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.boostGold,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentUser.rating!.toStringAsFixed(1),
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Profile details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.likeGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppTheme.likeGreen,
                        ),
                      ),
                      title: const Text('Wallet Balance'),
                      trailing: Text(
                        '₹${currentUser.walletBalance.toStringAsFixed(0)}',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.likeGreen,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(currentUser.email),
                    ),
                  ),

                  if (currentUser.college != null) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: const Text('College'),
                        subtitle: Text(currentUser.college!),
                      ),
                    ),
                  ],

                  if (currentUser.city != null) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Location'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentUser.city!),
                            if (currentUser.latitude != null && currentUser.longitude != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppTheme.likeGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Distance tracking enabled',
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.likeGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (currentUser.bio != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'About',
                      style: AppTheme.heading3,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          currentUser.bio!,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  
                  // KYC Details
                  Text(
                    'Verification Documents',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Face Photo (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: currentUser.selfieUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: currentUser.selfieUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: AppTheme.grey200,
                                    child: const Icon(Icons.face, size: 48, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Identity Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: currentUser.idCardUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: currentUser.idCardUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: AppTheme.grey200,
                                    child: const Icon(Icons.badge, size: 48, color: Colors.grey),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.nopeRed,
                        side: const BorderSide(color: AppTheme.nopeRed),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

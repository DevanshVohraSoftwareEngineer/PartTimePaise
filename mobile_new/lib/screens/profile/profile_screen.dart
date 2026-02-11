import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
// import '../../managers/distance_preference_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with Action Icons
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.luxeBlack : AppTheme.luxeWhite,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: isDark ? AppTheme.luxeDarkGrey : const Color(0xFFF2F2F7),
                          backgroundImage: (currentUser.selfieUrl ?? currentUser.avatarUrl) != null
                              ? CachedNetworkImageProvider(currentUser.selfieUrl ?? currentUser.avatarUrl!)
                              : null,
                          child: (currentUser.selfieUrl ?? currentUser.avatarUrl) == null
                              ? Text(
                                  currentUser.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
    
                      const SizedBox(height: 24),
    
                      // Name
                      Text(
                        currentUser.name.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
    
                      const SizedBox(height: 8),
    
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'VERIFIED MEMBER',
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.6),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.boostGold,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentUser.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Profile Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProfileButton(
                            context,
                            'EDIT PROFILE',
                            Icons.edit,
                            () => context.push('/profile/edit'),
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildProfileButton(
                            context,
                            'SETTINGS',
                            Icons.settings,
                            () => context.push('/profile/settings'),
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Corner Action Icons (Hidden now that we have prominent buttons)
                // Positioned(
                //   top: MediaQuery.of(context).padding.top + 10,
                //   right: 16,
                //   child: Row(
                //     children: [
                //       _buildHeaderIcon(context, Icons.edit, () => context.push('/profile/edit'), isDark),
                //       const SizedBox(width: 8),
                //       _buildHeaderIcon(context, Icons.settings, () => context.push('/profile/settings'), isDark),
                //     ],
                //   ),
                // ),
              ],
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
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: primaryColor,
                        ),
                      ),
                      title: Text('Wallet Balance', style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
                      trailing: Text(
                        '₹${currentUser.walletBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.email_outlined, color: primaryColor.withOpacity(0.6)),
                      title: Text('Email', style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
                      subtitle: Text(currentUser.email),
                    ),
                  ),

                  if (currentUser.college != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.school_outlined, color: primaryColor.withOpacity(0.6)),
                        title: Text('College', style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
                        subtitle: Text(currentUser.college!),
                      ),
                    ),
                  ],

                  if (currentUser.city != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.location_on_outlined, color: primaryColor.withOpacity(0.6)),
                        title: Text('Location', style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
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
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: AppTheme.likeGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Live Location Verified',
                                      style: TextStyle(
                                        color: AppTheme.likeGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 32),
                    Text(
                      'BIO',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        fontSize: 12,
                        color: primaryColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          currentUser.bio!,
                          style: TextStyle(color: primaryColor, height: 1.5),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    'KYC VERIFICATION DOCUMENTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontSize: 12,
                      color: primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Selfie', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: currentUser.selfieUrl != null 
                                        ? CachedNetworkImage(
                                            imageUrl: currentUser.selfieUrl!, 
                                            height: 100, 
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                          )
                                        : Container(height: 100, width: double.infinity, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), child: const Icon(Icons.person)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('ID Card', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: currentUser.idCardUrl != null 
                                        ? CachedNetworkImage(
                                            imageUrl: currentUser.idCardUrl!, 
                                            height: 100, 
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                          )
                                        : Container(height: 100, width: double.infinity, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), child: const Icon(Icons.badge)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Handheld ID Verification', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: currentUser.selfieWithIdUrl != null 
                              ? CachedNetworkImage(
                                  imageUrl: currentUser.selfieWithIdUrl!, 
                                  height: 150, 
                                  width: double.infinity, 
                                  fit: BoxFit.cover, 
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator())
                                )
                              : Container(height: 150, width: double.infinity, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), child: const Icon(Icons.add_a_photo_outlined)),
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
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
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

  Widget _buildProfileButton(
    BuildContext context, 
    String label, 
    IconData icon, 
    VoidCallback onTap, 
    bool isDark
  ) {
    final primaryColor = isDark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isDark ? Colors.white : Colors.black, // Makes sure the pencil is "black" in light mode
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

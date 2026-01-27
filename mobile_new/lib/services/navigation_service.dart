import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static NavigationService get instance => _instance;
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Smart navigation with error handling and fallbacks
  Future<void> navigateToPostTask(BuildContext context) async {
    try {
      // Check if context is still valid
      if (!context.mounted) {
        debugPrint('NavigationService: Context not mounted, skipping navigation');
        return;
      }

      // Show loading indicator
      _showLoadingSnackBar(context, 'Opening post task...');

      debugPrint('NavigationService: Navigating to /post-task');

      // Small delay to show the loading feedback
      await Future.delayed(const Duration(milliseconds: 100));

      // Use go for navigation
      if (context.mounted) {
        context.go('/post-task');
        debugPrint('NavigationService: Successfully initiated navigation to post task screen');
      }

    } catch (e, stackTrace) {
      debugPrint('NavigationService: Error navigating to post task: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        _showErrorSnackBar(context, 'Unable to open post task screen. Please try again.');
      }
    }
  }

  // Smart navigation with authentication check
  Future<void> navigateToPostTaskWithAuth(BuildContext context, bool isAuthenticated) async {
    if (!isAuthenticated) {
      debugPrint('NavigationService: User not authenticated, redirecting to login');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Please log in to post tasks');
        // Small delay before redirecting
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          context.go('/login');
        }
      }
      return;
    }

    await navigateToPostTask(context);
  }

  // Generic navigation method with error handling
  Future<void> navigateSafely(BuildContext context, String route, {Object? extra}) async {
    try {
      if (!context.mounted) return;

      debugPrint('NavigationService: Navigating to $route');

      if (extra != null) {
        context.go(route, extra: extra);
      } else {
        context.go(route);
      }

      debugPrint('NavigationService: Successfully initiated navigation to $route');

    } catch (e) {
      debugPrint('NavigationService: Error navigating to $route: $e');

      if (context.mounted) {
        _showErrorSnackBar(context, 'Unable to navigate');
      }
    }
  }

  // Show loading message
  void _showLoadingSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show error message
  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Check if navigation is possible
  bool canNavigate(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  // Go back to previous screen
  void goBack(BuildContext context) {
    try {
      if (!context.mounted) return;

      debugPrint('NavigationService: Going back');
      context.pop();
      debugPrint('NavigationService: Successfully went back');

    } catch (e) {
      debugPrint('NavigationService: Error going back: $e');

      if (context.mounted) {
        _showErrorSnackBar(context, 'Unable to go back');
      }
    }
  }
}
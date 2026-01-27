import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Google Sign In
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get user info
      return {
        'provider': 'google',
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photoUrl': googleUser.photoUrl,
        'id': googleUser.id,
      };
    } catch (e) {
      throw Exception('Google Sign In failed: ${e.toString()}');
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // Facebook Login
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get the access token
        final AccessToken? accessToken = result.accessToken;
        
        if (accessToken == null) {
          throw Exception('Failed to get Facebook access token');
        }

        // Get user data
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'name,email,picture.width(200)',
        );

        return {
          'provider': 'facebook',
          'accessToken': accessToken.token,
          'userId': accessToken.userId,
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? '',
          'photoUrl': userData['picture']?['data']?['url'],
          'id': userData['id'],
        };
      } else if (result.status == LoginStatus.cancelled) {
        // User cancelled the login
        return null;
      } else {
        throw Exception('Facebook Login failed: ${result.message}');
      }
    } catch (e) {
      throw Exception('Facebook Login failed: ${e.toString()}');
    }
  }

  Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
  }

  // Sign out from all social providers
  Future<void> signOutAll() async {
    await signOutGoogle();
    await signOutFacebook();
  }
}

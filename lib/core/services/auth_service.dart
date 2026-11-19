import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../platform/platform_config.dart';

class AuthService {
  final SupabaseClient? _supabase;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '597963892766-pidql1l9h5v1r783nd2tee8b8t7th3pg.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AuthService([this._supabase]);

  static const String _keyAuthToken = 'daybreak_auth_token';
  static const String _keyRefreshToken = 'daybreak_refresh_token';
  static const String _keyMsGraphToken = 'daybreak_ms_graph_token';

  bool get isAuthenticated => _supabase?.auth.currentUser != null;

  User? get currentUser => _supabase?.auth.currentUser;

  /// Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    final client = _supabase;
    if (client == null) return null;

    if (isAndroid) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID Token found from Google Sign-In');
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null) {
        await _secureStorage.write(
            key: _keyAuthToken, value: response.session!.accessToken);
        await _secureStorage.write(
            key: _keyRefreshToken, value: response.session!.refreshToken);
      }

      return response;
    } else {
      // Windows desktop browser OAuth flow
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'daybreak://login-callback',
      );
      return null;
    }
  }

  /// Sign in with Microsoft (Azure) with Tasks.Read scope
  Future<void> signInWithMicrosoft() async {
    final client = _supabase;
    if (client == null) return;

    await client.auth.signInWithOAuth(
      OAuthProvider.azure,
      redirectTo: isAndroid
          ? 'com.daybreak.daybreak://login-callback'
          : 'daybreak://login-callback',
      scopes: 'openid profile email offline_access Tasks.Read',
    );
  }

  /// Stores Microsoft Graph access token for task migration
  Future<void> saveMicrosoftGraphToken(String token) async {
    await _secureStorage.write(key: _keyMsGraphToken, value: token);
  }

  Future<String?> getMicrosoftGraphToken() async {
    return await _secureStorage.read(key: _keyMsGraphToken);
  }

  /// Signs out user and clears local token cache
  Future<void> signOut() async {
    try {
      await _supabase?.auth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _secureStorage.deleteAll();
  }
}

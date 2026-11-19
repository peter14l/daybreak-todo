import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const SignInScreen({super.key, this.onComplete});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
      ref.read(currentUserProvider.notifier).state = auth.currentUser;
      _finish();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleMicrosoftSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithMicrosoft();
      ref.read(currentUserProvider.notifier).state = auth.currentUser;
      _finish();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _continueAsGuest() {
    _finish();
  }

  void _finish() {
    ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sunrise Glow Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.accentColor.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      color: theme.accentColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Brand Title
                  Text(
                    'Daybreak',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Every morning is a fresh start.',
                    style: TextStyle(
                      color: theme.textMutedColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Feature pills row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPill('⚡ 0.4ms Local SQLite', theme),
                      _buildPill('🌅 Midnight Reset', theme),
                      _buildPill('🔄 Cloud Sync', theme),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Auth Card Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: theme.borderRadius,
                      border: Border.all(color: theme.borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Google Sign-In
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              backgroundColor: theme.surfaceHover,
                              side: BorderSide(
                                  color: theme.borderColor, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: theme.borderRadius,
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.g_mobiledata_rounded,
                                    size: 28, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Microsoft Sign-In
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              backgroundColor: theme.surfaceHover,
                              side: BorderSide(
                                  color: theme.borderColor, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: theme.borderRadius,
                              ),
                            ),
                            onPressed:
                                _isLoading ? null : _handleMicrosoftSignIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.window_rounded,
                                    size: 18, color: Colors.blueAccent),
                                const SizedBox(width: 10),
                                Text(
                                  'Continue with Microsoft',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_isLoading) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(theme.accentColor),
                              ),
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12.5,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: theme.borderColor,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: theme.textMutedColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: theme.borderColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Guest / Offline Mode
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: theme.textMutedColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: theme.borderRadius,
                              ),
                            ),
                            icon: const Icon(Icons.offline_bolt_outlined,
                                size: 18),
                            label: const Text(
                              'Continue without an account',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: _continueAsGuest,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Local-First Promise: Your tasks are always stored securely in offline SQLite on this device, with or without an account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textMutedColor.withValues(alpha: 0.7),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label, dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceHover,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textMutedColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

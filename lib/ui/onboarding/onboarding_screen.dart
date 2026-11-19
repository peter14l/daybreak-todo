import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../auth/sign_in_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      icon: Icons.wb_sunny_rounded,
      iconColor: Colors.amber,
      title: 'Every morning is a fresh start.',
      tagline: 'The True "My Day" Reset',
      description:
          'Unfinished tasks shouldn\'t pile on guilt. Every midnight, your day clears automatically so you can pick your focus intentionally every sunrise.',
      badgeText: '🌅 Guilt-free daily focus',
    ),
    _OnboardingSlideData(
      icon: Icons.flash_on_rounded,
      iconColor: Colors.orangeAccent,
      title: 'Sub-millisecond & Local-First.',
      tagline: 'Speed with zero network lag',
      description:
          'Powered by embedded SQLite and Drift. Your tasks, checklists, and notes open and save in under 0.5ms with 100% offline reliability.',
      badgeText: '⚡ 0.4ms Drift SQLite',
    ),
    _OnboardingSlideData(
      icon: Icons.palette_outlined,
      iconColor: Colors.tealAccent,
      title: 'Designed for Windows 11 & Android.',
      tagline: 'Native craftsmanship across platforms',
      description:
          'Seamlessly toggle between Fluent Luxe Mica Alt, Sunrise Warmth, and Linear Obsidian archetypes with home-screen widgets and compact glance mini-mode.',
      badgeText: '🎨 3 Curated Archetypes',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToSignIn();
    }
  }

  void _goToSignIn() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignInScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          color: theme.accentColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Daybreak',
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _goToSignIn,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textMutedColor,
                      ),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // Page carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Glowing Icon Circle
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: slide.iconColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: slide.iconColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        slide.iconColor.withValues(alpha: 0.25),
                                    blurRadius: 40,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide.icon,
                                color: slide.iconColor,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: slide.iconColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: slide.iconColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                slide.badgeText,
                                style: TextStyle(
                                  color: slide.iconColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Headline
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Description
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.textMutedColor,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Stepper
            Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Row(
                  children: [
                    // Dot indicators
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.accentColor
                                : theme.borderColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Next / Get Started button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: const Color(0xFF121212),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: theme.borderRadius,
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String tagline;
  final String description;
  final String badgeText;

  const _OnboardingSlideData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.tagline,
    required this.description,
    required this.badgeText,
  });
}

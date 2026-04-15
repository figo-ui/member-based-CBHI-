import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cbhi_localizations.dart';
import '../theme/app_theme.dart';

const _kOnboardingDoneKey = 'cbhi_onboarding_done';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDoneKey) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.health_and_safety_outlined,
      titleKey: 'onboardingTitle1',
      bodyKey: 'onboardingBody1',
      color: AppTheme.primary,
    ),
    _OnboardingPage(
      icon: Icons.app_registration_outlined,
      titleKey: 'onboardingTitle2',
      bodyKey: 'onboardingBody2',
      color: AppTheme.accent,
    ),
    _OnboardingPage(
      icon: Icons.badge_outlined,
      titleKey: 'onboardingTitle3',
      bodyKey: 'onboardingBody3',
      color: AppTheme.gold,
    ),
    _OnboardingPage(
      icon: Icons.cloud_off_outlined,
      titleKey: 'onboardingTitle4',
      bodyKey: 'onboardingBody4',
      color: AppTheme.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(strings.t('skip')),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _pages[index].build(context),
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? _pages[_currentPage].color
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton(
                onPressed: isLast
                    ? _finish
                    : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: _pages[_currentPage].color,
                ),
                child: Text(
                  isLast ? strings.t('getStarted') : strings.t('next'),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.color,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final Color color;

  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: color),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 32),

          Text(
            strings.t(titleKey),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 20),

          Text(
            strings.t(bodyKey),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
        ],
      ),
    );
  }
}

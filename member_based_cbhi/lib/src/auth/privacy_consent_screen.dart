import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';

const _kConsentKey = 'cbhi_privacy_consent_v1';

Future<bool> hasGivenConsent() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kConsentKey) ?? false;
}

Future<void> recordConsent() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kConsentKey, true);
}

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _scrolledToBottom = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_scrolledToBottom) setState(() => _scrolledToBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    await recordConsent();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.t('privacyConsent'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.t('privacyConsentSubtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Consent text
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConsentSection(
                      title: strings.t('privacySection1Title'),
                      body: strings.t('privacySection1Body'),
                    ),
                    _ConsentSection(
                      title: strings.t('privacySection2Title'),
                      body: strings.t('privacySection2Body'),
                    ),
                    _ConsentSection(
                      title: strings.t('privacySection3Title'),
                      body: strings.t('privacySection3Body'),
                    ),
                    _ConsentSection(
                      title: strings.t('privacySection4Title'),
                      body: strings.t('privacySection4Body'),
                    ),
                    _ConsentSection(
                      title: strings.t('privacySection5Title'),
                      body: strings.t('privacySection5Body'),
                    ),
                    _ConsentSection(
                      title: strings.t('privacySection6Title'),
                      body: strings.t('privacySection6Body'),
                    ),
                    _ConsentSection(
                      title: strings.t('privacySection7Title'),
                      body: strings.t('privacySection7Body'),
                    ),
                    const SizedBox(height: 16),
                    if (!_scrolledToBottom)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_downward,
                              color: AppTheme.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings.t('scrollToRead'),
                              style: const TextStyle(color: AppTheme.warning),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Accept button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: _scrolledToBottom ? _accept : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(strings.t('iAcceptContinue')),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('consentFooter'),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

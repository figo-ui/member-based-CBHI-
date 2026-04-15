import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cbhi_localizations.dart';
import '../../theme/app_theme.dart';
import '../registration_cubit.dart';
import '../models/membership_type.dart';

class MembershipSelectionScreen extends StatelessWidget {
  const MembershipSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final regCubit = context.read<RegistrationCubit>();
    final state = regCubit.state;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('membershipSelection'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    strings.t('membershipSelection'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.t('chooseMembershipPathway'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Indigent card
            _MembershipCard(
              icon: Icons.volunteer_activism_outlined,
              title: strings.t('indigentMembership'),
              subtitle: strings.t('indigentMembershipSubtitle'),
              features: [
                strings.t('indigentFeature1'),
                strings.t('indigentFeature2'),
                strings.t('indigentFeature3'),
              ],
              color: AppTheme.success,
              isRecommended: true,
              onSelect: () => regCubit.beginIndigentProof(
                const MembershipSelection(type: MembershipType.indigent),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 16),

            // Paying card
            _MembershipCard(
              icon: Icons.payments_outlined,
              title: strings.t('payingMembership'),
              subtitle: strings.t('payingMembershipSubtitle'),
              features: [
                strings.t('payingFeature1'),
                strings.t('payingFeature2'),
                strings.t('payingFeature3'),
              ],
              color: AppTheme.primary,
              isRecommended: false,
              onSelect: () => regCubit.submitPayingMembership(
                const MembershipSelection(
                  type: MembershipType.paying,
                  premiumAmount: 500,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 24),

            if (state.isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primary)),

            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.errorMessage!,
                          style: const TextStyle(color: AppTheme.error)),
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

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.color,
    required this.isRecommended,
    required this.onSelect,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final Color color;
  final bool isRecommended;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700)),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: color)),
                      ],
                    ),
                  ),
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        strings.t('recommended'),
                        style: TextStyle(
                            color: color, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(strings.t('selectThisOption')),
                style: FilledButton.styleFrom(backgroundColor: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

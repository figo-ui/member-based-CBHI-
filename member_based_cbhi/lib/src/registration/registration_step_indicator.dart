import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'registration_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step number extension on RegistrationStep
// ─────────────────────────────────────────────────────────────────────────────

extension RegistrationStepX on RegistrationStep {
  /// 1-based step number for display. Returns null for non-displayable steps.
  int? get stepNumber => switch (this) {
        RegistrationStep.personalInfo => 1,
        RegistrationStep.confirmation => 2,
        RegistrationStep.identity => 3,
        RegistrationStep.membership => 4,
        RegistrationStep.indigentProof => 5,
        RegistrationStep.payment => 6,
        RegistrationStep.setupAccount => 7,
        _ => null,
      };

  static const int totalSteps = 7;
}

// ─────────────────────────────────────────────────────────────────────────────
// RegistrationStepIndicator widget
// ─────────────────────────────────────────────────────────────────────────────

/// Displays a linear progress bar + "Step N of 7" label at the top of each
/// registration step screen.
///
/// Usage: place at the top of the step screen's Scaffold body, before the
/// main content.
class RegistrationStepIndicator extends StatelessWidget {
  const RegistrationStepIndicator({
    super.key,
    required this.step,
  });

  final RegistrationStep step;

  @override
  Widget build(BuildContext context) {
    final stepNumber = step.stepNumber;
    if (stepNumber == null) return const SizedBox.shrink();

    final progress = stepNumber / RegistrationStepX.totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $stepNumber of ${RegistrationStepX.totalSteps}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 3,
        ),
      ],
    );
  }
}

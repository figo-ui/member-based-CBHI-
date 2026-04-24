import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/account_setup_screen.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../cbhi_localizations.dart';
import '../theme/app_theme.dart';
import 'registration_cubit.dart';
import 'personal_info/personal_info_form.dart';
import 'confirmation/personal_info_confirmation.dart';
import 'identity/identity_verification_screen.dart';
import 'membership/membership_selection_screen.dart';
import 'indigent_proof_screen.dart';
import '../payment/payment_screen.dart';

class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<RegistrationCubit>().startRegistration();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              prev.status != AuthStatus.authenticated &&
              curr.status == AuthStatus.authenticated,
          listener: (context, _) {
            context.read<RegistrationCubit>().reset();
          },
        ),
      ],
      child: BlocBuilder<RegistrationCubit, RegistrationState>(
        builder: (context, state) {
          final regCubit = context.read<RegistrationCubit>();
          final authCubit = context.read<AuthCubit>();
          final repo = authCubit.repository;

          switch (state.currentStep) {
            case RegistrationStep.personalInfo:
              return PersonalInfoForm(
                repository: repo,
                onNext: regCubit.submitPersonalInfo,
              );
            case RegistrationStep.confirmation:
              return const PersonalInfoConfirmation();
            case RegistrationStep.identity:
              return const IdentityVerificationScreen();
            case RegistrationStep.membership:
              return const MembershipSelectionScreen();
            case RegistrationStep.indigentProof:
              return const IndigentProofScreen();
            case RegistrationStep.payment:
              final snapshot = state.registrationSnapshot;
              if (snapshot == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return PaymentScreen(
                repository: repo,
                snapshot: snapshot,
                onPaymentComplete: regCubit.submitPaymentSuccess,
              );

            case RegistrationStep.setupAccount:
              final phone = state.registeredPhone ?? '';
              if (phone.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  regCubit.reset();
                  authCubit.adoptRegisteredSession();
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return AccountSetupScreen(
                authCubit: authCubit,
                repository: repo,
                phoneNumber: phone,
              );

            case RegistrationStep.completed:
              return _RegistrationCompletedView(
                personalInfo: state.personalInfo,
                snapshot: state.registrationSnapshot,
                isOffline: state.isOffline,
              );
            default:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
          }
        },
      ),
    );
  }
}

// ── Registration Completed ────────────────────────────────────────────────────

class _RegistrationCompletedView extends StatefulWidget {
  const _RegistrationCompletedView({
    required this.personalInfo,
    required this.snapshot,
    required this.isOffline,
  });

  final dynamic personalInfo;
  final dynamic snapshot;
  final bool isOffline;

  @override
  State<_RegistrationCompletedView> createState() =>
      _RegistrationCompletedViewState();
}

class _RegistrationCompletedViewState
    extends State<_RegistrationCompletedView> {
  String? _tempPassword;

  @override
  void initState() {
    super.initState();
    _loadTempPassword();
    // Open dashboard immediately — pass personalInfo so offline fallback works
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().adoptRegisteredSession(
        personalInfo: widget.personalInfo,
        offlineSnapshot: widget.snapshot,
      );
    });
  }

  Future<void> _loadTempPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final pw = prefs.getString('cbhi_temp_password');
    if (pw != null && mounted) {
      setState(() => _tempPassword = pw);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) {
              final strings = CbhiLocalizations.of(context);

              // Show spinner while session is being adopted
              if (auth.isBusy) {
                return const Center(child: CircularProgressIndicator());
              }

              final authenticated = auth.status == AuthStatus.authenticated;

              // If authenticated, dashboard will open automatically via BlocListener.
              // Show a brief success screen with the temp password warning.
              if (authenticated) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 80, color: AppTheme.success),
                    const SizedBox(height: 16),
                    Text(
                      strings.t('registrationCompleted'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.t('registrationSuccessMessage'),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_tempPassword != null) ...[
                      const SizedBox(height: 24),
                      _TempPasswordCard(tempPassword: _tempPassword!),
                    ],
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(strings.t('loading'),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              }

              // Not authenticated — show offline mode with temp password
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: AppTheme.success),
                  const SizedBox(height: 16),
                  Text(
                    strings.t('registrationSavedForSync'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.t('offlineQueueMessage'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_tempPassword != null) ...[
                    const SizedBox(height: 24),
                    _TempPasswordCard(tempPassword: _tempPassword!),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    icon: const Icon(Icons.home_outlined),
                    label: Text(strings.t('home')),
                    onPressed: () => context.read<AuthCubit>().adoptRegisteredSession(
                      personalInfo: widget.personalInfo,
                      offlineSnapshot: widget.snapshot,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      context.read<RegistrationCubit>().reset();
                      context.read<AuthCubit>().leaveGuest();
                    },
                    child: Text(strings.t('backToSignIn')),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Temp Password Warning Card ────────────────────────────────────────────────

class _TempPasswordCard extends StatelessWidget {
  const _TempPasswordCard({required this.tempPassword});
  final String tempPassword;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.t('tempPasswordTitle'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.t('tempPasswordWarning'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning),
            ),
            child: Text(
              tempPassword,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: AppTheme.warning,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.t('tempPasswordNote'),
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

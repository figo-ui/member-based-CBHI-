import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cbhi_data.dart';
import '../cbhi_localizations.dart';
import '../theme/app_theme.dart';
import 'auth_cubit.dart';

/// Shown immediately after successful registration.
///
/// Flow:
///   1. Backend sends a 6-digit setup code to the registered phone via SMS.
///   2. User enters the code + chooses a password.
///   3. On success the account is activated and the user is signed in.
class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({
    super.key,
    required this.authCubit,
    required this.repository,
    required this.phoneNumber,
    required this.challenge,
  });

  final AuthCubit authCubit;
  final CbhiRepository repository;
  final String phoneNumber;
  final OtpChallenge challenge;

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isActivating = false;
  bool _isResending = false;
  String? _error;

  late int _secondsRemaining;
  Timer? _timer;
  bool _canResend = false;

  String get _code => _digitControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.challenge.expiresInSeconds;
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _countdownText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _activate() async {
    final strings = CbhiLocalizations.of(context);
    setState(() => _error = null);

    if (_code.length < 6) {
      setState(() => _error = strings.t('pleaseEnterAll6Digits'));
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = strings.t('passwordTooShort'));
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = strings.t('passwordsDoNotMatch'));
      return;
    }

    setState(() => _isActivating = true);
    try {
      // Step 1: verify OTP → get session
      final ok = await widget.authCubit.verifyOtp(
        phoneNumber: widget.phoneNumber,
        code: _code,
      );
      if (!ok || !mounted) return;

      // Step 2: set password using reset-password endpoint
      // (OTP was already consumed above; backend issued a session)
      // We use the authenticated session to call a dedicated set-password endpoint.
      await widget.repository.setInitialPassword(
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('accountActivated')),
            backgroundColor: AppTheme.success,
          ),
        );
        // Pop all the way back — AuthCubit is now authenticated
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  Future<void> _resend() async {
    final strings = CbhiLocalizations.of(context);
    setState(() {
      _isResending = true;
      _canResend = false;
      _secondsRemaining = 300;
      for (final c in _digitControllers) { c.clear(); }
    });
    _startCountdown();
    _focusNodes[0].requestFocus();

    try {
      final challenge = await widget.authCubit.sendOtp(
        phoneNumber: widget.phoneNumber,
      );
      if (challenge != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.f('setupCodeSent', {'target': challenge.target}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digitControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('setupAccountTitle')),
        automaticallyImplyLeading: false, // can't go back mid-setup
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    strings.t('setupAccountTitle'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('setupAccountSubtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // Target display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                widget.challenge.target,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 24),

            // Dev code card
            if (widget.challenge.debugCode != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.developer_mode_outlined,
                        color: AppTheme.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.t('developmentOtp'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppTheme.warning)),
                          Text(
                            widget.challenge.debugCode!,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 8,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
              const SizedBox(height: 20),
            ],

            // 6-digit PIN boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextFormField(
                    controller: _digitControllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    obscureText: true,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusS),
                        borderSide: BorderSide(
                          color: _digitControllers[i].text.isNotEmpty
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          width:
                              _digitControllers[i].text.isNotEmpty ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusS),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: _digitControllers[i].text.isNotEmpty
                          ? AppTheme.primary.withValues(alpha: 0.05)
                          : Colors.white,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 12),

            // Countdown
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _canResend
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${strings.t('otpExpiry')} $_countdownText',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _secondsRemaining < 60
                                        ? AppTheme.error
                                        : AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: strings.t('newPassword'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 280.ms),

            const SizedBox(height: 14),

            // Confirm password
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: strings.t('confirmPassword'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 340.ms),

            const SizedBox(height: 20),

            // Error
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Activate button
            FilledButton.icon(
              onPressed: _isActivating ? null : _activate,
              icon: _isActivating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(strings.t('activateAccount')),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 12),

            // Resend
            AnimatedOpacity(
              opacity: _canResend ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: TextButton.icon(
                onPressed: (_canResend && !_isResending) ? _resend : null,
                icon: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(strings.t('resendSetupCode')),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

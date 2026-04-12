import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../cbhi_data.dart';
import '../i18n/app_localizations.dart';
import 'auth_cubit.dart';

enum OtpMode { login, passwordReset }

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.authCubit,
    required this.title,
    required this.description,
    required this.identifier,
    required this.challenge,
    required this.mode,
  });

  final AuthCubit authCubit;
  final String title;
  final String description;
  final String identifier;
  final OtpChallenge challenge;
  final OtpMode mode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 6 individual digit controllers
  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();

  late int _secondsRemaining;
  Timer? _countdownTimer;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _obscurePassword = true;

  bool get _isPhoneIdentifier => !widget.identifier.contains('@');

  String get _enteredCode => _digitControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.challenge.expiresInSeconds;
    _startCountdown();
    // Auto-focus first digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _countdownText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    final strings = AppLocalizations.of(context);
    final code = _enteredCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('pleaseEnterAll6Digits'))),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final success = widget.mode == OtpMode.login
          ? await widget.authCubit.verifyOtp(
              phoneNumber: _isPhoneIdentifier ? widget.identifier : null,
              email: _isPhoneIdentifier ? null : widget.identifier,
              code: code,
            )
          : await widget.authCubit.resetPassword(
              identifier: widget.identifier,
              code: code,
              newPassword: _passwordController.text,
            );

      if (success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _canResend = false;
      _secondsRemaining = 300;
      for (final c in _digitControllers) {
        c.clear();
      }
    });
    _startCountdown();
    _focusNodes[0].requestFocus();

    final challenge = widget.mode == OtpMode.login
        ? await widget.authCubit.sendOtp(
            phoneNumber: _isPhoneIdentifier ? widget.identifier : null,
            email: _isPhoneIdentifier ? null : widget.identifier,
          )
        : await widget.authCubit.forgotPassword(widget.identifier);

    if (challenge != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.f('newCodeSentTo', {'target': challenge.target}),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

            const SizedBox(height: 24),

            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 8),

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
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 32),

            // Dev OTP card (non-production only)
            if (widget.challenge.debugCode != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.developer_mode_outlined,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('developmentOtp'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.warning),
                          ),
                          Text(
                            widget.challenge.debugCode!,
                            style: Theme.of(context).textTheme.headlineSmall
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
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
              const SizedBox(height: 24),
            ],

            // 6-box PIN input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextFormField(
                    controller: _digitControllers[index],
                    focusNode: _focusNodes[index],
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        borderSide: BorderSide(
                          color: _digitControllers[index].text.isNotEmpty
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          width: _digitControllers[index].text.isNotEmpty
                              ? 2
                              : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: _digitControllers[index].text.isNotEmpty
                          ? AppTheme.primary.withValues(alpha: 0.05)
                          : Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      // Auto-submit when all 6 digits entered
                      if (_enteredCode.length == 6 &&
                          widget.mode == OtpMode.login) {
                        _verify();
                      }
                    },
                  ),
                );
              }),
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

            const SizedBox(height: 24),

            // Countdown timer
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _canResend
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${strings.t('otpExpiry')} $_countdownText',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _secondsRemaining < 60
                                    ? AppTheme.error
                                    : AppTheme.textSecondary,
                                fontWeight: _secondsRemaining < 60
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // New password field (password reset mode only)
            if (widget.mode == OtpMode.passwordReset) ...[
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: strings.t('newPassword'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 16),
            ],

            // Verify button
            FilledButton.icon(
              onPressed: _isVerifying ? null : _verify,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(
                widget.mode == OtpMode.login
                    ? strings.t('verifyOtp')
                    : strings.t('forgotPassword'),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

            const SizedBox(height: 12),

            // Resend button
            AnimatedOpacity(
              opacity: _canResend ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: TextButton.icon(
                onPressed: _canResend ? _resend : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(strings.t('resendOtp')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

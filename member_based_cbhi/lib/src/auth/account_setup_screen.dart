import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cbhi_data.dart';
import '../cbhi_localizations.dart';
import '../theme/app_theme.dart';
import '../shared/language_selector.dart';
import 'auth_cubit.dart';

/// Shown immediately after successful registration.
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
      final ok = await widget.authCubit.verifyOtp(
        phoneNumber: widget.phoneNumber,
        code: _code,
      );
      if (!ok || !mounted) return;

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('setupAccountTitle')),
        automaticallyImplyLeading: false, 
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSelector(isLight: true),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        strings.t('setupAccountTitle'),
                        style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.t('setupAccountSubtitle'),
                        style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Target display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    widget.challenge.target,
                    style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 32),

                // 6-digit PIN boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      width: 44,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        controller: _digitControllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
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

                const SizedBox(height: 16),

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
                            const SizedBox(width: 8),
                            Text(
                              '${strings.t('otpExpiry')} $_countdownText',
                              style: textTheme.bodySmall?.copyWith(
                                        color: _secondsRemaining < 60
                                            ? AppTheme.error
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 32),

                // Password Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
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
                        ),
                        const SizedBox(height: 16),
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
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: 24),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ).animate().shake(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isActivating ? null : _activate,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isActivating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(strings.t('activateAccount')),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: (_canResend && !_isResending) ? _resend : null,
                  icon: _isResending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 20),
                  label: Text(strings.t('resendSetupCode')),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

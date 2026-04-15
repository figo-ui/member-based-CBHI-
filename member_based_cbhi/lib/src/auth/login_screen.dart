import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cbhi_localizations.dart';
import '../shared/biometric_service.dart';
import '../theme/app_theme.dart';
import 'auth_cubit.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authCubit});

  final AuthCubit authCubit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController(text: '+2519');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TabController _tabController;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) setState(() => _biometricAvailable = available && enabled);
  }

  Future<void> _loginWithBiometric() async {
    final strings = CbhiLocalizations.of(context);
    final token = await BiometricService.authenticateAndGetToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('biometricAuthenticationFailed'))),
        );
      }
      return;
    }
    // Token is the stored access token — restore session
    final ok = await widget.authCubit.loginWithStoredToken(token);
    if (ok && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('signIn')),
        actions: [
          if (_biometricAvailable)
            IconButton(
              tooltip: strings.t('signInWithBiometrics'),
              icon: const Icon(Icons.fingerprint),
              onPressed: _loginWithBiometric,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.phone_android, size: 18),
              text: strings.t('phonePlusOtp'),
            ),
            Tab(
              icon: const Icon(Icons.lock_outline, size: 18),
              text: strings.t('password'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PhoneLoginTab(
            authCubit: widget.authCubit,
            controller: _phoneController,
          ),
          _PasswordLoginTab(
            authCubit: widget.authCubit,
            emailController: _emailController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ],
      ),
    );
  }
}

class _PhoneLoginTab extends StatelessWidget {
  const _PhoneLoginTab({required this.authCubit, required this.controller});

  final AuthCubit authCubit;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon header
          Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('oneTimePassword'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.t('otpPhoneSubtitle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: strings.t('phoneNumber'),
              prefixIcon: const Icon(Icons.phone),
              hintText: '+2519XXXXXXXX',
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 24),

          FilledButton.icon(
                onPressed: () async {
                  final challenge = await authCubit.sendOtp(
                    phoneNumber: controller.text.trim(),
                  );
                  if (challenge != null && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OtpScreen(
                          authCubit: authCubit,
                          title: strings.t('verifyYourPhone'),
                          description: strings.f('enterCodeSentTo', {
                            'target': challenge.target,
                          }),
                          identifier: controller.text.trim(),
                          challenge: challenge,
                          mode: OtpMode.login,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: Text(strings.t('sendOtp')),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}

class _PasswordLoginTab extends StatelessWidget {
  const _PasswordLoginTab({
    required this.authCubit,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
  });

  final AuthCubit authCubit;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('credentialLogin'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.t('credentialLoginSubtitle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: strings.t('emailOrPhoneNumber'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 14),

          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: strings.t('password'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            obscureText: obscurePassword,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 24),

          FilledButton.icon(
                onPressed: () async {
                  final ok = await authCubit.loginWithPassword(
                    identifier: emailController.text.trim(),
                    password: passwordController.text,
                  );
                  if (ok && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.login),
                label: Text(strings.t('signIn')),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              onPressed: () async {
                final challenge = await authCubit.forgotPassword(
                  emailController.text.trim(),
                );
                if (challenge != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OtpScreen(
                        authCubit: authCubit,
                        title: strings.t('forgotPassword'),
                        description: strings.f('enterResetCodeSentTo', {
                          'target': challenge.target,
                        }),
                        identifier: emailController.text.trim(),
                        challenge: challenge,
                        mode: OtpMode.passwordReset,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.help_outline, size: 18),
              label: Text(strings.t('forgotPassword')),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }
}

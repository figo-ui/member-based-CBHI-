import 'package:flutter/material.dart';

import '../cbhi_localizations.dart';
import 'auth_cubit.dart';
import 'otp_screen.dart';

class FamilyMemberLoginScreen extends StatefulWidget {
  const FamilyMemberLoginScreen({super.key, required this.authCubit});

  final AuthCubit authCubit;

  @override
  State<FamilyMemberLoginScreen> createState() =>
      _FamilyMemberLoginScreenState();
}

class _FamilyMemberLoginScreenState extends State<FamilyMemberLoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _otpPhoneController = TextEditingController(text: '+2519');
  final _otpMembershipIdController = TextEditingController();
  final _otpHouseholdCodeController = TextEditingController();
  final _otpFullNameController = TextEditingController();

  final _passwordPhoneController = TextEditingController(text: '+2519');
  final _passwordMembershipIdController = TextEditingController();
  final _passwordHouseholdCodeController = TextEditingController();
  final _passwordFullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _otpPhoneController.dispose();
    _otpMembershipIdController.dispose();
    _otpHouseholdCodeController.dispose();
    _otpFullNameController.dispose();
    _passwordPhoneController.dispose();
    _passwordMembershipIdController.dispose();
    _passwordHouseholdCodeController.dispose();
    _passwordFullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('familyLogin')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: strings.t('phonePlusOtp')),
            Tab(text: strings.t('phonePlusPassword')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FamilyOtpTab(
            authCubit: widget.authCubit,
            phoneController: _otpPhoneController,
            membershipIdController: _otpMembershipIdController,
            householdCodeController: _otpHouseholdCodeController,
            fullNameController: _otpFullNameController,
          ),
          _FamilyPasswordTab(
            authCubit: widget.authCubit,
            phoneController: _passwordPhoneController,
            membershipIdController: _passwordMembershipIdController,
            householdCodeController: _passwordHouseholdCodeController,
            fullNameController: _passwordFullNameController,
            passwordController: _passwordController,
          ),
        ],
      ),
    );
  }
}

class _FamilyOtpTab extends StatelessWidget {
  const _FamilyOtpTab({
    required this.authCubit,
    required this.phoneController,
    required this.membershipIdController,
    required this.householdCodeController,
    required this.fullNameController,
  });

  final AuthCubit authCubit;
  final TextEditingController phoneController;
  final TextEditingController membershipIdController;
  final TextEditingController householdCodeController;
  final TextEditingController fullNameController;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text(
            strings.t('familyLoginOtpDescription'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _FamilyLookupFields(
            phoneController: phoneController,
            membershipIdController: membershipIdController,
            householdCodeController: householdCodeController,
            fullNameController: fullNameController,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final lookup = _validateLookup(
                context,
                phoneController: phoneController,
                membershipIdController: membershipIdController,
                householdCodeController: householdCodeController,
                fullNameController: fullNameController,
              );
              if (lookup == null) {
                return;
              }

              final challenge = await authCubit.requestFamilyMemberOtp(
                phoneNumber: lookup.phoneNumber,
                membershipId: lookup.membershipId,
                householdCode: lookup.householdCode,
                fullName: lookup.fullName,
              );

              if (challenge != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OtpScreen(
                      authCubit: authCubit,
                      title: strings.t('verifyFamilyMemberAccess'),
                      description: strings.f('enterCodeSentTo', {
                        'target': challenge.target,
                      }),
                      identifier: lookup.phoneNumber,
                      challenge: challenge,
                      mode: OtpMode.login,
                    ),
                  ),
                );
              }
            },
            child: Text(strings.t('sendOtp')),
          ),
        ],
      ),
    );
  }
}

class _FamilyPasswordTab extends StatelessWidget {
  const _FamilyPasswordTab({
    required this.authCubit,
    required this.phoneController,
    required this.membershipIdController,
    required this.householdCodeController,
    required this.fullNameController,
    required this.passwordController,
  });

  final AuthCubit authCubit;
  final TextEditingController phoneController;
  final TextEditingController membershipIdController;
  final TextEditingController householdCodeController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text(
            strings.t('familyLoginPasswordDescription'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _FamilyLookupFields(
            phoneController: phoneController,
            membershipIdController: membershipIdController,
            householdCodeController: householdCodeController,
            fullNameController: fullNameController,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: strings.t('password')),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final lookup = _validateLookup(
                context,
                phoneController: phoneController,
                membershipIdController: membershipIdController,
                householdCodeController: householdCodeController,
                fullNameController: fullNameController,
              );
              if (lookup == null) {
                return;
              }
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.t('passwordRequired'))),
                );
                return;
              }

              final ok = await authCubit.loginFamilyMemberWithPassword(
                phoneNumber: lookup.phoneNumber,
                membershipId: lookup.membershipId,
                householdCode: lookup.householdCode,
                fullName: lookup.fullName,
                password: passwordController.text,
              );
              if (ok && context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(strings.t('signIn')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final challenge = await authCubit.forgotPassword(
                phoneController.text.trim(),
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
                      identifier: phoneController.text.trim(),
                      challenge: challenge,
                      mode: OtpMode.passwordReset,
                    ),
                  ),
                );
              }
            },
            child: Text(strings.t('forgotPassword')),
          ),
        ],
      ),
    );
  }
}

class _FamilyLookupFields extends StatelessWidget {
  const _FamilyLookupFields({
    required this.phoneController,
    required this.membershipIdController,
    required this.householdCodeController,
    required this.fullNameController,
  });

  final TextEditingController phoneController;
  final TextEditingController membershipIdController;
  final TextEditingController householdCodeController;
  final TextEditingController fullNameController;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: strings.t('beneficiaryPhoneNumber'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: membershipIdController,
          decoration: InputDecoration(
            labelText: strings.t('membershipId'),
            hintText: strings.t('recommended'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: householdCodeController,
          decoration: InputDecoration(
            labelText: strings.t('householdCode'),
            hintText: strings.t('useIfMembershipIdUnavailable'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: fullNameController,
          decoration: InputDecoration(
            labelText: strings.t('beneficiaryFullName'),
          ),
        ),
      ],
    );
  }
}

_FamilyLookupInput? _validateLookup(
  BuildContext context, {
  required TextEditingController phoneController,
  required TextEditingController membershipIdController,
  required TextEditingController householdCodeController,
  required TextEditingController fullNameController,
}) {
  final strings = CbhiLocalizations.of(context);
  final phone = phoneController.text.trim();
  final membershipId = membershipIdController.text.trim();
  final householdCode = householdCodeController.text.trim();
  final fullName = fullNameController.text.trim();

  if (phone.isEmpty || phone == '+2519') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('beneficiaryPhoneRequired'))),
    );
    return null;
  }

  if (membershipId.isEmpty && (householdCode.isEmpty || fullName.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('membershipOrHouseholdRequired'))),
    );
    return null;
  }

  return _FamilyLookupInput(
    phoneNumber: phone,
    membershipId: membershipId.isEmpty ? null : membershipId,
    householdCode: householdCode.isEmpty ? null : householdCode,
    fullName: fullName.isEmpty ? null : fullName,
  );
}

class _FamilyLookupInput {
  const _FamilyLookupInput({
    required this.phoneNumber,
    this.membershipId,
    this.householdCode,
    this.fullName,
  });

  final String phoneNumber;
  final String? membershipId;
  final String? householdCode;
  final String? fullName;
}

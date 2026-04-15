import 'package:flutter/material.dart';
import '../app.dart';
import '../data/facility_repository.dart';
import '../i18n/app_localizations.dart';
import 'qr_scanner_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, required this.repository});
  final FacilityRepository repository;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _membershipIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+2519');
  final _householdCodeCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<QrScanResult>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null) return;
    setState(() {
      if (result.membershipId != null) {
        _membershipIdCtrl.text = result.membershipId!;
      } else if (result.householdCode != null) {
        _householdCodeCtrl.text = result.householdCode!;
      }
    });
    // Auto-verify after scan
    await _verify();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await widget.repository.verifyEligibility(
        membershipId: _membershipIdCtrl.text.trim().isEmpty
            ? null
            : _membershipIdCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim() == '+2519'
            ? null
            : _phoneCtrl.text.trim(),
        householdCode: _householdCodeCtrl.text.trim().isEmpty
            ? null
            : _householdCodeCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clear() {
    _membershipIdCtrl.clear();
    _phoneCtrl.text = '+2519';
    _householdCodeCtrl.clear();
    _fullNameCtrl.clear();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _membershipIdCtrl.dispose();
    _phoneCtrl.dispose();
    _householdCodeCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final beneficiary =
        (_result?['beneficiary'] as Map?)?.cast<String, dynamic>() ?? {};
    final eligibility =
        (_result?['eligibility'] as Map?)?.cast<String, dynamic>() ?? {};
    final coverage =
        (_result?['coverage'] as Map?)?.cast<String, dynamic>() ?? {};
    final isEligible = eligibility['isEligible'] == true;

    return Row(
      children: [
        // Search panel
        SizedBox(
          width: 380,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('searchMember'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t('enterMemberDetails'),
                  style: const TextStyle(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // QR scan button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _scanQr,
                    icon: const Icon(Icons.qr_code_scanner, color: kPrimary),
                    label: Text(
                      strings.t('scanQrCard'),
                      style: const TextStyle(color: kPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(strings.t('or'),
                          style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _membershipIdCtrl,
                  decoration: InputDecoration(
                    labelText: strings.t('membershipId'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: strings.t('phoneNumber'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          strings.t('or'),
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                TextField(
                  controller: _householdCodeCtrl,
                  decoration: InputDecoration(
                    labelText: strings.t('householdCode'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fullNameCtrl,
                  decoration: InputDecoration(labelText: strings.t('fullName')),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _verify,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(strings.t('verify')),
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _clear,
                      child: Text(strings.t('clear')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // Result panel
        Expanded(
          child: _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: kError, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: kError),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _result == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 64,
                        color: Color(0xFFCCDDD9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.t('searchMemberPrompt'),
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eligibility banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: (isEligible ? kSuccess : kError).withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isEligible ? kSuccess : kError).withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEligible
                                  ? Icons.verified
                                  : Icons.cancel_outlined,
                              color: isEligible ? kSuccess : kError,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEligible
                                        ? strings.t('eligibleForService')
                                        : strings.t('notEligible'),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isEligible ? kSuccess : kError,
                                    ),
                                  ),
                                  Text(
                                    eligibility['reason']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isEligible ? kSuccess : kError,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Member details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('memberDetails'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              _DetailRow(
                                strings.t('fullName'),
                                beneficiary['fullName']?.toString() ??
                                    strings.t('notAvailable'),
                              ),
                              _DetailRow(
                                strings.t('membershipId'),
                                beneficiary['membershipId']?.toString() ??
                                    strings.t('notAvailable'),
                              ),
                              _DetailRow(
                                strings.t('householdCode'),
                                beneficiary['householdCode']?.toString() ??
                                    strings.t('notAvailable'),
                              ),
                              _DetailRow(
                                strings.t('relationship'),
                                beneficiary['relationshipToHouseholdHead']
                                        ?.toString() ??
                                    strings.t('notAvailable'),
                              ),
                              _DetailRow(
                                strings.t('coverageStatus'),
                                coverage['status']?.toString() ??
                                    strings.t('notAvailable'),
                              ),
                              _DetailRow(
                                strings.t('validUntil'),
                                coverage['endDate']
                                        ?.toString()
                                        .split('T')
                                        .first ??
                                    strings.t('notAvailable'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kTextDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

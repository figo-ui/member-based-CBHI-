import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cbhi_data.dart';
import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Payment screen for CBHI premium renewal via Chapa
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.repository,
    required this.snapshot,
    required this.onPaymentComplete,
  });

  final CbhiRepository repository;
  final CbhiSnapshot snapshot;
  final VoidCallback onPaymentComplete;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _error;
  String? _checkoutUrl;
  String? _txRef;
  bool _paymentInitiated = false;
  bool _verifying = false;
  Map<String, dynamic>? _verifyResult;

  double get _premiumAmount => widget.snapshot.premiumAmount;

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.initiatePayment(
        amount: _premiumAmount,
        description:
            'CBHI premium for household ${widget.snapshot.householdCode}',
      );

      setState(() {
        _txRef = result['txRef']?.toString();
        _checkoutUrl = result['checkoutUrl']?.toString();
        _paymentInitiated = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPayment() async {
    final strings = AppLocalizations.of(context);
    if (_txRef == null) return;
    setState(() => _verifying = true);

    try {
      final result = await widget.repository.verifyPayment(_txRef!);
      setState(() {
        _verifyResult = result;
        _verifying = false;
      });

      if (result['status'] == 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('successPayment')),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onPaymentComplete();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _verifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('payPremium'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo mode banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: const Color(0xFFF9A825).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Text('🧪', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.t('demoSandboxAutoSuccess'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF856404),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('premiumAmount'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_premiumAmount.toStringAsFixed(2)} ETB',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${strings.t('householdLabel')}: ${widget.snapshot.householdCode}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Payment methods info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        strings.t('acceptedPaymentMethods'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PaymentChip(
                        label: 'Telebirr',
                        icon: Icons.phone_android,
                      ),
                      _PaymentChip(
                        label: 'CBE Birr',
                        icon: Icons.account_balance,
                      ),
                      _PaymentChip(label: 'Amole', icon: Icons.wallet),
                      _PaymentChip(label: 'HelloCash', icon: Icons.money),
                      _PaymentChip(
                        label: 'Bank Transfer',
                        icon: Icons.swap_horiz,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 24),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_paymentInitiated) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isLoading ? null : _initiatePayment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.open_in_new),
                label: Text(
                  strings.f('payViaChapa', {
                    'amount': _premiumAmount.toStringAsFixed(2),
                  }),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            ],

            if (_paymentInitiated && _checkoutUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.t('paymentInitiated'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${strings.t('transactionLabel')}: $_txRef',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(strings.t('completePaymentOnChapa')),
                    const SizedBox(height: 16),
                    // Show checkout URL as a copyable link
                    SelectableText(
                      _checkoutUrl!,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _verifying ? null : _verifyPayment,
                icon: _verifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined),
                label: Text(strings.t('verifyPayment')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
              ),
            ],

            if (_verifyResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      (_verifyResult!['status'] == 'success'
                              ? AppTheme.success
                              : AppTheme.warning)
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strings.t('statusLabel')}: ${_verifyResult!['status']?.toString().toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _verifyResult!['status'] == 'success'
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                    if (_verifyResult!['amount'] != null)
                      Text(
                        '${strings.t('amountLabel')}: ${_verifyResult!['amount']} ${strings.t('etb')}',
                      ),
                    if (_verifyResult!['paymentMethod'] != null)
                      Text(
                        '${strings.t('methodLabel')}: ${_verifyResult!['paymentMethod']}',
                      ),
                    Text(_verifyResult!['message']?.toString() ?? ''),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

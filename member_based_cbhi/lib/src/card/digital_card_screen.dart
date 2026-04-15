import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../cbhi_data.dart';
import '../cbhi_localizations.dart';
import '../cbhi_state.dart';
import '../shared/animated_widgets.dart';
import '../theme/app_theme.dart';

/// Digital CBHI card screen — shows QR-coded membership cards for all
/// household members (or just the current beneficiary for family logins).
class DigitalCardScreen extends StatelessWidget {
  const DigitalCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final strings = CbhiLocalizations.of(context);
        final snapshot = state.snapshot ?? CbhiSnapshot.empty();
        final cards = snapshot.digitalCards.isEmpty
            ? [
                {
                  'memberName': snapshot.viewerName,
                  'membershipId': snapshot.viewerMembershipId,
                  'coverageStatus': snapshot.coverageStatus,
                  'token': snapshot.cardToken,
                },
              ]
            : snapshot.digitalCards;

        return ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            SectionHeader(title: strings.t('digitalCbhiCards')),
            const SizedBox(height: 8),
            ...cards.toList().asMap().entries.map(
              (entry) {
                final card = entry.value;
                final hasToken =
                    (card['token']?.toString() ?? '').isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Maya City CBHI',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const Spacer(),
                              StatusBadge(
                                label: card['coverageStatus']?.toString() ??
                                    snapshot.coverageStatus,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            card['memberName']?.toString() ??
                                snapshot.viewerName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _CardInfoChip(
                                label: 'Household',
                                value: snapshot.householdCode.isEmpty
                                    ? '—'
                                    : snapshot.householdCode,
                              ),
                              const SizedBox(width: 16),
                              if ((card['membershipId']?.toString() ?? '')
                                  .isNotEmpty)
                                _CardInfoChip(
                                  label: 'Member ID',
                                  value: card['membershipId'].toString(),
                                ),
                            ],
                          ),
                          if (snapshot.coverageNumber.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _CardInfoChip(
                              label: 'Coverage',
                              value: snapshot.coverageNumber,
                            ),
                          ],
                          const SizedBox(height: 20),
                          // QR Code
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM),
                              ),
                              child: hasToken
                                  ? QrImageView(
                                      data: card['token']!.toString(),
                                      size: 200,
                                    )
                                  : SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 64,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            strings.t('noDigitalCardCached'),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              hasToken
                                  ? strings.t('encryptedQrToken')
                                  : strings.t('completeSyncForQr'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final info = [
                                    strings.t('appTitle'),
                                    '${strings.t('fullName')}: ${card['memberName'] ?? snapshot.viewerName}',
                                    '${strings.t('household')}: ${snapshot.householdCode}',
                                    'Member ID: ${card['membershipId'] ?? snapshot.viewerMembershipId}',
                                    '${strings.t('coverage')}: ${card['coverageStatus'] ?? snapshot.coverageStatus}',
                                    'Coverage #: ${snapshot.coverageNumber}',
                                  ].join('\n');
                                  await Clipboard.setData(
                                      ClipboardData(text: info));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(strings.t('cardDetailsCopied')),
                                      action: SnackBarAction(
                                          label: strings.t('ok'), onPressed: () {}),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.4)),
                                ),
                                icon: const Icon(Icons.share_outlined,
                                    size: 16),
                                label: Text(strings.t('shareCardInfo')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                          duration: 500.ms, delay: (entry.key * 100).ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        delay: (entry.key * 100).ms,
                        curve: Curves.easeOutCubic,
                      ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CardInfoChip extends StatelessWidget {
  const _CardInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

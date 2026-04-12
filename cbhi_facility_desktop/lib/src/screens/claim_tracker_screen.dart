import 'package:flutter/material.dart';
import '../app.dart';
import '../data/facility_repository.dart';
import '../i18n/app_localizations.dart';

class ClaimTrackerScreen extends StatefulWidget {
  const ClaimTrackerScreen({super.key, required this.repository});
  final FacilityRepository repository;

  @override
  State<ClaimTrackerScreen> createState() => _ClaimTrackerScreenState();
}

class _ClaimTrackerScreenState extends State<ClaimTrackerScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _claims = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final claims = await widget.repository.getClaims();
      setState(() => _claims = claims);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) => switch (status.toUpperCase()) {
    'APPROVED' || 'PAID' => kSuccess,
    'REJECTED' => kError,
    'UNDER_REVIEW' => kWarning,
    _ => kPrimary,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Text(
                strings.t('submittedClaims'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kTextDark,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: strings.t('refresh'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: kError)),
                )
              : _claims.isEmpty
              ? Center(
                  child: Text(
                    strings.t('noClaimsSubmittedYet'),
                    style: const TextStyle(color: kTextSecondary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(strings.t('claimNumber'))),
                          DataColumn(
                            label: Text(strings.t('beneficiaryColumn')),
                          ),
                          DataColumn(
                            label: Text(strings.t('serviceDateColumn')),
                          ),
                          DataColumn(label: Text(strings.t('claimedAmount'))),
                          DataColumn(label: Text(strings.t('approvedAmount'))),
                          DataColumn(label: Text(strings.t('status'))),
                          DataColumn(label: Text(strings.t('decisionNote'))),
                        ],
                        rows: _claims.map((claim) {
                          final status = claim['status']?.toString() ?? '';
                          final color = _statusColor(status);
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  claim['claimNumber']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  claim['beneficiaryName']?.toString() ??
                                      strings.t('notAvailable'),
                                ),
                              ),
                              DataCell(
                                Text(
                                  claim['serviceDate']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      strings.t('notAvailable'),
                                ),
                              ),
                              DataCell(Text('${claim['claimedAmount'] ?? 0}')),
                              DataCell(
                                Text(
                                  '${claim['approvedAmount'] ?? 0}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    strings.statusLabel(status),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  claim['decisionNote']?.toString() ?? '—',
                                  style: const TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

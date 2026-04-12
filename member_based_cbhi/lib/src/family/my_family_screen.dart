import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_cubit.dart';
import '../cbhi_data.dart';
import '../i18n/app_localizations.dart';
import 'add_beneficiary_screen.dart';
import 'my_family_cubit.dart';

class MyFamilyScreen extends StatelessWidget {
  const MyFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final familyCubit = context.read<MyFamilyCubit>();
    final repository = familyCubit.repository;
    final isFamilyMember = context.watch<AuthCubit>().state.isFamilyMember;

    return BlocConsumer<MyFamilyCubit, FamilyState>(
      listenWhen: (previous, current) => previous.error != current.error,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: familyCubit.load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isFamilyMember
                            ? strings.t('householdMembers')
                            : strings.t('myFamily'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (!isFamilyMember)
                      FilledButton.icon(
                        onPressed: state.isSaving
                            ? null
                            : () async {
                                final changed = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddBeneficiaryScreen(
                                          repository: repository,
                                        ),
                                      ),
                                    );
                                if (changed == true && context.mounted) {
                                  await familyCubit.load();
                                }
                              },
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(strings.t('addBeneficiary')),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFamilyMember
                      ? strings.t('viewHouseholdMembers')
                      : strings.t('manageHouseholdBeneficiaries'),
                ),
                const SizedBox(height: 20),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state.members.isEmpty)
                  Card(
                    child: ListTile(
                      title: Text(strings.t('noBeneficiariesAvailable')),
                      subtitle: Text(strings.t('addFamilyMembersOnceActive')),
                    ),
                  )
                else
                  ...state.members.map(
                    (member) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MemberAvatar(
                                  repository: repository,
                                  member: member,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              member.fullName,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                          ),
                                          Chip(
                                            label: Text(member.coverageStatus),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _InlineBadge(
                                            label:
                                                member
                                                    .relationshipToHouseholdHead ??
                                                'Member',
                                          ),
                                          if (member.membershipId.isNotEmpty)
                                            _InlineBadge(
                                              label: member.membershipId,
                                            ),
                                          if (member.phoneNumber != null &&
                                              member.phoneNumber!.isNotEmpty)
                                            _InlineBadge(
                                              label: member.phoneNumber!,
                                            ),
                                          if (member.canLoginIndependently)
                                            _InlineBadge(
                                              label: strings.t('otpEnabled'),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _detailLine(context, member),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (!isFamilyMember)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final changed =
                                            await Navigator.of(
                                              context,
                                            ).push<bool>(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddBeneficiaryScreen(
                                                      repository: repository,
                                                      member: member,
                                                    ),
                                              ),
                                            );
                                        if (changed == true &&
                                            context.mounted) {
                                          await familyCubit.load();
                                        }
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                      label: Text(strings.t('edit')),
                                    ),
                                  ),
                                  if (!member.isPrimaryHolder) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.tonalIcon(
                                        onPressed: () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: Text(
                                                    strings.t(
                                                      'removeBeneficiary',
                                                    ),
                                                  ),
                                                  content: Text(
                                                    strings.f(
                                                      'removeBeneficiaryMessage',
                                                      {'name': member.fullName},
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: Text(
                                                        strings.t('cancel'),
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: Text(
                                                        strings.t('remove'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                          if (confirmed == true &&
                                              context.mounted) {
                                            await familyCubit.removeMember(
                                              member.id,
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                        label: Text(strings.t('remove')),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _detailLine(BuildContext context, FamilyMember member) {
    final strings = AppLocalizations.of(context);
    final details = <String>[
      if (member.dateOfBirth != null && member.dateOfBirth!.isNotEmpty)
        '${strings.t('dobLabel')}: ${member.dateOfBirth!.split('T').first}',
      if (member.gender != null && member.gender!.isNotEmpty)
        '${strings.t('genderLabel')}: ${member.gender}',
      if (member.identityType != null && member.identityType!.isNotEmpty)
        '${strings.t('idLabel')}: ${member.identityType} ${member.identityNumber ?? ''}'
            .trim(),
      if (!member.canLoginIndependently &&
          member.relationshipToHouseholdHead == 'CHILD')
        strings.t('accessThroughHouseholdHead'),
      if (!member.canLoginIndependently &&
          member.relationshipToHouseholdHead != 'CHILD')
        strings.t('independentLoginNotEnabled'),
    ];
    return details.join('  •  ');
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.repository, required this.member});

  final CbhiRepository repository;
  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final resolved = repository.resolveMediaUrl(member.photoPath);
    final hasLocalFile =
        member.photoPath != null &&
        member.photoPath!.isNotEmpty &&
        File(member.photoPath!).existsSync();

    if (hasLocalFile) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: FileImage(File(member.photoPath!)),
      );
    }

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return CircleAvatar(
        radius: 28,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: resolved,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                const CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (_, __, ___) => Text(_initials(member.fullName)),
          ),
        ),
      );
    }

    return CircleAvatar(radius: 28, child: Text(_initials(member.fullName)));
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'B';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cbhi_localizations.dart';
import '../registration_cubit.dart';
import 'identity_cubit.dart';
import '../models/identity_model.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();

  String? selectedIdentityType;
  String? selectedEmploymentStatus;

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);

    /// Values match backend [IndigentEmploymentStatus] (snake_case).
    final List<Map<String, String>> employmentOptions = [
      {'value': 'farmer', 'label': strings.t('farmer')},
      {'value': 'merchant', 'label': strings.t('merchant')},
      {'value': 'daily_laborer', 'label': strings.t('dailyLaborer')},
      {'value': 'employed', 'label': strings.t('employed')},
      {'value': 'homemaker', 'label': strings.t('homemaker')},
      {'value': 'student', 'label': strings.t('student')},
      {'value': 'unemployed', 'label': strings.t('unemployed')},
      {'value': 'pensioner', 'label': strings.t('pensioner')},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('identityAndEmployment'))),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => IdentityCubit()),
        ],
        child: BlocBuilder<IdentityCubit, IdentityState>(
          builder: (context, identityState) {
            final identityCubit = context.read<IdentityCubit>();
            final regCubit = context.read<RegistrationCubit>();

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.t('identityVerification'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Identity Type Picker
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: strings.t('identityType')),
                      value: selectedIdentityType,
                      items: [
                        DropdownMenuItem(value: 'NATIONAL_ID', child: Text(strings.t('nationalId'))),
                        DropdownMenuItem(value: 'PASSPORT', child: Text(strings.t('passport'))),
                        DropdownMenuItem(value: 'LOCAL_ID', child: Text(strings.t('localId'))),
                      ],
                      onChanged: (value) {
                        setState(() => selectedIdentityType = value);
                      },
                      validator: (v) => v == null ? strings.t('required') : null,
                    ),

                    const SizedBox(height: 16),

                    // Identity Number
                    TextFormField(
                      controller: _idNumberController,
                      decoration: InputDecoration(labelText: strings.t('identityNumber')),
                      validator: (v) => (v == null || v.isEmpty) ? strings.t('required') : null,
                      onChanged: (v) => identityCubit.updateIdentityNumber(v),
                    ),

                    const SizedBox(height: 24),

                    // Employment Status (Key Feature)
                    Text(
                      strings.t('employmentOccupationStatus'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: strings.t('mainOccupation')),
                      value: selectedEmploymentStatus,
                      items: employmentOptions
                          .map((option) => DropdownMenuItem(
                                value: option['value'],
                                child: Text(option['label']!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedEmploymentStatus = value);
                        identityCubit.updateEmploymentStatus(value ?? '');
                      },
                      validator: (v) => v == null ? strings.t('required') : null,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              selectedIdentityType != null &&
                              selectedEmploymentStatus != null) {
                            
                            final identityModel = IdentityModel(
                              identityType: selectedIdentityType!,
                              identityNumber: _idNumberController.text.trim(),
                              employmentStatus: selectedEmploymentStatus!,
                            );

                            regCubit.submitIdentity(identityModel);
                          }
                        },
                        child: Text(strings.t('continueToMembership')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
            ),
            );
          },
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// Values match backend [IndigentEmploymentStatus] (snake_case).
  final List<Map<String, String>> employmentOptions = [
    {'value': 'farmer', 'label': 'Farmer (ገበሬ)'},
    {'value': 'merchant', 'label': 'Merchant / Trader (ነጋዴ)'},
    {'value': 'daily_laborer', 'label': 'Daily Laborer (የቀን ሰራተኛ)'},
    {'value': 'employed', 'label': 'Employed / Salaried (መደበኛ ሰራተኛ)'},
    {'value': 'homemaker', 'label': 'Homemaker (የቤት እመቤት)'},
    {'value': 'student', 'label': 'Student (ተማሪ)'},
    {'value': 'unemployed', 'label': 'Unemployed (ሥራ የለውም)'},
    {'value': 'pensioner', 'label': 'Pensioner (ጡረተኛ)'},
  ];

  String? selectedIdentityType;
  String? selectedEmploymentStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity & Employment')),
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
                    const Text(
                      'Identity Verification',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Identity Type Picker
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Identity Type'),
                      initialValue: selectedIdentityType,
                      items: const [
                        DropdownMenuItem(value: 'NATIONAL_ID', child: Text('National ID')),
                        DropdownMenuItem(value: 'PASSPORT', child: Text('Passport')),
                        DropdownMenuItem(value: 'LOCAL_ID', child: Text('Local / Kebele ID')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedIdentityType = value);
                      },
                      validator: (v) => v == null ? 'Please select identity type' : null,
                    ),

                    const SizedBox(height: 16),

                    // Identity Number
                    TextFormField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'Identity Number'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onChanged: (v) => identityCubit.updateIdentityNumber(v),
                    ),

                    const SizedBox(height: 24),

                    // Employment Status (Key Feature)
                    const Text(
                      'Employment / Occupation Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Main Occupation'),
                      initialValue: selectedEmploymentStatus,
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
                      validator: (v) => v == null ? 'Please select your occupation' : null,
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
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
                      child: const Text('Continue to Membership'),
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
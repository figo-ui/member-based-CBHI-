import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../registration_cubit.dart';

class PersonalInfoConfirmation extends StatelessWidget {
  const PersonalInfoConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    final regCubit = context.read<RegistrationCubit>();
    final personalInfo = regCubit.state.personalInfo!;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Your Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please review your details before continuing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildInfoCard('Personal Details', [
              'Full Name: ${personalInfo.firstName} ${personalInfo.middleName} ${personalInfo.lastName}',
              'Age: ${personalInfo.age}',
              'Phone: ${personalInfo.phone}',
              if (personalInfo.email != null) 'Email: ${personalInfo.email}',
              'Gender: ${personalInfo.gender}',
              'Date of Birth: ${personalInfo.dateOfBirth.toString().split(' ')[0]}',
              if (personalInfo.birthCertificatePath != null &&
                  personalInfo.birthCertificatePath!.isNotEmpty)
                'Birth certificate: attached',
              if (personalInfo.idDocumentPath != null &&
                  personalInfo.idDocumentPath!.isNotEmpty)
                'ID document: attached',
              if (personalInfo.birthCertificateRef != null)
                'Birth Certificate: ${personalInfo.birthCertificateRef}',
            ]),

            const SizedBox(height: 16),

            _buildInfoCard('Address & Household', [
              'Region: ${personalInfo.region}',
              'Zone: ${personalInfo.zone}',
              if (personalInfo.woreda != null) 'Woreda: ${personalInfo.woreda}',
              if (personalInfo.kebele != null) 'Kebele: ${personalInfo.kebele}',
              'Household Size: ${personalInfo.householdSize}',
            ]),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => regCubit.goBackToPersonalInfo(),
                    child: const Text('Edit Information'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => regCubit.confirmPersonalInfo(),
                    child: const Text('Confirm & Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(detail),
                )),
          ],
        ),
      ),
    );
  }
}
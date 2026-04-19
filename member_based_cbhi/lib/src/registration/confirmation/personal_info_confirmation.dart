import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cbhi_localizations.dart';
import '../registration_cubit.dart';

class PersonalInfoConfirmation extends StatelessWidget {
  const PersonalInfoConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = CbhiLocalizations.of(context);
    final regCubit = context.read<RegistrationCubit>();
    final personalInfo = regCubit.state.personalInfo!;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('reviewYourInformation'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('reviewYourInformation'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildInfoCard(strings.t('personalDetails'), [
              '${strings.t('fullName')}: ${personalInfo.firstName} ${personalInfo.middleName} ${personalInfo.lastName}',
              '${strings.t('age')}: ${personalInfo.age}',
              '${strings.t('phoneNumber')}: ${personalInfo.phone}',
              if (personalInfo.email != null) '${strings.t('email')}: ${personalInfo.email}',
              '${strings.t('genderLabel')}: ${personalInfo.gender}',
              '${strings.t('dobLabel')}: ${personalInfo.dateOfBirth.toString().split(' ')[0]}',
            ]),

            const SizedBox(height: 16),

            _buildInfoCard(strings.t('addressAndHousehold'), [
              '${strings.t('region')}: ${personalInfo.region}',
              '${strings.t('zone')}: ${personalInfo.zone}',
              if (personalInfo.woreda != null) '${strings.t('woreda')}: ${personalInfo.woreda}',
              if (personalInfo.kebele != null) '${strings.t('kebele')}: ${personalInfo.kebele}',
              '${strings.t('householdSize')}: ${personalInfo.householdSize}',
            ]),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => regCubit.goBackToPersonalInfo(),
                    child: Text(strings.t('editInformation')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => regCubit.confirmPersonalInfo(),
                    child: Text(strings.t('confirmAndContinue')),
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
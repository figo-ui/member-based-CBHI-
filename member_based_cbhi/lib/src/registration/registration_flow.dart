import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'registration_cubit.dart';
import 'personal_info/personal_info_form.dart';
import 'confirmation/personal_info_confirmation.dart';
import 'identity/identity_verification_screen.dart';
import 'membership/membership_selection_screen.dart';

class RegistrationFlow extends StatelessWidget {
  const RegistrationFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationCubit(context.read<CBHIData>()),
      child: BlocBuilder<RegistrationCubit, RegistrationState>(
        builder: (context, state) {
          switch (state.currentStep) {
            case RegistrationStep.personalInfo:
              return const PersonalInfoForm();
            case RegistrationStep.confirmation:
              return const PersonalInfoConfirmation();
            case RegistrationStep.identity:
              return const IdentityVerificationScreen();
            case RegistrationStep.membership:
              return const MembershipSelectionScreen();
            case RegistrationStep.completed:
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green),
                      SizedBox(height: 16),
                      Text('Registration Completed!', style: TextStyle(fontSize: 24)),
                      Text('Your digital card is now available.'),
                    ],
                  ),
                ),
              );
            default:
              return const Scaffold(body: Center(child: Text('Welcome to CBHI Registration')));
          }
        },
      ),
    );
  }
}
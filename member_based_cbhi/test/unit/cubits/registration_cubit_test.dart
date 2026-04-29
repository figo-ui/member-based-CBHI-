// Unit tests for RegistrationCubit — verifies registration flow state transitions

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/registration/registration_cubit.dart';
import 'package:member_based_cbhi/src/registration/models/personal_info_model.dart';
import 'package:member_based_cbhi/src/registration/models/identity_model.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}

void main() {
  late MockCbhiRepository mockRepository;
  late RegistrationCubit cubit;

  setUp(() {
    mockRepository = MockCbhiRepository();
    cubit = RegistrationCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('RegistrationCubit', () {
    test('initial state is at start step', () {
      expect(cubit.state.currentStep, RegistrationStep.start);
      expect(cubit.state.personalInfo, isNull);
      expect(cubit.state.identity, isNull);
    });

    test('submitPersonalInfo() advances to confirmation step', () {
      final personalInfo = PersonalInfoModel(
        firstName: 'Abebe',
        middleName: 'Kebede',
        lastName: 'Tadesse',
        age: 34,
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: DateTime(1990, 1, 1),
        householdSize: 4,
        region: 'Addis Ababa',
        zone: 'Addis Ababa',
        woreda: 'Bole',
        kebele: 'Kebele 01',
      );

      cubit.submitPersonalInfo(personalInfo);

      expect(cubit.state.currentStep, RegistrationStep.confirmation);
      expect(cubit.state.personalInfo, equals(personalInfo));
    });

    test('confirmPersonalInfo() advances to identity step', () {
      final personalInfo = PersonalInfoModel(
        firstName: 'Abebe',
        middleName: 'Kebede',
        lastName: 'Tadesse',
        age: 34,
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: DateTime(1990, 1, 1),
        householdSize: 4,
        region: 'Addis Ababa',
        zone: 'Addis Ababa',
        woreda: 'Bole',
        kebele: 'Kebele 01',
      );

      cubit.submitPersonalInfo(personalInfo);
      cubit.confirmPersonalInfo();

      expect(cubit.state.currentStep, RegistrationStep.identity);
    });

    test('submitIdentity() advances to membership step', () {
      final identity = IdentityModel(
        identityType: 'NATIONAL_ID',
        identityNumber: 'ID-123456',
        employmentStatus: 'EMPLOYED',
      );

      cubit.submitIdentity(identity);

      expect(cubit.state.currentStep, RegistrationStep.membership);
      expect(cubit.state.identity, equals(identity));
    });

    test('goBackToPersonalInfo() returns to personal info step', () {
      final personalInfo = PersonalInfoModel(
        firstName: 'Abebe',
        middleName: 'Kebede',
        lastName: 'Tadesse',
        age: 34,
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: DateTime(1990, 1, 1),
        householdSize: 4,
        region: 'Addis Ababa',
        zone: 'Addis Ababa',
        woreda: 'Bole',
        kebele: 'Kebele 01',
      );

      cubit.submitPersonalInfo(personalInfo);
      cubit.confirmPersonalInfo();
      cubit.goBackToPersonalInfo();

      expect(cubit.state.currentStep, RegistrationStep.personalInfo);
    });

    test('reset() clears all state', () {
      final personalInfo = PersonalInfoModel(
        firstName: 'Abebe',
        middleName: 'Kebede',
        lastName: 'Tadesse',
        age: 34,
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: DateTime(1990, 1, 1),
        householdSize: 4,
        region: 'Addis Ababa',
        zone: 'Addis Ababa',
        woreda: 'Bole',
        kebele: 'Kebele 01',
      );

      cubit.submitPersonalInfo(personalInfo);
      cubit.reset();

      expect(cubit.state.currentStep, RegistrationStep.start);
      expect(cubit.state.personalInfo, isNull);
    });
  });
}

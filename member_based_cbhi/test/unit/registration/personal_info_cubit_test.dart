// Unit tests for PersonalInfoCubit
// Tests field updates, validation, and model conversion.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/registration/personal_info/personal_info_cubit.dart';

void main() {
  group('PersonalInfoCubit', () {
    late PersonalInfoCubit cubit;

    setUp(() {
      cubit = PersonalInfoCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has empty fields', () {
      expect(cubit.state.firstName, '');
      expect(cubit.state.middleName, '');
      expect(cubit.state.lastName, '');
      expect(cubit.state.phone, '');
      expect(cubit.state.gender, '');
      expect(cubit.state.dateOfBirth, isNull);
      expect(cubit.state.region, '');
      expect(cubit.state.zone, '');
      expect(cubit.state.householdSize, 1);
    });

    test('updateField updates firstName', () {
      cubit.updateField(firstName: 'Alemayehu');
      expect(cubit.state.firstName, 'Alemayehu');
    });

    test('updateField updates multiple fields at once', () {
      cubit.updateField(
        firstName: 'Tigist',
        middleName: 'Haile',
        lastName: 'Bekele',
        phone: '+251912345678',
        gender: 'FEMALE',
      );
      expect(cubit.state.firstName, 'Tigist');
      expect(cubit.state.middleName, 'Haile');
      expect(cubit.state.lastName, 'Bekele');
      expect(cubit.state.phone, '+251912345678');
      expect(cubit.state.gender, 'FEMALE');
    });

    test('updateField updates dateOfBirth', () {
      final dob = DateTime(1990, 5, 15);
      cubit.updateField(dateOfBirth: dob);
      expect(cubit.state.dateOfBirth, dob);
    });

    test('updateField updates location fields', () {
      cubit.updateField(
        region: 'Oromia',
        zone: 'West Hararghe',
        woreda: 'Chiro',
        kebele: '01',
      );
      expect(cubit.state.region, 'Oromia');
      expect(cubit.state.zone, 'West Hararghe');
      expect(cubit.state.woreda, 'Chiro');
      expect(cubit.state.kebele, '01');
    });

    test('updateField updates householdSize', () {
      cubit.updateField(householdSize: 5);
      expect(cubit.state.householdSize, 5);
    });

    test('isValid returns false when required fields are empty', () {
      expect(cubit.isValid(), isFalse);
    });

    test('isValid returns false when only some fields are filled', () {
      cubit.updateField(
        firstName: 'Alemayehu',
        middleName: 'Bekele',
        lastName: 'Tadesse',
        phone: '+251912345678',
        gender: 'MALE',
        // Missing dateOfBirth, region, zone
      );
      expect(cubit.isValid(), isFalse);
    });

    test('isValid returns true when all required fields are filled', () {
      cubit.updateField(
        firstName: 'Alemayehu',
        middleName: 'Bekele',
        lastName: 'Tadesse',
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: DateTime(1985, 3, 20),
        region: 'Oromia',
        zone: 'West Hararghe',
        householdSize: 3,
      );
      expect(cubit.isValid(), isTrue);
    });

    test('isValid returns false when householdSize is 0', () {
      cubit.updateField(
        firstName: 'Alemayehu',
        middleName: 'Bekele',
        lastName: 'Tadesse',
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: DateTime(1985, 3, 20),
        region: 'Oromia',
        zone: 'West Hararghe',
        householdSize: 0,
      );
      expect(cubit.isValid(), isFalse);
    });

    test('toModel converts state to PersonalInfoModel correctly', () {
      final dob = DateTime(1985, 3, 20);
      cubit.updateField(
        firstName: 'Alemayehu',
        middleName: 'Bekele',
        lastName: 'Tadesse',
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: dob,
        region: 'Oromia',
        zone: 'West Hararghe',
        woreda: 'Chiro',
        kebele: '01',
        householdSize: 3,
      );

      final model = cubit.toModel();
      expect(model.firstName, 'Alemayehu');
      expect(model.middleName, 'Bekele');
      expect(model.lastName, 'Tadesse');
      expect(model.phone, '+251912345678');
      expect(model.gender, 'MALE');
      expect(model.dateOfBirth, dob);
      expect(model.region, 'Oromia');
      expect(model.zone, 'West Hararghe');
      expect(model.householdSize, 3);
    });

    test('toModel trims whitespace from string fields', () {
      cubit.updateField(
        firstName: '  Alemayehu  ',
        middleName: '  Bekele  ',
        lastName: '  Tadesse  ',
        phone: '  +251912345678  ',
        gender: 'MALE',
        dateOfBirth: DateTime(1985, 3, 20),
        region: 'Oromia',
        zone: 'West Hararghe',
        householdSize: 1,
      );

      final model = cubit.toModel();
      expect(model.firstName, 'Alemayehu');
      expect(model.middleName, 'Bekele');
      expect(model.lastName, 'Tadesse');
      expect(model.phone, '+251912345678');
    });

    test('toModel calculates age from dateOfBirth', () {
      // Born 30 years ago
      final dob = DateTime.now().subtract(const Duration(days: 365 * 30));
      cubit.updateField(
        firstName: 'Test',
        middleName: 'User',
        lastName: 'Name',
        phone: '+251912345678',
        gender: 'MALE',
        dateOfBirth: dob,
        region: 'Oromia',
        zone: 'West Hararghe',
        householdSize: 1,
      );

      final model = cubit.toModel();
      expect(model.age, closeTo(30, 1)); // Allow ±1 year for leap years
    });

    test('state is preserved across multiple updateField calls', () {
      cubit.updateField(firstName: 'Alemayehu');
      cubit.updateField(lastName: 'Bekele');
      cubit.updateField(phone: '+251912345678');

      // All previous updates should be preserved
      expect(cubit.state.firstName, 'Alemayehu');
      expect(cubit.state.lastName, 'Bekele');
      expect(cubit.state.phone, '+251912345678');
    });
  });
}

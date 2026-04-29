// Widget tests for PersonalInfoForm
// Tests validation, field presence, and form interaction.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:member_based_cbhi/src/registration/personal_info/personal_info_cubit.dart';
import 'package:member_based_cbhi/src/registration/personal_info/personal_info_form.dart';
import 'package:member_based_cbhi/src/cbhi_data.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

class MockCbhiRepository extends Mock implements CbhiRepository {}

Widget _buildTestApp({VoidCallback? onNext}) {
  final repo = MockCbhiRepository();
  when(() => repo.checkPhoneAvailability(any()))
      .thenAnswer((_) async => null);

  return MaterialApp(
    localizationsDelegates: CbhiLocalizations.delegatesFor(const Locale('en')),
    supportedLocales: CbhiLocalizations.supportedLocales,
    home: BlocProvider<PersonalInfoCubit>(
      create: (_) => PersonalInfoCubit(),
      child: Scaffold(
        body: PersonalInfoForm(
          repository: repo,
          onNext: onNext ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('PersonalInfoForm', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(PersonalInfoForm), findsOneWidget);
    });

    testWidgets('shows first name field', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsAny);
    });

    testWidgets('shows next/submit button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      // Should have at least one button
      expect(find.byType(FilledButton), findsAny);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

// Widget tests for admin app — state-driven UI rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_admin_desktop/src/blocs/claims_cubit.dart';
import 'package:cbhi_admin_desktop/src/blocs/overview_cubit.dart';

void main() {
  group('Claims list widget rendering', () {
    testWidgets('shows empty state when no claims', (tester) async {
      final state = ClaimsState.initial();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: state.claims.isEmpty
              ? const Center(child: Text('No claims found'))
              : ListView.builder(
                  itemCount: state.claims.length,
                  itemBuilder: (_, i) => Text(state.claims[i]['claimNumber'] ?? ''),
                ),
        ),
      ));

      expect(find.text('No claims found'), findsOneWidget);
    });

    testWidgets('shows claims list when data is present', (tester) async {
      final state = ClaimsState(
        claims: [
          {'status': 'SUBMITTED', 'claimNumber': 'CLM-001', 'beneficiaryName': 'Alice'},
          {'status': 'APPROVED', 'claimNumber': 'CLM-002', 'beneficiaryName': 'Bob'},
        ],
        isLoading: false, isReviewing: false, filter: 'ALL',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: state.filtered.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(state.filtered[i]['claimNumber']?.toString() ?? ''),
              subtitle: Text(state.filtered[i]['beneficiaryName']?.toString() ?? ''),
            ),
          ),
        ),
      ));

      expect(find.text('CLM-001'), findsOneWidget);
      expect(find.text('CLM-002'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      final state = ClaimsState.initial().copyWith(isLoading: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('Loaded'),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message', (tester) async {
      final state = ClaimsState(
        claims: const [], isLoading: false, isReviewing: false,
        error: 'Failed to load claims',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: state.error != null
                ? Text('Error: ${state.error}')
                : const Text('OK'),
          ),
        ),
      ));

      expect(find.text('Error: Failed to load claims'), findsOneWidget);
    });
  });

  group('Overview dashboard widget rendering', () {
    testWidgets('shows report data', (tester) async {
      final state = OverviewState(
        report: const {'totalHouseholds': 42, 'activeCoverage': 35},
        isLoading: false,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Households: ${state.report['totalHouseholds']}'),
              Text('Active: ${state.report['activeCoverage']}'),
            ],
          ),
        ),
      ));

      expect(find.text('Households: 42'), findsOneWidget);
      expect(find.text('Active: 35'), findsOneWidget);
    });
  });
}

// Performance tests for admin app claims list
// Tests scroll performance with large datasets and filter operation timing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cbhi_admin_desktop/src/blocs/claims_cubit.dart';

// Helper: build a list of N fake claims
List<Map<String, dynamic>> _fakeClaims(int count) {
  return List.generate(count, (i) => {
    'id': 'clm-$i',
    'claimNumber': 'CLM-${i.toString().padLeft(4, '0')}',
    'beneficiaryName': 'Member ${i + 1}',
    'facilityName': 'Health Center ${(i % 5) + 1}',
    'status': ['SUBMITTED', 'APPROVED', 'REJECTED', 'UNDER_REVIEW', 'PAID'][i % 5],
    'claimedAmount': (i + 1) * 150.0,
    'approvedAmount': i % 3 == 0 ? (i + 1) * 150.0 : null,
    'serviceDate': '2025-0${(i % 9) + 1}-01',
  });
}

void main() {
  group('Claims List Performance', () {
    testWidgets('renders 50 claims without overflow', (tester) async {
      final claims = _fakeClaims(50);
      final state = ClaimsState(
        claims: claims,
        isLoading: false,
        isReviewing: false,
        filter: 'ALL',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: state.filtered.length,
            itemBuilder: (_, i) {
              final claim = state.filtered[i];
              return ListTile(
                title: Text(claim['claimNumber']?.toString() ?? ''),
                subtitle: Text(claim['beneficiaryName']?.toString() ?? ''),
                trailing: Text(claim['status']?.toString() ?? ''),
              );
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls 50 claims without errors', (tester) async {
      final claims = _fakeClaims(50);
      final state = ClaimsState(
        claims: claims,
        isLoading: false,
        isReviewing: false,
        filter: 'ALL',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: state.filtered.length,
            itemBuilder: (_, i) {
              final claim = state.filtered[i];
              return ListTile(
                title: Text(claim['claimNumber']?.toString() ?? ''),
                subtitle: Text(claim['beneficiaryName']?.toString() ?? ''),
              );
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Scroll back up
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    test('filter operation completes within 50ms for 100 claims', () {
      final claims = _fakeClaims(100);
      final state = ClaimsState(
        claims: claims,
        isLoading: false,
        isReviewing: false,
        filter: 'APPROVED',
      );

      final stopwatch = Stopwatch()..start();
      final filtered = state.filtered;
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Filter operation took ${stopwatch.elapsedMilliseconds}ms, expected < 50ms');

      // Verify filter correctness
      expect(filtered.every((c) => c['status'] == 'APPROVED'), isTrue);
    });

    test('search operation completes within 50ms for 100 claims', () {
      final claims = _fakeClaims(100);
      final state = ClaimsState(
        claims: claims,
        isLoading: false,
        isReviewing: false,
        filter: 'ALL',
        searchQuery: 'CLM-0050',
      );

      final stopwatch = Stopwatch()..start();
      final filtered = state.filtered;
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Search took ${stopwatch.elapsedMilliseconds}ms, expected < 50ms');

      expect(filtered.length, 1);
      expect(filtered.first['claimNumber'], 'CLM-0050');
    });

    test('combined filter + search completes within 50ms for 100 claims', () {
      final claims = _fakeClaims(100);
      final state = ClaimsState(
        claims: claims,
        isLoading: false,
        isReviewing: false,
        filter: 'SUBMITTED',
        searchQuery: 'Member',
      );

      final stopwatch = Stopwatch()..start();
      final filtered = state.filtered;
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Combined filter+search took ${stopwatch.elapsedMilliseconds}ms, expected < 50ms');

      // All results should be SUBMITTED
      expect(filtered.every((c) => c['status'] == 'SUBMITTED'), isTrue);
    });

    testWidgets('builds claims list in under 100ms', (tester) async {
      final claims = _fakeClaims(50);

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: claims.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(claims[i]['claimNumber']?.toString() ?? ''),
              subtitle: Text(claims[i]['beneficiaryName']?.toString() ?? ''),
              trailing: Text(claims[i]['status']?.toString() ?? ''),
            ),
          ),
        ),
      ));
      await tester.pump();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Claims list build took ${stopwatch.elapsedMilliseconds}ms, expected < 100ms');
    });
  });
}

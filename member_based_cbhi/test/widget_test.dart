import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:member_based_cbhi/src/cbhi_localizations.dart';

void main() {
  testWidgets('smoke test renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('CBHI'))),
      ),
    );

    expect(find.text('CBHI'), findsOneWidget);
  });

  testWidgets('oromo app strings load without material localization errors', (
    WidgetTester tester,
  ) async {
    const selectedLocale = Locale('om');

    await tester.pumpWidget(
      MaterialApp(
        locale: CbhiLocalizations.resolveFrameworkLocale(selectedLocale),
        supportedLocales: CbhiLocalizations.frameworkSupportedLocales,
        localizationsDelegates: [
          CbhiLocalizations.delegateFor(selectedLocale),
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Text(CbhiLocalizations.of(context).t('language')),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Afaan Oromo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

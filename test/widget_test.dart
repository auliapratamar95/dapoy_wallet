import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dapoy_wallet/app/app.dart';

void main() {
  testWidgets('DapoyWalletApp renders navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DapoyWalletApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Anggaran'), findsWidgets);
    expect(find.text('Transaksi'), findsWidgets);
    expect(find.text('Analisis'), findsWidgets);
  });

  testWidgets('Renders properly without overflow on Samsung S7 (360x640)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: DapoyWalletApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders properly without overflow on iPhone 11 (375x812)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: DapoyWalletApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

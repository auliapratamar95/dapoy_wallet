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

    // Initial pump
    await tester.pump();

    // Verify main app title or navigation destinations exist
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Anggaran'), findsWidgets);
    expect(find.text('Transaksi'), findsWidgets);
    expect(find.text('Analisis'), findsWidgets);
  });
}

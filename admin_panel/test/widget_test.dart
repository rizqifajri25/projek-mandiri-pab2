import 'package:flutter_test/flutter_test.dart';

import 'package:admin_panel/main.dart';

void main() {
  testWidgets('Admin dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminApp());

    expect(find.text('Dashboard Realtime'), findsOneWidget);
    expect(find.text('USERS'), findsOneWidget);
    expect(find.text('TUGAS AKTIF'), findsOneWidget);
  });
}

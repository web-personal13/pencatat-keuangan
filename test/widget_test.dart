import 'package:flutter_test/flutter_test.dart';
import 'package:pencatat_keuangan/app.dart';
import 'package:pencatat_keuangan/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Dompi app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(DompiApp(storage: storage));
    await tester.pumpAndSettle();

    // Verify Onboarding or Main screen displays
    expect(find.textContaining('Dompi'), findsWidgets);
  });
}

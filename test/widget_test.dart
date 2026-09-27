import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/app/app.dart';

void main() {
  testWidgets('ThaheenApp smoke test mounts without errors', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThaheenApp());
    await tester.pump();

    // Verify that the app mounts cleanly.
    expect(find.byType(ThaheenApp), findsOneWidget);
  });
}

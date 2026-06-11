import 'package:flutter_test/flutter_test.dart';

import 'package:smartinbox_ai/app.dart';

void main() {
  testWidgets('SmartInboxApp renders LoginScreen smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const SmartInboxApp());

    // The app starts at the LoginScreen — verify the title text is present.
    expect(find.text('SmartInbox AI'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}

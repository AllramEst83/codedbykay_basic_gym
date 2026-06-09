import 'package:flutter_test/flutter_test.dart';

import 'package:codedbykay_basic_gym/main.dart';

void main() {
  testWidgets('FlexFlow app smoke test - app brand renders',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FlexFlowApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('FlexFlow'), findsOneWidget);
    expect(find.text('Calendar'), findsWidgets);
  });
}

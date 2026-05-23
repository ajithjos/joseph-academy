import 'package:flutter_test/flutter_test.dart';

import 'package:cornerstone/main.dart';

void main() {
  testWidgets('app shell renders title', (tester) async {
    await tester.pumpWidget(const CornerstoneApp());
    expect(find.text('Owner'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:joseph_academy/main.dart';

void main() {
  testWidgets('app shell renders title', (tester) async {
    await tester.pumpWidget(const JosephAcademyApp());
    expect(find.text('Joseph Academy'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/startup_failure.dart';

void main() {
  testWidgets('a failed start shows the error in both languages', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupFailureApp(error: 'disk full'));

    expect(find.textContaining('تعذّر فتح التطبيق'), findsOneWidget);
    expect(find.textContaining('could not open'), findsOneWidget);
    expect(find.text('disk full'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(SelectableText), findsOneWidget);
  });
}

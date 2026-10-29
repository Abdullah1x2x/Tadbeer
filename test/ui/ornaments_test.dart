import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/core/design_system/ornaments.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('the pattern lets taps through (dark: $dark)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(
            body: PatternBackground(
              child: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('tap'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tap'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the divider keeps its size and is hidden from screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Center(child: OrnamentDivider(width: 120, starSize: 6)),
      ),
    );
    expect(tester.getSize(find.byType(OrnamentDivider)), const Size(120, 12));
    expect(
      find.descendant(
        of: find.byType(OrnamentDivider),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });

  test('the star is closed and fits its radius', () {
    final bounds = eightPointStar(const Offset(50, 50), 20).getBounds();
    expect(bounds.top, closeTo(30, 0.01));
    expect(bounds.width, lessThanOrEqualTo(40.01));
  });
}

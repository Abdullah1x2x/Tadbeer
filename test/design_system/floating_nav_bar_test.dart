import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/design_system/design_system.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  const items = [
    FloatingNavItem(
      icon: AppIcons.house,
      selectedIcon: AppIcons.houseFill,
      label: 'الرئيسية',
    ),
    FloatingNavItem(
      icon: AppIcons.bookOpen,
      selectedIcon: AppIcons.bookOpenFill,
      label: 'المصحف',
    ),
    FloatingNavItem(
      icon: AppIcons.squaresFour,
      selectedIcon: AppIcons.squaresFourFill,
      label: 'المزيد',
    ),
  ];

  Widget host({required int selected, required ValueChanged<int> onSelected}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          bottomNavigationBar: FloatingNavBar(
            items: items,
            selectedIndex: selected,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  group('FloatingNavBar', () {
    testWidgets('the pill stays inside the bar while moving to an edge', (
      WidgetTester tester,
    ) async {
      final pill = find
          .descendant(
            of: find.byType(AnimatedPositioned),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final track = find
          .ancestor(
            of: find.byType(AnimatedPositioned),
            matching: find.byType(Stack),
          )
          .first;
      for (final (from, to) in [(0, 2), (2, 0)]) {
        await tester.pumpWidget(host(selected: from, onSelected: (_) {}));
        await tester.pumpAndSettle();
        await tester.pumpWidget(host(selected: to, onSelected: (_) {}));
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final bounds = tester.getRect(track);
          final rect = tester.getRect(pill);
          expect(rect.left, greaterThanOrEqualTo(bounds.left - 0.01));
          expect(rect.right, lessThanOrEqualTo(bounds.right + 0.01));
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows only the selected name and keeps all as tooltips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(selected: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();

      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('المصحف'), findsNothing);
      for (final item in items) {
        expect(find.byTooltip(item.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping an item reports it and moves the selection', (
      WidgetTester tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            selected: selected,
            onSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('المصحف'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.text('المصحف'), findsOneWidget);
      expect(find.text('الرئيسية'), findsNothing);

      // Tapping the selected item again does nothing.
      await tester.tap(find.byTooltip('المصحف'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays items right-to-left in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(host(selected: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();

      final home = tester.getCenter(find.byTooltip('الرئيسية'));
      final more = tester.getCenter(find.byTooltip('المزيد'));
      expect(home.dx, greaterThan(more.dx));
    });
  });
}

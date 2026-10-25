import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/design_system/design_system.dart';

void main() {
  const items = [
    FloatingNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    FloatingNavItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'المصحف',
    ),
    FloatingNavItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
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

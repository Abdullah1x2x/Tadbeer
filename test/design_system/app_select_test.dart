import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';
import 'package:tadbeer/core/design_system/app_menu.dart';
import 'package:tadbeer/core/design_system/app_select.dart';

void main() {
  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
  });

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  final surahs = [
    for (final (n, name) in [(1, 'الفاتحة'), (2, 'البقرة'), (3, 'آل عمران')])
      AppSelectOption<int>(value: n, label: '${'٠١٢٣'[n]}. $name'),
  ];

  testWidgets('shows the choice and picks another from a sheet', (
    tester,
  ) async {
    int? chosen;
    await tester.pumpWidget(
      host(
        AppSelectField<int>(
          title: 'اختر السورة',
          icon: AppIcons.bookOpenText,
          options: surahs,
          value: 1,
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    expect(find.text('١. الفاتحة'), findsOneWidget);

    await tester.tap(find.text('١. الفاتحة'));
    await tester.pumpAndSettle();
    expect(find.text('اختر السورة'), findsOneWidget);
    // The current choice is marked.
    expect(find.byIcon(AppIcons.checkCircleFill), findsOneWidget);

    await tester.tap(find.text('٣. آل عمران'));
    await tester.pumpAndSettle();
    expect(chosen, 3);
    expect(find.text('اختر السورة'), findsNothing);
  });

  testWidgets('a search finds by name or number in either digits', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppSelectField<int>(
          title: 'اختر السورة',
          options: surahs,
          value: 1,
          searchable: true,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('١. الفاتحة'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();
    expect(find.text('٢. البقرة'), findsOneWidget);
    expect(find.text('٣. آل عمران'), findsNothing);

    await tester.enterText(find.byType(TextField), 'عمران');
    await tester.pump();
    expect(find.text('٣. آل عمران'), findsOneWidget);
    expect(find.text('٢. البقرة'), findsNothing);
  });

  testWidgets('menu items share a look, deleting in the error colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PopupMenuButton<String>(
          icon: appMenuIcon,
          itemBuilder: (_) => [
            appMenuItem(
              value: 'edit',
              icon: AppIcons.pencilSimple,
              label: 'تعديل',
            ),
            appMenuItem(
              value: 'delete',
              icon: AppIcons.trash,
              label: 'حذف',
              destructive: true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byIcon(AppIcons.dotsThreeVertical));
    await tester.pumpAndSettle();
    final error = Theme.of(tester.element(find.text('حذف'))).colorScheme.error;
    expect(tester.widget<Text>(find.text('حذف')).style?.color, error);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.trash)).color, error);
    expect(tester.widget<Text>(find.text('تعديل')).style?.color, isNull);
    expect(tester.takeException(), isNull);
  });
}

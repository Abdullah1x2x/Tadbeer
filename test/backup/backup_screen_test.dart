import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/features/backup/backup_screen.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  group('BackupScreen UI & Options Tests', () {
    testWidgets(
      'Renders export and restore cards with Save to Files and Share buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const BackupScreen()));
        await tester.pumpAndSettle();

        final l10n = const AppStrings(AppLanguage.arabic);

        // Verify Screen Title
        expect(find.text(l10n.backup), findsOneWidget);

        // Verify Export Section
        expect(find.text(l10n.exportBackup), findsOneWidget);
        expect(find.text(l10n.notes), findsOneWidget);
        expect(find.text(l10n.bookmarks), findsOneWidget);
        expect(find.text(l10n.highlights), findsOneWidget);
        expect(find.text(l10n.reminders), findsOneWidget);
        expect(find.text(l10n.settings), findsOneWidget);

        // Verify the two export buttons: Save to Device Files and Share via Apps
        expect(find.text(l10n.saveToDeviceFiles), findsOneWidget);
        expect(find.byIcon(AppIcons.downloadSimple), findsOneWidget);

        expect(find.text(l10n.shareViaApps), findsOneWidget);
        expect(find.byIcon(AppIcons.shareNetwork), findsOneWidget);

        // Verify Restore Section
        expect(find.text(l10n.restoreBackup), findsWidgets);
        expect(find.byIcon(AppIcons.downloadSimple), findsOneWidget);
      },
    );

    testWidgets('Toggling checkboxes updates selection state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const BackupScreen()));
      await tester.pumpAndSettle();

      final l10n = const AppStrings(AppLanguage.arabic);

      // All checkboxes are checked by default
      final notesCheckbox = find.widgetWithText(CheckboxListTile, l10n.notes);
      expect(tester.widget<CheckboxListTile>(notesCheckbox).value, isTrue);

      // Tap to uncheck
      await tester.tap(notesCheckbox);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(notesCheckbox).value, isFalse);

      // Tap to re-check
      await tester.tap(notesCheckbox);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(notesCheckbox).value, isTrue);
    });
  });
}

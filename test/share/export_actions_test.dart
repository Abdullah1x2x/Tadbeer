import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/features/share/export_actions.dart';

void main() {
  testWidgets('an export offers sharing and saving to the device', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    shareOrSaveFile(context, file: File('a.pdf'), fileName: 'a.pdf').ignore();
    await tester.pumpAndSettle();

    expect(find.text('مشاركة'), findsOneWidget);
    expect(find.text('حفظ في ملفات الجهاز'), findsOneWidget);
  });
}

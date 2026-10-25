import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/main_shell.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/daily/ayah_of_day_card.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/widgets/widget_ayah_image.dart';
import 'package:tadbeer/features/widgets/widget_links.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    final amiri = FontLoader('AmiriQuran')
      ..addFont(rootBundle.load('assets/fonts/AmiriQuran-Regular.ttf'));
    await amiri.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_widget_links_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('every ayah of the day fits the widget image', (tester) async {
    // The longest ayahs the widget can be given.
    final longest = [...AyahOfTheDay.pool]
      ..sort((a, b) => b.text.length.compareTo(a.text.length));
    for (final ayah in longest.take(5)) {
      await tester.pumpWidget(Center(child: WidgetAyahImage(ayah: ayah)));
      final size = tester.getSize(find.byType(WidgetAyahImage));
      expect(size, WidgetAyahImage.sizeFor(ayah));
      expect(size.width, WidgetAyahImage.width);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('an ayah link opens it in the Mushaf', (tester) async {
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Text('intro')),
        ),
      ),
    );
    WidgetLinks.open(Uri.parse('tadbeer://ayah?s=2&a=255'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The shell sits under the reader, ready for the back button.
    expect(find.byType(MainShell, skipOffstage: false), findsOneWidget);
    final reader = tester.widget<QuranScreen>(find.byType(QuranScreen).last);
    expect(reader.targetSurahNumber, 2);
    expect(reader.targetAyahNumber, 255);
    expect(reader.initialPage, 42);
  });

  testWidgets('links from other apps are ignored', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        home: const Scaffold(body: Text('intro')),
      ),
    );
    WidgetLinks.open(Uri.parse('https://example.com/ayah?s=2&a=255'));
    await tester.pump();
    expect(find.text('intro'), findsOneWidget);
  });
}

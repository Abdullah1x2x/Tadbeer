import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/main_shell.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/daily/ayah_of_day_card.dart';
import 'package:tadbeer/data/quran/quran_models.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/widgets/widget_ayah_image.dart';
import 'package:tadbeer/features/widgets/widget_links.dart';

void main() {
  late Directory tempDir;

  /// The longest ayahs the widget can be given.
  late List<Ayah> longest;

  setUpAll(() async {
    final amiri = FontLoader('AmiriQuran')
      ..addFont(rootBundle.load('assets/fonts/AmiriQuran-Regular.ttf'));
    await amiri.load();
    // Their Madinah glyphs load here, outside any test's clock.
    await QuranRepository.instance.init();
    longest = [...AyahOfTheDay.pool]
      ..sort((a, b) => b.text.length.compareTo(a.text.length));
    longest = longest.take(5).toList();
    for (final ayah in longest) {
      await QcfGlyphs.prepare(ayah);
    }
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
    for (final ayah in longest) {
      // In the flowing text's font, and in the Madinah glyphs.
      for (final glyphs in [null, QcfGlyphs.of(ayah)!]) {
        await tester.pumpWidget(
          Center(
            child: WidgetAyahImage(
              ayah: ayah,
              glyphs: glyphs,
              font: 'AmiriQuran',
            ),
          ),
        );
        final size = tester.getSize(find.byType(WidgetAyahImage));
        expect(
          size,
          WidgetAyahImage.sizeFor(ayah, glyphs: glyphs, font: 'AmiriQuran'),
        );
        expect(size.width, WidgetAyahImage.width);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('the Madinah image writes the ayah in its page\'s glyphs', (
    tester,
  ) async {
    final ayah = longest.first;
    final glyphs = QcfGlyphs.of(ayah)!;
    await tester.pumpWidget(
      Center(
        child: WidgetAyahImage(ayah: ayah, glyphs: glyphs, font: 'AmiriQuran'),
      ),
    );
    final text = tester.widget<RichText>(find.byType(RichText)).text;
    expect(text.toPlainText(), glyphs.text);
    // Text.rich wraps the span in the default style; the glyphs' own
    // style is on the span inside.
    final inner = (text as TextSpan).children!.single as TextSpan;
    expect(inner.style!.fontFamily, QcfFonts.familyFor(ayah.page));
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

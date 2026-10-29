import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

/// One press on a Mushaf page: held until the rosette opens, slid to a
/// petal and lifted, all inside the page view that also turns pages.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QcfLayout.instance.init();
    for (final page in [1, 49, 50, 51]) {
      await QcfFonts.instance.ensurePage(page);
    }
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_rosette_press_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
    await UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(
        hideTadbeerIntroPermanently: true,
      ),
    );
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('press, slide to a petal and lift runs it', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: const MaterialApp(home: QuranScreen(initialPage: 50)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // A line of ayah text on the page.
    // The page's font sits on a span without text of its own, which
    // visitChildren skips, so walk the tree directly.
    bool drawnInPage50(InlineSpan span) =>
        span.style?.fontFamily == QcfFonts.familyFor(50) ||
        (span is TextSpan && (span.children ?? const []).any(drawnInPage50));

    final line = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .where((p) => drawnInPage50(p.text))
        .elementAt(5);
    final start = line.localToGlobal(line.size.center(Offset.zero));

    final finger = await tester.startGesture(start);
    // Held past the long press: the rosette opens under the finger.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    final heart = tester.getCenter(
      find
          .ancestor(
            of: find.text('وقفة تدبر'),
            matching: find.byType(AnimatedScale),
          )
          .first,
    );

    // Slide to the petal to the right of the heart: the bookmark.
    for (var x = 20.0; x <= 104; x += 21) {
      await finger.moveTo(heart + Offset(x, 0));
      await tester.pump();
    }
    expect(find.text('علامة'), findsNWidgets(2));

    await tester.runAsync(() async {
      await finger.up();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 500));

    expect(UserDataStore.instance.bookmarks, hasLength(1));
    // Still on the same page: the slide did not turn it.
    expect(find.textContaining('آل عمران'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

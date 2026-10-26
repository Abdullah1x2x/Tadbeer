import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/widgets/surah_header_banner.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_frame_theme_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    AppColors.use(AppColorTheme.navy);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('the Mushaf frame takes the theme colour, even after a switch', () {
    for (final tone in MushafPaperTone.values) {
      for (final theme in AppColorTheme.values) {
        AppColors.use(theme);
        final p = ThemePalette.of(theme);
        final light = MushafPalette.of(isDark: false, tone: tone);
        final dark = MushafPalette.of(isDark: true, tone: tone);
        expect(light.frame, p.lightPrimary, reason: '$theme $tone');
        expect(dark.frame, p.darkPrimary, reason: '$theme $tone');
        // The same theme, mode and paper give the same palette, so
        // painters only repaint when one of them changes.
        expect(
          identical(light, MushafPalette.of(isDark: false, tone: tone)),
          isTrue,
        );
      }
    }
    // The classic paper follows the theme too, not the first one used.
    AppColors.use(AppColorTheme.emerald);
    expect(
      MushafPalette.of(isDark: true, tone: MushafPaperTone.classic).page,
      ThemePalette.emerald.darkSurface,
    );
  });

  testWidgets('the surah header is drawn in the theme colour', (tester) async {
    AppColors.use(AppColorTheme.burgundy);
    final surah = QuranRepository.instance.getSurah(2);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(width: 400, child: SurahHeaderBanner(surah: surah)),
        ),
      ),
    );
    final number = tester.widget<Text>(find.text('٢'));
    expect(number.style?.color, ThemePalette.burgundy.lightPrimary);
    expect(tester.takeException(), isNull);
  });
}

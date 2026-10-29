import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';
import 'package:tadbeer/features/share/ayah_share_sheet.dart';

void main() {
  late Directory tempDir;

  // The Madinah glyphs of the page shown (Al-Baqarah 255) load once here,
  // outside any test's clock, as the reader would have them.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QcfLayout.instance.init();
    await QcfFonts.instance.ensurePage(42);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_share_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Center(child: FittedBox(child: child)),
    ),
  );

  group('AyahCard', () {
    // Al-Baqarah 282 is the longest verse; it must still fit every format.
    for (final style in AyahCardStyle.values) {
      for (final height in [360.0, 640.0]) {
        testWidgets('fits the longest verse ($style, height $height)', (
          WidgetTester tester,
        ) async {
          final ayah = QuranRepository.instance.getAyah(2, 282)!;
          await tester.pumpWidget(
            host(
              AyahCard(ayah: ayah, style: style, width: 360, height: height),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('سُورَةُ'), findsOneWidget);
          expect(find.text('تَدْبِير'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('writes the ayah in the selected Mushaf\'s font', (
      tester,
    ) async {
      final ayah = QuranRepository.instance.getAyah(2, 255)!;
      Future<void> pumpCard() async {
        await tester.pumpWidget(
          host(
            AyahCard(
              ayah: ayah,
              style: AyahCardStyle.dark,
              width: 360,
              height: 360,
            ),
          ),
        );
        await tester.pump();
      }

      // The Madinah Mushaf: the ayah in its own glyphs.
      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.madinah),
      );
      await pumpCard();
      expect(find.byType(QcfAyahText), findsOneWidget);

      // Flowing text: the ayah in the font chosen for it.
      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
      );
      await pumpCard();
      expect(find.byType(QcfAyahText), findsNothing);
      final verse = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byType(AyahCard),
              matching: find.byType(RichText),
            ),
          )
          .firstWhere((t) => t.text.toPlainText().contains('﴿'));
      expect(
        verse.text.style!.fontFamily,
        UserDataStore.instance.quranFontFamily,
      );
    });

    /// The colours the card's background is painted with.
    List<Color> backgroundOf(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AyahCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).gradient!.colors;
    }

    for (final theme in AppColorTheme.values) {
      testWidgets('takes its colours from the $theme theme', (tester) async {
        final ayah = QuranRepository.instance.getAyah(1, 2)!;
        final p = ThemePalette.of(theme);
        for (final style in AyahCardStyle.values) {
          await tester.pumpWidget(
            host(
              AyahCard(
                ayah: ayah,
                style: style,
                width: 360,
                height: 360,
                colorTheme: theme,
              ),
            ),
          );
          final colors = backgroundOf(tester);
          if (style == AyahCardStyle.dark) {
            expect(colors, [p.heroLightStart, p.darkBackground]);
          } else {
            // A light paper, tinted by the theme.
            expect(colors.first.computeLuminance(), greaterThan(0.85));
            expect(
              colors.last,
              Color.lerp(p.lightBackground, p.heroLightStart, 0.08),
            );
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  });

  group('AyahShareSheet saving', () {
    const channel = MethodChannel('gal');
    late List<MethodCall> calls;
    late bool granted;

    setUp(() {
      calls = [];
      granted = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'hasAccess' || 'requestAccess' => granted,
              _ => null,
            };
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> openSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ayah = QuranRepository.instance.getAyah(2, 255)!;
      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: const AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => AyahShareSheet.show(context, ayah),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// Whether the sheet has finished asking for access or saving.
    bool settled() =>
        calls.any((c) => c.method == 'putImageBytes') ||
        (!granted && calls.any((c) => c.method == 'requestAccess'));

    Future<void> tapSave(WidgetTester tester) async {
      // Drawing the image, and loading the Madinah glyphs it waits for,
      // run off the test clock.
      await tester.runAsync(() async {
        await tester.tap(find.text('حفظ في الصور'));
        for (var i = 0; i < 40 && !settled(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    testWidgets('saves a 2160 pixel wide image to Photos', (tester) async {
      await openSheet(tester);
      await tapSave(tester);
      final put = calls.singleWhere((c) => c.method == 'putImageBytes');
      final bytes = (put.arguments as Map)['bytes'] as Uint8List;
      // A PNG's width is the four bytes after its 16-byte header.
      final width = ByteData.sublistView(bytes, 16, 20).getUint32(0);
      expect(width, 2160);
      expect((put.arguments as Map)['name'], 'tadbeer_2_255');
      expect(find.text('حُفظت البطاقة في الصور'), findsOneWidget);
    });

    testWidgets('says how to allow it when access is refused', (tester) async {
      granted = false;
      await openSheet(tester);
      await tapSave(tester);
      expect(calls.where((c) => c.method == 'putImageBytes'), isEmpty);
      expect(
        find.text('اسمح لتدبير بإضافة الصور من إعدادات الجهاز'),
        findsOneWidget,
      );
    });
  });
}

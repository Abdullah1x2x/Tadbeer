import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/widgets/ayah_action_sheet.dart';
import 'package:tadbeer/features/quran/widgets/ayah_rosette.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_pause_sheet.dart';

void main() {
  late Directory tempDir;
  late BuildContext host;

  // Where the finger presses on an ayah.
  const press = Offset(206, 300);
  const ring = 98.0;

  /// The middle of the medallion, wherever it opened.
  late Offset centre;

  /// Where petal [i] sits, clockwise from the top.
  Offset petal(int i) {
    final a = i * math.pi / 4;
    return centre + Offset(math.sin(a), -math.cos(a)) * ring;
  }

  Offset heartOf(WidgetTester tester) => tester.getCenter(
    find
        .ancestor(
          of: find.text('وقفة تدبر'),
          matching: find.byType(AnimatedScale),
        )
        .first,
  );

  // Real fonts, so text measures as on a device.
  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    final amiri = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    await Future.wait([plex.load(), amiri.load()]);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_rosette_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    Offset? at = press,
    bool screenReader = false,
  }) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(accessibleNavigation: screenReader),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                host = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    final ayah = QuranRepository.instance.getAyah(2, 255)!;
    unawaited(AyahRosette.show(host, ayah, at: at));
    await tester.pumpAndSettle();
    if (!screenReader) centre = heartOf(tester);
  }

  /// Whether the actions' names are showing under them.
  bool labelsShown(WidgetTester tester) =>
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.text('رابط آيات'),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity ==
      1;

  testWidgets('sliding to a petal names it, and lifting runs it', (
    tester,
  ) async {
    await open(tester);
    expect(labelsShown(tester), isFalse);

    AyahRosette.dragTo(petal(2));
    await tester.pump();
    // The heart names the action under the finger.
    expect(find.text('علامة'), findsNWidgets(2));

    await tester.runAsync(() async {
      AyahRosette.releaseAt(petal(2));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(UserDataStore.instance.isBookmarked(2, 255), isTrue);
    expect(find.text('رابط آيات'), findsNothing);
  });

  testWidgets('lifting without choosing keeps it open with names', (
    tester,
  ) async {
    await open(tester);
    AyahRosette.releaseAt(press);
    await tester.pumpAndSettle();
    expect(labelsShown(tester), isTrue);

    // Now a tap chooses.
    await tester.tap(find.text('تمييز').first);
    await tester.pumpAndSettle();
    expect(find.byType(AyahActionSheet), findsOneWidget);
  });

  testWidgets('the empty place chooses nothing', (tester) async {
    await open(tester);
    AyahRosette.dragTo(petal(7));
    await tester.pump();
    AyahRosette.releaseAt(petal(7));
    await tester.pumpAndSettle();
    expect(labelsShown(tester), isTrue);
  });

  testWidgets('coming back to the heart opens the reflection', (tester) async {
    await open(tester);
    AyahRosette.dragTo(petal(0));
    await tester.pump();
    AyahRosette.dragTo(centre);
    await tester.pump();
    AyahRosette.releaseAt(centre);
    await tester.pumpAndSettle();
    expect(find.byType(TadbeerPauseSheet), findsOneWidget);
  });

  testWidgets('opened without a finger it waits for a tap', (tester) async {
    await open(tester, at: null);
    expect(labelsShown(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back closes the rosette, not the screen under it', (
    tester,
  ) async {
    await open(tester);
    AyahRosette.releaseAt(press);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('رابط آيات'), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('lifting in place chooses nothing, wherever it pressed', (
    tester,
  ) async {
    // Pressed where a petal will sit: the finger has not moved to it.
    await open(tester, at: const Offset(206, 700));
    AyahRosette.dragTo(const Offset(209, 700));
    AyahRosette.releaseAt(const Offset(206, 700));
    await tester.pumpAndSettle();
    expect(find.byType(TadbeerPauseSheet), findsNothing);
    expect(labelsShown(tester), isTrue);
  });

  testWidgets('it opens in the same place for every ayah', (tester) async {
    await open(tester, at: const Offset(60, 150));
    final first = centre;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    unawaited(
      AyahRosette.show(
        host,
        QuranRepository.instance.getAyah(1, 2)!,
        at: const Offset(350, 820),
      ),
    );
    await tester.pumpAndSettle();
    expect(heartOf(tester), first);
    // Low on the screen, leaving the top for the ayah.
    expect(first.dx, 206);
    expect(first.dy, greaterThan(915 / 2));
  });

  testWidgets('the ayah is shown on its own above it', (tester) async {
    await open(tester);
    expect(find.text('سورة البقرة · الآية ٢٥٥'), findsOneWidget);
    expect(find.byType(QcfAyahText), findsOneWidget);
    final card = tester.getRect(
      find
          .ancestor(
            of: find.byType(QcfAyahText),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    // Just above the medallion, however short the ayah.
    expect(card.bottom, lessThan(centre.dy - 150));
    expect(card.bottom, greaterThan(centre.dy - 190));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling a note from it leaves nothing open', (tester) async {
    await open(tester);
    AyahRosette.releaseAt(press);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملاحظة').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(AyahActionSheet), findsNothing);
    expect(find.text('رابط آيات'), findsNothing);
  });

  testWidgets('saving a note from it closes it too', (tester) async {
    await open(tester);
    AyahRosette.releaseAt(press);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملاحظة').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ملاحظة على الآية');
    await tester.runAsync(() async {
      await tester.tap(find.text('حفظ'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(AyahActionSheet), findsNothing);
    expect(UserDataStore.instance.getNotesForAyah(2, 255), hasLength(1));
  });

  testWidgets('a screen reader gets the plain sheet', (tester) async {
    await open(tester, screenReader: true);
    expect(find.byType(AyahActionSheet), findsOneWidget);
  });
}

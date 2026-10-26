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
import 'package:tadbeer/features/quran/widgets/ayah_action_sheet.dart';
import 'package:tadbeer/features/quran/widgets/ayah_rosette.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_pause_sheet.dart';

void main() {
  late Directory tempDir;
  late BuildContext host;

  // Where the finger presses; the rosette opens centred on it.
  const centre = Offset(206, 450);
  const ring = 98.0;

  /// Where petal [i] sits, clockwise from the top.
  Offset petal(int i) {
    final a = i * math.pi / 4;
    return centre + Offset(math.sin(a), -math.cos(a)) * ring;
  }

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
    Offset? at = centre,
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
    AyahRosette.releaseAt(centre);
    await tester.pumpAndSettle();
    expect(labelsShown(tester), isTrue);
    expect(find.text('سورة البقرة · الآية ٢٥٥'), findsOneWidget);

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
    AyahRosette.releaseAt(centre);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('رابط آيات'), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('lifting in place chooses nothing near the edge too', (
    tester,
  ) async {
    // Near the edge the rosette opens off-centre, so the finger rests
    // on the heart without having moved to it.
    const edge = Offset(400, 450);
    await open(tester, at: edge);
    AyahRosette.dragTo(edge + const Offset(3, 0));
    AyahRosette.releaseAt(edge);
    await tester.pumpAndSettle();
    expect(find.byType(TadbeerPauseSheet), findsNothing);
    expect(labelsShown(tester), isTrue);
  });

  testWidgets('a screen reader gets the plain sheet', (tester) async {
    await open(tester, screenReader: true);
    expect(find.byType(AyahActionSheet), findsOneWidget);
  });
}

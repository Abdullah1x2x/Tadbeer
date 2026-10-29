import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/onboarding/tour/scene_story.dart';
import 'package:tadbeer/features/onboarding/tour/section_guide.dart';
import 'package:tadbeer/features/onboarding/tour/tour_scenes.dart';
import 'package:tadbeer/features/onboarding/tour/tour_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_tour_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Steps the clock frame by frame; the scenes repeat, so nothing settles.
  Future<void> advance(WidgetTester tester, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Lets real file I/O (saving what was seen) finish.
  Future<void> io(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  Widget host(Widget child, {bool dark = false, bool lessMotion = false}) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 860),
          disableAnimations: lessMotion,
        ),
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: child,
        ),
      ),
    );
  }

  final scenes = <String, Widget Function(double)>{
    'mushaf': (t) => MushafScene(t: t),
    'mushaf centre': (t) => MushafScene(t: t, pickCenter: true),
    'reflect': (t) => ReflectScene(t: t),
    'reflect answer': (t) => ReflectScene(t: t, answer: true),
    'reflections list': (t) => ReflectionsListScene(t: t),
    'create link': (t) => CreateLinkScene(t: t),
    'add verses': (t) => AddVersesScene(t: t),
    'share network': (t) => ShareNetworkScene(t: t),
    'pathway days': (t) => PathwayDaysScene(t: t),
    'today ayah': (t) => TodayAyahScene(t: t),
    'listen': (t) => ListenScene(t: t),
    'journey': (t) => JourneyScene(t: t),
    'privacy': (t) => PrivacyScene(t: t),
  };

  for (final entry in scenes.entries) {
    testWidgets('${entry.key} scene draws through its whole story', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        for (final t in [0.0, 0.2, 0.45, 0.65, 0.85, 1.0]) {
          await tester.pumpWidget(
            host(
              Scaffold(body: Center(child: entry.value(t))),
              dark: dark,
            ),
          );
          expect(tester.takeException(), isNull, reason: 't=$t dark=$dark');
        }
      }
    });
  }

  testWidgets('the tour walks five pages and remembers it was seen', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(TourScreen(next: (_) => const Scaffold(body: Text('home')))),
    );
    await advance(tester);
    expect(find.text('مصحف المدينة بين يديك'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('التالي'));
      await advance(tester);
    }
    expect(find.text('كل شيء على جهازك'), findsOneWidget);
    await tester.tap(find.text('ابدأ رحلتك'));
    await io(tester);
    await advance(tester);
    expect(find.text('home'), findsOneWidget);
    expect(TourScreen.seen, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with less motion a scene shows its ending at once', (
    tester,
  ) async {
    late double seenT;
    await tester.pumpWidget(
      host(
        Scaffold(
          body: SceneStory(
            builder: (context, t) {
              seenT = t;
              return const SizedBox();
            },
          ),
        ),
        lessMotion: true,
      ),
    );
    expect(seenT, 1);
  });

  testWidgets('the links guide tells its story in three steps', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    SectionGuide.show(context, GuideTopic.ayahLinks);
    await io(tester);
    await advance(tester);
    expect(find.text('موضوع يجمع الآيات'), findsOneWidget);
    expect(find.text('الخطوة ١ من ٣'), findsOneWidget);
    expect(SectionGuide.seen(GuideTopic.ayahLinks), isTrue);
    await tester.tap(find.text('التالي'));
    await advance(tester);
    expect(find.text('الصبر عَونٌ تستعين به'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await advance(tester);
    await tester.tap(find.text('فهمت'));
    await advance(tester);
    expect(find.text('موضوع يجمع الآيات'), findsNothing);

    await tester.runAsync(SectionGuide.resetAll);
    expect(SectionGuide.seen(GuideTopic.ayahLinks), isFalse);
  });
}

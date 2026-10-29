import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/qibla/qibla.dart';
import 'package:tadbeer/features/qibla/qibla_location.dart';
import 'package:tadbeer/features/qibla/qibla_screen.dart';

/// A location source that answers at once with [fix].
class _FakeLocator extends QiblaLocator {
  final QiblaFix fix;
  final QiblaLocated? last;

  const _FakeLocator(this.fix, {this.last});

  @override
  QiblaLocated? saved() => last;

  @override
  Future<QiblaFix> locate() async => fix;
}

void main() {
  group('Qibla bearing', () {
    // Published Qibla directions, true north, to within half a degree.
    final cities = {
      'London': (51.5074, -0.1278, 118.99),
      'New York': (40.7128, -74.0060, 58.48),
      'Jakarta': (-6.2088, 106.8456, 295.15),
      'Cairo': (30.0444, 31.2357, 136.14),
      'Sanaa': (15.3694, 44.1910, 326.3),
    };
    for (final MapEntry(key: city, value: (lat, lon, expected))
        in cities.entries) {
      test(city, () {
        expect(qiblaBearing(lat, lon), closeTo(expected, 0.5));
      });
    }

    test('distance to Makkah', () {
      expect(distanceToKaabaKm(51.5074, -0.1278), closeTo(4790, 30));
      expect(distanceToKaabaKm(kaabaLatitude, kaabaLongitude), lessThan(0.01));
    });

    test('the turn takes the short way round', () {
      expect(turnTo(10, 350), 20);
      expect(turnTo(350, 10), -20);
      expect(turnTo(180, 0), -180);
    });
  });

  group('Qibla screen', () {
    late Directory tempDir;

    setUpAll(() async {
      final plex = FontLoader('IBMPlexSansArabic')
        ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
      await plex.load();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_qibla_');
      await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<void> pump(
      WidgetTester tester,
      QiblaLocator locator,
      Stream<double>? headings,
    ) async {
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
            home: QiblaScreen.withSources(locator: locator, headings: headings),
          ),
        ),
      );
      await tester.pump();
    }

    // Sanaa: the Qibla is about 326° from north.
    const sanaa = QiblaLocated(15.3694, 44.1910);

    testWidgets('says which way to turn, then that the reader faces it', (
      tester,
    ) async {
      final compass = StreamController<double>();
      addTearDown(compass.close);
      await pump(tester, const _FakeLocator(sanaa), compass.stream);
      expect(find.text('٣٢٦°'), findsOneWidget);

      compass.add(300);
      await tester.pump();
      expect(find.textContaining('استدر'), findsOneWidget);

      // The dial eases toward the heading; a few readings settle it.
      for (var i = 0; i < 20; i++) {
        compass.add(326);
        await tester.pump();
      }
      expect(find.text('أنت متجه إلى القبلة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a compass the dial stays north-up', (tester) async {
      await pump(tester, const _FakeLocator(sanaa), null);
      expect(find.textContaining('لا توجد بوصلة'), findsOneWidget);
      expect(find.text('٣٢٦°'), findsOneWidget);
    });

    testWidgets('asks for the location when it is refused', (tester) async {
      await pump(
        tester,
        const _FakeLocator(QiblaPermissionDenied(forever: false)),
        null,
      );
      expect(find.text('السماح بالموقع'), findsOneWidget);
      expect(find.textContaining('لا يُرسل'), findsOneWidget);
    });

    testWidgets('offers to turn on location when it is off', (tester) async {
      await pump(tester, const _FakeLocator(QiblaLocationOff()), null);
      expect(find.text('تشغيل الموقع'), findsOneWidget);
    });

    testWidgets('answers from the last location when a new one fails', (
      tester,
    ) async {
      await pump(
        tester,
        _FakeLocator(
          const QiblaLocationFailed(),
          last: const QiblaLocated(15.3694, 44.1910, saved: true),
        ),
        null,
      );
      expect(find.text('٣٢٦°'), findsOneWidget);
      expect(find.text('حسب آخر موقع معروف لك'), findsOneWidget);
    });
  });
}

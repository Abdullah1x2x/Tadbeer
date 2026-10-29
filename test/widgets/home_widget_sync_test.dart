import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/models/reading_journey.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/widgets/home_widget_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_widget_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('counts quarter hours from 2020 in local time', () {
    expect(HomeWidgetSync.quarterOf(DateTime(2020, 1, 1)), 0);
    expect(HomeWidgetSync.quarterOf(DateTime(2020, 1, 1, 0, 14)), 0);
    expect(HomeWidgetSync.quarterOf(DateTime(2020, 1, 1, 0, 15)), 1);
    expect(HomeWidgetSync.quarterOf(DateTime(2020, 1, 2, 23, 59)), 191);
  });

  test('stores an ayah for every quarter hour of the next two days', () {
    final now = DateTime(2026, 10, 26, 9, 20);
    final data = HomeWidgetSync.payload(UserDataStore.instance, now);
    final ayahs = (jsonDecode(data['ayahs'] as String) as List)
        .cast<Map<String, dynamic>>();
    expect(ayahs, hasLength(HomeWidgetSync.quarters));
    final first = HomeWidgetSync.quarterOf(now);
    expect(ayahs.first['q'], first);
    expect(ayahs.last['q'], first + HomeWidgetSync.quarters - 1);
    final next = HomeWidgetSync.ayahForQuarter(first + 1);
    expect(ayahs[1]['t'], next.text);
    expect(ayahs[1]['s'], next.surahNumber);
    // Neighbouring quarters show different ayahs.
    expect(ayahs[0]['t'], isNot(ayahs[1]['t']));
    expect(data['title'], 'آية للتدبّر');
    expect(data['theme'], 'navy');
    expect(data['has_khatma'], isFalse);
  });

  test('includes the khatma and today’s reading', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    final now = DateTime.now();
    await store.recordPageRead(1, now: now);
    final data = HomeWidgetSync.payload(store, now);
    expect(data['has_khatma'], isTrue);
    expect(data['portion'], 21);
    expect(data['read_today'], 1);
    expect(data['read_day'], dayKey(now));
    expect(data['khatma_progress'], 0); // 1 of 604 pages rounds to 0%
  });

  test('updating without a widget host does not throw', () async {
    await HomeWidgetSync.update();
  });
}

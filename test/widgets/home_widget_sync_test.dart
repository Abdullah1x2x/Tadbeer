import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/daily/ayah_of_day_card.dart';
import 'package:tadbeer/features/journey/reading_journey.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
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

  test('stores the coming month of ayahs, matching the app', () {
    final now = DateTime(2026, 10, 26, 9);
    final data = HomeWidgetSync.payload(UserDataStore.instance, now);
    final ayahs = (jsonDecode(data['ayahs'] as String) as List)
        .cast<Map<String, dynamic>>();
    expect(ayahs, hasLength(HomeWidgetSync.days));
    expect(ayahs.first['d'], '2026-10-26');
    expect(ayahs.last['d'], '2026-11-24');
    expect(ayahs[1]['t'], AyahOfTheDay.forDay(DateTime(2026, 10, 27)).text);
    expect(ayahs.first['r'], isNotEmpty);
    expect(data['title'], 'آية اليوم');
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

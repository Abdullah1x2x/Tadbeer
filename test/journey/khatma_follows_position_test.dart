import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_follow_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> moveTo(int page) => UserDataStore.instance.saveReadingPosition(
    page: page,
    surahNumber: QuranRepository.instance.getPage(page).ayahs.first.surahNumber,
    ayahNumber: QuranRepository.instance.getPage(page).ayahs.first.ayahNumber,
  );

  test('the khatma is where the reader is', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    expect(store.journey.plan!.currentPage, 1);

    await moveTo(300);
    expect(store.journey.plan!.currentPage, 300);
    // Progress by position, like a bookmark: everything before it is done.
    expect(store.journey.plan!.advanced, 299);
  });

  test('reading on page by page advances it one page at a time', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    await store.recordPageRead(1);
    await moveTo(2);
    expect(store.journey.plan!.currentPage, 2);
    expect(store.journey.plan!.advanced, 1);
  });

  test('reading the last page completes the khatma', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    await moveTo(604);
    expect(store.journey.plan!.advanced, 603);
    await store.recordPageRead(604);
    expect(store.journey.plan, isNull);
    expect(store.journey.completedKhatmas, 1);
  });

  test('saving the page just read keeps the khatma ahead of it', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    await store.recordPageRead(1);
    await moveTo(1);
    expect(store.journey.plan!.currentPage, 2);
    expect(store.journey.plan!.advanced, 1);
  });

  test('starting a khatma from a page brings the reader there', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30, startPage: 100);
    expect(store.readingPosition.page, 100);
    expect(store.journey.plan!.advanced, 0);
  });
}

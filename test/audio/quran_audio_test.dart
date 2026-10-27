import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/audio/audio_bar.dart';
import 'package:tadbeer/features/audio/quran_audio.dart';
import 'package:tadbeer/features/audio/reciters.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

/// A player that records what it is asked and plays nothing.
class _FakeEngine implements AudioEngine {
  final indexes = StreamController<int?>.broadcast(sync: true);
  final playingStates = StreamController<bool>.broadcast(sync: true);
  final loadings = StreamController<bool>.broadcast(sync: true);
  final completions = StreamController<void>.broadcast(sync: true);
  final failures = StreamController<Object>.broadcast(sync: true);

  final calls = <String>[];
  List<Uri> loaded = const [];
  bool failLoad = false;

  @override
  Stream<int?> get index => indexes.stream;
  @override
  Stream<bool> get playing => playingStates.stream;
  @override
  Stream<bool> get loading => loadings.stream;
  @override
  Stream<void> get completed => completions.stream;
  @override
  Stream<Object> get errors => failures.stream;

  @override
  Future<void> load(List<Uri> urls, {int start = 0}) async {
    calls.add('load');
    if (failLoad) throw Exception('offline');
    loaded = urls;
    indexes.add(start);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    playingStates.add(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playingStates.add(false);
  }

  @override
  Future<void> seekTo(int index) async {
    calls.add('seek $index');
    indexes.add(index);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    playingStates.add(false);
  }
}

void main() {
  late Directory tempDir;
  final repo = QuranRepository.instance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_audio_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await repo.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('AudioQueue', () {
    final husary = reciterById('ar.husary');

    test('names each ayah by its number in the Mushaf', () {
      expect(
        husary.urlFor(262).toString(),
        'https://cdn.islamic.network/quran/audio/128/ar.husary/262.mp3',
      );
      expect(reciterById('nobody').id, reciters.first.id);
      expect(reciterById('ar.parhizgar').lowQuality, isTrue);
      expect(reciters.where((r) => r.lowQuality), hasLength(1));
    });

    test('a surah begun from its start opens with the basmala', () {
      final baqarah = repo.getSurah(2);
      final queue = AudioQueue.from(repo.getAyah(2, 1)!, husary);
      expect(queue.urls, hasLength(baqarah.ayahCount + 1));
      expect(queue.urls.first, husary.urlFor(1));
      expect(queue.urls[1], husary.urlFor(repo.getAyah(2, 1)!.id));
      // The basmala carries the ayah it opens.
      expect(queue.ayahs.first.ayahNumber, 1);
    });

    test('al-Fatiha, at-Tawbah and a mid-surah start add no basmala', () {
      expect(AudioQueue.from(repo.getAyah(1, 1)!, husary).urls, hasLength(7));
      expect(
        AudioQueue.from(repo.getAyah(9, 1)!, husary).urls,
        hasLength(repo.getSurah(9).ayahCount),
      );
      final kursi = repo.getAyah(2, 255)!;
      final queue = AudioQueue.from(kursi, husary);
      expect(queue.urls.first, husary.urlFor(kursi.id));
      expect(queue.ayahs.last.ayahNumber, 286);
    });

    test('repeats each ayah in place', () {
      final queue = AudioQueue.from(repo.getAyah(112, 1)!, husary, repeat: 3);
      // Basmala, then each of the four ayahs three times.
      expect(queue.urls, hasLength(1 + 4 * 3));
      expect(queue.startOf(repo.getAyah(112, 2)!), 4);
    });
  });

  group('QuranAudio', () {
    test('plays from an ayah and follows the queue', () async {
      final engine = _FakeEngine();
      final audio = QuranAudio.withEngine(engine);
      await audio.playFrom(repo.getAyah(2, 255)!);
      expect(engine.calls, ['load', 'play']);
      expect(audio.current!.ayahNumber, 255);
      expect(audio.playing, isTrue);

      engine.indexes.add(1);
      expect(audio.current!.ayahNumber, 256);

      await audio.next();
      expect(audio.current!.ayahNumber, 257);
      await audio.previous();
      expect(audio.current!.ayahNumber, 256);

      await audio.toggle();
      expect(audio.playing, isFalse);
      await audio.stop();
      expect(audio.active, isFalse);
    });

    test('pauses to reflect after each ayah, then goes on', () {
      fakeAsync((async) {
        final engine = _FakeEngine();
        final audio = QuranAudio.withEngine(engine);
        audio.setPauseSeconds(5);
        async.flushMicrotasks();
        audio.playFrom(repo.getAyah(112, 2)!);
        async.flushMicrotasks();
        engine.calls.clear();

        engine.indexes.add(1);
        expect(engine.calls, ['pause']);
        expect(audio.resting, isTrue);
        async.elapse(const Duration(seconds: 4));
        expect(engine.calls, ['pause']);
        async.elapse(const Duration(seconds: 1));
        expect(engine.calls, ['pause', 'play']);
        expect(audio.resting, isFalse);
      });
    });

    test('a repeated ayah does not pause between its readings', () {
      fakeAsync((async) {
        final engine = _FakeEngine();
        final audio = QuranAudio.withEngine(engine);
        audio.setPauseSeconds(5);
        audio.setRepeat(2);
        async.flushMicrotasks();
        audio.playFrom(repo.getAyah(112, 2)!);
        async.flushMicrotasks();
        engine.calls.clear();
        engine.indexes.add(1); // The same ayah's second reading.
        expect(engine.calls, isEmpty);
        engine.indexes.add(2); // The next ayah.
        expect(engine.calls, ['pause']);
      });
    });

    test('goes on to the next surah at the end of one', () async {
      final engine = _FakeEngine();
      final audio = QuranAudio.withEngine(engine);
      await audio.playFrom(repo.getAyah(112, 4)!);
      engine.completions.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(audio.current!.surahNumber, 113);
      // Al-Falaq opens with the basmala.
      expect(engine.loaded.first, audio.reciter.urlFor(1));
    });

    test('says so when the recitation cannot be fetched', () async {
      final engine = _FakeEngine()..failLoad = true;
      final audio = QuranAudio.withEngine(engine);
      await audio.playFrom(repo.getAyah(1, 1)!);
      expect(audio.failed, isTrue);
      expect(audio.active, isFalse);
    });

    test('remembers the reciter and replays the ayah in their voice', () async {
      final engine = _FakeEngine();
      final audio = QuranAudio.withEngine(engine);
      await audio.playFrom(repo.getAyah(1, 2)!);
      await audio.setReciter(reciterById('ar.minshawi'));
      expect(audio.reciter.id, 'ar.minshawi');
      expect(engine.loaded.first.path, contains('ar.minshawi'));
      expect(QuranAudio.withEngine(_FakeEngine()).reciter.id, 'ar.minshawi');
    });
  });

  testWidgets('the bar names the ayah and controls the recitation', (
    tester,
  ) async {
    final engine = _FakeEngine();
    final audio = QuranAudio.withEngine(engine);
    final previous = QuranAudio.instance;
    QuranAudio.instance = audio;
    addTearDown(() => QuranAudio.instance = previous);

    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Center(child: AudioBar())),
        ),
      ),
    );
    expect(find.byType(IconButton), findsNothing);

    await tester.runAsync(() => audio.playFrom(repo.getAyah(2, 255)!));
    await tester.pump();
    expect(find.text('سورة البقرة · الآية ٢٥٥'), findsOneWidget);
    expect(find.text('محمود خليل الحصري'), findsOneWidget);

    await tester.tap(find.byTooltip('الآية التالية'));
    await tester.pump();
    expect(find.text('سورة البقرة · الآية ٢٥٦'), findsOneWidget);

    await tester.tap(find.byTooltip('إيقاف التلاوة'));
    await tester.pump();
    expect(find.byType(IconButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

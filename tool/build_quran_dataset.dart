// ignore_for_file: avoid_print, use_null_aware_elements
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

void main() {
  print('Building Quran dataset...');
  final xmlFile = File('assets/quran/quran-data.xml');
  final txtFile = File('assets/quran/quran-uthmani.txt');

  if (!xmlFile.existsSync() || !txtFile.existsSync()) {
    print('Error: files not found');
    exit(1);
  }

  final xmlDoc = XmlDocument.parse(xmlFile.readAsStringSync());
  final allLines = txtFile.readAsLinesSync();

  // The first 6236 non-empty lines before the copyright notice are the ayahs
  final ayahLines = <String>[];
  for (final line in allLines) {
    if (line.trim().startsWith('#')) break;
    if (line.trim().isNotEmpty) {
      ayahLines.add(line.trim());
    }
  }

  print('Found ${ayahLines.length} Quran ayah lines (expected: 6236)');
  assert(ayahLines.length == 6236, 'Expected exactly 6236 ayahs');

  // Parse Surahs
  final surasElement = xmlDoc.findAllElements('sura');
  final surahList = <Map<String, dynamic>>[];
  for (final s in surasElement) {
    surahList.add({
      'number': int.parse(s.getAttribute('index')!),
      'name': _nameFixes[s.getAttribute('name')] ?? s.getAttribute('name')!,
      'transliteration': s.getAttribute('tname')!,
      'translation': s.getAttribute('ename')!,
      'type': s.getAttribute('type')!,
      'ayahCount': int.parse(s.getAttribute('ayas')!),
      'order': int.parse(s.getAttribute('order')!),
      'rukus': int.parse(s.getAttribute('rukus')!),
      'pageStart': 0,
      'pageEnd': 0,
    });
  }
  print('Parsed ${surahList.length} surahs');
  assert(surahList.length == 114, 'Expected exactly 114 surahs');

  // Parse Pages
  final pageElements = xmlDoc.findAllElements('page');
  final pageStarts = <Map<String, int>>[];
  for (final p in pageElements) {
    pageStarts.add({
      'page': int.parse(p.getAttribute('index')!),
      'sura': int.parse(p.getAttribute('sura')!),
      'aya': int.parse(p.getAttribute('aya')!),
    });
  }
  print('Parsed ${pageStarts.length} page markers (expected: 604)');
  assert(pageStarts.length == 604, 'Expected exactly 604 pages');

  // Parse Juzs
  final juzElements = xmlDoc.findAllElements('juz');
  final juzStarts = <Map<String, int>>[];
  for (final j in juzElements) {
    juzStarts.add({
      'juz': int.parse(j.getAttribute('index')!),
      'sura': int.parse(j.getAttribute('sura')!),
      'aya': int.parse(j.getAttribute('aya')!),
    });
  }
  print('Parsed ${juzStarts.length} juz markers (expected: 30)');
  assert(juzStarts.length == 30, 'Expected exactly 30 juzs');

  // Parse Quarters (rub el hizb)
  final quarterElements = xmlDoc.findAllElements('quarter');
  final quarterStarts = <Map<String, int>>[];
  for (final q in quarterElements) {
    quarterStarts.add({
      'quarter': int.parse(q.getAttribute('index')!),
      'sura': int.parse(q.getAttribute('sura')!),
      'aya': int.parse(q.getAttribute('aya')!),
    });
  }
  print('Parsed ${quarterStarts.length} quarter markers (expected: 240)');
  assert(quarterStarts.length == 240, 'Expected exactly 240 quarters');

  // Parse Sajdas
  final sajdaElements = xmlDoc.findAllElements('sajda');
  final sajdas = <Map<String, dynamic>>[];
  final sajdaMap = <String, String>{};
  for (final s in sajdaElements) {
    final sura = int.parse(s.getAttribute('sura')!);
    final aya = int.parse(s.getAttribute('aya')!);
    final type = s.getAttribute('type') ?? 'recommended';
    sajdas.add({
      'index': int.parse(s.getAttribute('index')!),
      'surahNumber': sura,
      'ayahNumber': aya,
      'type': type,
    });
    sajdaMap['$sura:$aya'] = type;
  }
  print('Parsed ${sajdas.length} sajda locations');

  // Fast page lookup: find page for given sura and aya
  int findPage(int sura, int aya) {
    for (int i = pageStarts.length - 1; i >= 0; i--) {
      final p = pageStarts[i];
      if (sura > p['sura']! || (sura == p['sura']! && aya >= p['aya']!)) {
        return p['page']!;
      }
    }
    return 1;
  }

  // Fast juz lookup
  int findJuz(int sura, int aya) {
    for (int i = juzStarts.length - 1; i >= 0; i--) {
      final j = juzStarts[i];
      if (sura > j['sura']! || (sura == j['sura']! && aya >= j['aya']!)) {
        return j['juz']!;
      }
    }
    return 1;
  }

  // Fast quarter and hizb lookup
  int findQuarter(int sura, int aya) {
    for (int i = quarterStarts.length - 1; i >= 0; i--) {
      final q = quarterStarts[i];
      if (sura > q['sura']! || (sura == q['sura']! && aya >= q['aya']!)) {
        return q['quarter']!;
      }
    }
    return 1;
  }

  // Bismillah prefix in Tanzil text for verse 1 of surahs (except 1 and 9)
  const bismillahPrefix = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';

  int globalAyahIndex = 0;
  final allAyahs = <Map<String, dynamic>>[];
  final pagesMap = <int, List<Map<String, dynamic>>>{};
  for (int p = 1; p <= 604; p++) {
    pagesMap[p] = [];
  }

  for (final surah in surahList) {
    final sNum = surah['number'] as int;
    final aCount = surah['ayahCount'] as int;
    int firstPage = 0;
    int lastPage = 0;

    for (int aNum = 1; aNum <= aCount; aNum++) {
      globalAyahIndex++;
      final rawText = ayahLines[globalAyahIndex - 1];
      String cleanText = rawText;

      // In Tanzil, verse 1 has Bismillah prepended for surah != 1 and != 9
      if (sNum != 1 && sNum != 9 && aNum == 1) {
        if (cleanText.startsWith(bismillahPrefix)) {
          cleanText = cleanText.substring(bismillahPrefix.length);
        }
      }

      final page = findPage(sNum, aNum);
      final juz = findJuz(sNum, aNum);
      final quarter = findQuarter(sNum, aNum);
      final hizb = ((quarter - 1) ~/ 4) + 1;
      final isSajdah = sajdaMap.containsKey('$sNum:$aNum');
      final sajdaType = sajdaMap['$sNum:$aNum'];

      if (aNum == 1) firstPage = page;
      if (aNum == aCount) lastPage = page;

      final ayahObj = {
        'id': globalAyahIndex,
        'surahNumber': sNum,
        'ayahNumber': aNum,
        'text': cleanText,
        'rawText': rawText,
        'page': page,
        'juz': juz,
        'hizb': hizb,
        'quarter': quarter,
        'isSajdah': isSajdah,
        if (sajdaType != null) 'sajdaType': sajdaType,
      };

      allAyahs.add(ayahObj);
      pagesMap[page]!.add(ayahObj);
    }

    surah['pageStart'] = firstPage;
    surah['pageEnd'] = lastPage;
  }

  assert(globalAyahIndex == 6236, 'Must have processed all 6236 ayahs');

  // Build Pages List (1 to 604)
  final pagesList = <Map<String, dynamic>>[];
  for (int p = 1; p <= 604; p++) {
    final ayahsOnPage = pagesMap[p]!;
    final surahsOnPage = ayahsOnPage
        .map((a) => a['surahNumber'] as int)
        .toSet()
        .toList();
    final juzOnPage = ayahsOnPage.isNotEmpty
        ? ayahsOnPage.first['juz'] as int
        : 1;
    final hizbOnPage = ayahsOnPage.isNotEmpty
        ? ayahsOnPage.first['hizb'] as int
        : 1;

    pagesList.add({
      'pageNumber': p,
      'juzNumber': juzOnPage,
      'hizbNumber': hizbOnPage,
      'surahNumbers': surahsOnPage,
      'ayahs': ayahsOnPage,
    });
  }

  final finalData = {
    'version': '1.1',
    'source': 'Tanzil Project (tanzil.net)',
    'license': 'Creative Commons Attribution 3.0',
    'surahs': surahList,
    'pages': pagesList,
    'sajdas': sajdas,
  };

  final outFile = File('assets/quran/quran_data.json');
  outFile.writeAsStringSync(jsonEncode(finalData));
  print(
    'Successfully wrote assets/quran/quran_data.json (${(outFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB)',
  );
}

/// أسماء في بيانات تنزيل بلا همزة أو برسم المصحف، تُكتب بالإملاء المعتاد.
const _nameFixes = {
  'ابراهيم': 'إبراهيم',
  'سبإ': 'سبأ',
  'الانسان': 'الإنسان',
  'النبإ': 'النبأ',
  'الإنفطار': 'الانفطار',
  'الإنشقاق': 'الانشقاق',
};

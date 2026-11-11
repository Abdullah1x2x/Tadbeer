/// مدّ أسطر المصحف بالكشيدة بدل توسيع الفراغات وحدها.
///
/// خط Digital Khatt لا يمدّ حروفه بنفسه في محرك Flutter، فيُدخل حرف التطويل
/// بين حرفين متصلين حيث يجوز، ويوزّع على أطول الكلمات أولاً.
library;

/// حرف التطويل.
const tatweel = 'ـ';

/// الحروف التي تتصل بما بعدها.
final _joinsNext = RegExp(
  '[بت-خس-غـ-هىيئ'
  'ٮٯڡی]',
);

/// الحروف العربية، دون الهمزة المنفردة: لا يتصل بها ما قبلها.
final _letter = RegExp('[آ-يٮ-ۓ]');

/// علامات التشكيل والضبط، ومنها فاصل الحروف (U+034F) في نص Digital Khatt.
bool _isMark(int c) =>
    c == 0x034F ||
    (c >= 0x064B && c <= 0x065F) ||
    c == 0x0670 ||
    (c >= 0x06D6 && c <= 0x06ED) ||
    (c >= 0x08F0 && c <= 0x08FF);

/// مواضع الكشيدة الجائزة في [word]، الأقرب إلى آخرها أولاً.
///
/// الموضع بعد حرف يتصل بما بعده وتشكيله، وقبل حرف آخر. لا كشيدة في لفظ
/// الجلالة، ولا بين اللام والألف (لا)، ولا قبل حرف عليه ألف خنجرية أو مدّة،
/// ولا بعد حرف عليه ألف خنجرية: تنفصل عنه.
List<int> kashidaSpots(String word) {
  final chars = word.runes.toList();
  // ترتيب الشدة والفتحة يختلف بين المصادر، فيُفحص لفظ الجلالة دون تشكيل.
  final bare = String.fromCharCodes(chars.where((c) => !_isMark(c)));
  if (bare.contains('لله')) return const [];
  final offsets = <int>[];
  var offset = 0;
  for (final c in chars) {
    offsets.add(offset);
    offset += String.fromCharCode(c).length;
  }
  bool carriesAlef(int from) {
    for (var k = from; k < chars.length && _isMark(chars[k]); k++) {
      if (chars[k] == 0x0670 || chars[k] == 0x0653) return true;
    }
    return false;
  }

  final spots = <int>[];
  for (var i = 0; i < chars.length; i++) {
    if (!_joinsNext.hasMatch(String.fromCharCode(chars[i]))) continue;
    if (carriesAlef(i + 1)) continue;
    var j = i + 1;
    while (j < chars.length && _isMark(chars[j])) {
      j++;
    }
    if (j >= chars.length) continue;
    final next = String.fromCharCode(chars[j]);
    if (!_letter.hasMatch(next)) continue;
    if (chars[i] == 0x0644 && 'اأإآٱ'.contains(next)) continue;
    if (carriesAlef(j + 1)) continue;
    spots.add(offsets[j]);
  }
  return spots.reversed.toList();
}

/// [words] بعد إدخال [count] كشيدة: جولة على أطول الكلمات أولاً، بحد [perWord]
/// لكل كلمة، في أقرب موضع جائز إلى آخرها.
List<String> stretchWords(List<String> words, int count, {int perWord = 3}) {
  final spots = [for (final w in words) kashidaSpots(w)];
  final added = List.filled(words.length, 0);
  final order = [
    for (var i = 0; i < words.length; i++)
      if (spots[i].isNotEmpty) i,
  ]..sort((a, b) => words[b].length.compareTo(words[a].length));
  var left = count;
  for (
    var round = 0;
    round < perWord && left > 0 && order.isNotEmpty;
    round++
  ) {
    for (final i in order) {
      if (left == 0) break;
      added[i]++;
      left--;
    }
  }
  return [
    for (var i = 0; i < words.length; i++)
      added[i] == 0
          ? words[i]
          : words[i].substring(0, spots[i].first) +
                tatweel * added[i] +
                words[i].substring(spots[i].first),
  ];
}

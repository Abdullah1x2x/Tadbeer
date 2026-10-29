import '../../core/utils/arabic_search_normalizer.dart';
import '../duas/data/quran_duas_repository.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/models/tadbeer_model.dart';

/// نوع الآية كما تراه وقفة التدبر، لتبديل سؤال واحد يناسبها.
enum AyahKind {
  /// كل آية لا تدخل في نوع مما يلي.
  general,

  /// دعاء: يبدأ بـ«ربنا» أو «رب»، أو من أدعية القرآن في التطبيق.
  dua,

  /// ذكر الجنة أو الأجر، أو النار أو العذاب.
  promise,

  /// قصة أو حوار: فيها «قال» وأخواتها.
  story,
}

/// أسئلة وقفة التدبر لآية بعينها.
///
/// Every ayah gets the four general questions; a dua, a story or a
/// promise/warning swaps a single one for a question closer to it. The
/// check is a light one by words, so a wrong guess still asks a fair
/// question.
abstract final class TadbeerQuestions {
  static String _n(String s) => ArabicSearchNormalizer.normalize(s);

  static final String _basmala = _n('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');

  static final Set<String> _storyWords = {
    for (final w in const [
      'قال',
      'قالوا',
      'قالت',
      'قالا',
      'وقال',
      'وقالوا',
      'وقالت',
      'فقال',
      'فقالوا',
      'فقالت',
      'قيل',
      'وقيل',
    ])
      _n(w),
  };

  static final Set<String> _promiseWords = {
    for (final w in const [
      'الجنة',
      'جنة',
      'جنات',
      'وجنة',
      'وجنات',
      'أجر',
      'أجرا',
      'أجرهم',
      'أجره',
      'أجركم',
      'النار',
      'بالنار',
      'جهنم',
      'وجهنم',
      'عذاب',
      'عذابا',
      'العذاب',
      'بعذاب',
    ])
      _n(w),
  };

  static Set<String>? _duaKeys;

  /// Every ayah of the Quranic duas the app lists, as `surah:ayah`.
  static Set<String> get _duas => _duaKeys ??= {
    for (final d in QuranDuasRepository.instance.getDuas(
      quranRepository: QuranRepository.instance,
    ))
      for (var a = d.ayahNumber; a <= d.ayahEndNumber; a++)
        '${d.surahNumber}:$a',
  };

  /// نوع الآية.
  static AyahKind kindOf(Ayah ayah) {
    var text = _n(ayah.text);
    if (text.startsWith(_basmala)) {
      text = text.substring(_basmala.length).trim();
    }
    final words = text.split(RegExp(r'\s+'));
    if (_duas.contains('${ayah.surahNumber}:${ayah.ayahNumber}') ||
        words.first == 'ربنا' ||
        words.first == 'رب') {
      return AyahKind.dua;
    }
    if (words.any(_promiseWords.contains)) return AyahKind.promise;
    if (words.any(_storyWords.contains)) return AyahKind.story;
    return AyahKind.general;
  }

  /// الأسئلة الأربعة لهذه الآية، بترتيب [TadbeerItem.questionKeys].
  static List<String> forAyah(Ayah? ayah) {
    final q = [...TadbeerItem.questions];
    switch (ayah == null ? AyahKind.general : kindOf(ayah)) {
      case AyahKind.dua:
        q[1] = 'ما الذي تحتاجه أنت من هذا الدعاء؟';
      case AyahKind.story:
        q[1] = 'ما الذي يشبه حالك في هذا الموقف؟';
      case AyahKind.promise:
        q[2] = 'أين أنت من هذه الآية؟';
      case AyahKind.general:
        break;
    }
    return q;
  }
}

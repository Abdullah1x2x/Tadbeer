import '../../core/utils/arabic_search_normalizer.dart';
import '../duas/data/quran_duas_repository.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/models/tadbeer_model.dart';

/// نوع الآية كما تراه وقفة التدبر، ليُبدّل سؤال واحد بما يناسبها.
enum AyahKind {
  /// كل آية لا تدخل في الأنواع التالية.
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
/// كل آية تأخذ الأسئلة الأربعة العامة، والدعاء والقصة والوعد والوعيد تبدّل
/// سؤالاً واحداً بأقرب منه. الفحص خفيف بالكلمات، فإن أخطأ بقي السؤال عادلاً.
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

  /// آيات أدعية القرآن في التطبيق، بصيغة `سورة:آية`.
  static Set<String> get _duas {
    if (_duaKeys != null) return _duaKeys!;
    if (!QuranRepository.instance.isLoaded) return const {};
    return _duaKeys = {
      for (final d in QuranDuasRepository.instance.getDuas(
        quranRepository: QuranRepository.instance,
      ))
        for (var a = d.ayahNumber; a <= d.ayahEndNumber; a++)
          '${d.surahNumber}:$a',
    };
  }

  static AyahKind kindOf(Ayah ayah) {
    var text = _n(ayah.text);
    if (text.startsWith(_basmala)) {
      text = text.substring(_basmala.length).trim();
    }
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (_duas.contains('${ayah.surahNumber}:${ayah.ayahNumber}') ||
        (words.isNotEmpty && (words.first == 'ربنا' || words.first == 'رب'))) {
      return AyahKind.dua;
    }
    if (words.any(_promiseWords.contains)) return AyahKind.promise;
    if (words.any(_storyWords.contains)) return AyahKind.story;
    return AyahKind.general;
  }

  /// الأسئلة الأربعة لهذه الآية، بترتيب [TadbeerItem.questionKeys].
  static List<String> forAyah(Ayah? ayah, {bool isArabic = true}) {
    final q = [...TadbeerItem.questionsFor(isArabic: isArabic)];
    switch (ayah == null ? AyahKind.general : kindOf(ayah)) {
      case AyahKind.dua:
        q[1] = isArabic
            ? 'ما الذي تحتاجه أنت من هذا الدعاء؟'
            : 'What do you need most from this supplication?';
      case AyahKind.story:
        q[1] = isArabic
            ? 'ما الذي يشبه حالك في هذا الموقف؟'
            : 'What in this scene resembles your situation?';
      case AyahKind.promise:
        q[2] = isArabic
            ? 'أين أنت من هذه الآية؟'
            : 'Where do you stand in relation to this ayah?';
      case AyahKind.general:
        break;
    }
    return q;
  }
}

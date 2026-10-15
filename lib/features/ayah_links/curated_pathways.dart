import '../../features/quran/data/quran_repository.dart';
import 'ayah_link_model.dart';
import 'ayah_link_repository.dart';

/// نموذج يمثل آية قرآنية واحدة وملاحظتها التدبرية ضمن مسار تدبري مقترح.
class CuratedPathwayVerse {
  /// رقم السورة.
  final int surah;

  /// رقم الآية داخل السورة.
  final int ayah;

  /// الملاحظة التدبرية المرفقة بالآية.
  final String note;

  /// ينشئ عنصر آية ضمن مسار تدبري مقترح.
  const CuratedPathwayVerse({
    required this.surah,
    required this.ayah,
    required this.note,
  });
}

/// نموذج يمثل مساراً تدبرياً مقترحاً يجمع آيات مترابطة حول موضوع واحد.
class CuratedPathway {
  /// المعرّف الفريد للمسار التدبري.
  final String id;

  /// عنوان المسار التدبري.
  final String title;

  /// وصف موجز لموضوع المسار التدبري.
  final String description;

  /// التصنيف الموضوعي للمسار.
  final String category;

  /// قائمة الآيات المرتبطة ضمن هذا المسار.
  final List<CuratedPathwayVerse> verses;

  /// ينشئ مساراً تدبرياً مقترحاً.
  const CuratedPathway({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.verses,
  });
}

/// مكتبة المسارات التدبرية المقترحة المعتمدة في تطبيق تَدْبِير.
class CuratedPathwaysRegistry {
  CuratedPathwaysRegistry._();

  // ===========================================================================
  // 💡 كيف تضيف مساراً تدبرياً جديداً يربط بين الآيات؟
  // -------------------------------------------------------------
  // أضف عنصراً جديداً إلى قائمة [pathways] أدناه باستخدام [CuratedPathway]:
  // - حدد عنوان المسار ووصفه وتصنيفه الموضوعي.
  // - أضف الآيات المترابطة مع ملاحظاتها التدبرية عبر [CuratedPathwayVerse].
  // يظهر المسار تلقائياً في شاشة روابط الآيات ويمكن للمستخدمين استعراضه واستيراده.
  // ===========================================================================

  /// قائمة المسارات التدبرية المقترحة الجاهزة للاستيراد.
  static const List<CuratedPathway> pathways = [
    CuratedPathway(
      id: 'names_of_allah',
      title: 'أسماء الله الحسنى وجلال الصفات',
      description: 'آيات جامعة في التعرف على الخالق سبحانه بأسمائه الحسنى وصفاته العلى وأثرها في يقين القلب.',
      category: 'العقيدة والإيمان',
      verses: [
        CuratedPathwayVerse(
          surah: 2,
          ayah: 255,
          note: 'آية الكرسي: أعظم آية في كتاب الله؛ قيوميته وحياته التي لا يعتريها سنة ولا نوم.',
        ),
        CuratedPathwayVerse(
          surah: 59,
          ayah: 22,
          note: 'عالم الغيب والشهادة، الرحمن الرحيم المستحق للعبادة وحده.',
        ),
        CuratedPathwayVerse(
          surah: 59,
          ayah: 23,
          note: 'الملك القدوس السلام المؤمن المهيمن العزيز الجبار المتكبر.',
        ),
        CuratedPathwayVerse(
          surah: 59,
          ayah: 24,
          note: 'الخالق البارئ المصور، له الأسماء الحسنى يسبح له ما في السماوات والأرض.',
        ),
        CuratedPathwayVerse(
          surah: 112,
          ayah: 1,
          note: 'سورة الإخلاص: صفة الرحمن وتوحيده الخالص الأحد الصمد.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'prophetic_duas',
      title: 'أدعية الأنبياء في الشدائد والملمات',
      description: 'مناجاة الأنبياء لربهم عند انقطاع الأسباب واشتداد الكرب وحسن ظنهم برحمة الله.',
      category: 'الدعاء والمناجاة',
      verses: [
        CuratedPathwayVerse(
          surah: 21,
          ayah: 87,
          note: 'دعاء ذي النون في الظلمات: التوحيد والتنزيه والاعتراف بالتقصير مفتاح كل فرج.',
        ),
        CuratedPathwayVerse(
          surah: 21,
          ayah: 83,
          note: 'دعاء أيوب عليه السلام: قمة الأدب في عرض الضر وتفويض الأمر لأرحم الراحمين.',
        ),
        CuratedPathwayVerse(
          surah: 21,
          ayah: 89,
          note: 'دعاء زكريا عليه السلام: اليقين بأن الله خير الوارثين مع انقطاع أسباب الولد.',
        ),
        CuratedPathwayVerse(
          surah: 20,
          ayah: 25,
          note: 'دعاء موسى عليه السلام: شرح الصدر وتيسير الأمر تمهيداً لأعظم رسالة.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'inner_change',
      title: 'سنن التغيير النفسي والإيماني',
      description: 'القوانين القرآنية المطردة في إصلاح النفوس وتهذيب السلوك وشروط التمكين الداخلي.',
      category: 'التزكية والإصلاح',
      verses: [
        CuratedPathwayVerse(
          surah: 13,
          ayah: 11,
          note: 'قانون التغيير الإلهي: البداية تبدأ من مكنونات النفس لتتغير معها أحوال الحياة.',
        ),
        CuratedPathwayVerse(
          surah: 29,
          ayah: 69,
          note: 'معية الهداية مشروطة بصدق المجاهدة وبذل الجهد الخالص.',
        ),
        CuratedPathwayVerse(
          surah: 91,
          ayah: 9,
          note: 'الفلاح المطلق منوط بتزكية النفس وطهارتها من دنس الهوى.',
        ),
        CuratedPathwayVerse(
          surah: 8,
          ayah: 53,
          note: 'حفظ النعم الإلهية مرتهن بالاستقامة والشكر وعدم تبديل الطاعة بالمعصية.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'patience_and_certainty',
      title: 'الصبر واليقين وبشارات الصابرين',
      description: 'معارج الصبر على المكاره واليقين بوعد الله وجزاء الثابتين على الحق.',
      category: 'التربية الإيمانية',
      verses: [
        CuratedPathwayVerse(
          surah: 2,
          ayah: 155,
          note: 'حتمية الابتلاء في الدنيا، وبشارة الله العظمى لمن ثبت واحتسب.',
        ),
        CuratedPathwayVerse(
          surah: 2,
          ayah: 156,
          note: 'استرجاع الصابرين: التسليم المطلق لمالك الأنفس والمصير.',
        ),
        CuratedPathwayVerse(
          surah: 39,
          ayah: 10,
          note: 'جزاء الصابرين بغير حساب: عطاء إلهي يفيض بلا ميزان ولا حد.',
        ),
        CuratedPathwayVerse(
          surah: 11,
          ayah: 115,
          note: 'اقتران الصبر بالإحسان؛ فإن الله لا يضيع أجر المحسنين.',
        ),
      ],
    ),
  ];

  /// يستورد مساراً تدبرياً مقترحاً إلى قائمة روابط الآيات الخاصة بالمستخدم.
  static Future<AyahLinkItem> importPathway(
    CuratedPathway pathway, {
    AyahLinkRepository? repo,
  }) async {
    final linkRepo = repo ?? AyahLinkRepository();
    final quranRepo = QuranRepository.instance;

    final created = await linkRepo.createLink(
      title: pathway.title,
      description: pathway.description,
    );

    for (final v in pathway.verses) {
      final ayah = quranRepo.getAyah(v.surah, v.ayah);
      if (ayah != null) {
        await linkRepo.addVerseToLink(
          created.id,
          ayahId: ayah.id,
          surahNumber: v.surah,
          ayahNumber: v.ayah,
          page: ayah.page,
          note: v.note,
        );
      }
    }

    return linkRepo.getLink(created.id) ?? created;
  }
}

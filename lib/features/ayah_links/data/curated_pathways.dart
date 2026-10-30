import '../../../data/quran/quran_repository.dart';
import '../../../data/models/ayah_link_model.dart';
import 'ayah_link_repository.dart';

/// آية في مسار مقترح، مع فائدتها التدبرية.
class CuratedPathwayVerse {
  final int surah;

  final int ayah;

  /// الفائدة التدبرية.
  final String note;

  const CuratedPathwayVerse({
    required this.surah,
    required this.ayah,
    required this.note,
  });
}

/// مسار تدبري مقترح: آيات مترابطة حول موضوع واحد.
class CuratedPathway {
  final String id;

  final String title;

  final String description;

  /// التصنيف الموضوعي.
  final String category;

  final List<CuratedPathwayVerse> verses;

  const CuratedPathway({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.verses,
  });
}

/// المسارات التدبرية المقترحة.
class CuratedPathwaysRegistry {
  CuratedPathwaysRegistry._();

  // لإضافة مسار أضف [CuratedPathway] إلى [pathways]: العنوان والوصف والتصنيف،
  // والآيات بفوائدها عبر [CuratedPathwayVerse]. يظهر المسار في روابط الآيات
  // ويمكن استيراده.

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
      description:
          'معارج الصبر على المكاره واليقين بوعد الله وجزاء الثابتين على الحق.',
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
    CuratedPathway(
      id: 'doors_of_provision',
      title: 'أبواب الرزق',
      description: 'آيات من سور متفرّقة تفتح كلٌّ منها باباً للرزق: التقوى، والاستغفار، والشكر؛ فالرزق له مفاتيح بيد العبد.',
      category: 'الرزق والبركة',
      verses: [
        CuratedPathwayVerse(
          surah: 65,
          ayah: 2,
          note: 'الباب الأول: التقوى؛ من يتّق الله يجعل له من كل ضيق مخرجاً.',
        ),
        CuratedPathwayVerse(
          surah: 65,
          ayah: 3,
          note: 'ويرزقه من حيث لا يحتسب، ومن توكّل على الله فهو كافيه.',
        ),
        CuratedPathwayVerse(
          surah: 71,
          ayah: 10,
          note: 'الباب الثاني: الاستغفار؛ أمرٌ به مقروناً بأن الله غفّار.',
        ),
        CuratedPathwayVerse(
          surah: 71,
          ayah: 11,
          note: 'ثمرته الأولى: مطرٌ متتابع يحيي الأرض.',
        ),
        CuratedPathwayVerse(
          surah: 71,
          ayah: 12,
          note: 'وثمرته الثانية: أموالٌ وبنون وجنّات وأنهار.',
        ),
        CuratedPathwayVerse(
          surah: 14,
          ayah: 7,
          note: 'الباب الثالث: الشكر؛ وعدٌ مؤكّد بالزيادة لمن شكر.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'allah_is_near',
      title: 'الله قريبٌ يُجيب',
      description: 'ثلاث آيات تجتمع على معنى واحد: الله قريب من عبده، ووعد بالإجابة، ويكشف الضيق عن المضطر.',
      category: 'الدعاء والمناجاة',
      verses: [
        CuratedPathwayVerse(
          surah: 2,
          ayah: 186,
          note: 'قُربه منك: لم يقل «قل إني قريب»، بل أجاب بنفسه «فإني قريب».',
        ),
        CuratedPathwayVerse(
          surah: 40,
          ayah: 60,
          note: 'وعده بالإجابة: «ادعوني أستجب لكم»، وتسمية الدعاء عبادة.',
        ),
        CuratedPathwayVerse(
          surah: 27,
          ayah: 62,
          note: 'في أشدّ الضيق: هو وحده من يجيب المضطر ويكشف السوء.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'gratitude',
      title: 'الشكر',
      description: 'الشكر في ثلاث آيات: أمرٌ به، ووعدٌ بالزيادة عليه، ونفعه عائدٌ على الشاكر.',
      category: 'التزكية والإصلاح',
      verses: [
        CuratedPathwayVerse(
          surah: 2,
          ayah: 152,
          note: 'أمرٌ بالشكر مقروناً بالذكر: اذكروني أذكركم.',
        ),
        CuratedPathwayVerse(
          surah: 14,
          ayah: 7,
          note: 'جزاؤه: وعدٌ مؤكّد بالزيادة، وتحذير من الكفران.',
        ),
        CuratedPathwayVerse(
          surah: 31,
          ayah: 12,
          note: 'نفعه يعود عليك: من يشكر فإنما يشكر لنفسه، والله غنيٌّ حميد.',
        ),
      ],
    ),
  ];

  /// ينسخ المسار إلى روابط القارئ.
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

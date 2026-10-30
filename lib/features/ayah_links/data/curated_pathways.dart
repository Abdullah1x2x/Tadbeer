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
        CuratedPathwayVerse(
          surah: 57,
          ayah: 3,
          note: 'الأول والآخر والظاهر والباطن: إحاطة علمه وقدرته بكل شيء.',
        ),
        CuratedPathwayVerse(
          surah: 42,
          ayah: 11,
          note: 'ليس كمثله شيء: تنزيهٌ يملأ القلب إجلالاً، وهو السميع البصير.',
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
        CuratedPathwayVerse(
          surah: 7,
          ayah: 23,
          note: 'آدم وزوجه: اعترافٌ بالذنب هو أول طريق الرحمة.',
        ),
        CuratedPathwayVerse(
          surah: 14,
          ayah: 40,
          note:
              'إبراهيم يسأل إقامة الصلاة له ولذريته، فالهمّ الأكبر صلاح الدين.',
        ),
        CuratedPathwayVerse(
          surah: 28,
          ayah: 24,
          note: 'موسى في غربته: افتقارٌ صادق إلى الله، فجاءه الفرج بعدها.',
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
        CuratedPathwayVerse(
          surah: 12,
          ayah: 53,
          note: 'النفس تأمر بالسوء، فلا تأمنها إلا برحمة الله.',
        ),
        CuratedPathwayVerse(
          surah: 87,
          ayah: 14,
          note: 'الفلاح لمن زكّى نفسه، فالتزكية عمل يومي لا أمنية.',
        ),
        CuratedPathwayVerse(
          surah: 79,
          ayah: 40,
          note: 'خوف مقام الله ونهي النفس عن الهوى هما مفتاح المجاهدة.',
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
        CuratedPathwayVerse(
          surah: 3,
          ayah: 200,
          note: 'أربع وصايا: اصبروا وصابروا ورابطوا واتقوا، طريقاً إلى الفلاح.',
        ),
        CuratedPathwayVerse(
          surah: 103,
          ayah: 3,
          note: 'النجاة من الخسر بالإيمان والعمل والتواصي بالحق والصبر.',
        ),
        CuratedPathwayVerse(
          surah: 94,
          ayah: 5,
          note: 'وعدٌ لا يتخلف: مع العسر يسراً، لا بعده فقط.',
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
        CuratedPathwayVerse(
          surah: 34,
          ayah: 39,
          note: 'الباب الرابع: الإنفاق؛ فما أنفقت يخلفه الله وهو خير الرازقين.',
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
        CuratedPathwayVerse(
          surah: 50,
          ayah: 16,
          note: 'أقرب إليك من حبل الوريد، فلا تحتاج إلى وسيط لتناجيه.',
        ),
        CuratedPathwayVerse(
          surah: 57,
          ayah: 4,
          note: 'وهو معكم أينما كنتم: معيةٌ تطمئن الخائف وتردع الغافل.',
        ),
        CuratedPathwayVerse(
          surah: 58,
          ayah: 7,
          note: 'لا تخلو ثلاثة إلا والله رابعهم؛ علمه محيط بالسر.',
        ),
        CuratedPathwayVerse(
          surah: 11,
          ayah: 61,
          note: 'إن ربي قريب مجيب: استغفر وتب، فالباب مفتوح.',
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
        CuratedPathwayVerse(
          surah: 34,
          ayah: 13,
          note: 'الشاكرون قليل، فكن من هذا القليل.',
        ),
        CuratedPathwayVerse(
          surah: 27,
          ayah: 40,
          note: 'النعمة امتحان: أأشكر أم أكفر؟ وسليمان يدرك ذلك عند أعظم ملك.',
        ),
        CuratedPathwayVerse(
          surah: 76,
          ayah: 3,
          note: 'الهداية بيّنة، والإنسان بعدها شاكر أو كفور.',
        ),
        CuratedPathwayVerse(
          surah: 4,
          ayah: 147,
          note: 'ما يفعل الله بعذابكم إن شكرتم وآمنتم: الشكر أمان.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'tawakkul',
      title: 'التوكل على الله',
      description: 'سبعة أيام مع معنى تسليم الأمر لله بعد الأخذ بالأسباب، وأثره في طمأنينة القلب.',
      category: 'العقيدة والإيمان',
      verses: [
        CuratedPathwayVerse(
          surah: 3,
          ayah: 159,
          note: 'العزم أولاً ثم التوكل: فإذا عزمت فتوكل على الله.',
        ),
        CuratedPathwayVerse(
          surah: 65,
          ayah: 3,
          note: 'من يتوكل على الله فهو حسبه: كفايةٌ لا يبلغها أحد سواه.',
        ),
        CuratedPathwayVerse(
          surah: 8,
          ayah: 2,
          note: 'من صفات المؤمنين حقاً: على ربهم يتوكلون.',
        ),
        CuratedPathwayVerse(
          surah: 9,
          ayah: 51,
          note: 'لن يصيبنا إلا ما كتب الله لنا: يقينٌ يذهب الجزع.',
        ),
        CuratedPathwayVerse(
          surah: 14,
          ayah: 12,
          note: 'كلام الأنبياء أمام الأذى: وما لنا ألا نتوكل على الله وقد هدانا سبلنا.',
        ),
        CuratedPathwayVerse(
          surah: 25,
          ayah: 58,
          note: 'توكل على الحي الذي لا يموت؛ فكل سند سواه يزول.',
        ),
        CuratedPathwayVerse(
          surah: 33,
          ayah: 3,
          note: 'وكفى بالله وكيلاً: أوكل إليه ما أهمّك.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'sabr',
      title: 'الصبر',
      description: 'سبعة أيام مع الصبر في القرآن: عوناً، وخُلقاً للأنبياء، وطريقاً إلى معية الله.',
      category: 'التزكية والإصلاح',
      verses: [
        CuratedPathwayVerse(
          surah: 2,
          ayah: 153,
          note: 'الصبر والصلاة عونك في كل شدة، والله مع الصابرين.',
        ),
        CuratedPathwayVerse(
          surah: 2,
          ayah: 45,
          note: 'استعينوا بالصبر والصلاة: وهي ثقيلة إلا على الخاشعين.',
        ),
        CuratedPathwayVerse(
          surah: 3,
          ayah: 146,
          note: 'ما وهنوا لما أصابهم: والله يحب الصابرين.',
        ),
        CuratedPathwayVerse(
          surah: 16,
          ayah: 127,
          note: 'وما صبرك إلا بالله: فاسأله الصبر قبل أن تطلبه من نفسك.',
        ),
        CuratedPathwayVerse(
          surah: 12,
          ayah: 18,
          note: 'فصبر جميل: صبر يعقوب بلا شكوى إلى الخلق.',
        ),
        CuratedPathwayVerse(
          surah: 46,
          ayah: 35,
          note: 'اصبر كما صبر أولو العزم من الرسل.',
        ),
        CuratedPathwayVerse(
          surah: 8,
          ayah: 46,
          note: 'الصبر عند النزاع يحفظ القوة ويجمع القلوب.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'tawba',
      title: 'التوبة',
      description:
          'سبعة أيام مع باب الله المفتوح: لا قنوط، بل رجوع صادق ومغفرة واسعة.',
      category: 'التزكية والإصلاح',
      verses: [
        CuratedPathwayVerse(
          surah: 39,
          ayah: 53,
          note: 'لا تقنطوا من رحمة الله: أرجى آية للمسرفين على أنفسهم.',
        ),
        CuratedPathwayVerse(
          surah: 66,
          ayah: 8,
          note: 'توبة نصوحاً: صادقة لا رجعة فيها.',
        ),
        CuratedPathwayVerse(
          surah: 2,
          ayah: 222,
          note: 'إن الله يحب التوابين: التوبة تجلب محبته لا مغفرته فقط.',
        ),
        CuratedPathwayVerse(
          surah: 4,
          ayah: 110,
          note: 'من يعمل سوءاً ثم يستغفر يجد الله غفوراً رحيماً.',
        ),
        CuratedPathwayVerse(
          surah: 25,
          ayah: 70,
          note: 'يبدّل الله سيئاتهم حسنات: كرمٌ يفوق الرجاء.',
        ),
        CuratedPathwayVerse(
          surah: 3,
          ayah: 135,
          note: 'ذكروا الله فاستغفروا ولم يصروا: علامة أهل التقوى.',
        ),
        CuratedPathwayVerse(
          surah: 9,
          ayah: 104,
          note: 'هو يقبل التوبة عن عباده: فاطرق بابه الآن.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'yaqin',
      title: 'اليقين',
      description:
          'سبعة أيام في بناء اليقين: بالنظر في الآيات، والسؤال، والعبادة.',
      category: 'العقيدة والإيمان',
      verses: [
        CuratedPathwayVerse(
          surah: 6,
          ayah: 75,
          note: 'أرى الله إبراهيم ملكوت السماوات ليكون من الموقنين: النظر طريق اليقين.',
        ),
        CuratedPathwayVerse(
          surah: 2,
          ayah: 260,
          note: 'ليطمئن قلبي: السؤال طلباً للطمأنينة لا يناقض الإيمان.',
        ),
        CuratedPathwayVerse(
          surah: 32,
          ayah: 24,
          note: 'بالصبر واليقين تُنال الإمامة في الدين.',
        ),
        CuratedPathwayVerse(
          surah: 51,
          ayah: 20,
          note: 'في الأرض آيات للموقنين: تأمل ما حولك.',
        ),
        CuratedPathwayVerse(
          surah: 45,
          ayah: 4,
          note: 'في خلقكم وما يبث من دابة آيات لقوم يوقنون.',
        ),
        CuratedPathwayVerse(
          surah: 15,
          ayah: 99,
          note: 'واعبد ربك حتى يأتيك اليقين: عبادة دائمة حتى الرحيل.',
        ),
        CuratedPathwayVerse(
          surah: 13,
          ayah: 28,
          note: 'بذكر الله تطمئن القلوب: ثمرة اليقين.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'fear_hope',
      title: 'الخوف والرجاء',
      description: 'سبعة أيام بين جناحي المؤمن: رجاء يدفع إلى العمل، وخوف يمنع من الغفلة.',
      category: 'التزكية والإصلاح',
      verses: [
        CuratedPathwayVerse(
          surah: 32,
          ayah: 16,
          note: 'يدعون ربهم خوفاً وطمعاً: توازن قلوب القائمين بالليل.',
        ),
        CuratedPathwayVerse(
          surah: 39,
          ayah: 9,
          note: 'يحذر الآخرة ويرجو رحمة ربه: صورة العابد العالم.',
        ),
        CuratedPathwayVerse(
          surah: 15,
          ayah: 49,
          note: 'نبّئ عبادي أني أنا الغفور الرحيم: يبدأ بالرحمة.',
        ),
        CuratedPathwayVerse(
          surah: 15,
          ayah: 50,
          note: 'وأن عذابي هو العذاب الأليم: تذكير يحفظ من الاغترار.',
        ),
        CuratedPathwayVerse(
          surah: 17,
          ayah: 57,
          note: 'يرجون رحمته ويخافون عذابه: حال المقربين.',
        ),
        CuratedPathwayVerse(
          surah: 21,
          ayah: 90,
          note: 'يدعوننا رغباً ورهباً: سبب استجابة دعاء الأنبياء.',
        ),
        CuratedPathwayVerse(
          surah: 55,
          ayah: 46,
          note: 'ولمن خاف مقام ربه جنتان: الخوف يثمر كرامة.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'parents',
      title: 'بر الوالدين',
      description:
          'سبعة أيام مع حق الوالدين: الإحسان، ولين القول، والدعاء لهما.',
      category: 'الأسرة والأخلاق',
      verses: [
        CuratedPathwayVerse(
          surah: 17,
          ayah: 23,
          note: 'قرن الله الإحسان إليهما بعبادته، ونهى عن أدنى ضجر.',
        ),
        CuratedPathwayVerse(
          surah: 17,
          ayah: 24,
          note: 'جناح الذل من الرحمة، ودعاء لا ينقطع: رب ارحمهما.',
        ),
        CuratedPathwayVerse(
          surah: 31,
          ayah: 14,
          note: 'اشكر لي ولوالديك: شكرهما من شكر الله.',
        ),
        CuratedPathwayVerse(
          surah: 31,
          ayah: 15,
          note: 'حتى عند الاختلاف في الدين: وصاحبهما في الدنيا معروفاً.',
        ),
        CuratedPathwayVerse(
          surah: 46,
          ayah: 15,
          note: 'تذكّر حمل الأم ووضعها، وادعُ بصلاح الذرية.',
        ),
        CuratedPathwayVerse(
          surah: 2,
          ayah: 83,
          note: 'من ميثاق بني إسرائيل: وبالوالدين إحساناً.',
        ),
        CuratedPathwayVerse(
          surah: 14,
          ayah: 41,
          note: 'إبراهيم يدعو لوالديه: ربنا اغفر لي ولوالدي.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'blessings',
      title: 'نعم الله',
      description: 'سبعة أيام لنتذكّر ما نغفل عنه من نعم، فيتحرك القلب بالشكر.',
      category: 'التزكية والإصلاح',
      verses: [
        CuratedPathwayVerse(
          surah: 16,
          ayah: 18,
          note: 'لا تحصوها: فكيف بشكرها؟ والله غفور رحيم.',
        ),
        CuratedPathwayVerse(
          surah: 14,
          ayah: 34,
          note: 'آتاكم من كل ما سألتموه: نِعمٌ سبقت السؤال.',
        ),
        CuratedPathwayVerse(
          surah: 55,
          ayah: 13,
          note: 'فبأي آلاء ربكما تكذبان: سؤال يتكرر ليوقظ القلب.',
        ),
        CuratedPathwayVerse(
          surah: 93,
          ayah: 11,
          note: 'وأما بنعمة ربك فحدّث: إظهار النعمة شكر.',
        ),
        CuratedPathwayVerse(
          surah: 16,
          ayah: 53,
          note: 'ما بكم من نعمة فمن الله: فلمن تلجأ عند الضر؟',
        ),
        CuratedPathwayVerse(
          surah: 31,
          ayah: 20,
          note: 'نعم ظاهرة وباطنة: كثير منها لا تراه.',
        ),
        CuratedPathwayVerse(
          surah: 102,
          ayah: 8,
          note: 'ثم لتسألن يومئذ عن النعيم: النعمة مسؤولية.',
        ),
      ],
    ),
    CuratedPathway(
      id: 'quran_itself',
      title: 'القرآن',
      description:
          'سبعة أيام مع القرآن كما وصف نفسه: مبارك، ميسّر، هادٍ، وشفاء.',
      category: 'القرآن والتدبر',
      verses: [
        CuratedPathwayVerse(
          surah: 38,
          ayah: 29,
          note: 'أُنزل ليُتدبّر: غاية القراءة فهمٌ يحرّك القلب.',
        ),
        CuratedPathwayVerse(
          surah: 47,
          ayah: 24,
          note: 'أفلا يتدبرون القرآن: سؤال موجّه إلى قلبك.',
        ),
        CuratedPathwayVerse(
          surah: 17,
          ayah: 9,
          note: 'يهدي للتي هي أقوم في كل شأن.',
        ),
        CuratedPathwayVerse(
          surah: 54,
          ayah: 17,
          note: 'ولقد يسرنا القرآن للذكر: فهل من مدكر؟',
        ),
        CuratedPathwayVerse(
          surah: 59,
          ayah: 21,
          note: 'لو أُنزل على جبل لخشع: فأين قلوبنا؟',
        ),
        CuratedPathwayVerse(
          surah: 4,
          ayah: 82,
          note: 'لا اختلاف فيه: دليل أنه من عند الله.',
        ),
        CuratedPathwayVerse(
          surah: 10,
          ayah: 57,
          note: 'موعظة وشفاء لما في الصدور وهدى ورحمة.',
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

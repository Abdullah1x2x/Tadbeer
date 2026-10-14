// ignore_for_file: avoid_print

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  print('Starting generation of heritage PDFs...');
  final fontData = File('assets/fonts/Amiri-Regular.ttf').readAsBytesSync();
  final fontBoldData = File('assets/fonts/Amiri-Bold.ttf').readAsBytesSync();
  final amiri = pw.Font.ttf(fontData.buffer.asByteData());
  final amiriBold = pw.Font.ttf(fontBoldData.buffer.asByteData());

  final books = [
    {
      'file': 'assets/books/sahifah_sajjadiyah.pdf',
      'title': 'الصحيفة السجادية الكاملة',
      'subtitle': 'زبور آل محمد — ديوان أدعية الإمام علي بن الحسين زين العابدين عليه السلام',
      'author': 'الإمام علي بن الحسين (زين العابدين) عليه السلام',
      'chapters': [
        {
          'title': 'مقدمة الصحيفة وفضلها',
          'content':
              'الصحيفة السجادية هي درة التراث الإسلامي وزبور آل محمد صلوات الله عليهم أجمعين. '
              'تجمع أسمى معاني التوحيد، وأرقى مناجاة الخالق جل وعلا، وأدق تفاصيل إصلاح النفس والسلوك البشري.',
        },
        {
          'title': 'دعاؤه عليه السلام بالتحميد لله عز وجل',
          'content':
              'الْحَمْدُ لِلَّهِ الْأَوَّلِ بِلَا أَوَّلٍ كَانَ قَبْلَهُ، وَالْآخِرِ بِلَا آخِرٍ يَكُونُ بَعْدَهُ، '
              'الَّذِي قَصُرَتْ عَنْ رُؤْيَتِهِ أَبْصَارُ النَّاظِرِينَ، وَعَجَزَتْ عَنْ نَعْتِهِ أَوْهَامُ الْوَاصِفِينَ. '
              'ابْتَدَعَ بِقُدْرَتِهِ الْخَلْقَ ابْتِدَاعاً، وَاخْتَرَعَهُمْ عَلَى مَشِيَّتِهِ اخْتِرَاعاً، '
              'ثُمَّ سَلَكَ بِهِمْ طَرِيقَ إِرَادَتِهِ، وَبَعَثَهُمْ فِي سَبِيلِ مَحَبَّتِهِ.',
        },
        {
          'title': 'دعاؤه عليه السلام في مكارم الأخلاق ومرضي الأفعال',
          'content':
              'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِهِ، وَبَلِّغْ بِإِيمَانِي أَكْمَلَ الْإِيمَانِ، وَاجْعَلْ يَقِينِي أَفْضَلَ الْيَقِينِ، '
              'وَانْتَهِ بِنِيَّتِي إِلَى أَحْسَنِ النِّيَّاتِ، وَبِعَمَلِي إِلَى أَحْسَنِ الْأَعْمَالِ. '
              'اللَّهُمَّ وَفِّرْ بِلُطْفِكَ نِيَّتِي، وَصَحِّحْ بِمَا عِنْدَكَ يَقِينِي، وَاسْتَصْلِحْ بِقُدْرَتِكَ مَا فَسَدَ مِنِّي.',
        },
        {
          'title': 'دعاؤه عليه السلام لأهل الثغور وحماة الأمة',
          'content':
              'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِهِ، وَحَصِّنْ ثُغُورَ الْمُسْلِمِينَ بِعِزَّتِكَ، وَأَيِّدْ حُمَاتَهَا بِقُوَّتِكَ، '
              'وَأَسْبِغْ عَطَايَاهُمْ مِنْ جِدَتِكَ. اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِهِ، وَكَثِّرْ عِدَّتَهُمْ، وَاشْحَذْ أَسْلِحَتَهُمْ، '
              'وَاحْرُسْ حَوْزَتَهُمْ، وَامْنَعْ حَوْمَتَهُمْ، وَأَلِّفْ جَمْعَهُمْ، وَدَبِّرْ أَمْرَهُمْ.',
        },
      ],
    },
    {
      'file': 'assets/books/risalat_al_huquq.pdf',
      'title': 'رسالة الحقوق',
      'subtitle': 'الوثيقة الإيمانية والأخلاقية الجامعة في حقوق الله والنفس والناس',
      'author': 'الإمام علي بن الحسين (زين العابدين) عليه السلام',
      'chapters': [
        {
          'title': 'مقدمة الرسالة وحق الله الأكبر وحق النفس',
          'content':
              'اعْلَمْ رَحِمَكَ اللَّهُ أَنَّ لِلَّهِ عَلَيْكَ حُقُوقاً مُحِيطَةً بِكَ فِي كُلِّ حَرَكَةٍ تَحَرَّكْتَهَا، '
              'أَوْ سَكَنَةٍ سَكَنْتَهَا، أَوْ مَنْزِلَةٍ نَزَلْتَهَا، أَوْ جَارِحَةٍ قَلَبْتَهَا، أَوْ آلَةٍ تَصَرَّفْتَ بِهَا. '
              'فَأَكْبَرُ حُقُوقِ اللَّهِ عَلَيْكَ: أَنْ تَعْبُدَهُ وَلَا تُشْرِكَ بِهِ شَيْئاً. '
              'وَأَمَّا حَقُّ نَفْسِكَ عَلَيْكَ فَأَنْ تَسْتَعْمِلَهَا فِي طَاعَةِ اللَّهِ عز وجل.',
        },
        {
          'title': 'حقوق الجوارح: اللسان والسمع والبصر',
          'content':
              'فَأَمَّا حَقُّ اللِّسَانِ فَإِكْرَامُهُ عَنِ الْخَنَا، وَتَعْوِيدُهُ عَلَى الْخَيْرِ، وَحَمْلُهُ عَلَى الْأَدَبِ، '
              'وَإِعْفَاؤُهُ عَنِ الْفُضُولِ الَّتِي لَا مَنْفَعَةَ لَهَا. '
              'وَأَمَّا حَقُّ السَّمْعِ فَتَنْزِيهُهُ عَنْ أَنْ تَجْعَلَهُ طَرِيقاً إِلَى قَلْبِكَ إِلَّا لِفُوَّهَةٍ كَرِيمَةٍ تُحْدِثُ فِي قَلْبِكَ خَيْراً. '
              'وَأَمَّا حَقُّ الْبَصَرِ فَغَضُّهُ عَمَّا لَا يَحِلُّ لَكَ، وَأَلَّا تَبْتَذِلَهُ إِلَّا لِمَوْضِعِ عِبْرَةٍ تَسْتَبْصِرُ بِهَا.',
        },
        {
          'title': 'حقوق الرعية والرحم والناس',
          'content':
              'فَحَقُّ رَعِيَّتِكَ بِالسُّلْطَانِ أَنْ تَعْلَمَ أَنَّهُمْ صَارُوا رَعِيَّتَكَ لِضَعْفِهِمْ وَقُوَّتِكَ، فَيَجِبُ أَنْ تَعْدِلَ فِيهِمْ. '
              'وَأَمَّا حَقُّ أُمِّكَ فَأَنْ تَعْلَمَ أَنَّهَا حَمَلَتْكَ حَيْثُ لَا يَحْمِلُ أَحَدٌ أَحَداً، وَأَطْعَمَتْكَ مِنْ ثَمَرَةِ قَلْبِهَا. '
              'وَأَمَّا حَقُّ أَبِيكَ فَأَنْ تَعْلَمَ أَنَّهُ أَصْلُكَ، وَلَوْلَاهُ لَمْ تَكُنْ.',
        },
      ],
    },
    {
      'file': 'assets/books/nahj_al_balagha.pdf',
      'title': 'نهج البلاغة — روائع الخطب والعهود والحكم',
      'subtitle': 'مختارات جامعة من درر كلام أمير المؤمنين علي بن أبي طالب عليه السلام',
      'author': 'أمير المؤمنين علي بن أبي طالب عليه السلام',
      'chapters': [
        {
          'title': 'خطبة همام في صفات المتقين',
          'content':
              'أَمَّا بَعْدُ، فَإِنَّ اللَّهَ سُبْحَانَهُ وَتَعَالَى خَلَقَ الْخَلْقَ حِينَ خَلَقَهُمْ غَنِيّاً عَنْ طَاعَتِهِمْ، '
              'آمِناً مِنْ مَعْصِيَتِهِمْ، لِأَنَّهُ لَا تَضُرُّهُ مَعْصِيَةُ مَنْ عَصَاهُ، وَلَا تَنْفَعُهُ طَاعَةُ مَنْ أَطَاعَهُ. '
              'فَالْمُتَّقُونَ فِيهَا هُمْ أَهْلُ الْفَضَائِلِ: مَنْطِقُهُمُ الصَّوَابُ، وَمَلْبَسُهُمُ الِاقْتِصَادُ، وَمَشْيُهُمُ التَّوَاضُعُ. '
              'غَضُّوا أَبْصَارَهُمْ عَمَّا حَرَّمَ اللَّهُ عَلَيْهِمْ، وَوَقَفُوا أَسْمَاعَهُمْ عَلَى الْعِلْمِ النَّافِعِ لَهُمْ.',
        },
        {
          'title': 'عهد الإمام علي لمالك الأشتر النخعي لما ولاه مصر',
          'content':
              'هَذَا مَا أَمَرَ بِهِ عَبْدُ اللَّهِ عَلِيٌّ أَمِيرُ الْمُؤْمِنِينَ، مَالِكَ بْنَ الْحَارِثِ الْأَشْتَرَ فِي عَهْدِهِ إِلَيْهِ: '
              'أَمَرَهُ بِتَقْوَى اللَّهِ، وَإِيثَارِ طَاعَتِهِ، وَاتِّبَاعِ مَا أَمَرَ بِهِ فِي كِتَابِهِ. '
              'وَأَشْعِرْ قَلْبَكَ الرَّحْمَةَ لِلرَّعِيَّةِ، وَالْمَحَبَّةَ لَهُمْ، وَاللُّطْفَ بِهِمْ، '
              'وَلَا تَكُونَنَّ عَلَيْهِمْ سَبُعاً ضَارِياً تَغْتَنِمُ أَكْلَهُمْ، فَإِنَّهُمْ صِنْفَانِ: '
              'إِمَّا أَخٌ لَكَ فِي الدِّينِ، أَوْ نَظِيرٌ لَكَ فِي الْخَلْقِ.',
        },
        {
          'title': 'وصيته الجامعة لابنه الحسن عليهما السلام',
          'content':
              'مِنَ الْوَالِدِ الْفَانِ، الْمُقِرِّ لِلزَّمَانِ، إِلَى الْمَوْلُودِ الْمُؤَمِّلِ مَا لَا يُدْرِكُ. '
              'أَمَّا بَعْدُ، فَإِنِّي أُوصِيكَ بِتَقْوَى اللَّهِ، وَلُزُومِ أَمْرِهِ، وَعِمَارَةِ قَلْبِكَ بِذِكْرِهِ، وَالِاعْتِصَامِ بِحَبْلِهِ. '
              'وَأَحْيِ قَلْبَكَ بِالْمَوْعِظَةِ، وَأَمِتْهُ بِالزَّهَادَةِ، وَقَوِّهِ بِالْيَقِينِ، وَنَوِّرْهُ بِالْحِكْمَةِ.',
        },
      ],
    },
    {
      'file': 'assets/books/akhlaq_hamalat_quran.pdf',
      'title': 'أخلاق حَمَلَة القرآن وأهله',
      'subtitle': 'الآداب الإيمانية والمسلكية الواجبة على أهل القرآن ومدارسته',
      'author': 'الإمام أبي بكر محمد بن الحسين الآجري (ت 360 هـ)',
      'chapters': [
        {
          'title': 'فضل حملة القرآن الكريم وقارئيه',
          'content':
              'الحمد لله الذي أنزل على عبده الكتاب ولم يجعل له عوجا، قيما لينذر بأسا شديدا من لدنه ويبشر المؤمنين الذين يعملون الصالحات. '
              'إن أهل القرآن هم أهل الله وخاصته، جعل الله تعالى القرآن لقلوبهم ربيعاً، ولظلمة قبورهم ضياءً، '
              'ولهم في كل حرف يتلونه حسنة وعشر أمثالها.',
        },
        {
          'title': 'أخلاق القارئ والمتدبر لكتاب الله',
          'content':
              'ينبغي لحامل القرآن أن يكون أول ما يعنى به تطهير باطنه وظاهره، والإخلاص لله تعالى في قراءته وتدبره. '
              'فلا يبتغي بالقرآن عرضاً من الدنيا زائلاً، ولا مباهاة بين الأقران، '
              'بل يقصده ابتغاء مرضاة ربه، وتزكيةً لنفسه، واستنارةً لبصيرته.',
        },
        {
          'title': 'أدب التلاوة والعمل بمحكم التنزيل',
          'content':
              'إذا تلا حامل القرآن آية وعد استبشر ورجا، وإذا مر بآية وعيد خاف ووجل واستعاذ، '
              'وإذا تلا أمثال القرآن تدبرها وفهمها، وإذا قرأ أوامره امتثل، وإذا تلا نواهيه ارتدع وازدجر. '
              'فيكون القرآن حجة له لا عليه يوم يلقى الله رب العالمين.',
        },
      ],
    },
    {
      'file': 'assets/books/qawaid_tadabbur_quran.pdf',
      'title': 'قواعد وأصول في تدبر القرآن الكريم',
      'subtitle': 'المنهج العلمي والروحي لفهم كلام رب العالمين واستلهام هدايته',
      'author': 'دراسة جامعة محققة من أصول التفسير والتدبر',
      'chapters': [
        {
          'title': 'القاعدة الأولى: حقيقة التدبر القرآني وغايته',
          'content':
              'التدبر هو إعمال الفكر والنظر في مآلات الآيات وعواقبها، وتأمل دلالاتها لاستخراج الهدايات العملية. '
              'قال الله تعالى: {كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ وَلِيَتَذَكَّرَ أُولُو الْأَلْبَابِ}. '
              'فالتدبر هو الغاية العظمى من إنزال الكتاب الكريم، وهو روح التلاوة وحياتها.',
        },
        {
          'title': 'القاعدة الثانية: استحضار أن الخطاب موجه إليك شخصياً',
          'content':
              'من أعظم مفاتيح التدبر أن يستشعر القارئ أن كل نداء، وكل موعظة، وكل أمر ونهي في كتاب الله، '
              'إنما هو مخاطب به مباشرة في حاضره وواقعه. '
              'فإذا سمع: {يَا أَيُّهَا الَّذِينَ آمَنُوا} أصغى بسمعه وبقلبه، فإنه خير يؤمر به أو شر يُنهى عنه.',
        },
        {
          'title': 'القاعدة الثالثة: التفاعل الوجداني والعملي مع الآيات',
          'content':
              'التدبر لا ينتهي بانتهاء القراءة، بل يبدأ منها ليتحول إلى سلوك وموقف ويقين وعمل صالح. '
              'كان الصحابة وأهل البيت عليهم السلام لا يجاوزون عشر آيات حتى يتعلموا ما فيهن من العلم والعمل، '
              'فأخذوا العلم والعمل جميعاً.',
        },
      ],
    },
    {
      'file': 'assets/books/al_tibyan.pdf',
      'title': 'التبيان في آداب حَمَلَة القرآن',
      'subtitle': 'مرشد القارئ والسامع والمتدبر لآيات الكتاب الحكيم',
      'author': 'الإمام محيي الدين يحيى بن شرف النووي (ت 676 هـ)',
      'chapters': [
        {
          'title': 'في فضل تلاوة القرآن وحملته',
          'content':
              'الحمد لله الكريم المنان، ذي الطول والفضل والإحسان، الذي هدانا للإيمان، وفضل ديننا على سائر الأديان، '
              'وأنزل علينا أشرف كتبه، وأوضح طرقه. '
              'روي عن النبي صلى الله عليه وآله وسلم أنه قال: "خيركم من تعلم القرآن وعلمه".',
        },
        {
          'title': 'في آداب قارئ القرآن ومتدبره',
          'content':
              'أول ما ينبغي للقارئ أن يخلص في قراءته ويبتغي بها وجه الله تعالى، '
              'وينبغي أن يتأدب مع القرآن في طهارته وسواكه وإقباله على مصحفه بحضور قلب وخشوع، '
              'وأن يرتل ترتيلاً مبيناً امتثالاً لقوله تعالى: {وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا}.',
        },
        {
          'title': 'في أحوال السلف الصالح عند تلاوة القرآن',
          'content':
              'كان الصالحون من عباد الله إذا شرعوا في قراءة القرآن خشعت قلوبهم، وفاضت أعينهم، '
              'وربما ردد أحدهم الآية الواحدة ليلته كلها يتدبرها ويبكي عندها حباً وشوقاً وخوفاً ورجاءً. '
              'فالقرآن شفاء لما في الصدور، وهدى ورحمة للمؤمنين.',
        },
      ],
    },
  ];

  for (final b in books) {
    final pdf = pw.Document();
    final title = b['title'] as String;
    final subtitle = b['subtitle'] as String;
    final author = b['author'] as String;
    final filePath = b['file'] as String;
    final chapters = b['chapters'] as List<Map<String, String>>;

    // غلاف الكتاب
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: amiri, bold: amiriBold),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.brown800, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Text(
                    'تطبيق تَدْبِير — المكتبة الإسلامية',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(font: amiriBold, fontSize: 14, color: PdfColors.brown800),
                  ),
                ),
                pw.SizedBox(height: 36),
                pw.Text(
                  title,
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: amiriBold, fontSize: 26, color: PdfColors.black),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  subtitle,
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: amiri, fontSize: 15, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 28),
                pw.Container(
                  width: 80,
                  height: 2,
                  color: PdfColors.brown400,
                ),
                pw.SizedBox(height: 28),
                pw.Text(
                  author,
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: amiriBold, fontSize: 17, color: PdfColors.brown900),
                ),
              ],
            ),
          );
        },
      ),
    );

    // فصول ومباحث الكتاب
    for (final chap in chapters) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: amiri, bold: amiriBold),
          header: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              margin: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(font: amiri, fontSize: 11, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'تطبيق تَدْبِير',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(font: amiri, fontSize: 11, color: PdfColors.brown700),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(top: 8),
              margin: const pw.EdgeInsets.only(top: 16),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'الصفحة ${context.pageNumber} من ${context.pagesCount}',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: amiri, fontSize: 10, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) => [
            pw.Text(
              chap['title']!,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: amiriBold, fontSize: 20, color: PdfColors.brown900),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              chap['content']!,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.justify,
              style: pw.TextStyle(font: amiri, fontSize: 14, lineSpacing: 6),
            ),
          ],
        ),
      );
    }

    final outFile = File(filePath);
    await outFile.writeAsBytes(await pdf.save());
    print('Generated: $filePath (${outFile.lengthSync()} bytes)');
  }

  print('All heritage PDFs generated successfully!');
}

/// أقسام أذكار السبحة والمحراب الشريف (الفصل بين الاستغفار والتسبيح).
enum DhikrSection {
  /// محراب الاستغفار والتوبة والأوبة إلى الله.
  istighfar,

  /// محراب التسبيح والتحميد والتهليل والتكبير.
  tasbeeh,
}

/// امتداد مساعد لقسم الذكر يوفر المسميات العربية.
extension DhikrSectionX on DhikrSection {
  /// العنوان الكامل للقسم.
  String get title {
    switch (this) {
      case DhikrSection.istighfar:
        return 'محراب الاستغفار والتوبة';
      case DhikrSection.tasbeeh:
        return 'محراب التسبيح والتحميد';
    }
  }

  /// العنوان القصير للعرض في الأزرار والتبويبات.
  String get shortTitle {
    switch (this) {
      case DhikrSection.istighfar:
        return 'الاستغفار';
      case DhikrSection.tasbeeh:
        return 'التسبيح والتحميد';
    }
  }
}

/// نموذج بيانات الأذكار والاستغفار والتسبيح للسبحة الإلكترونية.
class TasbeehDhikr {
  final String id;
  final String arabicText;
  final String englishTranslation;
  final String virtue;
  final String category;
  final int defaultTarget;
  final DhikrSection section;

  /// ينشئ ذكراً أو صيغة استغفار وتسبيح.
  const TasbeehDhikr({
    required this.id,
    required this.arabicText,
    required this.englishTranslation,
    required this.virtue,
    required this.category,
    this.defaultTarget = 33,
    this.section = DhikrSection.tasbeeh,
  });

  /// ما إذا كان الذكر يتبع لمحراب الاستغفار.
  bool get isIstighfar => section == DhikrSection.istighfar;

  /// ما إذا كان الذكر يتبع لمحراب التسبيح والتحميد.
  bool get isTasbeeh => section == DhikrSection.tasbeeh;

  /// جميع التصنيفات المعتمدة للأذكار والاستغفار والتسبيح.
  static const List<String> categories = [
    'الكل',
    'استغفار وتوبة',
    'استغفار قرآني',
    'استغفار نبوي',
    'تسبيح وتنزيه',
    'حمد وشكر',
    'تهليل وتوحيد',
    'تكبير وتعظيم',
    'حوقلة وتوكل',
    'صلاة على النبي',
    'أدعية جامعة',
  ];

  /// تصنيفات محراب الاستغفار والتوبة.
  static const List<String> istighfarCategories = [
    'الكل',
    'استغفار وتوبة',
    'استغفار قرآني',
    'استغفار نبوي',
  ];

  /// تصنيفات محراب التسبيح والتحميد والتهليل.
  static const List<String> tasbeehCategories = [
    'الكل',
    'تسبيح وتنزيه',
    'حمد وشكر',
    'تهليل وتوحيد',
    'تكبير وتعظيم',
    'حوقلة وتوكل',
    'صلاة على النبي',
    'أدعية جامعة',
  ];

  /// قائمة صيغ الاستغفار والتوبة فقط.
  static List<TasbeehDhikr> get istighfarDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.istighfar).toList();

  /// قائمة صيغ التسبيح والتحميد والتهليل فقط.
  static List<TasbeehDhikr> get tasbeehDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.tasbeeh).toList();

  /// باقة الأذكار والصيغ المعتمدة للاستغفار والتسبيح (49 صيغة موثقة ومفصلة).
  static const List<TasbeehDhikr> defaultDhikrs = [
    // =========================================================
    // القسم الأول: محراب الاستغفار والتوبة (20 صيغة مباركة)
    // =========================================================
    TasbeehDhikr(
      id: 'istighfar_1',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
      englishTranslation:
          'I seek the forgiveness of Allah the Almighty and repent to Him.',
      virtue:
          'من لزم الاستغفار جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً ورزقه من حيث لا يحتسب.',
      category: 'استغفار وتوبة',
      defaultTarget: 100,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_sayyid',
      arabicText:
          'اللَّهُمَّ أَنْتَ رَبِّي لا إِلَهَ إِلا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لا يَغْفِرُ الذُّنُوبَ إِلا أَنْتَ',
      englishTranslation:
          'O Allah, You are my Lord; none has the right to be worshipped but You. You created me and I am Your servant...',
      virtue:
          'سيد الاستغفار؛ من قالها موقناً بها حين يمسي فمات من ليلته دخل الجنة، وكذلك إذا أصبح.',
      category: 'استغفار نبوي',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_rabbi',
      arabicText:
          'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
      englishTranslation:
          'My Lord, forgive me and accept my repentance, for You are the Accepter of Repentance, the Most Merciful.',
      virtue:
          'كان النبي ﷺ يُعدّ له في المجلس الواحد مائة مرة قبل أن يقوم.',
      category: 'استغفار نبوي',
      defaultTarget: 100,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_hayy',
      arabicText:
          'أَسْتَغْفِرُ اللَّهَ الَّذِي لا إِلَهَ إِلا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ',
      englishTranslation:
          'I seek forgiveness from Allah, other than Whom there is no deity, the Ever-Living, the Sustainer, and I repent to Him.',
      virtue:
          'قال رسول الله ﷺ: من قالها غُفر له وإن كان فرّ من الزحف.',
      category: 'استغفار نبوي',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_siddiq',
      arabicText:
          'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلا يَغْفِرُ الذُّنُوبَ إِلا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ وَارْحَمْنِي إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
      englishTranslation:
          'O Allah, I have wronged myself greatly, and none forgives sins except You...',
      virtue:
          'علّمها النبي ﷺ لأبي بكر الصديق رضي الله عنه ليدعو بها في صلاته ومحرابه.',
      category: 'استغفار نبوي',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_adam',
      arabicText:
          'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      englishTranslation:
          'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
      virtue:
          'الكلمات القرآنية التي تلقاها آدم من ربه فتاب عليه [الأعراف: ٢٣]، وهي مفتاح التوبة الصادقة.',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_musa',
      arabicText: 'رَبِّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي',
      englishTranslation:
          'My Lord, indeed I have wronged myself, so forgive me.',
      virtue:
          'تضرع كليم الله موسى عليه السلام حين ندم واستغفر فغفر الله له وكان من المقربين [القصص: ١٦].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_nuh',
      arabicText:
          'رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
      englishTranslation:
          'My Lord, forgive me and my parents and whoever enters my house a believer and the believing men and believing women.',
      virtue:
          'استغفار قرآني جامع للنفس والوالدين ولعموم أهل الإيمان أحياءً وأمواتاً [نوح: ٢٨].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_ibrahim',
      arabicText:
          'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
      englishTranslation:
          'Our Lord, forgive me and my parents and the believers the Day the account is established.',
      virtue:
          'دعوة خليل الرحمن إبراهيم عليه السلام الجامعة للنجاة والمغفرة يوم الحساب الأكبر [إبراهيم: ٤١].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_al_albab',
      arabicText:
          'رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ',
      englishTranslation:
          'Our Lord, forgive us our sins and remove from us our misdeeds and cause us to die with the righteous.',
      virtue:
          'دعاء أولي الألباب المتفكرين في خلق السماوات والأرض راجين مغفرة الذنوب وحسن الختام [آل عمران: ١٩٣].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_mumineen',
      arabicText:
          'رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا وَارْحَمْنَا وَأَنتَ خَيْرُ الرَّاحِمِينَ',
      englishTranslation:
          'Our Lord, we have believed, so forgive us and have mercy upon us, and You are the best of the merciful.',
      virtue:
          'توسل عباد الرحمن بالإيمان لنيل المغفرة والرحمة الواسعة [المؤمنون: ١٠٩].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_zanbi_kulluh',
      arabicText:
          'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ: دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ، وَعَلانِيَتَهُ وَسِرَّهُ',
      englishTranslation:
          'O Allah, forgive me all my sins, small and great, first and last, open and secret.',
      virtue:
          'كان النبي ﷺ يكثر منه في سجوده؛ استغفار شامل مستوعب لجميع الخطايا ظاهرها وباطنها (صحيح مسلم).',
      category: 'استغفار نبوي',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_qaddamt',
      arabicText:
          'اللَّهُمَّ اغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ، وَمَا أَسْرَرْتُ وَمَا أَعْلَنْتُ، وَمَا أَسْرَفْتُ، وَمَا أَنْتَ أَعْلَمُ بِهِ مِنِّي، أَنْتَ الْمُقَدِّمُ وَأَنْتَ الْمُؤَخِّرُ، لا إِلَهَ إِلا أَنْتَ',
      englishTranslation:
          'O Allah, forgive me what I have sent before and what I have left behind, what I have concealed and what I have declared...',
      virtue:
          'من دعاء النبي ﷺ بين التشهد والتسليم في صلاته لجبر العمل وتمام المغفرة (صحيح مسلم).',
      category: 'استغفار نبوي',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_sujood',
      arabicText: 'سُبْحَانَكَ اللَّهُمَّ رَبَّنَا وَبِحَمْدِكَ، اللَّهُمَّ اغْفِرْ لِي',
      englishTranslation:
          'Glory be to You, O Allah, our Lord, and praise; O Allah, forgive me.',
      virtue:
          'كان النبي ﷺ يكثر أن يقوله في ركوعه وسجوده امتثالاً لأمر الله في سورة النصر (متفق عليه).',
      category: 'استغفار نبوي',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_salat',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ ، أَسْتَغْفِرُ اللَّهَ ، أَسْتَغْفِرُ اللَّهَ',
      englishTranslation:
          'I seek the forgiveness of Allah, I seek the forgiveness of Allah, I seek the forgiveness of Allah.',
      virtue:
          'هدي النبي ﷺ دبر كل صلاة مكتوبة لجبر أي نقص أو سهو في أداء العبادة.',
      category: 'استغفار وتوبة',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_kaffara',
      arabicText:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لا إِلَهَ إِلا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ',
      englishTranslation:
          'Glory is to You, O Allah, and praise. I bear witness that there is no deity except You; I seek Your forgiveness and repent to You.',
      virtue:
          'كفارة لما قد يقع في المجلس من لغو أو تقصير، وخاتمة مباركة لكل لقاء.',
      category: 'استغفار وتوبة',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_umum_muslimeen',
      arabicText:
          'اللَّهُمَّ اغْفِرْ لِلْمُسْلِمِينَ وَالْمُسْلِمَاتِ، وَالْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ، الأَحْيَاءِ مِنْهُمْ وَالأَمْوَاتِ',
      englishTranslation:
          'O Allah, forgive the believing men and women, living and deceased.',
      virtue:
          'قال رسول الله ﷺ: من استغفر للمؤمنين والمؤمنات كتب الله له بكل مؤمن ومؤمنة حسنة (حديث حسن).',
      category: 'استغفار وتوبة',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_mukhtasar',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      englishTranslation:
          'I seek forgiveness of Allah and repent to Him.',
      virtue:
          'الذكر الخفيف اليومي؛ كان النبي ﷺ يستغفر الله ويتوب إليه في اليوم أكثر من سبعين مرة وفي رواية مائة مرة.',
      category: 'استغفار وتوبة',
      defaultTarget: 100,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_dhu_alnoor',
      arabicText: 'رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا إِنَّكَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      englishTranslation:
          'Our Lord, perfect for us our light and forgive us. Indeed, You are over all things competent.',
      virtue:
          'دعاء المؤمنين يوم القيامة حين يسعى نورهم بين أيديهم يسألون الله إتمام النور والمغفرة [التحريم: ٨].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),
    TasbeehDhikr(
      id: 'istighfar_ikhwan',
      arabicText:
          'رَبَّنَا اغْفِرْ لَنَا وَلإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالإِيمَانِ وَلا تَجْعَلْ فِي قُلُوبِنَا غِلا لِّلَّذِينَ آمَنُوا',
      englishTranslation:
          'Our Lord, forgive us and our brothers who preceded us in faith and put not in our hearts any resentment toward those who have believed.',
      virtue:
          'دعاء سلامة الصدر والمغفرة للمسلمين والأسلاف السابقين بالإيمان [الحشر: ١٠].',
      category: 'استغفار قرآني',
      defaultTarget: 33,
      section: DhikrSection.istighfar,
    ),

    // =========================================================
    // القسم الثاني: محراب التسبيح والتحميد والتهليل (29 صيغة مباركة)
    // =========================================================
    TasbeehDhikr(
      id: 'tasbeeh_subhan_bihamdih',
      arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      englishTranslation:
          'Glory be to Allah and Praise Him, Glory be to Allah the Supreme.',
      virtue:
          'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_baqiyat',
      arabicText:
          'سُبْحَانَ اللَّهِ ، وَالْحَمْدُ لِلَّهِ ، وَلا إِلَهَ إِلا اللَّهُ ، وَاللَّهُ أَكْبَرُ',
      englishTranslation:
          'Glory be to Allah, and praise be to Allah, and there is no deity but Allah, and Allah is most great.',
      virtue:
          'الباقيات الصالحات؛ أحب الكلام إلى الله تعالى وغراس الجنة ونور للمؤمن.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_juwayriyah',
      arabicText:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      englishTranslation:
          'Glory be to Allah and praise Him: as many times as the number of His creation, according to His pleasure, to the weight of His Throne, and the ink of His words.',
      virtue:
          'حديث جويرية رضي الله عنها؛ جوامع التسبيح التي تعدل ساعات طويلة من الذكر المتواصل.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_nakhlah',
      arabicText: 'سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ',
      englishTranslation:
          'Glory be to Allah, the Supreme, and praise be to Him.',
      virtue:
          'قال رسول الله ﷺ: من قال سبحان الله العظيم وبحمده غُرست له نخلة في الجنة.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_malaikah',
      arabicText: 'سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلائِكَةِ وَالرُّوحِ',
      englishTranslation:
          'All-Glorious, All-Holy, Lord of the Angels and the Spirit.',
      virtue:
          'تسبيح الملائكة الكرام؛ كان النبي ﷺ يكثر منه في ركوعه وسجوده تنزيهاً للرب العظيم.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_jabaroot',
      arabicText:
          'سُبْحَانَ ذِي الْعِزَّةِ وَالْجَبَرُوتِ وَالْمَلَكُوتِ وَالْكِبْرِيَاءِ وَالْعَظَمَةِ',
      englishTranslation:
          'Glory be to the Possessor of Might, Omnipotence, the Kingdom, Grandeur, and Majesty.',
      virtue:
          'تسبيح التعظيم الشريف الذي يرسخ هيبة الرب ومحبته في سويداء القلب.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_alquddoos',
      arabicText: 'سُبْحَانَ الْمَلِكِ الْقُدُّوسِ',
      englishTranslation:
          'Glory be to the Sovereign, the Most Holy.',
      virtue:
          'سنة نبوية شريفة بعد الفراغ من صلاة الوتر في جوف الليل.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'yunus_dua',
      arabicText: 'لا إِلَهَ إِلا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      englishTranslation:
          'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
      virtue:
          'دعوة ذي النون في بطن الحوت؛ ما دعا بها مكروب إلا فرج الله عنه وأبدل حزنه فرجاً.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_mujarrad',
      arabicText: 'سُبْحَانَ اللَّهِ',
      englishTranslation: 'Glory be to Allah.',
      virtue:
          'قال ﷺ: أيعجز أحدكم أن يكسب كل يوم ألف حسنة؟ يسبح مائة تسبيحة فيكتب له ألف حسنة أو يحط عنه ألف خطيئة.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_rukoo',
      arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      englishTranslation: 'Glory be to my Lord, the Supreme.',
      virtue:
          'تسبيح الركوع المفروض في كل صلاة؛ إعظاماً وإجلالاً لمقام الرب جل جلاله.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_sujood',
      arabicText: 'سُبْحَانَ رَبِّيَ الأَعْلَى',
      englishTranslation: 'Glory be to my Lord, the Most High.',
      virtue:
          'تسبيح السجود وأقرب ما يكون العبد من ربه وهو ساجد؛ تنزيهاً لعلو شأن الله وقدره.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_istiftah',
      arabicText: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلا إِلَهَ غَيْرُكَ',
      englishTranslation:
          'Glory is to You, O Allah, and praise. Blessed is Your name, exalted is Your majesty, and there is no deity other than You.',
      virtue:
          'دعاء استفتاح الصلاة المأثور في تمجيد الرب وتنزيهه قبل الشروع في التلاوة.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_mizan',
      arabicText: 'سُبْحَانَ اللَّهِ مِلْءَ الْمِيزَانِ، وَمُنْتَهَى الْعِلْمِ، وَمَبْلَغَ الرِّضَا، وَزِنَةَ الْعَرْشِ',
      englishTranslation:
          'Glory be to Allah to the fullness of the Scale, the limit of knowledge, the maximum of pleasure, and the weight of the Throne.',
      virtue:
          'تسبيح عظيم مأثور في سعة التنزيه ومبالغة التمجيد وطلب الرضا التام.',
      category: 'تسبيح وتنزيه',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),

    // ---------------------------------------------------------
    // حمد وشكر
    // ---------------------------------------------------------
    TasbeehDhikr(
      id: 'tahmeed_alhamdulillah',
      arabicText: 'الْحَمْدُ لِلَّهِ',
      englishTranslation: 'All praise is due to Allah.',
      virtue:
          'قال رسول الله ﷺ: والحمد لله تملأ الميزان؛ وأفضل الدعاء الحمد لله.',
      category: 'حمد وشكر',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tahmeed_katheeran',
      arabicText: 'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ',
      englishTranslation:
          'Praise be to Allah, abundant, pure, and blessed praise.',
      virtue:
          'قال النبي ﷺ: رأيت بضعة وثلاثين ملكاً يبتدرونها أيهم يكتبها أولاً لعظم أجرها.',
      category: 'حمد وشكر',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tahmeed_shukr',
      arabicText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ، عَلَى كُلِّ حَالٍ',
      englishTranslation:
          'Praise be to Allah, Lord of all the worlds, in every circumstance.',
      virtue:
          'شكر دائم للرب الرحيم في السراء والضراء، واعتراف بتمام الفضل ولطف القضاء.',
      category: 'حمد وشكر',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tahmeed_quran_alhamd',
      arabicText: 'الْحَمْدُ لِلَّهِ الَّذِي هَدَانَا لِهَٰذَا وَمَا كُنَّا لِنَهْتَدِيَ لَوْلَا أَنْ هَدَانَا اللَّهُ',
      englishTranslation:
          'Praise to Allah, who has guided us to this; and we would never have been guided if Allah had not guided us.',
      virtue:
          'حمد أهل الجنة والشاكرين اعترافاً بفضل الهداية ونعمة الإيمان [الأعراف: ٤٣].',
      category: 'حمد وشكر',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),

    // ---------------------------------------------------------
    // تهليل وتوحيد
    // ---------------------------------------------------------
    TasbeehDhikr(
      id: 'tahleel_wahdah',
      arabicText:
          'لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      englishTranslation:
          'There is no god but Allah alone with no partner; to Him belongs all dominion and praise, and He has power over all things.',
      virtue:
          'كانت له عدل عشر رقاب، وكُتبت له مائة حسنة ومُحيت عنه مائة سيئة وكانت له حرزاً من الشيطان.',
      category: 'تهليل وتوحيد',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tahleel_khayr',
      arabicText: 'لا إِلَهَ إِلا اللَّهُ',
      englishTranslation: 'There is no deity worthy of worship except Allah.',
      virtue:
          'خير ما قلت أنا والنبيون من قبلي، وأعلى شعب الإيمان وعروته الوثقى.',
      category: 'تهليل وتوحيد',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tahleel_ikhlas',
      arabicText: 'أَشْهَدُ أَنْ لا إِلَهَ إِلا اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ',
      englishTranslation:
          'I bear witness that there is no deity except Allah and that Muhammad is His Messenger.',
      virtue:
          'كلمة التوحيد الخالصة التي بها يحيا القلب وتثبت القدم على الصراط المستقيم.',
      category: 'تهليل وتوحيد',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'tahleel_la_mawgood',
      arabicText: 'لا إِلَهَ إِلا اللَّهُ الْمَلِكُ الْحَقُّ الْمُبِينُ',
      englishTranslation:
          'There is no deity except Allah, the Sovereign, the Evident Truth.',
      virtue:
          'تهليل شريف في استشعار ملك الله الحق وتفرده بالخلق والتدبير والملك.',
      category: 'تهليل وتوحيد',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),

    // ---------------------------------------------------------
    // تكبير وتعظيم
    // ---------------------------------------------------------
    TasbeehDhikr(
      id: 'takbeer_kabeera',
      arabicText: 'اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلاً',
      englishTranslation:
          'Allah is Most Great, very great, and praise be to Allah abundantly, and glory be to Allah morning and evening.',
      virtue:
          'قال رسول الله ﷺ: عجبت لها! فُتحت لها أبواب السماء لعظم قدرها عند الله (صحيح مسلم).',
      category: 'تكبير وتعظيم',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'takbeer_mutlaq',
      arabicText: 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، لا إِلَهَ إِلا اللَّهُ، وَاللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ',
      englishTranslation:
          'Allah is Most Great, Allah is Most Great, there is no god but Allah; Allah is Most Great, Allah is Most Great, and to Allah belongs all praise.',
      virtue:
          'صيغة التكبير والتهليل والتحميد المشروعة في الأعياد والأيام الفاضلة ومواسم الطاعة.',
      category: 'تكبير وتعظيم',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),

    // ---------------------------------------------------------
    // حوقلة وتوكل
    // ---------------------------------------------------------
    TasbeehDhikr(
      id: 'hawqalah',
      arabicText: 'لا حَوْلَ وَلا قُوَّةَ إِلا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      englishTranslation:
          'There is no power and no strength except with Allah, the Most High, the Supreme.',
      virtue:
          'كنز من كنوز الجنة وباب عظيم من أبواب تفريج الكروب والتوكل التام على الله.',
      category: 'حوقلة وتوكل',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'hasbuna_allah',
      arabicText: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      englishTranslation:
          'Sufficient for us is Allah, and He is the best Disposer of affairs.',
      virtue:
          'قالها إبراهيم عليه السلام حين أُلقي في النار، وقالها محمد ﷺ حين قيل له إن الناس قد جمعوا لكم [آل عمران: ١٧٣].',
      category: 'حوقلة وتوكل',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),

    // ---------------------------------------------------------
    // صلاة على النبي ﷺ
    // ---------------------------------------------------------
    TasbeehDhikr(
      id: 'salawat',
      arabicText: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      englishTranslation:
          'O Allah, send peace, blessings, and grace upon our Prophet Muhammad.',
      virtue:
          'من صلى عليّ صلاة صلى الله عليه بها عشراً وحُطت عنه عشر خطيئات ورفعت له عشر درجات.',
      category: 'صلاة على النبي',
      defaultTarget: 100,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'salawat_ibrahimiyah',
      arabicText:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      englishTranslation:
          'O Allah, bestow Your favor on Muhammad and the family of Muhammad as You bestowed Your favor on Abraham...',
      virtue:
          'أشرف صيغ الصلاة على النبي المصطفى ﷺ وأعظمها ثواباً وبركة وقربة إلى الله.',
      category: 'صلاة على النبي',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),

    // ---------------------------------------------------------
    // أدعية جامعة
    // ---------------------------------------------------------
    TasbeehDhikr(
      id: 'ya_hayyu_ya_qayyum',
      arabicText:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      englishTranslation:
          'O Ever-Living, O Sustainer, in Your mercy I seek relief. Rectify for me all my affairs and do not leave me to myself for the blink of an eye.',
      virtue:
          'وصية النبي ﷺ لابنته فاطمة رضي الله عنها في الصباح والمساء لكفاية الهموم وصلاح الشأن.',
      category: 'أدعية جامعة',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
    TasbeehDhikr(
      id: 'radeetu_billah',
      arabicText:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا وَرَسُولاً',
      englishTranslation:
          'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad as my Prophet and Messenger.',
      virtue:
          'من قالها حين يصبح وحين يمسي كان حقاً على الله تعالى أن يرضيه يوم القيامة.',
      category: 'أدعية جامعة',
      defaultTarget: 33,
      section: DhikrSection.tasbeeh,
    ),
  ];
}

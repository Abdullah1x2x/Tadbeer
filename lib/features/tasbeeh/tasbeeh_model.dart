/// نموذج بيانات الأذكار والاستغفار والتسبيح للسبحة الإلكترونية.
class TasbeehDhikr {
  final String id;
  final String arabicText;
  final String englishTranslation;
  final String virtue;
  final String category;
  final int defaultTarget;

  /// ينشئ ذكراً أو صيغة استغفار وتسبيح.
  const TasbeehDhikr({
    required this.id,
    required this.arabicText,
    required this.englishTranslation,
    required this.virtue,
    required this.category,
    this.defaultTarget = 33,
  });

  /// باقة الأذكار والصيغ المعتمدة للاستغفار والتسبيح.
  static const List<TasbeehDhikr> defaultDhikrs = [
    TasbeehDhikr(
      id: 'istighfar_1',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
      englishTranslation:
          'I seek the forgiveness of Allah the Almighty and repent to Him.',
      virtue:
          'من لزم الاستغفار جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً ورزقه من حيث لا يحتسب.',
      category: 'استغفار',
      defaultTarget: 100,
    ),
    TasbeehDhikr(
      id: 'istighfar_sayyid',
      arabicText:
          'اللَّهُمَّ أَنْتَ رَبِّي لا إِلَهَ إِلا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لا يَغْفِرُ الذُّنُوبَ إِلا أَنْتَ',
      englishTranslation:
          'O Allah, You are my Lord; none has the right to be worshipped but You. You created me and I am Your servant...',
      virtue:
          'سيد الاستغفار؛ من قالها موقناً بها حين يمسي فمات من ليلته دخل الجنة، وكذلك إذا أصبح.',
      category: 'استغفار',
      defaultTarget: 33,
    ),
    TasbeehDhikr(
      id: 'istighfar_rabbi',
      arabicText: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
      englishTranslation:
          'My Lord, forgive me and accept my repentance, for You are the Accepter of Repentance, the Most Merciful.',
      virtue:
          'كان النبي ﷺ يعد له في المجلس الواحد مائة مرة قبل أن يقوم.',
      category: 'استغفار',
      defaultTarget: 100,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_subhan_bihamdih',
      arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      englishTranslation:
          'Glory be to Allah and Praise Him, Glory be to Allah the Supreme.',
      virtue:
          'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن.',
      category: 'تسبيح',
      defaultTarget: 100,
    ),
    TasbeehDhikr(
      id: 'tasbeeh_baqiyat',
      arabicText:
          'سُبْحَانَ اللَّهِ ، وَالْحَمْدُ لِلَّهِ ، وَلا إِلَهَ إِلا اللَّهُ ، وَاللَّهُ أَكْبَرُ',
      englishTranslation:
          'Glory be to Allah, and praise be to Allah, and there is no deity but Allah, and Allah is most great.',
      virtue:
          'الباقيات الصالحات؛ أحب الكلام إلى الله تعالى وغراس الجنة.',
      category: 'تسبيح',
      defaultTarget: 33,
    ),
    TasbeehDhikr(
      id: 'tahleel_wahdah',
      arabicText:
          'لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      englishTranslation:
          'There is no god but Allah alone with no partner; to Him belongs all dominion and praise, and He has power over all things.',
      virtue:
          'كانت له عدل عشر رقاب، وكُتبت له مائة حسنة ومُحيت عنه مائة سيئة وكانت له حرزاً من الشيطان.',
      category: 'تهليل',
      defaultTarget: 100,
    ),
    TasbeehDhikr(
      id: 'hawqalah',
      arabicText: 'لا حَوْلَ وَلا قُوَّةَ إِلا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      englishTranslation:
          'There is no power and no strength except with Allah, the Most High, the Supreme.',
      virtue:
          'كنز من كنوز الجنة وباب من أبواب تفريج الكروب والتوكل على الله.',
      category: 'حوقلة',
      defaultTarget: 33,
    ),
    TasbeehDhikr(
      id: 'salawat',
      arabicText: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      englishTranslation:
          'O Allah, send peace, blessings, and grace upon our Prophet Muhammad.',
      virtue:
          'من صلى عليّ صلاة صلى الله عليه بها عشراً وحُطت عنه عشر خطيئات ورفعت له عشر درجات.',
      category: 'صلاة على النبي',
      defaultTarget: 100,
    ),
    TasbeehDhikr(
      id: 'yunus_dua',
      arabicText: 'لا إِلَهَ إِلا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      englishTranslation:
          'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
      virtue:
          'دعوة ذي النون إذ دعا وهو في بطن الحوت؛ لم يدع بها رجل مسلم في شيء قط إلا استجاب الله له.',
      category: 'تسبيح ودعاء',
      defaultTarget: 33,
    ),
  ];
}

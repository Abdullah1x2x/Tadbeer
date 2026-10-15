# 📖 دليل إضافة وتوسيع المحتوى لمطوري «تَدْبِير» (Tadbeer Content Extension Guide)

> **دليل عملي ومرجعي شامل للمطورين لإضافة وتعديل المحتوى الإيماني والقرآني والتدبري في تطبيق «تَدْبِير» دون الحاجة للمساس بأكواد الواجهات أو تعديل قواعد البيانات.**

---

## 📌 الفلسفة المعمارية لإضافة المحتوى (Declarative Content Architecture)

صُمم تطبيق «تَدْبِير» وفق معمارية تصريحية مرنة (**Declarative Data Architecture**):
1. **فصل كامل بين المحتوى والواجهات:** كل قسم في التطبيق يستمد بياناته المعتمدة من ملفات Dart مهيأة في مجلدات الميزات (`data/`) أو مستودعاتها.
2. **بدون تعديل في الواجهات أو كروت العرض:** بمجرد إضافة كائن البيانات إلى القائمة المخصصة له، يظهر المحتوى الجديد تلقائياً في شاشات التطبيق، ومحركات البحث السريعة، وأنظمة التصفية، والعدادات التفاعلية.
3. **أمان تام على قاعدة البيانات:** لا تتطلب إضافة المحتوى المعتمد أي تعديلات أو هجرات على قاعدة بيانات المستخدمين (`tadbeer_user_data.db`)، مما يحافظ على استقرار التطبيق وبيانات المستخدمين.

---

## 🧭 جدول الوصول السريع لمصادر البيانات

| نوع المحتوى | الملف المخصص للإضافة | النموذج البرمجي | طريقة وانعكاس العرض في التطبيق |
| :--- | :--- | :--- | :--- |
| **صيغ الاستغفار والتسبيح** | [`lib/features/tasbeeh/data/curated_dhikrs.dart`](../lib/features/tasbeeh/data/curated_dhikrs.dart) | `TasbeehDhikr` | تنضم مباشرة لسبحة الاستغفار والتسبيح، وتعمل مع العداد الذكي التلقائي. |
| **معاني الكلمات وغريب القرآن** | [`lib/features/word_meanings/data/custom_word_meanings.dart`](../lib/features/word_meanings/data/custom_word_meanings.dart) | `CustomWordMeaningConfig` | تندمج تلقائياً مع معجم المصحف (604 صفحة) وتظهر في لوحة الآية والبحث. |
| **الكتب والملازم التدبرية** | [`lib/features/books/curated_books.dart`](../lib/features/books/curated_books.dart) | `BookSectionConfig` و `BookConfig` | تُنشأ بطاقة القسم والملزمة مع قارئ PDF أو قارئ الفصول والبحث. |
| **أدعية القرآن الكريم** | [`lib/features/duas/quran_duas_repository.dart`](../lib/features/duas/quran_duas_repository.dart) | `_DuaCatalogEntry` | ترتبط بالسورة والآية والمصحف الشريف وفهرس الأدعية الموضوعي. |
| **أذكار الصباح والمساء** | [`lib/features/duas/adhkar_repository.dart`](../lib/features/duas/adhkar_repository.dart) | `AdhkarItem` | تظهر في شاشة أذكار الصباح والمساء مع العداد الرقمي التفاعلي. |
| **أدعية أهل البيت والتراث** | [`lib/features/duas/ahlulbayt_duas_repository.dart`](../lib/features/duas/ahlulbayt_duas_repository.dart) | `AhlulbaytDua` | تظهر في فهرس أدعية أهل البيت مع قارئ النصوص وتكبير الخط والنسخ. |
| **أدعية السنة وجوامع الدعاء** | [`lib/features/duas/sunnah_duas_repository.dart`](../lib/features/duas/sunnah_duas_repository.dart) | `GeneralDuaItem` | تظهر في بطاقات الأدعية المأثورة وجوامع الرجاء مع تصنيف المناسبة. |
| **مسارات وروابط الآيات** | [`lib/features/ayah_links/curated_pathways.dart`](../lib/features/ayah_links/curated_pathways.dart) | `CuratedPathway` | تظهر في شبكة روابط الآيات الموضوعية مع إمكانية استيرادها للمستخدم. |

---

## 1. صيغ الاستغفار والتسبيح (Tasbeeh & Istighfar)

- **الملف:** `lib/features/tasbeeh/data/curated_dhikrs.dart`
- **القائمة المستهدفة:** `curatedDhikrs`

### كيفية الإضافة:
أضف عنصراً جديداً باستخدام `TasbeehDhikr`:

```dart
// مثال: إضافة صيغة استغفار جديدة
TasbeehDhikr(
  id: 'istighfar_custom_1',
  arabicText: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لا إِلَهَ إِلا هُوَ الرَّحْمَنُ الرَّحِيمُ وَأَتُوبُ إِلَيْهِ',
  englishTranslation: 'I seek forgiveness from Allah the Almighty...',
  virtue: 'فضل عظيم مأثور في تفريج الكرب وسعة الرزق واستجابة الدعاء.',
  category: 'استغفار', // التصنيف المعروض في رأس البطاقة
  defaultTarget: 70,   // الهدف المبدئي للعداد (33 أو 70 أو 100)
  section: DhikrSection.istighfar, // DhikrSection.istighfar أو DhikrSection.tasbeeh
  // paceSeconds: 2.5, // (اختياري) لتحديد وتيرة زمنية مخصصة للعد التلقائي؛ إن حُذف يُحسب تلقائياً بذكاء
),

// مثال: إضافة صيغة تسبيح وتحميد جديدة
TasbeehDhikr(
  id: 'tasbeeh_custom_1',
  arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
  englishTranslation: 'Glory be to Allah and praise be to Him, Glory be to Allah the Almighty.',
  virtue: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن.',
  category: 'تسبيح',
  defaultTarget: 33,
  section: DhikrSection.tasbeeh,
),
```

> **ملاحظة ذكية حول ميزة العد التلقائي (Smart Auto-Pacing):**  
> إذا لم تُحدد `paceSeconds`، يقوم التطبيق تلقائياً بحساب الإيقاع الهادئ المناسب للذكر بحسب عدد كلماته العربية (`800ms + words * 320ms`)، مما يريح المطور من ضبط التوقيت يدوياً!

---

## 2. معاني الكلمات وغريب القرآن (Word Meanings)

- **الملف:** `lib/features/word_meanings/data/custom_word_meanings.dart`
- **القائمة المستهدفة:** `customWordMeanings`

بدلاً من التعامل مع ملف `word_meanings.json` الضخم وتعديله، يمكنك إضافة أي لفظة قرآنية غريبة أو تصحيح معناها مباشرة عبر الكود:

```dart
CustomWordMeaningConfig(
  surah: 1, // رقم السورة (من 1 إلى 114)
  ayah: 2,  // رقم الآية داخل السورة
  word: 'الْحَمْدُ', // اللفظة القرآنية كما وردت في الآية الكريمة
  meaning: 'الثناء بالجميل على جهة التبجيل والتعظيم لله عز وجل وحده.', // البيان الميسر
  sourceName: 'المعجم الوسيط', // (اختياري) اسم المعجم أو المرجع اللغوي
),
```

> **الاندماج التلقائي:**  
> يقوم التطبيق تلقائياً بمطابقة رقم السورة والآية مع رقم صفحة المصحف الشريف (من 1 إلى 604)، وتظهر الكلمة فوراً في:
> 1. شاشة معاني غريب القرآن مع محرك البحث الصرفي.
> 2. لوحة المعاني المنبثقة من أسفل المصحف عند النقر على الآية الكريمة.

---

## 3. الكتب والملازم والبحوث التدبرية (Books & Malazem)

- **الملف:** `lib/features/books/curated_books.dart`
- **القائمة المستهدفة:** `curatedBookSections`

يدعم نظام الكتب والملازم ثلاثة أنماط متباينة تلائم كافة أنواع المحتوى:

### النمط الأول: إضافة ملزمة أو كتاب بملف PDF مرفق
1. ضع ملف الـ PDF داخل مجلد: `assets/books/` (مثال: `assets/books/tafseer_fatiha.pdf`).
2. أضفه في قائمة `curatedBookSections`:

```dart
BookSectionConfig(
  name: 'ملازم التدبر',
  description: 'ملازم دورات التدبر وتفسير الآيات',
  icon: Icons.folder_special_rounded,
  color: Color(0xFF2E6F4D),
  seriesFilterList: ['سلسلة مدارسة السور', 'سلسلة المفاهيم'],
  books: [
    BookConfig(
      id: 'malzamah_fatiha',
      title: 'ملزمة مدارسة سورة الفاتحة',
      subtitle: 'دليل منهجي في تدبر السبع المثاني',
      author: 'مركز تدبر',
      assetPath: 'assets/books/tafseer_fatiha.pdf',
      estimatedMinutes: 25,
      badgeText: 'ملزمة PDF',
    ),
  ],
)
```

### النمط الثاني: إضافة ملزمة بملف نصي (.txt أو .md)
```dart
BookConfig(
  id: 'notes_kahf',
  title: 'لطائف سورة الكهف',
  subtitle: 'وقفات إيمانية وتدبرية',
  author: 'أهل التدبر',
  assetPath: 'assets/books/notes_kahf.txt',
)
```

### النمط الثالث: إضافة كتاب بفصول ومباحث نصية برمجية
```dart
BookConfig(
  id: 'custom_book_reflection',
  title: 'قواعد حسان في تدبر القرآن',
  subtitle: 'أصول لفهم كلام الرحمن',
  author: 'العلامة السعدي',
  chapters: [
    BookChapter(
      title: 'المبحث الأول: إخلاص النية في قراءة القرآن',
      summary: 'أثر الإخلاص في فتح مغاليق الفهم',
      content: '''نص المبحث يكتب هنا بكل سهولة وبكامل التنسيق...''',
    ),
    BookChapter(
      title: 'المبحث الثاني: جمع القلب عند التلاوة',
      content: '''نص المبحث الثاني...''',
    ),
  ],
)
```

---

## 4. الأدعية والأذكار (Duas & Adhkar)

### أ. أدعية القرآن الكريم الـ 88 الموثقة
- **الملف:** `lib/features/duas/quran_duas_repository.dart`
- **القائمة:** `_catalog`

```dart
_DuaCatalogEntry(
  id: 89,
  surahNumber: 3,
  surahName: 'آل عمران',
  ayahNumber: 8,
  ayahEndNumber: 8,
  ayahDisplay: '8',
  title: 'طلب الثبات بعد الهداية',
  duaText: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
  defaultPage: 50,
  category: 'الهداية والثبات',
  isDirectDua: true,
  orderInSurah: 1,
  verses: [
    QuranDuaVerse(
      ayahNumber: 8,
      text: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
    ),
  ],
)
```

### ب. أذكار الصباح والمساء التفاعلية
- **الملف:** `lib/features/duas/adhkar_repository.dart`
- **القائمتان:** `morningAdhkar` (للصباح) و `eveningAdhkar` (للمساء)

```dart
AdhkarItem(
  id: 'm_custom_dhikr',
  category: AdhkarCategory.morning,
  text: 'أَصْبَحْنَا عَلَى فِطْرَةِ الإِسْلامِ، وَعَلَى كَلِمَةِ الإِخْلاصِ...',
  repeatCount: 1, // عدد التكرار المطلوب للذكر
  virtue: 'فضل الذكر وثوابه المبارك...',
  source: 'مسند الإمام أحمد',
)
```

### ج. أدعية أهل البيت (عليهم السلام) والصحيفة السجادية
- **الملف:** `lib/features/duas/ahlulbayt_duas_repository.dart`
- **القائمة:** `defaultDuas`

```dart
AhlulbaytDua(
  id: 'dua_tawbah_sajjad',
  title: 'دعاء التوبة وطلب المغفرة',
  attributedTo: 'الإمام زين العابدين علي بن الحسين (عليهما السلام)',
  category: 'التوبة والمغفرة',
  summary: 'من أدعية الصحيفة السجادية الجامعة في الانكسار والرجوع إلى الله.',
  content: '''اللَّهُمَّ يَا مَنْ لا يَصِفُهُ نَعْتُ الْوَاصِفِينَ...''',
)
```

### د. أدعية السنة النبوية وجوامع الدعاء والرجاء
- **الملف:** `lib/features/duas/sunnah_duas_repository.dart`
- **القائمتان:** `sunnahDuas` (للأدعية النبوية) و `jawamiDuas` (لجوامع الدعاء)

```dart
GeneralDuaItem(
  id: 'sunnah_custom_afw',
  title: 'دعاء العفو والمغفرة',
  text: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي.',
  occasion: 'في ليلة القدر والعشر الأواخر وسائر الأيام',
  source: 'جامع الترمذي',
  isSunnah: true,
)
```

---

## 5. مسارات وروابط الآيات التدبرية (Ayah Links & Pathways)

- **الملف:** `lib/features/ayah_links/curated_pathways.dart`
- **القائمة المستهدفة:** `CuratedPathwaysRegistry.pathways`

تتيح هذه الميزة جمع آيات من سور مختلفة تتناول موضوعاً قرآنياً واحداً وإرفاق ملاحظة تدبرية ملهمة لكل آية:

```dart
CuratedPathway(
  id: 'pathway_sabr_nasr',
  title: 'الصبر مفتاح النصر والفرج',
  description: 'تأملات قرآنية في اقتران الصبر بالبشارة الإلهية ومعية الله للمؤمنين.',
  category: 'أخلاق وتزكية',
  verses: [
    CuratedPathwayVerse(
      surah: 2,
      ayah: 153,
      note: 'تأمل في قوله تعالى: ﴿يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ﴾ وعظمة معية الله.',
    ),
    CuratedPathwayVerse(
      surah: 3,
      ayah: 200,
      note: 'تأمل في التدرج القرآني: ﴿اصْبِرُوا وَصَابِرُوا وَرَابِطُوا وَاتَّقُوا اللَّهَ لَعَلَّكُمْ تُفْلِحُونَ﴾.',
    ),
  ],
)
```

---

## ✅ خطوات التحقق والفحص بعد إضافة أي محتوى

بعد إضافة أو تعديل أي محتوى، افتح الطرفية وشغّل الأوامر التالية لضمان سلامة الكود بنسبة 100%:

```bash
# 1. التحقق من سلامة الأكواد وعدم وجود أي تحذيرات أو أخطاء
dart analyze

# 2. تشغيل كافة الاختبارات الآلية للتأكد من عدم حدوث أي تراجع
flutter test
```

إذا ظهرت لك الرسالة:
`No issues found!` و `All tests passed!`
فإن المحتوى جاهز تماماً للاعتماد والدمج!

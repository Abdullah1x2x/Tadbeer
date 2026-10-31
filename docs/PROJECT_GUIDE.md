# دليل مشروع تَدْبِير من الصفر

هذا الدليل مكتوب لمن يريد فهم المشروع وتعديل أي تفصيلة فيه بنفسه، حتى لو كانت هذه أول مرة يفتحه. اقرأ الأقسام 1 إلى 5 مرة واحدة، ثم استخدم [قسم «أريد أن أغيّر...»](#7-أريد-أن-أغيّر) كمرجع يومي.

## الفهرس

1. [ما هو المشروع](#1-ما-هو-المشروع)
2. [تجهيز جهازك من الصفر](#2-تجهيز-جهازك-من-الصفر)
3. [الأوامر اليومية](#3-الأوامر-اليومية)
4. [كيف يعمل التطبيق](#4-كيف-يعمل-التطبيق)
5. [قواعد المشروع](#5-قواعد-المشروع)
6. [خريطة كل ملفات المشروع](#6-خريطة-كل-ملفات-المشروع)
7. [أريد أن أغيّر...](#7-أريد-أن-أغيّر)
8. [الاختبارات](#8-الاختبارات)
9. [إصدار نسخة جديدة](#9-إصدار-نسخة-جديدة)
10. [مشاكل شائعة وحلولها](#10-مشاكل-شائعة-وحلولها)

---

## 1. ما هو المشروع

تطبيق Flutter للقراءة والتدبر. يعمل كله على الجهاز، ولا يحتاج الإنترنت إلا للتلاوة.

| المعلومة | القيمة |
| --- | --- |
| اللغة والإطار | Dart وFlutter 3.47.6 |
| المنصة الأساسية | Android؛ والكود يدعم iOS وسطح المكتب لكنها لم تُجرَّب للإصدار |
| معرّف التطبيق | `com.tadbeer.app` |
| التخزين | SQLite مع ملف JSON احتياطي على الجهاز |
| إدارة الحالة | أدوات Flutter نفسها (`ChangeNotifier` و`ValueNotifier`)، بلا مكتبات حالة |
| الترجمة | العربية هي الأساس، ومعها الإنجليزية |

## 2. تجهيز جهازك من الصفر

هذه الخطوات على Fedora، وهي متشابهة في بقية توزيعات Linux.

**1. ثبّت الأدوات الأساسية:**

```bash
sudo dnf install git curl unzip xz java-17-openjdk-devel clang cmake ninja-build gtk3-devel
```

**2. ثبّت Flutter بالإصدار نفسه المستخدم في CI:**

```bash
git clone -b stable https://github.com/flutter/flutter.git ~/Development/flutter
```

```bash
cd ~/Development/flutter && git checkout 3.47.6
```

أضف هذا السطر إلى `~/.bashrc`، ثم افتح طرفية جديدة:

```bash
export PATH="$HOME/Development/flutter/bin:$PATH"
```

**3. ثبّت Android Studio**، ومن SDK Manager ثبّت:
- Android SDK Platform 37.
- NDK الإصدار `28.2.13676358`.
- Android SDK Command-line Tools.

ثم اقبل التراخيص:

```bash
flutter doctor --android-licenses
```

**4. أنشئ محاكياً** من Device Manager في Android Studio. وعلى أجهزة Intel، إن لم يعمل كرت الشاشة، شغّله هكذا:

```bash
MESA_VK_DEVICE_SELECT="8086:a788!" ~/Android/Sdk/emulator/emulator -avd Pixel_7_API37 -gpu host -no-snapshot-load
```

استبدل `8086:a788` برقم كرت شاشتك، و`Pixel_7_API37` باسم محاكيك.

**5. حمّل المشروع وشغّله:**

```bash
git clone https://github.com/Abdullah1x2x/Tadbeer.git
```

```bash
cd Tadbeer && flutter pub get && flutter run
```

تأكد من سلامة التجهيز بالأمر `flutter doctor`.

## 3. الأوامر اليومية

| ماذا تريد | الأمر |
| --- | --- |
| تشغيل التطبيق | `flutter run` |
| فحص الكود | `flutter analyze` |
| تنسيق الكود | `dart format lib test` |
| كل الاختبارات | `flutter test` |
| اختبار ملف واحد | `flutter test test/quran/reading_position_test.dart` |
| توليد الترجمة بعد تعديل ARB | `flutter gen-l10n` |
| نسخة لهاتف حديث | `flutter build apk --release --split-per-abi` |
| حزمة متجر | `flutter build appbundle --release` |
| قياس الأداء | `flutter run --profile` |

ملاحظتان مهمتان:
- وضع `flutter run` العادي (debug) بطيء بطبيعته، فلا تحكم منه على السلاسة. استخدم `--profile` أو `--release`.
- أثناء `flutter run` اضغط `r` لتطبيق تعديلك فوراً، و`R` لإعادة تشغيل التطبيق.

بعد البناء تجد الملف في `build/app/outputs/flutter-apk/`. ولأغلب الهواتف استخدم `app-arm64-v8a-release.apk`.

## 4. كيف يعمل التطبيق

### 4.1 الطبقات

الكود في `lib/` أربع طبقات، والاعتماد يسير في اتجاه واحد:

```text
features  ←  الشاشات وكل ميزة في مجلدها
   ↓
data      ←  نماذج البيانات، والقرآن، والتخزين
   ↓
core      ←  الألوان والأزرار والحركة وأدوات النص
```

ومجلد `app/` يربط الطبقات معاً. القاعدة: `core` لا تعرف `data`، و`data` لا تعرف `features`.

### 4.2 من لحظة فتح التطبيق

1. يبدأ `lib/main.dart` ويستدعي `bootstrap()`.
2. يقوم `lib/app/bootstrap.dart` بالتالي بالترتيب:
   - تسجيل التراخيص.
   - فتح بيانات القارئ `UserDataStore.instance.init()`.
   - تحميل القرآن `QuranRepository.instance.init()`.
   - تجهيز التذكيرات وجدولتها.
   - ربط الودجت والسلسلة وتذكير الورد.
   - تجهيز التلاوة في الخلفية.
3. يعرض `TadbeerApp` في `lib/app/app.dart` الثيم واللغة، ويختار أول شاشة.
4. **في أول تشغيل:** الاسم، ثم اختيار المظهر، ثم الجولة، ثم آية الترحيب، ثم الرئيسية.
5. يعرض `MainShell` في `lib/app/main_shell.dart` التبويبات الخمسة: الرئيسية، والمصحف، والاستغفار، والأدعية، والمزيد.
6. عند أول دخول للرئيسية يظهر طلب الأذونات، ثم الدليل التفاعلي.

### 4.3 كيف تُحفظ بيانات القارئ

مثال: كتب القارئ ملاحظة وضغط حفظ.

```text
الشاشة → UserDataStore.saveNote → notifyListeners → الشاشات تتحدث
                                → UserDatabase (SQLite)
                                → saveToDisk (ملف JSON احتياطي)
```

- `UserDataStore` هو المرجع الوحيد للبيانات، فتقرأ منه كل الشاشات وتكتب عبره.
- كوده موزّع على أقسام في `lib/data/storage/`: `notes_section.dart` و`journey_section.dart` وغيرها.
- الميزات الصغيرة تحفظ حالتها في `saveFeatureState(key, map)` بدل إنشاء جدول جديد، مثل الحفظ والشروحات والدليل التفاعلي.

### 4.4 كيف تُرسم صفحة المصحف

1. `QuranScreen` فيها `PageView` من 604 صفحات.
2. كل صفحة `QuranPageView`، وفي نمط المدينة تعرض `QcfPageBody`.
3. لكل صفحة خط خاص `assets/fonts/qcf/pN.ttf`، يُحمَّل عند الحاجة عبر `QcfFonts`.
4. `QcfLayout` يقرأ `qcf_v1_layout.json.gz`، وفيه كلمات كل سطر ورموزها.
5. أثناء السحب تتحول الصفحة إلى صورة عبر `SnapshotWidget`، لأن رسم الحروف ثقيل. وعند التوقف تعود نصاً حياً.
6. عند الانتقال لا يُحفظ شيء فوراً، بل بعد نصف ثانية من استقرار الصفحة (`_saveAfterSettling`).

### 4.5 كيف تعمل الترجمة

النصوص ليست في الشاشات. المسار كالتالي:

```text
lib/l10n/app_ar.arb و app_en.arb
        ↓  flutter gen-l10n
lib/l10n/app_localizations*.dart  (ملفات مولّدة، لا تعدّلها)
        ↓
lib/app/localization.dart  (AppStrings)
        ↓
context.l10n.اسم_النص  (في الشاشات)
```

## 5. قواعد المشروع

- **النص القرآني لا يُعدَّل أبداً**، فهو ملف `assets/quran/quran_data.json`.
- **لا تكتب نصاً في الشاشة مباشرة:** ضعه في ARB.
- **لا تعدّل** `lib/l10n/app_localizations*.dart` يدوياً.
- **لا ترفع** `android/key.properties` ولا `tadbeer-upload.jks`؛ فهما مفاتيح توقيع التطبيق، وفقدانهما يمنع تحديث النسخ المنشورة. احتفظ بنسخة آمنة منهما خارج الجهاز.
- **التعليقات** بالعربية، قصيرة، وتشرح السبب. والتعليق التوثيقي يبدأ بـ `///`.
- قبل كل commit شغّل: `flutter analyze` ثم `flutter test`.

## 6. خريطة كل ملفات المشروع

### 6.1 جذر المشروع

| الملف أو المجلد | وظيفته |
| --- | --- |
| `pubspec.yaml` | اسم التطبيق وإصداره ومكتباته وأصوله |
| `pubspec.lock` | الإصدارات المثبتة للمكتبات |
| `analysis_options.yaml` | قواعد فحص الكود |
| `l10n.yaml` | إعداد توليد الترجمة |
| `lib/` | كود التطبيق |
| `test/` | الاختبارات |
| `assets/` | الخطوط والبيانات والكتب والأيقونات |
| `android/` و`ios/` | كود المنصتين وإعداداتهما |
| `linux/` و`macos/` و`windows/` و`web/` | ملفات المنصات الأخرى |
| `tool/` | أدوات بناء البيانات، ولا تدخل في التطبيق |
| `docs/` | الموقع والأدلة |
| `fastlane/` | نصوص صفحة المتجر |
| `.github/workflows/` | الفحص الآلي `ci.yml` والإصدار `release.yml` |
| `README.md` و`README.ar.md` | صفحة المشروع |
| `DEVELOPMENT_GUIDE.md` و`DEVELOPMENT_GUIDE.ar.md` | دليل التطوير المختصر |
| `CHANGELOG.md` | سجل التغييرات |
| `ATTRIBUTION.md` و`THIRD_PARTY_NOTICES.md` | المصادر والتراخيص |
| `PRIVACY_POLICY.md` | سياسة الخصوصية |
| `LICENSE` | رخصة الكود |

### 6.2 الأصول `assets/`

| المسار | المحتوى |
| --- | --- |
| `assets/quran/quran_data.json` | نص القرآن والسور والصفحات، ولا يُعدَّل |
| `assets/quran/word_meanings.json` | معاني الكلمات |
| `assets/quran/qcf_v1_layout.json.gz` | تخطيط أسطر مصحف المدينة |
| `assets/fonts/qcf/` | 604 خطوط، خط لكل صفحة |
| `assets/fonts/` | خطوط النص والواجهة، ونص رخصتها `OFL.txt` |
| `assets/books/` | ملفات PDF وفهرس `books_catalog.json` |
| `assets/books/malazem/` | الملازم |
| `assets/icons/` | شعار التطبيق |

### 6.3 Android

| الملف | وظيفته |
| --- | --- |
| `android/app/build.gradle.kts` | معرّف التطبيق والتوقيع والإصدارات |
| `android/app/src/main/AndroidManifest.xml` | الاسم والأذونات والخدمات |
| `android/app/src/main/kotlin/com/tadbeer/app/MainActivity.kt` | نقطة بداية Android |
| `android/app/src/main/kotlin/com/tadbeer/app/TadbeerWidgetProvider.kt` | ودجت الشاشة الرئيسية |
| `android/app/src/main/res/layout/` | تصميم الودجت |
| `android/app/src/main/res/font/` | خط معاينة الودجت |
| `android/key.properties` | كلمات سر التوقيع، غير مرفوع إلى Git |

### 6.4 الأدوات `tool/`

| الملف | وظيفته |
| --- | --- |
| `tool/build_quran_dataset.dart` | بناء `quran_data.json` |
| `tool/qcf/build_layout.py` | بناء تخطيط المصحف وجلب خطوطه |
| `tool/build_lexicon_meanings.py` و`process_quran_meanings.py` و`refine_and_split_meanings.py` | معالجة معاني الكلمات |
| `tool/generate_heritage_pdfs.dart` | توليد ملفات PDF للكتب التراثية |
| `tool/brand/make_logo.py` | توليد الشعار |
| `tool/widget/make_glass.py` | توليد خلفية الودجت |

### 6.5 كود التطبيق `lib/`

- `lib/main.dart`: نقطة البداية.
- `lib/l10n/`: ملفات الترجمة، و`app_ar.arb` و`app_en.arb` فقط هما للتعديل.

#### `lib/app`: ربط التطبيق: الإقلاع والتبويبات والترجمة

| الملف | الوظيفة |
| --- | --- |
| `app.dart` | يفتح الشاشات من خارج شجرة الواجهة، كالنقر على إشعار. |
| `bootstrap.dart` | تهيئة التطبيق قبل أول إطار: البيانات، والتذكيرات، والتلاوة في الخلفية. |
| `licenses.dart` | تراخيص المحتوى المضمّن الذي ليس كوداً: النص القرآني والمعاني والخطوط. |
| `localization.dart` | لغات الواجهة مع اتجاه النص لكل منها. |
| `main_shell.dart` | الهيكل الرئيسي: الأقسام متجاورة خلف شريط التنقل السفلي. |

#### `lib/core/design_system`: عناصر الواجهة المشتركة

| الملف | الوظيفة |
| --- | --- |
| `app_icons.dart` | كل أيقونات التطبيق، من مجموعة Phosphor. |
| `app_logo.dart` | شعار التطبيق بإطاره وظله، بنفس الشكل في كل مكان وكل ثيم. |
| `app_menu.dart` | قوائم التطبيق المنبثقة وأيقونتها. |
| `app_search_field.dart` | حقل البحث أعلى القوائم، بزر يمسح النص. |
| `app_select.dart` | حقل الاختيار الموحّد: يعرض القيمة الحالية ويفتح الخيارات في لوحة سفلية. |
| `app_tokens.dart` | قيم التصميم الموحّدة: المسافات والانحناءات وسماكة الإطارات والظلال. |
| `design_system.dart` | نظام تصميم تدبير: يصدّر الرموز والبطاقات والأزرار والشارات وأدوات الحركة. |
| `empty_state.dart` | حالة فارغة موحّدة: أيقونة، وعنوان، وسطر يشرح كيف تبدأ، وزر إجراء اختياري. |
| `floating_nav_bar.dart` | عنصر في شريط التنقل العائم. |
| `futuristic_badge.dart` | شارة صغيرة للحالات والوسوم والعدادات، بإطار ولون خلفية خافت ونقطة اختيارية. |
| `futuristic_button.dart` | زر التطبيق: ممتلئ للإجراء الأساسي، أو مفرّغ للثانوي، مع حالة تحميل. |
| `futuristic_card.dart` | بطاقة التطبيق: سطح بتدرج خفيف وإطار وظل، تنكمش قليلاً عند الضغط. |
| `ornaments.dart` | نجمة ثمانية (مربعان متداخلان) مركزها c. |

#### `lib/core/motion`: الحركة

| الملف | الوظيفة |
| --- | --- |
| `app_motion.dart` | قيم الحركة الموحّدة: المدد والمنحنيات، واحترام "تقليل الحركة"، وانتقال الحوارات. |

#### `lib/core/theme`: الألوان والثيمات

| الملف | الوظيفة |
| --- | --- |
| `theme.dart` | ثيمات الألوان التي يختار منها القارئ؛ الكحلي هو الافتراضي. |

#### `lib/core/utils`: أدوات النص العربي

| الملف | الوظيفة |
| --- | --- |
| `arabic_root_search_helper.dart` | البحث بالجذر: `جذر:صبر` يجد كل الصيغ المشتقة (صابر، اصبر، اصطبر، الصابرين…). |
| `arabic_search_normalizer.dart` | تطبيع النص العربي للبحث فقط: النص العثماني نفسه لا يُمس، والتطبيع يُطبّق عند المطابقة ليجد البحث الآية بأي طريقة كتابة. |
| `text_direction.dart` | اتجاه text من حروفه نفسها، فيبقى العربي من اليمين ولو كانت الواجهة إنجليزية، والعكس. |

#### `lib/data/models`: نماذج بيانات القارئ

| الملف | الوظيفة |
| --- | --- |
| `ayah_link_model.dart` | موضع عقدة على لوحة شبكة الروابط. |
| `bookmark_model.dart` | فاصل على آية، يعود منه القارئ إلى موضعها بنقرة من شاشة الفواصل. |
| `highlight_model.dart` | تظليل آية بأحد الألوان الأربعة، دون المساس بالنص القرآني. |
| `note_model.dart` | نوع الخاطرة. |
| `reading_journey.dart` | رحلة القراءة: خطة الختمة وسجل الصفحات المقروءة يومياً. |
| `reminder_model.dart` | تكرار التذكير. |
| `tadbeer_model.dart` | وقفة تدبر للقارئ عند آية: إجاباته عن الأسئلة الأربعة، وما التزم به. |
| `user_settings_model.dart` | أحجام خط المصحف الثلاثة: صغير 15.5، ومتوسط 18.5 (يطابق مصحف المدينة)، وكبير 22. |

#### `lib/data/quran`: بيانات القرآن

| الملف | الوظيفة |
| --- | --- |
| `custom_word_meanings.dart` | معنى كلمة يضيفه المطور. |
| `quran_models.dart` | سورة من سور القرآن الـ ١١٤. |
| `quran_repository.dart` | نص القرآن وبيانات المصحف، للقراءة فقط. |

#### `lib/data/storage`: تخزين بيانات القارئ

| الملف | الوظيفة |
| --- | --- |
| `ayah_links_section.dart` | قسم روابط الآيات. |
| `bookmarks_section.dart` | قسم الفواصل. |
| `highlights_section.dart` | قسم التظليل. |
| `journey_section.dart` | قسم رحلة القراءة والختمة. |
| `notes_section.dart` | قسم الخواطر. |
| `reading_position_section.dart` | قسم موضع القراءة. |
| `reminders_section.dart` | قسم التذكيرات. |
| `settings_section.dart` | قسم الإعدادات. |
| `store_state.dart` | ما يطلبه المخزن من مجدول التذكيرات حين تتغير التذكيرات. |
| `tadbeer_section.dart` | قسم وقفات التدبر. |
| `user_data_store.dart` | مخزن بيانات القارئ على الجهاز، ومصدرها الوحيد في التطبيق. |
| `user_database.dart` | نوع مشكلة قاعدة البيانات. |

#### `lib/features/audio`: التلاوة والتنزيل

| الملف | الوظيفة |
| --- | --- |
| `audio_bar.dart` | شريط التلاوة في المصحف: الآية المسموعة وأزرار التحكم. |
| `audio_downloads.dart` | تنزيل التلاوات للاستماع دون إنترنت، سورةً سورة لكل قارئ. |
| `downloads_screen.dart` | تنزيل التلاوات: كل سورة بصوت القارئ المختار، تُنزّل أو تُحذف. |
| `quran_audio.dart` | تشغيل التلاوة آيةً آية: من أي آية، مع التكرار ووقفة التدبر. |
| `recitation_handler.dart` | التلاوة خارج التطبيق: إشعار التشغيل وأزرار شاشة القفل. |
| `reciters.dart` | قرّاء التلاوة المسموعة: ملف لكل آية من شبكة Islamic Network. |

#### `lib/features/ayah_links`: روابط الآيات

| الملف | الوظيفة |
| --- | --- |
| `data/ayah_link_repository.dart` | روابط الآيات: يربط القارئ آيات من سور مختلفة بموضوع واحد. |
| `data/curated_pathways.dart` | آية في مسار مقترح، مع فائدتها التدبرية. |
| `screens/ayah_link_detail_screen.dart` | تفاصيل رابط: بعرض الشبكة أو القائمة المرتبة. |
| `screens/ayah_links_screen.dart` | روابط الآيات للقارئ: بحث وإنشاء واستيراد. |
| `widgets/add_verse_to_link_dialog.dart` | إضافة آية إلى رابط. |
| `widgets/ayah_link_edit_dialogs.dart` | حوارات تعديل الرابط وحذف عناصره، تشترك فيها الشبكة والقائمة. |
| `widgets/ayah_link_network_nodes.dart` | يرسم منحنيات ناعمة من العقدة المركزية إلى العقد الفرعية. |
| `widgets/ayah_link_network_view.dart` | شبكة الرابط: عقدة المحور في المركز والآيات حولها. |
| `widgets/ayah_link_ordered_view.dart` | قائمة الرابط المرتبة، لقراءة الآيات المترابطة بتتابع هادئ. |
| `widgets/ayah_link_picker_dialog.dart` | لوحة لإضافة آية من المصحف إلى رابط موجود أو جديد. |
| `widgets/create_link_dialog.dart` | حوار إنشاء رابط أو تعديله: العنوان مطلوب، والوصف اختياري. |

#### `lib/features/backup`: النسخ الاحتياطي المشفر

| الملف | الوظيفة |
| --- | --- |
| `backup_crypto_service.dart` | نتيجة تصدير نسخة احتياطية أو استعادتها. |
| `backup_screen.dart` | إنشاء النسخ الاحتياطية المشفرة واستعادتها. |

#### `lib/features/bookmarks`: الفواصل

| الملف | الوظيفة |
| --- | --- |
| `bookmarks_screen.dart` | الفواصل، للانتقال السريع إلى مواضعها، مع بحث فوري باسم السورة أو رقم الآية أو نصها. |

#### `lib/features/books`: الكتب والملازم

| الملف | الوظيفة |
| --- | --- |
| `data/book_model.dart` | فصل أو مبحث في كتاب أو ملزمة. |
| `data/book_repository.dart` | أقسام المكتبة وكتبها، محفوظة على الجهاز. |
| `data/curated_books.dart` | قسم يعرّفه المطور في الكود. |
| `data/heritage_data.dart` | نصوص الكتب التراثية. |
| `data/malazem_data.dart` | ملازم السيد حسين بدر الدين الحوثي ودروسه (91 ملزمة). |
| `data/sahifah_sajjadiyah_data.dart` | نص الصحيفة السجادية الكامل. |
| `screens/book_reader_screen.dart` | قراءة الكتب والملازم: فصول، أو نص، أو PDF. |
| `screens/book_reader_views.dart` | عروض القارئ: الفصول والنص وقائمة الفصول. |
| `screens/book_section_screen.dart` | كتب قسم واحد، مع تصفية بالسلسلة وبحث داخل القسم. |
| `screens/books_screen.dart` | دليل أقسام المكتبة: بطاقة لكل قسم، تفتح كتبه. |

#### `lib/features/continue`: المتابعة من حيث توقفت

| الملف | الوظيفة |
| --- | --- |
| `continue_card.dart` | بطاقة «أكمل من حيث توقفت»: آخر الأذكار والكتاب والحفظ والمسار في مكان واحد. |
| `last_activity.dart` | نوع النشاط الذي يُستكمل. |

#### `lib/features/daily`: آية للتدبر

| الملف | الوظيفة |
| --- | --- |
| `ayah_of_day_card.dart` | آيات للتدبّر: القائمة المشتركة بين بطاقة الرئيسية والودجت. |

#### `lib/features/duas`: الأدعية والأذكار

| الملف | الوظيفة |
| --- | --- |
| `data/adhkar_reminders.dart` | تذكيرات أذكار الصباح والمساء: تنبيه يومي يفتح الأذكار مباشرة. |
| `data/adhkar_repository.dart` | فئة الذكر. |
| `data/ahlulbayt_duas_repository.dart` | دعاء مأثور عن أهل البيت (عليهم السلام). |
| `data/quran_dua_model.dart` | آية من آيات دعاء قرآني. |
| `data/quran_duas_repository.dart` | مدخل في فهرس الأدعية القرآنية. |
| `data/sunnah_duas_repository.dart` | دعاء نبوي أو جامع. |
| `screens/ahlulbayt_dua_reader_screen.dart` | قراءة دعاء مأثور، مع ضبط حجم الخط ونسخ النص. |
| `screens/ahlulbayt_duas_screen.dart` | أدعية أهل البيت (عليهم السلام) والصحيفة السجادية، مع بحث وتصنيفات. |
| `screens/duas_screen.dart` | تبويب الأدعية: أدعية القرآن، وأذكار الصباح والمساء، وأدعية أهل البيت، وأدعية السنة، وجوامع الدعاء. |
| `screens/general_duas_list_screen.dart` | أدعية السنة النبوية أو جوامع الدعاء، مع بحث. |
| `screens/morning_evening_adhkar_screen.dart` | أذكار الصباح والمساء، مع عدّاد لكل ذكر. |
| `screens/quran_duas_screen.dart` | أدعية القرآن الـ89، مع بحث فوري وتصفية بالمحور. |
| `widgets/quran_dua_card.dart` | بطاقة دعاء قرآني، مع نسخه وفتحه في المصحف. |

#### `lib/features/focus`: وضع التأمل

| الملف | الوظيفة |
| --- | --- |
| `focus_mode_screen.dart` | وضع التأمل: آية واحدة في كل مرة على خلفية هادئة متحركة. |

#### `lib/features/highlights`: التظليل

| الملف | الوظيفة |
| --- | --- |
| `highlights_screen.dart` | الآيات المظلّلة، مع بحث فوري باسم السورة أو رقم الآية أو نصها. |

#### `lib/features/home`: الشاشة الرئيسية

| الملف | الوظيفة |
| --- | --- |
| `home_screen.dart` | الشاشة الرئيسية. |

#### `lib/features/journey`: رحلتي مع القرآن والختمة

| الملف | الوظيفة |
| --- | --- |
| `journey_screen.dart` | «رحلتي مع القرآن»: خطة الختمة، وورد اليوم، والإحصاءات. |
| `monthly_report.dart` | إحصاءات شهر لتقرير الشهر. |
| `mushaf_map_screen.dart` | نشاط الصفحة في خريطة المصحف. |
| `portion_reminder.dart` | تذكير ورد الختمة اليومي بعدد الصفحات المتبقية. |
| `streak_reminder.dart` | تنبيه قبل انقطاع سلسلة الأيام المتتالية. |
| `weekly_goals.dart` | أهداف الأسبوع: عدد صفحات وعدد وقفات تدبر. |

#### `lib/features/memorization`: الحفظ والمراجعة

| الملف | الوظيفة |
| --- | --- |
| `memorization_model.dart` | حالة حفظ آية في نظام صناديق لايتنر. |
| `memorization_screen.dart` | شاشة الحفظ: الإحصاءات، ومراجعة اليوم، واختيار سورة. |

#### `lib/features/more`: تبويب المزيد

| الملف | الوظيفة |
| --- | --- |
| `more_screen.dart` | تبويب «المزيد»: الأدوات الثانوية والإعدادات في قائمة واحدة. |

#### `lib/features/notes`: الملاحظات والتصدير

| الملف | الوظيفة |
| --- | --- |
| `note_editor_screen.dart` | محرر الخواطر بملء الشاشة، للخواطر الطويلة. |
| `note_pdf_exporter.dart` | يصدّر خاطرة واحدة PDF للمشاركة أو الطباعة، لا للنسخ الاحتياطي. |
| `notes_screen.dart` | الخواطر كلها في قائمة واحدة، خواطر الآيات والحرة معاً، الأحدث أولاً. |
| `tadbeer_journal_exporter.dart` | فترات تصدير دفتر التدبر. |

#### `lib/features/onboarding`: أول تشغيل والجولة والشروحات

| الملف | الوظيفة |
| --- | --- |
| `name_screen.dart` | يسأل القارئ عن اسمه عند أول فتح، لتناديه به التذكيرات. |
| `theme_picker_screen.dart` | اختيار مظهر التطبيق عند أول فتح: فاتح أو داكن أو تلقائي، وأحد الثيمات الخمسة. |
| `tour/home_walkthrough.dart` | دليل الرئيسية بعد الجولة: يعتّم الشاشة ويضيء عناصرها الحقيقية واحداً بعد آخر، ويُعاد من الإعدادات. |
| `tour/scene_story.dart` | قصة متحرّكة قصيرة تُعاد ما دامت ظاهرة. |
| `tour/scenes/companion_scenes.dart` | أقسام التطبيق تجتمع حول نجمة ذهبية: كل ما يحتاجه القارئ في مكان واحد. |
| `tour/scenes/icon_scenes.dart` | أيقونة القسم في هالة ذهبية، تدور حولها نجوم صغيرة. |
| `tour/scenes/journey_scenes.dart` | يوم القارئ في بطاقة واحدة: ورد يكتمل، وأيام الأسبوع تُضاء، وسلسلة تزيد. |
| `tour/scenes/links_scenes.dart` | شبكة روابط عن أبواب الرزق: ثلاث آيات تنضم إلى الموضوع، ولكل منها ملاحظة. |
| `tour/scenes/listen_scenes.dart` | تلاوة سورة الإخلاص: الضوء ينتقل من آية لأخرى، ثم يُختار «آية واحدة». |
| `tour/scenes/mushaf_scenes.dart` | ضغطة مطوّلة على آية تفتح القائمة الدائرية؛ ثم يختار القارئ منها. |
| `tour/scenes/pathways_scenes.dart` | مسار من سبعة أيام: يُضاء يومه الأول ثم الذي بعده. |
| `tour/scenes/reflect_scenes.dart` | بطاقة الوقفة: تُكتب أسئلتها الأربعة سطراً بعد سطر. |
| `tour/scenes/section_scenes.dart` | صف في وسط المشهد، يصغر مع النص الكبير بدل أن يفيض. |
| `tour/section_guide.dart` | الأقسام التي تشرح نفسها عند أول دخول. |
| `tour/tour_scenes.dart` | مشاهد الجولة وشروحات الأقسام: قصص قصيرة مرسومة من عناصر التطبيق نفسها. |
| `tour/tour_screen.dart` | جولة أول تشغيل: خمس صفحات، في كل صفحة ميزة ومشهدها المتحرّك. |

#### `lib/features/pathways`: مسارات التدبر

| الملف | الوظيفة |
| --- | --- |
| `guided_pathways_screen.dart` | تقدّم المسارات الموجّهة: الأيام المكتملة في كل مسار. |

#### `lib/features/qibla`: اتجاه القبلة

| الملف | الوظيفة |
| --- | --- |
| `qibla.dart` | حساب اتجاه القبلة والمسافة إلى الكعبة من موقع القارئ. |
| `qibla_location.dart` | موقع القارئ لحساب القبلة: من GPS دون إنترنت، مع حفظ آخر موقع. |
| `qibla_screen.dart` | اتجاه القبلة: بوصلة تدور مع الجهاز وعليها علامة الكعبة. |

#### `lib/features/quran`: المصحف

| الملف | الوظيفة |
| --- | --- |
| `qcf/madinah_preview.dart` | معاينة صغيرة لخط مصحف المدينة في الإعدادات. |
| `qcf/qcf_ayah_text.dart` | آية بخط مصحف المدينة جاهزة للرسم: رموزها واسم خط صفحتها. |
| `qcf/qcf_fonts.dart` | خطوط صفحات مصحف المدينة المضمّنة في التطبيق. |
| `qcf/qcf_layout.dart` | تخطيط صفحات مصحف المدينة (مجمع الملك فهد، الإصدار الأول). |
| `qcf/qcf_page_body.dart` | متن صفحة مصحف المدينة بخط مجمع الملك فهد. |
| `screens/quran_page_parts.dart` | أجزاء صفحة المصحف: الرأس والتذييل ونص الآيات. |
| `screens/quran_page_view.dart` | يميّز النقر من الضغط المطوّل على آية داخل نص الصفحة، دون أن يتعارض مع سحب الصفحات. |
| `screens/quran_screen.dart` | شاشة المصحف (٦٠٤ صفحات) بأدوات التدبر والبحث والتنقل والتلاوة. |
| `screens/quran_screen_dialogs.dart` | حوارا الانتقال إلى صفحة وحجم الخط. |
| `widgets/ayah_action_sheet.dart` | نافذة إجراءات الآية: التدبر، والربط، والخاطرة، والفاصل، والتظليل، والنسخ. |
| `widgets/ayah_rosette.dart` | الوردة الثمانية: إجراءات الآية تتفتح حول الإصبع على هيئة نجمة ثمانية. |
| `widgets/mushaf_frame_painter.dart` | نوع علامة الهامش في صفحة المصحف. |
| `widgets/quran_side_menu.dart` | القائمة الجانبية للمصحف: الانتقال إلى السور والأجزاء، والرئيسية والإعدادات. |
| `widgets/surah_header_banner.dart` | ترويسة السورة على طراز مصحف المدينة. |
| `widgets/text_scale_control.dart` | حجم خط النص المتدفق: زرّا تصغير وتكبير بينهما النسبة الحالية، وزر يعيده إلى حجمه التلقائي. |
| `widgets/word_details_sheet.dart` | لوحة بتفاصيل الكلمة: معناها وموضعها ومصدرها. |
| `widgets/word_meanings_panel.dart` | لوحة معاني كلمات الصفحة الحالية، تطفو فوق المصحف دون أن تغيّر تخطيطه. |

#### `lib/features/reminders`: التذكيرات والإشعارات

| الملف | الوظيفة |
| --- | --- |
| `local_reminder_service.dart` | تذكيرات القراءة على الجهاز دون إنترنت. |
| `reminders_screen.dart` | إدارة التذكيرات: إضافتها وتعديلها وتجربتها، بإشعار عادي أو منبه. |
| `startup_permissions.dart` | يطلب أذونات الإشعارات والمنبهات مرة واحدة عند أول تشغيل. |

#### `lib/features/search`: البحث

| الملف | الوظيفة |
| --- | --- |
| `built_in_search_providers.dart` | البحث في الآيات، بالنص أو بالجذر. |
| `search_provider.dart` | نتيجة بحث واحدة من أي قسم. |
| `search_screen.dart` | البحث الشامل الفوري دون إنترنت في كل أقسام التطبيق. |

#### `lib/features/settings`: الإعدادات

| الملف | الوظيفة |
| --- | --- |
| `settings_dialogs.dart` | حوارات الإعدادات: إعادة الضبط، والمظهر، وسياسة الخصوصية. |
| `settings_screen.dart` | الإعدادات: المظهر، وخط المصحف، والتطبيق، والبيانات، وحول. |
| `settings_widgets.dart` | دائرة معاينة لثيم: تدرج لونه الأساسي مع لمسة ذهبية. |

#### `lib/features/share`: المشاركة والحفظ

| الملف | الوظيفة |
| --- | --- |
| `ayah_share_sheet.dart` | مقاس بطاقة المشاركة. |
| `export_actions.dart` | يسأل القارئ ماذا يفعل بملف صدّره: يشاركه، أو يحفظه في جهازه. |

#### `lib/features/tadbeer`: وقفة التدبر

| الملف | الوظيفة |
| --- | --- |
| `commitment_card.dart` | بطاقة في الرئيسية تسأل القارئ عمّا التزم به في وقفة سابقة. |
| `my_reflections_screen.dart` | «وقفاتي»: كل ما كتبه القارئ عند الآيات، وما التزم به منها. |
| `tadbeer_intro_screen.dart` | شاشة الترحيب: آية في التدبر، وخيار إخفاء الشاشة نهائياً. |
| `tadbeer_pause_sheet.dart` | لوحة "وقفة تدبر" على آية: أربعة أسئلة تظهر واحداً واحداً. |
| `tadbeer_questions.dart` | نوع الآية كما تراه وقفة التدبر، ليُبدّل سؤال واحد بما يناسبها. |

#### `lib/features/tasbeeh`: الاستغفار والتسبيح

| الملف | الوظيفة |
| --- | --- |
| `data/curated_dhikrs.dart` | صيغ الاستغفار والتسبيح. |
| `tasbeeh_model.dart` | قسما السبحة. |
| `tasbeeh_screen.dart` | الاستغفار والتسبيح: سبحة بسيطة بقسمين. |
| `tasbeeh_screen_sections.dart` | أقسام شاشة التسبيح ولوحاتها. |
| `tasbeeh_widgets.dart` | تبويب للاختيار بين الاستغفار والتسبيح. |

#### `lib/features/widgets`: ودجت الهاتف

| الملف | الوظيفة |
| --- | --- |
| `home_widget_sync.dart` | بيانات ودجت الشاشة الرئيسية: آية كل ربع ساعة وتقدم الختمة. |
| `widget_ayah_image.dart` | الآية مرسومة صورةً لودجت الشاشة الرئيسية. |
| `widget_links.dart` | يفتح ما يطلبه القارئ من أزرار الودجت. |

#### `lib/features/word_meanings`: معاني الكلمات

| الملف | الوظيفة |
| --- | --- |
| `word_meanings_screen.dart` | معاني كلمات القرآن: استعراض الكلمات الغريبة والبحث فيها وتصفيتها بالسورة، والانتقال إلى موضع الكلمة في المصحف، والمصادر. |

## 7. أريد أن أغيّر...

بعد أي تعديل شغّل `flutter analyze` و`flutter test`.

### النصوص والمظهر

| أريد أن | ماذا أفعل |
| --- | --- |
| أغيّر نصاً ظاهراً | ابحث عنه في `lib/l10n/app_ar.arb`، وعدّله هناك وفي `app_en.arb`، ثم `flutter gen-l10n` |
| أضيف نصاً جديداً | أضف المفتاح في ملفي ARB، ثم getter في `lib/app/localization.dart` تحت `// نصوص الشاشات`، ثم `flutter gen-l10n`، واستخدمه: `context.l10n.myKey` |
| أغيّر ألوان ثيم | `lib/core/theme/theme.dart`، في لوحة الثيم داخل `ThemePalette` |
| أضيف ثيماً | أضف قيمة إلى `AppColorTheme`، ولوحتها في `ThemePalette.of`، واسمها في شاشة الاختيار `lib/features/onboarding/theme_picker_screen.dart` |
| أغيّر الزوايا والظلال | `lib/core/design_system/app_tokens.dart` |
| أغيّر سرعة الحركة | `lib/core/motion/app_motion.dart` |
| أضيف أيقونة | `lib/core/design_system/app_icons.dart` |
| أغيّر شعار التطبيق | استبدل الصور في `assets/icons/`، ثم `dart run flutter_launcher_icons` |
| أغيّر اسم التطبيق | `android:label` في `android/app/src/main/AndroidManifest.xml`، و`appName` في ملفي ARB |

### المحتوى

تفاصيل أكثر مع أمثلة في [دليل المحتوى](CONTENT_GUIDE.md).

| أريد أن | ماذا أفعل |
| --- | --- |
| أضيف دعاءً من السنة أو الجوامع | `lib/features/duas/data/sunnah_duas_repository.dart` |
| أضيف ذكراً | `lib/features/duas/data/adhkar_repository.dart`، في قائمة فئته |
| أضيف دعاءً قرآنياً | `lib/features/duas/data/quran_duas_repository.dart`، بأرقام متسلسلة، وحدّث عدد الاختبار في `test/duas/quran_duas_test.dart` |
| أضيف دعاءً لأهل البيت | `lib/features/duas/data/ahlulbayt_duas_repository.dart` |
| أضيف صيغة تسبيح | `lib/features/tasbeeh/data/curated_dhikrs.dart` |
| أضيف مساراً تدبرياً | `lib/features/ayah_links/data/curated_pathways.dart`؛ عدد الأيام يساوي عدد الآيات |
| أغيّر أسئلة وقفة التدبر | `TadbeerItem.questions` في `lib/data/models/tadbeer_model.dart`. السؤال الرابع هو الالتزام، فاترك ترتيبه |
| أصحح معنى كلمة | `assets/quran/word_meanings.json` |
| أضيف كتاباً | ضع الملف في `assets/books/`، وأضفه إلى `lib/features/books/data/curated_books.dart` |
| أضيف قارئاً | أضف `Reciter` إلى `reciters` في `lib/features/audio/reciters.dart` |

### المصحف

| أريد أن | ماذا أفعل |
| --- | --- |
| أغيّر سرعة تقليب الصفحة | `_MushafPagePhysics` في `quran_screen.dart`: الصلابة `stiffness` الأعلى أسرع |
| أغيّر مدة الضغط المطول على الآية | `duration` في `_getOrCreateRecognizer` داخل `quran_page_view.dart` |
| أغيّر أزرار قائمة الآية الدائرية | `lib/features/quran/widgets/ayah_rosette.dart` |
| أغيّر الشريط السفلي | `_buildBottomBar` في `quran_screen.dart` |
| أغيّر متى تُحسب الصفحة مقروءة | `_readDwell` و`_autoCountDwell` و`_lastPageDwell` في `quran_screen.dart` |
| أغيّر إطار الصفحة | `lib/features/quran/widgets/mushaf_frame_painter.dart` |

### الجولة والشروحات

| أريد أن | ماذا أفعل |
| --- | --- |
| أغيّر نص جولة أو شرح | المفاتيح `tour...` و`guide...` و`walk...` في ملفي ARB |
| أعدّل صفحات الجولة | القائمة `_content` في `lib/features/onboarding/tour/tour_screen.dart` |
| أعدّل مشهداً متحركاً | `lib/features/onboarding/tour/scenes/`؛ كل مشهد يبني نفسه من `t` بين 0 و1 |
| أضيف شرحاً لقسم | أضف قيمة إلى `GuideTopic` وخطواتها في `_steps` داخل `section_guide.dart`، وضع `GuideButton(topic: ...)` في رأس الشاشة |
| أعدّل دليل الرئيسية | `_steps` في `lib/features/onboarding/tour/home_walkthrough.dart` |

### الشاشات والميزات

| أريد أن | ماذا أفعل |
| --- | --- |
| أضيف زراً في المزيد | أضف `_Tile` داخل `_Group` في `lib/features/more/more_screen.dart` |
| أضيف إعداداً محفوظاً | أضف الحقل في `UserSettings` (`lib/data/models/user_settings_model.dart`): الباني و`toJson` و`fromJson` و`copyWith`. ثم عدّله عبر `updateSettings` |
| أضيف ميزة جديدة | أنشئ مجلداً في `lib/features/`، واربط شاشتها من `more_screen.dart` |
| أحفظ حالة ميزة صغيرة | `UserDataStore.instance.saveFeatureState('key', map)` واقرأها بـ `featureState('key')` |
| أغيّر وقت تذكير افتراضي | `defaultTime` في `lib/features/duas/data/adhkar_reminders.dart` |
| أغيّر الودجت على Android | `lib/features/widgets/` و`android/app/src/main/res/layout/tadbeer_widget.xml` و`TadbeerWidgetProvider.kt` |

### نموذج لتعديل كامل: زر جديد في المزيد

1. أضف النص إلى `lib/l10n/app_ar.arb`: `"myPage": "صفحتي"`، وإلى `app_en.arb`: `"myPage": "My page"`.
2. أضف إلى `lib/app/localization.dart`: `String get myPage => _l.myPage;`
3. نفّذ `flutter gen-l10n`.
4. أنشئ `lib/features/my_page/my_page_screen.dart`.
5. أضف إلى `more_screen.dart` داخل مجموعة:

```dart
_Tile(
  icon: AppIcons.sparkleFill,
  label: l10n.myPage,
  onTap: () => open(const MyPageScreen()),
),
```

6. نفّذ `flutter analyze` ثم `flutter run`.

## 8. الاختبارات

مجلد `test/` يقابل مجلدات `lib/features/`. وفيه 659 اختباراً.

- `test/ui/screens_smoke_test.dart` يفتح كل الشاشات بالوضعين الفاتح والداكن وبخط كبير.
- إذا أضفت شاشة، فأضفها إلى قائمة `screens` في هذا الملف.
- في `testWidgets` الوقت وهمي، فأي قراءة أو كتابة حقيقية للملفات يجب أن تكون داخل `tester.runAsync`، وإلا سيعلق الاختبار.
- لا تعتمد على انتظار ثابت مثل 100ms؛ انتظر الحالة نفسها، فخادم CI أبطأ من جهازك.
- الحركات المتكررة تمنع `pumpAndSettle` من الانتهاء، فاستخدم `pump` عدة مرات.

## 9. إصدار نسخة جديدة

1. غيّر الإصدار في `pubspec.yaml`، مثل `version: 1.0.1+2`. الرقم بعد `+` يجب أن يزيد في كل إصدار.
2. أضف التغييرات إلى `CHANGELOG.md`.
3. نفّذ `flutter analyze` و`flutter test`.
4. ادمج في `main`، ثم أنشئ وسماً:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

عند رفع الوسم يبني `.github/workflows/release.yml` التطبيق ويوقّعه وينشر الملفات في صفحة Releases.

يحتاج ذلك أربعة أسرار في إعدادات GitHub: `ANDROID_KEYSTORE_BASE64` و`ANDROID_KEY_ALIAS` و`ANDROID_KEY_PASSWORD` و`ANDROID_STORE_PASSWORD`.

الموقع في `docs/` يُنشر عبر GitHub Pages. وتعمل صفحة الخصوصية من `docs/privacy.html`.

## 10. مشاكل شائعة وحلولها

| المشكلة | الحل |
| --- | --- |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | التوقيع مختلف عن النسخة المثبتة. احذفها أولاً، وتضيع بياناتها: `adb uninstall com.tadbeer.app` |
| فشل بناء release بسبب التوقيع | تأكد من وجود `android/key.properties`. وللتجربة المحلية فقط: `TADBEER_ALLOW_DEBUG_SIGNING=true flutter run --release` |
| لا يظهر نص جديد | نفّذ `flutter gen-l10n`، وأعد تشغيل التطبيق بـ `R` |
| خطأ `The getter 'l10n' isn't defined` | أضف الاستيراد `app/localization.dart` |
| اختبار يعلق | غالباً قراءة ملف خارج `tester.runAsync` |
| `pumpAndSettle timed out` | حركة متكررة، أو مؤشر تحميل ما زال يدور |
| `RenderFlex overflowed` | ضع النص في `Expanded`، أو حوّل `Row` إلى `Wrap` |
| التطبيق بطيء أثناء التطوير | هذا طبيعي في debug؛ جرّب `flutter run --profile` |
| الترجمة تعمل في جزء دون آخر | عناصر `core` لا تستخدم `context.l10n`، فمرّر النص إليها من الشاشة |

---

ملفات مرجعية أخرى: [دليل المعمارية](ARCHITECTURE_AND_CODE_GUIDE.md)، [دليل المحتوى](CONTENT_GUIDE.md)، [دليل التطوير](../DEVELOPMENT_GUIDE.ar.md).

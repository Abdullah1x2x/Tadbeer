# سياسة الخصوصية والأمان · Privacy & Security Policy

> **تطبيق «تَدبِير» (Tadbeer) — تطبيق قرآني وتدبري مفتوح المصدر يعمل محلياً دون إنترنت، ولا يستخدم الإنترنت إلا للتلاوة المسموعة والتحقق من التحديثات.**  
> **Effective Date:** October 2026 | **تاريخ السريان:** أكتوبر 2026  
> **Compliance:** Fully compliant with Google Play Developer Policy, Apple App Store Review Guidelines, and GDPR/CCPA.

---

##  النسخة العربية (Arabic Version)

### 1. ميثاق الخصوصية بالتصميم (Privacy by Design)
تطبيق «تَدبِير» مبني على مبدأ أساسي راسخ: **الخصوصية حق أصيل لكل مؤمن ومتدبر لكتاب الله**. التطبيق يعمل بصورة مستقلة ومحلية على جهازك، ولا يتصل بأي خادم إلا لتنزيل التلاوة المسموعة حين تطلبها أو للتحقق من التحديثات (انظر البند 3).

---

### 2. عدم جمع أي بيانات شخصية (Zero Data Collection)
- **لا جمع:** لا يجمع التطبيق أي معلومات تعريف شخصية (كالاسم، أو البريد الإلكتروني، أو رقم الهاتف، أو الموقع الجغرافي). الاسم الذي تكتبه عند البدء ليناديك به التطبيق، وآخر موقع لحساب القبلة، يُحفظان على جهازك فقط ولا يُرسلان إلى أي جهة.
- **لا تتبع:** لا يقوم التطبيق بتتبع سلوك الاستخدام أو سجلات التلاوة أو أوقات القراءة.
- **لا مشاركة:** لا توجد خوادم سحابية تستقبل بياناتك، ولا يتم بيع أو مشاركة أي معلومة مع أي طرف ثالث على الإطلاق.

---

### 3. العمل المحلي دون إنترنت، والإنترنت للتلاوة المسموعة والتحقق من التحديثات فقط (Offline-First)
- كافة العمليات، بما في ذلك: قراءة وتصفح المصحف، البحث القرآني الصرفي، معجم المفردات (6,465 كلمة)، قراءة الملازم والكتب، اتجاه القبلة، وحساب أوقات التنبيهات، تنفذ محلياً بالكامل على جهازك دون اتصال.
- يطلب التطبيق إذن الإنترنت (`android.permission.INTERNET`) **لغرضين حصريين:**
  1. تشغيل التلاوة المسموعة أو تنزيلها حين تطلبها أنت، من خادم شبكة Islamic Network (`cdn.islamic.network`). يصل إلى هذا الخادم ما يصل في أي تنزيل من الإنترنت: **عنوان IP الخاص بجهازك واسم الملف الصوتي المطلوب** (رقم الآية والقارئ). لا يُرسَل معه أي شيء من بياناتك أو ملاحظاتك أو معرّفات جهازك. يخضع هذا الخادم لسياسة الخصوصية الخاصة بمشغّله. وبعد تنزيل السورة تُحفظ ملفاتها على جهازك وتُسمع دون اتصال.
  2. التحقق من وجود إصدارات وتحديثات جديدة للتطبيق عبر قراءة ملف الإصدار العام (`version.json`) من المستودع المفتوح، وذلك يدوياً عبر زر الإعدادات أو تلقائياً في الخلفية (يمكن تعطيله من الإعدادات). لا يتم إرسال أي معرّفات للجهاز أو بيانات شخصية أثناء الفحص.

---

### 4. التخزين المحلي والتشفير القياسي العسكري (Local Storage & AES-256)
- **قاعدة البيانات المحلية:** تُحفظ خواطرك، وملاحظاتك التدبرية، وفواصلك، وتظليلاتك محلياً حصراً في قاعدة بيانات SQLite داخل المساحة الخاصة بالتطبيق على جهازك، وهي مساحة لا تصل إليها التطبيقات الأخرى.
- **النسخ الاحتياطي المشفر (`.quranbackup`):** عند رغبتك في تصدير نسخة احتياطية من تدبراتك، يقوم التطبيق بتشفيرها محلياً بأعلى المعايير القياسية:
  - تشفير متماثل: **AES-256-CBC**.
  - اشتقاق المفاتيح من كلمة مرور سرية يحددها المستخدم وحده عبر **PBKDF2-HMAC-SHA256**.
  - ضغط البيانات عبر **Gzip**.
  - توقيع الملف بـ **HMAC-SHA256** والتحقق منه قبل فك التشفير، فيُرفض أي ملف تالف أو معدّل.

---

### 5. الأذونات المطلوبة والغرض الحصري منها (Device Permissions)
- **إذن الإشعارات المحلية (`POST_NOTIFICATIONS`):**  
  يُطلب حصراً لجدولة التنبيهات والمنبهات اليومية التي يضبطها المستخدم بنفسه للورد القرآني وورد الاستغفار. لا تُرسل أي إشعارات إعلانية أو ترويجية على الإطلاق.
- **إذن الاهتزاز والتشغيل عند الإقلاع والمنبهات الدقيقة (`RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `SCHEDULE_EXACT_ALARM`):**  
  لإعادة جدولة منبهات الورد القرآني محلياً بعد إعادة تشغيل الجهاز، ولتنبيهها في وقتها المحدد.
- **إذن الموقع التقريبي (`ACCESS_COARSE_LOCATION`):**  
  اختياري، ويُطلب فقط حين تفتح اتجاه القبلة. يُحدَّد الموقع من GPS بدقة منخفضة، ويُحسب اتجاه القبلة على جهازك، ويُحفظ آخر موقع على جهازك فقط ولا يُرسل إلى أي جهة.
- **إذن الإنترنت (`INTERNET`):**  
  للتلاوة المسموعة والتحقق من التحديثات فقط، كما في البند 3.
- **أذونات التشغيل في الخلفية (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`):**  
  لتستمر التلاوة المسموعة حين تغلق الشاشة، مع أزرار التحكم في الإشعار.
- **إذن التخزين (`WRITE_EXTERNAL_STORAGE`، لأندرويد 10 وما قبله فقط):**  
  لحفظ بطاقة الآية في الصور حين تطلب ذلك.

---

### 6. خلو تام من الإعلانات والمتتبعات (Zero Ads & Zero Trackers)
- التطبيق خالٍ بنسبة 100% من أي منصات إعلانية (Google AdMob أو غيرها).
- التطبيق خالٍ بنسبة 100% من حزم التحليلات والتتبع (Google Analytics, Firebase Analytics, Facebook Pixel, الخ).

---

### 7. تواصل واستفسارات الخصوصية (Contact & Inquiries)
لأي استفسار بخصوص الأمان والخصوصية أو لمراجعة الكود المصدري المفتوح، يرجى فتح تذكرة عبر مستودع المشروع الرسمي على GitHub:  
👉 **[github.com/Abdullah1x2x/Tadbeer/issues](https://github.com/Abdullah1x2x/Tadbeer/issues)**

---

##  English Version (For Store Reviewers & International Users)

### 1. Privacy by Design Tenet
**Tadbeer** is an open-source, offline-first Quran contemplation and reading application built with Flutter. It is architected from the ground up to respect user sovereignty and absolute digital privacy, using network connectivity solely for audio recitations and checking for application updates.

---

### 2. Zero Data Collection Policy
- **No Personal Data Collected:** Tadbeer does not collect, record, transmit, store on servers, or share any personal identity information (e.g., name, email, phone number, location, or device unique identifiers). The name you enter at onboarding, used to address you, and the last location used for the Qibla stay on your device only and are never sent anywhere. The only network traffic is audio recitation and update checks, described in section 3.
- **No Behavioral Tracking:** No telemetry, analytics, session logs, reading history, or habit tracking are ever captured.
- **No Third-Party Sharing:** Zero data is transmitted to advertisers, data brokers, or external cloud infrastructure.

---

### 3. Offline-First Architecture, with Internet Used Only for Audio Recitation and Update Checks
- All application functionalities, including the Mushaf (604 pages), morphological root search, the lexicon of 6,465 Quranic word meanings, book and PDF readers, the Qibla direction, and notification scheduling, run strictly on the local hardware without a connection.
- The application declares internet permission (`android.permission.INTERNET`) **for two explicit purposes only:**
  1. Streaming or downloading audio recitation, on the user's request, from the Islamic Network CDN (`cdn.islamic.network`). That server receives **the device's IP address and the name of the requested audio file** (ayah number and reciter). No user data, notes, device identifiers or analytics are sent. Downloaded surahs are stored on the device and play offline.
  2. Checking for new app versions and updates by reading the public version metadata file (`version.json`) from the repository, either manually via the Settings screen or automatically at launch (which can be toggled in Settings). No identifiers, telemetries, or personal info are transmitted.

---

### 4. Local Data Persistence & AES-256 Backups
- **Device-Only SQLite:** User-generated content (notes, reflection journal entries, bookmarks, ayah highlights, and habit trackers) resides strictly in on-device SQLite storage (`tadbeer_user_data.db`) inside the app's private storage, which other apps cannot access.
- **Military-Grade AES-256 Backups:** Exported user backup snapshots (`.quranbackup`) are encrypted locally with **AES-256-CBC** with keys derived from a user-provided password via PBKDF2-HMAC-SHA256, compressed via Gzip, and authenticated with **HMAC-SHA256** before decryption, so a damaged or altered file is rejected. The developers have no backdoors or recovery mechanisms for user passwords.

---

### 5. Hardware & Device Permissions Disclosure
- **`POST_NOTIFICATIONS`:** Used strictly to trigger scheduled on-device local alarms and reminders configured explicitly by the user for reading habits.
- **`RECEIVE_BOOT_COMPLETED` & `SCHEDULE_EXACT_ALARM`:** Utilized to restore local alarms after system reboots without requiring network connectivity.
- **`VIBRATE`:** Provides subtle haptic feedback for the electronic tasbeeh counter and alarms.
- **`ACCESS_COARSE_LOCATION`:** Optional, requested only when the user opens the Qibla direction. The location is read from GPS at low accuracy, the Qibla bearing is computed on-device, and the last location is stored on-device only. It is never transmitted.
- **`INTERNET`:** Used only for audio recitation and update checks, as described in section 3.
- **`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` & `WAKE_LOCK`:** Keep audio recitation playing with the screen off, with media controls in the notification.
- **`WRITE_EXTERNAL_STORAGE` (Android 10 and earlier only):** Saves an ayah card to Photos when the user asks.

---

### 6. Zero Advertisements & Zero Analytics Frameworks
Tadbeer is 100% free of advertising SDKs, marketing trackers, and telemetry services.

---

### 7. Compliance & Open-Source Verification
The full source code of Tadbeer is licensed under the permissive **MIT License** and is open for public audit and verification:  
Repository: [https://github.com/Abdullah1x2x/Tadbeer](https://github.com/Abdullah1x2x/Tadbeer)  
Issue Tracker: [https://github.com/Abdullah1x2x/Tadbeer/issues](https://github.com/Abdullah1x2x/Tadbeer/issues)

# سياسة الخصوصية والأمان · Privacy & Security Policy

> **تطبيق «تَدْبِير» (Tadbeer) — تطبيق قرآني وتدبري مفتوح المصدر يعمل محلياً بالكامل دون إنترنت.**  
> **Effective Date:** October 2026 | **تاريخ السريان:** أكتوبر 2026  
> **Compliance:** Fully compliant with Google Play Developer Policy, Apple App Store Review Guidelines, and GDPR/CCPA offline standards.

---

## 🇸🇦 النسخة العربية (Arabic Version)

### 1. ميثاق الخصوصية بالتصميم (Privacy by Design)
تطبيق «تَدْبِير» مبني على مبدأ أساسي راسخ: **الخصوصية حق أصيل لكل مؤمن ومتدبر لكتاب الله**. التطبيق يعمل بصورة مستقلة ومحلية تماماً على جهازك دون أي وسيط خارجي.

---

### 2. عدم جمع أي بيانات شخصية (Zero Data Collection)
- **لا جمع:** لا يجمع التطبيق أي معلومات تعريف شخصية (كالاسم، أو البريد الإلكتروني، أو رقم الهاتف، أو الموقع الجغرافي).
- **لا تتبع:** لا يقوم التطبيق بتتبع سلوك الاستخدام أو سجلات التلاوة أو أوقات القراءة.
- **لا مشاركة:** لا توجد خوادم سحابية تستقبل بياناتك، ولا يتم بيع أو مشاركة أي معلومة مع أي طرف ثالث على الإطلاق.

---

### 3. العمل المحلي التام دون إنترنت (100% Offline-First)
- التطبيق **لا يطلب إذن الوصول إلى شبكة الإنترنت** (`android.permission.INTERNET`) في ملف التكوين الأساسي.
- كافة العمليات، بما في ذلك: البحث القرآني الصرفي، معجم المفردات (6,465 كلمة)، قراءة وتصفح المصحف، قراءة الملازم والكتب، وحساب أوقات التنبيهات، تنفذ محلياً بالكامل داخل معالج جهازك وبطاقة الذاكرة.

---

### 4. التخزين المحلي والتشفير القياسي العسكري (Local Storage & AES-256)
- **قاعدة البيانات المحلية:** تُحفظ خواطرك، وملاحظاتك التدبرية، وفواصلك، وتظليلاتك محلياً حصراً في قاعدة بيانات SQLite مشفرة داخل المساحة الخاصة بالتطبيق على جهازك.
- **النسخ الاحتياطي المشفر (`.quranbackup`):** عند رغبتك في تصدير نسخة احتياطية من تدبراتك، يقوم التطبيق بتشفيرها محلياً بأعلى المعايير القياسية:
  - تشفير متماثل: **AES-256-CBC**.
  - اشتقاق المفاتيح بكلمة مرور سرية يحددها المستخدم وحده.
  - ضغط البيانات عبر **Gzip**.
  - فحص سلامة الملف ومطابقته ببصمة **SHA-256 Checksum** لمنع التلاعب.

---

### 5. الأذونات المطلوبة والغرض الحصري منها (Device Permissions)
- **إذن الإشعارات المحلية (`POST_NOTIFICATIONS`):**  
  يُطلب حصراً لجدولة التنبيهات والمنبهات اليومية التي يضبطها المستخدم بنفسه للورد القرآني وورد الاستغفار. لا تُرسل أي إشعارات إعلانية أو ترويجية على الإطلاق.
- **إذن الاهتزاز والتشغيل عند الإقلاع (`RECEIVE_BOOT_COMPLETED`, `VIBRATE`):**  
  لإعادة جدولة منبهات الورد القرآني محلياً بعد إعادة تشغيل الجهاز.

---

### 6. خلو تام من الإعلانات والمتتبعات (Zero Ads & Zero Trackers)
- التطبيق خالٍ بنسبة 100% من أي منصات إعلانية (Google AdMob أو غيرها).
- التطبيق خالٍ بنسبة 100% من حزم التحليلات والتتبع (Google Analytics, Firebase Analytics, Facebook Pixel, الخ).

---

### 7. تواصل واستفسارات الخصوصية (Contact & Inquiries)
لأي استفسار بخصوص الأمان والخصوصية أو لمراجعة الكود المصدري المفتوح، يرجى فتح تذكرة عبر مستودع المشروع الرسمي على GitHub:  
👉 **[github.com/Abdullah-Alshami/Tadbeer/issues](https://github.com/Abdullah-Alshami/Tadbeer/issues)**

---

## 🇬🇧 English Version (For Store Reviewers & International Users)

### 1. Privacy by Design Tenet
**Tadbeer** is an open-source, offline-first Quran contemplation and reading application built with Flutter. It is architected from the ground up to respect user sovereignty and absolute digital privacy.

---

### 2. Zero Data Collection Policy
- **No Personal Data Collected:** Tadbeer does not collect, record, transmit, store on servers, or share any personal identity information (e.g., name, email, phone number, location, IP address, or device unique identifiers).
- **No Behavioral Tracking:** No telemetry, analytics, session logs, reading history, or habit tracking are ever captured.
- **No Third-Party Sharing:** Zero data is transmitted to advertisers, data brokers, or external cloud infrastructure.

---

### 3. 100% Offline-First Architecture
- The application **does not declare or request internet permission** (`android.permission.INTERNET`) in its production manifest.
- All application functionalities—including the offline Quran text engine (604 pages), morphological root search, lexicon of 6,465 Quranic word meanings, book and PDF readers, and notification scheduling—run strictly on the local hardware.

---

### 4. Local Data Persistence & AES-256 Backups
- **Device-Only SQLite:** User-generated content (notes, reflection journal entries, bookmarks, ayah highlights, and habit trackers) resides strictly in on-device SQLite storage (`tadbeer_user_data.db`).
- **Military-Grade AES-256 Backups:** Exported user backup snapshots (`.quranbackup`) are encrypted locally with **AES-256-CBC** using a user-provided password, compressed via Gzip, and verified with a **SHA-256** checksum. The developers have no backdoors or recovery mechanisms for user passwords.

---

### 5. Hardware & Device Permissions Disclosure
- **`POST_NOTIFICATIONS`:** Used strictly to trigger scheduled on-device local alarms and reminders configured explicitly by the user for reading habits.
- **`RECEIVE_BOOT_COMPLETED` & `SCHEDULE_EXACT_ALARM`:** Utilized to restore local alarms after system reboots without requiring network connectivity.
- **`VIBRATE`:** Provides subtle haptic feedback for the electronic tasbeeh counter and alarms.

---

### 6. Zero Advertisements & Zero Analytics Frameworks
Tadbeer is 100% free of advertising SDKs, marketing trackers, and telemetry services.

---

### 7. Compliance & Open-Source Verification
The full source code of Tadbeer is licensed under the permissive **MIT License** and is open for public audit and verification:  
Repository: [https://github.com/Abdullah-Alshami/Tadbeer](https://github.com/Abdullah-Alshami/Tadbeer)  
Issue Tracker: [https://github.com/Abdullah-Alshami/Tadbeer/issues](https://github.com/Abdullah-Alshami/Tadbeer/issues)

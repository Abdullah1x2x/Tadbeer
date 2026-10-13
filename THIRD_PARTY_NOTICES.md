# إشعارات الأطراف الثالثة والتراخيص (Third-Party Notices & Licenses)

> **المشروع:** تَدْبِير (`Tadbeer`) — تطبيق قرآني مفتوح المصدر للقراءة والتدبّر دون إنترنت  
> **الترخيص الرئيسي:** [رخصة MIT (MIT License)](LICENSE)  
> **تاريخ التدقيق:** أكتوبر 2026

---

## 1. ملخص التدقيق القانوني (Audit Summary)

أُجري تدقيق شامل لجميع مكونات مشروع «تَدْبِير»، وشمل الفحص:
- **البيانات القرآنية والمعجمية المضمّنة** في `assets/quran/`.
- **الخطوط الحاسوبية** المضمّنة في `assets/fonts/`.
- **الاعتماديات البرمجية المباشرة والمتعدية** في `pubspec.lock`.
- **مكونات ومحركات التشغيل الأصلية** عبر مختلف المنصات (Android, iOS, Linux, Windows, macOS, Web).

### نتيجة التدقيق
- **التوافق القانوني:** متوافق بنسبة **100%** مع تراخيص المصادر المفتوحة ومتطلبات النشر على المتاجر الرسمية (**Google Play**, **Apple App Store**, **F-Droid**).
- **التعارضات القانونية:** **صفر** تعارضات (خلو تام من تراخيص GPL التعارضية أو الشروط المقيدة للاستخدام التجاري أو شروط منع التوزيع).
- **إشعارات التطبيق التلقائية:** تُسجّل جميع التراخيص آلياً ضمن `LicenseRegistry` عبر Flutter، وتتاح للمستخدم من داخل التطبيق عبر نافذة `showLicensePage`.

---

## 2. سجل البيانات والمحتوى المضمّن (Datasets & Content)

| المكوّن | المصدر الرسمي | الإصدار | نوع الترخيص | شروط والتزامات إعادة التوزيع |
| :--- | :--- | :--- | :--- | :--- |
| **النص القرآني الكريم بالرسم العثماني** (`quran_data.json`) | [Tanzil Project](https://tanzil.net/) | Tanzil 1.1 | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) | • حظر تعديل أو تحريف النص القرآني بأي شكل.<br>• الإسناد الصريح لمشروع تنزيل مع رابط الموقع. |
| **معجم معاني كلمات القرآن** (`word_meanings.json` — 6,465 مدخلاً) | [الموسوعة القرآنية (Quranpedia.net)](https://quranpedia.net) | `2026-10-10` | [CC0 1.0 Public Domain](https://creativecommons.org/publicdomain/zero/1.0/) + معاجم تراثية | • مجاني للاستخدام وإعادة التوزيع داخل التطبيقات.<br>• إسناد الرقمنة لمشروع الموسوعة القرآنية مع ذكر الإصدار. |
| **مستودع الأدعية القرآنية** (`quran_duas_repository.dart` — 88 دعاءً) | نصوص القرآن من تنزil / التبويب والبرمجة من تدبير | `1.0.0` | نصوص: `CC BY 3.0`<br>برمجة: `MIT` | الحفاظ على دقة النص القرآني وإسناد المصدر. |
| **المسارات التدبرية المقترحة** (`curated_pathways.dart`) | مؤلفو مشروع تدبير | `1.0.0` | [MIT](LICENSE) | تأليف أصلي للمشروع يخضع لترخيص MIT. |
| **شعار وأيقونات التطبيق** (`assets/icons/*`, `logo.vectorcraft`) | تصميم مشروع تدبير | `1.0.0` | [MIT](LICENSE) | هوية بصرية أصلية تتبع ترخيص المشروع الرئيسي. |

---

## 3. سجل الخطوط الحاسوبية (Fonts Registry)

جميع خطوط المصحف والواجهة مرخّصة برخصة الخطوط الحرة المفتوحة **[SIL Open Font License 1.1 (OFL-1.1)](https://openfontlicense.org/)**:

| الخط | المصدر والمؤلف | الإصدار | الترخيص | الالتزامات والشروط |
| :--- | :--- | :--- | :--- | :--- |
| **Scheherazade New** (`ScheherazadeNew-Regular.ttf`) | [SIL International](https://software.sil.org/scheherazade/) | `4.500` | SIL OFL-1.1 | إرفاق نص الترخيص، عدم بيع الخط منفرداً، احترام الأسماء المحفوظة (`Scheherazade`, `SIL`). |
| **Noto Naskh Arabic** (`NotoNaskhArabic-Regular.ttf`) | [Google Fonts / Monotype](https://github.com/notofonts/arabic) | `2.021` | SIL OFL-1.1 | إرفاق نص الترخيص وإشعار الحقوق، عدم بيع الخط منفرداً. |
| **Harmattan** (`Harmattan-Regular.ttf`) | [SIL International](https://software.sil.org/harmattan/) | `4.400` | SIL OFL-1.1 | إرفاق نص الترخيص، احترام الأسماء المحفوظة (`Harmattan`, `SIL`). |
| **Lateef** (`Lateef-Regular.ttf`) | [SIL International](https://software.sil.org/lateef/) | `4.400` | SIL OFL-1.1 | إرفاق نص الترخيص، احترام الأسماء المحفوظة (`Lateef`, `SIL`). |
| **Amiri Quran** (`AmiriQuran-Regular.ttf`) | [د. خالد حسني / Alif Type](https://github.com/aliftype/amiri) | `1.003` | SIL OFL-1.1 | إرفاق نص الترخيص وإشعار الحقوق. |
| **Amiri** (`Amiri-Regular.ttf`, `Amiri-Bold.ttf`) | [د. خالد حسني / Alif Type](https://github.com/aliftype/amiri) | `1.002` | SIL OFL-1.1 | إرفاق نص الترخيص وإشعار الحقوق. |
| **Material Icons** (`MaterialIcons-Regular.otf`) | [Google LLC](https://github.com/google/material-design-icons) | Flutter SDK | Apache-2.0 | إرفاق نص الترخيص وإشعار حقوق Google LLC (مضمّن عبر Flutter). |
| **Islamic Icons** (`IslamicIcons.ttf`) | [Ramazan Erbasaran](https://pub.dev/packages/flutter_islamic_icons) | `1.0.2` | BSD-2-Clause | إرفاق نص ترخيص BSD-2-Clause وإشعار الحقوق. |

---

## 4. سجل حزم التشغيل المباشرة (Direct Dependencies)

الحزم المصرح بها مباشرة في [`pubspec.yaml`](pubspec.yaml) وتدخل في بناء التطبيق وتوزيعه:

| الحزمة | الإصدار | الوظيفة في التطبيق | نوع الترخيص | صاحب حقوق النشر |
| :--- | :--- | :--- | :--- | :--- |
| **`crypto`** | `3.0.7` | حساب تجزئة SHA-256 للنسخ الاحتياطي | BSD-3-Clause | Copyright 2015, the Dart project authors. |
| **`encrypt`** | `5.0.3` | تشفير AES-256 للنسخ الاحتياطي | BSD-3-Clause | Copyright (c) 2018, Leo Cavalcante. |
| **`file_picker`** | `13.1.0` | اختيار ملفات النسخ الاحتياطي من الجهاز | MIT | Copyright (c) 2018 Miguel Ruivo. |
| **`flutter`** | SDK | إطار عمل الواجهات الأساسي | BSD-3-Clause | Copyright 2014 The Flutter Authors. |
| **`flutter_islamic_icons`** | `1.0.2` | أيقونات المصحف والأدعية الإسلامية | BSD-2-Clause | Copyright 2022, RAMAZAN ERBASARAN. |
| **`flutter_local_notifications`**| `23.0.0-dev.2`| التنبيهات والمنبهات المحلية دون إنترنت | BSD-3-Clause | Copyright 2018 Michael Bui. |
| **`flutter_timezone`** | `5.1.1` | جلب المنطقة الزمنية المحلية للجهاز | Apache-2.0 | flutter_timezone Authors. |
| **`path`** | `1.9.1` | معالجة مسارات الملفات | BSD-3-Clause | Copyright 2014, the Dart project authors. |
| **`path_provider`** | `2.1.6` | الوصول لمجلدات التخزين المحلية | BSD-3-Clause | Copyright 2013 The Flutter Authors. |
| **`pdf`** | `3.13.1` | توليد وتصدير مستندات PDF للملاحظات والتدبر | Apache-2.0 | Copyright (c) 2017, David PHAM-VAN. |
| **`qr_flutter`** | `4.1.0` | رسم وعرض رموز QR لمشاركة الروابط | BSD-3-Clause | Copyright (c) 2020, Luke Freeman. |
| **`share_plus`** | `13.3.1` | مشاركة البطاقات والنصوص عبر النظام | BSD-3-Clause | Copyright 2017, the Flutter project authors. |
| **`sqflite`** | `2.4.4+1` | قاعدة بيانات SQLite المحلية على الأجهزة | BSD-2-Clause | Copyright (c) 2019, Alexandre Roux Tekartik. |
| **`sqflite_common`** | `2.5.13+1` | واجهة SQLite المشتركة | BSD-2-Clause | Copyright (c) 2019, Alexandre Roux Tekartik. |
| **`sqflite_common_ffi`** | `2.4.3` | تشغيل SQLite عبر FFI لسطح المكتب والاختبارات | BSD-2-Clause | Copyright (c) 2019, Alexandre Roux Tekartik. |
| **`timezone`** | `0.11.1` | حساب توقيت المناطق الزمنية | BSD-2-Clause | Copyright (c) 2014, timezone project authors. |
| **`uuid`** | `4.6.0` | توليد معرفات فريدة للملاحظات والتنبيهات | MIT | Copyright (c) 2021 Yulian Kuncheff. |

---

## 5. تدقيق الاعتماديات المتعدية وأطر التشغيل (Transitive & Platform Audit)

تم فحص كامل شجرة الاعتماديات المتعدية (Transitive Dependencies) المستخرجة من `pubspec.lock` والبالغ عددها **95 حزمة فرعية**، وتصنيفها بحسب التراخيص:

- **فئة تراخيص BSD-3-Clause (54 حزمة):**  
  تشمل الحزم الأساسية المعتمدة من فريق Flutter و Dart: `async`، `characters`، `collection`، `convert`، `cross_file`، `ffi`، `file`، `fixnum`، `intl`، `meta`، `source_span`، `string_scanner`، `typed_data`، وغيرها.  
  *الالتزام:* إرفاق إشعار حقوق النشر ونص الترخيص (يُضمّن تلقائياً في حزمة التطبيق داخل ملف `NOTICES.Z`).
- **فئة تراخيص MIT (28 حزمة):**  
  تشمل: `archive` (ضغط Gzip)، `bidi` (النصوص العربية في PDF)، `equatable`، `android_file_picker`، `file_picker_linux`، `file_picker_darwin`، `file_picker_web`، `file_picker_windows`، وغيرها.  
  *الالتزام:* إرفاق نص ترخيص MIT وإشعار الحقوق.
- **فئة تراخيص Apache-2.0 (7 حزم):**  
  تشمل: `barcode` (توليد الباركود داخل PDF)، `clock`، وغيرها.  
  *الالتزام:* إرفاق نص ترخيص Apache-2.0 وبيان الحقوق.
- **فئة تراخيص BSD-2-Clause (5 حزم):**  
  تشمل: ملحقات حزمة `sqflite` وحزم التوقيت.  
  *الالتزام:* إرفاق إشعار حقوق النشر.
- **فئة تراخيص MPL-2.0 (حزمة واحدة):**  
  حزمة `dbus` (عميل D-Bus لنظام Linux). ترخيص MPL-2.0 هو ترخيص على مستوى الملف؛ ولأن حزمة `dbus` تُستخدم كمكتبة مستقلة دون تعديل على ملفاتها الأصلية، فإن شروط الترخيص مستوفاة بالكامل ولا تسري على بقية شيفرات التطبيق.
- **مكونات منصات التشغيل الأصلية (Platform Toolchains):**  
  - **Android:** مكتبات `AndroidX` و `desugar_jdk_libs` (Apache-2.0)، محرك `libsqlite3.so` (Public Domain).
  - **Flutter Engine:** محرك `libflutter.so` / `Flutter.framework` المعتمد على Skia و Impeller و HarfBuzz و BoringSSL و ICU (تراخيص BSD / MIT / Apache / Unicode المتوافقة والمضمّنة في ملف `NOTICES.Z`).

---

## 6. نصوص التراخيص المعيارية (Standard License Texts)

### 6.1 رخصة MIT (MIT License)
```text
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### 6.2 رخصة الخطوط المفتوحة (SIL Open Font License 1.1)
```text
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide development
of collaborative font projects, to support the font creation efforts of
academic and linguistic communities, and to provide a free and open framework
in which fonts may be shared and improved in partnership with others.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining a copy
of the Font Software, to use, study, copy, merge, embed, modify, redistribute,
and sell modified and unmodified copies of the Font Software, subject to the
following conditions:
1) Neither the Font Software nor any of its individual components, in Original
or Modified Versions, may be sold by itself.
2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy contains
the above copyright notice and this license.
3) No Modified Version of the Font Software may use the Reserved Font Name(s)
unless prominent written permission is granted by the corresponding Copyright
Holder.
4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font Software
shall not be used to promote, endorse or advertise any Modified Version.
5) The Font Software, modified or unmodified, in part or in whole, must be
distributed entirely under this license and not under any other license.

TERMINATION & DISCLAIMER
This license becomes null and void if any of the above conditions are not met.
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

### 6.3 رخصة المشاع الإبداعي (Creative Commons Attribution 3.0 Unported - CC BY 3.0)
```text
Creative Commons Attribution 3.0 Unported (CC BY 3.0)

You are free to:
- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:
- Attribution — You must give appropriate credit, provide a link to the license,
  and indicate if changes were made. You may do so in any reasonable manner, but
  not in any way that suggests the licensor endorses you or your use.
- No additional restrictions — You may not apply legal terms or technological
  measures that legally restrict others from doing anything the license permits.

Special Notice for Tanzil Quran Text:
Modification of the Holy Quran text is strictly prohibited. The text is provided
under verification of authenticity by the Tanzil Project (https://tanzil.net).
```

---

### 6.4 رخصة BSD ثلاثية البنود (BSD 3-Clause License)
```text
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

### 6.5 رخصة أباتشي (Apache License, Version 2.0)
```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 7. الخاتمة والجاهزية للنشر (Store Compliance Statement)

يؤكد هذا السجل أن تطبيق **تَدْبِير (Tadbeer)**:
1. **خالٍ من أي تعارضات في التراخيص**، وجميع اعتماداته البرمجية والأصلية متوافقة قانونياً مع ترخيص المشروع الرئيسي ([MIT License](LICENSE)).
2. **يستوفي شروط النشر** على متاجر التطبيقات:
   - **Google Play:** متوافق مع سياسات الخصوصية والأذونات وحقوق الملكية الفكرية.
   - **Apple App Store:** متوافق مع بنود الاستخدام وإشعار التراخيص وملف `PrivacyInfo.xcprivacy`.
   - **F-Droid:** مؤهل بالكامل لمعايير الحزم الحرة مفتوحة المصدر (FOSS) وخالٍ من أي مكونات ثنائية غير حرة (Non-Free Blobs).

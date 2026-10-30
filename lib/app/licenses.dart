/// تراخيص المحتوى المضمّن الذي ليس كوداً: النص القرآني والمعاني والخطوط.
library;

import 'package:flutter/foundation.dart';

/// يسجّل تراخيص المحتوى المضمّن في [LicenseRegistry] لتظهر في صفحة التراخيص
/// داخل التطبيق.
void registerBundledAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['tanzil_quran_text'],
      '''Tanzil Quran Text (Uthmani Script & Mushaf Metadata)
Copyright (C) 2007-2026 Tanzil Project (https://tanzil.net)
Licensed under Creative Commons Attribution 3.0 Unported License (CC BY 3.0).

Terms of Use:
- Permission is granted to copy and distribute verbatim copies of this Quran text,
  but CHANGING IT IS NOT ALLOWED.
- Attribution to Tanzil Project (https://tanzil.net) is required.''',
    );

    yield const LicenseEntryWithLineBreaks(
      <String>['quranpedia_word_meanings'],
      '''Quranpedia.net Open Quranic Encyclopedia Dataset (Version 2026-10-10)
Source: https://quranpedia.net
License: https://quranpedia.net/dumps/LICENSE.md

- Free to use inside apps, websites, bots, and research tools.
- Republishing this data as a downloadable dataset credits Quranpedia.net
  (https://quranpedia.net) with dump version 2026-10-10.
- Classical heritage lexicons (Lisan Al-Arab, Maqayis Al-Lughah, Taj Al-Arus,
  Mufradat Al-Raghib, Al-Tibyan by Ibn Al-Ha'im, Tadhkirat Al-Arib by Ibn Al-Jawzi)
  are in the Public Domain. Contemporary references remain the property of their
  respective authors and publishers.''',
    );

    yield const LicenseEntryWithLineBreaks(
      <String>[
        'Scheherazade New Font',
        'Noto Naskh Arabic Font',
        'Harmattan Font',
        'Lateef Font',
        'Amiri Quran Font',
        'Amiri Font',
      ],
      '''Bundled Quranic & Arabic Fonts:
- Scheherazade New (Version 4.500) — Copyright (c) 1994-2026 SIL Global (https://software.sil.org/scheherazade/)
- Noto Naskh Arabic (Version 2.021) — Copyright 2022 The Noto Project Authors (https://github.com/notofonts/arabic)
- Harmattan (Version 4.400) — Copyright (c) 2004-2025 SIL Global (https://software.sil.org/harmattan/)
- Lateef (Version 4.400) — Copyright (c) 1994-2025 SIL Global (https://software.sil.org/lateef/)
- Amiri Quran (Version 1.003) & Amiri (Version 1.002) — Copyright 2010-2022 The Amiri Project Authors / Khaled Hosny (https://github.com/aliftype/amiri)

Licensed under the SIL Open Font License, Version 1.1 (https://scripts.sil.org/OFL).

-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded, 
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components as
distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to a
new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name as
presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.''',
    );

    yield const LicenseEntryWithLineBreaks(
      <String>['qcf_madinah_mushaf'],
      '''Madinah Mushaf page fonts (QCF v1)
Copyright (C) King Fahd Glorious Quran Printing Complex (https://qurancomplex.gov.sa).
Fonts obtained through Quran Foundation (https://quran.foundation).
Mushaf line layout data: Quran.com API v4, Quran Foundation.
These materials are not covered by the Tadbeer MIT License.''',
    );

    yield const LicenseEntryWithLineBreaks(
      <String>['quran_recitations'],
      '''Recitations are streamed or downloaded on request from Islamic Network
(https://alquran.cloud). Copyright remains with the reciters or their estates.
They are not bundled with the app or covered by the Tadbeer MIT License.''',
    );

    yield const LicenseEntryWithLineBreaks(
      <String>['sahifa_sajjadiyya_wikisource'],
      '''Twelve duas of Al-Sahifa Al-Sajjadiyya: classical text, digitized by
Arabic Wikisource contributors (https://ar.wikisource.org). Paragraphs were
split and five typing errors corrected. Licensed under CC BY-SA 4.0.''',
    );

    yield const LicenseEntryWithLineBreaks(
      <String>['android_pdf_viewer'],
      '''AndroidPdfViewer (https://github.com/marain87/AndroidPdfViewer)
Licensed under the Apache License, Version 2.0.''',
    );
  });
}

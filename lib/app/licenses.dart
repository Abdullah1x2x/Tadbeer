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

Licensed under the SIL Open Font License, Version 1.1 (https://scripts.sil.org/OFL).''',
    );
  });
}

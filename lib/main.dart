import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/local_reminder_service.dart';
import 'core/storage/user_data_store.dart';
import 'features/quran/data/quran_repository.dart';
import 'features/quran/screens/quran_screen.dart';

/// Registers bundled non-Dart asset licenses (Quranic text, Word Meanings dataset,
/// and SIL OFL 1.1 fonts) into Flutter's [LicenseRegistry] so they appear in
/// `showLicensePage` inside the binary distribution on Google Play & App Store.
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

/// Entrypoint for the Tadbeer application.
///
/// EDUCATIONAL NOTE:
/// Tadbeer is 100% offline-first. Initialization sequence:
/// 1. Register bundled third-party asset notices in [LicenseRegistry].
/// 2. Initialize local persistent SQLite user storage ([UserDataStore]).
/// 3. Initialize authentic, verified Uthmani Quran dataset ([QuranRepository]).
/// 4. Initialize local offline reminders ([LocalReminderService]) with deep link payload routing.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledAssetLicenses();

  // 1. Initialize local persistent storage
  await UserDataStore.instance.init();

  // 2. Initialize verified Quran dataset
  await QuranRepository.instance.init();

  // 3. Initialize local reading reminders & synchronize saved schedules
  await LocalReminderService.instance.init(
    onTapped: (payload) {
      if (payload == 'quran_resume') {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const QuranScreen(readingMode: true),
          ),
        );
      }
    },
  );
  await LocalReminderService.instance.syncAllReminders(
    UserDataStore.instance.reminders,
  );

  runApp(const TadbeerApp());
}

/// تهيئة التطبيق قبل أول إطار: البيانات، والتذكيرات، والتلاوة في الخلفية.
///
/// The order matters: the store and the Quran data load first, as every
/// later step reads them.
library;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../data/quran/quran_repository.dart';
import '../data/storage/user_data_store.dart';
import '../features/audio/recitation_handler.dart';
import '../features/duas/data/adhkar_repository.dart';
import '../features/duas/screens/morning_evening_adhkar_screen.dart';
import '../features/journey/portion_reminder.dart';
import '../features/journey/streak_reminder.dart';
import '../features/reminders/local_reminder_service.dart';
import '../features/tasbeeh/tasbeeh_model.dart';
import '../features/widgets/home_widget_sync.dart';
import 'licenses.dart';
import 'main_shell.dart';

/// Prepares everything the first frame needs. The app works offline; only
/// the recitation audio reaches the internet, and only when asked.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledAssetLicenses();

  // 1. Local storage; it reschedules reminders through the reminder service
  // whenever they change.
  UserDataStore.instance.reminderScheduler = LocalReminderService.instance;
  await UserDataStore.instance.init();

  // 2. The Quran dataset.
  await QuranRepository.instance.init();

  // 3. Reminders, rescheduled from what was saved.
  await LocalReminderService.instance.init(onTapped: _openFromReminder);
  await LocalReminderService.instance.syncAllReminders(
    UserDataStore.instance.reminders,
  );

  _attachSyncs();
  await _startBackgroundRecitation();
}

/// Opens the screen a tapped reminder points to.
void _openFromReminder(String? payload) {
  if (payload == 'adhkar_morning' || payload == 'adhkar_evening') {
    // Open the matching adhkar from the Duas tab.
    final navigator = MainShell.showFromOutside(ShellTab.duas);
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => MorningEveningAdhkarScreen(
          initialCategory: payload == 'adhkar_morning'
              ? AdhkarCategory.morning
              : AdhkarCategory.evening,
        ),
      ),
    );
    return;
  }
  if (payload == 'quran_resume') {
    // Open the Mushaf tab at the reading (khatma) position rather than a
    // separate reader; skip the intro when launched from the reminder.
    MainShell.showFromOutside(ShellTab.quran);
  }
}

/// Keeps reminders, the widget and the streak following the reader's data.
void _attachSyncs() {
  // Keeps the khatma reminder's "pages left today" current while reading.
  PortionReminderSync.attach();
  // Warns in the evening before the streak of active days breaks.
  StreakReminderSync.attach();
  // The home-screen widget follows the ayah of the day and the khatma.
  HomeWidgetSync.attach();
  // A completed tasbeeh round counts toward the reading streak.
  TasbeehRepository.instance.onTargetReached = () =>
      UserDataStore.instance.markActiveDay();
}

/// The recitation plays on in the background, with its controls in the
/// notification. Platforms without it (desktop) play in the app only.
Future<void> _startBackgroundRecitation() async {
  try {
    RecitationHandler.instance = await AudioService.init(
      builder: RecitationHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.tadbeer.app.recitation',
        androidNotificationChannelName: 'التلاوة',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  } on Object catch (e) {
    debugPrint('Background recitation unavailable: $e');
  }
}

/// تهيئة التطبيق قبل أول إطار: البيانات، والتذكيرات، والتلاوة في الخلفية.
///
/// الترتيب مهم: المخزن وبيانات القرآن أولاً، لأن كل ما بعدهما يقرأ منهما.
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

/// يجهّز كل ما يحتاجه أول إطار.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledAssetLicenses();

  // 1. التخزين المحلي، ويعيد جدولة التذكيرات عبر خدمتها كلما تغيّرت.
  UserDataStore.instance.reminderScheduler = LocalReminderService.instance;
  await UserDataStore.instance.init();

  // 2. بيانات القرآن.
  await QuranRepository.instance.init();

  // 3. التذكيرات، تُجدول من جديد مما حُفظ.
  await LocalReminderService.instance.init(onTapped: _openFromReminder);
  await LocalReminderService.instance.syncAllReminders(
    UserDataStore.instance.reminders,
  );

  _attachSyncs();
  await _startBackgroundRecitation();
}

/// يفتح الشاشة التي يشير إليها التذكير المنقور.
void _openFromReminder(String? payload) {
  if (payload == 'adhkar_morning' || payload == 'adhkar_evening') {
    // يفتح الأذكار المطابقة من تبويب الأدعية.
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
    // يفتح المصحف عند موضع القراءة، متجاوزاً شاشة الترحيب.
    MainShell.showFromOutside(ShellTab.quran);
  }
}

/// يجعل التذكيرات والودجت وسلسلة الأيام تتبع بيانات القارئ.
void _attachSyncs() {
  // يُبقي "الصفحات المتبقية اليوم" في تذكير الختمة محدّثة أثناء القراءة.
  PortionReminderSync.attach();
  // ينبّه مساءً قبل أن تنقطع سلسلة الأيام.
  StreakReminderSync.attach();
  // الودجت يتبع آية اليوم والختمة.
  HomeWidgetSync.attach();
  // إتمام جولة تسبيح يُحتسب في سلسلة الأيام.
  TasbeehRepository.instance.onTargetReached = () =>
      UserDataStore.instance.markActiveDay();
}

/// تستمر التلاوة في الخلفية مع أزرارها في الإشعار؛ وعلى سطح المكتب تعمل داخل
/// التطبيق فقط.
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

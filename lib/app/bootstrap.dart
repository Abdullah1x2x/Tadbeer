/// تهيئة التطبيق قبل أول إطار: البيانات، والتذكيرات، والتلاوة في الخلفية.
///
/// الترتيب مهم: المخزن وبيانات القرآن أولاً، لأن كل ما بعدهما يقرأ منهما.
library;

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import '../data/models/user_settings_model.dart';
import '../data/quran/quran_repository.dart';
import '../data/storage/user_data_store.dart';
import '../features/audio/desktop_player.dart';
import '../features/audio/quran_audio.dart';
import '../features/audio/recitation_handler.dart';
import '../features/duas/data/adhkar_repository.dart';
import '../features/duas/screens/morning_evening_adhkar_screen.dart';
import '../features/journey/portion_reminder.dart';
import '../features/journey/streak_reminder.dart';
import '../features/quran/qcf/qcf_layout.dart';
import '../features/reminders/local_reminder_service.dart';
import '../features/tasbeeh/tasbeeh_model.dart';
import '../features/widgets/home_widget_sync.dart';
import 'app.dart';
import 'licenses.dart';
import 'localization.dart';
import 'main_shell.dart';

/// يجهّز كل ما يحتاجه أول إطار.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledAssetLicenses();
  _startDesktopAudio();

  // 1. التخزين المحلي، وبيانات القرآن، والتسبيح بالتوازي.
  UserDataStore.instance.reminderScheduler = LocalReminderService.instance;
  await Future.wait([
    UserDataStore.instance.init(),
    TasbeehRepository.instance.init(),
    QuranRepository.instance.init(),
  ]);

  // 2. التذكيرات، تُجدول من جديد مما حُفظ.
  await LocalReminderService.instance.init(onTapped: _openFromReminder);
  await LocalReminderService.instance.syncAllReminders(
    UserDataStore.instance.reminders,
  );

  _attachSyncs();
  await _startBackgroundRecitation();

  // فهرس البحث يُبنى في الخلفية، فيجهز قبل أول بحث.
  unawaited(
    QuranRepository.instance.warmSearchIndex().catchError((Object e) {
      // يُبنى عند أول بحث إن تعذّر هنا.
      debugPrint('Warming the search index failed: $e');
    }),
  );

  // تخطيط مصحف المدينة يُفك في الخلفية، فيجهز قبل فتح المصحف.
  if (UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah) {
    unawaited(QcfLayout.instance.init());
  }
}

/// الهاتف عمودي دائماً؛ والجهاز اللوحي (أقصر بعديه 600 فأكثر) يبقى يدور،
/// فيعرض المصحف صفحتين متقابلتين بالعرض.
///
/// يُستدعى بعد أول إطار: مقاس الشاشة قد يكون صفراً قبله. ويُقاس من الشاشة لا
/// من النافذة، فلا يغيّره تقسيم الشاشة.
void lockPhonesToPortrait() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return;
  final view = views.first;
  final display = view.display;
  final shortest = display.size.isEmpty
      ? view.physicalSize.shortestSide / view.devicePixelRatio
      : display.size.shortestSide / display.devicePixelRatio;
  if (shortest > 0 && shortest < 600) {
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
  }
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

/// يشغّل التلاوة على لينكس وويندوز عبر libmpv؛ أندرويد وiOS لهما مشغّلهما.
///
/// على لينكس تأتي libmpv من النظام (حزمة mpv-libs أو libmpv2)؛ ودونها يقول
/// زر التلاوة ما يُثبَّت بدل أن يصمت.
void _startDesktopAudio() {
  if (Platform.isLinux && !linuxHasLibmpv()) {
    QuranAudio.onPlayerMissing = _showPlayerMissing;
    return;
  }
  try {
    JustAudioMediaKit.ensureInitialized();
  } on Object catch (e) {
    debugPrint('Desktop audio unavailable: $e');
  }
}

void _showPlayerMissing() {
  final messenger = appScaffoldMessengerKey.currentState;
  final context = appScaffoldMessengerKey.currentContext;
  if (messenger == null || context == null) return;
  var osRelease = '';
  try {
    osRelease = File('/etc/os-release').readAsStringSync();
  } on FileSystemException {
    // توزيعة لا تصف نفسها: يُذكر اسم الحزمة وحده.
  }
  final command = mpvInstallCommand(osRelease);
  final l10n = context.l10n;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.audioPlayerMissing(command)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
          label: l10n.copy,
          onPressed: () => Clipboard.setData(ClipboardData(text: command)),
        ),
      ),
    );
}

/// تستمر التلاوة في الخلفية مع أزرارها في الإشعار؛ وعلى سطح المكتب تعمل داخل
/// التطبيق فقط.
Future<void> _startBackgroundRecitation() async {
  try {
    RecitationHandler.instance = await AudioService.init(
      builder: RecitationHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'org.tadbeer.quran.recitation',
        androidNotificationChannelName: 'التلاوة',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_stat_tadbeer',
      ),
    );
  } on Object catch (e) {
    debugPrint('Background recitation unavailable: $e');
  }
}

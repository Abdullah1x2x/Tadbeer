import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/localization.dart';
import '../daily/ayah_of_day_card.dart';
import '../journey/portion_reminder.dart';
import '../journey/streak_reminder.dart';
import '../../data/models/reminder_model.dart';
import '../../data/storage/user_data_store.dart';

/// تذكيرات القراءة على الجهاز دون إنترنت.
///
/// نوعان يختار القارئ بينهما: [ReminderAlertType.notification] إشعار عادي،
/// و[ReminderAlertType.alarm] منبه كامل: صوت المنبه بنغمته الافتراضية، ورنين
/// مستمر، واهتزاز متكرر، وظهور على شاشة القفل.
class LocalReminderService implements ReminderScheduler {
  static final LocalReminderService instance = LocalReminderService._internal();
  LocalReminderService._internal();

  static const String notificationChannelId = 'tadbeer_reminders';
  static const String notificationChannelName = 'تنبيهات ورد القرآن (إشعارات)';
  static const String notificationChannelDescription =
      'إشعار محلي بقراءة وتدبّر القرآن الكريم';

  static const String alarmChannelId = 'tadbeer_alarms';
  static const String alarmChannelName = 'منبه ورد القرآن (رنين كالمنبه)';
  static const String alarmChannelDescription =
      'تنبيه بصوت رنين المنبه المستمر لقراءة وتدبّر القرآن الكريم';

  static const int testNotificationId = 999998;
  static const int testAlarmId = 999999;

  /// إجراءا الإشعار: تأجيله، وتسجيل القراءة.
  static const String snoozeActionId = 'snooze';
  static const String markReadActionId = 'mark_read';

  /// مدة التأجيل.
  static const Duration snoozeDelay = Duration(minutes: 10);

  /// قناة أندرويد لحالة الجهاز وفتح إعدادات التطبيق.
  static const MethodChannel _device = MethodChannel('tadbeer/device');

  /// `Notification.FLAG_INSISTENT` في أندرويد (4): يعيد الصوت حتى يُغلق الإشعار
  /// أو يُنقر.
  static final Int32List _insistentAlarmFlags = Int32List.fromList(const [4]);

  /// نمط اهتزاز المنبه المتكرر، بالمللي ثانية.
  static final Int64List _alarmVibrationPattern = Int64List.fromList(const [
    0,
    1000,
    500,
    1000,
    500,
    1000,
  ]);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  AppLifecycleListener? _lifecycle;

  bool get isInitialized => _isInitialized;

  void Function(String? payload)? onNotificationTapped;

  /// هل يعمل التطبيق داخل اختبارات Flutter؛ عندها لا تُستدعى الإضافة.
  bool get _isRunningInFlutterTest {
    try {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      return bindingType.contains('TestWidgetsFlutterBinding') ||
          bindingType.contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  /// يهيّئ المناطق الزمنية وقنوات الإشعارات، ويقرأ إشعار الإقلاع، ويشغّل المؤقت
  /// البديل على سطح المكتب.
  Future<void> init({void Function(String? payload)? onTapped}) async {
    if (onTapped != null) {
      onNotificationTapped = onTapped;
    }
    if (_isInitialized) return;

    await _initializeTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
    final linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open Tadbeer',
      defaultIcon: AssetsLinuxIcon('assets/icons/app_icon.png'),
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'تَدْبِير',
      appUserModelId: 'Com.Tadbeer.QuranApp',
      guid: 'a8c4e120-5b91-4d73-91e4-63c27f8419a2',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          switch (response.actionId) {
            case 'dismiss_alarm':
              return;
            case snoozeActionId:
              snooze(response.id);
              return;
            case markReadActionId:
              _markRead();
              return;
          }
          onNotificationTapped?.call(response.payload);
        },
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationAction,
      );
      _isInitialized = true;
      if (!_isRunningInFlutterTest) {
        _lifecycle ??= AppLifecycleListener(onResume: _resyncIfZoneChanged);
      }

      await _createAndroidNotificationChannels();
      await _checkAppLaunchNotification();
    } catch (e) {
      debugPrint('Notification plugin initialize error: $e');
    }
  }

  /// يحمّل قاعدة المناطق الزمنية ويضبط منطقة الجهاز.
  Future<void> _initializeTimeZone() async {
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Failed to initialize timezones: $e');
      return;
    }
    await _applyDeviceTimeZone();
  }

  /// يعيد جدولة التذكيرات إن تغيّرت منطقة الجهاز منذ آخر مرة، كالسفر.
  Future<void> _resyncIfZoneChanged() async {
    final before = tz.local.name;
    await _applyDeviceTimeZone();
    if (tz.local.name == before) return;
    await syncAllReminders(UserDataStore.instance.reminders);
  }

  /// يضبط منطقة الجهاز في قاعدة المناطق المحمّلة.
  Future<void> _applyDeviceTimeZone() async {
    try {
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
        debugPrint('Local timezone initialized to: ${timeZoneInfo.identifier}');
        return;
      } catch (tzError) {
        debugPrint(
          'Could not resolve device timezone via plugin, trying offset fallback: $tzError',
        );
      }

      final localOffset = DateTime.now().timeZoneOffset;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.timeZone(nowMs).offset == localOffset) {
          tz.setLocalLocation(location);
          debugPrint('Fallback timezone set to: ${location.name}');
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize timezones: $e');
    }
  }

  /// ينشئ قناتي الإشعار العادي والمنبه في أندرويد.
  Future<void> _createAndroidNotificationChannels() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        // ١. قناة الإشعار العادي.
        const notificationChannel = AndroidNotificationChannel(
          notificationChannelId,
          notificationChannelName,
          description: notificationChannelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
        );
        await androidImplementation.createNotificationChannel(
          notificationChannel,
        );

        // ٢. قناة المنبه: بمستوى صوت المنبه ونغمته الافتراضية.
        final alarmChannel = AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDescription,
          importance: Importance.max,
          playSound: true,
          sound: const UriAndroidNotificationSound(
            'content://settings/system/alarm_alert',
          ),
          enableVibration: true,
          vibrationPattern: _alarmVibrationPattern,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
        await androidImplementation.createNotificationChannel(alarmChannel);
      }
    } catch (e) {
      debugPrint('Could not create Android notification channels: $e');
    }
  }

  /// إن فُتح التطبيق بنقر إشعار، يوجّه القارئ إلى وجهته.
  Future<void> _checkAppLaunchNotification() async {
    if (_isRunningInFlutterTest) return;
    try {
      final launchDetails = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final actionId = launchDetails.notificationResponse?.actionId;
        if (actionId == 'dismiss_alarm') return;
        if (actionId == markReadActionId) {
          await _markRead();
          return;
        }
        final payload = launchDetails.notificationResponse!.payload;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onNotificationTapped?.call(payload);
        });
      }
    } catch (e) {
      debugPrint('Could not inspect notification app launch details: $e');
    }
  }

  /// يطلب إذن الإشعارات (أندرويد 13، وiOS وmacOS والويب)، ومعه المنبهات الدقيقة
  /// إن طُلب [exactAlarms]؛ فطلبها في أندرويد 14 يفتح الإعدادات مباشرة.
  Future<bool> requestPermissions({bool exactAlarms = false}) async {
    if (_isRunningInFlutterTest) return true;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        if (exactAlarms) await requestExactAlarms();
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? granted ?? false;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final macosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();

      if (macosImplementation != null) {
        final granted = await macosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final webImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >();

      if (webImplementation != null) {
        final granted = await webImplementation
            .requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  /// يفتح إعداد المنبهات الدقيقة في أندرويد إن لم تكن مسموحة.
  Future<void> requestExactAlarms() async {
    try {
      final android = _android;
      if (await android?.canScheduleExactNotifications() == false) {
        await android!.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Exact alarm permission check note: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// هل تصل الإشعارات، وهل تُضبط المنبهات بدقة؛ خارج أندرويد كلاهما نعم.
  Future<({bool notifications, bool exactAlarms})> permissionStatus() async {
    const allGood = (notifications: true, exactAlarms: true);
    if (_isRunningInFlutterTest) return allGood;
    final android = _android;
    if (android == null) return allGood;
    try {
      return (
        notifications: await android.areNotificationsEnabled() ?? true,
        exactAlarms: await android.canScheduleExactNotifications() ?? true,
      );
    } catch (e) {
      debugPrint('permissionStatus: $e');
      return allGood;
    }
  }

  /// صانع الهاتف في أندرويد (مثل `Xiaomi`)، أو null.
  Future<String?> manufacturer() async {
    if (_isRunningInFlutterTest || _android == null) return null;
    try {
      return await _device.invokeMethod<String>('manufacturer');
    } catch (e) {
      debugPrint('manufacturer: $e');
      return null;
    }
  }

  /// يفتح إعدادات إشعارات التطبيق، أو صفحة التطبيق في الإعدادات (للبطارية).
  Future<void> openSystemSettings({bool notifications = false}) async {
    try {
      await _device.invokeMethod<void>(
        notifications ? 'openNotificationSettings' : 'openAppSettings',
      );
    } catch (e) {
      debugPrint('openSystemSettings: $e');
    }
  }

  /// إعدادات الإشعار أو المنبه لكل منصة بحسب نوع التنبيه.
  ///
  /// [withRead] يضيف زر «قرأت» لتذكيرات القرآن، و[bigText] يعرض النص كاملاً.
  NotificationDetails _buildNotificationDetails(
    ReminderAlertType alertType, {
    bool withRead = false,
    String? bigText,
  }) {
    final strings = _strings;
    final style = bigText == null ? null : BigTextStyleInformation(bigText);
    final snoozeAction = AndroidNotificationAction(
      snoozeActionId,
      strings.snoozeAction,
      cancelNotification: false,
    );
    if (alertType == ReminderAlertType.alarm) {
      final androidAlarmDetails = AndroidNotificationDetails(
        alarmChannelId,
        alarmChannelName,
        channelDescription: alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: _alarmVibrationPattern,
        additionalFlags: _insistentAlarmFlags,
        autoCancel: true,
        ongoing: false,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: style,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'open_quran',
            strings.openMushaf,
            showsUserInterface: true,
            cancelNotification: true,
          ),
          snoozeAction,
          AndroidNotificationAction(
            'dismiss_alarm',
            strings.stopAlarm,
            cancelNotification: true,
          ),
        ],
      );

      const darwinAlarmDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const linuxAlarmDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      const windowsAlarmDetails = WindowsNotificationDetails();

      return NotificationDetails(
        android: androidAlarmDetails,
        iOS: darwinAlarmDetails,
        macOS: darwinAlarmDetails,
        linux: linuxAlarmDetails,
        windows: windowsAlarmDetails,
      );
    }

    // الإشعار العادي.
    final androidNotificationDetails = AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      styleInformation: style,
      actions: <AndroidNotificationAction>[
        // «قرأت» يفتح التطبيق ليسجّل القراءة في نفس عزلة المخزن، فلا تتعارض
        // كتابتان على قاعدة البيانات.
        if (withRead)
          AndroidNotificationAction(
            markReadActionId,
            strings.markReadAction,
            showsUserInterface: true,
            cancelNotification: true,
          ),
        snoozeAction,
      ],
    );

    const darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const linuxNotificationDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
    );

    const windowsNotificationDetails = WindowsNotificationDetails();

    return NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
      linux: linuxNotificationDetails,
      windows: windowsNotificationDetails,
    );
  }

  /// يعرض إشعاراً أو منبهاً فوراً.
  Future<bool> showImmediateNotification({
    int id = testNotificationId,
    required String title,
    required String body,
    ReminderAlertType alertType = ReminderAlertType.notification,
    String payload = 'quran_resume',
  }) async {
    if (_isRunningInFlutterTest) return true;
    try {
      if (!_isInitialized) {
        await init();
      }
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _buildNotificationDetails(alertType),
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
      return false;
    }
  }

  /// يرسل إشعاراً أو منبهاً تجريبياً فوراً، بعد التحقق من الإذن.
  Future<bool> showTestNotification({
    ReminderAlertType alertType = ReminderAlertType.notification,
    String? title,
    String? body,
  }) async {
    final isAlarm = alertType == ReminderAlertType.alarm;
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint('Notification permission was not granted.');
    }
    return showImmediateNotification(
      id: isAlarm ? testAlarmId : testNotificationId,
      title:
          title ??
          (isAlarm ? _strings.testAlarmTitle : _strings.testNoticeTitle),
      body:
          body ?? (isAlarm ? _strings.testAlarmBody : _strings.testNoticeBody),
      alertType: alertType,
      payload: 'quran_resume',
    );
  }

  /// المعرّف الرقمي الأساسي لإشعارات التذكير الفرعية.
  int _baseNotificationId(String reminderId) {
    return (stableHash(reminderId) % 10000000) * 10;
  }

  /// يلغي كل إشعارات التذكير المجدولة في النظام.
  Future<void> cancelReminder(ReminderItem reminder) async {
    if (_isRunningInFlutterTest) return;
    final baseId = _baseNotificationId(reminder.id);
    for (int i = 0; i <= 7; i++) {
      try {
        await _notificationsPlugin.cancel(id: baseId + i);
      } catch (e) {
        debugPrint('cancelReminder: ${baseId + i}: $e');
      }
    }
    if (reminder.id == portionReminderId) {
      // ويُلغى معها الاحتياطي اليومي بعدها.
      for (int i = 0; i <= portionReminderDays; i++) {
        try {
          await _notificationsPlugin.cancel(id: _portionBaseId + i);
        } catch (e) {
          debugPrint('cancelReminder: portion $i: $e');
        }
      }
    }
    if (reminder.id == streakReminderId) {
      for (int i = 0; i < 2; i++) {
        try {
          await _notificationsPlugin.cancel(id: _streakBaseId + i);
        } catch (e) {
          debugPrint('cancelReminder: streak $i: $e');
        }
      }
    }
  }

  /// نصوص الإشعارات بلغة التطبيق.
  AppStrings get _strings => AppStrings(
    AppLanguage.fromCode(UserDataStore.instance.settings.languageCode),
  );

  /// اسم القارئ، لتناديه به التذكيرات.
  String get _readerName => UserDataStore.instance.settings.userName;

  /// معرّفات إشعارات ورد الختمة، فوق كل معرّفات التذكيرات المحسوبة.
  static const int _portionBaseId = 100000000;

  /// معرّفات إشعارات السلسلة، فوق إشعارات الورد.
  static const int _streakBaseId = 100000100;

  /// معرّف التذكير المؤجَّل؛ تأجيل جديد يحل محل السابق.
  static const int _snoozeId = 100000200;

  /// مفتاح ترحيل أرقام الإشعارات من `String.hashCode` إلى [stableHash].
  static const _idsKey = 'notification_ids';

  /// يؤجّل الإشعار المعروض [id] مدة [snoozeDelay] بنصه ونوعه.
  ///
  /// يعمل أيضاً في عزلة الخلفية، فلا يعتمد إلا على الإشعار نفسه.
  Future<void> snooze(int? id) async {
    if (id == null) return;
    try {
      final shown = (await _notificationsPlugin.getActiveNotifications())
          .where((n) => n.id == id)
          .firstOrNull;
      await _notificationsPlugin.cancel(id: id);
      if (shown == null) return;
      final alertType = shown.channelId == alarmChannelId
          ? ReminderAlertType.alarm
          : ReminderAlertType.notification;
      final payload = shown.payload ?? 'quran_resume';
      await _zonedScheduleSafe(
        id: _snoozeId,
        title: shown.title ?? '',
        body: shown.body ?? '',
        // لحظة مطلقة، فلا تحتاج قاعدة المناطق في عزلة الخلفية.
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(snoozeDelay),
        details: _buildNotificationDetails(
          alertType,
          withRead: payload == 'quran_resume',
          bigText: shown.body,
        ),
        preferredMode: await _resolveAndroidScheduleMode(alertType),
        payload: payload,
      );
    } catch (e) {
      debugPrint('snooze: $e');
    }
  }

  /// «قرأت»: يتم ورد الختمة إن بقي منه شيء اليوم، وإلا يحسب اليوم في السلسلة.
  Future<void> _markRead() async {
    final store = UserDataStore.instance;
    final journey = store.journey;
    final plan = journey.plan;
    if (plan != null &&
        !plan.isComplete &&
        journey.portionPagesOn(DateTime.now()) < plan.pagesPerDay) {
      await store.completeTodayPortion();
    } else {
      await store.markActiveDay();
    }
  }

  /// يلغي كل إشعارات التطبيق المجدولة.
  @override
  Future<void> cancelAll() async {
    if (_isRunningInFlutterTest) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// يطابق جدولة النظام مع التذكيرات المحفوظة.
  @override
  Future<void> syncAllReminders(List<ReminderItem> reminders) async {
    if (_isRunningInFlutterTest) return;
    final store = UserDataStore.instance;
    if (store.featureState(_idsKey)['v'] != 2) {
      // أرقام الإصدار السابق لا تُعرف بعد تغيّر البصمة؛ فيُلغى كل ما جُدول.
      try {
        await _notificationsPlugin.cancelAllPendingNotifications();
      } catch (e) {
        debugPrint('cancelAllPendingNotifications: $e');
      }
      await store.saveFeatureState(_idsKey, {'v': 2});
    }
    for (final reminder in reminders) {
      if (reminder.isEnabled) {
        await scheduleReminder(reminder, requestPermissionIfNeeded: false);
      } else {
        await cancelReminder(reminder);
      }
    }
  }

  /// نمط الجدولة في أندرويد: منبه دقيق إن أُذن به، وإلا غير دقيق.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode(
    ReminderAlertType alertType,
  ) async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final canExact = await androidImplementation
            .canScheduleExactNotifications();
        if (canExact == false) {
          return AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }
    } catch (e) {
      debugPrint('Could not check exact alarms: $e');
    }
    return alertType == ReminderAlertType.alarm
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// يجدول إشعاراً أو منبهاً بالمنطقة الزمنية، ويتراجع إلى الجدولة غير الدقيقة
  /// عند غياب الإذن.
  Future<void> _zonedScheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode preferredMode,
    DateTimeComponents? matchDateTimeComponents,
    required String payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: preferredMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on UnimplementedError {
      debugPrint(
        'Native zonedSchedule not supported on this platform; using in-app timer fallback.',
      );
    } catch (e) {
      if (preferredMode != AndroidScheduleMode.inexactAllowWhileIdle) {
        debugPrint(
          'Exact/alarmClock schedule failed ($e), retrying with inexactAllowWhileIdle...',
        );
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
        } catch (fallbackError) {
          debugPrint('Fallback schedule also failed: $fallbackError');
        }
      } else {
        debugPrint('Error scheduling reminder: $e');
      }
    }
  }

  /// يجدول تذكيراً بحسب تكراره (مرة، يومياً، أيام محددة) ونوع تنبيهه.
  Future<void> scheduleReminder(
    ReminderItem reminder, {
    bool requestPermissionIfNeeded = true,
  }) async {
    if (_isRunningInFlutterTest) return;
    if (!_isInitialized) {
      await init();
    }

    if (!reminder.isEnabled) {
      await cancelReminder(reminder);
      return;
    }

    if (requestPermissionIfNeeded) {
      await requestPermissions();
    }

    await cancelReminder(reminder);

    final scheduleMode = await _resolveAndroidScheduleMode(reminder.alertType);

    if (reminder.id == portionReminderId) {
      await _schedulePortion(
        reminder,
        _buildNotificationDetails(reminder.alertType, withRead: true),
        scheduleMode,
      );
      return;
    }
    if (reminder.id == streakReminderId) {
      await _scheduleStreak(
        reminder,
        _buildNotificationDetails(reminder.alertType, withRead: true),
        scheduleMode,
      );
      return;
    }

    final title = reminder.title.trim().isNotEmpty
        ? reminder.title.trim()
        : 'ورد القرآن الكريم';
    // تذكيرات الأذكار تفتح الأذكار بدل المصحف.
    final isAdhkar = reminder.id.startsWith('adhkar_');
    final strings = _strings;
    final greeting = strings.toReader(
      _readerName,
      isAdhkar ? strings.reminderAdhkarBody : strings.reminderQuranBody,
    );
    // آية اليوم تتجدد كلما أعيدت الجدولة، أي مع كل فتح للتطبيق.
    final body = isAdhkar ? greeting : '$greeting\n${_ayahOfDay()}'.trim();
    final payload = isAdhkar ? reminder.id : 'quran_resume';
    final details = _buildNotificationDetails(
      reminder.alertType,
      withRead: !isAdhkar,
      bigText: body,
    );

    final baseId = _baseNotificationId(reminder.id);

    try {
      final now = tz.TZDateTime.now(tz.local);

      if (reminder.repeatMode == ReminderRepeatMode.once) {
        // تذكير "مرة واحدة" فات موعده قد رنّ: يُعطّل بدل جدولته للغد.
        if (reminder.hasOnceReminderFired()) {
          await _markOnceReminderFired(reminder);
          return;
        }

        tz.TZDateTime scheduledDate;
        final existingTarget = reminder.scheduledFor;
        if (existingTarget != null) {
          // يحتفظ بالموعد الأصلي (عند المزامنة بعد إعادة التشغيل مثلاً).
          scheduledDate = tz.TZDateTime.from(existingTarget, tz.local);
        } else {
          scheduledDate = nextDailyTime(now, reminder.hour, reminder.minute);
          // يحفظ الموعد بدقة، لتعرف المزامنات اللاحقة أنه رنّ.
          await UserDataStore.instance.putReminder(
            reminder.copyWith(scheduledFor: scheduledDate.toLocal()),
          );
        }

        await _zonedScheduleSafe(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          details: details,
          preferredMode: scheduleMode,
          payload: payload,
        );
      } else if (reminder.repeatMode == ReminderRepeatMode.daily) {
        final scheduledDate = nextDailyTime(
          now,
          reminder.hour,
          reminder.minute,
        );

        await _zonedScheduleSafe(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          details: details,
          preferredMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else if (reminder.repeatMode == ReminderRepeatMode.weekdays) {
        final days = reminder.selectedDays.isEmpty
            ? [1, 2, 3, 4, 5, 6, 7]
            : reminder.selectedDays;

        for (final day in days) {
          final scheduledDate = nextWeekdayTime(
            now,
            day,
            reminder.hour,
            reminder.minute,
          );
          await _zonedScheduleSafe(
            id: baseId + day,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            details: details,
            preferredMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  /// ورد الختمة: إشعار لكل يوم بصفحاته المتبقية.
  Future<void> _schedulePortion(
    ReminderItem reminder,
    NotificationDetails details,
    AndroidScheduleMode scheduleMode,
  ) async {
    final store = UserDataStore.instance;
    final strings = _strings;
    final notices = portionNotices(
      store.journey,
      DateTime.now(),
      hour: reminder.hour,
      minute: reminder.minute,
    );
    for (var i = 0; i < notices.length; i++) {
      await _zonedScheduleSafe(
        id: _portionBaseId + i,
        title: strings.toReader(
          _readerName,
          strings.portionLeftTitle(notices[i].pages),
        ),
        body: strings.portionLeftBody,
        scheduledDate: tz.TZDateTime.from(notices[i].at, tz.local),
        details: details,
        preferredMode: scheduleMode,
        payload: 'quran_resume',
      );
    }
    // بعد آخر الأيام المجدولة: تذكير يومي عام، حتى يُفتح التطبيق فيُجدول من جديد.
    final fallback = portionFallbackAt(
      store.journey,
      DateTime.now(),
      hour: reminder.hour,
      minute: reminder.minute,
    );
    if (fallback != null) {
      await _zonedScheduleSafe(
        id: _portionBaseId + portionReminderDays,
        title: strings.toReader(_readerName, strings.portionDueTitle),
        body: strings.portionLeftBody,
        scheduledDate: tz.TZDateTime.from(fallback, tz.local),
        details: details,
        preferredMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'quran_resume',
      );
    }
  }

  /// نص آية اليوم، أو فراغ إن لم تجهز بيانات القرآن.
  String _ayahOfDay() {
    try {
      return '﴿${AyahOfTheDay.forDay(DateTime.now()).rawText.trim()}﴾';
    } catch (e) {
      debugPrint('ayahOfDay: $e');
      return '';
    }
  }

  /// السلسلة: إشعار الليلة إن لم يكن في اليوم نشاط بعد، أو إشعار الغد.
  Future<void> _scheduleStreak(
    ReminderItem reminder,
    NotificationDetails details,
    AndroidScheduleMode scheduleMode,
  ) async {
    final strings = _strings;
    final notices = streakNotices(
      UserDataStore.instance.journey,
      DateTime.now(),
      hour: reminder.hour,
      minute: reminder.minute,
    );
    for (var i = 0; i < notices.length; i++) {
      await _zonedScheduleSafe(
        id: _streakBaseId + i,
        title: strings.toReader(
          _readerName,
          strings.streakAtRiskTitle(notices[i].streak),
        ),
        body: strings.streakAtRiskBody,
        scheduledDate: tz.TZDateTime.from(notices[i].at, tz.local),
        details: details,
        preferredMode: scheduleMode,
        payload: 'quran_resume',
      );
    }
  }

  /// يعطّل تذكير "مرة واحدة" بعد أن رنّ، ويلغي ما بقي من إشعاراته.
  Future<void> _markOnceReminderFired(ReminderItem reminder) async {
    await cancelReminder(reminder);
    final latest = UserDataStore.instance.reminders
        .where((r) => r.id == reminder.id)
        .firstOrNull;
    // يُعطّل فقط إن كان التذكير المحفوظ ما زال على نفس الموعد، فقد يكون القارئ
    // عدّله.
    if (latest != null &&
        latest.isEnabled &&
        latest.scheduledFor == reminder.scheduledFor) {
      await UserDataStore.instance.putReminder(
        latest.copyWith(isEnabled: false),
      );
    }
  }
}

/// أول [hour]:[minute] بعد [now]، بتوقيت [now] نفسه ولو تغيّر التوقيت الصيفي.
tz.TZDateTime nextDailyTime(tz.TZDateTime now, int hour, int minute) {
  final today = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  return today.isAfter(now)
      ? today
      : tz.TZDateTime(
          now.location,
          now.year,
          now.month,
          now.day + 1,
          hour,
          minute,
        );
}

/// أول [hour]:[minute] في [dayOfWeek] بعد [now].
tz.TZDateTime nextWeekdayTime(
  tz.TZDateTime now,
  int dayOfWeek,
  int hour,
  int minute,
) {
  var next = nextDailyTime(now, hour, minute);
  while (next.weekday != dayOfWeek) {
    next = tz.TZDateTime(
      now.location,
      next.year,
      next.month,
      next.day + 1,
      hour,
      minute,
    );
  }
  return next;
}

/// بصمة FNV-1a بـ32 بت لـ[s]، ثابتة بين إصدارات Dart بخلاف `String.hashCode`.
int stableHash(String s) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(s)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// إجراءات الإشعار التي لا تفتح التطبيق، في عزلة الخلفية.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationAction(
  NotificationResponse response,
) async {
  if (response.actionId == LocalReminderService.snoozeActionId) {
    await LocalReminderService.instance.snooze(response.id);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/localization.dart';
import '../../features/journey/portion_reminder.dart';
import '../../features/journey/streak_reminder.dart';
import '../../features/reminders/reminder_model.dart';
import '../storage/user_data_store.dart';

/// Local offline reminder service for Quran recitation and tadbeer alarms.
///
/// Supports two user-selectable alert modes:
/// 1. [ReminderAlertType.notification] — Standard notification in the notification bar.
/// 2. [ReminderAlertType.alarm] — Full alarm-style alert using the device alarm
///    audio stream, default alarm ringtone, insistent continuous ringing flag,
///    repeating vibration pattern, and full-screen lockscreen wake intent.
class LocalReminderService {
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

  /// Android `Notification.FLAG_INSISTENT` = 4: repeats audio until dismissed or tapped.
  static final Int32List _insistentAlarmFlags = Int32List.fromList(const [4]);

  /// Repeating vibration pattern for alarm mode (ms).
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

  /// ما إذا كانت خدمة التنبيهات والمنبهات قد تمت تهيئتها.
  bool get isInitialized => _isInitialized;

  Timer? _fallbackTimer;
  String? _lastTriggeredMinuteKey;

  void Function(String? payload)? onNotificationTapped;

  /// التحقق مما إذا كان التطبيق يعمل حالياً داخل بيئة اختبارات Flutter.
  bool get _isRunningInFlutterTest {
    try {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      return bindingType.contains('TestWidgetsFlutterBinding') ||
          bindingType.contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  /// Initializes timezone data, native platform notification & alarm channels,
  /// cold-start launch payloads, and fallback timers for desktop/Linux.
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
          if (response.actionId == 'dismiss_alarm') {
            return;
          }
          onNotificationTapped?.call(response.payload);
        },
      );
      _isInitialized = true;

      await _createAndroidNotificationChannels();
      await _checkAppLaunchNotification();
      _startFallbackTimerIfNeeded();
    } catch (e) {
      debugPrint('Notification plugin initialize error: $e');
    }
  }

  /// تهيئة قاعدة بيانات المناطق الزمنية وضبط المنطقة الزمنية المحلية للجهاز.
  Future<void> _initializeTimeZone() async {
    try {
      tz.initializeTimeZones();
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

  /// إنشاء قناتي الإشعارات والمنبه الصوتي على نظام أندرويد.
  Future<void> _createAndroidNotificationChannels() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        // 1. Standard Notification Channel
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

        // 2. Alarm Channel (uses device Alarm volume stream & default alarm sound)
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

  /// التحقق مما إذا كان فتح التطبيق قد تم عبر النقر على إشعار أو منبه لتوجيه المستخدم.
  Future<void> _checkAppLaunchNotification() async {
    if (_isRunningInFlutterTest) return;
    try {
      final launchDetails = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        if (launchDetails.notificationResponse?.actionId == 'dismiss_alarm') {
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

  /// Linux and Web do not support background OS `zonedSchedule`.
  /// When running on those platforms, a lightweight timer checks once every
  /// 20 seconds so active reminders still trigger while the app is open.
  void _startFallbackTimerIfNeeded() {
    if (_isRunningInFlutterTest) return;
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) return;

    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkInAppFallbackReminders(),
    );
  }

  /// فحص التنبيهات المجدولة دورياً داخل التطبيق للمنصات التي لا تدعم الجدولة الخلفية.
  Future<void> _checkInAppFallbackReminders() async {
    final now = DateTime.now();
    final minuteKey =
        '${now.year}-${now.month}-${now.day}-${now.hour}:${now.minute}';
    if (_lastTriggeredMinuteKey == minuteKey) return;

    final reminders = UserDataStore.instance.reminders;
    for (final reminder in reminders) {
      if (!reminder.isEnabled) continue;
      if (reminder.hour != now.hour || reminder.minute != now.minute) continue;

      bool shouldFire = false;
      if (reminder.repeatMode == ReminderRepeatMode.daily ||
          reminder.repeatMode == ReminderRepeatMode.once) {
        shouldFire = true;
      } else if (reminder.repeatMode == ReminderRepeatMode.weekdays) {
        final days = reminder.selectedDays.isEmpty
            ? const [1, 2, 3, 4, 5, 6, 7]
            : reminder.selectedDays;
        shouldFire = days.contains(now.weekday);
      }

      var title = reminder.title.trim().isNotEmpty
          ? reminder.title.trim()
          : 'ورد القرآن الكريم';
      var body = _strings.toReader(_readerName, _strings.reminderQuranBody);
      if (reminder.id == portionReminderId) {
        // Pages left today, or nothing once today's portion is read.
        final store = UserDataStore.instance;
        final journey = store.journey;
        final plan = journey.plan;
        final left = plan == null || plan.isComplete
            ? 0
            : plan.pagesPerDay - journey.portionPagesOn(now);
        shouldFire = shouldFire && left > 0;
        title = _strings.toReader(_readerName, _strings.portionLeftTitle(left));
        body = _strings.portionLeftBody;
      } else if (reminder.id == streakReminderId) {
        // Only while today has no activity and there is a streak to keep.
        final journey = UserDataStore.instance.journey;
        shouldFire = shouldFire && journey.streakAtRisk(now);
        title = _strings.toReader(
          _readerName,
          _strings.streakAtRiskTitle(journey.streak(now)),
        );
        body = _strings.streakAtRiskBody;
      }

      if (shouldFire) {
        _lastTriggeredMinuteKey = minuteKey;
        await showImmediateNotification(
          id: _baseNotificationId(reminder.id),
          title: title,
          body: body,
          alertType: reminder.alertType,
          payload: 'quran_resume',
        );
        if (reminder.repeatMode == ReminderRepeatMode.once) {
          final disabled = reminder.copyWith(isEnabled: false);
          await UserDataStore.instance.putReminder(disabled);
        }
      }
    }
  }

  /// Explicitly requests notification and exact alarm permissions across
  /// Android 13+/14+, iOS, macOS, and Web.
  Future<bool> requestPermissions() async {
    if (_isRunningInFlutterTest) return true;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        try {
          final canExact = await androidImplementation
              .canScheduleExactNotifications();
          if (canExact == false) {
            await androidImplementation.requestExactAlarmsPermission();
          }
        } catch (e) {
          debugPrint('Exact alarm permission check note: $e');
        }
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

  /// بناء إعدادات الإشعار أو المنبه الصوتي حسب نوع التنبيه المختار لكل منصة.
  NotificationDetails _buildNotificationDetails(ReminderAlertType alertType) {
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
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'open_quran',
            'فتح المصحف',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'dismiss_alarm',
            'إيقاف المنبه',
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

    // Standard Notification Mode
    const androidNotificationDetails = AndroidNotificationDetails(
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

    return const NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
      linux: linuxNotificationDetails,
      windows: windowsNotificationDetails,
    );
  }

  /// Displays an immediate notification or alarm.
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

  /// Sends a test notification or alarm immediately after verifying permissions.
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
          (isAlarm ? 'منبه تجريبي — تَدْبِير' : 'إشعار تجريبي — تَدْبِير'),
      body:
          body ??
          (isAlarm
              ? 'هذا تنبيه كالمنبه برنين مستمر — اضغط «إيقاف المنبه» أو «فتح المصحف»'
              : 'نظام الإشعارات يعمل بنجاح في تطبيق تَدْبِير'),
      alertType: alertType,
      payload: 'quran_resume',
    );
  }

  /// توليد معرف رقمي أساسي للإشعارات الفرعية المرتبطة بمعرف التنبيه.
  int _baseNotificationId(String reminderId) {
    return (reminderId.hashCode.abs() % 10000000) * 10;
  }

  /// Cancels all scheduled OS notification slots for a given reminder.
  Future<void> cancelReminder(ReminderItem reminder) async {
    if (_isRunningInFlutterTest) return;
    final baseId = _baseNotificationId(reminder.id);
    for (int i = 0; i <= 7; i++) {
      try {
        await _notificationsPlugin.cancel(id: baseId + i);
      } catch (_) {}
    }
    if (reminder.id == portionReminderId) {
      for (int i = 0; i < portionReminderDays; i++) {
        try {
          await _notificationsPlugin.cancel(id: _portionBaseId + i);
        } catch (_) {}
      }
    }
    if (reminder.id == streakReminderId) {
      for (int i = 0; i < 2; i++) {
        try {
          await _notificationsPlugin.cancel(id: _streakBaseId + i);
        } catch (_) {}
      }
    }
  }

  /// Notification texts in the app's language.
  AppStrings get _strings => AppStrings(
    AppLanguage.fromCode(UserDataStore.instance.settings.languageCode),
  );

  /// The name the reader gave, used to address reminders to them.
  String get _readerName => UserDataStore.instance.settings.userName;

  /// Ids of the khatma portion notices, above every hashed reminder id.
  static const int _portionBaseId = 100000000;

  /// Ids of the streak notices, above the portion notices.
  static const int _streakBaseId = 100000100;

  /// Cancels all scheduled notifications across the app.
  Future<void> cancelAll() async {
    if (_isRunningInFlutterTest) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Synchronizes all saved reminders with the host OS scheduler.
  Future<void> syncAllReminders(List<ReminderItem> reminders) async {
    if (_isRunningInFlutterTest) return;
    for (final reminder in reminders) {
      if (reminder.isEnabled) {
        await scheduleReminder(reminder, requestPermissionIfNeeded: false);
      } else {
        await cancelReminder(reminder);
      }
    }
  }

  /// تحديد نمط الجدولة المناسب على أندرويد (منبه دقيق أو إشعار احتياطي) حسب الصلاحيات الممنوحة.
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
    } catch (_) {}
    return alertType == ReminderAlertType.alarm
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// جدولة إشعار أو منبه مرتبط بالمنطقة الزمنية مع التراجع الآمن عند غياب صلاحية الجدولة الدقيقة.
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

  /// Schedules a reminder based on its repeat mode (once, daily, or specific weekdays)
  /// and its alert type (standard notification vs alarm).
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

    final details = _buildNotificationDetails(reminder.alertType);
    final scheduleMode = await _resolveAndroidScheduleMode(reminder.alertType);

    if (reminder.id == portionReminderId) {
      await _schedulePortion(reminder, details, scheduleMode);
      return;
    }
    if (reminder.id == streakReminderId) {
      await _scheduleStreak(reminder, details, scheduleMode);
      return;
    }

    final title = reminder.title.trim().isNotEmpty
        ? reminder.title.trim()
        : 'ورد القرآن الكريم';
    // Adhkar reminders open the adhkar instead of the Mushaf.
    final isAdhkar = reminder.id.startsWith('adhkar_');
    final strings = _strings;
    final body = strings.toReader(
      _readerName,
      isAdhkar ? strings.reminderAdhkarBody : strings.reminderQuranBody,
    );
    final payload = isAdhkar ? reminder.id : 'quran_resume';

    final baseId = _baseNotificationId(reminder.id);

    try {
      final now = tz.TZDateTime.now(tz.local);

      if (reminder.repeatMode == ReminderRepeatMode.once) {
        // A one-time reminder whose scheduled moment already passed has
        // fired: disable it instead of rescheduling it for tomorrow.
        if (reminder.hasOnceReminderFired()) {
          await _markOnceReminderFired(reminder);
          return;
        }

        tz.TZDateTime scheduledDate;
        final existingTarget = reminder.scheduledFor;
        if (existingTarget != null) {
          // Keep the originally scheduled moment (e.g. on app restart sync).
          scheduledDate = tz.TZDateTime.from(existingTarget, tz.local);
        } else {
          scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            reminder.hour,
            reminder.minute,
          );
          if (!scheduledDate.isAfter(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          // Persist the exact target so later syncs can tell it has fired.
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
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          reminder.hour,
          reminder.minute,
        );
        if (!scheduledDate.isAfter(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

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
          final scheduledDate = _nextInstanceOfDayAndTime(
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

  /// ورد الختمة: إشعار لكل يوم يذكر الصفحات المتبقية من ورده.
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
  }

  /// السلسلة: إشعار الليلة إن لم يكن اليوم نشاط بعد، أو إشعار الغد.
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

  /// تعطيل تنبيه "مرة واحدة" بعد أن رنّ، وإلغاء أي إشعار متبقٍّ له.
  Future<void> _markOnceReminderFired(ReminderItem reminder) async {
    await cancelReminder(reminder);
    final latest = UserDataStore.instance.reminders
        .where((r) => r.id == reminder.id)
        .firstOrNull;
    // Only disable if the stored reminder still targets the same moment
    // (the user may have edited it in the meantime).
    if (latest != null &&
        latest.isEnabled &&
        latest.scheduledFor == reminder.scheduledFor) {
      await UserDataStore.instance.putReminder(
        latest.copyWith(isEnabled: false),
      );
    }
  }

  /// حساب الموعد القادم ليوم محدد من أيام الأسبوع بالساعة والدقيقة المحددة.
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

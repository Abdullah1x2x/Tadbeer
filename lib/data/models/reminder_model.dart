import 'package:flutter/material.dart';

/// أنماط تكرار التذكير المتاحة (مرة واحدة، يومياً، أو أيام محددة من الأسبوع).
enum ReminderRepeatMode {
  /// تنبيه لمرة واحدة فقط.
  once,

  /// تنبيه يتكرر يومياً في نفس الموعد.
  daily,

  /// تنبيه يتكرر في أيام مختارة من الأسبوع.
  weekdays,
}

/// يحدد طريقة تسليم التنبيه (إشعار عادي أو منبه صوتي مستمر).
///
/// Determines whether the reminder is delivered as a standard notification
/// or as a continuous ringing alarm.
enum ReminderAlertType {
  /// إشعار عادي في شريط الإشعارات.
  notification,

  /// تنبيه صوتي مستمر كالمنبه.
  alarm,
}

/// يمثل تذكيراً محلياً لقراءة الورد القرآني يجدوله المستخدم.
///
/// Represents a local Quran reading reminder scheduled by the user.
///
/// Fully offline: uses local device alarms and notification APIs.
class ReminderItem {
  /// المعرّف الفريد للتذكير.
  final String id;

  /// عنوان التذكير الذي يظهر في الإشعار أو المنبه.
  final String title;

  /// الساعة المحددة للتنبيه بنظام 24 ساعة (0..23).
  final int hour;

  /// الدقيقة المحددة للتنبيه (0..59).
  final int minute;

  /// نمط تكرار التذكير.
  final ReminderRepeatMode repeatMode;

  /// نوع التنبيه (إشعار أو منبه).
  final ReminderAlertType alertType;

  /// أيام الأسبوع المحددة للتنبيه (1 = الإثنين .. 7 = الأحد).
  ///
  /// Specific days of the week: 1 = Monday .. 7 = Sunday
  final List<int> selectedDays;

  /// ما إذا كان التذكير مفعلاً حالياً.
  final bool isEnabled;

  /// تاريخ ووقت إنشاء التذكير.
  final DateTime createdAt;

  /// الموعد الفعلي المجدول للتنبيه ذي المرة الواحدة.
  ///
  /// For [ReminderRepeatMode.once] only: the exact moment the OS notification
  /// was scheduled for. Once this moment has passed, the reminder has already
  /// fired and must be disabled instead of being rescheduled for the next day.
  final DateTime? scheduledFor;

  /// ينشئ كائن تذكير جديد.
  const ReminderItem({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.repeatMode,
    this.alertType = ReminderAlertType.notification,
    this.selectedDays = const [],
    this.isEnabled = true,
    required this.createdAt,
    this.scheduledFor,
  });

  /// ما إذا كان تنبيه "مرة واحدة" قد حان موعده وانقضى (أي أنه رنّ بالفعل).
  bool hasOnceReminderFired([DateTime? now]) {
    if (repeatMode != ReminderRepeatMode.once) return false;
    final at = scheduledFor;
    if (at == null) return false;
    return !at.isAfter(now ?? DateTime.now());
  }

  /// وقت التذكير ككائن [TimeOfDay].
  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  /// ينسق الوقت من نظام 24 ساعة إلى نظام 12 ساعة بالأرقام العربية مع رمز (ص/م).
  ///
  /// Formats a 24-hour (0..23) time into 12-hour format (01..12) with ص/م
  /// so midnight (0) displays as ١٢:٠٠ ص instead of ٠٠:٠٠.
  static String formatTime12Hour(int hour, int minute) {
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = hour < 12 ? 'ص' : 'م';
    final String hStr = _toArabicDigits(hour12, minDigits: 2);
    final String mStr = _toArabicDigits(minute, minDigits: 2);
    return '$hStr:$mStr $period';
  }

  /// يحول الرقم الصحيح إلى نص بالأرقام العربية المشرقية مع إكمال الأصفار البادئة.
  static String _toArabicDigits(int number, {int minDigits = 1}) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = number.toString().padLeft(minDigits, '0');
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.write(arabicDigits[code - 48]);
      } else {
        buffer.write(s[i]);
      }
    }
    return buffer.toString();
  }

  /// الوقت المنسق للعرض بنظام 12 ساعة بالأرقام العربية.
  String get formattedTime => formatTime12Hour(hour, minute);

  /// يحول كائن التذكير إلى خريطة بيانات JSON للحفظ المحلي.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'hour': hour,
    'minute': minute,
    'repeatMode': repeatMode.name,
    'alertType': alertType.name,
    'selectedDays': selectedDays,
    'isEnabled': isEnabled,
    'createdAt': createdAt.toIso8601String(),
    if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
  };

  /// ينشئ كائن تذكير من خريطة بيانات JSON المحفوظة.
  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    ReminderRepeatMode mode;
    switch (json['repeatMode'] as String?) {
      case 'daily':
        mode = ReminderRepeatMode.daily;
        break;
      case 'weekdays':
        mode = ReminderRepeatMode.weekdays;
        break;
      default:
        mode = ReminderRepeatMode.once;
    }

    final ReminderAlertType alertType =
        (json['alertType'] as String?) == 'alarm'
        ? ReminderAlertType.alarm
        : ReminderAlertType.notification;

    return ReminderItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'ورد القرآن',
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      repeatMode: mode,
      alertType: alertType,
      selectedDays: (json['selectedDays'] as List?)?.cast<int>() ?? const [],
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledFor: json['scheduledFor'] is String
          ? DateTime.tryParse(json['scheduledFor'] as String)
          : null,
    );
  }

  /// ينشئ نسخة محدثة من التذكير مع تعديل الحقول الممررة.
  ///
  /// Changing the time, repeat mode, days, or re-enabling the reminder
  /// clears [scheduledFor] so the next schedule computes a fresh date —
  /// unless a new [scheduledFor] is passed explicitly.
  ReminderItem copyWith({
    String? title,
    int? hour,
    int? minute,
    ReminderRepeatMode? repeatMode,
    ReminderAlertType? alertType,
    List<int>? selectedDays,
    bool? isEnabled,
    DateTime? scheduledFor,
    bool clearScheduledFor = false,
  }) {
    final schedulingChanged =
        hour != null ||
        minute != null ||
        repeatMode != null ||
        selectedDays != null ||
        isEnabled == true;
    final DateTime? nextScheduledFor =
        scheduledFor ??
        ((clearScheduledFor || schedulingChanged) ? null : this.scheduledFor);
    return ReminderItem(
      id: id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatMode: repeatMode ?? this.repeatMode,
      alertType: alertType ?? this.alertType,
      selectedDays: selectedDays ?? this.selectedDays,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      scheduledFor: nextScheduledFor,
    );
  }
}

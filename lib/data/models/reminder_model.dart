import 'package:flutter/material.dart';

/// تكرار التذكير.
enum ReminderRepeatMode {
  /// مرة واحدة.
  once,

  /// كل يوم في نفس الموعد.
  daily,

  /// في أيام مختارة من الأسبوع.
  weekdays,
}

/// طريقة التنبيه.
enum ReminderAlertType {
  /// إشعار عادي.
  notification,

  /// رنين مستمر كالمنبه.
  alarm,
}

/// تذكير يجدوله القارئ لورده، ويُنبَّه به محلياً على الجهاز.
class ReminderItem {
  final String id;

  /// العنوان الظاهر في الإشعار.
  final String title;

  /// الساعة بنظام 24 ساعة (0..23).
  final int hour;

  /// الدقيقة (0..59).
  final int minute;

  final ReminderRepeatMode repeatMode;

  final ReminderAlertType alertType;

  /// أيام [ReminderRepeatMode.weekdays]: 1 = الإثنين … 7 = الأحد.
  final List<int> selectedDays;

  final bool isEnabled;

  final DateTime createdAt;

  /// لتذكير "مرة واحدة" فقط: اللحظة التي جُدول لها.
  ///
  /// إذا مضت فقد رنّ التذكير، فيُعطَّل بدل أن يُجدول لليوم التالي.
  final DateTime? scheduledFor;

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

  /// هل مضى موعد تذكير "مرة واحدة"، أي أنه رنّ.
  bool hasOnceReminderFired([DateTime? now]) {
    if (repeatMode != ReminderRepeatMode.once) return false;
    final at = scheduledFor;
    if (at == null) return false;
    return !at.isAfter(now ?? DateTime.now());
  }

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  /// الوقت بنظام 12 ساعة بالأرقام العربية مع ص/م؛ منتصف الليل يظهر ١٢:٠٠ ص لا
  /// ٠٠:٠٠.
  static String formatTime12Hour(int hour, int minute) {
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = hour < 12 ? 'ص' : 'م';
    final String hStr = _toArabicDigits(hour12, minDigits: 2);
    final String mStr = _toArabicDigits(minute, minDigits: 2);
    return '$hStr:$mStr $period';
  }

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

  String get formattedTime => formatTime12Hour(hour, minute);

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

  /// نسخة معدّلة. تغيير الوقت أو التكرار أو الأيام أو إعادة التفعيل يمسح
  /// [scheduledFor] ليُحسب موعد جديد، إلا إن مُرّر صراحة.
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

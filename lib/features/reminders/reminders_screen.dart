import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/services/local_reminder_service.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../features/reminders/reminder_model.dart';

/// شاشة إدارة التذكيرات والمنبهات المحلية لقراءة الورد القرآني.
///
/// Reminders management screen for scheduling local Quran recitation alerts.
///
/// Supports two user-selectable alert types:
/// - [ReminderAlertType.notification] (إشعار عادي)
/// - [ReminderAlertType.alarm] (تنبيه كالمنبه)
class RemindersScreen extends StatefulWidget {
  /// ينشئ شاشة إدارة التذكيرات.
  const RemindersScreen({super.key});

  /// ينشئ حالة شاشة التذكيرات.
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

/// الحالة الداخلية لشاشة التذكيرات وإدارة الإضافة والتعديل والجدولة.
class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// يطلب أذونات الإشعارات والمنبهات عند فتح الشاشة.
  @override
  void initState() {
    super.initState();
    LocalReminderService.instance.requestPermissions();
  }

  /// يحرر موارد متحكم حقل البحث عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// يفتح نافذة الحوار لإضافة تذكير جديد أو تعديل تذكير حالي.
  void _openReminderDialog([ReminderItem? existing]) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TimeOfDay selectedTime =
        existing?.time ?? const TimeOfDay(hour: 6, minute: 0);
    ReminderRepeatMode repeatMode =
        existing?.repeatMode ?? ReminderRepeatMode.daily;
    ReminderAlertType alertType =
        existing?.alertType ?? ReminderAlertType.notification;
    List<int> selectedDays = List.from(
      existing?.selectedDays ?? [1, 2, 3, 4, 5, 6, 7],
    );
    final titleController = TextEditingController(
      text: existing?.title ?? l10n.defaultReminderTitle,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.comsilkLight,
            title: Text(
              existing == null ? l10n.addReminder : l10n.editReminder,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Input
                  TextField(
                    controller: titleController,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'Amiri'),
                    decoration: InputDecoration(
                      labelText: l10n.reminderTitle,
                      labelStyle: const TextStyle(fontFamily: 'Amiri'),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.comsilk,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Picker Button
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.border(context)),
                    ),
                    tileColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.comsilk,
                    leading: const Icon(
                      Icons.access_time,
                      color: AppColors.olive,
                    ),
                    title: Text(
                      l10n.reminderTime,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
                    ),
                    trailing: Text(
                      ReminderItem.formatTime12Hour(
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.olive,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Alert Type Selector (إشعار vs تنبيه كالمنبه)
                  Text(
                    l10n.alertType,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _AlertTypeOptionCard(
                          icon: Icons.notifications_none_rounded,
                          title: l10n.notificationAlert,
                          subtitle: l10n.notificationSubtitle,
                          selected: alertType == ReminderAlertType.notification,
                          isDark: isDark,
                          onTap: () => setDialogState(
                            () => alertType = ReminderAlertType.notification,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AlertTypeOptionCard(
                          icon: Icons.alarm_rounded,
                          title: l10n.alarmAlert,
                          subtitle: l10n.alarmSubtitle,
                          selected: alertType == ReminderAlertType.alarm,
                          isDark: isDark,
                          onTap: () => setDialogState(
                            () => alertType = ReminderAlertType.alarm,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Repeat Mode Radio
                  Text(
                    l10n.repeatMode,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                    ),
                  ),
                  RadioGroup<ReminderRepeatMode>(
                    groupValue: repeatMode,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => repeatMode = val);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ReminderRepeatMode>(
                          value: ReminderRepeatMode.daily,
                          activeColor: AppColors.olive,
                          title: Text(
                            l10n.repeatDaily,
                            style: const TextStyle(fontFamily: 'Amiri'),
                          ),
                        ),
                        RadioListTile<ReminderRepeatMode>(
                          value: ReminderRepeatMode.once,
                          activeColor: AppColors.olive,
                          title: Text(
                            l10n.repeatOnce,
                            style: const TextStyle(fontFamily: 'Amiri'),
                          ),
                        ),
                        RadioListTile<ReminderRepeatMode>(
                          value: ReminderRepeatMode.weekdays,
                          activeColor: AppColors.olive,
                          title: Text(
                            l10n.selectDays,
                            style: const TextStyle(fontFamily: 'Amiri'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Days Selector if weekdays
                  if (repeatMode == ReminderRepeatMode.weekdays) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _DayChip(
                          day: 6,
                          label: l10n.daySat,
                          selected: selectedDays.contains(6),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 6),
                        ),
                        _DayChip(
                          day: 7,
                          label: l10n.daySun,
                          selected: selectedDays.contains(7),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 7),
                        ),
                        _DayChip(
                          day: 1,
                          label: l10n.dayMon,
                          selected: selectedDays.contains(1),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 1),
                        ),
                        _DayChip(
                          day: 2,
                          label: l10n.dayTue,
                          selected: selectedDays.contains(2),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 2),
                        ),
                        _DayChip(
                          day: 3,
                          label: l10n.dayWed,
                          selected: selectedDays.contains(3),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 3),
                        ),
                        _DayChip(
                          day: 4,
                          label: l10n.dayThu,
                          selected: selectedDays.contains(4),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 4),
                        ),
                        _DayChip(
                          day: 5,
                          label: l10n.dayFri,
                          selected: selectedDays.contains(5),
                          onToggle: () =>
                              _toggleDay(setDialogState, selectedDays, 5),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(fontFamily: 'Amiri'),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final reminder = ReminderItem(
                    id: existing?.id ?? const Uuid().v4(),
                    title: titleController.text.trim().isNotEmpty
                        ? titleController.text.trim()
                        : l10n.defaultReminderTitle,
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    repeatMode: repeatMode,
                    alertType: alertType,
                    selectedDays: selectedDays,
                    isEnabled: existing?.isEnabled ?? true,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  );

                  await UserDataStore.instance.putReminder(reminder);
                  await LocalReminderService.instance.scheduleReminder(
                    reminder,
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    final modeLabel = alertType == ReminderAlertType.alarm
                        ? l10n.alarmAlert
                        : l10n.notificationAlert;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.reminderScheduledSuccess(modeLabel),
                          style: const TextStyle(fontFamily: 'Amiri'),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// يبدل حالة اختيار يوم من أيام الأسبوع مع ضمان بقاء يوم واحد على الأقل محدداً.
  void _toggleDay(StateSetter setDialogState, List<int> days, int day) {
    setDialogState(() {
      if (days.contains(day)) {
        if (days.length > 1) days.remove(day);
      } else {
        days.add(day);
      }
    });
  }

  /// يرسل تنبيهاً أو منبهاً تجريبياً فورياً للتحقق من عمل الإشعارات على الجهاز.
  Future<void> _sendTestAlert(ReminderAlertType alertType) async {
    final sent = await LocalReminderService.instance.showTestNotification(
      alertType: alertType,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    final isAlarm = alertType == ReminderAlertType.alarm;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? (isAlarm
                    ? l10n.testAlarmSentSuccess
                    : l10n.testNotificationSentSuccess)
              : l10n.testAlertPermissionError,
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// يبني واجهة شاشة التذكيرات مع حقل البحث وقائمة التنبيهات المجدولة.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.reminders,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<ReminderAlertType>(
              tooltip: l10n.testAlertTooltip,
              icon: const Icon(Icons.notifications_active_outlined),
              onSelected: _sendTestAlert,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: ReminderAlertType.notification,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.testNotificationNow,
                          style: const TextStyle(fontFamily: 'Amiri'),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ReminderAlertType.alarm,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm_rounded, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.testAlarmNow,
                          style: const TextStyle(fontFamily: 'Amiri'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openReminderDialog(),
          backgroundColor: AppColors.olive,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.alarm_add),
          label: Text(
            l10n.addReminder,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final allReminders = UserDataStore.instance.reminders;

            if (allReminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm,
                      size: 64,
                      color: AppColors.border(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noRemindersYet,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                    ),
                  ],
                ),
              );
            }

            final normalizedQuery = ArabicSearchNormalizer.normalize(
              _searchQuery,
            );
            final reminders = allReminders.where((r) {
              if (normalizedQuery.isEmpty) return true;
              return ArabicSearchNormalizer.normalize(r.title).contains(
                normalizedQuery,
              );
            }).toList();

            return Column(
              children: [
                // Search Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: l10n.searchRemindersHint,
                      hintStyle: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.olive,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.comsilk,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Reminders List / Empty Query Results
                Expanded(
                  child: reminders.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noSearchResults,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reminders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            return _ReminderCard(
                              reminder: reminder,
                              onEdit: () => _openReminderDialog(reminder),
                              onToggle: (bool val) async {
                                final updated = reminder.copyWith(
                                  isEnabled: val,
                                );
                                await UserDataStore.instance.putReminder(
                                  updated,
                                );
                                await LocalReminderService.instance
                                    .scheduleReminder(updated);
                              },
                              onDelete: () async {
                                await LocalReminderService.instance
                                    .cancelReminder(reminder);
                                await UserDataStore.instance.removeReminder(
                                  reminder.id,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة خيار لتحديد طريقة التنبيه (إشعار عادي أو منبه صوتي).
class _AlertTypeOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  /// ينشئ بطاقة خيار نوع التنبيه.
  const _AlertTypeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  /// يبني واجهة بطاقة خيار نوع التنبيه.
  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.olive : AppColors.border(context);
    final bgColor = selected
        ? AppColors.olive.withValues(alpha: isDark ? 0.25 : 0.14)
        : (isDark ? AppColors.darkSurface : AppColors.comsilk);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: selected ? 1.8 : 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.olive
                  : (isDark ? AppColors.nightSubtitle : AppColors.daySubtitle),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selected
                    ? (isDark ? AppColors.comsilk : AppColors.oliveDark)
                    : (isDark
                          ? AppColors.nightQuranText
                          : AppColors.dayQuranText),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 11,
                color: isDark ? AppColors.nightSubtitle : AppColors.daySubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريحة اختيار ليوم واحد من أيام الأسبوع عند ضبط التكرار المخصص.
class _DayChip extends StatelessWidget {
  final int day;
  final String label;
  final bool selected;
  final VoidCallback onToggle;

  /// ينشئ شريحة اختيار يوم الأسبوع.
  const _DayChip({
    required this.day,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  /// يبني واجهة شريحة اليوم القابلة للتحديد.
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'Amiri', fontSize: 12),
      ),
      selected: selected,
      selectedColor: AppColors.olive.withValues(alpha: 0.25),
      checkmarkColor: AppColors.oliveDark,
      onSelected: (_) => onToggle(),
    );
  }
}

/// بطاقة عرض لتذكير واحد تتضمن الوقت ونوع التنبيه ومفتاح التفعيل.
class _ReminderCard extends StatelessWidget {
  final ReminderItem reminder;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  /// ينشئ بطاقة عرض التذكير.
  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  /// يبني واجهة بطاقة التذكير وأزرار التحكم به.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String repeatSubtitle;
    switch (reminder.repeatMode) {
      case ReminderRepeatMode.daily:
        repeatSubtitle = l10n.repeatDaily;
        break;
      case ReminderRepeatMode.weekdays:
        repeatSubtitle = l10n.specificDays;
        break;
      case ReminderRepeatMode.once:
        repeatSubtitle = l10n.repeatOnce;
        break;
    }

    final isAlarm = reminder.alertType == ReminderAlertType.alarm;
    final alertTypeLabel = isAlarm ? l10n.alarmAlert : l10n.notificationAlert;
    final alertTypeIcon = isAlarm
        ? Icons.alarm_on_rounded
        : Icons.notifications_none_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.comsilk,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          // Time & Alert Type display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.formattedTime,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: reminder.isEnabled
                      ? (isDark ? AppColors.comsilk : AppColors.oliveDark)
                      : Colors.grey,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(alertTypeIcon, size: 13, color: AppColors.olive),
                  const SizedBox(width: 4),
                  Text(
                    '$alertTypeLabel • $repeatSubtitle',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.nightQuranText
                        : AppColors.dayQuranText,
                  ),
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: reminder.isEnabled,
            activeThumbColor: AppColors.olive,
            onChanged: onToggle,
          ),

          // Secondary Actions (⋮)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

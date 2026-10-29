import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'data/curated_dhikrs.dart';

export 'data/curated_dhikrs.dart';

/// أقسام أذكار السبحة والمحراب (استغفار وتسبيح).
enum DhikrSection {
  /// قسم الاستغفار والتوبة.
  istighfar,

  /// قسم التسبيح والتحميد والذكر.
  tasbeeh,
}

/// امتداد مساعد لقسم الذكر يوفر المسميات العربية البسيطة والمباشرة.
extension DhikrSectionX on DhikrSection {
  /// عنوان القسم.
  String get title {
    switch (this) {
      case DhikrSection.istighfar:
        return 'الاستغفار';
      case DhikrSection.tasbeeh:
        return 'التسبيح';
    }
  }

  /// العنوان القصير للعرض في الأزرار والتبويبات.
  String get shortTitle => title;
}

/// نموذج بيانات الأذكار والاستغفار والتسبيح للسبحة الإلكترونية.
class TasbeehDhikr {
  final String id;
  final String arabicText;
  final String englishTranslation;
  final String virtue;
  final String category;
  final int defaultTarget;
  final DhikrSection section;

  /// مدة الإيقاع الزمني المخصصة للعد التلقائي بالثواني (اختيارية للمطور).
  /// إذا تُركت فارغة أو null، تُحسب تلقائياً بذكاء بحسب طول الذكر وعدد كلماته.
  final double? paceSeconds;

  /// ينشئ ذكراً أو صيغة استغفار وتسبيح.
  const TasbeehDhikr({
    required this.id,
    required this.arabicText,
    required this.englishTranslation,
    required this.virtue,
    required this.category,
    this.defaultTarget = 33,
    this.section = DhikrSection.tasbeeh,
    this.paceSeconds,
  });

  /// مدة الإيقاع بالثواني لكل عَدّة (تُحسب تلقائياً من طول الذكر ما لم تُحدد يدوياً).
  double get estimatedPaceSeconds {
    if (paceSeconds != null && paceSeconds! > 0) {
      return paceSeconds!;
    }
    // حساب عدد الكلمات العربية بدقة
    final words = arabicText.trim().split(RegExp(r'\s+')).length;
    // معادلة إيقاع التدبر الهادئ: 800 ملي ثانية وقفة تأمل + 320 ملي ثانية لكل كلمة
    final totalMillis = 800 + (words * 320);
    final clampedSeconds = (totalMillis / 1000.0).clamp(1.2, 7.0);
    return double.parse(clampedSeconds.toStringAsFixed(1));
  }

  /// مدة الإيقاع الزمني المحسوبة ككائن [Duration] مناسب للمؤقتات التلقائية.
  Duration get estimatedPaceDuration =>
      Duration(milliseconds: (estimatedPaceSeconds * 1000).round());

  /// ما إذا كان الذكر يتبع لقسم الاستغفار.
  bool get isIstighfar => section == DhikrSection.istighfar;

  /// ما إذا كان الذكر يتبع لقسم التسبيح.
  bool get isTasbeeh => section == DhikrSection.tasbeeh;

  /// التصنيفات المعتمدة: استغفار وتسبيح فقط دون أي تعقيد.
  static const List<String> categories = ['الكل', 'استغفار', 'تسبيح'];

  /// قائمة صيغ الاستغفار فقط.
  static List<TasbeehDhikr> get istighfarDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.istighfar).toList();

  /// قائمة صيغ التسبيح فقط.
  static List<TasbeehDhikr> get tasbeehDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.tasbeeh).toList();

  /// باقة الأذكار والصيغ المعتمدة (49 صيغة موثقة: 20 استغفار و 29 تسبيح).
  /// يمكن للمطور إضافة أو تعديل الأذكار في ملف: [curatedDhikrs]
  static const List<TasbeehDhikr> defaultDhikrs = curatedDhikrs;
}

/// مستودع إدارة حالة السبحة الإلكترونية والورد اليومي من الاستغفار والتسبيح.
class TasbeehRepository extends ChangeNotifier {
  static final TasbeehRepository instance = TasbeehRepository._internal();
  TasbeehRepository._internal();

  /// Called when a round reaches its target; the app uses it to count the
  /// day toward the reading streak.
  VoidCallback? onTargetReached;

  bool _initialized = false;
  TasbeehDhikr _activeDhikr = TasbeehDhikr.defaultDhikrs.first;
  int _currentCount = 0;
  int _targetCount = 100;
  int _lifetimeTotalCount = 0;
  int _todayTotalCount = 0;
  String _lastDateIso = '';
  bool _autoAdvanceEnabled = true;

  /// الذكر الفعال حالياً في السبحة.
  TasbeehDhikr get activeDhikr => _activeDhikr;

  /// القسم الفعال حالياً في السبحة (استغفار أو تسبيح).
  DhikrSection get activeSection => _activeDhikr.section;

  /// العدد الحالي في الدورة الراهنة.
  int get currentCount => _currentCount;

  /// الهدف المحدد للدورة الحالية (0 تعني عدّاً حراً غير محدود).
  int get targetCount => _targetCount;

  /// ما إذا كان التبديل التلقائي إلى الصيغة التالية مفعلاً عند بلوغ الهدف.
  bool get autoAdvanceEnabled => _autoAdvanceEnabled;

  /// المجموع التراكمي الكلي لمرات الاستغفار والتسبيح منذ تثبيت التطبيق.
  int get lifetimeTotalCount => _lifetimeTotalCount;

  /// المجموع المحقق لليوم الحالي.
  int get todayTotalCount => _todayTotalCount;

  /// ما إذا كان المستودع قد أتم تحميل البيانات المحفوظة.
  bool get isInitialized => _initialized;

  /// تهيئة المستودع وقراءة الإحصائيات المحفوظة محلياً.
  Future<void> init() async {
    if (_initialized) return;
    final today = _getTodayDateIso();
    _lastDateIso = today;

    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;

        _lifetimeTotalCount =
            (jsonMap['lifetimeTotalCount'] as num?)?.toInt() ?? 0;
        final savedDate = jsonMap['lastDateIso'] as String? ?? '';
        if (savedDate == today) {
          _todayTotalCount = (jsonMap['todayTotalCount'] as num?)?.toInt() ?? 0;
        } else {
          _todayTotalCount = 0;
        }

        final savedDhikrId = jsonMap['activeDhikrId'] as String?;
        if (savedDhikrId != null) {
          _activeDhikr = TasbeehDhikr.defaultDhikrs.firstWhere(
            (d) => d.id == savedDhikrId,
            orElse: () => TasbeehDhikr.defaultDhikrs.first,
          );
        }

        _targetCount =
            (jsonMap['targetCount'] as num?)?.toInt() ??
            _activeDhikr.defaultTarget;
        _currentCount = (jsonMap['currentCount'] as num?)?.toInt() ?? 0;
        _autoAdvanceEnabled = jsonMap['autoAdvanceEnabled'] as bool? ?? true;
      } else {
        _targetCount = _activeDhikr.defaultTarget;
      }
    } catch (e) {
      // السقوط الآمن إلى الحالة الافتراضية في بيئات الاختبار أو عند تعذر الوصول للملف
      _targetCount = _activeDhikr.defaultTarget;
    }

    _initialized = true;
    notifyListeners();
  }

  /// زيادة العداد بمقدار نقرة واحدة.
  ///
  /// تعيد `true` إذا تم بلوغ الهدف المحدد للدورة الحالية.
  bool increment() {
    _checkDateRollover();
    _currentCount++;
    _lifetimeTotalCount++;
    _todayTotalCount++;

    final targetReached = _targetCount > 0 && _currentCount == _targetCount;
    // A completed round counts the day toward the reading streak.
    if (targetReached) onTargetReached?.call();
    _persistDebounced();
    notifyListeners();
    return targetReached;
  }

  /// تصفير عداد الدورة الحالية مع الحفاظ على المجموع التراكمي.
  void resetCurrentCount() {
    _currentCount = 0;
    _persistDebounced();
    notifyListeners();
  }

  /// ضبط الهدف المطلوب للدورة (33 أو 100 أو 0 للعد الحر).
  void setTarget(int target) {
    if (_targetCount == target) return;
    _targetCount = target;
    _persistDebounced();
    notifyListeners();
  }

  /// تفعيل أو تعطيل التبديل التلقائي إلى الذكر التالي عند إتمام الورد المستهدف.
  void toggleAutoAdvance() {
    _autoAdvanceEnabled = !_autoAdvanceEnabled;
    _persistDebounced();
    notifyListeners();
  }

  /// ضبط التبديل التلقائي بقيمة محددة.
  void setAutoAdvance(bool enabled) {
    if (_autoAdvanceEnabled == enabled) return;
    _autoAdvanceEnabled = enabled;
    _persistDebounced();
    notifyListeners();
  }

  /// تغيير الذكر الفعال حالياً والبدء بدورة جديدة.
  void setActiveDhikr(TasbeehDhikr dhikr) {
    _activeDhikr = dhikr;
    _currentCount = 0;
    _targetCount = dhikr.defaultTarget;
    _persistDebounced();
    notifyListeners();
  }

  /// التبديل إلى قسم محدد (استغفار أو تسبيح) واختيار أول ذكر فيه إذا لم يكن الذكر الحالي من نفس القسم.
  void setActiveSection(DhikrSection section) {
    if (_activeDhikr.section == section) return;
    final targetDhikrs = section == DhikrSection.istighfar
        ? TasbeehDhikr.istighfarDhikrs
        : TasbeehDhikr.tasbeehDhikrs;
    if (targetDhikrs.isNotEmpty) {
      setActiveDhikr(targetDhikrs.first);
    }
  }

  /// الانتقال إلى الذكر التالي ضمن قائمة محددة (أو القائمة الافتراضية).
  void nextDhikr({List<TasbeehDhikr>? pool}) {
    final list = (pool != null && pool.isNotEmpty)
        ? pool
        : TasbeehDhikr.defaultDhikrs;
    final currentIndex = list.indexWhere((d) => d.id == _activeDhikr.id);
    final nextIndex = currentIndex == -1 ? 0 : (currentIndex + 1) % list.length;
    setActiveDhikr(list[nextIndex]);
  }

  /// الانتقال إلى الذكر السابق ضمن قائمة محددة (أو القائمة الافتراضية).
  void previousDhikr({List<TasbeehDhikr>? pool}) {
    final list = (pool != null && pool.isNotEmpty)
        ? pool
        : TasbeehDhikr.defaultDhikrs;
    final currentIndex = list.indexWhere((d) => d.id == _activeDhikr.id);
    final prevIndex = currentIndex == -1
        ? 0
        : (currentIndex - 1 + list.length) % list.length;
    setActiveDhikr(list[prevIndex]);
  }

  /// التحقق من تبدل اليوم لتصفير عداد اليوم.
  void _checkDateRollover() {
    final today = _getTodayDateIso();
    if (_lastDateIso != today) {
      _lastDateIso = today;
      _todayTotalCount = 0;
    }
  }

  String _getTodayDateIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<File?> _getStorageFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/tadbeer_tasbeeh_state.json');
    } catch (_) {
      return null;
    }
  }

  void _persistDebounced() {
    _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getStorageFile();
      if (file == null) return;
      final payload = jsonEncode({
        'lifetimeTotalCount': _lifetimeTotalCount,
        'todayTotalCount': _todayTotalCount,
        'lastDateIso': _lastDateIso,
        'activeDhikrId': _activeDhikr.id,
        'currentCount': _currentCount,
        'targetCount': _targetCount,
        'autoAdvanceEnabled': _autoAdvanceEnabled,
      });
      await file.writeAsString(payload, flush: true);
    } catch (_) {
      // التجاهل الآمن في بيئات الاختبار
    }
  }
}

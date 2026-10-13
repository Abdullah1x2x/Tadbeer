import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'tasbeeh_model.dart';

/// مستودع إدارة حالة السبحة الإلكترونية والورد اليومي من الاستغفار والتسبيح.
class TasbeehRepository extends ChangeNotifier {
  static final TasbeehRepository instance = TasbeehRepository._internal();
  TasbeehRepository._internal();

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

        _lifetimeTotalCount = (jsonMap['lifetimeTotalCount'] as num?)?.toInt() ?? 0;
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

        _targetCount = (jsonMap['targetCount'] as num?)?.toInt() ?? _activeDhikr.defaultTarget;
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

  /// الانتقال إلى الذكر التالي ضمن قائمة محددة (أو القائمة الافتراضية).
  void nextDhikr({List<TasbeehDhikr>? pool}) {
    final list = (pool != null && pool.isNotEmpty)
        ? pool
        : TasbeehDhikr.defaultDhikrs;
    final currentIndex = list.indexWhere((d) => d.id == _activeDhikr.id);
    final nextIndex =
        currentIndex == -1 ? 0 : (currentIndex + 1) % list.length;
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

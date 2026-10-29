import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'data/curated_dhikrs.dart';

export 'data/curated_dhikrs.dart';

/// قسما السبحة.
enum DhikrSection {
  istighfar,

  /// التسبيح والتحميد والتكبير.
  tasbeeh,
}

/// عناوين الأقسام.
extension DhikrSectionX on DhikrSection {
  String get title {
    switch (this) {
      case DhikrSection.istighfar:
        return 'الاستغفار';
      case DhikrSection.tasbeeh:
        return 'التسبيح';
    }
  }

  /// العنوان القصير للأزرار والتبويبات.
  String get shortTitle => title;
}

/// ذكر في السبحة: نصه وفضله وهدفه الافتراضي وقسمه.
class TasbeehDhikr {
  final String id;
  final String arabicText;
  final String englishTranslation;
  final String virtue;
  final String category;
  final int defaultTarget;
  final DhikrSection section;

  /// مدة كل عَدّة في العد التلقائي، بالثواني؛ إن تُركت null تُحسب من طول الذكر.
  final double? paceSeconds;

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

  /// مدة كل عَدّة بالثواني: [paceSeconds] إن حُدّدت، وإلا تُحسب من طول الذكر.
  double get estimatedPaceSeconds {
    if (paceSeconds != null && paceSeconds! > 0) {
      return paceSeconds!;
    }
    final words = arabicText.trim().split(RegExp(r'\s+')).length;
    // وقفة تأمل 800 مللي ثانية، و320 لكل كلمة.
    final totalMillis = 800 + (words * 320);
    final clampedSeconds = (totalMillis / 1000.0).clamp(1.2, 7.0);
    return double.parse(clampedSeconds.toStringAsFixed(1));
  }

  /// [estimatedPaceSeconds] كـ[Duration] للمؤقتات.
  Duration get estimatedPaceDuration =>
      Duration(milliseconds: (estimatedPaceSeconds * 1000).round());

  bool get isIstighfar => section == DhikrSection.istighfar;

  bool get isTasbeeh => section == DhikrSection.tasbeeh;

  /// تصنيفات التصفية.
  static const List<String> categories = ['الكل', 'استغفار', 'تسبيح'];

  static List<TasbeehDhikr> get istighfarDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.istighfar).toList();

  static List<TasbeehDhikr> get tasbeehDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.tasbeeh).toList();

  /// الأذكار المعتمدة: 49 صيغة (20 استغفار و29 تسبيح)، وتُضاف في [curatedDhikrs].
  static const List<TasbeehDhikr> defaultDhikrs = curatedDhikrs;
}

/// حالة السبحة وورد اليوم، محفوظة على الجهاز.
class TasbeehRepository extends ChangeNotifier {
  static final TasbeehRepository instance = TasbeehRepository._internal();
  TasbeehRepository._internal();

  /// يُستدعى عند بلوغ هدف الدورة؛ يستخدمه التطبيق لاحتساب اليوم في سلسلة القراءة.
  VoidCallback? onTargetReached;

  bool _initialized = false;
  TasbeehDhikr _activeDhikr = TasbeehDhikr.defaultDhikrs.first;
  int _currentCount = 0;
  int _targetCount = 100;
  int _lifetimeTotalCount = 0;
  int _todayTotalCount = 0;
  String _lastDateIso = '';
  bool _autoAdvanceEnabled = true;

  /// الذكر الجاري.
  TasbeehDhikr get activeDhikr => _activeDhikr;

  DhikrSection get activeSection => _activeDhikr.section;

  /// العدد في الدورة الحالية.
  int get currentCount => _currentCount;

  /// هدف الدورة (0 = عدّ حر بلا حد).
  int get targetCount => _targetCount;

  /// هل ينتقل إلى الذكر التالي تلقائياً عند بلوغ الهدف.
  bool get autoAdvanceEnabled => _autoAdvanceEnabled;

  /// مجموع العدّ منذ تثبيت التطبيق.
  int get lifetimeTotalCount => _lifetimeTotalCount;

  /// مجموع اليوم.
  int get todayTotalCount => _todayTotalCount;

  bool get isInitialized => _initialized;

  /// يقرأ الحالة والإحصاءات المحفوظة.
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
      // عند تعذّر القراءة (كالاختبارات) تبدأ من الحالة الافتراضية.
      _targetCount = _activeDhikr.defaultTarget;
    }

    _initialized = true;
    notifyListeners();
  }

  /// يزيد العدّ بواحد، ويعيد true إن بلغ هدف الدورة.
  bool increment() {
    _checkDateRollover();
    _currentCount++;
    _lifetimeTotalCount++;
    _todayTotalCount++;

    final targetReached = _targetCount > 0 && _currentCount == _targetCount;
    // إتمام الدورة يحتسب اليوم في سلسلة القراءة.
    if (targetReached) onTargetReached?.call();
    _persistDebounced();
    notifyListeners();
    return targetReached;
  }

  /// يصفّر الدورة الحالية، ويبقى المجموع.
  void resetCurrentCount() {
    _currentCount = 0;
    _persistDebounced();
    notifyListeners();
  }

  /// هدف الدورة: 33 أو 100 أو 0 للعدّ الحر.
  void setTarget(int target) {
    if (_targetCount == target) return;
    _targetCount = target;
    _persistDebounced();
    notifyListeners();
  }

  /// يشغّل الانتقال التلقائي للذكر التالي أو يطفئه.
  void toggleAutoAdvance() {
    _autoAdvanceEnabled = !_autoAdvanceEnabled;
    _persistDebounced();
    notifyListeners();
  }

  void setAutoAdvance(bool enabled) {
    if (_autoAdvanceEnabled == enabled) return;
    _autoAdvanceEnabled = enabled;
    _persistDebounced();
    notifyListeners();
  }

  /// يغيّر الذكر الجاري ويبدأ دورة جديدة.
  void setActiveDhikr(TasbeehDhikr dhikr) {
    _activeDhikr = dhikr;
    _currentCount = 0;
    _targetCount = dhikr.defaultTarget;
    _persistDebounced();
    notifyListeners();
  }

  /// ينتقل إلى [section]، ويختار أول ذكر فيه إن لم يكن الجاري منه.
  void setActiveSection(DhikrSection section) {
    if (_activeDhikr.section == section) return;
    final targetDhikrs = section == DhikrSection.istighfar
        ? TasbeehDhikr.istighfarDhikrs
        : TasbeehDhikr.tasbeehDhikrs;
    if (targetDhikrs.isNotEmpty) {
      setActiveDhikr(targetDhikrs.first);
    }
  }

  /// الذكر التالي في [pool] أو في كل الأذكار.
  void nextDhikr({List<TasbeehDhikr>? pool}) {
    final list = (pool != null && pool.isNotEmpty)
        ? pool
        : TasbeehDhikr.defaultDhikrs;
    final currentIndex = list.indexWhere((d) => d.id == _activeDhikr.id);
    final nextIndex = currentIndex == -1 ? 0 : (currentIndex + 1) % list.length;
    setActiveDhikr(list[nextIndex]);
  }

  /// الذكر السابق في [pool] أو في كل الأذكار.
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

  /// يصفّر عدّ اليوم إن تبدّل التاريخ.
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
      // يُتجاهل الفشل في بيئات الاختبار.
    }
  }
}

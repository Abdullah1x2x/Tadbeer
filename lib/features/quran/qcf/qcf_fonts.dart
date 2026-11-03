/// خطوط صفحات مصحف المدينة المضمّنة في التطبيق.
///
/// لكل صفحة من الـ٦٠٤ خط QCF خاص بها مضمّن في التطبيق. لا يُسجّل خط الصفحة إلا
/// حين يصلها القارئ، فيبقى الإقلاع سريعاً ولا تحمل الذاكرة إلا الصفحات
/// المفتوحة.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class QcfFonts {
  QcfFonts._();

  static final QcfFonts instance = QcfFonts._();

  static const pageCount = 604;

  final Map<int, Future<bool>> _loading = {};
  final Set<int> _ready = {};

  /// اسم الخط المسجّل لصفحة [page].
  static String familyFor(int page) => 'QCF_P$page';

  static String assetFor(int page) => 'assets/fonts/qcf/p$page.ttf';

  /// يحمّل خط [page]؛ true متى أمكن الرسم به.
  Future<bool> ensurePage(int page) {
    if (page < 1 || page > pageCount) return Future.value(false);
    return _loading[page] ??= _load(page);
  }

  /// هل اكتمل تحميل خط [page].
  bool isPageLoaded(int page) => _ready.contains(page);

  /// يحمّل خطوط الصفحات المجاورة استباقياً.
  ///
  /// تحميل أي خط يعيد تخطيط كل نصوص التطبيق، فلا يُستدعى أثناء حركة الصفحة.
  void preloadSurrounding(int page, {int window = 2}) {
    for (var i = 1; i <= window; i++) {
      if (page + i <= pageCount) ensurePage(page + i);
      if (page - i >= 1) ensurePage(page - i);
    }
  }

  /// يحمّل خطوط المصحف كلها، الأقرب إلى [around] أولاً، دفعة كل إطار.
  ///
  /// كل خط يعيد تخطيط نصوص التطبيق، والخطوط المحمّلة في إطار واحد تشترك في
  /// إعادة واحدة؛ وبعد اكتمالها لا يُحمّل خط أثناء التقليب.
  Future<void> preloadAll({int around = 1}) async {
    final pages = preloadOrder(around);
    for (var i = 0; i < pages.length; i += _batch) {
      await Future.wait(pages.skip(i).take(_batch).map(ensurePage));
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  static const _batch = 32;

  /// صفحات المصحف كلها، من [around] متباعدةً عنها في الاتجاهين.
  @visibleForTesting
  static List<int> preloadOrder(int around) => {
    for (var d = 0; d < pageCount; d++) ...[around + d, around - d],
  }.where((p) => p >= 1 && p <= pageCount).toList();

  Future<bool> _load(int page) async {
    try {
      final loader = FontLoader(familyFor(page))
        ..addFont(rootBundle.load(assetFor(page)));
      await loader.load();
      _ready.add(page);
      return true;
    } catch (e) {
      unawaited(_loading.remove(page));
      debugPrint('QCF font for page $page failed to load: $e');
      return false;
    }
  }
}

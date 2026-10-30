/// خطوط صفحات مصحف المدينة المضمّنة في التطبيق.
///
/// لكل صفحة من الـ٦٠٤ خط QCF خاص بها مضمّن في التطبيق. لا يُسجّل خط الصفحة إلا
/// حين يصلها القارئ، فيبقى الإقلاع سريعاً ولا تحمل الذاكرة إلا الصفحات
/// المفتوحة.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
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

/// خطوط صفحات مصحف المدينة المضمّنة في التطبيق.
///
/// Each of the 604 pages has its own QCF font, bundled as an asset. A page's
/// font is registered only when the reader reaches it, so start-up stays
/// fast and memory holds just the pages that were opened.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class QcfFonts {
  QcfFonts._();

  static final QcfFonts instance = QcfFonts._();

  static const pageCount = 604;

  final Map<int, Future<bool>> _loading = {};
  final Set<int> _ready = {};

  /// The font family name registered for [page].
  static String familyFor(int page) => 'QCF_P$page';

  static String assetFor(int page) => 'assets/fonts/qcf/p$page.ttf';

  /// Loads the font of [page]; true when it can be drawn.
  Future<bool> ensurePage(int page) {
    if (page < 1 || page > pageCount) return Future.value(false);
    return _loading[page] ??= _load(page);
  }

  /// Whether [page]'s font has finished loading.
  bool isPageLoaded(int page) => _ready.contains(page);

  Future<bool> _load(int page) async {
    try {
      final loader = FontLoader(familyFor(page))
        ..addFont(rootBundle.load(assetFor(page)));
      await loader.load();
      _ready.add(page);
      return true;
    } catch (e) {
      _loading.remove(page);
      debugPrint('QCF font for page $page failed to load: $e');
      return false;
    }
  }
}

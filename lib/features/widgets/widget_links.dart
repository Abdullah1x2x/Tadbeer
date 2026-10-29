/// فتح ما يطلبه المستخدم من ودجت الشاشة الرئيسية.
///
/// The widget's buttons open the app with a `tadbeer://` link:
/// `ayah?s=&a=` shows the ayah in the Mushaf, `reflect?s=&a=` opens its
/// reflection, `khatma` opens the Mushaf at the khatma page and `home` the
/// home screen.
library;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/main_shell.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';

class WidgetLinks {
  WidgetLinks._();

  static Uri? _lastUri;
  static DateTime? _lastAt;

  /// Handles the link the app was launched with and any tapped later. Call
  /// after the first frame, once the navigator exists.
  static void attach() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(open).catchError((_) {});
    HomeWidget.widgetClicked.listen(open, onError: (_) {});
  }

  static void open(Uri? uri) {
    if (uri == null || uri.scheme != 'tadbeer') return;
    // A cold start can report the same tap twice.
    final now = DateTime.now();
    if (uri == _lastUri &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastUri = uri;
    _lastAt = now;

    final surah = int.tryParse(uri.queryParameters['s'] ?? '');
    final ayahNumber = int.tryParse(uri.queryParameters['a'] ?? '');
    final ayah = surah == null || ayahNumber == null
        ? null
        : QuranRepository.instance.getAyah(surah, ayahNumber);

    switch (uri.host) {
      case 'khatma':
        MainShell.showFromOutside(ShellTab.quran);
      case 'ayah' when ayah != null:
        // Shown on its own so viewing it leaves the reading position as is.
        MainShell.showFromOutside(ShellTab.home)?.push(
          MaterialPageRoute(
            builder: (_) => QuranScreen(
              initialPage: ayah.page,
              targetSurahNumber: ayah.surahNumber,
              targetAyahNumber: ayah.ayahNumber,
            ),
          ),
        );
      case 'reflect' when ayah != null:
        final navigator = MainShell.showFromOutside(ShellTab.home);
        if (navigator == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigator.mounted) {
            TadbeerPauseSheet.show(navigator.context, ayah);
          }
        });
      default:
        MainShell.showFromOutside(ShellTab.home);
    }
  }
}

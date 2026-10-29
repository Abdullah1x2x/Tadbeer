/// يفتح ما يطلبه القارئ من أزرار الودجت.
/// كل زر يفتح التطبيق برابط `tadbeer://`: `ayah?s=&a=` يعرض الآية في المصحف، و`reflect?s=&a=` يفتح التدبر عليها، و`khatma` يفتح المصحف على صفحة الختمة، و`home` الشاشة الرئيسية.
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

  /// يعالج الرابط الذي فُتح به التطبيق وأي رابط لاحق؛ يُستدعى بعد أول إطار حين يوجد الـ navigator.
  static void attach() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(open).catchError((_) {});
    HomeWidget.widgetClicked.listen(open, onError: (_) {});
  }

  static void open(Uri? uri) {
    if (uri == null || uri.scheme != 'tadbeer') return;
    // الإقلاع البارد قد يبلّغ عن النقرة مرتين.
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
        // تُعرض وحدها، فلا يتغيّر موضع القراءة بمجرد رؤيتها.
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

import 'dart:convert';
import 'dart:ffi';

/// هل توجد libmpv التي يحتاجها مشغّل التلاوة على لينكس، بالأسماء التي
/// يبحث بها media_kit.
bool linuxHasLibmpv() {
  for (final name in const ['libmpv.so', 'libmpv.so.2', 'libmpv.so.1']) {
    try {
      DynamicLibrary.open(name);
      return true;
    } on ArgumentError {
      // ليست بهذا الاسم؛ يُجرَّب التالي.
    }
  }
  return false;
}

/// أمر تثبيت libmpv في توزيعة لينكس التي يصفها [osRelease] (محتوى
/// `/etc/os-release`)، أو اسم الحزمة إن لم تُعرف التوزيعة.
String mpvInstallCommand(String osRelease) {
  final ids = <String>{};
  for (final line in const LineSplitter().convert(osRelease)) {
    final match = RegExp(r'^(ID|ID_LIKE)=(.*)$').firstMatch(line.trim());
    if (match == null) continue;
    ids.addAll(match.group(2)!.replaceAll(RegExp('["\']'), '').split(' '));
  }
  if (ids.contains('debian') || ids.contains('ubuntu')) {
    return 'sudo apt install libmpv2';
  }
  if (ids.contains('fedora') || ids.contains('rhel')) {
    return 'sudo dnf install mpv-libs';
  }
  if (ids.contains('arch')) return 'sudo pacman -S mpv';
  if (ids.contains('suse') || ids.contains('opensuse')) {
    return 'sudo zypper install libmpv2';
  }
  return 'libmpv (mpv)';
}

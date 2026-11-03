import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/startup_failure.dart';
import 'features/widgets/widget_links.dart';

/// نقطة البداية: [bootstrap] يجهّز كل شيء، ثم تُعرض الواجهة.
void main() async {
  try {
    await bootstrap();
  } catch (e, stack) {
    debugPrint('Startup failed: $e\n$stack');
    runApp(StartupFailureApp(error: e));
    return;
  }
  runApp(const TadbeerApp());
  // أزرار ودجت الشاشة الرئيسية تفتح الشاشة المقابلة.
  WidgetsBinding.instance.addPostFrameCallback((_) => WidgetLinks.attach());
}

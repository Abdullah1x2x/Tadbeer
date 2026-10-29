import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'features/widgets/widget_links.dart';

/// نقطة البداية: [bootstrap] يجهّز كل شيء، ثم تُعرض الواجهة.
void main() async {
  await bootstrap();
  runApp(const TadbeerApp());
  // أزرار ودجت الشاشة الرئيسية تفتح الشاشة المقابلة.
  WidgetsBinding.instance.addPostFrameCallback((_) => WidgetLinks.attach());
}

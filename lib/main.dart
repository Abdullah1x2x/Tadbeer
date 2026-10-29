import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'features/widgets/widget_links.dart';

/// Entrypoint for the Tadbeer application; [bootstrap] holds the startup.
void main() async {
  await bootstrap();
  runApp(const TadbeerApp());
  // Buttons on the home-screen widget open the matching screen.
  WidgetsBinding.instance.addPostFrameCallback((_) => WidgetLinks.attach());
}

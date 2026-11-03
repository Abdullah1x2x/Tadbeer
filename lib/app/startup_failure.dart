import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// تظهر إن فشل [bootstrap]، بدل أن يبقى التطبيق على شاشة البداية.
///
/// الإعدادات لم تُقرأ بعد، فتُعرض الرسالة باللغتين.
class StartupFailureApp extends StatelessWidget {
  final Object error;

  const StartupFailureApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final ar = lookupAppLocalizations(const Locale('ar'));
    final en = lookupAppLocalizations(const Locale('en'));
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(ar.startupFailed, textDirection: TextDirection.rtl),
                const SizedBox(height: 12),
                Text(en.startupFailed, textDirection: TextDirection.ltr),
                const SizedBox(height: 24),
                SelectableText('$error', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

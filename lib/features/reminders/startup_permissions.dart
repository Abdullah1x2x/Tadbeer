import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';
import '../../data/storage/user_data_store.dart';
import 'local_reminder_service.dart';

/// يطلب أذونات الإشعارات والمنبهات مرة واحدة عند أول تشغيل.
///
/// يشرح السبب أولاً، فطلب المنبهات الدقيقة في أندرويد 14 يفتح الإعدادات مباشرة.
/// ومن يؤجله يُسأل ثانية عند أول تذكير يضبطه.
class StartupPermissions {
  StartupPermissions._();

  static const _key = 'startup_permissions';

  /// يعرض الشرح ثم يطلب الأذونات، إن لم يُسأل القارئ من قبل.
  static Future<void> askOnce(BuildContext context) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final store = UserDataStore.instance;
    if (store.featureState(_key)['asked'] == true) return;
    await store.saveFeatureState(_key, {'asked': true});
    if (!context.mounted) return;
    final l10n = context.l10n;
    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.bellRinging, size: 32),
        title: Text(l10n.permissionsTitle, textAlign: TextAlign.center),
        content: Text(l10n.permissionsBody, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.permissionsLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.permissionsAllow),
          ),
        ],
      ),
    );
    if (allow == true) await LocalReminderService.instance.requestPermissions();
  }
}

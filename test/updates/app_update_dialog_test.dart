import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_dialog.dart';
import 'package:tadbeer/features/updates/app_update_model.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

void main() {
  testWidgets(
    'AppUpdateDialog renders update info and action buttons correctly',
    (tester) async {
      const update = AppUpdateInfo(
        latestVersion: '1.2.0',
        buildNumber: 15,
        releaseDate: '2026-11-10',
        title: 'تحديث هام متاح الآن',
        changelog:
            '١. إضافة ميزات جديدة لروابط الآيات.\n٢. تحسينات عامة وسرعة أعلى.',
        telegramUrl: 'https://t.me/tadbeerapp',
        downloadUrl: 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest',
        isMandatory: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => AppUpdateDialog.show(context, update),
                  child: const Text('Show Update'),
                );
              },
            ),
          ),
        ),
      );

      // افتح النافذة
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      // التحقق من ظهور عناصر النافذة
      expect(find.text('تحديث هام متاح الآن'), findsOneWidget);
      expect(find.text('v1.2.0'), findsOneWidget);
      expect(find.text('2026-11-10'), findsOneWidget);
      expect(find.textContaining('روابط الآيات'), findsOneWidget);
      expect(
        find.textContaining('تحميل وتثبيت التحديث تلقائياً'),
        findsOneWidget,
      );
      expect(
        find.textContaining('تحميل عبر قناة تيليجرام الرسمية'),
        findsOneWidget,
      );
      expect(find.textContaining('تحميل من GitHub'), findsNothing);
      expect(find.text('لاحقاً'), findsOneWidget);

      // إغلاق النافذة عبر النقر على "لاحقاً"
      await tester.tap(find.text('لاحقاً'));
      await tester.pumpAndSettle();

      expect(find.text('تحديث هام متاح الآن'), findsNothing);
    },
  );

  testWidgets(
    'AppUpdateDialog renders downloading state when active in AppUpdateService',
    (tester) async {
      const update = AppUpdateInfo(
        latestVersion: '1.2.0',
        buildNumber: 15,
        releaseDate: '2026-11-10',
        title: 'تحديث تجريبي',
        changelog: 'تحسينات',
        telegramUrl: 'https://t.me/tadbeerapp',
        downloadUrl: 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest',
        isMandatory: false,
      );

      // ضبط الحالة المركزية إلى جارٍ التنزيل
      AppUpdateService.instance.downloadState.value = const UpdateDownloadState(
        status: UpdateDownloadStatus.downloading,
        updateInfo: update,
        progress: DownloadProgress(
          receivedBytes: 25 * 1024 * 1024,
          totalBytes: 50 * 1024 * 1024,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppUpdateDialog(update: update)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('جارٍ التحميل والتثبيت التلقائي'),
        findsOneWidget,
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.textContaining('25.0 MB / 50.0 MB'), findsOneWidget);
      expect(find.text('إلغاء التحميل'), findsOneWidget);

      // النقر على إلغاء التحميل
      await tester.tap(find.text('إلغاء التحميل'));
      await tester.pumpAndSettle();

      expect(AppUpdateService.instance.downloadState.value.isIdle, isTrue);
    },
  );
}

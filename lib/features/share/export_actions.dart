import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';

/// نتيجة حفظ صورة في معرض الصور.
enum PhotoSaveResult { saved, denied, failed }

/// يحفظ صورة PNG [bytes] باسم [name] في معرض الصور، بعد طلب الإذن إن لزم.
Future<PhotoSaveResult> saveImageToPhotos(Uint8List bytes, String name) async {
  try {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      return PhotoSaveResult.denied;
    }
    await Gal.putImageBytes(bytes, name: name);
    return PhotoSaveResult.saved;
  } on GalException catch (e) {
    debugPrint('Saving an image to Photos failed: ${e.type}');
    return e.type == GalExceptionType.accessDenied
        ? PhotoSaveResult.denied
        : PhotoSaveResult.failed;
  }
}

/// موضع [context] على الشاشة، تتعلق به قائمة المشاركة في iPad وإلا لم تظهر.
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}

/// يسأل القارئ ماذا يفعل بملف صدّره: يشاركه، أو يحفظه في جهازه.
Future<void> shareOrSaveFile(
  BuildContext context, {
  required File file,
  required String fileName,
  String? subject,
  String? text,
  String? mimeType,
  bool deleteTempFile = true,
}) async {
  try {
    final l10n = context.l10n;
    final origin = shareOrigin(context);
    final save = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.shareNetwork),
              title: Text(l10n.share),
              onTap: () => Navigator.pop(sheet, false),
            ),
            ListTile(
              leading: const Icon(AppIcons.downloadSimple),
              title: Text(l10n.saveToDeviceFiles),
              onTap: () => Navigator.pop(sheet, true),
            ),
          ],
        ),
      ),
    );
    if (save == null) return;
    if (!save) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, name: fileName, mimeType: mimeType)],
            subject: subject,
            text: text,
            sharePositionOrigin: origin,
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.fileShareError(e.toString()),
                textAlign: TextAlign.center,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    try {
      final saved = await FilePicker.saveFile(
        fileName: fileName,
        bytes: await file.readAsBytes(),
      );
      if (saved == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fileSavedToDevice, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorSavingFile(e.toString()),
              textAlign: TextAlign.center,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } finally {
    if (deleteTempFile && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}

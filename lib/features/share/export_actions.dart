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

/// يسأل القارئ ماذا يفعل بملف صدّره: يشاركه، أو يحفظه في جهازه.
Future<void> shareOrSaveFile(
  BuildContext context, {
  required File file,
  required String fileName,
  String? subject,
  String? text,
  String? mimeType,
}) async {
  final l10n = context.l10n;
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
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: fileName, mimeType: mimeType)],
        subject: subject,
        text: text,
      ),
    );
    return;
  }

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
}

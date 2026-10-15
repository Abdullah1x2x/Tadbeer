import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../quran/data/quran_repository.dart';
import '../ayah_link_detail_screen.dart';
import '../ayah_link_model.dart';
import '../ayah_link_repository.dart';

/// أدوات مشاركة واستيراد روابط الآيات دون اتصال بالإنترنت عبر رمز الاستجابة السريعة (QR).
class AyahLinkQrDialog {
  AyahLinkQrDialog._();

  /// يشفر رابط الآيات إلى نص مضغوط صالح للتضمين في رمز QR.
  static String encodeLink(AyahLinkItem link) {
    final payload = {
      'v': 1, // format version
      't': link.title,
      if (link.description != null && link.description!.isNotEmpty)
        'd': link.description,
      'ay': link.verses
          .map((v) => {
                's': v.surahNumber,
                'a': v.ayahNumber,
                if (v.note != null && v.note!.isNotEmpty) 'n': v.note,
              })
          .toList(),
    };
    return 'tadbeer://link?data=${base64Url.encode(utf8.encode(jsonEncode(payload)))}';
  }

  /// يفك تشفير نص الرابط المستورد إلى نموذج بيانات.
  static Map<String, dynamic>? decodeLink(String raw) {
    try {
      String encoded = raw.trim();
      if (encoded.startsWith('tadbeer://link?data=')) {
        encoded = encoded.substring('tadbeer://link?data='.length);
      }
      final jsonStr = utf8.decode(base64Url.decode(encoded));
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
  }

  /// يعرض نافذة رمز QR لمشاركة الرابط دون إنترنت.
  static Future<void> showShareDialog(
    BuildContext context,
    AyahLinkItem link,
  ) {
    final qrData = encodeLink(link);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return showDialog(
      context: context,
      builder: (dialogCtx) {
        final l10n = context.l10n;
        return Directionality(
          textDirection: context.currentLanguage.direction,
          child: AlertDialog(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.isArabic
                        ? 'مشاركة رابط الآيات دون إنترنت'
                        : 'Share Ayah Link Offline',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '«${link.title}»',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.isArabic
                        ? 'يتضمن ${ArabicSearchNormalizer.toArabicDigits(link.verses.length)} آيات مرتبطة'
                        : 'Includes ${link.verses.length} linked verses',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.isArabic
                        ? 'يمكن مسح هذا الرمز من تطبيق تَدْبِير في جهاز آخر لاستيراد الرابط بالكامل دون اتصال بالإنترنت.'
                        : 'This code can be scanned from another Tadbeer device to import the link offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.isArabic
                            ? 'تم نسخ بيانات الرابط إلى الحافظة'
                            : 'Link data copied to clipboard',
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(l10n.isArabic ? 'نسخ البيانات' : 'Copy Data'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.isArabic ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// يعرض نافذة استيراد رابط آيات عبر إدخال أو لصق رمز QR.
  static Future<void> showImportDialog(
    BuildContext context, {
    AyahLinkRepository? repo,
  }) async {
    final linkRepo = repo ?? AyahLinkRepository();
    final quranRepo = QuranRepository.instance;
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final decoded = AyahLinkQrDialog.decodeLink(textController.text);
            final isValid = decoded != null && decoded.containsKey('t');
            final title = isValid ? decoded['t'] as String : '';
            final rawVerses =
                isValid ? (decoded['ay'] as List? ?? const []) : const [];

            final l10n = context.l10n;
            return Directionality(
              textDirection: context.currentLanguage.direction,
              child: AlertDialog(
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.isArabic
                            ? 'استيراد رابط آيات'
                            : 'Import Ayah Link',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.isArabic
                            ? 'الصق رمز المشاركة أو بيانات الرابط أدناه لاستيراده إلى روابطك:'
                            : 'Paste the share code or link data below to import it into your links:',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: textController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.isArabic
                              ? 'الصق الرابط أو النص الممسوح هنا...'
                              : 'Paste link or scanned text here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste_rounded, size: 20),
                            tooltip: l10n.isArabic
                                ? 'لصق من الحافظة'
                                : 'Paste from clipboard',
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                textController.text = data!.text!;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (isValid) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.isArabic ? 'العنوان: $title' : 'Title: $title',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.isArabic
                                    ? 'الآيات المتضمنة: ${ArabicSearchNormalizer.toArabicDigits(rawVerses.length)} آية'
                                    : 'Included verses: ${rawVerses.length} verses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.nightSubtitle
                                      : AppColors.daySubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: !isValid
                        ? null
                        : () async {
                            final desc = decoded['d'] as String?;
                            final created = await linkRepo.createLink(
                              title: title,
                              description: desc,
                            );

                            for (final v in rawVerses) {
                              final map = v as Map<String, dynamic>;
                              final surahNum = map['s'] as int;
                              final ayahNum = map['a'] as int;
                              final note = map['n'] as String?;
                              final ayah =
                                  quranRepo.getAyah(surahNum, ayahNum);
                              if (ayah != null) {
                                await linkRepo.addVerseToLink(
                                  created.id,
                                  ayahId: ayah.id,
                                  surahNumber: surahNum,
                                  ayahNumber: ayahNum,
                                  page: ayah.page,
                                  note: note,
                                );
                              }
                            }

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AyahLinkDetailScreen(
                                    linkId: created.id,
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.isArabic ? 'استيراد الآن' : 'Import Now'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

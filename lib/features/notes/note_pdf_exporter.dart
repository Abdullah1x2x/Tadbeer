import 'dart:io';

import 'package:flutter/material.dart' show BuildContext, TextDirection;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/localization.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../core/utils/text_direction.dart';
import '../../data/models/note_model.dart';
import '../../data/quran/quran_repository.dart';
import '../share/export_actions.dart';

/// يصدّر خاطرة واحدة PDF للمشاركة أو الطباعة، لا للنسخ الاحتياطي.
///
/// تُضمَّن خطوط أميري وأميري قرآني في الملف، ويُضبط اتجاه الصفحة من اليمين
/// لليسار، ليظهر العربي صحيحاً.
class NotePdfExporter {
  NotePdfExporter._();

  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;
  static pw.Font? _cachedQuran;

  static pw.Font? get regularFont => _cachedRegular;

  static pw.Font? get boldFont => _cachedBold;

  /// خط المصحف المحمّل، لآيات الملف.
  static pw.Font? get quranFont => _cachedQuran;

  /// يحمّل خطوط أميري وأميري قرآني في الذاكرة مرة واحدة.
  static Future<void> ensureFontsLoaded() => _ensureFontsLoaded();

  static Future<void> _ensureFontsLoaded() async {
    if (_cachedRegular == null) {
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      _cachedRegular = pw.Font.ttf(fontData);
    }
    if (_cachedBold == null) {
      final fontBoldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      _cachedBold = pw.Font.ttf(fontBoldData);
    }
    if (_cachedQuran == null) {
      final fontQuranData = await rootBundle.load(
        'assets/fonts/AmiriQuran-Regular.ttf',
      );
      _cachedQuran = pw.Font.ttf(fontQuranData);
    }
  }

  /// ينشئ ملف PDF للخاطرة في مجلد الكاش أو [outputDir].
  static Future<File> generateNotePdf(
    NoteItem note, {
    Directory? outputDir,
    AppStrings? l10n,
    AppLanguage? language,
  }) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document();

    final ttfRegular = _cachedRegular!;
    final ttfBold = _cachedBold!;
    final ttfQuran = _cachedQuran!;

    final isAyahNote = note.isAyahNote;
    final effectiveLang = language ?? l10n?.language ?? AppLanguage.arabic;
    final isArabic = effectiveLang == AppLanguage.arabic;
    final baseDir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final fallbackFlutterDir = isArabic ? TextDirection.rtl : TextDirection.ltr;

    pw.TextDirection pwDirOf(String text) =>
        directionOfText(text, fallback: fallbackFlutterDir) == TextDirection.rtl
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;

    String formatNum(int n) =>
        isArabic ? ArabicSearchNormalizer.toArabicDigits(n) : '$n';

    final surahNum = note.surahNumber;
    final ayahNum = note.ayahNumber;
    final surah = (surahNum != null && surahNum >= 1 && surahNum <= 114)
        ? QuranRepository.instance.getSurah(surahNum)
        : null;
    final surahTitle = surah != null
        ? (l10n?.surahTitle(surah.name) ??
              (isArabic ? 'سورة ${surah.name}' : 'Surah ${surah.name}'))
        : (surahNum != null
              ? (isArabic
                    ? 'سورة رقم ${formatNum(surahNum)}'
                    : 'Surah ${formatNum(surahNum)}')
              : (l10n?.ayahNoteLabel ??
                    (isArabic ? 'خاطرة على آية' : 'Ayah Reflection')));
    final ayahTitle = ayahNum != null
        ? (l10n?.ayahTitle(ayahNum) ??
              (isArabic
                  ? 'الآية ${formatNum(ayahNum)}'
                  : 'Verse ${formatNum(ayahNum)}'))
        : null;
    final ayahRef = [surahTitle, ?ayahTitle].join(' · ');

    final pageText = note.page != null
        ? (l10n?.pageAbbr(note.page!) ??
              (isArabic
                  ? 'صفحة ${formatNum(note.page!)}'
                  : 'p. ${formatNum(note.page!)}'))
        : null;

    final dateText =
        '${note.createdAt.year}/${note.createdAt.month}/${note.createdAt.day}';
    final trimmedTitle = note.title?.trim();
    final contentSectionLabel = isAyahNote
        ? (l10n?.reflectionNoteColon ??
              (isArabic ? 'تدبّر الآية وملاحظاتي:' : 'Reflection note:'))
        : (isArabic ? 'المحتوى:' : 'Content:');
    final footerText = isArabic
        ? 'تطبيق تَدبِير · لا إعلانات · لا تتبع · محلي بالكامل'
        : 'Tadbeer · No ads · No tracking · 100% local';

    final paragraphs = note.content.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: baseDir,
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        footer: (pw.Context pdfContext) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFDDD7C8),
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  footerText,
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '${formatNum(pdfContext.pageNumber)} / ${formatNum(pdfContext.pagesCount)}',
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context pdfContext) => <pw.Widget>[
          // الترويسة.
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFF606C38),
                  width: 2,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تَدبِير · Tadbeer',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 18,
                    color: const PdfColor.fromInt(0xFF606C38),
                  ),
                ),
                pw.Text(
                  isArabic
                      ? ArabicSearchNormalizer.convertDigits(dateText)
                      : dateText,
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          if (isAyahNote) ...[
            // السورة والآية.
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF4F1E8),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ayahRef,
                    textDirection: baseDir,
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 14,
                      color: const PdfColor.fromInt(0xFF3F4925),
                    ),
                  ),
                  if (pageText != null)
                    pw.Text(
                      pageText,
                      textDirection: baseDir,
                      style: pw.TextStyle(
                        font: ttfRegular,
                        fontSize: 12,
                        color: const PdfColor.fromInt(0xFF606C38),
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // صندوق الآية.
            if (note.ayahText != null && note.ayahText!.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFDDD7C8),
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  note.ayahText!,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: ttfQuran,
                    fontSize: 18,
                    lineSpacing: 8,
                    color: const PdfColor.fromInt(0xFF22211C),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          ],

          // عنوان الخاطرة (الحرة أو خواطر الآيات الاختيارية).
          if (trimmedTitle != null && trimmedTitle.isNotEmpty) ...[
            pw.Text(
              trimmedTitle,
              textDirection: pwDirOf(trimmedTitle),
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: isAyahNote ? 18 : 22,
                color: const PdfColor.fromInt(0xFF3F4925),
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          pw.Text(
            contentSectionLabel,
            textDirection: baseDir,
            style: pw.TextStyle(
              font: ttfBold,
              fontSize: 14,
              color: const PdfColor.fromInt(0xFF606C38),
            ),
          ),
          pw.SizedBox(height: 8),

          // فقرات الخاطرة: مفرّدة حتى تتمدد عبر الصفحات دون overflow.
          for (final line in paragraphs)
            if (line.trim().isEmpty)
              pw.SizedBox(height: 8)
            else ...[
              pw.Text(
                line,
                textDirection: pwDirOf(line),
                style: pw.TextStyle(
                  font: ttfRegular,
                  fontSize: 14,
                  lineSpacing: 6,
                  color: const PdfColor.fromInt(0xFF22211C),
                ),
              ),
              pw.SizedBox(height: 4),
            ],
        ],
      ),
    );

    final dir = outputDir ?? await getTemporaryDirectory();
    final safeId = note.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = File('${dir.path}/tadbeer_note_${safeId}_$stamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// يصدّر الخاطرة PDF، ثم يشاركها القارئ أو يحفظها في جهازه.
  static Future<void> exportAndShareNote(
    BuildContext context,
    NoteItem note,
  ) async {
    final l10n = context.l10n;
    final language = context.currentLanguage;
    final file = await generateNotePdf(
      note,
      l10n: l10n,
      language: language,
    );
    if (!context.mounted) return;
    final trimmedTitle = note.title?.trim();
    final subject = (trimmedTitle != null && trimmedTitle.isNotEmpty)
        ? trimmedTitle
        : (language == AppLanguage.arabic
              ? 'ملاحظة وتدبر من تَدبِير'
              : 'Tadbeer Reflection Note');
    await shareOrSaveFile(
      context,
      file: file,
      fileName: file.uri.pathSegments.last,
      subject: subject,
    );
  }
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/note_model.dart';
import '../../data/quran/quran_repository.dart';
import '../../core/utils/arabic_search_normalizer.dart';

/// Service for exporting an individual Tadbeer note (Ayah Note or Free Note) to PDF.
///
/// EDUCATIONAL NOTE:
/// PDF export is intended for personal sharing and printing, NOT as a backup format.
/// To render Arabic typography correctly in PDF documents, TrueType font files
/// (Amiri-Regular, Amiri-Bold, and AmiriQuran) are embedded directly, and the
/// page text direction is explicitly set to RTL.
class NotePdfExporter {
  NotePdfExporter._();

  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;
  static pw.Font? _cachedQuran;

  /// الخط العربي العادي المحمّل في الذاكرة لتصدير ملفات PDF.
  static pw.Font? get regularFont => _cachedRegular;

  /// الخط العربي العريض المحمّل في الذاكرة لتصدير ملفات PDF.
  static pw.Font? get boldFont => _cachedBold;

  /// خط المصحف القرآني المحمّل في الذاكرة لتصدير الآيات داخل PDF.
  static pw.Font? get quranFont => _cachedQuran;

  /// Ensures Arabic TrueType fonts (Amiri-Regular, Amiri-Bold, AmiriQuran) are cached in memory.
  static Future<void> ensureFontsLoaded() => _ensureFontsLoaded();

  /// تحميل خطوط TrueType العربية من أصول التطبيق وحفظها في الذاكرة المؤقتة.
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

  /// Generates a PDF file for a single note and writes it to cache storage.
  static Future<File> generateNotePdf(NoteItem note) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document();

    final ttfRegular = _cachedRegular!;
    final ttfBold = _cachedBold!;
    final ttfQuran = _cachedQuran!;

    final isAyahNote = note.isAyahNote;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header Banner
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
                        'تَدْبِير · Tadbeer',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 18,
                          color: const PdfColor.fromInt(0xFF606C38),
                        ),
                      ),
                      pw.Text(
                        '${note.createdAt.year}/${note.createdAt.month}/${note.createdAt.day}',
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
                  // Surah & Ayah Info
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
                          () {
                            final surahNum = note.surahNumber;
                            final ayahNum = note.ayahNumber;
                            final surah =
                                (surahNum != null &&
                                    surahNum >= 1 &&
                                    surahNum <= 114)
                                ? QuranRepository.instance.getSurah(surahNum)
                                : null;
                            final surahTitle = surah != null
                                ? 'سورة ${surah.name}'
                                : 'سورة رقم ${surahNum ?? ''}';
                            final ayahStr = ayahNum != null
                                ? 'الآية ${ArabicSearchNormalizer.toArabicDigits(ayahNum)}'
                                : '';
                            return '$surahTitle · $ayahStr';
                          }(),
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 14,
                            color: const PdfColor.fromInt(0xFF3F4925),
                          ),
                        ),
                        if (note.page != null)
                          pw.Text(
                            'صفحة ${ArabicSearchNormalizer.toArabicDigits(note.page!)}',
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

                  // Quran Verse Box
                  if (note.ayahText != null && note.ayahText!.isNotEmpty)
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
                        style: pw.TextStyle(
                          font: ttfQuran,
                          fontSize: 18,
                          lineSpacing: 8,
                          color: const PdfColor.fromInt(0xFF22211C),
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  pw.SizedBox(height: 24),
                ] else ...[
                  // Free Note Title
                  if (note.title != null && note.title!.isNotEmpty) ...[
                    pw.Text(
                      note.title!,
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 22,
                        color: const PdfColor.fromInt(0xFF3F4925),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                  ],
                ],

                // Note Content Title
                pw.Text(
                  isAyahNote ? 'تدبّر الآية وملاحظاتي:' : 'المحتوى:',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                    color: const PdfColor.fromInt(0xFF606C38),
                  ),
                ),
                pw.SizedBox(height: 8),

                // Note Content Body
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFAF9F5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    note.content,
                    style: pw.TextStyle(
                      font: ttfRegular,
                      fontSize: 14,
                      lineSpacing: 6,
                      color: const PdfColor.fromInt(0xFF22211C),
                    ),
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.only(top: 16),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(
                        color: PdfColor.fromInt(0xFFDDD7C8),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Text(
                    'تطبيق تَدْبِير · لا إعلانات · لا تتبع · محلي بالكامل',
                    style: pw.TextStyle(
                      font: ttfRegular,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/tadbeer_note_${note.id.substring(0, 8)}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Exports and invokes the platform share sheet for the note PDF.
  static Future<void> exportAndShareNote(NoteItem note) async {
    final file = await generateNotePdf(note);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: note.title ?? 'ملاحظة وتدبر من تَدْبِير',
      ),
    );
  }
}

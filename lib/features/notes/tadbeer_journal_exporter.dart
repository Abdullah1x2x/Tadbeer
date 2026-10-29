import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import '../../data/models/note_model.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/models/tadbeer_model.dart';
import '../tadbeer/tadbeer_questions.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'note_pdf_exporter.dart';
import '../../core/design_system/app_icons.dart';

/// فترات تصدير دفتر التدبر.
enum JournalPeriod {
  last7Days('آخر 7 أيام (أسبوعي)'),
  last30Days('آخر 30 يومًا (شهري)'),
  allTime('كامل السجل التدبري');

  final String label;
  const JournalPeriod(this.label);
}

/// الخواطر ووقفات التدبر في فترة.
class JournalSummary {
  final JournalPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final List<NoteItem> notes;
  final List<TadbeerItem> tadbeerItems;
  final Set<String> surahNames;

  const JournalSummary({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.tadbeerItems,
    required this.surahNames,
  });

  int get totalReflections => notes.length + tadbeerItems.length;

  bool get isEmpty => totalReflections == 0;
}

/// دفتر التدبر: يجمع الخواطر ووقفات التدبر في فترة، ويصدّرها PDF أو Markdown دون إنترنت.
/// تُضمَّن خطوط أميري في الملف، ويُحترم الاتجاه من اليمين لليسار.
class TadbeerJournalExporter {
  TadbeerJournalExporter._();

  /// يجمع خواطر الفترة [period].
  static JournalSummary buildSummary({
    JournalPeriod period = JournalPeriod.last30Days,
  }) {
    final now = DateTime.now();
    final DateTime cutoff;
    switch (period) {
      case JournalPeriod.last7Days:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case JournalPeriod.last30Days:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case JournalPeriod.allTime:
        cutoff = DateTime.fromMillisecondsSinceEpoch(0);
        break;
    }

    final store = UserDataStore.instance;
    final repo = QuranRepository.instance;

    final filteredNotes = store.notes.where((n) {
      return n.updatedAt.isAfter(cutoff) || n.createdAt.isAfter(cutoff);
    }).toList();

    final filteredTadbeer = store.tadbeerItems.where((t) {
      return !t.isEmpty &&
          (t.updatedAt.isAfter(cutoff) || t.createdAt.isAfter(cutoff));
    }).toList();

    filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    filteredTadbeer.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final surahNames = <String>{};
    for (final n in filteredNotes) {
      if (n.surahNumber != null) {
        surahNames.add(repo.getSurah(n.surahNumber!).name);
      }
    }
    for (final t in filteredTadbeer) {
      surahNames.add(repo.getSurah(t.surahNumber).name);
    }

    return JournalSummary(
      period: period,
      startDate: cutoff,
      endDate: now,
      notes: filteredNotes,
      tadbeerItems: filteredTadbeer,
      surahNames: surahNames,
    );
  }

  /// الدفتر بصيغة Markdown.
  static String generateMarkdown(JournalSummary summary) {
    final repo = QuranRepository.instance;
    final buffer = StringBuffer();

    buffer.writeln('# 📖 دفتر تدبّر — سجل الخواطر والتأملات القرآنية');
    buffer.writeln();
    buffer.writeln('**الفترة:** ${summary.period.label}');
    buffer.writeln(
      '**تاريخ التصدير:** ${summary.endDate.year}/${summary.endDate.month}/${summary.endDate.day}',
    );
    buffer.writeln();

    // جدول الإحصاءات.
    buffer.writeln('### 📊 ملخص الإحصاءات التدبرية');
    buffer.writeln('| البند | العدد |');
    buffer.writeln('|---|---|');
    buffer.writeln(
      '| إجمالي الخواطر والوقفات | ${ArabicSearchNormalizer.toArabicDigits(summary.totalReflections)} |',
    );
    buffer.writeln(
      '| الوقفات التدبرية | ${ArabicSearchNormalizer.toArabicDigits(summary.tadbeerItems.length)} |',
    );
    buffer.writeln(
      '| الملاحظات والفوائد | ${ArabicSearchNormalizer.toArabicDigits(summary.notes.length)} |',
    );
    buffer.writeln(
      '| السور المتدبرة | ${ArabicSearchNormalizer.toArabicDigits(summary.surahNames.length)} |',
    );
    buffer.writeln();

    if (summary.surahNames.isNotEmpty) {
      buffer.writeln(
        '**السور التي تم تدبرها:** ${summary.surahNames.join('، ')}',
      );
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();

    // وقفات التدبر.
    if (summary.tadbeerItems.isNotEmpty) {
      buffer.writeln('## 🌿 الوقفات التدبرية');
      buffer.writeln();
      for (final t in summary.tadbeerItems) {
        final surah = repo.getSurah(t.surahNumber);
        final ayah = repo.getAyah(t.surahNumber, t.ayahNumber);
        buffer.writeln(
          '### سورة ${surah.name} — الآية ${ArabicSearchNormalizer.toArabicDigits(t.ayahNumber)}',
        );
        if (ayah != null) {
          buffer.writeln('> ﴿ ${ayah.text} ﴾');
          buffer.writeln();
        }
        final questions = TadbeerQuestions.forAyah(ayah);
        for (var i = 0; i < questions.length; i++) {
          final ans = t.answers[TadbeerItem.questionKeys[i]]?.trim();
          if (ans != null && ans.isNotEmpty) {
            buffer.writeln('*${questions[i]}*');
            buffer.writeln(ans);
            buffer.writeln();
          }
        }
        buffer.writeln(
          '_تاريخ التدوين: ${t.updatedAt.year}/${t.updatedAt.month}/${t.updatedAt.day}_',
        );
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    // الخواطر.
    if (summary.notes.isNotEmpty) {
      buffer.writeln('## 📝 الخواطر والملاحظات');
      buffer.writeln();
      for (final n in summary.notes) {
        if (n.isAyahNote) {
          final surah = repo.getSurah(n.surahNumber!);
          buffer.writeln(
            '### سورة ${surah.name} — الآية ${ArabicSearchNormalizer.toArabicDigits(n.ayahNumber!)}',
          );
          if (n.ayahText != null) {
            buffer.writeln('> ﴿ ${n.ayahText} ﴾');
            buffer.writeln();
          }
        } else {
          buffer.writeln('### ${n.title ?? 'خاطرة حرة'}');
        }

        buffer.writeln(n.content);
        buffer.writeln();
        buffer.writeln(
          '_تاريخ التدوين: ${n.updatedAt.year}/${n.updatedAt.month}/${n.updatedAt.day}_',
        );
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln(
      '_تم التصدير محليًا عبر تطبيق تَدْبِير (Tadbeer) — بدون أي اتصال خارجي_',
    );
    return buffer.toString();
  }

  /// ينشئ الدفتر PDF في مجلد الكاش.
  static Future<File> generatePdf(
    JournalSummary summary, {
    Directory? outputDir,
  }) async {
    await NotePdfExporter.ensureFontsLoaded();
    final pdf = pw.Document();

    final ttfRegular = NotePdfExporter.regularFont!;
    final ttfBold = NotePdfExporter.boldFont!;
    final ttfQuran = NotePdfExporter.quranFont!;
    final repo = QuranRepository.instance;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFF606C38),
                  width: 1.5,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تَدْبِير · دفتر التدبر والخواطر القرآنية',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                    color: const PdfColor.fromInt(0xFF606C38),
                  ),
                ),
                pw.Text(
                  '${summary.period.label} · ${summary.endDate.year}/${summary.endDate.month}/${summary.endDate.day}',
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تطبيق تَدْبِير — تدبر آيات القرآن الكريم',
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'صفحة ${ArabicSearchNormalizer.toArabicDigits(context.pageNumber)} من ${ArabicSearchNormalizer.toArabicDigits(context.pagesCount)}',
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),

            // ترويسة الإحصاءات.
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFAEDCD),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStatBox(
                    label: 'إجمالي الخواطر',
                    value: ArabicSearchNormalizer.toArabicDigits(
                      summary.totalReflections,
                    ),
                    fontBold: ttfBold,
                    fontRegular: ttfRegular,
                  ),
                  _buildPdfStatBox(
                    label: 'الوقفات التدبرية',
                    value: ArabicSearchNormalizer.toArabicDigits(
                      summary.tadbeerItems.length,
                    ),
                    fontBold: ttfBold,
                    fontRegular: ttfRegular,
                  ),
                  _buildPdfStatBox(
                    label: 'الفوائد والملاحظات',
                    value: ArabicSearchNormalizer.toArabicDigits(
                      summary.notes.length,
                    ),
                    fontBold: ttfBold,
                    fontRegular: ttfRegular,
                  ),
                  _buildPdfStatBox(
                    label: 'السور المتدبرة',
                    value: ArabicSearchNormalizer.toArabicDigits(
                      summary.surahNames.length,
                    ),
                    fontBold: ttfBold,
                    fontRegular: ttfRegular,
                  ),
                ],
              ),
            ),

            if (summary.surahNames.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'السور التي شملها التدبر: ${summary.surahNames.join('، ')}',
                style: pw.TextStyle(
                  font: ttfRegular,
                  fontSize: 10,
                  color: const PdfColor.fromInt(0xFF283618),
                ),
              ),
            ],

            pw.SizedBox(height: 20),

            if (summary.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Text(
                    'لا توجد خواطر أو وقفات تدبرية مسجلة خلال هذه الفترة.',
                    style: pw.TextStyle(
                      font: ttfRegular,
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ),

            // قسم وقفات التدبر.
            if (summary.tadbeerItems.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xFF606C38),
                      width: 1,
                    ),
                  ),
                ),
                child: pw.Text(
                  'الوقفات التدبرية (أسئلة التدبر الأربعة)',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                    color: const PdfColor.fromInt(0xFF283618),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              ...summary.tadbeerItems.map((t) {
                final surah = repo.getSurah(t.surahNumber);
                final ayah = repo.getAyah(t.surahNumber, t.ayahNumber);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 14),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFDDA15E),
                      width: 1,
                    ),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(t.ayahNumber)}',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 12,
                              color: const PdfColor.fromInt(0xFF606C38),
                            ),
                          ),
                          pw.Text(
                            '${t.updatedAt.year}/${t.updatedAt.month}/${t.updatedAt.day}',
                            style: pw.TextStyle(
                              font: ttfRegular,
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      if (ayah != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            '﴿ ${ayah.text} ﴾',
                            style: pw.TextStyle(
                              font: ttfQuran,
                              fontSize: 11,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 8),
                      ...List.generate(TadbeerItem.questions.length, (idx) {
                        final ans = t.answers[TadbeerItem.questionKeys[idx]]
                            ?.trim();
                        if (ans == null || ans.isEmpty) {
                          return pw.SizedBox.shrink();
                        }
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                            children: [
                              pw.Text(
                                TadbeerQuestions.forAyah(ayah)[idx],
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 10,
                                  color: const PdfColor.fromInt(0xFF606C38),
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                ans,
                                style: pw.TextStyle(
                                  font: ttfRegular,
                                  fontSize: 10,
                                  color: PdfColors.grey900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],

            pw.SizedBox(height: 16),

            // قسم الخواطر.
            if (summary.notes.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xFF606C38),
                      width: 1,
                    ),
                  ),
                ),
                child: pw.Text(
                  'الخواطر والفوائد المسجلة',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                    color: const PdfColor.fromInt(0xFF283618),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              ...summary.notes.map((n) {
                final isAyahNote = n.isAyahNote;
                final surah = isAyahNote ? repo.getSurah(n.surahNumber!) : null;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            isAyahNote
                                ? 'سورة ${surah!.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(n.ayahNumber!)}'
                                : (n.title ?? 'خاطرة حرة'),
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 11,
                              color: const PdfColor.fromInt(0xFF606C38),
                            ),
                          ),
                          pw.Text(
                            '${n.updatedAt.year}/${n.updatedAt.month}/${n.updatedAt.day}',
                            style: pw.TextStyle(
                              font: ttfRegular,
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      if (n.ayahText != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          '﴿ ${n.ayahText} ﴾',
                          style: pw.TextStyle(
                            font: ttfQuran,
                            fontSize: 11,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      pw.Text(
                        n.content,
                        style: pw.TextStyle(
                          font: ttfRegular,
                          fontSize: 10,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ];
        },
      ),
    );

    final dir = outputDir ?? await getTemporaryDirectory();
    final file = File(
      '${dir.path}/tadbeer_journal_${summary.period.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// صندوق إحصاء صغير في ترويسة الملف.
  static pw.Widget _buildPdfStatBox({
    required String label,
    required String value,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 16,
            color: const PdfColor.fromInt(0xFF283618),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: 9,
            color: const PdfColor.fromInt(0xFF606C38),
          ),
        ),
      ],
    );
  }

  /// يصدّر الدفتر PDF أو Markdown ويفتح المشاركة.
  static Future<void> exportAndShareJournal({
    required JournalPeriod period,
    required bool asPdf,
  }) async {
    final summary = buildSummary(period: period);

    if (asPdf) {
      final pdfFile = await generatePdf(summary);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdfFile.path)],
          subject: 'دفتر تدبّر — ${period.label}',
        ),
      );
    } else {
      final mdString = generateMarkdown(summary);
      final dir = await getTemporaryDirectory();
      final mdFile = File(
        '${dir.path}/tadbeer_journal_${period.name}_${DateTime.now().millisecondsSinceEpoch}.md',
      );
      await mdFile.writeAsString(mdString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(mdFile.path)],
          subject: 'دفتر تدبّر — ${period.label}',
        ),
      );
    }
  }

  /// لوحة لاختيار الفترة والصيغة.
  static Future<void> showExportDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    JournalPeriod selectedPeriod = JournalPeriod.last30Days;
    bool exportAsPdf = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final summary = buildSummary(period: selectedPeriod);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.bookOpenTextFill,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'تصدير دفتر التدبّر والخواطر',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'الفترة الزمنية:',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: JournalPeriod.values.map((p) {
                          final isSelected = p == selectedPeriod;
                          return ChoiceChip(
                            label: Text(
                              p.label,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.olive,
                            onSelected: (_) {
                              setSheetState(() => selectedPeriod = p);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'صيغة التصدير:',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: exportAsPdf
                                    ? AppColors.olive.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: exportAsPdf
                                      ? AppColors.olive
                                      : Colors.grey.withValues(alpha: 0.4),
                                  width: exportAsPdf ? 2 : 1,
                                ),
                              ),
                              onPressed: () {
                                setSheetState(() => exportAsPdf = true);
                              },
                              icon: const Icon(AppIcons.filePdfFill),
                              label: const Text(
                                'مستند PDF',
                                style: TextStyle(fontFamily: 'Amiri'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: !exportAsPdf
                                    ? AppColors.olive.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: !exportAsPdf
                                      ? AppColors.olive
                                      : Colors.grey.withValues(alpha: 0.4),
                                  width: !exportAsPdf ? 2 : 1,
                                ),
                              ),
                              onPressed: () {
                                setSheetState(() => exportAsPdf = false);
                              },
                              icon: const Icon(AppIcons.code),
                              label: const Text(
                                'ملف Markdown',
                                style: TextStyle(fontFamily: 'Amiri'),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.comsilkLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'يحتوي التقرير على ${ArabicSearchNormalizer.toArabicDigits(summary.totalReflections)} خاطرة وملاحظة تدبرية عبر ${ArabicSearchNormalizer.toArabicDigits(summary.surahNames.length)} سورة قرآنية.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetCtx);
                          await exportAndShareJournal(
                            period: selectedPeriod,
                            asPdf: exportAsPdf,
                          );
                        },
                        icon: const Icon(AppIcons.shareNetworkFill),
                        label: const Text(
                          'تصدير ومشاركة الآن',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../data/book_model.dart';
import '../../continue/last_activity.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/utils/text_direction.dart';
import '../../share/export_actions.dart';

part 'book_reader_views.dart';

/// قراءة الكتب والملازم: فصول، أو نص، أو PDF.
class BookReaderScreen extends StatefulWidget {
  final BookModel book;
  final int initialChapterIndex;

  /// صفحة PDF التي يُفتح عليها (من 0).
  final int initialPdfPage;

  const BookReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
    this.initialPdfPage = 0,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  int _currentChapterIndex = 0;
  double _fontSize = 17.5;
  final ScrollController _scrollController = ScrollController();

  String? _loadedFileContent;
  bool _isLoadingFile = false;
  String? _fileLoadError;

  String? _localPdfPath;
  bool _isLoadingPdf = false;
  String? _pdfLoadError;
  int _currentPdfPage = 0;
  int _totalPdfPages = 0;

  @override
  void initState() {
    super.initState();
    final total = widget.book.chapters.length;
    if (total > 0) {
      _currentChapterIndex = widget.initialChapterIndex.clamp(0, total - 1);
    } else {
      _currentChapterIndex = 0;
    }
    _currentPdfPage = widget.initialPdfPage < 0 ? 0 : widget.initialPdfPage;
    _recordActivity();

    if (widget.book.hasAttachedFile && widget.book.isText) {
      _loadFileText();
    }
    if (widget.book.isPdf) {
      _loadPdf();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    final path = widget.book.filePath;
    if (path == null) return;

    setState(() {
      _isLoadingPdf = true;
      _pdfLoadError = null;
    });

    try {
      if (path.startsWith('assets/')) {
        final tempDir = await getTemporaryDirectory();
        final fileName = path.split('/').last;
        final file = File('${tempDir.path}/$fileName');
        if (!await file.exists()) {
          final byteData = await rootBundle.load(path);
          await file.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );
        }
        if (mounted) {
          setState(() {
            _localPdfPath = file.path;
            _isLoadingPdf = false;
          });
        }
        return;
      }

      final file = File(path);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localPdfPath = file.path;
            _isLoadingPdf = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pdfLoadError = 'ملف الـ PDF غير موجود على الجهاز.';
            _isLoadingPdf = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfLoadError = 'تعذر قراءة ملف الـ PDF: $e';
          _isLoadingPdf = false;
        });
      }
    }
  }

  Future<void> _loadFileText() async {
    final path = widget.book.filePath;
    if (path == null) return;

    setState(() {
      _isLoadingFile = true;
      _fileLoadError = null;
    });

    try {
      if (path.startsWith('assets/')) {
        final text = await rootBundle.loadString(path);
        if (mounted) {
          setState(() {
            _loadedFileContent = text;
            _isLoadingFile = false;
          });
        }
        return;
      }
      final file = File(path);
      if (await file.exists()) {
        final text = await file.readAsString();
        if (mounted) {
          setState(() {
            _loadedFileContent = text;
            _isLoadingFile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _fileLoadError = 'الملف المرفق غير موجود على الجهاز.';
            _isLoadingFile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileLoadError = 'تعذر قراءة محتوى الملف: $e';
          _isLoadingFile = false;
        });
      }
    }
  }

  /// يحفظ الفصل، أو صفحة PDF، ليعود إليه "أكمل من حيث توقفت".
  void _recordActivity() => LastActivityStore.record(
    ActivityKind.book,
    ref: widget.book.id,
    title: widget.book.title,
    position: widget.book.isPdf ? _currentPdfPage : _currentChapterIndex,
  );

  void _changeChapter(int index) {
    if (index < 0 || index >= widget.book.chapters.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentChapterIndex = index;
    });
    _recordActivity();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _copyChapterContent() {
    String textToCopy = '';
    if (widget.book.chapters.isNotEmpty) {
      final chapter = widget.book.chapters[_currentChapterIndex];
      textToCopy =
          '${widget.book.title}\n${chapter.title}\n\n${chapter.content}\n\n— تطبيق تَدْبِير';
    } else if (_loadedFileContent != null) {
      textToCopy =
          '${widget.book.title}\n\n$_loadedFileContent\n\n— تطبيق تَدْبِير';
    }

    if (textToCopy.isEmpty) return;

    Clipboard.setData(ClipboardData(text: textToCopy));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.textCopied,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// زرا تصغير الخط وتكبيره، وبينهما حجمه الحالي.
  List<Widget> _fontSizeControls() => [
    IconButton(
      tooltip: context.l10n.decreaseFontSize,
      icon: const Icon(AppIcons.minus, size: 20),
      onPressed: _fontSize > 14 ? () => setState(() => _fontSize -= 1.5) : null,
    ),
    Text(
      '${_fontSize.toInt()}',
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
    IconButton(
      tooltip: context.l10n.increaseFontSize,
      icon: const Icon(AppIcons.plus, size: 20),
      onPressed: _fontSize < 28 ? () => setState(() => _fontSize += 1.5) : null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Column(
            children: [
              Text(
                widget.book.title,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.book.isPdf && _totalPdfPages > 0)
                Text(
                  l10n.pageOfTotal(_currentPdfPage + 1, _totalPdfPages),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else if (widget.book.author.isNotEmpty)
                Text(
                  widget.book.author,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (widget.book.hasAttachedFile)
              IconButton(
                tooltip: l10n.shareFile,
                icon: const Icon(AppIcons.shareNetworkFill),
                onPressed: _shareOrOpenFile,
              ),
            if (widget.book.chapters.length > 1)
              IconButton(
                tooltip: l10n.tableOfContents,
                icon: const Icon(AppIcons.listBullets),
                onPressed: _showChapterListSheet,
              ),
            if (widget.book.chapters.isNotEmpty || _loadedFileContent != null)
              IconButton(
                tooltip: l10n.copyContent,
                icon: const Icon(AppIcons.copy),
                onPressed: _copyChapterContent,
              ),
          ],
        ),
        body: SafeArea(child: _buildBody(isDark, primaryColor)),
      ),
    );
  }

  Widget _buildPdfView(bool isDark, Color primaryColor) {
    final canUseNative = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (canUseNative) {
      if (_isLoadingPdf) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                context.l10n.preparingDocument,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }

      if (_pdfLoadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  AppIcons.warningCircle,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _pdfLoadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadPdf,
                  icon: const Icon(AppIcons.arrowClockwise),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        );
      }

      if (_localPdfPath != null) {
        return Stack(
          children: [
            PDFView(
              filePath: _localPdfPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: false,
              defaultPage: _currentPdfPage,
              fitPolicy: FitPolicy.WIDTH,
              nightMode: isDark,
              onRender: (pages) {
                if (mounted) {
                  setState(() {
                    _totalPdfPages = pages ?? 0;
                    _isLoadingPdf = false;
                  });
                }
              },
              onError: (error) {
                if (mounted) {
                  setState(() {
                    _pdfLoadError = 'خطأ أثناء عرض الملف: $error';
                    _isLoadingPdf = false;
                  });
                }
              },
              onPageError: (page, error) {
                if (mounted) {
                  setState(() {
                    _pdfLoadError = 'تعذر تحميل الصفحة $page: $error';
                  });
                }
              },
              onPageChanged: (page, total) {
                if (mounted) {
                  final moved = (page ?? 0) != _currentPdfPage;
                  setState(() {
                    _currentPdfPage = page ?? 0;
                    _totalPdfPages = total ?? 0;
                  });
                  if (moved) _recordActivity();
                }
              },
            ),
            if (_totalPdfPages > 0)
              Positioned(
                bottom: 16,
                right: 0,
                left: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(
                        alpha: 0.82,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      context.l10n.pageOfTotal(
                        _currentPdfPage + 1,
                        _totalPdfPages,
                      ),
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    }

    // بديل للمنصات غير المحمولة (سطح المكتب والويب والاختبارات).
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(
                builder: (context) {
                  final pdfAccentColor =
                      widget.book.badgeColor ??
                      (isDark ? AppColors.darkAccentGold : AppColors.olive);
                  return Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: pdfAccentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: pdfAccentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      AppIcons.filePdfFill,
                      color: pdfAccentColor,
                      size: 46,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                widget.book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.book.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.book.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccentGold : AppColors.olive)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.book.category} • ${widget.book.formattedFileSize}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.oliveDark,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(AppIcons.arrowSquareOut),
                label: Text(
                  context.l10n.openAndReadPdf,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _shareOrOpenFile,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(AppIcons.shareNetworkFill),
                label: Text(context.l10n.shareFile),
                onPressed: _shareOrOpenFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContentView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.bookOpenFill,
              size: 56,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noTextContentAvailable,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

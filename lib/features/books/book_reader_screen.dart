import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import 'book_model.dart';

/// شاشة قراءة واستعراض الملازم والكتب التدبرية (فصول، نصوص، أو مستندات PDF).
class BookReaderScreen extends StatefulWidget {
  final BookModel book;
  final int initialChapterIndex;

  const BookReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
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
          await file.writeAsBytes(byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ));
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

  void _changeChapter(int index) {
    if (index < 0 || index >= widget.book.chapters.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentChapterIndex = index;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showChapterListSheet() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return Directionality(
          textDirection: ctx.currentLanguage.direction,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.list_alt_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.bookIndexPrefix(widget.book.title),
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.book.chapters.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chap = widget.book.chapters[index];
                      final isCurrent = index == _currentChapterIndex;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isCurrent
                              ? primaryColor
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                        title: Text(
                          chap.title,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 15,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent ? primaryColor : null,
                          ),
                        ),
                        subtitle: chap.summary.isNotEmpty
                            ? Text(
                                chap.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _changeChapter(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
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
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _shareOrOpenFile() async {
    final path = widget.book.filePath;
    if (path == null) return;

    try {
      File? fileToShare;
      final safeTitle =
          widget.book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final ext = path.contains('.') ? path.split('.').last : 'pdf';
      final targetFileName = '$safeTitle.$ext';

      if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$targetFileName');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
        fileToShare = tempFile;
      } else {
        final file = File(path);
        if (await file.exists()) {
          fileToShare = file;
        }
      }

      if (fileToShare != null && await fileToShare.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(fileToShare.path, name: targetFileName)],
            text: '${widget.book.title} — تطبيق تَدْبِير',
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.fileNotFound),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.fileShareError(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
        title: Column(
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.book.isPdf && _totalPdfPages > 0)
              Text(
                l10n.pageOfTotal(_currentPdfPage + 1, _totalPdfPages),
                style: TextStyle(
                  fontSize: 11,
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
                  fontSize: 11,
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
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareOrOpenFile,
            ),
          if (widget.book.chapters.length > 1)
            IconButton(
              tooltip: l10n.tableOfContents,
              icon: const Icon(Icons.list_alt_rounded),
              onPressed: _showChapterListSheet,
            ),
          if (widget.book.chapters.isNotEmpty || _loadedFileContent != null)
            IconButton(
              tooltip: l10n.copyContent,
              icon: const Icon(Icons.copy_rounded),
              onPressed: _copyChapterContent,
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(isDark, primaryColor),
      ),
    ),
  );
}

  Widget _buildBody(bool isDark, Color primaryColor) {
    // 1. إذا كان الكتاب مبنياً على فصول ومباحث نصية (استعراض القراءة المباشرة)
    if (widget.book.chapters.isNotEmpty) {
      return _buildChaptersView(isDark, primaryColor);
    }

    // 2. إذا كان الكتاب ملف PDF مرفق (للمطالعة والمشاركة الخارجية)
    if (widget.book.isPdf) {
      return _buildPdfView(isDark, primaryColor);
    }

    // 3. إذا كان الكتاب ملفاً نصياً يجري تحميله
    if (widget.book.hasAttachedFile && widget.book.isText) {
      if (_isLoadingFile) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_fileLoadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _fileLoadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
      return _buildScrollableTextView(
        content: _loadedFileContent ?? context.l10n.noTextContent,
        isDark: isDark,
        primaryColor: primaryColor,
      );
    }

    // 4. لا يوجد محتوى
    return _buildEmptyContentView(isDark);
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
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 15),
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
                  Icons.error_outline_rounded,
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
                  icon: const Icon(Icons.refresh_rounded),
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
                  setState(() {
                    _currentPdfPage = page ?? 0;
                    _totalPdfPages = total ?? 0;
                  });
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white)
                          .withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      context.l10n.pageOfTotal(_currentPdfPage + 1, _totalPdfPages),
                      style: TextStyle(
                        fontFamily: 'Amiri',
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

    // Fallback for non-mobile platforms (Desktop / Web / Test environment)
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  size: 46,
                ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.olive)
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
                  backgroundColor:
                      isDark ? AppColors.darkAccentGold : AppColors.oliveDark,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  context.l10n.openAndReadPdf,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _shareOrOpenFile,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.share_rounded),
                label: Text(context.l10n.shareFile),
                onPressed: _shareOrOpenFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChaptersView(bool isDark, Color primaryColor) {
    final chapter = widget.book.chapters[_currentChapterIndex];
    final totalChapters = widget.book.chapters.length;

    return Column(
      children: [
        // شريط التقدم بين الفصول والتحكم في حجم الخط
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.olive)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.sectionOfTotal(_currentChapterIndex + 1, totalChapters),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.l10n.decreaseFontSize,
                icon: const Icon(Icons.text_decrease_rounded, size: 20),
                onPressed: _fontSize > 14
                    ? () => setState(() => _fontSize -= 1.5)
                    : null,
              ),
              Text(
                '${_fontSize.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                tooltip: context.l10n.increaseFontSize,
                icon: const Icon(Icons.text_increase_rounded, size: 20),
                onPressed: _fontSize < 28
                    ? () => setState(() => _fontSize += 1.5)
                    : null,
              ),
            ],
          ),
        ),

        // المحتوى النصي للمبحث
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      chapter.title,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: _fontSize + 4,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightPrimaryDark,
                      ),
                    ),
                    if (chapter.summary.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.comsilk,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          chapter.summary,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SelectableText(
                      chapter.content,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: _fontSize,
                        height: 1.85,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // أزرار التنقل بين المباحث / الأدعية
                    Row(
                      children: [
                        if (_currentChapterIndex > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                context.currentLanguage.direction == TextDirection.rtl
                                    ? Icons.chevron_right_rounded
                                    : Icons.chevron_left_rounded,
                                size: 18,
                              ),
                              label: Text(
                                widget.book.id == 'sahifah_sajjadiyah'
                                    ? context.l10n.previousDua
                                    : context.l10n.previousSection,
                              ),
                              onPressed: () =>
                                  _changeChapter(_currentChapterIndex - 1),
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 12),
                        if (_currentChapterIndex < totalChapters - 1)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.oliveDark,
                              ),
                              icon: Icon(
                                context.currentLanguage.direction == TextDirection.rtl
                                    ? Icons.chevron_left_rounded
                                    : Icons.chevron_right_rounded,
                                size: 18,
                              ),
                              label: Text(
                                widget.book.id == 'sahifah_sajjadiyah'
                                    ? context.l10n.nextDua
                                    : context.l10n.nextSection,
                              ),
                              onPressed: () =>
                                  _changeChapter(_currentChapterIndex + 1),
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableTextView({
    required String content,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Column(
      children: [
        // شريط حجم الخط
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.book.fileName ?? context.l10n.textFile,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.l10n.decreaseFontSize,
                icon: const Icon(Icons.text_decrease_rounded, size: 20),
                onPressed: _fontSize > 14
                    ? () => setState(() => _fontSize -= 1.5)
                    : null,
              ),
              Text(
                '${_fontSize.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                tooltip: context.l10n.increaseFontSize,
                icon: const Icon(Icons.text_increase_rounded, size: 20),
                onPressed: _fontSize < 28
                    ? () => setState(() => _fontSize += 1.5)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SelectableText(
                  content,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: _fontSize,
                    height: 1.85,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
              Icons.menu_book_rounded,
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

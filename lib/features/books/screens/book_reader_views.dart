part of 'book_reader_screen.dart';

/// عروض القارئ: الفصول والنص وقائمة الفصول.
extension _BookReaderViews on _BookReaderScreenState {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          AppIcons.listBullets,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.bookIndexPrefix(widget.book.title),
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
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
                              textDirection: directionOfText(chap.title),
                              style: TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
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
                                    textDirection: directionOfText(
                                      chap.summary,
                                    ),
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

  Future<void> _shareOrOpenFile() async {
    final path = widget.book.filePath;
    if (path == null) return;

    try {
      File? fileToShare;
      final safeTitle = widget.book.title.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final ext = path.contains('.') ? path.split('.').last : 'pdf';
      final targetFileName = '$safeTitle.$ext';

      if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$targetFileName');
        await tempFile.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
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

  Widget _buildBody(bool isDark, Color primaryColor) {
    // ١. فصول مكتوبة: تُقرأ مباشرة.
    if (widget.book.chapters.isNotEmpty) {
      return _buildChaptersView(isDark, primaryColor);
    }

    // ٢. ملف PDF مرفق.
    if (widget.book.isPdf) {
      return _buildPdfView(isDark, primaryColor);
    }

    // ٣. ملف نصي يُحمّل.
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

    // ٤. لا محتوى.
    return _buildEmptyContentView(isDark);
  }

  Widget _buildChaptersView(bool isDark, Color primaryColor) {
    final chapter = widget.book.chapters[_currentChapterIndex];
    final totalChapters = widget.book.chapters.length;

    return Column(
      children: [
        // التقدم بين الفصول وحجم الخط.
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccentGold : AppColors.olive)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.sectionOfTotal(
                    _currentChapterIndex + 1,
                    totalChapters,
                  ),
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
              ..._fontSizeControls(),
            ],
          ),
        ),

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
                      textDirection: directionOfText(chapter.title),
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
                          textDirection: directionOfText(chapter.summary),
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
                    // لغة الكتاب تحدد الاتجاه، لا لغة الواجهة.
                    SelectableText(
                      chapter.content,
                      textDirection: directionOfText(chapter.content),
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
                    // التنقل بين المباحث أو الأدعية.
                    Row(
                      children: [
                        if (_currentChapterIndex > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(AppIcons.caretLeft, size: 18),
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
                              icon: Icon(AppIcons.caretRight, size: 18),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ..._fontSizeControls(),
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
                  textDirection: directionOfText(content),
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
}

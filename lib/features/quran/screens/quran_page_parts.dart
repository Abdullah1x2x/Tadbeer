part of 'quran_page_view.dart';

/// أجزاء صفحة المصحف: الرأس والتذييل ونص الآيات.
extension _QuranPageParts on _QuranPageViewState {
  /// صفحة مصحف المدينة: الترويسة والأسطر المطبوعة والتذييل.
  Widget _buildQcfPage(
    BuildContext context, {
    required int pageNumber,
    required Surah surah,
    required int juzNumber,
    required List<MarginStampData> marginStamps,
    required bool isDark,
    required MushafPalette palette,
    required UserDataStore storage,
    required double fontSize,
    required Widget fallback,
  }) {
    final memorized = HifzStore.all().keys.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          _buildPageHeader(
            context,
            surah: surah,
            juzNumber: juzNumber,
            isDark: isDark,
            palette: palette,
            marginStamps: marginStamps,
          )
        else
          const SizedBox(height: 4),
        const SizedBox(height: 4),
        Expanded(
          child: QcfPageBody(
            pageNumber: pageNumber,
            // الصفحة المطبوعة تتسع للشاشة وحدها؛ ولا يكبّرها إلا حجم صريح (في
            // الاختبارات).
            zoom: widget.fontSize == null
                ? 1
                : fontSize / UserSettings.defaultQuranFontSize,
            textColor: palette.text,
            markerColor: isDark
                ? AppColors.darkAccentGold
                : AppColors.lightAccentGold,
            backgroundFor: (s, a) {
              final selected = widget.selectedAyah;
              if (selected != null &&
                  selected.surahNumber == s &&
                  selected.ayahNumber == a) {
                return isDark
                    ? AppColors.darkSelectedAyah
                    : const Color(0x36B89745);
              }
              final highlight = storage.getHighlight(s, a);
              if (highlight == null) return null;
              final base = AppColors.highlightColors[highlight.colorIndex];
              return base.withValues(alpha: isDark ? 0.35 : 0.25);
            },
            isMarked: (s, a) {
              final reflection = storage.getTadbeer(s, a);
              return storage.isBookmarked(s, a) ||
                  storage.getNotesForAyah(s, a).isNotEmpty ||
                  (reflection != null && !reflection.isEmpty) ||
                  memorized.contains('$s:$a');
            },
            recognizerFor: _getOrCreateRecognizer,
            fallback: fallback,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.showFooter)
          _buildPageFooter(
            context,
            pageNumber: pageNumber,
            isDark: isDark,
            palette: palette,
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  /// الترويسة: اسم السورة ورقم الجزء وعلامات الهامش إن وُجدت.
  Widget _buildPageHeader(
    BuildContext context, {
    required Surah surah,
    required int juzNumber,
    required bool isDark,
    required MushafPalette palette,
    List<MarginStampData> marginStamps = const [],
  }) {
    final frameColor = palette.frame;
    final headerColor = isDark ? AppColors.darkTextPrimary : palette.frame;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: frameColor.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 0.75,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '❖ ',
                  style: TextStyle(
                    fontSize: 7.5,
                    color: frameColor.withValues(alpha: 0.8),
                  ),
                ),
                Flexible(
                  child: Text(
                    'سُورَةُ ${surah.name}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (marginStamps.isNotEmpty) ...[
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: marginStamps
                  .map(
                    (stamp) => MarginStampMedallion(
                      stamp: stamp,
                      isDark: isDark,
                      palette: palette,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 4),
          ] else
            const SizedBox(width: 4),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'الجزء ${ArabicSearchNormalizer.toArabicDigits(juzNumber)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  ' ❖',
                  style: TextStyle(
                    fontSize: 7.5,
                    color: frameColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// التذييل: رقم الصفحة بالأرقام العربية.
  Widget _buildPageFooter(
    BuildContext context, {
    required int pageNumber,
    required bool isDark,
    required MushafPalette palette,
  }) {
    final frameColor = palette.frame;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: frameColor.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 0.75,
          ),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: frameColor.withValues(alpha: isDark ? 0.45 : 0.55),
              width: 0.7,
            ),
            color:
                (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface)
                    .withValues(alpha: 0.35),
          ),
          child: Text(
            ArabicSearchNormalizer.toArabicDigits(pageNumber),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightPrimary,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  /// الصفحتان الافتتاحيتان (الفاتحة وأول البقرة) متمركزتين داخل إطار المصحف.
  Widget _buildOpeningPageContent({
    required BuildContext context,
    required List<_SurahPageBlock> blocks,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final block in blocks) ...[
            if (block.isStartOfSurah) ...[
              SurahHeaderBanner(
                surah: QuranRepository.instance.getSurah(block.surahNumber),
              ),
              const SizedBox(height: 4),
              if (block.surahNumber != 1 && block.surahNumber != 9) ...[
                const BismillahBanner(),
                const SizedBox(height: 6),
              ],
            ],
            _buildAyahsParagraph(
              context: context,
              ayahs: block.ayahs,
              fontSize: fontSize,
              isDark: isDark,
              storage: storage,
              isCentered: true,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// الصفحات العادية: ترويسات السور والبسملة والآيات المتصلة.
  Widget _buildStandardPageContent({
    required BuildContext context,
    required List<_SurahPageBlock> blocks,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks) ...[
          if (block.isStartOfSurah) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SurahHeaderBanner(
                surah: QuranRepository.instance.getSurah(block.surahNumber),
              ),
            ),
            if (block.surahNumber != 1 && block.surahNumber != 9) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: BismillahBanner(),
              ),
            ],
          ],
          _buildAyahsParagraph(
            context: context,
            ayahs: block.ayahs,
            fontSize: fontSize,
            isDark: isDark,
            storage: storage,
            isCentered: false,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// فقرة الآيات المتصلة: أرقامها وتظليلها وشارات الفواصل والخواطر.
  Widget _buildAyahsParagraph({
    required BuildContext context,
    required List<Ayah> ayahs,
    required double fontSize,
    required bool isDark,
    required UserDataStore storage,
    required bool isCentered,
  }) {
    final textColor = MushafPalette.of(
      isDark: isDark,
      tone: storage.settings.mushafPaperTone,
    ).text;
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final fontFamily = storage.settings.quranFontFamilyName;

    final spanChildren = <InlineSpan>[];
    // تُقرأ مرة للصفحة، وتُفحص لكل آية أدناه.
    final memorized = HifzStore.all().keys.toSet();

    for (final ayah in ayahs) {
      final isSelected = widget.selectedAyah?.id == ayah.id;
      final highlight = storage.getHighlight(ayah.surahNumber, ayah.ayahNumber);
      final isBookmarked = storage.isBookmarked(
        ayah.surahNumber,
        ayah.ayahNumber,
      );
      final hasNote = storage
          .getNotesForAyah(ayah.surahNumber, ayah.ayahNumber)
          .isNotEmpty;
      final reflection = storage.getTadbeer(ayah.surahNumber, ayah.ayahNumber);
      final hasReflection = reflection != null && !reflection.isEmpty;
      final inHifz = memorized.contains(
        '${ayah.surahNumber}:${ayah.ayahNumber}',
      );
      final markerColor = isDark
          ? AppColors.darkAccentGold
          : AppColors.lightAccentGold;
      final markers = <(IconData, Color)>[
        if (isBookmarked)
          (
            AppIcons.bookmarkSimpleFill,
            isDark ? AppColors.darkAccentGold : AppColors.lightPrimary,
          ),
        if (hasNote) (AppIcons.notePencil, markerColor),
        if (hasReflection) (AppIcons.flowerLotusFill, markerColor),
        if (inHifz) (AppIcons.brainFill, AppColors.statusSuccess),
      ];
      final hasIndicators = markers.isNotEmpty;

      final ayahText = _QuranPageViewState._formatAyahText(ayah.text);
      final rosetteText =
          '\u00A0﴿${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}﴾';
      const trailingSpace = ' ';

      Color? highlightColor;
      if (isSelected) {
        highlightColor = isDark
            ? AppColors.darkSelectedAyah
            : const Color(0x36B89745);
      } else if (highlight != null) {
        final baseColor = AppColors.highlightColors[highlight.colorIndex];
        highlightColor = isDark
            ? baseColor.withValues(alpha: 0.35)
            : baseColor.withValues(alpha: 0.25);
      }

      final recognizer = _getOrCreateRecognizer(ayah);

      spanChildren.add(
        TextSpan(
          text: ayahText,
          recognizer: recognizer,
          style: TextStyle(color: textColor, backgroundColor: highlightColor),
        ),
      );
      spanChildren.add(
        TextSpan(
          text: rosetteText,
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            height: 1.95,
            backgroundColor: highlightColor,
            color: isSelected
                ? (isDark ? const Color(0xFFDFCA94) : const Color(0xFF7A5C1E))
                : goldColor,
          ),
        ),
      );

      if (hasIndicators) {
        final iconSize = (fontSize * 0.62).clamp(13.0, 20.0);
        final iconCount = markers.length;
        final badgeWidth =
            4.0 + 12.0 + (iconCount * iconSize) + (iconCount > 1 ? 4.0 : 0.0);
        final badgeHeight = (iconSize + 6.0).clamp(18.0, 26.0);

        spanChildren.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: badgeWidth,
              height: badgeHeight,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onAyahLongPress != null) {
                      widget.onAyahLongPress!(ayah);
                    } else {
                      AyahRosette.show(context, ayah);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccentGold.withValues(alpha: 0.16)
                          : AppColors.lightPrimary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            (isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.lightAccentGold)
                                .withValues(alpha: isDark ? 0.45 : 0.55),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < markers.length; i++) ...[
                              if (i > 0) const SizedBox(width: 3.0),
                              Icon(
                                markers[i].$1,
                                size: iconSize,
                                color: markers[i].$2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      spanChildren.add(const TextSpan(text: trailingSpace));
    }

    final rootSpan = TextSpan(
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.95,
        color: textColor,
      ),
      children: spanChildren,
    );

    return Text.rich(
      rootSpan,
      textAlign: isCentered ? TextAlign.center : TextAlign.justify,
      textDirection: TextDirection.rtl,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }
}

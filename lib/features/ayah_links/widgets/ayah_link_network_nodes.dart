part of 'ayah_link_network_view.dart';

/// رسام خطوط الشبكة لربط العقدة المركزية بالعقد الفرعية بمنحنيات بيزييه ناعمة.
class _NetworkConnectionsPainter extends CustomPainter {
  final Offset center;
  final Map<String, Offset> positions;
  final bool isDark;

  /// ينشئ رسام خطوط الشبكة.
  const _NetworkConnectionsPainter({
    required this.center,
    required this.positions,
    required this.isDark,
  });

  /// يرسم المسارات المنحنية ونقاط الارتباط على لوحة الشبكة.
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (isDark ? AppColors.oliveSoft : AppColors.olive).withValues(
        alpha: 0.45,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final dotPaint = Paint()
      ..color = (isDark ? AppColors.oliveSoft : AppColors.olive).withValues(
        alpha: 0.8,
      )
      ..style = PaintingStyle.fill;

    for (final pos in positions.values) {
      // Subtle smooth curve toward center
      final path = Path();
      path.moveTo(center.dx, center.dy);

      final controlX = (center.dx + pos.dx) / 2;
      final controlY = (center.dy + pos.dy) / 2;

      path.quadraticBezierTo(controlX, controlY, pos.dx, pos.dy);
      canvas.drawPath(path, linePaint);

      // Decorative mini junction dot
      canvas.drawCircle(pos, 3.5, dotPaint);
    }
  }

  /// يحدد ما إذا كان يجب إعادة رسم الخطوط عند تغير المواضع أو السمة.
  @override
  bool shouldRepaint(covariant _NetworkConnectionsPainter oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.isDark != isDark;
  }
}

/// العقدة المركزية التي تمثل عنوان ومحور رابط الآيات.
///
/// Central Node representing the overall Ayah Link theme/title.
class _CenterThemeNode extends StatelessWidget {
  final String title;
  final String? description;
  final int versesCount;
  final bool isDark;

  /// ينشئ العقدة المركزية لرابط الآيات.
  const _CenterThemeNode({
    required this.title,
    this.description,
    required this.versesCount,
    required this.isDark,
  });

  /// يبني بطاقة العقدة المركزية مع عنوان الرابط وعدد الآيات المرتبطة.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.graphFill,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              context.l10n.isArabic
                  ? '${ArabicSearchNormalizer.convertDigits('$versesCount')} آيات مرتبطة'
                  : '$versesCount linked verses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  height: 1.45,
                  color: isDark
                      ? AppColors.nightSubtitle
                      : AppColors.daySubtitle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// عقدة آية تفاعلية قابلة للسحب والضغط داخل لوحة الشبكة.
///
/// Interactive Verse Node on the Canvas with draggable gestures.
class _VerseCanvasNode extends StatelessWidget {
  final AyahLinkVerse verse;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  /// ينشئ عقدة آية تفاعلية على لوحة الشبكة.
  const _VerseCanvasNode({
    required this.verse,
    required this.isDark,
    required this.onTap,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  /// يبني بطاقة عقدة الآية مع مقتطف النص وملاحظة التدبر.
  @override
  Widget build(BuildContext context) {
    final surah = QuranRepository.instance.getSurah(verse.surahNumber);
    final ayah = QuranRepository.instance.getAyah(
      verse.surahNumber,
      verse.ayahNumber,
    );
    final effectiveNote = verse.getEffectiveNote();
    final hasNote = effectiveNote != null && effectiveNote.isNotEmpty;
    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final nodeWidth = (fontSize * 11.5).clamp(195.0, 280.0);

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onPanUpdate(details.delta),
      onPanEnd: (_) => onPanEnd(),
      child: Container(
        width: nodeWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasNote
                ? AppColors.olive
                : (isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder),
            width: hasNote ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Node Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.isArabic
                        ? '${surah.name} · ${ArabicSearchNormalizer.toArabicDigits(verse.ayahNumber)}'
                        : '${surah.name} · ${verse.ayahNumber}',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.olive,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasNote)
                  Icon(AppIcons.note, size: 14, color: AppColors.olive),
              ],
            ),
            const SizedBox(height: 6),

            // Full verse text
            if (ayah != null)
              Text(
                '﴿ ${ayah.text} ﴾',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: fontSize * 0.78,
                  height: 1.6,
                  color: isDark
                      ? AppColors.nightQuranText
                      : AppColors.dayQuranText,
                ),
              ),

            // Note snippet under verse (if present, compact otherwise)
            if (hasNote) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.border(context)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    AppIcons.notePencil,
                    size: 13,
                    color: isDark ? AppColors.oliveSoft : AppColors.olive,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.isArabic ? 'ملاحظتي' : 'My note',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.oliveSoft : AppColors.olive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                effectiveNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark
                      ? AppColors.nightSubtitle
                      : AppColors.daySubtitle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// عقدة كرت ملاحظة تفاعلية قابلة للسحب والضغط داخل لوحة الشبكة.
class _NoteCanvasNode extends StatelessWidget {
  final AyahLinkNote note;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  /// ينشئ عقدة كرت ملاحظة تفاعلية على لوحة الشبكة.
  const _NoteCanvasNode({
    required this.note,
    required this.isDark,
    required this.onTap,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  /// يبني واجهة عقدة كرت الملاحظة على لوحة الشبكة.
  @override
  Widget build(BuildContext context) {
    final fontSize = UserDataStore.instance.settings.ayahLinkFontSize;
    final nodeWidth = (fontSize * 11.5).clamp(195.0, 280.0);
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onPanUpdate(details.delta),
      onPanEnd: (_) => onPanEnd(),
      child: Container(
        width: nodeWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Node Header
            Row(
              children: [
                Icon(
                  AppIcons.noteFill,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasTitle
                        ? note.title!.trim()
                        : (context.l10n.isArabic
                              ? 'كرت ملاحظة تدبرية'
                              : 'Reflection Note'),
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: AppColors.border(context)),
            const SizedBox(height: 6),

            // Note Content
            Text(
              note.content,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? AppColors.nightSubtitle : AppColors.daySubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

part of 'quran_screen.dart';

/// حوارا الانتقال إلى صفحة وحجم الخط.
extension _QuranScreenDialogs on _QuranScreenState {
  /// حوار الانتقال إلى صفحة برقمها.
  void _showJumpToPageDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => _JumpToPageDialog(
        initialPage: _currentPageIndex + 1,
        onPageSelected: (page) => _jumpToMushafPage(page),
      ),
    );
  }

  /// لوحة طريقة عرض المصحف وخطه، مع معاينة.
  void _showFontSizeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (ctx, _) {
            final settings = UserDataStore.instance.settings;
            final currentFamily = settings.quranFontFamily;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<MushafStyle>(
                      segments: [
                        ButtonSegment(
                          value: MushafStyle.madinah,
                          label: Text(context.l10n.mushafStyleMadinah),
                        ),
                        ButtonSegment(
                          value: MushafStyle.text,
                          label: Text(context.l10n.mushafStyleText),
                        ),
                      ],
                      selected: {settings.mushafStyle},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) =>
                          UserDataStore.instance.setMushafStyle(v.first),
                    ),
                    const SizedBox(height: 16),
                    // اختيار الخط يخص النص المتدفق وحده.
                    if (settings.mushafStyle == MushafStyle.text) ...[
                      Text(
                        context.l10n.quranFontFamily,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final fontOpt in QuranFontFamilyOption.values)
                            ChoiceChip(
                              label: Text(
                                fontOpt.labelArabic,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: currentFamily == fontOpt
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: currentFamily == fontOpt,
                              onSelected: (_) {
                                UserDataStore.instance.setQuranFontFamily(
                                  fontOpt,
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const TextScaleControl(),
                      const SizedBox(height: 12),
                      // الخط والحجم المختاران، على البسملة.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: MushafPalette.of(
                            isDark: isDark,
                            tone: settings.mushafPaperTone,
                          ).outer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: settings.quranFontFamilyName,
                            fontSize: 20 * settings.flowingTextScale,
                            color: MushafPalette.of(
                              isDark: isDark,
                              tone: settings.mushafPaperTone,
                            ).text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(context.l10n.doneLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// حوار إدخال رقم الصفحة مع إدارة دورة حياة المتحكم النصي بأمان.
class _JumpToPageDialog extends StatefulWidget {
  final int initialPage;
  final ValueChanged<int> onPageSelected;

  const _JumpToPageDialog({
    required this.initialPage,
    required this.onPageSelected,
  });

  @override
  State<_JumpToPageDialog> createState() => _JumpToPageDialogState();
}

class _JumpToPageDialogState extends State<_JumpToPageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialPage}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.comsilkLight,
      title: Text(
        l10n.jumpToPage,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.enterPageRange,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.nightSubtitle : AppColors.oliveDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '1 - 604',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final raw = ArabicSearchNormalizer.toEnglishDigits(
              _controller.text.trim(),
            );
            final val = int.tryParse(raw);
            if (val != null && val >= 1 && val <= 604) {
              Navigator.pop(context);
              widget.onPageSelected(val);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.olive,
            foregroundColor: Colors.white,
          ),
          child: Text(
            l10n.go,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}


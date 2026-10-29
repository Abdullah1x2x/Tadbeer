import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../data/ahlulbayt_duas_repository.dart';
import '../../../core/design_system/app_icons.dart';

/// قراءة دعاء مأثور، مع ضبط حجم الخط ونسخ النص.
class AhlulbaytDuaReaderScreen extends StatefulWidget {
  final AhlulbaytDua dua;

  const AhlulbaytDuaReaderScreen({super.key, required this.dua});

  @override
  State<AhlulbaytDuaReaderScreen> createState() =>
      _AhlulbaytDuaReaderScreenState();
}

class _AhlulbaytDuaReaderScreenState extends State<AhlulbaytDuaReaderScreen> {
  double _fontSize = 19.0;

  void _increaseFontSize() {
    if (_fontSize < 28.0) {
      setState(() => _fontSize += 1.5);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > 15.0) {
      setState(() => _fontSize -= 1.5);
    }
  }

  void _copyAllText() {
    Clipboard.setData(
      ClipboardData(
        text:
            '${widget.dua.title}\n(${widget.dua.attributedTo})\n\n${widget.dua.fullText}\n\n— تطبيق تَدْبِير',
      ),
    );
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.fullDuaCopiedSuccess,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            widget.dua.title,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: l10n.decreaseFontSize,
              icon: const Icon(AppIcons.minus, size: 20),
              onPressed: _decreaseFontSize,
            ),
            IconButton(
              tooltip: l10n.increaseFontSize,
              icon: const Icon(AppIcons.plus, size: 20),
              onPressed: _increaseFontSize,
            ),
            IconButton(
              tooltip: l10n.copyFullDua,
              icon: const Icon(AppIcons.copy, size: 20),
              onPressed: _copyAllText,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // تفاصيل الدعاء ومناسبته.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.darkAccentGold
                                        : AppColors.olive)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.dua.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkAccentGold
                                  : AppColors.oliveDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.dua.attributedTo,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.dua.summary,
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // النص كاملاً متصلاً.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SelectableText(
                  widget.dua.fullText,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.85,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _copyAllText,
                icon: const Icon(AppIcons.copy, size: 18),
                label: Text(
                  l10n.copyFullDua,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

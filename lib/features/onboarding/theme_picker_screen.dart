import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/ornaments.dart';
import '../../data/storage/user_data_store.dart';

/// اختيار مظهر التطبيق عند أول فتح: فاتح أو داكن أو تلقائي، وأحد الثيمات
/// الخمسة.
///
/// كل اختيار يُطبّق فوراً على التطبيق كله وهذه الشاشة معه، فيرى القارئ النتيجة
/// الحقيقية قبل أن يبدأ.
class ThemePickerScreen extends StatelessWidget {
  /// الشاشة التي تُفتح عند البدء.
  final WidgetBuilder next;

  const ThemePickerScreen({super.key, required this.next});

  Future<void> _start(BuildContext context) async {
    unawaited(HapticFeedback.mediumImpact());
    final navigator = Navigator.of(context);
    final store = UserDataStore.instance;
    await store.updateSettings(store.settings.copyWith(themeChosen: true));
    navigator.pushReplacement(MaterialPageRoute(builder: next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) {
        final settings = UserDataStore.instance.settings;
        final store = UserDataStore.instance;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: context.currentLanguage.direction,
          child: Scaffold(
            body: PatternBackground(
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                      children: [
                        Text(
                          l10n.themePickerTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: OrnamentDivider(width: 120, starSize: 5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.themePickerHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: const Icon(AppIcons.sun, size: 18),
                              label: Text(l10n.light),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: const Icon(AppIcons.moon, size: 18),
                              label: Text(l10n.dark),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: const Icon(AppIcons.circleHalf, size: 18),
                              label: Text(l10n.themeAuto),
                            ),
                          ],
                          selected: {settings.themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (v) {
                            HapticFeedback.selectionClick();
                            store.updateSettings(
                              settings.copyWith(themeMode: v.first),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        for (final theme in AppColorTheme.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ThemeCard(
                              theme: theme,
                              name: l10n.colorThemeName(theme.index),
                              selected: settings.colorTheme == theme,
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                store.updateSettings(
                                  settings.copyWith(colorTheme: theme),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _start(context),
                          // يشير إلى الأمام: لليسار في العربية، ولليمين في
                          // الإنجليزية.
                          icon: const Icon(AppIcons.arrowRight),
                          label: Text(l10n.themePickerStart),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// الثيم في صورة تطبيق مصغّر: لون صفحته، وبطاقة بتدرجه وخطوط ذهبية، وزر ذهبي.
class _ThemeCard extends StatelessWidget {
  final AppColorTheme theme;
  final String name;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.name,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ThemePalette.of(theme);
    final gold = isDark ? p.darkAccentGold : p.lightAccentGold;
    final page = isDark ? p.darkBackground : p.lightBackground;
    final hero = isDark
        ? [p.heroDarkStart, p.heroDarkEnd]
        : [p.heroLightStart, p.heroLightEnd];
    final text = isDark ? Colors.white : p.lightTextPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: page,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? gold : gold.withValues(alpha: 0.25),
              width: selected ? 2.2 : 1,
            ),
          ),
          child: Row(
            children: [
              // البطاقة المصغّرة.
              Container(
                width: 92,
                height: 58,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hero,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Line(color: gold, width: 34),
                    _Line(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 60,
                    ),
                    _Line(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 46,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
              ),
              // الزر الذهبي المصغّر، وعليه علامة حين يُختار.
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? gold : Colors.transparent,
                  border: Border.all(color: gold, width: 1.6),
                ),
                child: selected
                    ? Icon(AppIcons.check, size: 18, color: page)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final Color color;
  final double width;

  const _Line({required this.color, required this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 5,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

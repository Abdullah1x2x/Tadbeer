import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../backup/backup_screen.dart';
import '../reminders/reminders_screen.dart';
import 'user_settings_model.dart';
import '../../core/design_system/app_icons.dart';
import '../quran/qcf/madinah_preview.dart';

/// شاشة الإعدادات لإدارة المظهر ونوع وحجم خط المصحف واللغة وإعادة تعيين البيانات.
///
/// Settings screen for managing appearance, Quran font scale, language, and data reset.
class SettingsScreen extends StatelessWidget {
  /// ينشئ شاشة الإعدادات.
  const SettingsScreen({super.key});

  /// يبني واجهة شاشة الإعدادات مقسمة إلى بطاقات منظمة.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.currentLanguage == AppLanguage.arabic;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.settings,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final settings = UserDataStore.instance.settings;
            final madinah = settings.mushafStyle == MushafStyle.madinah;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. المظهر (Appearance)
                _buildSectionHeader(context, l10n.appearance),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppIcons.palette,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.themeMode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: isDark ? 0.22 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _getActiveThemeLabel(
                                  settings.themeMode,
                                  isDark,
                                  context.currentLanguage == AppLanguage.arabic,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildThemeOptionButton(
                                context: context,
                                isSelected:
                                    settings.themeMode == ThemeMode.light,
                                label: l10n.light,
                                icon: AppIcons.sun,
                                isDark: isDark,
                                onSelect: () {
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(
                                      themeMode: ThemeMode.light,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOptionButton(
                                context: context,
                                isSelected:
                                    settings.themeMode == ThemeMode.dark,
                                label: l10n.dark,
                                icon: AppIcons.moon,
                                isDark: isDark,
                                onSelect: () {
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(
                                      themeMode: ThemeMode.dark,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOptionButton(
                                context: context,
                                isSelected:
                                    settings.themeMode == ThemeMode.system,
                                label:
                                    context.currentLanguage ==
                                        AppLanguage.arabic
                                    ? 'تلقائي'
                                    : 'System',
                                icon: AppIcons.circleHalf,
                                isDark: isDark,
                                onSelect: () {
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(
                                      themeMode: ThemeMode.system,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Color theme: one swatch per palette.
                        Text(
                          l10n.appColorTheme,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            for (final t in AppColorTheme.values)
                              _ColorThemeSwatch(
                                theme: t,
                                label: l10n.colorThemeName(t.index),
                                selected: settings.colorTheme == t,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(colorTheme: t),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppIcons.eye,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getThemeExplanation(
                                  settings.themeMode,
                                  isDark,
                                  context.currentLanguage == AppLanguage.arabic,
                                ),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.nightSubtitle
                                      : AppColors.daySubtitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 2. الخط والقراءة (Typography & Reading)
                _buildSectionHeader(context, l10n.typographyAndReading),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Madinah pages first; flowing text is the
                        // alternative that needs no download.
                        Row(
                          children: [
                            Icon(
                              AppIcons.bookOpenText,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.mushafStyleTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<MushafStyle>(
                          segments: [
                            ButtonSegment(
                              value: MushafStyle.madinah,
                              label: Text(l10n.mushafStyleMadinah),
                            ),
                            ButtonSegment(
                              value: MushafStyle.text,
                              label: Text(l10n.mushafStyleText),
                            ),
                          ],
                          selected: {settings.mushafStyle},
                          showSelectedIcon: false,
                          onSelectionChanged: (v) =>
                              UserDataStore.instance.setMushafStyle(v.first),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          madinah
                              ? l10n.mushafStyleMadinahHint
                              : l10n.mushafStyleTextHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        if (madinah) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.qcfAttribution,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                        const Divider(height: 28),
                        // The font choice only applies to the flowing text.
                        if (!madinah) ...[
                          Row(
                            children: [
                              Icon(
                                AppIcons.textT,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.quranFontFamily,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // A compact dropdown replaces the five large cards;
                          // the live preview below shows the chosen font.
                          DropdownButtonFormField<QuranFontFamilyOption>(
                            // Re-created when the setting changes elsewhere
                            // (e.g. after restoring a backup).
                            key: ValueKey(settings.quranFontFamily),
                            initialValue: settings.quranFontFamily,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(16),
                            items: [
                              for (final fontOpt
                                  in QuranFontFamilyOption.values)
                                DropdownMenuItem(
                                  value: fontOpt,
                                  child: Text(
                                    fontOpt.getLabel(
                                      context.currentLanguage ==
                                          AppLanguage.arabic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (fontOpt) {
                              if (fontOpt == null) return;
                              HapticFeedback.selectionClick();
                              UserDataStore.instance.setQuranFontFamily(
                                fontOpt,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 6),
                            child: Text(
                              settings.quranFontFamily.getSubtitle(
                                context.currentLanguage == AppLanguage.arabic,
                              ),
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.textAa,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  madinah ? l10n.pageSize : l10n.fontSize,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              // Madinah pages zoom: 100% fits the screen.
                              madinah
                                  ? l10n.percent(
                                      (settings.quranFontSize /
                                              UserSettings
                                                  .defaultQuranFontSize *
                                              100)
                                          .round(),
                                    )
                                  : l10n.fontSizePoints(
                                      context.currentLanguage ==
                                              AppLanguage.arabic
                                          ? ArabicSearchNormalizer.toArabicDigits(
                                              settings.quranFontSize.round(),
                                            )
                                          : settings.quranFontSize.round(),
                                    ),
                              style: TextStyle(
                                fontFamily:
                                    context.currentLanguage ==
                                        AppLanguage.arabic
                                    ? 'IBMPlexSansArabic'
                                    : null,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: settings.quranFontSize,
                          min: UserSettings.minQuranFontSize,
                          max: UserSettings.maxQuranFontSize,
                          divisions: 24,
                          label: madinah
                              ? l10n.percent(
                                  (settings.quranFontSize /
                                          UserSettings.defaultQuranFontSize *
                                          100)
                                      .round(),
                                )
                              : '${settings.quranFontSize.round()}',
                          onChanged: (newSize) {
                            UserDataStore.instance.setQuranFontSize(newSize);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              AppIcons.bookOpenText,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.mushafPaperTone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final (index, tone, label, icon) in [
                              (
                                0,
                                MushafPaperTone.classic,
                                l10n.paperClassic,
                                AppIcons.fileText,
                              ),
                              (
                                1,
                                MushafPaperTone.sepia,
                                l10n.paperSepia,
                                AppIcons.coffee,
                              ),
                            ]) ...[
                              if (index > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _buildThemeOptionButton(
                                  context: context,
                                  isSelected: settings.mushafPaperTone == tone,
                                  label: label,
                                  icon: icon,
                                  isDark: isDark,
                                  onSelect: () {
                                    UserDataStore.instance.updateSettings(
                                      settings.copyWith(mushafPaperTone: tone),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
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
                          child: madinah
                              ? MadinahPreview(
                                  zoom:
                                      settings.quranFontSize /
                                      UserSettings.defaultQuranFontSize,
                                  color: MushafPalette.of(
                                    isDark: isDark,
                                    tone: settings.mushafPaperTone,
                                  ).text,
                                )
                              : Text(
                                  'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ\u00A0\u00A0ۛ فِيهِ\u00A0\u00A0ۛ هُدًى لِّلْمُتَّقِينَ ﴿٢﴾ أُو۟لَٰٓئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْ\u00A0\u00A0ۖ وَأُو۟لَٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ ﴿٥﴾',
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: settings.quranFontFamilyName,
                                    fontSize: settings.quranFontSize,
                                    height: 1.85,
                                    color: MushafPalette.of(
                                      isDark: isDark,
                                      tone: settings.mushafPaperTone,
                                    ).text,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TextButton.icon(
                                  onPressed:
                                      settings.quranFontSize ==
                                          UserSettings.defaultQuranFontSize
                                      ? null
                                      : () => UserDataStore.instance
                                            .setQuranFontSize(
                                              UserSettings.defaultQuranFontSize,
                                            ),
                                  icon: const Icon(
                                    AppIcons.arrowClockwise,
                                    size: 16,
                                  ),
                                  label: Text(
                                    l10n.resetToDefaultWithVal(
                                      madinah
                                          ? l10n.percent(100)
                                          : l10n.digits(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. التطبيق (Application)
                _buildSectionHeader(context, l10n.applicationSection),
                _buildCard(
                  context: context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          AppIcons.globe,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.languageTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          settings.languageCode == 'ar'
                              ? 'العربية (افتراضي)'
                              : 'English',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: settings.languageCode,
                          underline: const SizedBox(),
                          onChanged: (code) {
                            if (code != null) {
                              UserDataStore.instance.updateSettings(
                                settings.copyWith(languageCode: code),
                              );
                              AppLocalizationScope.of(
                                context,
                              ).onLanguageChanged(AppLanguage.fromCode(code));
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          AppIcons.alarmFill,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.reminders,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.dailyRemindersSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: Icon(AppIcons.caretRight, size: 20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RemindersScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. البيانات (Data)
                _buildSectionHeader(context, l10n.dataSection),
                _buildCard(
                  context: context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          AppIcons.shieldCheck,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.backup,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.backupSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: Icon(AppIcons.caretRight, size: 20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BackupScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          AppIcons.trash,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          l10n.resetData,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        subtitle: Text(
                          l10n.resetDataSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        onTap: () => _confirmResetData(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. حول (About)
                _buildSectionHeader(context, l10n.about),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppIcons.bookOpenFill,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.appName,
                                  style: TextStyle(
                                    fontFamily: isArabic ? 'Amiri' : null,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightPrimaryDark,
                                  ),
                                ),
                                Text(
                                  l10n.versionInfo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.nightSubtitle
                                        : AppColors.daySubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.aboutContent,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Text(
                          l10n.sourcesAndCredits,
                          style: TextStyle(
                            fontFamily: isArabic ? 'IBMPlexSansArabic' : null,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.sourcesAndCreditsDetails,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showPrivacyPolicyDialog(context),
                                icon: const Icon(AppIcons.shield, size: 17),
                                label: Text(
                                  l10n.privacyPolicy,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showLicensePage(
                                    context: context,
                                    applicationName: l10n.appName,
                                    applicationVersion: '1.0.0',
                                    applicationLegalese:
                                        'Copyright © 2026 Tadbeer Project Contributors (MIT License)\n'
                                        'Quran Text: Tanzil.net (CC BY 3.0)\n'
                                        'Word Meanings Dataset: Quranpedia.net (Version 2026-10-10)\n'
                                        'Fonts: SIL Open Font License 1.1\n'
                                        'Books & Malazem: Authentic Public Domain & Heritage Works',
                                  );
                                },
                                icon: const Icon(AppIcons.fileText, size: 17),
                                label: Text(
                                  l10n.openSourceLicenses,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// يعرض نافذة تأكيد لإعادة تعيين جميع بيانات المستخدم إلى الوضع الافتراضي.
  Future<void> _confirmResetData(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(AppIcons.warning, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(l10n.resetData),
          ],
        ),
        content: Text(l10n.resetWarningMessage),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, false),
            icon: const Icon(AppIcons.x, size: 16),
            label: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(AppIcons.trash, size: 16),
            label: Text(l10n.confirmReset),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await UserDataStore.instance.resetAllUserData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  /// يبني عنوان قسم فرعي داخل شاشة الإعدادات.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// يبني حاوية بطاقة موحدة المظهر لتجميع عناصر الإعدادات.
  Widget _buildCard({required Widget child, required BuildContext context}) {
    return Material(
      color: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// يبني زراً تفاعلياً لأحد خيارات المظهر (السمة أو لون ورق المصحف).
  Widget _buildThemeOptionButton({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onSelect,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onSelect();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: isDark ? 0.24 : 0.12)
                  : (isDark
                        ? AppColors.darkSurface
                        : AppColors.lightBackground),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 1.8 : 0.9,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? primaryColor
                      : (isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? primaryColor
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Icon(
                    AppIcons.checkCircleFill,
                    size: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// إرجاع التسمية التوضيحية للسمة المفعّلة حالياً مع توضيح حالة مظهر الجهاز عند تفعيل الوضع التلقائي.
  String _getActiveThemeLabel(ThemeMode mode, bool isDark, bool isArabic) {
    switch (mode) {
      case ThemeMode.light:
        return isArabic ? 'فاتح' : 'Light';
      case ThemeMode.dark:
        return isArabic ? 'داكن' : 'Dark';
      case ThemeMode.system:
        final resolved = isDark
            ? (isArabic ? 'داكن' : 'Dark')
            : (isArabic ? 'فاتح' : 'Light');
        return isArabic ? 'تلقائي ($resolved)' : 'System ($resolved)';
    }
  }

  /// إرجاع النص الإرشادي التوضيحي لمزايا السمة المحددة.
  String _getThemeExplanation(ThemeMode mode, bool isDark, bool isArabic) {
    if (mode == ThemeMode.light) {
      return isArabic
          ? 'الوضع النهاري: خلفية ورقية هادئة مع لمسات كحلية وذهبية لقراءة نهارية مريحة وواضحة.'
          : 'Light Mode: Calm paper tones with navy and gold accents for comfortable daytime reading.';
    } else if (mode == ThemeMode.dark) {
      return isArabic
          ? 'الوضع الليلي: ألوان كحلية ليلية مع لمسات ذهبية صُممت خصيصاً لتقليل إجهاد النظر والسطوع أثناء التلاوة والتدبر الطويل.'
          : 'Dark Mode: Deep night-navy tones with gold accents, engineered to minimize eye fatigue during extended nighttime reading.';
    } else {
      final current = isDark
          ? (isArabic ? 'داكن' : 'Dark')
          : (isArabic ? 'فاتح' : 'Light');
      return isArabic
          ? 'الوضع التلقائي: يتزامن مظهر التطبيق آلياً مع إعدادات هاتفك (المظهر المفعّل حالياً في جهازك: $current).'
          : 'System Mode: Automatically synchronizes with your device settings (Currently active: $current).';
    }
  }

  /// يعرض نافذة ميثاق وسياسة الخصوصية والأمان للمستخدم داخل التطبيق بدون إنترنت.
  void _showPrivacyPolicyDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isArabic = context.currentLanguage == AppLanguage.arabic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.shieldFill,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.privacyPolicyTitle,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                context.l10n.privacyPolicySubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(AppIcons.x, size: 20),
                          tooltip: context.l10n.close,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildPrivacyTile(
                            icon: AppIcons.cloudSlash,
                            title: isArabic
                                ? 'عمل محلي تام دون إنترنت (100% Offline-First)'
                                : '100% Offline-First by Architecture',
                            description: isArabic
                                ? 'لا يطلب التطبيق إذن الإنترنت (android.permission.INTERNET) في ملف التكوين، ويعمل ذاتياً بالكامل على جهازك دون الحاجة لأي خوادم سحابية.'
                                : 'The application does not request internet permission and operates completely independently on your local device without external servers.',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.userMinus,
                            title: isArabic
                                ? 'عدم جمع أي بيانات شخصية (Zero Data Collection)'
                                : 'Zero Personal Data Collection',
                            description: isArabic
                                ? 'لا يجمع التطبيق ولا يسجل ولا يشارك أي بيانات شخصية، أو معرّفات أجهزة، أو سجلات قراءة، أو إحصاءات استخدام مع أي طرف خارجي على الإطلاق.'
                                : 'Tadbeer does not collect, record, transmit, or share any personal identity information, usage habits, or device identifiers.',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.lockKey,
                            title: isArabic
                                ? 'تخزين محلي وتشفير عالي (AES-256)'
                                : 'Local Storage & AES-256 Encryption',
                            description: isArabic
                                ? 'تُحفظ كافة ملاحظاتك ووقفاتك التدبرية محلياً في قاعدة بيانات SQLite على جهازك، وتُشفّر النسخ الاحتياطية (.quranbackup) بكلمة مرورك بمعيار AES-256-CBC مع فحص SHA-256.'
                                : 'All reflections and notes reside strictly in on-device SQLite storage. Exported backups are encrypted locally with AES-256-CBC and verified via SHA-256.',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.bellRingingFill,
                            title: isArabic
                                ? 'استخدام حصري ومحدد للأذونات (Device Permissions)'
                                : 'Strictly Scoped Device Permissions',
                            description: isArabic
                                ? 'تُستخدم أذونات الإشعارات المحلية حصراً لتشغيل منبهات وتذكيرات الورد اليومي التي يحددها المستخدم بنفسه، ولا تُرسل أي إشعارات ترويجية.'
                                : 'Notification permissions are used exclusively to trigger local alarms and reminders scheduled directly by the user.',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.prohibit,
                            title: isArabic
                                ? 'خلو تام من الإعلانات والمتتبعات (Zero Ads & Trackers)'
                                : 'Zero Advertisements & Trackers',
                            description: isArabic
                                ? 'التطبيق خالٍ بنسبة 100% من أي منصات إعلانية أو حزم تتبع أو أدوات تحليل أداء خارجية.'
                                : 'The app is completely free from advertising SDKs, marketing trackers, and analytics frameworks.',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Text(
                              isArabic
                                  ? 'تطبيق «تَدْبِير» مشروع مفتوح المصدر بالكامل تحت رخصة MIT، ورمزه المصدري متاح للمراجعة والتدقيق العام على GitHub.'
                                  : 'Tadbeer is an open-source project licensed under MIT, fully accessible for public review and audit on GitHub.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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

  /// عنصر توضيحي فردي داخل نافذة سياسة الخصوصية.
  Widget _buildPrivacyTile({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// دائرة معاينة لسمة ألوان: تدرّج لونها الأساسي مع لمسة ذهبية.
class _ColorThemeSwatch extends StatelessWidget {
  final AppColorTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorThemeSwatch({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ThemePalette.of(theme);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.heroLightStart, p.heroLightEnd],
                ),
                border: Border.all(
                  color: selected ? p.lightAccentGold : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.lightPrimary.withValues(alpha: 0.3),
                    blurRadius: selected ? 10 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: selected
                  ? const Icon(AppIcons.check, color: Colors.white)
                  : Align(
                      alignment: const Alignment(0.55, 0.55),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.lightAccentGold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

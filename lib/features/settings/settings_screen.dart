import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../backup/backup_screen.dart';
import '../reminders/reminders_screen.dart';
import 'user_settings_model.dart';

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
                              Icons.palette_outlined,
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: isDark ? 0.22 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
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
                                  fontSize: 11,
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
                                mode: ThemeMode.light,
                                currentMode: settings.themeMode,
                                label: l10n.light,
                                icon: Icons.light_mode_rounded,
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
                                mode: ThemeMode.dark,
                                currentMode: settings.themeMode,
                                label: l10n.dark,
                                icon: Icons.dark_mode_rounded,
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
                                mode: ThemeMode.system,
                                currentMode: settings.themeMode,
                                label: context.currentLanguage ==
                                        AppLanguage.arabic
                                    ? 'تلقائي'
                                    : 'System',
                                icon: Icons.brightness_auto_rounded,
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
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
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
                                  fontSize: 11.5,
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
                        Row(
                          children: [
                            Icon(
                              Icons.font_download_outlined,
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
                        for (final fontOpt in QuranFontFamilyOption.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                UserDataStore.instance.setQuranFontFamily(
                                  fontOpt,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: settings.quranFontFamily == fontOpt
                                      ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(
                                              alpha: isDark ? 0.22 : 0.10,
                                            )
                                      : (isDark
                                            ? AppColors.darkSurface
                                            : AppColors.lightBackground),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: settings.quranFontFamily == fontOpt
                                        ? Theme.of(context).colorScheme.primary
                                        : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder),
                                    width: settings.quranFontFamily == fontOpt
                                        ? 1.4
                                        : 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      settings.quranFontFamily == fontOpt
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 20,
                                      color: settings.quranFontFamily == fontOpt
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : (isDark
                                                ? AppColors.nightSubtitle
                                                : AppColors.daySubtitle),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fontOpt.getLabel(
                                              context.currentLanguage ==
                                                  AppLanguage.arabic,
                                            ),
                                            style: TextStyle(
                                              fontWeight:
                                                  settings.quranFontFamily ==
                                                      fontOpt
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fontOpt.getSubtitle(
                                              context.currentLanguage ==
                                                  AppLanguage.arabic,
                                            ),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark
                                                  ? AppColors.nightSubtitle
                                                  : AppColors.daySubtitle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.format_size_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.fontSize,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              l10n.fontSizePoints(
                                context.currentLanguage == AppLanguage.arabic
                                    ? ArabicSearchNormalizer.toArabicDigits(
                                        settings.quranFontSize.round(),
                                      )
                                    : settings.quranFontSize.round(),
                              ),
                              style: TextStyle(
                                fontFamily: context.currentLanguage == AppLanguage.arabic ? 'Amiri' : null,
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
                          divisions: 16,
                          label: '${settings.quranFontSize.round()}',
                          onChanged: (newSize) {
                            UserDataStore.instance.setQuranFontSize(newSize);
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.mushafBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ\u00A0\u00A0ۛ فِيهِ\u00A0\u00A0ۛ هُدًى لِّلْمُتَّقِينَ ﴿٢﴾ أُو۟لَٰٓئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْ\u00A0\u00A0ۖ وَأُو۟لَٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ ﴿٥﴾',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: settings.quranFontFamilyName,
                              fontSize: settings.quranFontSize,
                              height: 1.85,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.mushafQuranText,
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
                                      : () => UserDataStore.instance.setQuranFontSize(
                                          UserSettings.defaultQuranFontSize,
                                        ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: Text(
                                    l10n.resetToDefaultWithVal(
                                      context.currentLanguage == AppLanguage.arabic
                                          ? '٢٠'
                                          : '20',
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
                          Icons.language_outlined,
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
                          Icons.alarm_rounded,
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
                        trailing: Icon(
                          isArabic
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                        ),
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
                          Icons.security_rounded,
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
                        trailing: Icon(
                          isArabic
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                        ),
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
                          Icons.delete_forever_rounded,
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
                                Icons.menu_book_rounded,
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
                            fontFamily: isArabic ? 'Amiri' : null,
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
                                icon: const Icon(Icons.shield_outlined,
                                    size: 17),
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
                                icon: const Icon(Icons.policy_outlined,
                                    size: 17),
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
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(l10n.resetData),
          ],
        ),
        content: Text(l10n.resetWarningMessage),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, false),
            icon: const Icon(Icons.close_rounded, size: 16),
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
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
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

  /// يبني زراً تفاعلياً لأحد خيارات سمة المظهر (فاتح / داكن / تلقائي).
  Widget _buildThemeOptionButton({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onSelect,
  }) {
    final isSelected = currentMode == mode;
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
                    : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
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
                    Icons.check_circle_rounded,
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
  String _getActiveThemeLabel(
    ThemeMode mode,
    bool isDark,
    bool isArabic,
  ) {
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
  String _getThemeExplanation(
    ThemeMode mode,
    bool isDark,
    bool isArabic,
  ) {
    if (mode == ThemeMode.light) {
      return isArabic
          ? 'الوضع النهاري: ألوان ورقية مستوحاة من ورق المصحف الشريف لقراءة نهارية مريحة وواضحة.'
          : 'Light Mode: Calm parchment tones inspired by the Medina Mushaf for comfortable daytime reading.';
    } else if (mode == ThemeMode.dark) {
      return isArabic
          ? 'الوضع الليلي: ألوان داكنة زمردية صُممت خصيصاً لتقليل إجهاد النظر والسطوع أثناء التلاوة والتدبر الطويل.'
          : 'Dark Mode: Subdued, deep forest tones engineered to minimize eye fatigue during extended nighttime reading.';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          child: Icon(Icons.shield_rounded,
                              color: primaryColor, size: 22),
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
                                  fontSize: 11,
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
                          icon: const Icon(Icons.close_rounded, size: 20),
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
                            icon: Icons.cloud_off_rounded,
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
                            icon: Icons.no_accounts_rounded,
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
                            icon: Icons.enhanced_encryption_rounded,
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
                            icon: Icons.notifications_active_rounded,
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
                            icon: Icons.block_flipped,
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
                    fontFamily: 'Amiri',
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

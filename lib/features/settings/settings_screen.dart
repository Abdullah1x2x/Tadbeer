import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import '../backup/backup_screen.dart';
import '../reminders/reminders_screen.dart';
import '../../data/models/user_settings_model.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/app_select.dart';
import '../quran/widgets/text_scale_control.dart';
import '../quran/qcf/madinah_preview.dart';

part 'settings_widgets.dart';

/// الإعدادات: المظهر، وخط المصحف، والتطبيق، والبيانات، وحول.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                // ١. المظهر
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
                                  context,
                                  settings.themeMode,
                                  isDark,
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
                                label: context.l10n.systemTheme,
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
                        // ثيم الألوان: دائرة لكل ثيم.
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
                                  context,
                                  settings.themeMode,
                                  isDark,
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
                // ٢. الخط والقراءة
                _buildSectionHeader(context, l10n.typographyAndReading),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // صفحات مصحف المدينة أولاً؛ والنص المتدفق بديل لا يحتاج
                        // تحميلاً.
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
                        // اختيار الخط يخص النص المتدفق وحده.
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
                          // قائمة مختصرة بدل خمس بطاقات كبيرة، والمعاينة تحتها
                          // تُظهر الخط المختار.
                          AppSelectField<QuranFontFamilyOption>(
                            title: l10n.quranFontFamily,
                            icon: AppIcons.textT,
                            value: settings.quranFontFamily,
                            options: [
                              // اسم كل خط مكتوب بالخط نفسه.
                              for (final fontOpt
                                  in QuranFontFamilyOption.values)
                                AppSelectOption(
                                  value: fontOpt,
                                  label: fontOpt.getLabel(
                                    context.currentLanguage ==
                                        AppLanguage.arabic,
                                  ),
                                  style: TextStyle(
                                    fontFamily: fontOpt.fontFamily,
                                  ),
                                ),
                            ],
                            onChanged:
                                UserDataStore.instance.setQuranFontFamily,
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
                          const SizedBox(height: 12),
                          const TextScaleControl(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                        ],
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
                                  zoom: 1,
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
                                    fontSize: 20 * settings.flowingTextScale,
                                    height: 1.85,
                                    color: MushafPalette.of(
                                      isDark: isDark,
                                      tone: settings.mushafPaperTone,
                                    ).text,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ٣. التطبيق
                _buildSectionHeader(context, l10n.applicationSection),
                _buildCard(
                  context: context,
                  child: Column(
                    children: [
                      // الاسم الذي تناديه به التذكيرات.
                      ListTile(
                        leading: Icon(
                          AppIcons.user,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.yourName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          settings.userName.isEmpty
                              ? l10n.yourNameNotSet
                              : settings.userName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: const Icon(AppIcons.pencilSimple, size: 20),
                        onTap: () => _editName(context, settings.userName),
                      ),
                      const Divider(height: 1),
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
                        trailing: AppSelectField<String>(
                          title: l10n.languageTitle,
                          compact: true,
                          value: settings.languageCode,
                          options: const [
                            AppSelectOption(value: 'ar', label: 'العربية'),
                            AppSelectOption(value: 'en', label: 'English'),
                          ],
                          onChanged: (code) {
                            UserDataStore.instance.updateSettings(
                              settings.copyWith(languageCode: code),
                            );
                            AppLocalizationScope.of(context)
                                .onLanguageChanged(AppLanguage.fromCode(code));
                          },
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

                // ٤. البيانات
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

                // ٥. حول
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

  /// يطلب التأكيد قبل مسح كل بيانات القارئ.
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
      await UserDataStore.instance.resetAllData();
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

  /// يغيّر الاسم الذي تناديه به التذكيرات.
  Future<void> _editName(BuildContext context, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (name != null) await UserDataStore.instance.setUserName(name);
  }

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

  /// بطاقة موحّدة تجمع عناصر قسم.
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

  /// زر لأحد خيارات المظهر (الوضع أو لون ورق المصحف).
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

  /// اسم الوضع الحالي، ومعه مظهر الجهاز حين يكون تلقائياً.
  String _getActiveThemeLabel(
    BuildContext context,
    ThemeMode mode,
    bool isDark,
  ) {
    final l10n = context.l10n;
    return switch (mode) {
      ThemeMode.light => l10n.light,
      ThemeMode.dark => l10n.dark,
      ThemeMode.system => l10n.systemThemeLabel(
        isDark ? l10n.dark : l10n.light,
      ),
    };
  }

  /// شرح الوضع المختار.
  String _getThemeExplanation(
    BuildContext context,
    ThemeMode mode,
    bool isDark,
  ) {
    final l10n = context.l10n;
    return switch (mode) {
      ThemeMode.light => l10n.lightThemeExplanation,
      ThemeMode.dark => l10n.darkThemeExplanation,
      ThemeMode.system => l10n.systemThemeExplanation(
        isDark ? l10n.dark : l10n.light,
      ),
    };
  }

  /// يعرض سياسة الخصوصية داخل التطبيق دون إنترنت.
  void _showPrivacyPolicyDialog(BuildContext context) {
    HapticFeedback.selectionClick();
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
                            title: context.l10n.privacyOfflineTitle,
                            description: context.l10n.privacyOfflineBody,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.userMinus,
                            title: context.l10n.privacyNoDataTitle,
                            description: context.l10n.privacyNoDataBody,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.lockKey,
                            title: context.l10n.privacyStorageTitle,
                            description: context.l10n.privacyStorageBody,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.bellRingingFill,
                            title: context.l10n.privacyPermissionsTitle,
                            description: context.l10n.privacyPermissionsBody,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildPrivacyTile(
                            icon: AppIcons.prohibit,
                            title: context.l10n.privacyNoAdsTitle,
                            description: context.l10n.privacyNoAdsBody,
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
                              context.l10n.privacyOpenSourceBody,
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

  /// بند في نافذة سياسة الخصوصية.
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

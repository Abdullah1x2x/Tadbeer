import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../features/ayah_links/ayah_link_model.dart';
import '../../features/ayah_links/ayah_link_repository.dart';
import 'views/ayah_link_network_view.dart';
import 'views/ayah_link_ordered_view.dart';
import 'widgets/add_verse_to_link_dialog.dart';
import 'widgets/ayah_link_qr_dialog.dart';
import 'widgets/create_link_dialog.dart';

/// شاشة عرض تفاصيل رابط الآيات عبر وضعي الشبكة التفاعلية والقائمة المرتبة.
///
/// Screen displaying an Ayah Link across the 2 views:
/// 1. 🌐 Network Canvas (شبكة)
/// 2. 📜 Ordered List (مرتب)
class AyahLinkDetailScreen extends StatefulWidget {
  /// المعرّف الفريد لرابط الآيات المراد عرضه.
  final String linkId;

  /// ينشئ شاشة تفاصيل رابط الآيات.
  const AyahLinkDetailScreen({super.key, required this.linkId});

  /// ينشئ حالة شاشة تفاصيل رابط الآيات.
  @override
  State<AyahLinkDetailScreen> createState() => _AyahLinkDetailScreenState();
}

/// الحالة الداخلية لشاشة تفاصيل رابط الآيات وإدارة التبديل بين أنماط العرض.
class _AyahLinkDetailScreenState extends State<AyahLinkDetailScreen> {
  final AyahLinkRepository _repo = AyahLinkRepository();
  final GlobalKey<AyahLinkNetworkViewState> _networkKey =
      GlobalKey<AyahLinkNetworkViewState>();
  late String _activeViewMode;

  /// يهيئ نمط العرض النشط بناءً على آخر وضع محفوظ للرابط.
  @override
  void initState() {
    super.initState();
    final link = _repo.getLink(widget.linkId);
    final mode = link?.lastViewMode ?? 'network';
    _activeViewMode = (mode == 'ordered') ? 'ordered' : 'network';
  }

  /// يبدل نمط العرض بين الشبكة والقائمة المرتبة ويحفظ التفضيل في المستودع.
  void _switchViewMode(String mode) {
    setState(() => _activeViewMode = mode);
    _repo.updateViewState(widget.linkId, viewMode: mode);
  }

  /// يفتح نافذة حوار لإضافة آية قرآنية جديدة إلى الرابط الحالي.
  Future<void> _openAddVerse(AyahLinkItem link) async {
    await AddVerseToLinkDialog.show(
      context,
      linkId: link.id,
      existingAyahIds: link.verses.map((v) => v.ayahId).toList(),
    );
  }

  /// يفتح نافذة حوار لإضافة أو تعديل الملاحظة والتدبر الخاص برابط الآيات.
  Future<void> _openAddNote(AyahLinkItem link) async {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: link.description ?? '');

    final updatedNote = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.comsilkLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.isArabic ? 'ملاحظة وتدبر الرابط' : 'Link Reflection Note',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.isArabic
                  ? 'سجّل ملاحظتك أو الرابط التدبري الذي يجمع هذه الآيات:'
                  : 'Record your reflection or the theme connecting these verses:',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              autofocus: true,
              style: const TextStyle(fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: l10n.isArabic
                    ? 'اكتب تدبرك أو ملاحظتك هنا...'
                    : 'Write your reflection or note here...',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.comsilk,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (updatedNote != null && mounted) {
      final newDesc = updatedNote.isEmpty ? null : updatedNote;
      await _repo.updateLink(link.copyWith(description: newDesc));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isArabic
                  ? (newDesc != null
                      ? 'تم حفظ ملاحظة الرابط بنجاح'
                      : 'تمت إزالة ملاحظة الرابط')
                  : 'Link note updated successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// يفتح نافذة حوار لتعديل عنوان ووصف رابط الآيات الحالي.
  Future<void> _editLink(AyahLinkItem link) async {
    await CreateLinkDialog.show(context, existingLink: link);
  }

  /// يعرض نافذة تأكيد لحذف رابط الآيات نهائياً ثم يعود للشاشة السابقة.
  Future<void> _confirmDelete(AyahLinkItem link) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteAyahLink),
        content: Text(
          l10n.isArabic
              ? 'هل أنت متأكد من رغبتك في حذف رابط «${link.title}»؟'
              : 'Are you sure you want to delete the link "${link.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _repo.deleteLink(link.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isArabic
                  ? 'تم حذف رابط «${link.title}»'
                  : 'Link "${link.title}" deleted',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// يبني واجهة شاشة تفاصيل الرابط وشريط التبويب والأزرار العائمة.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: ListenableBuilder(
        listenable: UserDataStore.instance,
        builder: (context, _) {
          final link = _repo.getLink(widget.linkId);
          if (link == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Text(
                  l10n.isArabic
                      ? 'الرابط غير موجود أو تم حذفه'
                      : 'Link not found or has been deleted',
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                link.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_2_rounded),
                  tooltip: l10n.isArabic
                      ? 'مشاركة عبر رمز الاستجابة السريعة (QR)'
                      : 'Share via QR Code',
                  onPressed: () =>
                      AyahLinkQrDialog.showShareDialog(context, link),
                ),
                // Secondary actions popup menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: l10n.more,
                  onSelected: (val) {
                    if (val == 'autolayout') {
                      _networkKey.currentState?.autoLayout();
                    } else if (val == 'edit') {
                      _editLink(link);
                    } else if (val == 'delete') {
                      _confirmDelete(link);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (_activeViewMode == 'network')
                      PopupMenuItem(
                        value: 'autolayout',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_mosaic_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.autoLayout),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.editTitleAndDescription),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.deleteAyahLink,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.comsilkLight,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ViewTabButton(
                        label: l10n.networkView,
                        icon: Icons.hub_outlined,
                        isActive: _activeViewMode == 'network',
                        onTap: () => _switchViewMode('network'),
                      ),
                      const SizedBox(width: 8),
                      _ViewTabButton(
                        label: l10n.orderedView,
                        icon: Icons.format_list_numbered_rtl_rounded,
                        isActive: _activeViewMode == 'ordered',
                        onTap: () => _switchViewMode('ordered'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: IndexedStack(
              index: _activeViewMode == 'network' ? 0 : 1,
              children: [
                AyahLinkNetworkView(
                  key: _networkKey,
                  link: link,
                  onAddVerse: () => _openAddVerse(link),
                ),
                AyahLinkOrderedView(
                  link: link,
                  onAddVerse: () => _openAddVerse(link),
                ),
              ],
            ),
            floatingActionButton: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'add_verse_fab',
                  onPressed: () => _openAddVerse(link),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addVerse),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.extended(
                  heroTag: 'add_note_fab',
                  onPressed: () => _openAddNote(link),
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.comsilkLight,
                  foregroundColor: isDark
                      ? AppColors.darkAccentGold
                      : AppColors.olive,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkAccentGold.withValues(alpha: 0.5)
                          : AppColors.olive.withValues(alpha: 0.4),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(
                    l10n.isArabic ? 'إضافة ملاحظة' : 'Add Note',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_activeViewMode == 'network') ...[
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'center_view_fab',
                    onPressed: () => _networkKey.currentState?.centerView(),
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.comsilkLight,
                    foregroundColor: AppColors.olive,
                    tooltip: l10n.resetToCenter,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: const Icon(Icons.center_focus_strong, size: 20),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// زر تبويب مخصص للتبديل بين وضع الشبكة ووضع القائمة المرتبة.
class _ViewTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  /// ينشئ زر التبويب مع العنوان والأيقونة وحالة التفعيل.
  const _ViewTabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  /// يبني عنصر واجهة زر التبويب مع تأثيرات الحركة والتلوين.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

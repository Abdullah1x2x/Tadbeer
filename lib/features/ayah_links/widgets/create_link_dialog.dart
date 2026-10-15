import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../ayah_link_model.dart';
import '../ayah_link_repository.dart';

/// نافذة حوار مبسطة لإنشاء رابط آيات جديد أو تعديل رابط موجود.
///
/// Minimal dialog to create or edit an Ayah Link.
///
/// Keeps fields minimal: Title is required, Description/Idea is optional.
class CreateLinkDialog extends StatefulWidget {
  /// رابط الآيات المراد تعديله في حال وجوده، أو فارغ عند الإنشاء الجديد.
  final AyahLinkItem? existingLink;

  /// ينشئ نافذة حوار إنشاء أو تعديل رابط الآيات.
  const CreateLinkDialog({super.key, this.existingLink});

  /// يعرض نافذة حوار إنشاء أو تعديل رابط الآيات ويعيد العنصر الناتج.
  static Future<AyahLinkItem?> show(
    BuildContext context, {
    AyahLinkItem? existingLink,
  }) {
    return showDialog<AyahLinkItem>(
      context: context,
      builder: (_) => CreateLinkDialog(existingLink: existingLink),
    );
  }

  /// ينشئ حالة نافذة حوار إنشاء أو تعديل رابط الآيات.
  @override
  State<CreateLinkDialog> createState() => _CreateLinkDialogState();
}

/// الحالة الداخلية لنافذة إنشاء أو تعديل رابط الآيات.
class _CreateLinkDialogState extends State<CreateLinkDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  /// يهيئ حقول العنوان والوصف بالقيم الحالية عند التعديل.
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingLink?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingLink?.description ?? '',
    );
  }

  /// يحرر موارد متحكمات النصوص عند إغلاق النافذة.
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// يتحقق من صحة المدخلات ويحفظ رابط الآيات الجديد أو المحدث.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    try {
      final repo = AyahLinkRepository();
      AyahLinkItem result;

      if (widget.existingLink != null) {
        result = widget.existingLink!.copyWith(
          title: title,
          description: desc.isEmpty ? null : desc,
        );
        await repo.updateLink(result);
      } else {
        result = await repo.createLink(
          title: title,
          description: desc.isEmpty ? null : desc,
        );
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// يبني نموذج إدخال عنوان ووصف رابط الآيات.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.existingLink != null;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: AlertDialog(
        backgroundColor: AppColors.background(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.hub_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing
                  ? (l10n.isArabic ? 'تعديل رابط الآيات' : 'Edit Ayah Link')
                  : l10n.newAyahLink,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.linkTitle,
                  hintText: l10n.linkTitleHint,
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.isArabic
                        ? 'يرجى إدخال عنوان الرابط'
                        : 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.linkDescription,
                  hintText: l10n.linkDescriptionHint,
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEditing
                        ? l10n.save
                        : (l10n.isArabic ? 'إنشاء' : 'Create'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

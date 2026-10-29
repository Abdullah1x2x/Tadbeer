import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/models/tadbeer_model.dart';
import 'tadbeer_questions.dart';
import '../../core/design_system/app_icons.dart';

/// لوحة "وقفة تدبر" على آية: أربعة أسئلة تظهر واحداً واحداً.
/// يستطيع القارئ أن يتخطى أو يكتب أو يحفظ في أي لحظة دون إكمالها كلها. الإجابات الفارغة لا تُحفظ، والمحفوظة تعود حين يفتح الآية ثانية.
class TadbeerPauseSheet extends StatefulWidget {
  final Ayah ayah;

  /// السؤال الذي تبدأ منه (0..3).
  final int initialQuestion;

  const TadbeerPauseSheet({
    super.key,
    required this.ayah,
    this.initialQuestion = 0,
  });

  /// يفتح وقفة التدبر لوحةً سفلية.
  static Future<void> show(
    BuildContext context,
    Ayah ayah, {
    int initialQuestion = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          TadbeerPauseSheet(ayah: ayah, initialQuestion: initialQuestion),
    );
  }

  @override
  State<TadbeerPauseSheet> createState() => _TadbeerPauseSheetState();
}

/// الاسم القديم، يبقى للتوافق.
typedef TadabburPauseSheet = TadbeerPauseSheet;

class _TadbeerPauseSheetState extends State<TadbeerPauseSheet> {
  int _currentQuestionIndex = 0; // 0..3, see TadbeerItem.questionKeys
  late final List<String> _questions = TadbeerQuestions.forAyah(widget.ayah);
  final Map<int, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // إجابات سابقة إن تدبّر القارئ هذه الآية من قبل.
    final existingTadbeer = UserDataStore.instance.getTadbeer(
      widget.ayah.surahNumber,
      widget.ayah.ayahNumber,
    );

    for (final key in TadbeerItem.questionKeys) {
      final initialText = existingTadbeer?.answers[key] ?? '';
      _controllers[key] = TextEditingController(text: initialText);
    }
    _currentQuestionIndex = widget.initialQuestion.clamp(
      0,
      TadbeerItem.questionKeys.length - 1,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// يحفظ الإجابات غير الفارغة ويغلق اللوحة.
  Future<void> _saveAndClose() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final answers = <int, String>{};
    _controllers.forEach((index, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        answers[index] = text;
      }
    });

    await UserDataStore.instance.saveTadbeer(
      surahNumber: widget.ayah.surahNumber,
      ayahNumber: widget.ayah.ayahNumber,
      ayahId: widget.ayah.id,
      answers: answers,
    );

    if (mounted) {
      Navigator.pop(context);
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            answers.isEmpty
                ? (l10n.isArabic
                      ? 'تم مسح الإجابات الفارغة بنجاح'
                      : 'Cleared empty answers successfully')
                : (l10n.isArabic
                      ? 'تم حفظ وقفة التدبر بنجاح'
                      : 'Tadbeer pause saved successfully'),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.olive,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// السؤال التالي، أو الحفظ والإنهاء بعد الأخير.
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _saveAndClose();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surah = QuranRepository.instance.getSurah(widget.ayah.surahNumber);
    final questionNumber = _currentQuestionIndex + 1;
    final currentQuestion = _questions[_currentQuestionIndex];
    final activeController =
        _controllers[TadbeerItem.questionKeys[_currentQuestionIndex]]!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightBorder,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.olive.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.flowerLotus,
                            size: 18,
                            color: AppColors.olive,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.tadbeerPause,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.comsilk
                                : AppColors.oliveDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: l10n.close,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // الآية.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.comsilk,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.ayahReference(
                              surah.name,
                              l10n.isArabic
                                  ? ArabicSearchNormalizer.toArabicDigits(
                                      widget.ayah.ayahNumber,
                                    )
                                  : widget.ayah.ayahNumber,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkAccentGold
                                  : AppColors.lightPrimary,
                            ),
                          ),
                          Text(
                            l10n.pageAbbr(
                              l10n.isArabic
                                  ? ArabicSearchNormalizer.toArabicDigits(
                                      widget.ayah.page,
                                    )
                                  : widget.ayah.page,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '﴿ ${widget.ayah.text} ﴾',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 15,
                          height: 1.6,
                          color: isDark
                              ? AppColors.nightQuranText
                              : AppColors.dayQuranText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // مؤشر الأسئلة: نقاط واسم السؤال.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.isArabic
                          ? 'السؤال ${ArabicSearchNormalizer.toArabicDigits(questionNumber)} من ٤'
                          : 'Question $questionNumber of 4',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.olive,
                      ),
                    ),
                    Row(
                      children: List.generate(_questions.length, (idx) {
                        final isCurrent = idx == _currentQuestionIndex;
                        final isFilled =
                            (_controllers[TadbeerItem.questionKeys[idx]]?.text
                                .trim()
                                .isNotEmpty ??
                            false);

                        return Container(
                          width: isCurrent ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.olive
                                : isFilled
                                ? AppColors.olive.withValues(alpha: 0.5)
                                : Colors.grey.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.olive.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    currentQuestion,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: activeController,
                  maxLines: 4,
                  textDirection: context.currentLanguage.direction,
                  autofocus: false,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark
                        ? AppColors.nightQuranText
                        : AppColors.dayQuranText,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.isArabic
                        ? 'اكتب ما خطر ببالك...'
                        : 'Write your thoughts here...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.comsilk,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    if (_currentQuestionIndex > 0) ...[
                      OutlinedButton.icon(
                        onPressed: _previousQuestion,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.comsilk
                              : AppColors.oliveDark,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(AppIcons.arrowLeft, size: 16),
                        label: Text(l10n.previous),
                      ),
                      const SizedBox(width: 8),
                    ],

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          _currentQuestionIndex < _questions.length - 1
                              ? AppIcons.arrowRight
                              : AppIcons.check,
                          size: 16,
                        ),
                        label: Text(
                          _currentQuestionIndex < _questions.length - 1
                              ? (l10n.isArabic ? 'التالي' : 'Next')
                              : (l10n.isArabic ? 'تم وحفظ' : 'Done & Save'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // الحفظ والإنهاء متاح في أي سؤال.
                if (_currentQuestionIndex < _questions.length - 1)
                  Center(
                    child: TextButton.icon(
                      onPressed: _saveAndClose,
                      icon: const Icon(AppIcons.floppyDisk, size: 16),
                      label: Text(
                        l10n.isArabic
                            ? 'حفظ ما كتبت الآن وإنهاء'
                            : 'Save reflections & finish',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.oliveSoft
                            : AppColors.olive,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

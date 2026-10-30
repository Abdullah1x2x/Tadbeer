import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import 'scene_story.dart';
import 'tour_scenes.dart';

/// الأقسام التي تشرح نفسها عند أول دخول.
enum GuideTopic {
  mushaf,
  reflections,
  ayahLinks,
  pathways,
  memorization,
  wordMeanings,
  notes,
  search,
  books,
  duas,
  tasbeeh,
  journey,
  reminders,
  backup,
  qibla,
}

/// خطوة في شرح قسم: مشهدها، وعنوانها، وشرحها.
class _GuideStep {
  final Widget Function(double t) scene;
  final String title;
  final String body;

  const _GuideStep(this.scene, this.title, this.body);
}

/// شرح كل قسم: يظهر مرة عند أول دخول، ويعيده زر الشرح متى شاء القارئ.
///
/// أقسام التدبّر الثلاثة (الوقفات والروابط والمسارات) تُشرح في ثلاث خطوات،
/// فهي غاية التطبيق؛ وغيرها في خطوة واحدة.
abstract final class SectionGuide {
  static const _key = 'section_guides';

  /// في الاختبارات لا يظهر شرح من تلقاء نفسه، فلا يحجب الشاشات المختبرة.
  static bool get autoShowAllowed {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return !binding.contains('Test');
  }

  static bool seen(GuideTopic topic) =>
      UserDataStore.instance.featureState(_key)[topic.name] == true;

  static Future<void> _markSeen(GuideTopic topic) {
    return UserDataStore.instance.saveFeatureState(_key, {
      ...UserDataStore.instance.featureState(_key),
      topic.name: true,
    });
  }

  /// يعيد كل الشروحات لتظهر عند الدخول التالي.
  static Future<void> resetAll() =>
      UserDataStore.instance.saveFeatureState(_key, {});

  /// يعرض الشرح إن لم يره القارئ، بعد أن تُرسم الشاشة.
  static void showOnce(BuildContext context, GuideTopic topic) {
    if (!autoShowAllowed || seen(topic)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || seen(topic)) return;
      // لا يُفتح فوق شاشة أخرى غطّت القسم قبل أن يظهر.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      show(context, topic);
    });
  }

  /// يعرض شرح [topic] الآن.
  static Future<void> show(BuildContext context, GuideTopic topic) async {
    await _markSeen(topic);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface(context),
      builder: (_) => _GuideSheet(steps: _steps(context.l10n, topic)),
    );
  }

  static List<_GuideStep> _steps(AppStrings l10n, GuideTopic topic) {
    _GuideStep single(IconData icon, String title, String body) =>
        _GuideStep((t) => IconScene(t: t, icon: icon), title, body);
    return switch (topic) {
      GuideTopic.reflections => [
        _GuideStep(
          (t) => MushafScene(t: t, pickCenter: true),
          l10n.guideReflections1Title,
          l10n.guideReflections1Body,
        ),
        _GuideStep(
          (t) => ReflectScene(t: t, answer: true),
          l10n.guideReflections2Title,
          l10n.guideReflections2Body,
        ),
        _GuideStep(
          (t) => ReflectionsListScene(t: t),
          l10n.guideReflections3Title,
          l10n.guideReflections3Body,
        ),
      ],
      GuideTopic.ayahLinks => [
        _GuideStep(
          (t) => CreateLinkScene(t: t),
          l10n.guideLinks1Title,
          l10n.guideLinks1Body,
        ),
        _GuideStep(
          (t) => AddVersesScene(t: t),
          l10n.guideLinks2Title,
          l10n.guideLinks2Body,
        ),
        _GuideStep(
          (t) => WholeNetworkScene(t: t),
          l10n.guideLinks3Title,
          l10n.guideLinks3Body,
        ),
      ],
      GuideTopic.pathways => [
        _GuideStep(
          (t) => PathwayDaysScene(t: t, done: 0),
          l10n.guidePathways1Title,
          l10n.guidePathways1Body,
        ),
        _GuideStep(
          (t) => TodayAyahScene(t: t),
          l10n.guidePathways2Title,
          l10n.guidePathways2Body,
        ),
        _GuideStep(
          (t) => PathwayDaysScene(t: t, done: 1),
          l10n.guidePathways3Title,
          l10n.guidePathways3Body,
        ),
      ],
      GuideTopic.mushaf => [
        _GuideStep(
          (t) => MushafScene(t: t),
          l10n.guideMushafTitle,
          l10n.guideMushafBody,
        ),
      ],
      GuideTopic.memorization => [
        single(
          AppIcons.brainFill,
          l10n.guideMemorizationTitle,
          l10n.guideMemorizationBody,
        ),
      ],
      GuideTopic.wordMeanings => [
        single(
          AppIcons.books,
          l10n.guideWordMeaningsTitle,
          l10n.guideWordMeaningsBody,
        ),
      ],
      GuideTopic.notes => [
        single(AppIcons.notePencil, l10n.guideNotesTitle, l10n.guideNotesBody),
      ],
      GuideTopic.search => [
        single(
          AppIcons.magnifyingGlass,
          l10n.guideSearchTitle,
          l10n.guideSearchBody,
        ),
      ],
      GuideTopic.books => [
        single(
          AppIcons.bookOpenTextFill,
          l10n.guideBooksTitle,
          l10n.guideBooksBody,
        ),
      ],
      GuideTopic.duas => [
        single(AppIcons.handHeartFill, l10n.guideDuasTitle, l10n.guideDuasBody),
      ],
      GuideTopic.tasbeeh => [
        single(
          AppIcons.sparkleFill,
          l10n.guideTasbeehTitle,
          l10n.guideTasbeehBody,
        ),
      ],
      GuideTopic.journey => [
        _GuideStep(
          (t) => JourneyScene(t: t),
          l10n.guideJourneyTitle,
          l10n.guideJourneyBody,
        ),
      ],
      GuideTopic.reminders => [
        single(
          AppIcons.bellRingingFill,
          l10n.guideRemindersTitle,
          l10n.guideRemindersBody,
        ),
      ],
      GuideTopic.qibla => [
        single(AppIcons.compassFill, l10n.guideQiblaTitle, l10n.guideQiblaBody),
      ],
      GuideTopic.backup => [
        single(
          AppIcons.cloudArrowUp,
          l10n.guideBackupTitle,
          l10n.guideBackupBody,
        ),
      ],
    };
  }
}

/// زر الشرح (ⓘ) في رأس القسم؛ ويعرض الشرح وحده عند أول دخول.
class GuideButton extends StatefulWidget {
  final GuideTopic topic;

  const GuideButton({super.key, required this.topic});

  @override
  State<GuideButton> createState() => _GuideButtonState();
}

class _GuideButtonState extends State<GuideButton> {
  @override
  void initState() {
    super.initState();
    SectionGuide.showOnce(context, widget.topic);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.guideButton,
      icon: const Icon(AppIcons.info),
      onPressed: () {
        HapticFeedback.selectionClick();
        SectionGuide.show(context, widget.topic);
      },
    );
  }
}

/// يعرض الشرح عند أول دخول في قسم لا رأس له (مثل المصحف).
class GuideAutoShow extends StatefulWidget {
  final GuideTopic topic;

  const GuideAutoShow({super.key, required this.topic});

  @override
  State<GuideAutoShow> createState() => _GuideAutoShowState();
}

class _GuideAutoShowState extends State<GuideAutoShow> {
  @override
  void initState() {
    super.initState();
    SectionGuide.showOnce(context, widget.topic);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _GuideSheet extends StatefulWidget {
  final List<_GuideStep> steps;

  const _GuideSheet({required this.steps});

  @override
  State<_GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<_GuideSheet> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index >= widget.steps.length - 1) {
      Navigator.pop(context);
      return;
    }
    _pages.nextPage(
      duration: AppMotion.duration(context, const Duration(milliseconds: 380)),
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = widget.steps;
    final gold = AppColors.accentGold(context);
    final height = MediaQuery.sizeOf(context).height;
    final last = _index == steps.length - 1;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: SafeArea(
        child: SizedBox(
          height: (height * 0.72).clamp(420.0, 620.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => CustomScrollView(
                    // النص الكبير يطول، فتُمرّر الخطوة بدل أن تفيض.
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 420,
                                    ),
                                    child: SceneStory(
                                      playing: i == _index,
                                      duration: const Duration(
                                        milliseconds: 5200,
                                      ),
                                      builder: (context, t) =>
                                          steps[i].scene(t),
                                    ),
                                  ),
                                ),
                              ),
                              if (steps.length > 1)
                                Text(
                                  l10n.guideStep(i + 1, steps.length),
                                  style: TextStyle(
                                    fontFamily: AppTheme.appFontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: gold,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                steps[i].title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                steps[i].body,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.appFontFamily,
                                  fontSize: 14.5,
                                  height: 1.6,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (steps.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        AnimatedContainer(
                          duration: AppMotion.duration(context, AppMotion.slow),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? gold
                                : gold.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(
                      last ? l10n.tourGotIt : l10n.tourNext,
                      style: const TextStyle(
                        fontFamily: AppTheme.appFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

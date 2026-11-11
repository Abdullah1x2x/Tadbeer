import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../core/design_system/design_system.dart';
import '../core/motion/app_motion.dart';
import '../features/duas/screens/duas_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/onboarding/tour/home_walkthrough.dart';
import '../features/quran/screens/quran_screen.dart';
import '../features/quran/widgets/ayah_rosette.dart';
import '../features/reminders/startup_permissions.dart';
import '../features/tasbeeh/tasbeeh_screen.dart';
import '../features/updates/app_update_dialog.dart';
import '../features/updates/app_update_service.dart';
import 'app.dart';
import 'localization.dart';
import '../core/design_system/app_icons.dart';

enum ShellTab { home, quran, tasbeeh, duas, more }

/// الهيكل الرئيسي: الأقسام متجاورة خلف شريط التنقل السفلي.
///
/// كل تبويب يُبنى عند أول زيارة ثم يُحفظ بحالته. ويختفي الشريط أثناء قراءة
/// المصحف، ويعود بالنقر على الصفحة.
class MainShell extends StatefulWidget {
  final ShellTab initialTab;

  const MainShell({super.key, this.initialTab = ShellTab.home});

  /// هل الهيكل معروض الآن؛ لا يكون كذلك أثناء شاشة الترحيب.
  static bool get isMounted => _mountedCount > 0;
  static int _mountedCount = 0;

  /// طلبات التبويب من خارج الواجهة، كالنقر على إشعار.
  static final ValueNotifier<ShellTab?> requestedTab = ValueNotifier(null);

  /// يعرض [tab] لطلب آتٍ من خارج الشاشات (إشعار أو ودجت)، ويغلق ما فوق الهيكل.
  ///
  /// يعيد الـ navigator، أو null قبل بناء التطبيق.
  static NavigatorState? showFromOutside(ShellTab tab) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return null;
    navigator.popUntil((route) => route.isFirst);
    if (isMounted) {
      requestedTab.value = tab;
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(initialTab: tab)),
      );
    }
    return navigator;
  }

  /// ينتقل إلى [tab] إن كان [context] داخل الهيكل، وإلا يعيد false ليفتح
  /// المستدعي صفحة بدلها.
  static bool selectTab(BuildContext context, ShellTab tab) {
    // يُستدعى من معالجات النقر، فلا يسجّل اعتماداً على الـ InheritedWidget.
    final scope = context.getInheritedWidgetOfExactType<_ShellScope>();
    if (scope == null) return false;
    scope.select(tab);
    return true;
  }

  /// خطاف اختباري لتتبع الفحص التلقائي في الاختبارات دون اتصال خارجي.
  @visibleForTesting
  static Future<void> Function(BuildContext)? silentUpdateCheckForTesting;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late ShellTab _tab = widget.initialTab;
  late final Set<ShellTab> _visited = {widget.initialTab};

  Timer? _updateTimer;
  bool _startupDone = false;

  @override
  void initState() {
    super.initState();
    MainShell._mountedCount++;
    MainShell.requestedTab.addListener(_onTabRequested);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_runStartupFlow());
      }
    });
  }

  /// يعرض الأذونات والدليل أولاً، ثم يبدأ الفحص التلقائي للتحديثات.
  Future<void> _runStartupFlow() async {
    await _welcome();
    if (!mounted) return;
    _startupDone = true;
    _scheduleSilentUpdateCheck(const Duration(seconds: 3));
  }

  void _scheduleSilentUpdateCheck(Duration delay) {
    final testHook = MainShell.silentUpdateCheckForTesting;
    if (Platform.environment.containsKey('FLUTTER_TEST') && testHook == null) {
      return;
    }
    _updateTimer?.cancel();
    _updateTimer = Timer(delay, () {
      if (!mounted) return;
      if (testHook != null) {
        unawaited(testHook(context));
      } else {
        unawaited(
          AppUpdateService.instance.checkForUpdates(
            context,
            showFeedback: false,
          ),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _startupDone && mounted) {
      _scheduleSilentUpdateCheck(const Duration(seconds: 1));
    }
  }

  /// الأذونات أولاً، ثم دليل الرئيسية لمن وصلها أول مرة.
  Future<void> _welcome() async {
    await StartupPermissions.askOnce(context);
    if (!mounted || _tab != ShellTab.home) return;
    await HomeWalkthrough.showOnce(context);
  }

  void _onTabRequested() {
    final tab = MainShell.requestedTab.value;
    if (tab == null) return;
    MainShell.requestedTab.value = null;
    _select(tab);
  }

  /// يعكس ظهور أدوات المصحف؛ يختفي الشريط باختفائها.
  final ValueNotifier<bool> _quranControlsVisible = ValueNotifier(true);

  /// يحرّك انزلاق التبويب القادم وتلاشي الستار عنه.
  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late final CurvedAnimation _eased = CurvedAnimation(
    parent: _switch,
    curve: Curves.easeOutCubic,
  );

  /// اتجاه دخول التبويب: 1 من اليمين، و-1 من اليسار.
  double _travel = 1;

  @override
  void dispose() {
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MainShell._mountedCount--;
    MainShell.requestedTab.removeListener(_onTabRequested);
    _eased.dispose();
    _switch.dispose();
    _quranControlsVisible.dispose();
    super.dispose();
  }

  Widget _buildTab(ShellTab tab) {
    switch (tab) {
      case ShellTab.home:
        return const HomeScreen();
      case ShellTab.quran:
        return QuranScreen(controlsVisible: _quranControlsVisible);
      case ShellTab.tasbeeh:
        return const TasbeehScreen();
      case ShellTab.duas:
        return const DuasScreen();
      case ShellTab.more:
        return const MoreScreen();
    }
  }

  void _select(ShellTab tab) {
    if (tab == _tab) return;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // في RTL تقع التبويبات اللاحقة يساراً، فتدخل الصفحة من جهة التبويب الذي
    // اتجه إليه المستخدم.
    final forward = tab.index > _tab.index;
    setState(() {
      _travel = (forward ? 1.0 : -1.0) * (isRtl ? -1.0 : 1.0);
      _tab = tab;
      _visited.add(tab);
    });
    if (AppMotion.shouldAnimate(context)) {
      _switch.forward(from: 0);
    } else {
      _switch.value = 1;
    }
  }

  /// كل تبويب يبقى في نفس سلسلة الأغلفة، فالتبديل يغيّر المعاملات فقط ولا يعيد
  /// بناء حالته.
  ///
  /// يمر التبديل عبر لون الخلفية: القديم يختفي فوراً، والجديد ينزلق تحت ستار
  /// بلون الخلفية يتلاشى. تلاشي لون واحد شبه مجاني، أما تلاشي صفحات كاملة فكان
  /// يعيد رسمها كل إطار.
  Widget _tabLayer(ShellTab tab) {
    final isCurrent = tab == _tab;
    final position = isCurrent
        ? Tween(
            begin: Offset(0.06 * _travel, 0),
            end: Offset.zero,
          ).animate(_eased)
        : const AlwaysStoppedAnimation(Offset.zero);

    return Offstage(
      // المفتاح يحفظ حالة التبويبات عند إدراج تبويب جديد.
      key: ValueKey(tab),
      offstage: !isCurrent,
      child: TickerMode(
        enabled: isCurrent,
        child: IgnorePointer(
          ignoring: !isCurrent,
          child: SlideTransition(
            position: position,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(child: _buildTab(tab)),
                IgnorePointer(
                  child: FadeTransition(
                    opacity: ReverseAnimation(_eased),
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final items = [
      FloatingNavItem(
        key: HomeWalkthrough.homeTab,
        icon: AppIcons.house,
        selectedIcon: AppIcons.houseFill,
        label: l10n.home,
      ),
      FloatingNavItem(
        icon: AppIcons.bookOpen,
        selectedIcon: AppIcons.bookOpenFill,
        label: l10n.mushaf,
      ),
      FloatingNavItem(
        // السبحة، حتى لا يشبه تبويب الأدعية.
        icon: FlutterIslamicIcons.tasbih2,
        selectedIcon: FlutterIslamicIcons.solidTasbih2,
        label: l10n.istighfar,
      ),
      FloatingNavItem(
        icon: AppIcons.handHeart,
        selectedIcon: AppIcons.handHeartFill,
        label: l10n.duas,
      ),
      FloatingNavItem(
        key: HomeWalkthrough.moreTab,
        icon: AppIcons.squaresFour,
        selectedIcon: AppIcons.squaresFourFill,
        label: l10n.more,
      ),
    ];

    return _ShellScope(
      select: _select,
      child: PopScope(
        // الرجوع من أي تبويب يعود إلى الرئيسية قبل مغادرة التطبيق.
        canPop: _tab == ShellTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // وردة إجراءات الآية المفتوحة تُغلق أولاً.
          if (AyahRosette.dismissIfOpen()) return;
          _select(ShellTab.home);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          // المصحف يأخذ الشاشة كاملة دائماً، فلا يتغير حجم خطه بظهور الشريط.
          extendBody: _tab == ShellTab.quran,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _tab == ShellTab.quran
                ? null
                : (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 200) return;
                    final isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    final forward = isRtl ? velocity > 0 : velocity < 0;
                    final nextIndex = forward ? _tab.index + 1 : _tab.index - 1;
                    if (nextIndex >= 0 && nextIndex < ShellTab.values.length) {
                      _select(ShellTab.values[nextIndex]);
                    }
                  },
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final tab in ShellTab.values)
                  if (_visited.contains(tab)) _tabLayer(tab),
              ],
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _quranControlsVisible,
            builder: (context, controlsVisible, bar) {
              final hidden = _tab == ShellTab.quran && !controlsVisible;
              // يتلاشى دون حركة رأسية.
              return IgnorePointer(
                ignoring: hidden,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: hidden ? 0 : 1),
                  duration: AppMotion.duration(context, AppMotion.chrome),
                  curve: Curves.easeInOut,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: child,
                  ),
                  child: bar,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _UpdateDownloadFloatingBanner(),
                FloatingNavBar(
                  items: items,
                  selectedIndex: _tab.index,
                  onSelected: (i) => _select(ShellTab.values[i]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط عائم مصغر يظهر فوق شريط التنقل لمتابعة تقدم تنزيل التحديث في الخلفية.
class _UpdateDownloadFloatingBanner extends StatelessWidget {
  const _UpdateDownloadFloatingBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppUpdateService.instance.isDialogVisible,
      builder: (context, isDialogVisible, _) {
        if (isDialogVisible) return const SizedBox.shrink();

        return ValueListenableBuilder<UpdateDownloadState>(
          valueListenable: AppUpdateService.instance.downloadState,
          builder: (context, state, _) {
            if (state.isIdle || state.isError) {
              return const SizedBox.shrink();
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primary = Theme.of(context).colorScheme.primary;

            if (state.isDownloading && state.updateInfo != null) {
              final percent = (state.progress != null)
                  ? (state.progress!.progress * 100).toInt()
                  : 0;
              final progressVal = state.progress?.progress;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222A) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progressVal,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.downloadingUpdate,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              minHeight: 4,
                              backgroundColor: primary.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        AppUpdateDialog.show(context, state.updateInfo!);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.l10n.viewAction,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        AppUpdateService.instance.cancelDownload();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          AppIcons.x,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.isCompleted &&
                state.targetFile != null &&
                state.updateInfo != null) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222A) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.checkCircleFill,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.updateDownloadedReadyToInstall,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        AppUpdateService.instance.installCurrentDownloadedApk();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.l10n.installAction,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        AppUpdateService.instance.cancelDownload();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          AppIcons.x,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

/// يتيح للأبناء تبديل التبويب دون الاحتفاظ بمرجع للهيكل.
class _ShellScope extends InheritedWidget {
  final ValueChanged<ShellTab> select;

  const _ShellScope({required this.select, required super.child});

  @override
  bool updateShouldNotify(_ShellScope oldWidget) => false;
}

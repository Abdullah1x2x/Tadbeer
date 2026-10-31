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

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late ShellTab _tab = widget.initialTab;
  late final Set<ShellTab> _visited = {widget.initialTab};

  @override
  void initState() {
    super.initState();
    MainShell._mountedCount++;
    MainShell.requestedTab.addListener(_onTabRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _welcome();
    });
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
          // المصحف يأخذ الشاشة كاملة دائماً، فلا يتغير حجم خطه بظهور الشريط.
          extendBody: _tab == ShellTab.quran,
          body: Stack(
            fit: StackFit.expand,
            children: [
              for (final tab in ShellTab.values)
                if (_visited.contains(tab)) _tabLayer(tab),
            ],
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _quranControlsVisible,
            builder: (context, controlsVisible, bar) {
              final hidden = _tab == ShellTab.quran && !controlsVisible;
              // ينزلق ويتلاشى دون أن يتغير ارتفاعه.
              return IgnorePointer(
                ignoring: hidden,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: hidden ? 0 : 1),
                  duration: AppMotion.duration(context, AppMotion.slow),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 96 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: bar,
                ),
              );
            },
            child: FloatingNavBar(
              items: items,
              selectedIndex: _tab.index,
              onSelected: (i) => _select(ShellTab.values[i]),
            ),
          ),
        ),
      ),
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

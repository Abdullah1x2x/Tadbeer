import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../core/design_system/design_system.dart';
import '../core/motion/app_motion.dart';
import '../features/duas/duas_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/quran/screens/quran_screen.dart';
import '../features/tasbeeh/tasbeeh_screen.dart';
import 'app.dart';
import 'localization.dart';
import '../core/design_system/app_icons.dart';

/// تبويبات الشريط السفلي بترتيب ظهورها.
enum ShellTab { home, quran, tasbeeh, duas, more }

/// الهيكل الرئيسي للتطبيق مع شريط التنقل السفلي.
///
/// The main sections sit side by side behind a bottom [NavigationBar], so the
/// reader can move between the Mushaf, Istighfar and Duas in one tap. Tabs are
/// built lazily on first visit and kept alive afterwards to preserve their
/// state. While the Mushaf tab is being read the bar slides away, and it
/// returns when the reader taps the page to show the Mushaf controls.
class MainShell extends StatefulWidget {
  /// التبويب الذي يفتح عليه الهيكل.
  final ShellTab initialTab;

  /// ينشئ الهيكل الرئيسي للتطبيق.
  const MainShell({super.key, this.initialTab = ShellTab.home});

  /// Whether a shell is currently mounted (false while the intro shows).
  static bool get isMounted => _mountedCount > 0;
  static int _mountedCount = 0;

  /// Tab requests from outside the widget tree (e.g. a tapped notification).
  static final ValueNotifier<ShellTab?> requestedTab = ValueNotifier(null);

  /// Shows [tab] when the request comes from outside the app's screens (a
  /// notification or the home-screen widget), closing any page above the
  /// shell. Returns the app's navigator, or null before the app is built.
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

  /// Switches to [tab] when [context] is inside the shell. Returns false
  /// otherwise (e.g. a screen shown on its own), so callers can fall back to
  /// pushing a page.
  static bool selectTab(BuildContext context, ShellTab tab) {
    // Called from tap handlers, so look up without registering a dependency.
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
  }

  void _onTabRequested() {
    final tab = MainShell.requestedTab.value;
    if (tab == null) return;
    MainShell.requestedTab.value = null;
    _select(tab);
  }

  /// Mirrors the Mushaf tab's controls; the bar hides while they are hidden.
  final ValueNotifier<bool> _quranControlsVisible = ValueNotifier(true);

  /// Drives the incoming tab's slide and the veil fading off it.
  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late final CurvedAnimation _eased = CurvedAnimation(
    parent: _switch,
    curve: Curves.easeOutCubic,
  );

  /// +1 when the incoming tab enters from the right, -1 from the left.
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
    // Tabs further along the bar sit to the left in RTL, so the new page
    // slides in from the side of the tab the user moved toward.
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

  /// Every visited tab keeps the same wrapper chain, so switching only changes
  /// parameters and never rebuilds a tab's state.
  ///
  /// The switch fades through the page colour: the outgoing tab goes at once
  /// and the incoming one slides in under a veil of the background colour
  /// that fades away. Fading one flat colour is nearly free, where fading
  /// whole pages made every frame redraw them off-screen.
  Widget _tabLayer(ShellTab tab) {
    final isCurrent = tab == _tab;
    final position = isCurrent
        ? Tween(
            begin: Offset(0.06 * _travel, 0),
            end: Offset.zero,
          ).animate(_eased)
        : const AlwaysStoppedAnimation(Offset.zero);

    return Offstage(
      // Keyed so tabs keep their state when a newly visited tab is inserted.
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
        icon: AppIcons.house,
        selectedIcon: AppIcons.houseFill,
        label: l10n.home,
      ),
      FloatingNavItem(
        icon: AppIcons.bookOpen,
        selectedIcon: AppIcons.bookOpenFill,
        label: l10n.isArabic ? 'المصحف' : 'Mushaf',
      ),
      FloatingNavItem(
        // Prayer beads, so it never looks like the duas tab.
        icon: FlutterIslamicIcons.tasbih2,
        selectedIcon: FlutterIslamicIcons.solidTasbih2,
        label: l10n.isArabic ? 'الاستغفار' : 'Istighfar',
      ),
      FloatingNavItem(
        icon: AppIcons.handHeart,
        selectedIcon: AppIcons.handHeartFill,
        label: l10n.duas,
      ),
      FloatingNavItem(
        icon: AppIcons.squaresFour,
        selectedIcon: AppIcons.squaresFourFill,
        label: l10n.more,
      ),
    ];

    return _ShellScope(
      select: _select,
      child: PopScope(
        // Back from any other tab returns to Home before leaving the app.
        canPop: _tab == ShellTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _select(ShellTab.home);
        },
        child: Scaffold(
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
              // Slides down and fades while collapsing, so reading the
              // Mushaf gets the full screen.
              return TweenAnimationBuilder<double>(
                tween: Tween(end: hidden ? 0 : 1),
                duration: AppMotion.duration(context, AppMotion.slow),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: t,
                    child: Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - t)),
                        child: child,
                      ),
                    ),
                  ),
                ),
                child: bar,
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

/// Lets descendants switch tabs without holding a reference to the shell.
class _ShellScope extends InheritedWidget {
  final ValueChanged<ShellTab> select;

  const _ShellScope({required this.select, required super.child});

  @override
  bool updateShouldNotify(_ShellScope oldWidget) => false;
}

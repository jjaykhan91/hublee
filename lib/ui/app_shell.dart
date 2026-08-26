/// The root shell widget that wraps all bottom-navigation tabs.
///
/// Uses [StatefulNavigationShell] from go_router to keep each tab's
/// navigation stack alive independently so the user can switch tabs
/// without losing scroll position or page history.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/app_haptics.dart';
import 'widgets/hublee_nav_icons.dart';
import 'widgets/reading_width.dart';

const _destinations = <({String label, Widget icon, Widget selected})>[
  (
    label: 'Home',
    icon: HubleeNavIcon(kind: HubleeNavKind.home),
    selected: HubleeNavIcon(kind: HubleeNavKind.home, filled: true),
  ),
  (
    label: 'Quran',
    icon: HubleeNavIcon(kind: HubleeNavKind.quran),
    selected: HubleeNavIcon(kind: HubleeNavKind.quran, filled: true),
  ),
  (
    label: 'Hadith',
    icon: HubleeNavIcon(kind: HubleeNavKind.hadith),
    selected: HubleeNavIcon(kind: HubleeNavKind.hadith, filled: true),
  ),
  (
    label: 'Learn',
    icon: HubleeNavIcon(kind: HubleeNavKind.learn),
    selected: HubleeNavIcon(kind: HubleeNavKind.learn, filled: true),
  ),
  (
    label: 'Saved',
    icon: Icon(Icons.bookmark_outline_rounded),
    selected: Icon(Icons.bookmark_rounded),
  ),
  (
    label: 'Settings',
    icon: Icon(Icons.settings_outlined),
    selected: Icon(Icons.settings_rounded),
  ),
];

/// Persistent navigation scaffold.
///
/// Phone and open foldables: 6-tab [NavigationBar]. Wide windows
/// without a fold: [NavigationRail] and a capped reading column.
class AppShell extends StatelessWidget {
  /// The shell that manages the active tab body and branch state.
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _select(int index) {
    AppHaptics.selection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final wide = ReadingLayout.useRail(
      size,
      displayFeatures: MediaQuery.displayFeaturesOf(context),
    );
    final compactBar = ReadingLayout.compactChrome(size);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.selected,
              backgroundColor: isDark
                  ? const Color(0xFF0B0F14)
                  : colorScheme.surface,
              destinations: [
                for (final dest in _destinations)
                  NavigationRailDestination(
                    icon: dest.icon,
                    selectedIcon: dest.selected,
                    label: Text(dest.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: ConstrainedReadingBody(
                child: SafeArea(top: false, child: navigationShell),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(top: false, child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _select,
        backgroundColor: isDark ? const Color(0xFF0B0F14) : colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelBehavior: compactBar
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
        destinations: [
          for (final dest in _destinations)
            NavigationDestination(
              icon: dest.icon,
              selectedIcon: dest.selected,
              label: dest.label,
            ),
        ],
      ),
    );
  }
}

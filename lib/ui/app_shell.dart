/// The root shell widget that wraps all bottom-navigation tabs.
///
/// Uses [StatefulNavigationShell] from go_router to keep each tab's
/// navigation stack alive independently so the user can switch tabs
/// without losing scroll position or page history.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';
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
    final size = MediaQuery.sizeOf(context);
    final wide = ReadingLayout.useRail(
      size,
      displayFeatures: MediaQuery.displayFeaturesOf(context),
    );
    // Six tabs still fit their labels from 360 dp (about 60 dp each), and
    // icons like Learn's book shelf are ambiguous on their own.
    final compactBar = size.width < 360;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final dest in _destinations)
                  NavigationRailDestination(
                    icon: dest.icon,
                    selectedIcon: dest.selected,
                    label: Text(dest.label),
                  ),
              ],
            ),
            const VerticalDivider(width: AppStroke.hairline),
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
      // Colours, indicator and height come from the theme; the hairline
      // is what separates the flat bar from the page.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: AppStroke.hairline),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _select,
            labelBehavior: compactBar
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final dest in _destinations)
                NavigationDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selected,
                  label: dest.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

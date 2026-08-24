/// The root shell widget that wraps all bottom-navigation tabs.
///
/// Uses [StatefulNavigationShell] from go_router to keep each tab's
/// navigation stack alive independently so the user can switch tabs
/// without losing scroll position or page history.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/app_haptics.dart';
import 'widgets/reading_width.dart';

const _destinations = <({IconData icon, IconData selected, String label})>[
  (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Home'),
  (
    icon: Icons.menu_book_outlined,
    selected: Icons.menu_book_rounded,
    label: 'Quran',
  ),
  (
    icon: Icons.library_books_outlined,
    selected: Icons.library_books_rounded,
    label: 'Hadith',
  ),
  (icon: Icons.school_outlined, selected: Icons.school_rounded, label: 'Learn'),
  (
    icon: Icons.bookmark_outline_rounded,
    selected: Icons.bookmark_rounded,
    label: 'Saved',
  ),
  (
    icon: Icons.settings_outlined,
    selected: Icons.settings_rounded,
    label: 'Settings',
  ),
];

/// Persistent navigation scaffold.
///
/// Phone: 6-tab [NavigationBar]. Wide windows: [NavigationRail] and a
/// capped reading column.
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
    final wide = ReadingLayout.useRail(MediaQuery.sizeOf(context).width);

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
                    icon: Icon(dest.icon),
                    selectedIcon: Icon(dest.selected),
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
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
        destinations: [
          for (final dest in _destinations)
            NavigationDestination(
              icon: Icon(dest.icon),
              selectedIcon: Icon(dest.selected),
              label: dest.label,
            ),
        ],
      ),
    );
  }
}

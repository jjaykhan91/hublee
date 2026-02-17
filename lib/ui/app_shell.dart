/// The root shell widget that wraps all bottom-navigation tabs.
///
/// Uses [StatefulNavigationShell] from go_router to keep each tab's
/// navigation stack alive independently so the user can switch tabs
/// without losing scroll position or page history.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent bottom-navigation scaffold.
///
/// Receives the [navigationShell] from `StatefulShellRoute` and
/// renders a 5-tab [NavigationBar] (Home, Quran, Hadith, Bookmarks,
/// Settings).
class AppShell extends StatelessWidget {
  /// The shell that manages the active tab body and branch state.
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // When the user taps the already-active tab, go back to
          // the initial location of that branch.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: isDark ? const Color(0xFF0B0F14) : colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Quran',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Hadith',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Defines all application routes using go_router.
///
/// Uses [StatefulShellRoute.indexedStack] for bottom navigation with
/// 5 tabs (Home, Quran, Hadith, Bookmarks, Settings). Detail pages
/// like surah reading and hadith reading push full-screen above the
/// shell so the bottom nav bar is hidden during focused reading.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/app_shell.dart';
import 'ui/home_page.dart';
import 'ui/quran_page.dart';
import 'ui/surah_reader_page.dart';
import 'ui/hadith_page.dart';
import 'ui/hadith_reader_page.dart';
import 'ui/global_search_page.dart';
import 'ui/bookmarks_page.dart';
import 'ui/settings_page.dart';
import 'ui/tajweed_guide_page.dart';
import 'router_paths.dart';
import 'ui/splash_page.dart';
import 'ui/route_error_page.dart';
import 'ui/diagnostics_page.dart';

/// Navigator key for the root (full-screen) navigator.
/// Used by detail pages that should push above the shell.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The application's router configuration.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoute.splash,
  errorBuilder: (context, state) => RouteErrorPage(
    message: state.error?.toString() ?? "That link isn't valid.",
  ),
  routes: [
    // ── Splash (preload, then [AppRoute.home]) ────────────────────
    GoRoute(
      path: AppRoute.splash,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashPage(),
    ),

    // ── Bottom navigation shell ──────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),

        // Tab 1: Quran (surah list)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quran',
              builder: (context, state) => const QuranPage(),
              routes: [
                // Full-screen surah reading view
                GoRoute(
                  path: ':surahId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final surahId = AppRoute.tryParseSurahId(
                      state.pathParameters['surahId'],
                    );
                    if (surahId == null) {
                      return const RouteErrorPage(message: 'Surah not found');
                    }
                    final scrollToAyah = state.uri.queryParameters['ayah'];
                    return SurahReaderPage(
                      surahId: surahId,
                      scrollToAyah: scrollToAyah != null
                          ? int.tryParse(scrollToAyah)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 2: Hadith (all books from all collections)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/hadith',
              builder: (context, state) => const HadithPage(),
              routes: [
                // Full-screen hadith book reading view
                // Path: /hadith/:collectionId/:bookFile
                GoRoute(
                  path: ':collectionId/:bookFile',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final collectionId = state.pathParameters['collectionId']!;
                    final bookFile = state.pathParameters['bookFile']!;
                    final title =
                        state.uri.queryParameters['title'] ?? bookFile;
                    final scrollToIndex = state.uri.queryParameters['index'];
                    return HadithReaderPage(
                      collectionId: collectionId,
                      bookFile: bookFile,
                      title: title,
                      scrollToIndex: scrollToIndex != null
                          ? int.tryParse(scrollToIndex)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Bookmarks
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookmarks',
              builder: (context, state) => const BookmarksPage(),
            ),
          ],
        ),

        // Tab 4: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // ── Full-screen routes (no bottom nav) ───────────────────────
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: AppRoute.tajweedGuide,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TajweedGuidePage(),
    ),
    GoRoute(
      path: AppRoute.diagnostics,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DiagnosticsPage(),
    ),
  ],
);

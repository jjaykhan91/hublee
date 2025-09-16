import 'package:flutter/material.dart';
import '../../services/app_scope.dart';
import 'settings_drawer.dart';

/// A drop-in replacement for Scaffold that ALWAYS provides:
/// - an endDrawer with SettingsDrawer (half-width),
/// - a consistent settings icon in the AppBar that opens the drawer,
/// - a transparent scrim so the page stays visible while adjusting settings.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  /// Quick title without building a custom AppBar.
  final String? titleText;
  /// Optional leading widget for the AppBar.
  final Widget? leading;
  /// Extra actions next to the settings gear.
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
    this.titleText,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final toggleTheme = AppScope.of(context).toggleTheme;

    // Builder for the consistent settings icon
    Widget buildSettingsIcon(BuildContext ctx) {
      return IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.settings_rounded),
        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
      );
    }

    // If no custom AppBar provided, build a default one with consistent gear.
    PreferredSizeWidget resolvedAppBar = appBar ??
        AppBar(
          title: Text(titleText ?? ''),
          leading: leading,
          actions: [
            ...?actions,
            Builder(builder: buildSettingsIcon),
          ],
        );

    // If caller provided a custom AppBar, we still inject the gear icon.
    if (appBar != null && appBar is AppBar) {
      final AppBar custom = appBar as AppBar;
      resolvedAppBar = AppBar(
        title: custom.title,
        leading: custom.leading ?? leading,
        automaticallyImplyLeading: custom.automaticallyImplyLeading,
        backgroundColor: custom.backgroundColor,
        elevation: custom.elevation,
        centerTitle: custom.centerTitle,
        actions: [
          ...?custom.actions,
          ...?actions,
          Builder(builder: buildSettingsIcon), // 👈 always add gear
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,

      // 👇 Transparent scrim so content stays visible behind the drawer
      drawerScrimColor: Colors.transparent,

      // 👇 Always include the Settings drawer everywhere
      endDrawer: SettingsDrawer(onToggleTheme: toggleTheme),
      endDrawerEnableOpenDragGesture: true,

      appBar: resolvedAppBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
    );
  }
}

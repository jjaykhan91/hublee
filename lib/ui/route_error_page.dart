/// Fallback page shown when a route cannot be resolved.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import 'widgets/spot_art.dart';

/// Explains that the requested path is invalid and offers a way home.
class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key, this.message});

  /// Optional extra detail (unknown path, out-of-range surah, etc.).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpotIllustration(SpotArt.notFound),
              const SizedBox(height: 16),
              Text(
                message ?? "That link isn't valid.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoute.home),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact debug chip showing the latest timing; opens Diagnostics.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../router_paths.dart';
import '../../services/app_metrics.dart';
import '../../theme/app_tokens.dart';

/// Hidden in release, and until turned on in Diagnostics. Tap to open
/// the full metrics log.
class MetricsHud extends StatelessWidget {
  const MetricsHud({super.key, this.router});

  /// Router that opens Diagnostics; the app's [appRouter] when null.
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: AppMetrics.instance,
      builder: (context, _) {
        final metrics = AppMetrics.instance;
        if (!metrics.hudEnabled) return const SizedBox.shrink();
        final last = metrics.lastTiming;
        final errors = metrics.errorCount;
        final label = [
          last == null ? 'Metrics' : '${last.name} ${last.milliseconds} ms',
          if (errors > 0) '$errors error${errors == 1 ? '' : 's'}',
        ].join(' · ');
        final colorScheme = Theme.of(context).colorScheme;
        final foreground = errors > 0
            ? colorScheme.onError
            : colorScheme.onInverseSurface;

        // A developer aid: keep it out of the screen-reader tree.
        return ExcludeSemantics(
          child: Material(
            color: errors > 0
                ? colorScheme.error.withValues(alpha: 0.92)
                : colorScheme.inverseSurface.withValues(alpha: 0.92),
            borderRadius: AppRadius.chip,
            child: InkWell(
              borderRadius: AppRadius.chip,
              // The chip sits above the router in MaterialApp.builder, so
              // there is no GoRouter in this context; use the router itself.
              onTap: () => (router ?? appRouter).push(AppRoute.diagnostics),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      errors > 0
                          ? Icons.error_outline_rounded
                          : Icons.speed_rounded,
                      size: 16,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

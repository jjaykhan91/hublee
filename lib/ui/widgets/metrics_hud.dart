/// Compact debug chip showing the latest timing; opens Diagnostics.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router_paths.dart';
import '../../services/app_metrics.dart';
import '../../theme/app_tokens.dart';

/// Hidden in release. Tap to open the full metrics log.
class MetricsHud extends StatelessWidget {
  const MetricsHud({super.key});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: AppMetrics.instance,
      builder: (context, _) {
        final last = AppMetrics.instance.lastTiming;
        final label = last == null
            ? 'Metrics'
            : '${last.name} ${last.milliseconds} ms';
        final colorScheme = Theme.of(context).colorScheme;

        return Material(
          color: colorScheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: AppRadius.chip,
          child: InkWell(
            borderRadius: AppRadius.chip,
            onTap: () => context.push(AppRoute.diagnostics),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 16,
                    color: colorScheme.onInverseSurface,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

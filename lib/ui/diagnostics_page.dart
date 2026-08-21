/// Debug/profile screen for session timings, navigation, and jank.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_metrics.dart';
import '../theme/app_tokens.dart';

/// Lists recorded metrics and toggles the Flutter performance overlay.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    AppMetrics.instance.addListener(_refresh);
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    AppMetrics.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final last = metrics.lastTiming;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: metrics.clear,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            'Stays on this device. Use this screen to compare search, '
            'launch, and frame cost after a UI change.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Performance overlay'),
              subtitle: const Text(
                'Flutter graph of UI and raster thread time',
              ),
              value: metrics.overlayEnabled,
              onChanged: (value) {
                metrics.overlayEnabled = value;
                metrics.recordUi(
                  'performanceOverlay',
                  detail: {'on': '$value'},
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _MetricLine(
                  label: 'Last timing',
                  value: last == null ? '—' : '${last.milliseconds} ms',
                  caption: last?.name,
                ),
                const Divider(height: 1),
                _MetricLine(
                  label: 'Jank',
                  value: '${metrics.jankPercent.toStringAsFixed(1)}%',
                  caption:
                      '${metrics.jankCount} / ${metrics.frameCount} frames',
                ),
                const Divider(height: 1),
                _MetricLine(
                  label: 'Last build / raster',
                  value:
                      '${metrics.lastBuild.inMilliseconds} / '
                      '${metrics.lastRaster.inMilliseconds} ms',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent events',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (metrics.events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Open Search, switch tabs, or wait for splash — '
                'timings will show up here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ...metrics.events.map((event) => _EventTile(event: event)),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: caption == null ? null : Text(caption!),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final MetricEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (event.kind) {
      MetricKind.timing => Icons.timer_outlined,
      MetricKind.navigation => Icons.navigation_outlined,
      MetricKind.ui => Icons.tune_rounded,
    };
    final trailing = event.milliseconds != null
        ? '${event.milliseconds} ms'
        : _kindLabel(event.kind);

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(event.name),
        subtitle: Text(
          [
            TimeOfDay.fromDateTime(event.at).format(context),
            ...event.detail.entries.map((e) => '${e.key} ${e.value}'),
          ].join(' · '),
        ),
        trailing: Text(
          trailing,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static String _kindLabel(MetricKind kind) {
    return switch (kind) {
      MetricKind.timing => 'timing',
      MetricKind.navigation => 'nav',
      MetricKind.ui => 'ui',
    };
  }
}

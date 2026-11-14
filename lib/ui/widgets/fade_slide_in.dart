/// The one entrance animation: a short fade with a small slide.
///
/// Timing comes from [AppMotion]. When the system "remove animations"
/// setting is on, the child is shown in place at once.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Fades and slides [child] into place once, when it is first built.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.axis = Axis.vertical,
  }) : assert(index >= 0, 'index must not be negative');

  final Widget child;

  /// Position in a staggered group. Each step waits [AppMotion.stagger]
  /// longer, up to [AppMotion.staggerCap].
  final int index;

  /// Vertical rises from just below; horizontal slides in from the side.
  final Axis axis;

  /// How long the item at [index] waits before it starts.
  static Duration delayFor(int index) {
    final delay = AppMotion.stagger * index;
    return delay > AppMotion.staggerCap ? AppMotion.staggerCap : delay;
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // Fraction of the child's own size it travels.
  static const _rise = Offset(0, 0.04);
  static const _drift = Offset(0.03, 0);

  late final AnimationController _controller;
  late final CurvedAnimation _progress;
  late final Animation<Offset> _offset;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = FadeSlideIn.delayFor(widget.index);
    final total = delay + AppMotion.slow;
    _controller = AnimationController(vsync: this, duration: total);
    // The wait is part of the one animation, so no timer outlives the
    // widget.
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.curve,
      ),
    );
    _offset = Tween<Offset>(
      begin: widget.axis == Axis.vertical ? _rise : _drift,
      end: Offset.zero,
    ).animate(_progress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Shorthand: `Card(...).entrance(index: 2)`.
extension EntranceMotion on Widget {
  /// Wraps this widget in a [FadeSlideIn].
  Widget entrance({int index = 0, Axis axis = Axis.vertical}) {
    return FadeSlideIn(index: index, axis: axis, child: this);
  }
}

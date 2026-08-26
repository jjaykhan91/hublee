/// Overlay scrubber that appears while the reader is scrolling, then
/// hides so it does not keep a gutter of screen space.
///
/// Wrap your [ScrollablePositionedList] and this widget in a [Stack].
/// The overlay floats on the physical right edge; it is not visible
/// until the list moves or the user drags the thumb.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

const _kThumbSize = 36.0;
const _kTrackWidth = 20.0;
const _kHideAfter = Duration(milliseconds: 1400);

/// Overlay scrubber that sits on the right edge of the reader.
class ScrollScrubber extends StatefulWidget {
  /// Inset from the physical right edge of the stack.
  static const double edgeInset = 8;

  /// Width of the overlay hit area when visible.
  static const double overlayWidth = AppSpacing.minTouchTarget;

  /// Right padding readers reserve. The overlay floats, so this is a
  /// slim edge inset rather than a permanent column.
  static const double gutter = 12;

  /// Total number of scrollable items.
  final int itemCount;

  /// Builds a label string for the given 0-based index.
  final String Function(int index) labelBuilder;

  /// Controller to jump to items when the user drags.
  final ItemScrollController scrollController;

  /// Listener to track the current visible position.
  final ItemPositionsListener positionsListener;

  const ScrollScrubber({
    super.key,
    required this.itemCount,
    required this.labelBuilder,
    required this.scrollController,
    required this.positionsListener,
  });

  @override
  State<ScrollScrubber> createState() => _ScrollScrubberState();
}

class _ScrollScrubberState extends State<ScrollScrubber>
    with SingleTickerProviderStateMixin {
  double _position = 0.0;
  bool _isDragging = false;
  int _currentIndex = 0;
  var _seeded = false;
  var _shown = false;
  double? _lastLeading;
  int? _lastIndex;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    widget.positionsListener.itemPositions.addListener(_onPositionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _seeded) return;
      if (widget.positionsListener.itemPositions.value.isNotEmpty) {
        _onPositionsChanged();
      }
    });
  }

  @override
  void dispose() {
    widget.positionsListener.itemPositions.removeListener(_onPositionsChanged);
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPositionsChanged() {
    final positions = widget.positionsListener.itemPositions.value;
    if (_isDragging || positions.isEmpty) return;

    final sorted = positions.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topItem = sorted.first;
    final index = topItem.index.clamp(0, widget.itemCount - 1);
    final leading = topItem.itemLeadingEdge;

    if (widget.itemCount <= 1) return;
    final newPosition = index / (widget.itemCount - 1);

    if (!_seeded) {
      _seeded = true;
      _lastIndex = index;
      _lastLeading = leading;
      _position = newPosition.clamp(0.0, 1.0);
      _currentIndex = index;
      // First report after the user already moved (e.g. tests that
      // skip the idle layout tick) should still show the thumb.
      if (index > 0 || leading < -0.02) _reveal();
      return;
    }

    final moved =
        index != _lastIndex ||
        (leading - (_lastLeading ?? leading)).abs() > 0.002;
    _lastIndex = index;
    _lastLeading = leading;

    if (mounted) {
      setState(() {
        _position = newPosition.clamp(0.0, 1.0);
        _currentIndex = index;
      });
    }
    if (moved) _reveal();
  }

  void _reveal() {
    _hideTimer?.cancel();
    if (!_shown && mounted) setState(() => _shown = true);
    _fadeController.forward();
    _scheduleHide();
  }

  void _onDragStart(DragStartDetails details) {
    _hideTimer?.cancel();
    setState(() {
      _isDragging = true;
      _shown = true;
    });
    _fadeController.forward();
    _updatePositionFromGlobal(details.globalPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updatePositionFromGlobal(details.globalPosition);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _scheduleHide();
  }

  void _updatePositionFromGlobal(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final trackHeight = renderBox.size.height - _kThumbSize;
    if (trackHeight <= 0) return;

    final fraction = ((localPosition.dy - _kThumbSize / 2) / trackHeight).clamp(
      0.0,
      1.0,
    );
    final targetIndex = (fraction * (widget.itemCount - 1)).round().clamp(
      0,
      widget.itemCount - 1,
    );

    if (targetIndex != _currentIndex) {
      AppHaptics.selection();
    }

    setState(() {
      _position = fraction;
      _currentIndex = targetIndex;
    });

    if (widget.scrollController.isAttached) {
      widget.scrollController.jumpTo(index: targetIndex);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_isDragging) return;
    _hideTimer = Timer(_kHideAfter, () {
      if (!mounted || _isDragging) return;
      _fadeController.reverse().whenComplete(() {
        if (!mounted || _isDragging || _fadeController.value > 0) return;
        setState(() => _shown = false);
      });
    });
  }

  void _onTapDown(TapDownDetails details) {
    _hideTimer?.cancel();
    _fadeController.forward();
    _updatePositionFromGlobal(details.globalPosition);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final trackHeight = MediaQuery.of(context).size.height - _kThumbSize - 120;
    final thumbTop = _position * trackHeight.clamp(0.0, double.infinity);

    return Positioned(
      key: const Key('scroll-scrubber-overlay'),
      right: ScrollScrubber.edgeInset,
      top: 8,
      bottom: 8,
      width: ScrollScrubber.overlayWidth,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          final visible = _shown || _isDragging;
          return IgnorePointer(
            ignoring: !visible,
            child: Opacity(
              opacity: _isDragging ? 1 : _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Semantics(
          slider: true,
          label: 'Reading position',
          value: widget.labelBuilder(_currentIndex),
          child: GestureDetector(
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onTapDown: _onTapDown,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: _kTrackWidth / 2 - 1.5,
                  top: _kThumbSize / 2,
                  bottom: _kThumbSize / 2,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: _isDragging ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: thumbTop,
                  child: Container(
                    width: _kTrackWidth,
                    height: _kThumbSize,
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                Positioned(
                  right: _kTrackWidth + 8,
                  top: thumbTop + (_kThumbSize - 36) / 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppShadows.scrubber,
                    ),
                    child: Text(
                      widget.labelBuilder(_currentIndex),
                      style: TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

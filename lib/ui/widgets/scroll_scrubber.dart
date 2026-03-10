/// A vertical scroll position scrubber overlay for use with
/// [ScrollablePositionedList]. Shows a draggable thumb on the right
/// edge with a tooltip label indicating the current position.
///
/// Since [ScrollablePositionedList] uses [ItemScrollController]
/// instead of a standard [ScrollController], this widget listens
/// to [ItemPositionsListener] to track position and uses
/// [ItemScrollController.jumpTo] for navigation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../theme/app_tokens.dart';

/// Overlay scrubber that sits on the right edge of the reader.
///
/// Wrap your [ScrollablePositionedList] and this widget in a [Stack].
class ScrollScrubber extends StatefulWidget {
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
  /// Current position as a fraction [0.0, 1.0].
  double _position = 0.0;

  /// Whether the user is currently dragging.
  bool _isDragging = false;

  /// Current item index derived from position.
  int _currentIndex = 0;

  /// Controls the fade animation for the label tooltip.
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  /// Timer to auto-hide the label after inactivity.
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Listen to scroll positions to update the thumb.
    widget.positionsListener.itemPositions.addListener(_onPositionsChanged);
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

    // Find the topmost visible item.
    final sorted = positions.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topItem = sorted.first;
    final index = topItem.index.clamp(0, widget.itemCount - 1);

    if (widget.itemCount <= 1) return;
    final newPosition = index / (widget.itemCount - 1);

    if (mounted) {
      setState(() {
        _position = newPosition.clamp(0.0, 1.0);
        _currentIndex = index;
      });
    }
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _fadeController.forward();
    _hideTimer?.cancel();
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

    final fraction =
        ((localPosition.dy - _kThumbSize / 2) / trackHeight).clamp(0.0, 1.0);
    final targetIndex = (fraction * (widget.itemCount - 1))
        .round()
        .clamp(0, widget.itemCount - 1);

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
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _fadeController.reverse();
    });
  }

  void _onTapDown(TapDownDetails details) {
    _fadeController.forward();
    _hideTimer?.cancel();
    _updatePositionFromGlobal(details.globalPosition);
    _scheduleHide();
  }

  static const _kThumbSize = 44.0;
  static const _kTrackWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final trackHeight = MediaQuery.of(context).size.height - _kThumbSize - 120;
    final thumbTop = _position * trackHeight.clamp(0.0, double.infinity);

    return Positioned(
      right: 2,
      top: 8,
      bottom: 8,
      width: _kTrackWidth + 100, // Extra width for label tooltip
      child: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        onTapDown: _onTapDown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Track line
            Positioned(
              right: _kTrackWidth / 2 - 1.5,
              top: _kThumbSize / 2,
              bottom: _kThumbSize / 2,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(
                    alpha: _isDragging ? 0.2 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Thumb
            Positioned(
              right: 0,
              top: thumbTop,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _kTrackWidth,
                height: _kThumbSize,
                decoration: BoxDecoration(
                  color: _isDragging
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 18,
                  color: _isDragging
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),

            // Label tooltip (shows on drag/tap)
            Positioned(
              right: _kTrackWidth + 8,
              top: thumbTop + (_kThumbSize - 36) / 2,
              child: FadeTransition(
                opacity: _fadeAnimation,
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
            ),
          ],
        ),
      ),
    );
  }
}

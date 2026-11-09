/// Overlay scrubber that appears while the reader is scrolling, then
/// hides so it does not keep a gutter of screen space.
///
/// Wrap your [ScrollablePositionedList] and this widget in a [Stack].
/// The overlay floats on the physical right edge; it is not visible
/// until the list moves or the user drags the thumb.
///
/// Only a drag that starts on the thumb moves the reader. The rest of
/// the edge passes touches through to the list, so a thumb resting on
/// the edge while reading scrolls instead of jumping.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

const _kThumbSize = 36.0;
const _kTrackWidth = 20.0;
const _kHideAfter = Duration(milliseconds: 1400);

/// Height of the touch box around the thumb. Its width is the overlay's.
const _kHandleHitHeight = AppSpacing.minTouchTarget;

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

  /// Finger offset from the thumb's top when the drag began, so the
  /// thumb stays under the finger instead of snapping to it.
  double _grabOffset = _kThumbSize / 2;

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
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final local = renderBox.globalToLocal(details.globalPosition);
      final thumbTop = _position * _trackHeight(renderBox.size.height);
      _grabOffset = (local.dy - thumbTop).clamp(0.0, _kThumbSize);
    }
    setState(() {
      _isDragging = true;
      _shown = true;
    });
    _fadeController.forward();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updatePositionFromGlobal(details.globalPosition);
  }

  void _onDragEnd(DragEndDetails details) => _onDragCancel();

  void _onDragCancel() {
    if (!mounted) return;
    setState(() => _isDragging = false);
    _scheduleHide();
  }

  void _updatePositionFromGlobal(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final trackHeight = _trackHeight(renderBox.size.height);
    if (trackHeight <= 0) return;

    final fraction = ((localPosition.dy - _grabOffset) / trackHeight).clamp(
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

  /// Distance the thumb's top can travel within an overlay of [height].
  static double _trackHeight(double height) =>
      (height - _kThumbSize).clamp(0.0, double.infinity);

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

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
            key: const Key('scroll-scrubber-gate'),
            ignoring: !visible,
            child: Opacity(
              opacity: _isDragging ? 1 : _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final thumbTop = _position * _trackHeight(height);
            final hitTop = (thumbTop - (_kHandleHitHeight - _kThumbSize) / 2)
                .clamp(0.0, (height - _kHandleHitHeight).clamp(0.0, height));
            return _buildScrubber(colorScheme, thumbTop, hitTop);
          },
        ),
      ),
    );
  }

  Widget _buildScrubber(
    ColorScheme colorScheme,
    double thumbTop,
    double hitTop,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Track, thumb, and label are drawn only; touches on them fall
        // through to the list. The handle box below is the one target.
        IgnorePointer(
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
              // The big bubble pops out only while the handle is dragged.
              Positioned(
                right: _kTrackWidth + 10,
                top: thumbTop + _kThumbSize / 2,
                child: FractionalTranslation(
                  translation: const Offset(0, -0.5),
                  child: AnimatedOpacity(
                    opacity: _isDragging ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedScale(
                      scale: _isDragging ? 1 : 0.6,
                      alignment: Alignment.centerRight,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: ExcludeSemantics(
                        child: _ScrubberBubble(
                          label: widget.labelBuilder(_currentIndex),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          key: const Key('scroll-scrubber-handle'),
          right: 0,
          left: 0,
          top: hitTop,
          height: _kHandleHitHeight,
          child: Semantics(
            slider: true,
            label: 'Reading position',
            value: widget.labelBuilder(_currentIndex),
            child: GestureDetector(
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              onVerticalDragCancel: _onDragCancel,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        ),
      ],
    );
  }
}

/// The bubble shown beside the handle while dragging. "Ayah 3 of 7" and
/// "Hadith 12 of 40" become a large number with small words around it;
/// any other label, such as a surah name, is shown as large text.
class _ScrubberBubble extends StatelessWidget {
  const _ScrubberBubble({required this.label});

  final String label;

  static final _counted = RegExp(r'^(.*?)\s+(\d+)\s+of\s+(\d+)$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onBubble = colorScheme.onPrimary;
    final match = _counted.firstMatch(label);

    final Widget content;
    if (match == null) {
      content = Text(
        label,
        style: theme.textTheme.titleLarge?.copyWith(
          color: onBubble,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      final small = theme.textTheme.labelLarge?.copyWith(
        color: onBubble.withValues(alpha: 0.85),
        fontWeight: FontWeight.w600,
      );
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(match.group(1)!, style: small),
          Text(
            match.group(2)!,
            style: theme.textTheme.displaySmall?.copyWith(
              color: onBubble,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text('of ${match.group(3)}', style: small),
        ],
      );
    }

    return Container(
      key: const Key('scroll-scrubber-bubble'),
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: AppShadows.scrubber,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}

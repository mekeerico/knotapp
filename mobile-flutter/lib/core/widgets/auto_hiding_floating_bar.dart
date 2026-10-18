import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A floating bottom bar that gently slides and fades out
/// whenever the user touches or scrolls the screen, and smoothly glides back in
/// as soon as the user removes their finger or scrolling stops.
class AutoHidingFloatingBar extends StatefulWidget {
  final Widget child;
  final Widget floatingContent;
  final double bottomOffset;
  final Duration animationDuration;
  final Duration reappearDelay;

  const AutoHidingFloatingBar({
    super.key,
    required this.child,
    required this.floatingContent,
    this.bottomOffset = 0,
    this.animationDuration = const Duration(milliseconds: 680),
    this.reappearDelay = const Duration(milliseconds: 350),
  });

  @override
  State<AutoHidingFloatingBar> createState() => _AutoHidingFloatingBarState();
}

class _AutoHidingFloatingBarState extends State<AutoHidingFloatingBar> {
  bool _isVisible = true;
  bool _isPointerDown = false;
  bool _isScrolling = false;
  Timer? _reappearTimer;

  void _hide() {
    _reappearTimer?.cancel();
    if (_isVisible) {
      setState(() => _isVisible = false);
    }
  }

  void _scheduleReappear() {
    _reappearTimer?.cancel();
    // Only schedule reappear if pointer is up AND scrolling has settled
    if (_isPointerDown || _isScrolling) return;

    _reappearTimer = Timer(widget.reappearDelay, () {
      if (mounted && !_isPointerDown && !_isScrolling) {
        setState(() => _isVisible = true);
      }
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _isPointerDown = true;
    _hide();
  }

  void _onPointerUp(PointerUpEvent event) {
    _isPointerDown = false;
    _scheduleReappear();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isPointerDown = false;
    _scheduleReappear();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isScrolling = true;
      _hide();
    } else if (notification is ScrollUpdateNotification) {
      if (notification.scrollDelta != null && notification.scrollDelta!.abs() > 0.5) {
        _isScrolling = true;
        _hide();
      }
    } else if (notification is ScrollEndNotification) {
      _isScrolling = false;
      _scheduleReappear();
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _isScrolling = false;
        _scheduleReappear();
      } else {
        _isScrolling = true;
        _hide();
      }
    }
    return false;
  }

  @override
  void dispose() {
    _reappearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Stack(
          children: [
            // Underlying scrollable content
            Positioned.fill(child: widget.child),

            // Floating bottom bar overlay with gentle fade & slide
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.bottomOffset,
              child: AnimatedSlide(
                duration: widget.animationDuration,
                curve: Curves.easeInOutSine,
                offset: _isVisible ? Offset.zero : const Offset(0, 0.35),
                child: AnimatedOpacity(
                  duration: widget.animationDuration,
                  curve: Curves.easeInOutSine,
                  opacity: _isVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_isVisible,
                    child: widget.floatingContent,
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

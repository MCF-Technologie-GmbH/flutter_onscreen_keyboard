// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/constants/action_key_type.dart';
import 'package:flutter_onscreen_keyboard/src/utils/extensions.dart';

class TextKeyWidget extends StatefulWidget {
  const TextKeyWidget({
    required this.textKey,
    required this.onTapDown,
    required this.onTapUp,
    required this.suppressTap,
    required this.feedback,
    this.onAlternate,
    this.onCursorMove,
    this.showSecondary = false,
    super.key,
  });

  final TextKey textKey;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final bool Function() suppressTap;
  final ValueChanged<String>? onAlternate;
  final ValueChanged<int>? onCursorMove;
  final bool showSecondary;
  final OnscreenKeyboardFeedback feedback;

  @override
  State<TextKeyWidget> createState() => _TextKeyWidgetState();
}

class _TextKeyWidgetState extends State<TextKeyWidget> {
  Timer? _longPressTimer;
  Timer? _spaceTrackTimer;
  OverlayEntry? _alternatesOverlay;
  OverlayEntry? _keyPreviewOverlay;
  int? _pointer;
  int _alternateIndex = 0;
  bool _pressed = false;
  Rect? _popoverRect;
  Offset? _downPosition;
  Offset? _lastSpacePosition;
  double _spaceRemainder = 0;
  bool _spaceTracking = false;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _downPosition = event.position;
    setState(() => _pressed = true);
    if (widget.feedback.enableVisualFeedback &&
        widget.textKey.child == null &&
        widget.textKey.primary.length <= 2) {
      _showKeyPreview();
    }
    if (widget.feedback.enableHaptics) {
      unawaited(HapticFeedback.selectionClick());
    }
    if (widget.textKey.alternates.isNotEmpty) {
      _longPressTimer = Timer(const Duration(milliseconds: 450), () {
        if (!mounted || _pointer == null) return;
        if (widget.feedback.enableHaptics) {
          unawaited(HapticFeedback.mediumImpact());
        }
        _showAlternates();
      });
    }
    if (widget.textKey.primary == ' ' && widget.onCursorMove != null) {
      _spaceTrackTimer = Timer(const Duration(milliseconds: 280), () {
        if (!mounted || _pointer == null) return;
        _spaceTracking = true;
        _lastSpacePosition = _downPosition;
        _removeKeyPreview();
        if (widget.feedback.enableHaptics) {
          unawaited(HapticFeedback.mediumImpact());
        }
      });
    }
  }

  void _move(PointerMoveEvent event) {
    if (_spaceTracking) {
      final last = _lastSpacePosition ?? event.position;
      _spaceRemainder += event.position.dx - last.dx;
      _lastSpacePosition = event.position;
      final steps = _spaceRemainder ~/ 14;
      if (steps != 0) {
        _spaceRemainder -= steps * 14;
        widget.onCursorMove?.call(steps);
      }
      return;
    }
    if (_downPosition case final origin?
        when (event.position - origin).distance >= 10) {
      _removeKeyPreview();
    }
    final rect = _popoverRect;
    if (_alternatesOverlay == null || rect == null) return;
    final index =
        ((event.position.dx - rect.left) /
                (rect.width / widget.textKey.alternates.length))
            .floor()
            .clamp(0, widget.textKey.alternates.length - 1);
    if (index != _alternateIndex) {
      _alternateIndex = index;
      _alternatesOverlay?.markNeedsBuild();
    }
  }

  void _up(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    _longPressTimer?.cancel();
    _spaceTrackTimer?.cancel();
    if (_spaceTracking) {
      _finish();
      return;
    }
    if (_alternatesOverlay != null) {
      final value = widget.textKey.alternates[_alternateIndex];
      final alternate = widget.showSecondary ? value.toUpperCase() : value;
      widget.onAlternate?.call(alternate);
      _finish();
      return;
    } else if (!widget.suppressTap()) {
      widget.onTapDown();
      widget.onTapUp();
      widget.textKey.onTap?.call(context);
    }
    _finish();
  }

  void _cancel(PointerCancelEvent event) {
    if (_pointer == event.pointer) _finish();
  }

  void _finish() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _spaceTrackTimer?.cancel();
    _spaceTrackTimer = null;
    _removeAlternatesOverlay();
    _alternatesOverlay = null;
    _removeKeyPreview();
    _popoverRect = null;
    _pointer = null;
    _downPosition = null;
    _lastSpacePosition = null;
    _spaceRemainder = 0;
    _spaceTracking = false;
    if (mounted) setState(() => _pressed = false);
  }

  void _removeAlternatesOverlay() {
    final entry = _alternatesOverlay;
    if (entry != null) entry.remove();
  }

  void _showAlternates() {
    _removeKeyPreview();
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    // Accent alternates are picked by sliding a finger over them, so they
    // are drawn larger than the key itself.
    const itemWidth = 64.0;
    const height = 76.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = math.min(
      itemWidth * widget.textKey.alternates.length,
      screenWidth - 8,
    );
    final left = (origin.dx + (box.size.width - width) / 2).clamp(
      4.0,
      math.max<double>(4, screenWidth - width - 4),
    );
    final top = math.max<double>(4, origin.dy - height - 8);
    _popoverRect = Rect.fromLTWH(left, top, width, height);
    _alternatesOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              for (var i = 0; i < widget.textKey.alternates.length; i++)
                Expanded(
                  child: ColoredBox(
                    color: i == _alternateIndex
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: Center(
                      child: Text(
                        widget.showSecondary
                            ? widget.textKey.alternates[i].toUpperCase()
                            : widget.textKey.alternates[i],
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_alternatesOverlay!);
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _spaceTrackTimer?.cancel();
    _removeAlternatesOverlay();
    _removeKeyPreview();
    super.dispose();
  }

  void _showKeyPreview() {
    _removeKeyPreview();
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = box.size.width.clamp(52.0, 72.0);
    const height = 58.0;
    final left = (origin.dx + (box.size.width - width) / 2).clamp(
      4.0,
      screenWidth - width - 4,
    );
    final top = math.max<double>(4, origin.dy - height - 5);
    _keyPreviewOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: IgnorePointer(
          child: Material(
            elevation: 5,
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                widget.textKey.getText(secondary: widget.showSecondary),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_keyPreviewOverlay!);
  }

  void _removeKeyPreview() {
    final entry = _keyPreviewOverlay;
    _keyPreviewOverlay = null;
    if (entry != null) entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = context.theme.textKeyThemeData;
    Widget child = switch (widget.textKey.child) {
      Icon() => Padding(
        padding:
            theme.padding ??
            (theme.fitChild ? const EdgeInsets.all(28) : EdgeInsets.zero),
        child: widget.textKey.child,
      ),
      Widget() => Padding(
        padding: theme.padding ?? const EdgeInsets.all(10),
        child: widget.textKey.child,
      ),
      null => Padding(
        padding: theme.padding ?? const EdgeInsets.all(10),
        child: Text(
          widget.textKey.getText(secondary: widget.showSecondary),
          style: theme.textStyle ?? TextStyle(color: theme.foregroundColor),
        ),
      ),
    };
    child = theme.fitChild ? FittedBox(child: child) : Center(child: child);
    return Semantics(
      button: true,
      label: widget.textKey.getText(secondary: widget.showSecondary),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: Transform.scale(
          scale: widget.feedback.enableVisualFeedback && _pressed ? .96 : 1,
          child: Container(
            margin: theme.margin,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: theme.borderRadius,
              border: theme.border,
              boxShadow: theme.boxShadow,
              gradient: theme.gradient,
              color: widget.feedback.enableVisualFeedback && _pressed
                  ? colors.primaryContainer
                  : theme.backgroundColor ?? colors.surface,
            ),
            child: IconTheme(
              data: IconThemeData(
                size: theme.iconSize,
                color: theme.foregroundColor ?? colors.onSurface,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ActionKeyWidget extends StatefulWidget {
  const ActionKeyWidget({
    required this.actionKey,
    required this.pressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.feedback,
    this.capsLock = false,
    this.onDeleteWord,
    super.key,
  });

  final ActionKey actionKey;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final OnscreenKeyboardFeedback feedback;
  final bool capsLock;
  final VoidCallback? onDeleteWord;

  @override
  State<ActionKeyWidget> createState() => _ActionKeyWidgetState();
}

class _ActionKeyWidgetState extends State<ActionKeyWidget> {
  Timer? _repeatTimer;
  int? _pointer;
  int _repeatCount = 0;
  Offset? _downPosition;
  int _wordDeleteCount = 0;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _downPosition = event.position;
    setState(() {});
    widget.actionKey.onTapDown?.call(context);
    widget.onTapDown();
    if (widget.feedback.enableHaptics) {
      unawaited(HapticFeedback.selectionClick());
    }
    if (widget.actionKey.repeatable) {
      _repeatTimer = Timer(const Duration(milliseconds: 400), _repeat);
    }
  }

  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer ||
        widget.actionKey.name != ActionKeyType.backspace ||
        widget.onDeleteWord == null ||
        _downPosition == null) {
      return;
    }
    final distance = _downPosition!.dx - event.position.dx;
    final count = distance < 28 ? 0 : 1 + ((distance - 28) ~/ 38);
    while (_wordDeleteCount < count) {
      _repeatTimer?.cancel();
      _repeatTimer = null;
      _wordDeleteCount++;
      widget.onDeleteWord?.call();
      if (widget.feedback.enableHaptics) {
        unawaited(HapticFeedback.selectionClick());
      }
    }
  }

  void _repeat() {
    if (_pointer == null) return;
    _repeatCount++;
    widget.onTapDown();
    widget.onTapUp();
    final delay = _repeatCount > 16
        ? 35
        : _repeatCount > 7
        ? 55
        : 90;
    _repeatTimer = Timer(Duration(milliseconds: delay), _repeat);
  }

  void _up(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    widget.actionKey.onTapUp?.call(context);
    widget.onTapUp();
    widget.actionKey.onTap?.call(context);
    _finish();
  }

  void _cancel(PointerCancelEvent event) {
    if (_pointer != event.pointer) return;
    widget.onTapUp();
    _finish();
  }

  void _finish() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _repeatCount = 0;
    _wordDeleteCount = 0;
    _downPosition = null;
    _pointer = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = context.theme.actionKeyThemeData;
    final isShift = widget.actionKey.name == ActionKeyType.shift;
    final capsLock = isShift && widget.capsLock;
    final visualChild = capsLock
        ? const Icon(Icons.keyboard_capslock_rounded)
        : widget.actionKey.child;
    final semanticLabel = isShift
        ? widget.capsLock
              ? 'Caps Lock on'
              : widget.pressed
              ? 'Shift on'
              : 'Shift off'
        : widget.actionKey.label ?? widget.actionKey.name;
    Widget child = switch (visualChild) {
      Icon() => Padding(
        padding:
            theme.padding ??
            (theme.fitChild ? const EdgeInsets.all(28) : EdgeInsets.zero),
        child: visualChild,
      ),
      Widget() => Padding(
        padding: theme.padding ?? EdgeInsets.zero,
        child: visualChild,
      ),
      null => Padding(
        padding: theme.padding ?? EdgeInsets.zero,
        child: Text(
          widget.actionKey.label ?? widget.actionKey.name,
          style: theme.textStyle,
        ),
      ),
    };
    child = theme.fitChild ? FittedBox(child: child) : Center(child: child);
    final visuallyPressed =
        widget.pressed ||
        (widget.feedback.enableVisualFeedback && _pointer != null);
    final background = capsLock
        ? theme.capsLockBackgroundColor ??
              theme.pressedBackgroundColor ??
              colors.primary
        : visuallyPressed
        ? theme.pressedBackgroundColor ?? colors.primary
        : theme.backgroundColor ?? colors.surfaceContainer;
    final foreground = capsLock
        ? theme.capsLockForegroundColor ??
              theme.pressedForegroundColor ??
              colors.onPrimary
        : visuallyPressed
        ? theme.pressedForegroundColor ?? colors.onPrimary
        : theme.foregroundColor ?? colors.onSurface;
    if (capsLock) {
      // Caps lock must not look like a momentary shift: the key keeps its
      // pressed colours and gains a lock bar under the icon.
      child = Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                key: const ValueKey('onscreen-keyboard-caps-lock-bar'),
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: foreground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Semantics(
      button: true,
      toggled: isShift ? widget.pressed : null,
      label: semanticLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: Transform.scale(
          scale: visuallyPressed ? .96 : 1,
          child: Container(
            margin: theme.margin,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: theme.borderRadius,
              border: theme.border,
              boxShadow: theme.boxShadow,
              gradient: theme.gradient,
              color: background,
            ),
            child: IconTheme(
              data: IconThemeData(
                size: theme.iconSize,
                color: foreground,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

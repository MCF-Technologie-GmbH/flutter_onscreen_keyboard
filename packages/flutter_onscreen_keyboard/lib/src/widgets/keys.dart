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
    this.showSecondary = false,
    super.key,
  });

  final TextKey textKey;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final bool Function() suppressTap;
  final ValueChanged<String>? onAlternate;
  final bool showSecondary;
  final OnscreenKeyboardFeedback feedback;

  @override
  State<TextKeyWidget> createState() => _TextKeyWidgetState();
}

class _TextKeyWidgetState extends State<TextKeyWidget> {
  Timer? _longPressTimer;
  OverlayEntry? _alternatesOverlay;
  OverlayEntry? _keyPreviewOverlay;
  int? _pointer;
  int _alternateIndex = 0;
  bool _pressed = false;
  Rect? _popoverRect;
  Offset? _downPosition;

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
  }

  void _move(PointerMoveEvent event) {
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
    if (_alternatesOverlay != null) {
      final alternate = widget.textKey.alternates[_alternateIndex];
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
    _removeAlternatesOverlay();
    _alternatesOverlay = null;
    _removeKeyPreview();
    _popoverRect = null;
    _pointer = null;
    _downPosition = null;
    if (mounted) setState(() => _pressed = false);
  }

  void _removeAlternatesOverlay() {
    final entry = _alternatesOverlay;
    if (entry != null && entry.mounted) entry.remove();
  }

  void _showAlternates() {
    _removeKeyPreview();
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    const itemWidth = 44.0;
    const height = 52.0;
    final width = itemWidth * widget.textKey.alternates.length;
    final left = origin.dx + (box.size.width - width) / 2;
    final top = origin.dy - height - 8;
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
                        widget.textKey.alternates[i],
                        style: Theme.of(context).textTheme.titleLarge,
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
    if (entry != null && entry.mounted) entry.remove();
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
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _cancel,
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
    super.key,
  });

  final ActionKey actionKey;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final OnscreenKeyboardFeedback feedback;
  final bool capsLock;

  @override
  State<ActionKeyWidget> createState() => _ActionKeyWidgetState();
}

class _ActionKeyWidgetState extends State<ActionKeyWidget> {
  Timer? _repeatTimer;
  int? _pointer;
  int _repeatCount = 0;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
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
    final visualChild = isShift && widget.capsLock
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
    return Semantics(
      button: true,
      toggled: isShift ? widget.pressed : null,
      label: semanticLabel,
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
            color: visuallyPressed
                ? theme.pressedBackgroundColor ?? colors.primary
                : theme.backgroundColor ?? colors.surfaceContainer,
          ),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerUp: _up,
            onPointerCancel: _cancel,
            child: IconTheme(
              data: IconThemeData(
                size: theme.iconSize,
                color: visuallyPressed
                    ? theme.pressedForegroundColor ?? colors.onPrimary
                    : theme.foregroundColor ?? colors.onSurface,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

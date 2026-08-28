// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
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
  int? _pointer;
  int _alternateIndex = 0;
  bool _pressed = false;
  Rect? _popoverRect;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    setState(() => _pressed = true);
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
    _popoverRect = null;
    _pointer = null;
    if (mounted) setState(() => _pressed = false);
  }

  void _removeAlternatesOverlay() {
    final entry = _alternatesOverlay;
    if (entry == null || !entry.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entry.mounted) entry.remove();
    });
  }

  void _showAlternates() {
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
    super.dispose();
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
    super.key,
  });

  final ActionKey actionKey;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final OnscreenKeyboardFeedback feedback;

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
    Widget child = switch (widget.actionKey.child) {
      Icon() => Padding(
        padding:
            theme.padding ??
            (theme.fitChild ? const EdgeInsets.all(28) : EdgeInsets.zero),
        child: widget.actionKey.child,
      ),
      Widget() => Padding(
        padding: theme.padding ?? EdgeInsets.zero,
        child: widget.actionKey.child,
      ),
      null => Padding(
        padding: theme.padding ?? EdgeInsets.zero,
        child: Text(widget.actionKey.label ?? widget.actionKey.name),
      ),
    };
    child = theme.fitChild ? FittedBox(child: child) : Center(child: child);
    return Semantics(
      button: true,
      label: widget.actionKey.label ?? widget.actionKey.name,
      child: Container(
        margin: theme.margin,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: theme.borderRadius,
          border: theme.border,
          boxShadow: theme.boxShadow,
          gradient: theme.gradient,
          color: widget.pressed
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
              color: widget.pressed
                  ? theme.pressedForegroundColor ?? colors.onPrimary
                  : theme.foregroundColor ?? colors.onSurface,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

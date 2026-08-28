// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/widgets/keys.dart';

class RawOnscreenKeyboard extends StatefulWidget {
  const RawOnscreenKeyboard({
    required this.layout,
    required this.onKeyDown,
    required this.onKeyUp,
    required this.mode,
    super.key,
    this.aspectRatio,
    this.pressedActionKeys = const {},
    this.showSecondary = false,
    this.onAlternate,
    this.onSwipe,
    this.onSwipeUpdate,
    this.feedback = const OnscreenKeyboardFeedback(),
  });

  final KeyboardLayout layout;
  final double? aspectRatio;
  final ValueChanged<OnscreenKeyboardKey> onKeyDown;
  final ValueChanged<OnscreenKeyboardKey> onKeyUp;
  final Set<String> pressedActionKeys;
  final bool showSecondary;
  final String mode;
  final ValueChanged<String>? onAlternate;
  final ValueChanged<List<String>>? onSwipe;
  final ValueChanged<List<String>>? onSwipeUpdate;
  final OnscreenKeyboardFeedback feedback;

  @override
  State<RawOnscreenKeyboard> createState() => _RawOnscreenKeyboardState();
}

class _RawOnscreenKeyboardState extends State<RawOnscreenKeyboard> {
  final List<(GlobalKey, TextKey)> _textKeys = [];
  final List<String> _trace = [];
  int? _pointer;
  Offset? _origin;
  bool _swiping = false;
  Timer? _swipePreviewTimer;

  void _pointerDown(PointerDownEvent event) {
    if (_pointer != null || widget.onSwipe == null) return;
    final key = _hit(event.position);
    if (key == null) return;
    _pointer = event.pointer;
    _origin = event.position;
    _swiping = false;
    _trace
      ..clear()
      ..add(key.primary);
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    if (!_swiping && (event.position - _origin!).distance >= 12) {
      _swiping = true;
    }
    if (!_swiping) return;
    final key = _hit(event.position);
    if (key != null && (_trace.isEmpty || _trace.last != key.primary)) {
      _trace.add(key.primary);
      _scheduleSwipePreview();
    }
  }

  void _scheduleSwipePreview() {
    if (_trace.length < 2 || widget.onSwipeUpdate == null) return;
    _swipePreviewTimer?.cancel();
    _swipePreviewTimer = Timer(const Duration(milliseconds: 32), () {
      if (!mounted || !_swiping || _pointer == null) return;
      widget.onSwipeUpdate?.call(List.unmodifiable(_trace));
    });
  }

  void _pointerUp(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    _swipePreviewTimer?.cancel();
    if (_swiping && _trace.length >= 2) {
      widget.onSwipe?.call(List.unmodifiable(_trace));
    }
    _pointer = null;
    _origin = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _swiping = false);
  }

  TextKey? _hit(Offset globalPosition) {
    for (final entry in _textKeys) {
      final context = entry.$1.currentContext;
      if (context == null) continue;
      final box = context.findRenderObject()! as RenderBox;
      if ((box.localToGlobal(Offset.zero) & box.size).contains(
        globalPosition,
      )) {
        return entry.$2;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _textKeys.clear();
    final activeMode = widget.layout.modes[widget.mode]!;
    return Listener(
      onPointerDown: _pointerDown,
      onPointerMove: _pointerMove,
      onPointerUp: _pointerUp,
      onPointerCancel: (_) {
        _swipePreviewTimer?.cancel();
        _pointer = null;
        _origin = null;
        _trace.clear();
        _swiping = false;
      },
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? widget.layout.aspectRatio,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            spacing: activeMode.verticalSpacing,
            children: [
              for (final row in activeMode.rows)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?row.leading,
                      for (final key in row.keys)
                        Expanded(
                          flex: key.flex,
                          child: switch (key) {
                            TextKey() => _textKey(key),
                            ActionKey() => ActionKeyWidget(
                              actionKey: key,
                              pressed: widget.pressedActionKeys.contains(
                                key.name,
                              ),
                              feedback: widget.feedback,
                              onTapDown: () => widget.onKeyDown(key),
                              onTapUp: () => widget.onKeyUp(key),
                            ),
                          },
                        ),
                      ?row.trailing,
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _swipePreviewTimer?.cancel();
    super.dispose();
  }

  Widget _textKey(TextKey key) {
    final globalKey = GlobalKey();
    _textKeys.add((globalKey, key));
    return KeyedSubtree(
      key: globalKey,
      child: TextKeyWidget(
        textKey: key,
        showSecondary: widget.showSecondary,
        feedback: widget.feedback,
        suppressTap: () => _swiping,
        onAlternate: widget.onAlternate,
        onTapDown: () => widget.onKeyDown(key),
        onTapUp: () => widget.onKeyUp(key),
      ),
    );
  }
}

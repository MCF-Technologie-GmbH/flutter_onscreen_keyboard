// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/constants/action_key_type.dart';
import 'package:flutter_onscreen_keyboard/src/widgets/keys.dart';

class RawOnscreenKeyboard extends StatefulWidget {
  const RawOnscreenKeyboard({
    required this.layout,
    required this.onKeyDown,
    required this.onKeyUp,
    required this.mode,
    super.key,
    this.aspectRatio,
    this.fillAvailableSpace = false,
    this.pressedActionKeys = const {},
    this.showSecondary = false,
    this.onAlternate,
    this.onSwipe,
    this.onSwipeUpdate,
    this.onSwipeData,
    this.onSwipeDataUpdate,
    this.onTapSample,
    this.onSpaceCursorMove,
    this.onDeleteWord,
    this.feedback = const OnscreenKeyboardFeedback(),
  });

  final KeyboardLayout layout;
  final double? aspectRatio;

  /// Whether the keyboard should fill tight parent constraints.
  ///
  /// Docked keyboards use this so their rows share the height left below the
  /// utility bar. Floating keyboards retain the layout aspect ratio.
  final bool fillAvailableSpace;
  final ValueChanged<OnscreenKeyboardKey> onKeyDown;
  final ValueChanged<OnscreenKeyboardKey> onKeyUp;
  final Set<String> pressedActionKeys;
  final bool showSecondary;
  final String mode;
  final ValueChanged<String>? onAlternate;
  final ValueChanged<List<String>>? onSwipe;
  final ValueChanged<List<String>>? onSwipeUpdate;
  final ValueChanged<OnscreenKeyboardSwipeData>? onSwipeData;
  final ValueChanged<OnscreenKeyboardSwipeData>? onSwipeDataUpdate;
  final ValueChanged<OnscreenKeyboardTapSample>? onTapSample;
  final ValueChanged<int>? onSpaceCursorMove;
  final VoidCallback? onDeleteWord;
  final OnscreenKeyboardFeedback feedback;

  @override
  State<RawOnscreenKeyboard> createState() => _RawOnscreenKeyboardState();
}

class _RawOnscreenKeyboardState extends State<RawOnscreenKeyboard> {
  final List<(GlobalKey, TextKey)> _textKeys = [];
  final Map<String, GlobalKey> _textKeyKeys = {};
  final List<String> _trace = [];
  final List<Offset> _points = [];
  final GlobalKey _surfaceKey = GlobalKey();
  int? _pointer;
  Offset? _origin;
  TextKey? _downKey;
  Duration? _downTimestamp;
  bool _swiping = false;
  bool _dragging = false;
  Timer? _swipePreviewTimer;

  bool get _hasSwipeHandler =>
      widget.onSwipe != null || widget.onSwipeData != null;

  void _pointerDown(PointerDownEvent event) {
    if (_pointer != null || (!_hasSwipeHandler && widget.onTapSample == null)) {
      return;
    }
    final key = _hit(event.position);
    if (key == null ||
        !RegExp(r'^\p{L}$', unicode: true).hasMatch(key.primary)) {
      return;
    }
    _pointer = event.pointer;
    _origin = event.position;
    _downKey = key;
    _downTimestamp = event.timeStamp;
    _swiping = false;
    _dragging = false;
    _trace
      ..clear()
      ..add(key.primary);
    _points
      ..clear()
      ..add(_normalize(event.position));
    setState(() {});
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    if (!_dragging && (event.position - _origin!).distance >= 12) {
      _dragging = true;
    }
    if (!_hasSwipeHandler) return;
    if (!_swiping && (event.position - _origin!).distance >= 12) {
      _swiping = true;
    }
    if (!_swiping) return;
    final point = _normalize(event.position);
    if (_points.isEmpty || (_points.last - point).distance >= .002) {
      _points.add(point);
      setState(() {});
    }
    final key = _hit(event.position);
    if (key != null && (_trace.isEmpty || _trace.last != key.primary)) {
      _trace.add(key.primary);
      _scheduleSwipePreview();
    }
  }

  void _scheduleSwipePreview() {
    if (_trace.length < 2 && _points.length < 3) return;
    if (widget.onSwipeUpdate == null && widget.onSwipeDataUpdate == null) {
      return;
    }
    _swipePreviewTimer?.cancel();
    _swipePreviewTimer = Timer(const Duration(milliseconds: 32), () {
      if (!mounted || !_swiping || _pointer == null) return;
      widget.onSwipeUpdate?.call(List.unmodifiable(_trace));
      widget.onSwipeDataUpdate?.call(_snapshot());
    });
  }

  void _pointerUp(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    _swipePreviewTimer?.cancel();
    if (_swiping && _trace.length >= 2) {
      widget.onSwipe?.call(List.unmodifiable(_trace));
      widget.onSwipeData?.call(_snapshot());
    } else if (_downKey case final key?) {
      final center = _centerOf(key);
      if (center != null) {
        widget.onTapSample?.call(
          OnscreenKeyboardTapSample(
            character: key.primary,
            position: _normalize(event.position),
            keyCenter: center,
            timestamp: _downTimestamp ?? event.timeStamp,
            keyCenters: {
              for (final entry in _textKeys)
                if (entry.$1.currentContext case final context?)
                  entry.$2.primary.toLowerCase(): _centerFromContext(context),
            },
          ),
        );
      }
    }
    _pointer = null;
    _origin = null;
    _downKey = null;
    _downTimestamp = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _swiping = false;
      _dragging = false;
      if (mounted) setState(_points.clear);
    });
  }

  Offset _normalize(Offset globalPosition) {
    final context = _surfaceKey.currentContext;
    if (context == null) return Offset.zero;
    final box = context.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(globalPosition);
    return Offset(
      (local.dx / box.size.width).clamp(0, 1),
      (local.dy / box.size.height).clamp(0, 1),
    );
  }

  OnscreenKeyboardSwipeData _snapshot() => OnscreenKeyboardSwipeData(
    trace: List.unmodifiable(_trace),
    points: List.unmodifiable(_points),
    keyCenters: {
      for (final entry in _textKeys)
        if (entry.$1.currentContext case final context?)
          entry.$2.primary: _centerFromContext(context),
    },
  );

  Offset? _centerOf(TextKey key) {
    for (final entry in _textKeys) {
      if (!identical(entry.$2, key)) continue;
      final context = entry.$1.currentContext;
      if (context != null) return _centerFromContext(context);
    }
    return null;
  }

  Offset _centerFromContext(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return _normalize(box.localToGlobal(box.size.center(Offset.zero)));
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
    final surface = Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Column(
            spacing: activeMode.verticalSpacing,
            children: [
              for (final (rowIndex, row) in activeMode.rows.indexed)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?row.leading,
                      for (final (keyIndex, key) in row.keys.indexed)
                        Expanded(
                          flex: key.flex,
                          child: switch (key) {
                            TextKey() => _textKey(
                              key,
                              '${widget.mode}:$rowIndex:$keyIndex',
                            ),
                            ActionKey() => ActionKeyWidget(
                              actionKey: key,
                              pressed:
                                  widget.pressedActionKeys.contains(key.name) ||
                                  (key.name == ActionKeyType.shift &&
                                      widget.pressedActionKeys.contains(
                                        ActionKeyType.capslock,
                                      )),
                              capsLock:
                                  key.name == ActionKeyType.shift &&
                                  widget.pressedActionKeys.contains(
                                    ActionKeyType.capslock,
                                  ),
                              onDeleteWord: key.name == ActionKeyType.backspace
                                  ? widget.onDeleteWord
                                  : null,
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
          if (_swiping && _points.length >= 2)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SwipeTracePainter(
                    points: List.of(_points),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Listener(
      onPointerDown: _pointerDown,
      onPointerMove: _pointerMove,
      onPointerUp: _pointerUp,
      onPointerCancel: (_) {
        _swipePreviewTimer?.cancel();
        _pointer = null;
        _origin = null;
        _downKey = null;
        _downTimestamp = null;
        _trace.clear();
        _points.clear();
        _swiping = false;
        _dragging = false;
        if (mounted) setState(() {});
      },
      child: KeyedSubtree(
        key: _surfaceKey,
        child: widget.fillAvailableSpace
            ? SizedBox.expand(child: surface)
            : AspectRatio(
                aspectRatio: widget.aspectRatio ?? widget.layout.aspectRatio,
                child: surface,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _swipePreviewTimer?.cancel();
    super.dispose();
  }

  Widget _textKey(TextKey key, String position) {
    // A key must keep the same element while the keyboard repaints its pressed
    // state or swipe trace. Recreating this GlobalKey canceled long-press
    // timers and could strand preview overlays after pointer down.
    final globalKey = _textKeyKeys.putIfAbsent(position, GlobalKey.new);
    _textKeys.add((globalKey, key));
    return KeyedSubtree(
      key: globalKey,
      child: TextKeyWidget(
        textKey: key,
        showSecondary: widget.showSecondary,
        feedback: widget.feedback,
        suppressTap: () => _swiping || _dragging,
        onAlternate: widget.onAlternate,
        onCursorMove: key.primary == ' ' ? widget.onSpaceCursorMove : null,
        onTapDown: () => widget.onKeyDown(key),
        onTapUp: () => widget.onKeyUp(key),
      ),
    );
  }
}

class _SwipeTracePainter extends CustomPainter {
  const _SwipeTracePainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(
        points[index].dx * size.width,
        points[index].dy * size.height,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final paint = Paint()
      ..color = color.withValues(alpha: .62)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
    final end = Offset(
      points.last.dx * size.width,
      points.last.dy * size.height,
    );
    canvas.drawCircle(end, 7, Paint()..color = color.withValues(alpha: .82));
  }

  @override
  bool shouldRepaint(_SwipeTracePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

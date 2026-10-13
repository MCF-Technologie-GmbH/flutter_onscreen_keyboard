import 'package:flutter/widgets.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart'
    show OnscreenKeyboard;

/// Publishes the part of the application that the on-screen keyboard covers
/// right now.
///
/// [OnscreenKeyboard] inserts this widget above its `child`. In the overlay
/// presentation the keyboard is drawn over the application without resizing
/// it, so widgets that must stay usable while typing (for example dialogs) can
/// read [rect] and lay themselves out in the free space.
///
/// [rect] is expressed in the coordinate space of the keyboard's `child`
/// (which fills the keyboard surface). It follows the keyboard's slide
/// animation and its drag position, and is [Rect.zero] while nothing is
/// covered: when the keyboard is hidden, and always for the docked and
/// floating presentations (docked already shrinks the application).
class OnscreenKeyboardObscuredArea extends InheritedWidget {
  /// Creates an [OnscreenKeyboardObscuredArea].
  const OnscreenKeyboardObscuredArea({
    required this.rect,
    required super.child,
    super.key,
  });

  /// The covered rectangle, or [Rect.zero] when nothing is covered.
  final Rect rect;

  /// Whether the keyboard currently covers any part of the application.
  bool get isEmpty => rect.isEmpty;

  /// The covered rectangle of the nearest [OnscreenKeyboard], or `null` when
  /// there is no [OnscreenKeyboard] above [context].
  ///
  /// Registers [context] to rebuild when the rectangle changes.
  static Rect? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<OnscreenKeyboardObscuredArea>()
      ?.rect;

  /// The covered rectangle of the nearest [OnscreenKeyboard], or [Rect.zero]
  /// when there is none.
  ///
  /// Registers [context] to rebuild when the rectangle changes.
  static Rect of(BuildContext context) => maybeOf(context) ?? Rect.zero;

  @override
  bool updateShouldNotify(OnscreenKeyboardObscuredArea oldWidget) =>
      oldWidget.rect != rect;
}

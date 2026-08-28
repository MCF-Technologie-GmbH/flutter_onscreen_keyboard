import 'package:flutter/widgets.dart';
import 'package:flutter_onscreen_keyboard/src/models/keys.dart';
import 'package:flutter_onscreen_keyboard/src/phone/language_model.dart';

/// A function that returns the desired width for the keyboard widget.
typedef WidthGetter = double Function(BuildContext context);

/// Signature for a listener function that responds to keyboard key events.
///
/// Called when a key is pressed on the on-screen keyboard.
typedef OnscreenKeyboardListener = void Function(OnscreenKeyboardKey key);

/// Signature for building a list of action widgets for the
/// keyboard control bar.
typedef ActionsBuilder = List<Widget> Function(BuildContext context);

/// Builds the compact suggestion/utility area above a phone keyboard.
typedef SuggestionBarBuilder =
    Widget Function(
      BuildContext context,
      List<OnscreenKeyboardSuggestion> suggestions,
      ValueChanged<OnscreenKeyboardSuggestion> onSelected,
      VoidCallback? onUndo,
    );

/// A function that returns the desired docked keyboard height.
typedef HeightGetter = double Function(BuildContext context);

/// A callback function that receives the current [BuildContext].
typedef CallbackWithContext = void Function(BuildContext context);

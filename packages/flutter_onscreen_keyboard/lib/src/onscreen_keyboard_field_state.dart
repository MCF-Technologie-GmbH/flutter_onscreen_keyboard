part of 'onscreen_keyboard.dart';

/// An interface that defines the contract for the state of an
/// onscreen keyboard field.
abstract interface class OnscreenKeyboardFieldState {
  /// The [TextEditingController] associated with the field.
  TextEditingController get controller;

  /// The [FocusNode] associated with the field.
  FocusNode get focusNode;

  /// The maxLines property of the field.
  int? get maxLines;

  /// The [List<TextInputFormatter>] associated with the field.
  List<TextInputFormatter>? get inputFormatters;

  /// The [ValueChanged<String>] callback for text changes.
  ValueChanged<String>? get onChanged;

  /// Phone-keyboard behavior derived from this field's Flutter configuration.
  OnscreenKeyboardFieldConfiguration get fieldConfiguration;

  /// Callback invoked when a non-newline action submits the field.
  ValueChanged<String>? get onSubmitted;

  /// Callback invoked before the default completion behavior.
  VoidCallback? get onEditingComplete;
}

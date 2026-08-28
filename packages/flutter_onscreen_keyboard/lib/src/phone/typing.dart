// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_onscreen_keyboard/src/models/layout.dart';

/// Controls how the keyboard is placed around the application.
enum OnscreenKeyboardPresentation { floating, docked }

/// Controls offline language assistance.
enum OnscreenKeyboardTypingMode { off, suggestions, autocorrect }

/// Familiar, entirely local phone-keyboard editing gestures.
@immutable
class OnscreenKeyboardEditingGestures {
  const OnscreenKeyboardEditingGestures({
    this.spaceCursorControl = true,
    this.doubleSpacePeriod = true,
    this.wordDelete = true,
  });

  final bool spaceCursorControl;
  final bool doubleSpacePeriod;
  final bool wordDelete;
}

/// Coarse input categories used by phone layouts and prediction safeguards.
enum OnscreenKeyboardInputKind {
  text,
  multiline,
  number,
  signedDecimal,
  phone,
  email,
  url,
}

/// Immutable description of the field currently attached to the keyboard.
@immutable
class OnscreenKeyboardFieldConfiguration {
  const OnscreenKeyboardFieldConfiguration({
    required this.inputKind,
    required this.inputAction,
    required this.multiline,
    required this.obscureText,
    required this.readOnly,
    required this.enableSuggestions,
    required this.autocorrect,
    required this.learningEnabled,
    required this.formatterRestricted,
  });

  factory OnscreenKeyboardFieldConfiguration.fromFlutter({
    TextInputType? keyboardType,
    TextInputAction? inputAction,
    int? maxLines = 1,
    bool obscureText = false,
    bool readOnly = false,
    bool enableSuggestions = true,
    bool autocorrect = true,
    bool learningEnabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final multiline = maxLines != 1 || keyboardType == TextInputType.multiline;
    final kind = switch (keyboardType) {
      TextInputType.number => OnscreenKeyboardInputKind.number,
      TextInputType.phone => OnscreenKeyboardInputKind.phone,
      TextInputType.emailAddress => OnscreenKeyboardInputKind.email,
      TextInputType.url => OnscreenKeyboardInputKind.url,
      TextInputType.multiline => OnscreenKeyboardInputKind.multiline,
      _
          when keyboardType?.index == TextInputType.number.index &&
              ((keyboardType?.signed ?? false) ||
                  (keyboardType?.decimal ?? false)) =>
        OnscreenKeyboardInputKind.signedDecimal,
      _ when multiline => OnscreenKeyboardInputKind.multiline,
      _ => OnscreenKeyboardInputKind.text,
    };
    return OnscreenKeyboardFieldConfiguration(
      inputKind: kind,
      inputAction: inputAction,
      multiline: multiline,
      obscureText: obscureText,
      readOnly: readOnly,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      learningEnabled: learningEnabled,
      formatterRestricted: inputFormatters?.isNotEmpty ?? false,
    );
  }

  final OnscreenKeyboardInputKind inputKind;
  final TextInputAction? inputAction;
  final bool multiline;
  final bool obscureText;
  final bool readOnly;
  final bool enableSuggestions;
  final bool autocorrect;
  final bool learningEnabled;
  final bool formatterRestricted;

  bool get isLanguageInput =>
      inputKind == OnscreenKeyboardInputKind.text ||
      inputKind == OnscreenKeyboardInputKind.multiline;

  bool get allowsSuggestions =>
      isLanguageInput && !obscureText && !readOnly && enableSuggestions;

  bool get allowsAutocorrect =>
      allowsSuggestions && autocorrect && !formatterRestricted;

  bool get allowsLearning => allowsSuggestions && learningEnabled;
}

/// Resolves a layout whenever the active field or locale changes.
typedef OnscreenKeyboardLayoutResolver =
    KeyboardLayout Function(
      BuildContext context,
      Locale locale,
      OnscreenKeyboardFieldConfiguration? field,
    );

/// Visual and platform feedback settings for key interactions.
@immutable
class OnscreenKeyboardFeedback {
  const OnscreenKeyboardFeedback({
    this.enableVisualFeedback = true,
    this.enableHaptics = true,
  });

  final bool enableVisualFeedback;
  final bool enableHaptics;
}

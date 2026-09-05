import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/constants/action_key_type.dart';
import 'package:flutter_onscreen_keyboard/src/theme/onscreen_keyboard_theme.dart';
import 'package:flutter_onscreen_keyboard/src/types.dart';
import 'package:flutter_onscreen_keyboard/src/utils/extensions.dart';

part 'onscreen_keyboard_controller.dart';
part 'onscreen_keyboard_field_state.dart';
part 'onscreen_keyboard_text_field.dart';
part 'onscreen_keyboard_text_form_field.dart';

/// A customizable on-screen keyboard widget.
///
/// Wrap your application with this widget to enable the
/// on-screen keyboard functionality.
class OnscreenKeyboard extends StatefulWidget {
  /// Creates an [OnscreenKeyboard].
  const OnscreenKeyboard({
    required this.child,
    super.key,
    this.layout,
    this.theme,
    this.width,
    this.dragHandle,
    this.aspectRatio,
    this.showControlBar = true,
    this.buildControlBarActions,
    this.presentation = OnscreenKeyboardPresentation.floating,
    this.typingMode = OnscreenKeyboardTypingMode.off,
    this.locale,
    this.languageModel,
    this.layoutResolver,
    this.feedback = const OnscreenKeyboardFeedback(),
    this.editingGestures = const OnscreenKeyboardEditingGestures(),
    this.suggestionBarBuilder,
    this.swipeTypingEnabled = true,
    this.onSwipeDiagnostic,
    this.minimumSwipeConfidence = .48,
    this.minimumSwipeScoreMargin = .12,
    this.dockedHeight,
    this.enabled = true,
  });

  /// The main application child widget.
  final Widget child;

  /// Whether fields and controller calls may show this keyboard.
  ///
  /// Disabling an open keyboard closes and detaches it immediately. Defaults
  /// to true for compatibility with earlier releases.
  final bool enabled;

  /// The layout configuration for the keyboard.
  ///
  /// If not provided, a default layout will be selected automatically
  /// based on the current [defaultTargetPlatform] — a [MobileKeyboardLayout]
  /// for Android/iOS/Fuchsia and a [DesktopKeyboardLayout] for
  /// macOS/Windows/Linux.
  final KeyboardLayout? layout;

  /// Custom theme for the on-screen keyboard UI.
  ///
  /// If not provided, a default theme based on
  /// the current [ThemeData] will be used.
  final OnscreenKeyboardThemeData? theme;

  /// An optional width configuration function for the keyboard.
  final WidthGetter? width;

  /// A widget displayed as a drag handle to move the keyboard.
  final Widget? dragHandle;

  /// {@macro keyboardLayout.aspectRatio}
  final double? aspectRatio;

  /// Whether to show the control bar at the top of the keyboard.
  /// Defaults to `true`.
  final bool showControlBar;

  /// {@macro controlBar.actions}
  final ActionsBuilder? buildControlBarActions;

  /// Whether the keyboard floats above or docks below the application.
  final OnscreenKeyboardPresentation presentation;

  /// Offline language-assistance behavior.
  final OnscreenKeyboardTypingMode typingMode;

  /// Locale override. When omitted the app locale is followed.
  final Locale? locale;

  /// Optional offline language model.
  final OnscreenKeyboardSuggestionModel? languageModel;

  /// Optional field- and locale-aware layout resolver.
  final OnscreenKeyboardLayoutResolver? layoutResolver;

  /// Key interaction feedback.
  final OnscreenKeyboardFeedback feedback;

  /// Familiar cursor, punctuation, and word-deletion gestures.
  final OnscreenKeyboardEditingGestures editingGestures;

  /// Optional replacement for the default three-slot suggestion bar.
  final SuggestionBarBuilder? suggestionBarBuilder;

  /// Whether experimental swipe decoding is enabled.
  ///
  /// Defaults to `true` for compatibility. Products that do not explicitly
  /// validate swipe quality should set this to `false`.
  final bool swipeTypingEnabled;

  /// Optional, explicit local diagnostics callback for swipe tuning.
  final ValueChanged<OnscreenKeyboardSwipeDiagnostic>? onSwipeDiagnostic;

  /// Minimum decoder confidence required for automatic swipe insertion.
  final double minimumSwipeConfidence;

  /// Minimum score separation from the runner-up for automatic insertion.
  final double minimumSwipeScoreMargin;

  /// Optional dock height. Defaults to a responsive viewport fraction.
  final HeightGetter? dockedHeight;

  /// A builder to wrap the app with [OnscreenKeyboard].
  ///
  /// This provides a convenient way to globally integrate the
  /// on-screen keyboard into your app by setting it as the
  /// `builder` of your [MaterialApp] or [WidgetsApp].
  ///
  /// ### Example
  /// ```dart
  /// MaterialApp(
  ///   builder: OnscreenKeyboard.builder(
  ///     width: (context) => 600,
  ///     aspectRatio: 5 / 2,
  ///     // ...more options
  ///   ),
  ///   home: const HomeScreen(),
  /// );
  /// ```
  ///
  /// - [theme]: Custom theme configuration for the keyboard, such as color,
  ///   shadow, border, margin, and shape. If null, defaults will be applied.
  /// - [layout]: Keyboard layout to render. Falls back to default layout
  ///   if not set.
  /// - [width]: A function that returns the keyboard's width.
  /// - [showControlBar]: Whether to show the control bar at the top of the
  ///   keyboard. Defaults to `true`.
  /// - [dragHandle]: A widget to show as the drag handle above the keyboard.
  ///   If null, a default handle is shown.
  /// - [aspectRatio]: Determines the width-to-height ratio of the
  ///   keyboard widget.
  /// - [buildControlBarActions]: A callback that builds trailing action widgets
  ///   (e.g., move, close) in the keyboard's control bar. If omitted, default
  ///   actions are shown.
  ///
  /// Returns a [TransitionBuilder] to be passed to [MaterialApp.builder].
  ///
  /// See also:
  ///  - [OnscreenKeyboard.new], which creates an [OnscreenKeyboard] widget.
  static TransitionBuilder builder({
    OnscreenKeyboardThemeData? theme,
    KeyboardLayout? layout,
    WidthGetter? width,
    bool showControlBar = true,
    Widget? dragHandle,
    double? aspectRatio,
    ActionsBuilder? buildControlBarActions,
    OnscreenKeyboardPresentation presentation =
        OnscreenKeyboardPresentation.floating,
    OnscreenKeyboardTypingMode typingMode = OnscreenKeyboardTypingMode.off,
    Locale? locale,
    OnscreenKeyboardSuggestionModel? languageModel,
    OnscreenKeyboardLayoutResolver? layoutResolver,
    OnscreenKeyboardFeedback feedback = const OnscreenKeyboardFeedback(),
    OnscreenKeyboardEditingGestures editingGestures =
        const OnscreenKeyboardEditingGestures(),
    SuggestionBarBuilder? suggestionBarBuilder,
    bool swipeTypingEnabled = true,
    ValueChanged<OnscreenKeyboardSwipeDiagnostic>? onSwipeDiagnostic,
    double minimumSwipeConfidence = .48,
    double minimumSwipeScoreMargin = .12,
    HeightGetter? dockedHeight,
    bool enabled = true,
  }) => (context, child) {
    return OnscreenKeyboard(
      theme: theme,
      layout: layout,
      width: width,
      showControlBar: showControlBar,
      dragHandle: dragHandle,
      aspectRatio: aspectRatio,
      buildControlBarActions: buildControlBarActions,
      presentation: presentation,
      typingMode: typingMode,
      locale: locale,
      languageModel: languageModel,
      layoutResolver: layoutResolver,
      feedback: feedback,
      editingGestures: editingGestures,
      suggestionBarBuilder: suggestionBarBuilder,
      swipeTypingEnabled: swipeTypingEnabled,
      onSwipeDiagnostic: onSwipeDiagnostic,
      minimumSwipeConfidence: minimumSwipeConfidence,
      minimumSwipeScoreMargin: minimumSwipeScoreMargin,
      dockedHeight: dockedHeight,
      enabled: enabled,
      child: child!,
    );
  };

  /// Gets the nearest [OnscreenKeyboardController] from the widget tree.
  static OnscreenKeyboardController of(BuildContext context) {
    final provider = context
        .getInheritedWidgetOfExactType<_OnscreenKeyboardProvider>();
    assert(provider != null, '''
No OnscreenKeyboard found in context. Did you wrap your app with OnscreenKeyboard?

    MaterialApp(
      builder: OnscreenKeyboard.builder(),  // <- add this line
      home: const App(),
    )
    ''');
    return provider!.state;
  }

  @override
  State<OnscreenKeyboard> createState() => _OnscreenKeyboardState();
}

class _OnscreenKeyboardState extends State<OnscreenKeyboard>
    implements OnscreenKeyboardController {
  /// Whether to show the secondary keys.
  bool get _showSecondary => _capsLock || _shift || _shiftHeld;

  final _pressedActionKeys = <String>{};
  bool _shift = false;
  bool _capsLock = false;
  DateTime? _lastShiftTap;

  /// Shift is physically held down; letters typed meanwhile stay uppercase
  /// and the release is not counted as a tap.
  bool _shiftHeld = false;
  bool _typedWhileShiftHeld = false;

  /// The current one-shot shift was armed automatically at a field or
  /// sentence start. Only an automatically armed shift is disarmed again
  /// automatically; a manual tap always wins.
  bool _autoShift = false;

  /// Two shift taps within this window toggle caps lock.
  static const Duration shiftDoubleTapWindow = Duration(seconds: 1);
  Locale _locale = const Locale('en');
  late OnscreenKeyboardTypingMode _typingMode = widget.typingMode;
  List<OnscreenKeyboardSuggestion> _suggestions = const [];
  String? _suggestionPrefix;
  OnscreenKeyboardCancellationToken? _requestToken;
  TextEditingValue? _correctionBefore;
  TextEditingValue? _correctionAfter;
  String? _correctionOriginal;
  String? _correctionReplacement;
  List<String> _correctionPreviousWords = const [];
  final List<OnscreenKeyboardTapSample> _tapSamples = [];
  Map<String, Offset> _keyCenters = const {};
  DateTime? _lastSpaceTap;
  TextEditingValue? _swipeBefore;
  TextEditingValue? _swipeAfter;
  OnscreenKeyboardSwipeData? _lastSwipeGesture;
  List<OnscreenKeyboardSuggestion> _lastSwipeSuggestions = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.locale == null) {
      final next = Localizations.maybeLocaleOf(context) ?? const Locale('en');
      if (_locale != next) _locale = next;
    } else {
      _locale = widget.locale!;
    }
    _ensureValidMode();
  }

  @override
  void didUpdateWidget(covariant OnscreenKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      close();
    }
    if (widget.locale != oldWidget.locale && widget.locale != null) {
      _locale = widget.locale!;
    }
    if (widget.typingMode != oldWidget.typingMode) {
      _typingMode = widget.typingMode;
    }
    if (widget.languageModel != oldWidget.languageModel ||
        widget.typingMode != oldWidget.typingMode ||
        widget.locale != oldWidget.locale ||
        widget.layout != oldWidget.layout ||
        widget.layoutResolver != oldWidget.layoutResolver ||
        widget.swipeTypingEnabled != oldWidget.swipeTypingEnabled) {
      _requestToken?.cancel();
      _suggestions = const [];
      _suggestionPrefix = null;
      _tapSamples.clear();
      _keyCenters = const {};
      if (!widget.swipeTypingEnabled) _clearSwipeUndo();
      _ensureValidMode();
      unawaited(_refreshSuggestions());
    }
  }

  @override
  KeyboardLayout get layout => _resolveLayout();

  void _onKeyDown(OnscreenKeyboardKey key) {
    switch (key) {
      case TextKey():
        _handleTexTextKeyDown(key);
      case ActionKey():
        _handleActionKeyDown(key);
    }

    for (final listener in _rawKeyDownListeners) {
      listener(key);
    }
  }

  void _onKeyUp(OnscreenKeyboardKey key) {
    switch (key) {
      case TextKey():
        break;
      case ActionKey():
        _handleActionKeyUp(key);
    }
  }

  void _handleTexTextKeyDown(TextKey key) {
    _acceptPendingCorrection();
    final text = key.getText(secondary: _showSecondary);
    final isBoundary = _isWordBoundary(text);
    final field = activeTextField;
    final boundaryRange = isBoundary && field != null
        ? _currentWordRange(field.controller.value)
        : TextRange.empty;
    final boundaryOriginal = field == null || boundaryRange.isCollapsed
        ? ''
        : field.controller.text.substring(
            boundaryRange.start,
            boundaryRange.end,
          );
    final cachedSuggestionsMatch =
        boundaryOriginal.isNotEmpty &&
        _suggestionPrefix?.toLowerCase() == boundaryOriginal.toLowerCase();
    final corrected = isBoundary && _maybeApplyCachedCorrection();
    final resolveCorrectionAfterBoundary =
        isBoundary &&
        !corrected &&
        !cachedSuggestionsMatch &&
        boundaryOriginal.isNotEmpty &&
        _canRequestBoundaryCorrection(field);
    final beforeBoundary = resolveCorrectionAfterBoundary
        ? field!.controller.value
        : null;
    final previousWords = resolveCorrectionAfterBoundary
        ? _wordsBeforeCursor(includeCurrent: false)
        : const <String>[];
    final boundaryTapSamples = resolveCorrectionAfterBoundary
        ? List<OnscreenKeyboardTapSample>.unmodifiable(_tapSamples)
        : const <OnscreenKeyboardTapSample>[];
    final boundaryKeyCenters = resolveCorrectionAfterBoundary
        ? Map<String, Offset>.unmodifiable(_keyCenters)
        : const <String, Offset>{};
    if (isBoundary) {
      _tapSamples.clear();
      _keyCenters = const {};
    }
    final handled =
        (text == ' ' && _maybeInsertDoubleSpacePeriod()) ||
        (_isPunctuation(text) && _replaceSpaceWithPunctuation(text));
    if (!handled) _insertText(text);
    if (corrected) _correctionAfter = activeTextField?.controller.value;
    if (text != ' ') _lastSpaceTap = null;
    _clearSwipeUndoUnlessCurrent();
    if (_shiftHeld && text.trim().isNotEmpty) {
      _typedWhileShiftHeld = true;
      if (_shift) {
        setState(() {
          _shift = false;
          _autoShift = false;
          _lastShiftTap = null;
        });
      }
    } else if (_shift && !_capsLock && text.trim().isNotEmpty) {
      setState(() {
        _shift = false;
        _autoShift = false;
        _lastShiftTap = null;
        _pressedActionKeys.remove(ActionKeyType.shift);
      });
    }
    _maybeAutoShift();
    final afterBoundary = field?.controller.value;
    if (resolveCorrectionAfterBoundary &&
        beforeBoundary != null &&
        afterBoundary != null &&
        afterBoundary != beforeBoundary) {
      unawaited(
        _resolveCorrectionAfterBoundary(
          field: field!,
          beforeBoundary: beforeBoundary,
          afterBoundary: afterBoundary,
          wordRange: boundaryRange,
          original: boundaryOriginal,
          previousWords: previousWords,
          tapSamples: boundaryTapSamples,
          keyCenters: boundaryKeyCenters,
        ),
      );
    } else {
      unawaited(_afterTextInput(text, learnBoundary: !corrected));
    }
  }

  /// Applies the armed shift to a word inserted as a whole (swipe
  /// candidate, accepted suggestion) the way typing its first letter would.
  String _casedWord(String word) {
    if (word.isEmpty) return word;
    if (_capsLock) return word.toUpperCase();
    if (_shift || _shiftHeld) {
      return word[0].toUpperCase() + word.substring(1);
    }
    return word;
  }

  /// A whole word consumed the one-shot shift exactly like a letter does.
  void _consumeShiftAfterWord() {
    if (_shiftHeld) {
      _typedWhileShiftHeld = true;
    }
    if (_shift && !_capsLock) {
      setState(() {
        _shift = false;
        _autoShift = false;
        _lastShiftTap = null;
        if (!_shiftHeld) _pressedActionKeys.remove(ActionKeyType.shift);
      });
    }
    _maybeAutoShift();
  }

  void _insertText(String text, {bool replaceCurrentWord = false}) {
    final field = activeTextField;
    final controller = field?.controller;
    if (field == null || controller == null || !controller.selection.isValid) {
      return;
    }
    var start = controller.selection.start;
    final end = controller.selection.end;
    if (replaceCurrentWord && controller.selection.isCollapsed) {
      start = _currentWordRange(controller.value).start;
    }
    _replaceRange(start, end, text);
  }

  bool _replaceRange(int start, int end, String text) {
    final field = activeTextField;
    final controller = field?.controller;
    if (field == null || controller == null) return false;
    final oldValue = controller.value;
    var newValue = TextEditingValue(
      text: controller.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    for (final formatter
        in field.inputFormatters ?? const <TextInputFormatter>[]) {
      newValue = formatter.formatEditUpdate(oldValue, newValue);
    }
    if (newValue == oldValue) return false;
    controller.value = newValue;
    if (newValue.text != oldValue.text) field.onChanged?.call(newValue.text);
    return true;
  }

  bool _isPunctuation(String text) =>
      text.length == 1 && RegExp('[.,!?;:]').hasMatch(text);

  bool _replaceSpaceWithPunctuation(String punctuation) {
    final controller = activeTextField?.controller;
    if (controller == null ||
        !controller.selection.isValid ||
        !controller.selection.isCollapsed ||
        controller.selection.start < 1 ||
        controller.text[controller.selection.start - 1] != ' ') {
      return false;
    }
    final offset = controller.selection.start;
    return _replaceRange(offset - 1, offset, punctuation);
  }

  bool _maybeInsertDoubleSpacePeriod() {
    if (!widget.editingGestures.doubleSpacePeriod) return false;
    final now = DateTime.now();
    final controller = activeTextField?.controller;
    final offset = controller?.selection.start ?? -1;
    final isDoubleTap =
        _lastSpaceTap != null &&
        now.difference(_lastSpaceTap!) <= const Duration(milliseconds: 350);
    _lastSpaceTap = now;
    if (!isDoubleTap ||
        controller == null ||
        !controller.selection.isValid ||
        !controller.selection.isCollapsed ||
        offset < 2 ||
        controller.text[offset - 1] != ' ' ||
        !RegExp(
          r'[\p{L}\p{N}\p{M}]',
          unicode: true,
        ).hasMatch(controller.text[offset - 2])) {
      return false;
    }
    _lastSpaceTap = null;
    return _replaceRange(offset - 1, offset, '. ');
  }

  bool _isWordBoundary(String text) => RegExp(r'^\s|[.,!?;:]$').hasMatch(text);

  Future<void> _afterTextInput(String text, {bool learnBoundary = true}) async {
    if (_isWordBoundary(text) && learnBoundary) {
      final words = _wordsBeforeCursor();
      if (words.isNotEmpty &&
          activeTextField!.fieldConfiguration.allowsLearning) {
        final model = widget.languageModel;
        if (model != null && model is OnscreenKeyboardContextLanguageModel) {
          await (model as OnscreenKeyboardContextLanguageModel)
              .learnAcceptedContext(
                locale: _locale,
                word: words.last,
                previousWord: words.length > 1 ? words[words.length - 2] : null,
                previousPreviousWord: words.length > 2
                    ? words[words.length - 3]
                    : null,
              );
        } else {
          await model?.learnAcceptedWord(
            locale: _locale,
            word: words.last,
            previousWord: words.length > 1 ? words[words.length - 2] : null,
          );
        }
      }
    }
    await _refreshSuggestions();
  }

  bool _maybeApplyCachedCorrection() {
    final field = activeTextField;
    if (_typingMode != OnscreenKeyboardTypingMode.autocorrect ||
        field == null ||
        !field.fieldConfiguration.allowsAutocorrect ||
        _suggestions.isEmpty) {
      return false;
    }
    final range = _currentWordRange(field.controller.value);
    if (range.isCollapsed) return false;
    final original = field.controller.text.substring(range.start, range.end);
    if (_suggestionPrefix?.toLowerCase() != original.toLowerCase()) {
      return false;
    }
    final candidate = _automaticCorrectionFor(original, _suggestions);
    if (candidate == null) return false;
    _correctionOriginal = original;
    _correctionReplacement = candidate.word;
    _correctionPreviousWords = _wordsBeforeCursor(includeCurrent: false);
    _correctionBefore = field.controller.value;
    _insertText(candidate.word, replaceCurrentWord: true);
    _correctionAfter = field.controller.value;
    return true;
  }

  OnscreenKeyboardSuggestion? _automaticCorrectionFor(
    String original,
    List<OnscreenKeyboardSuggestion> suggestions,
  ) {
    if (suggestions.any(
      (suggestion) =>
          suggestion.kind == OnscreenKeyboardSuggestionKind.typed &&
          suggestion.exactMatch,
    )) {
      return null;
    }
    final corrections = suggestions
        .where(
          (suggestion) =>
              suggestion.kind != OnscreenKeyboardSuggestionKind.typed,
        )
        .toList(growable: false);
    if (corrections.isEmpty) return null;
    final candidate = corrections.first;
    final margin = corrections.length < 2
        ? candidate.score
        : candidate.score - corrections[1].score;
    final requiredMargin = _locale.languageCode.toLowerCase() == 'de'
        ? 1.3
        : 1.7;
    if (candidate.word.toLowerCase() == original.toLowerCase() ||
        candidate.confidence < .985 ||
        margin < requiredMargin ||
        !_safeToCorrect(original)) {
      return null;
    }
    return candidate;
  }

  bool _canRequestBoundaryCorrection(OnscreenKeyboardFieldState? field) =>
      _typingMode == OnscreenKeyboardTypingMode.autocorrect &&
      widget.languageModel != null &&
      field != null &&
      field.fieldConfiguration.allowsAutocorrect &&
      field.fieldConfiguration.allowsSuggestions;

  Future<void> _resolveCorrectionAfterBoundary({
    required OnscreenKeyboardFieldState field,
    required TextEditingValue beforeBoundary,
    required TextEditingValue afterBoundary,
    required TextRange wordRange,
    required String original,
    required List<String> previousWords,
    required List<OnscreenKeyboardTapSample> tapSamples,
    required Map<String, Offset> keyCenters,
  }) async {
    final model = widget.languageModel;
    if (model == null) return;
    _requestToken?.cancel();
    final token = OnscreenKeyboardCancellationToken();
    _requestToken = token;
    try {
      final result = await model.suggestions(
        OnscreenKeyboardSuggestionRequest(
          locale: _locale,
          prefix: original,
          previousWord: previousWords.isEmpty ? null : previousWords.last,
          previousPreviousWord: previousWords.length < 2
              ? null
              : previousWords[previousWords.length - 2],
          tapSamples: tapSamples,
          keyCenters: keyCenters,
          cancellationToken: token,
        ),
      );
      if (!mounted ||
          token.isCancelled ||
          token != _requestToken ||
          activeTextField != field ||
          field.controller.value != afterBoundary) {
        return;
      }
      final candidate = _automaticCorrectionFor(original, result);
      if (candidate == null) {
        await _afterTextInput(' ');
        return;
      }
      _correctionOriginal = original;
      _correctionReplacement = candidate.word;
      _correctionPreviousWords = previousWords;
      _correctionBefore = beforeBoundary;
      if (!_replaceRange(wordRange.start, wordRange.end, candidate.word)) {
        await _afterTextInput(' ');
        return;
      }
      final boundaryLength =
          afterBoundary.text.length - beforeBoundary.text.length;
      field.controller.selection = TextSelection.collapsed(
        offset: wordRange.start + candidate.word.length + boundaryLength,
      );
      _correctionAfter = field.controller.value;
      await _refreshSuggestions();
    } on OnscreenKeyboardRequestCancelled {
      // A later key press superseded this boundary correction.
    }
  }

  void _acceptPendingCorrection() {
    final original = _correctionOriginal;
    final replacement = _correctionReplacement;
    final field = activeTextField;
    if (original == null || replacement == null || field == null) return;
    if (field.controller.value == _correctionAfter &&
        field.fieldConfiguration.allowsLearning) {
      final model = widget.languageModel;
      switch (model) {
        case final OnscreenKeyboardCorrectionLearningModel correctionModel:
          unawaited(
            correctionModel.recordCorrectionOutcome(
              locale: _locale,
              original: original,
              replacement: replacement,
              accepted: true,
            ),
          );
      }
      switch (model) {
        case final OnscreenKeyboardContextLanguageModel contextModel:
          unawaited(
            contextModel.learnAcceptedContext(
              locale: _locale,
              word: replacement,
              previousWord: _correctionPreviousWords.isEmpty
                  ? null
                  : _correctionPreviousWords.last,
              previousPreviousWord: _correctionPreviousWords.length < 2
                  ? null
                  : _correctionPreviousWords[_correctionPreviousWords.length -
                        2],
            ),
          );
        default:
          unawaited(
            model?.learnAcceptedWord(
              locale: _locale,
              word: replacement,
              previousWord: _correctionPreviousWords.isEmpty
                  ? null
                  : _correctionPreviousWords.last,
            ),
          );
      }
    }
    _clearCorrectionUndo();
  }

  void _clearCorrectionUndo() {
    _correctionBefore = null;
    _correctionAfter = null;
    _correctionOriginal = null;
    _correctionReplacement = null;
    _correctionPreviousWords = const [];
  }

  bool _safeToCorrect(String word) =>
      word == word.toLowerCase() &&
      RegExp(r'^[\p{L}]+$', unicode: true).hasMatch(word) &&
      !word.contains(RegExp(r'[/@._\d]'));

  void _handleActionKeyDown(ActionKey key) {
    if (key.name == ActionKeyType.language) {
      switchLocale();
      return;
    }
    if (key.name == ActionKeyType.shift) {
      _beginShiftHold();
      return;
    }
    if (key.name == ActionKeyType.capslock) {
      _handleShift(key.name);
      return;
    }
    if (!key.canHold) {
      setState(() => _pressedActionKeys.add(key.name));
    }

    if (activeTextField?.controller case final controller?
        when controller.selection.isValid) {
      final originalText = controller.text;

      switch (key.name) {
        case ActionKeyType.backspace:
          if (undoLastCorrection()) return;
          if (_undoLastSwipe()) return;
          if (controller.text.isEmpty) return;
          String? newText;
          int? offset;
          if (!controller.selection.isCollapsed) {
            newText = controller.text.replaceRange(
              controller.start,
              controller.end,
              '',
            );
            offset = controller.start;
          } else if (controller.start > 0) {
            // handling emojis
            final leftSide = controller.text
                .substring(0, controller.start)
                .characters
                .toList();
            final rightSide = controller.text.substring(controller.start);
            offset = controller.start - leftSide.removeLast().length;
            newText = leftSide.join() + rightSide;
          }
          if (newText != null && offset != null) {
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: offset),
            );

            // Call onChanged callback if text changed
            if (newText != originalText && activeTextField!.onChanged != null) {
              activeTextField!.onChanged!(newText);
            }
          }
          _maybeAutoShift();

        case ActionKeyType.tab:
          if (!controller.selection.isValid) return;
          final newText = controller.text.replaceRange(
            controller.start,
            controller.end,
            '\t',
          );
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: controller.start + 1),
          );

          // Call onChanged callback if text changed
          if (newText != originalText && activeTextField!.onChanged != null) {
            activeTextField!.onChanged!(newText);
          }

        case ActionKeyType.enter:
          if (!controller.selection.isValid) return;
          final action = activeTextField!.fieldConfiguration.inputAction;
          if (activeTextField!.fieldConfiguration.multiline &&
              (action == null || action == TextInputAction.newline)) {
            final newText = controller.text.replaceRange(
              controller.start,
              controller.end,
              '\n',
            );
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: controller.start + 1),
            );

            // Call onChanged callback if text changed
            if (newText != originalText && activeTextField!.onChanged != null) {
              activeTextField!.onChanged!(newText);
            }
            _maybeAutoShift();
          } else {
            activeTextField!.onEditingComplete?.call();
            activeTextField!.onSubmitted?.call(controller.text);
            if (action == TextInputAction.next) {
              activeTextField!.focusNode.nextFocus();
            } else {
              activeTextField!.focusNode.unfocus();
            }
          }

        case ActionKeyType.capslock:
          break;
        case ActionKeyType.shift:
          break;
      }
    }
  }

  void _handleActionKeyUp(ActionKey key) {
    if (key.name == ActionKeyType.shift) {
      _endShiftHold();
      return;
    }
    if (key.name == ActionKeyType.capslock) return;
    _safeSetState(() {
      if (key.canHold && !_pressedActionKeys.contains(key.name)) {
        _pressedActionKeys.add(key.name);
      } else {
        _pressedActionKeys.remove(key.name);
      }
    });
  }

  void _beginShiftHold() {
    setState(() {
      _shiftHeld = true;
      _typedWhileShiftHeld = false;
      if (!_capsLock) _pressedActionKeys.add(ActionKeyType.shift);
    });
  }

  void _endShiftHold() {
    if (!_shiftHeld) return;
    final typedWhileHeld = _typedWhileShiftHeld;
    setState(() {
      _shiftHeld = false;
      _typedWhileShiftHeld = false;
    });
    if (typedWhileHeld) {
      // Holding shift typed its capitals; the release is not a tap.
      setState(() {
        _lastShiftTap = null;
        _pressedActionKeys.remove(ActionKeyType.shift);
        if (_shift) _pressedActionKeys.add(ActionKeyType.shift);
      });
      return;
    }
    _handleShift(ActionKeyType.shift);
  }

  void _handleShift(String name) {
    // clock.now() so the double-tap window follows the test clock.
    final now = clock.now();
    final doubleTap =
        _lastShiftTap != null &&
        now.difference(_lastShiftTap!) <= shiftDoubleTapWindow;
    // Only a tap that arms shift from off can start a double tap. Disarming
    // and quickly re-arming, or leaving caps lock, must never lock again.
    final armsShift = !doubleTap && !_capsLock && !_shift;
    setState(() {
      _autoShift = false;
      if (name == ActionKeyType.capslock || doubleTap) {
        _capsLock = !_capsLock;
        _shift = false;
      } else if (_capsLock) {
        _capsLock = false;
        _shift = false;
      } else {
        _shift = !_shift;
      }
      _pressedActionKeys
        ..remove(ActionKeyType.shift)
        ..remove(ActionKeyType.capslock);
      if (_capsLock) {
        _pressedActionKeys.add(ActionKeyType.capslock);
      } else if (_shift) {
        _pressedActionKeys.add(ActionKeyType.shift);
      }
    });
    _lastShiftTap = armsShift && name == ActionKeyType.shift ? now : null;
  }

  /// Arms a one-shot shift at the start of a language field or sentence,
  /// the way phone keyboards do, and disarms it again when the cursor
  /// leaves such a position without a letter having been typed. Runs only
  /// with an active typing mode: `off` stays fully manual.
  void _maybeAutoShift() {
    if (_typingMode == OnscreenKeyboardTypingMode.off) return;
    if (_capsLock || _shiftHeld) return;
    final field = activeTextField;
    if (field == null) return;
    final configuration = field.fieldConfiguration;
    if (!configuration.isLanguageInput ||
        configuration.obscureText ||
        configuration.readOnly) {
      return;
    }
    final value = field.controller.value;
    if (!value.selection.isValid || !value.selection.isCollapsed) return;
    final before = value.text.substring(0, value.selection.start);
    final sentenceStart =
        before.trim().isEmpty ||
        RegExp(r'[.!?]\s+$').hasMatch(before) ||
        RegExp(r'\n\s*$').hasMatch(before);
    if (sentenceStart && !_shift) {
      setState(() {
        _shift = true;
        _autoShift = true;
        _lastShiftTap = null;
        _pressedActionKeys.add(ActionKeyType.shift);
      });
    } else if (!sentenceStart && _shift && _autoShift) {
      setState(() {
        _shift = false;
        _autoShift = false;
        _pressedActionKeys.remove(ActionKeyType.shift);
      });
    }
  }

  /// Safely call [setState] after the current frame.
  void _safeSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  /// Whether the keyboard is currently visible.
  bool _visible = false;
  Timer? _focusVisibilityTimer;

  @override
  bool get isVisible => widget.enabled && _visible;

  @override
  void open() {
    if (!widget.enabled) return;
    setState(() => _visible = true);
    _ensureActiveFieldVisible();
  }

  void _ensureActiveFieldVisible() {
    if (widget.presentation != OnscreenKeyboardPresentation.docked) return;
    final field = activeTextField;
    if (field == null) return;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _focusVisibilityTimer?.cancel();
    _focusVisibilityTimer = Timer(
      reducedMotion ? Duration.zero : const Duration(milliseconds: 190),
      () {
        _focusVisibilityTimer = null;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_scrollFieldVisible(field, reducedMotion)),
        );
      },
    );
  }

  Future<void> _scrollFieldVisible(
    OnscreenKeyboardFieldState field,
    bool reducedMotion,
  ) async {
    if (!mounted ||
        field != activeTextField ||
        !field.focusNode.hasFocus ||
        field is! State) {
      return;
    }
    final fieldState = field as State;
    if (!fieldState.mounted) return;
    final renderObject = fieldState.context.findRenderObject();
    final scrollable = Scrollable.maybeOf(
      fieldState.context,
      axis: Axis.vertical,
    );
    if (renderObject == null || scrollable == null) return;
    await scrollable.position.ensureVisible(
      renderObject,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: const Cubic(.23, 1, .32, 1),
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void close() {
    _focusVisibilityTimer?.cancel();
    detachTextField();
    setState(() => _visible = false);
  }

  @override
  void hide() {
    _focusVisibilityTimer?.cancel();
    setState(() => _visible = false);
  }

  @override
  Locale get locale => _locale;

  @override
  OnscreenKeyboardTypingMode get typingMode => _typingMode;

  @override
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    setState(() {
      _locale = locale;
      _ensureValidMode();
      _suggestions = const [];
      _suggestionPrefix = null;
    });
    unawaited(_refreshSuggestions());
  }

  @override
  void switchLocale() => setLocale(
    _locale.languageCode.toLowerCase() == 'en'
        ? const Locale('de')
        : const Locale('en'),
  );

  @override
  void setTypingMode(OnscreenKeyboardTypingMode mode) {
    if (_typingMode == mode) return;
    setState(() {
      _typingMode = mode;
      if (mode == OnscreenKeyboardTypingMode.off) {
        _suggestions = const [];
        _suggestionPrefix = null;
        if (_autoShift) {
          _shift = false;
          _autoShift = false;
          _pressedActionKeys.remove(ActionKeyType.shift);
        }
      }
    });
    if (mode != OnscreenKeyboardTypingMode.off) _maybeAutoShift();
    unawaited(_refreshSuggestions());
  }

  @override
  bool undoLastCorrection() {
    final controller = activeTextField?.controller;
    if (controller == null ||
        _correctionBefore == null ||
        controller.value != _correctionAfter) {
      return false;
    }
    final before = _correctionBefore!;
    final original = _correctionOriginal;
    final replacement = _correctionReplacement;
    controller.value = before;
    activeTextField?.onChanged?.call(before.text);
    if (original != null &&
        replacement != null &&
        widget.languageModel is OnscreenKeyboardCorrectionLearningModel &&
        (activeTextField?.fieldConfiguration.allowsLearning ?? false)) {
      unawaited(
        (widget.languageModel! as OnscreenKeyboardCorrectionLearningModel)
            .recordCorrectionOutcome(
              locale: _locale,
              original: original,
              replacement: replacement,
              accepted: false,
            ),
      );
    }
    _clearCorrectionUndo();
    unawaited(_refreshSuggestions());
    return true;
  }

  bool _undoLastSwipe() {
    final controller = activeTextField?.controller;
    if (controller == null ||
        _swipeBefore == null ||
        controller.value != _swipeAfter) {
      return false;
    }
    final before = _swipeBefore!;
    controller.value = before;
    activeTextField?.onChanged?.call(before.text);
    _clearSwipeUndo();
    unawaited(_refreshSuggestions());
    return true;
  }

  void _clearSwipeUndoUnlessCurrent() {
    final controller = activeTextField?.controller;
    if (_swipeAfter != null && controller?.value != _swipeAfter) {
      _clearSwipeUndo();
    }
  }

  void _clearSwipeUndo() {
    _swipeBefore = null;
    _swipeAfter = null;
    _lastSwipeGesture = null;
    _lastSwipeSuggestions = const [];
  }

  @override
  Future<void> forgetSuggestion(OnscreenKeyboardSuggestion suggestion) async {
    final model = widget.languageModel;
    if (model == null ||
        model is! OnscreenKeyboardSuggestionPersonalizationModel) {
      return;
    }
    await (model as OnscreenKeyboardSuggestionPersonalizationModel).forgetWord(
      locale: _locale,
      word: suggestion.word,
    );
    await _refreshSuggestions();
  }

  void _moveCursor(int characters) {
    final controller = activeTextField?.controller;
    if (controller == null || !controller.selection.isValid) return;
    final base = controller.selection.extentOffset;
    final target = (base + characters).clamp(0, controller.text.length);
    controller.selection = TextSelection.collapsed(offset: target);
    _clearCorrectionUndo();
    _clearSwipeUndo();
    unawaited(_refreshSuggestions());
  }

  void _deletePreviousWord() {
    final controller = activeTextField?.controller;
    if (controller == null || !controller.selection.isValid) return;
    if (!controller.selection.isCollapsed) {
      _replaceRange(controller.selection.start, controller.selection.end, '');
      return;
    }
    final end = controller.selection.start;
    if (end == 0) return;
    var start = end;
    while (start > 0 && RegExp(r'\s').hasMatch(controller.text[start - 1])) {
      start--;
    }
    final isWord = RegExp(r"[\p{L}\p{M}\p{N}'’-]", unicode: true);
    while (start > 0 && isWord.hasMatch(controller.text[start - 1])) {
      start--;
    }
    if (start == end) start--;
    _replaceRange(start, end, '');
    _clearCorrectionUndo();
    _clearSwipeUndo();
    unawaited(_refreshSuggestions());
  }

  @override
  void setAlignment(Alignment alignment) {
    _alignListener.value = ((alignment.x + 1) / 2, (alignment.y + 1) / 2);
  }

  @override
  void moveToTop() => setAlignment(Alignment.topCenter);

  @override
  void moveToBottom() => setAlignment(Alignment.bottomCenter);

  @override
  void attachTextField(OnscreenKeyboardFieldState state) {
    _activeTextField.value = state;
    _ensureValidMode();
    _maybeAutoShift();
    if (_visible) _ensureActiveFieldVisible();
    unawaited(_refreshSuggestions());
  }

  @override
  void detachTextField([OnscreenKeyboardFieldState? state]) {
    if (state == null || state == activeTextField) {
      _activeTextField.value = null;
      _requestToken?.cancel();
      _suggestions = const [];
      _suggestionPrefix = null;
    }
  }

  final _activeTextField = ValueNotifier<OnscreenKeyboardFieldState?>(null);

  OnscreenKeyboardFieldState? get activeTextField => _activeTextField.value;

  /// List of raw key down listeners.
  final _rawKeyDownListeners = ObserverList<OnscreenKeyboardListener>();

  @override
  void addRawKeyDownListener(OnscreenKeyboardListener listener) {
    _rawKeyDownListeners.add(listener);
  }

  @override
  void removeRawKeyDownListener(OnscreenKeyboardListener listener) {
    _rawKeyDownListeners.remove(listener);
  }

  /// Returns the default keyboard layout based on the current platform.
  KeyboardLayout _getDefaultLayout() =>
      widget.presentation == OnscreenKeyboardPresentation.docked
      ? PhoneKeyboardLayout(
          locale: _locale,
          fieldConfiguration: activeTextField?.fieldConfiguration,
        )
      : switch (defaultTargetPlatform) {
          TargetPlatform.android ||
          TargetPlatform.iOS ||
          TargetPlatform.fuchsia => const MobileKeyboardLayout(),
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux => const DesktopKeyboardLayout(),
        };

  /// The resolved layout used by the keyboard.
  KeyboardLayout _resolveLayout() =>
      widget.layoutResolver?.call(
        context,
        _locale,
        activeTextField?.fieldConfiguration,
      ) ??
      widget.layout ??
      _getDefaultLayout();

  /// The current active keyboard mode (e.g., "alphabetic", "symbols").
  ///
  /// This determines which layout mode from [KeyboardLayout.modes] is used.
  String _mode = '';

  void _ensureValidMode() {
    final modes = _resolveLayout().modes;
    if (!modes.containsKey(_mode)) _mode = modes.keys.first;
  }

  @override
  void switchMode() {
    final modes = layout.modes.keys.toList();
    final i = modes.indexOf(_mode);
    setState(() => _mode = modes[(i + 1) % modes.length]);
  }

  @override
  void setModeNamed(String modeName) {
    if (_mode == modeName) return;

    if (layout.modes.containsKey(modeName)) {
      setState(() {
        _mode = modeName;
      });
    } else {
      debugPrint(
        "OnScreenKeyboard: Keyboard mode '$modeName' "
        'not found on the KeyboardLayout.',
      );
    }
  }

  Future<void> _refreshSuggestions() async {
    final model = widget.languageModel;
    final field = activeTextField;
    _requestToken?.cancel();
    if (model == null ||
        field == null ||
        _typingMode == OnscreenKeyboardTypingMode.off ||
        !field.fieldConfiguration.allowsSuggestions) {
      _suggestionPrefix = null;
      if (mounted && _suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }
    final token = OnscreenKeyboardCancellationToken();
    _requestToken = token;
    final words = _wordsBeforeCursor(includeCurrent: false);
    final range = _currentWordRange(field.controller.value);
    final prefix = field.controller.text.substring(range.start, range.end);
    try {
      final result = await model.suggestions(
        OnscreenKeyboardSuggestionRequest(
          locale: _locale,
          prefix: prefix,
          previousWord: words.isEmpty ? null : words.last,
          previousPreviousWord: words.length < 2
              ? null
              : words[words.length - 2],
          tapSamples: List.unmodifiable(_tapSamples),
          keyCenters: _keyCenters,
          cancellationToken: token,
        ),
      );
      if (!mounted || token.isCancelled || token != _requestToken) return;
      setState(() {
        _suggestions = result;
        _suggestionPrefix = prefix;
      });
    } on OnscreenKeyboardRequestCancelled {
      // A newer edit superseded this request.
    }
  }

  Future<void> _previewSwipeData(OnscreenKeyboardSwipeData data) =>
      _decodeSwipe(
        data.trace,
        points: data.points,
        keyCenters: data.keyCenters,
        commit: false,
      );

  bool get _swipeEnabled =>
      widget.swipeTypingEnabled &&
      _typingMode != OnscreenKeyboardTypingMode.off &&
      (activeTextField?.fieldConfiguration.allowsSuggestions ?? false) &&
      widget.languageModel is OnscreenKeyboardSwipeModel;

  void _handleTapSample(OnscreenKeyboardTapSample sample) {
    final field = activeTextField;
    if (field == null ||
        _typingMode == OnscreenKeyboardTypingMode.off ||
        !field.fieldConfiguration.allowsSuggestions) {
      return;
    }
    final range = _currentWordRange(field.controller.value);
    final prefix = field.controller.text.substring(range.start, range.end);
    if (prefix.isEmpty) return;
    _tapSamples.add(sample);
    if (_tapSamples.length > prefix.characters.length) {
      _tapSamples.removeRange(0, _tapSamples.length - prefix.characters.length);
    }
    _keyCenters = {
      ..._keyCenters,
      ...sample.keyCenters,
      sample.character.toLowerCase(): sample.keyCenter,
    };
    unawaited(_refreshSuggestions());
  }

  Future<void> _handleSwipeData(OnscreenKeyboardSwipeData data) => _decodeSwipe(
    data.trace,
    points: data.points,
    keyCenters: data.keyCenters,
    commit: true,
  );

  Future<void> _decodeSwipe(
    List<String> trace, {
    required bool commit,
    List<Offset> points = const [],
    Map<String, Offset> keyCenters = const {},
  }) async {
    final model = widget.languageModel;
    final field = activeTextField;
    if (field == null ||
        _typingMode == OnscreenKeyboardTypingMode.off ||
        !field.fieldConfiguration.allowsSuggestions) {
      return;
    }
    final swipeModel = switch (model) {
      final OnscreenKeyboardSwipeModel value => value,
      _ => null,
    };
    if (swipeModel == null) return;
    _requestToken?.cancel();
    final token = OnscreenKeyboardCancellationToken();
    _requestToken = token;
    final words = _wordsBeforeCursor(includeCurrent: false);
    try {
      final result = await swipeModel.decodeSwipe(
        OnscreenKeyboardSwipeRequest(
          locale: _locale,
          trace: trace,
          previousWord: words.isEmpty ? null : words.last,
          previousPreviousWord: words.length < 2
              ? null
              : words[words.length - 2],
          cancellationToken: token,
          points: points,
          keyCenters: keyCenters,
          onDiagnostic: commit ? widget.onSwipeDiagnostic : null,
        ),
      );
      if (!mounted || token.isCancelled || token != _requestToken) return;
      if (result.isNotEmpty) {
        _lastSwipeGesture = OnscreenKeyboardSwipeData(
          trace: List.unmodifiable(trace),
          points: List.unmodifiable(points),
          keyCenters: Map.unmodifiable(keyCenters),
        );
        _lastSwipeSuggestions = result;
        if (commit) {
          final margin = result.length < 2
              ? result.first.score
              : result.first.score - result[1].score;
          if (result.first.confidence >= widget.minimumSwipeConfidence &&
              margin >= widget.minimumSwipeScoreMargin) {
            _swipeBefore = field.controller.value;
            _insertText(
              '${_casedWord(result.first.word)} ',
              replaceCurrentWord: true,
            );
            _swipeAfter = field.controller.value;
            _consumeShiftAfterWord();
          }
        }
        setState(() => _suggestions = result);
      }
    } on OnscreenKeyboardRequestCancelled {
      // A newer gesture superseded this request.
    }
  }

  void _acceptSuggestion(OnscreenKeyboardSuggestion suggestion) {
    final previousWords = _wordsBeforeCursor(includeCurrent: false);
    final previous = previousWords.isEmpty ? null : previousWords.last;
    final previousPrevious = previousWords.length < 2
        ? null
        : previousWords[previousWords.length - 2];
    final isSwipeAlternative = _lastSwipeSuggestions.contains(suggestion);
    if (isSwipeAlternative &&
        _swipeBefore != null &&
        activeTextField?.controller.value == _swipeAfter) {
      activeTextField!.controller.value = _swipeBefore!;
    }
    _insertText('${_casedWord(suggestion.word)} ', replaceCurrentWord: true);
    _consumeShiftAfterWord();
    if (isSwipeAlternative &&
        _lastSwipeGesture != null &&
        widget.languageModel is OnscreenKeyboardSwipeLearningModel) {
      unawaited(
        (widget.languageModel! as OnscreenKeyboardSwipeLearningModel)
            .learnSwipeGesture(
              locale: _locale,
              word: suggestion.word,
              gesture: _lastSwipeGesture!,
            ),
      );
    }
    _clearSwipeUndo();
    if (activeTextField?.fieldConfiguration.allowsLearning ?? false) {
      final model = widget.languageModel;
      if (model != null && model is OnscreenKeyboardContextLanguageModel) {
        unawaited(
          (model as OnscreenKeyboardContextLanguageModel).learnAcceptedContext(
            locale: _locale,
            word: suggestion.word,
            previousWord: previous,
            previousPreviousWord: previousPrevious,
          ),
        );
      } else {
        unawaited(
          model?.learnAcceptedWord(
                locale: _locale,
                word: suggestion.word,
                previousWord: previous,
              ) ??
              Future<void>.value(),
        );
      }
    }
    unawaited(_refreshSuggestions());
  }

  TextRange _currentWordRange(TextEditingValue value) {
    if (!value.selection.isValid ||
        value.selection.start < 0 ||
        value.selection.end < 0) {
      return TextRange.collapsed(value.text.length);
    }
    var start = value.selection.start;
    var end = value.selection.end;
    final isWord = RegExp(r"[\p{L}\p{M}'’-]", unicode: true);
    while (start > 0 && isWord.hasMatch(value.text[start - 1])) {
      start--;
    }
    while (end < value.text.length && isWord.hasMatch(value.text[end])) {
      end++;
    }
    return TextRange(start: start, end: end);
  }

  List<String> _wordsBeforeCursor({bool includeCurrent = true}) {
    final controller = activeTextField?.controller;
    if (controller == null) return const [];
    if (!controller.selection.isValid || controller.selection.start < 0) {
      return RegExp(r"[\p{L}\p{M}'’-]+", unicode: true)
          .allMatches(controller.text)
          .map((match) => match.group(0)!)
          .toList(growable: false);
    }
    var end = controller.selection.start;
    if (!includeCurrent) end = _currentWordRange(controller.value).start;
    return RegExp(r"[\p{L}\p{M}'’-]+", unicode: true)
        .allMatches(controller.text.substring(0, end))
        .map((match) => match.group(0)!)
        .toList(growable: false);
  }

  Widget _buildSuggestionBar(BuildContext context) {
    final undo = _correctionBefore == null ? null : undoLastCorrection;
    if (widget.suggestionBarBuilder case final builder?) {
      return builder(context, _suggestions, _acceptSuggestion, undo);
    }
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (undo != null)
            IconButton(
              onPressed: undo,
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'Undo correction',
            ),
          for (final suggestion in _suggestions.take(3))
            Expanded(
              child: TextButton(
                onPressed: () => _acceptSuggestion(suggestion),
                onLongPress: () => forgetSuggestion(suggestion),
                child: Text(
                  suggestion.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          if (_suggestions.isEmpty) const Spacer(),
          IconButton(
            onPressed: switchLocale,
            icon: const Icon(Icons.language_rounded),
            tooltip: _locale.languageCode.toUpperCase(),
          ),
          IconButton(
            onPressed: hide,
            icon: const Icon(Icons.keyboard_hide_rounded),
            tooltip: 'Hide keyboard',
          ),
        ],
      ),
    );
  }

  Widget _buildDocked(BuildContext context, KeyboardLayout resolvedLayout) {
    final media = MediaQuery.of(context);
    final reducedMotion = media.disableAnimations;
    final keyboardVisible = widget.enabled && _visible;
    final maximumHeight = math.min(media.size.height * .55, 440).toDouble();
    final minimumHeight = maximumHeight < 270 ? maximumHeight : 270.0;
    final calculatedHeight =
        (media.size.width / resolvedLayout.aspectRatio +
                (widget.showControlBar ? 44 : 0))
            .clamp(minimumHeight, maximumHeight);
    final targetHeight = widget.dockedHeight?.call(context) ?? calculatedHeight;
    return TweenAnimationBuilder<double>(
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: const Cubic(.23, 1, .32, 1),
      tween: Tween(end: keyboardVisible ? targetHeight : 0),
      builder: (context, inset, _) => Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery(
            data: media,
            child: Padding(
              padding: EdgeInsets.only(bottom: inset),
              child: widget.child,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: SizedBox(
                width: double.infinity,
                height: inset,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: targetHeight,
                  maxHeight: targetHeight,
                  child: _buildDockedPanel(context, resolvedLayout),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockedPanel(
    BuildContext context,
    KeyboardLayout resolvedLayout,
  ) {
    final theme = context.theme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: TextFieldTapRegion(
        child: ColoredBox(
          color: theme.color ?? Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: theme.padding ?? EdgeInsets.zero,
              child: Column(
                children: [
                  if (widget.showControlBar) _buildSuggestionBar(context),
                  Expanded(
                    child: RawOnscreenKeyboard(
                      aspectRatio: widget.aspectRatio,
                      fillAvailableSpace: true,
                      onKeyDown: _onKeyDown,
                      onKeyUp: _onKeyUp,
                      onAlternate: _insertText,
                      onSpaceCursorMove:
                          widget.editingGestures.spaceCursorControl
                          ? _moveCursor
                          : null,
                      onDeleteWord: widget.editingGestures.wordDelete
                          ? _deletePreviousWord
                          : null,
                      onTapSample: _handleTapSample,
                      onSwipeData: _swipeEnabled ? _handleSwipeData : null,
                      onSwipeDataUpdate: _swipeEnabled
                          ? _previewSwipeData
                          : null,
                      feedback: widget.feedback,
                      layout: resolvedLayout,
                      mode: _mode,
                      pressedActionKeys: _pressedActionKeys,
                      showSecondary: _showSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  final GlobalKey _keyboardKey = GlobalKey();

  /// Alignment of the keyboard
  final ValueNotifier<(double, double)> _alignListener = ValueNotifier((.5, 1));

  /// Whether the keyboard is currently being dragged.
  final ValueNotifier<bool> _draggingListener = ValueNotifier(false);

  @override
  void dispose() {
    _requestToken?.cancel();
    _focusVisibilityTimer?.cancel();
    _activeTextField.dispose();
    _alignListener.dispose();
    _draggingListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLayout = _resolveLayout();
    final resolvedTheme =
        widget.theme ??
        (widget.presentation == OnscreenKeyboardPresentation.docked
            ? OnscreenKeyboardThemeData.phone(context)
            : const OnscreenKeyboardThemeData());
    if (!resolvedLayout.modes.containsKey(_mode)) {
      _mode = resolvedLayout.modes.keys.first;
    }
    assert(
      resolvedLayout.modes.isNotEmpty,
      'Keyboard layout must have at least one mode defined.',
    );

    return _OnscreenKeyboardProvider(
      state: this,
      child: OnscreenKeyboardTheme(
        data: resolvedTheme,
        child: widget.presentation == OnscreenKeyboardPresentation.docked
            ? _RetargetableOverlay(child: _buildDocked(context, resolvedLayout))
            : _buildFloating(context, resolvedLayout),
      ),
    );
  }

  Widget _buildFloating(BuildContext context, KeyboardLayout resolvedLayout) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => OnscreenKeyboardTheme(
            data: widget.theme ?? const OnscreenKeyboardThemeData(),
            child: Stack(
              children: [
                // the app widget
                widget.child,

                // keyboard
                if (widget.enabled && _visible)
                  Positioned.fill(
                    child: Builder(
                      builder: (context) {
                        final useSaveArea = context.theme.useSafeArea ?? true;
                        return SafeArea(
                          top: useSaveArea,
                          right: useSaveArea,
                          bottom: useSaveArea,
                          left: useSaveArea,
                          child: Builder(
                            builder: (context) {
                              // drag handle keyboard widget
                              final dragHandle = GestureDetector(
                                onPanStart: (_) =>
                                    _draggingListener.value = true,
                                onPanCancel: () =>
                                    _draggingListener.value = false,
                                onPanDown: (_) =>
                                    _draggingListener.value = true,
                                onPanEnd: (_) =>
                                    _draggingListener.value = false,
                                onPanUpdate: (details) {
                                  final keyboardSize =
                                      _keyboardKey.currentContext!.size!;
                                  _alignListener.value = (
                                    (_alignListener.value.$1 +
                                            details.delta.dx /
                                                (context.size!.width -
                                                    keyboardSize.width))
                                        .clamp(0.0, 1.0),
                                    (_alignListener.value.$2 +
                                            details.delta.dy /
                                                (context.size!.height -
                                                    keyboardSize.height))
                                        .clamp(0.0, 1.0),
                                  );
                                },
                                child: ValueListenableBuilder(
                                  valueListenable: _draggingListener,
                                  builder: (context, value, child) {
                                    if (child != null) return child;
                                    return IconButton(
                                      mouseCursor: value
                                          ? SystemMouseCursors.grabbing
                                          : SystemMouseCursors.grab,
                                      onPressed: null,
                                      icon: Icon(
                                        Icons.drag_handle_rounded,
                                        color: Theme.of(
                                          context,
                                        ).iconTheme.color,
                                      ),
                                    );
                                  },
                                  child: widget.dragHandle,
                                ),
                              );

                              final keyboard = TextFieldTapRegion(
                                child: OnscreenKeyboardTheme(
                                  data:
                                      resolvedLayout.modes[_mode]!.theme?.call(
                                        context,
                                      ) ??
                                      context.theme,
                                  child: Builder(
                                    key: _keyboardKey,
                                    builder: (context) {
                                      final colors = Theme.of(
                                        context,
                                      ).colorScheme;
                                      final theme = context.theme;
                                      final borderRadius =
                                          theme.borderRadius ??
                                          BorderRadius.circular(6);
                                      return Material(
                                        type: MaterialType.transparency,
                                        child: Container(
                                          width: widget.width?.call(context),
                                          margin: theme.margin,
                                          padding: theme.padding,
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                            color: theme.color,
                                            borderRadius: borderRadius,
                                            gradient: theme.gradient,
                                            boxShadow:
                                                theme.boxShadow ??
                                                [
                                                  BoxShadow(
                                                    color: colors.shadow.fade(
                                                      .05,
                                                    ),
                                                    spreadRadius: 5,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                          ),
                                          foregroundDecoration: BoxDecoration(
                                            borderRadius: borderRadius,
                                            border:
                                                theme.border ??
                                                Border.all(
                                                  color: colors.outline.fade(),
                                                ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (widget.showControlBar)
                                                _ControlBar(
                                                  dragHandle: dragHandle,
                                                  actions: widget
                                                      .buildControlBarActions
                                                      ?.call(context),
                                                ),
                                              RawOnscreenKeyboard(
                                                aspectRatio: widget.aspectRatio,
                                                onKeyDown: _onKeyDown,
                                                onKeyUp: _onKeyUp,
                                                onAlternate: _insertText,
                                                onSpaceCursorMove:
                                                    widget
                                                        .editingGestures
                                                        .spaceCursorControl
                                                    ? _moveCursor
                                                    : null,
                                                onDeleteWord:
                                                    widget
                                                        .editingGestures
                                                        .wordDelete
                                                    ? _deletePreviousWord
                                                    : null,
                                                onTapSample: _handleTapSample,
                                                onSwipeData: _swipeEnabled
                                                    ? _handleSwipeData
                                                    : null,
                                                onSwipeDataUpdate: _swipeEnabled
                                                    ? _previewSwipeData
                                                    : null,
                                                feedback: widget.feedback,
                                                layout: resolvedLayout,
                                                mode: _mode,
                                                pressedActionKeys:
                                                    _pressedActionKeys,
                                                showSecondary: _showSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );

                              return AnimatedBuilder(
                                animation: _alignListener,
                                builder: (context, child) => Align(
                                  alignment: Alignment(
                                    _alignListener.value.$1 * 2 - 1,
                                    _alignListener.value.$2 * 2 - 1,
                                  ),
                                  child: child,
                                ),
                                child: keyboard,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps the compatibility overlay supplied by floating presentation while
/// allowing the docked subtree to retarget whenever runtime configuration,
/// focus, visibility, or its animated inset changes.
class _RetargetableOverlay extends StatefulWidget {
  const _RetargetableOverlay({required this.child});

  final Widget child;

  @override
  State<_RetargetableOverlay> createState() => _RetargetableOverlayState();
}

class _RetargetableOverlayState extends State<_RetargetableOverlay> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => widget.child,
  );

  @override
  void didUpdateWidget(covariant _RetargetableOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

/// Default control bar widget used in the on-screen keyboard.
///
/// This bar typically appears at the top of the keyboard and provides:
class _ControlBar extends StatelessWidget {
  /// Creates a control bar for the on-screen keyboard.
  const _ControlBar({required this.dragHandle, this.actions});

  /// A widget used for dragging the keyboard.
  final Widget dragHandle;

  /// {@template controlBar.actions}
  /// Optional custom action widgets shown on the right side of the control bar.
  ///
  /// If not provided or is empty, default actions are shown:
  /// - Move to bottom
  /// - Move to top
  /// - Close keyboard
  /// {@endtemplate}
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = context.theme;

    final Widget trailing;
    if (actions != null && actions!.isNotEmpty) {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: actions!);
    } else {
      trailing = Flexible(
        child: FittedBox(
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  OnscreenKeyboard.of(context).moveToBottom();
                },
                icon: const Icon(Icons.arrow_downward_rounded),
                tooltip: 'Move to bottom',
              ),
              IconButton(
                onPressed: () {
                  OnscreenKeyboard.of(context).moveToTop();
                },
                icon: const Icon(Icons.arrow_upward_rounded),
                tooltip: 'Move to top',
              ),
              IconButton(
                onPressed: () {
                  OnscreenKeyboard.of(context).close();
                },
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: theme.controlBarColor ?? colors.surfaceContainer,
      child: IconButtonTheme(
        data: IconButtonThemeData(style: IconButton.styleFrom(iconSize: 16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [dragHandle, trailing],
        ),
      ),
    );
  }
}

/// An [InheritedWidget] that provides [OnscreenKeyboardController]
/// to its descendants.
class _OnscreenKeyboardProvider extends InheritedWidget {
  const _OnscreenKeyboardProvider({required this.state, required super.child});

  /// The state of the nearest [OnscreenKeyboard] in the widget tree.
  final _OnscreenKeyboardState state;

  @override
  bool updateShouldNotify(_OnscreenKeyboardProvider oldWidget) =>
      oldWidget.state != state;
}

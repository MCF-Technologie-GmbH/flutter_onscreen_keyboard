import 'dart:async';
import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

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
    this.suggestionBarBuilder,
    this.dockedHeight,
  });

  /// The main application child widget.
  final Widget child;

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
  final OnscreenKeyboardLanguageModel? languageModel;

  /// Optional field- and locale-aware layout resolver.
  final OnscreenKeyboardLayoutResolver? layoutResolver;

  /// Key interaction feedback.
  final OnscreenKeyboardFeedback feedback;

  /// Optional replacement for the default three-slot suggestion bar.
  final SuggestionBarBuilder? suggestionBarBuilder;

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
    OnscreenKeyboardLanguageModel? languageModel,
    OnscreenKeyboardLayoutResolver? layoutResolver,
    OnscreenKeyboardFeedback feedback = const OnscreenKeyboardFeedback(),
    SuggestionBarBuilder? suggestionBarBuilder,
    HeightGetter? dockedHeight,
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
      suggestionBarBuilder: suggestionBarBuilder,
      dockedHeight: dockedHeight,
      child: child!,
    );
  };

  /// Gets the nearest [OnscreenKeyboardController] from the widget tree.
  static OnscreenKeyboardController of(BuildContext context) {
    final provider = context
        .getInheritedWidgetOfExactType<_OnscreenKeyboardProvider>();
    assert(
      provider != null,
      '''
No OnscreenKeyboard found in context. Did you wrap your app with OnscreenKeyboard?

    MaterialApp(
      builder: OnscreenKeyboard.builder(),  // <- add this line
      home: const App(),
    )
    ''',
    );
    return provider!.state;
  }

  @override
  State<OnscreenKeyboard> createState() => _OnscreenKeyboardState();
}

class _OnscreenKeyboardState extends State<OnscreenKeyboard>
    implements OnscreenKeyboardController {
  /// Whether to show the secondary keys.
  bool get _showSecondary => _capsLock ^ _shift;

  final _pressedActionKeys = <String>{};
  bool _shift = false;
  bool _capsLock = false;
  DateTime? _lastShiftTap;
  Locale _locale = const Locale('en');
  late OnscreenKeyboardTypingMode _typingMode = widget.typingMode;
  List<OnscreenKeyboardSuggestion> _suggestions = const [];
  OnscreenKeyboardCancellationToken? _requestToken;
  TextEditingValue? _correctionBefore;
  TextEditingValue? _correctionAfter;

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
        widget.layoutResolver != oldWidget.layoutResolver) {
      _requestToken?.cancel();
      _suggestions = const [];
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
    final text = key.getText(secondary: _showSecondary);
    final corrected = _isWordBoundary(text) && _maybeApplyCachedCorrection();
    _insertText(text);
    if (corrected) _correctionAfter = activeTextField?.controller.value;
    if (_shift && !_capsLock && text.trim().isNotEmpty) {
      setState(() {
        _shift = false;
        _lastShiftTap = null;
        _pressedActionKeys.remove(ActionKeyType.shift);
      });
    }
    unawaited(_afterTextInput(text));
  }

  void _insertText(String text, {bool replaceCurrentWord = false}) {
    final field = activeTextField;
    final controller = field?.controller;
    if (field == null || controller == null || !controller.selection.isValid) {
      return;
    }
    final oldValue = controller.value;
    var start = controller.selection.start;
    final end = controller.selection.end;
    if (replaceCurrentWord && controller.selection.isCollapsed) {
      start = _currentWordRange(controller.value).start;
    }
    var newValue = TextEditingValue(
      text: controller.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    for (final formatter
        in field.inputFormatters ?? const <TextInputFormatter>[]) {
      newValue = formatter.formatEditUpdate(oldValue, newValue);
    }
    if (newValue == oldValue) return;
    controller.value = newValue;
    if (newValue.text != oldValue.text) field.onChanged?.call(newValue.text);
  }

  bool _isWordBoundary(String text) => RegExp(r'^\s|[.,!?;:]$').hasMatch(text);

  Future<void> _afterTextInput(String text) async {
    if (_isWordBoundary(text)) {
      final words = _wordsBeforeCursor();
      if (words.isNotEmpty &&
          activeTextField!.fieldConfiguration.allowsLearning) {
        await widget.languageModel?.learnAcceptedWord(
          locale: _locale,
          word: words.last,
          previousWord: words.length > 1 ? words[words.length - 2] : null,
        );
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
    final candidate = _suggestions.first;
    final margin = _suggestions.length < 2
        ? candidate.score
        : candidate.score - _suggestions[1].score;
    if (candidate.word.toLowerCase() == original.toLowerCase() ||
        candidate.confidence < .9 ||
        margin < .35 ||
        !_safeToCorrect(original)) {
      return false;
    }
    _correctionBefore = field.controller.value;
    _insertText(candidate.word, replaceCurrentWord: true);
    _correctionAfter = field.controller.value;
    return true;
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
    if (key.name == ActionKeyType.shift || key.name == ActionKeyType.capslock) {
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
    if (key.name == ActionKeyType.shift || key.name == ActionKeyType.capslock) {
      return;
    }
    _safeSetState(() {
      if (key.canHold && !_pressedActionKeys.contains(key.name)) {
        _pressedActionKeys.add(key.name);
      } else {
        _pressedActionKeys.remove(key.name);
      }
    });
  }

  void _handleShift(String name) {
    final now = DateTime.now();
    final doubleTap =
        _lastShiftTap != null &&
        now.difference(_lastShiftTap!) <= const Duration(milliseconds: 300);
    setState(() {
      if (name == ActionKeyType.capslock || doubleTap) {
        _capsLock = !_capsLock;
        _shift = false;
      } else {
        _shift = !_shift;
      }
      if (_shift || _capsLock) {
        _pressedActionKeys.add(ActionKeyType.shift);
      } else {
        _pressedActionKeys
          ..remove(ActionKeyType.shift)
          ..remove(ActionKeyType.capslock);
      }
    });
    _lastShiftTap = now;
  }

  /// Safely call [setState] after the current frame.
  void _safeSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  /// Whether the keyboard is currently visible.
  bool _visible = false;

  @override
  bool get isVisible => _visible;

  @override
  void open() => setState(() => _visible = true);

  @override
  void close() {
    detachTextField();
    setState(() => _visible = false);
  }

  @override
  void hide() => setState(() => _visible = false);

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
    });
    unawaited(_refreshSuggestions());
  }

  @override
  void switchLocale() => setLocale(
    _locale.languageCode.toLowerCase() == 'de'
        ? const Locale('en')
        : const Locale('de'),
  );

  @override
  void setTypingMode(OnscreenKeyboardTypingMode mode) {
    if (_typingMode == mode) return;
    setState(() {
      _typingMode = mode;
      if (mode == OnscreenKeyboardTypingMode.off) _suggestions = const [];
    });
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
    controller.value = before;
    activeTextField?.onChanged?.call(before.text);
    _correctionBefore = null;
    _correctionAfter = null;
    unawaited(_refreshSuggestions());
    return true;
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
    unawaited(_refreshSuggestions());
  }

  @override
  void detachTextField([OnscreenKeyboardFieldState? state]) {
    if (state == null || state == activeTextField) {
      _activeTextField.value = null;
      _requestToken?.cancel();
      _suggestions = const [];
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
          cancellationToken: token,
        ),
      );
      if (!mounted || token.isCancelled || token != _requestToken) return;
      setState(() => _suggestions = result);
    } on OnscreenKeyboardRequestCancelled {
      // A newer edit superseded this request.
    }
  }

  Future<void> _handleSwipe(List<String> trace) async {
    final model = widget.languageModel;
    final field = activeTextField;
    if (model == null ||
        field == null ||
        _typingMode == OnscreenKeyboardTypingMode.off ||
        !field.fieldConfiguration.allowsSuggestions) {
      return;
    }
    _requestToken?.cancel();
    final token = OnscreenKeyboardCancellationToken();
    _requestToken = token;
    final words = _wordsBeforeCursor(includeCurrent: false);
    try {
      final result = await model.decodeSwipe(
        OnscreenKeyboardSwipeRequest(
          locale: _locale,
          trace: trace,
          previousWord: words.isEmpty ? null : words.last,
          cancellationToken: token,
        ),
      );
      if (!mounted || token.isCancelled || token != _requestToken) return;
      if (result.isNotEmpty) {
        _insertText(result.first.word, replaceCurrentWord: true);
        setState(() => _suggestions = result);
      }
    } on OnscreenKeyboardRequestCancelled {
      // A newer gesture superseded this request.
    }
  }

  void _acceptSuggestion(OnscreenKeyboardSuggestion suggestion) {
    final previousWords = _wordsBeforeCursor(includeCurrent: false);
    final previous = previousWords.isEmpty ? null : previousWords.last;
    _insertText(suggestion.word, replaceCurrentWord: true);
    if (activeTextField?.fieldConfiguration.allowsLearning ?? false) {
      unawaited(
        widget.languageModel?.learnAcceptedWord(
              locale: _locale,
              word: suggestion.word,
              previousWord: previous,
            ) ??
            Future<void>.value(),
      );
    }
    unawaited(_refreshSuggestions());
  }

  TextRange _currentWordRange(TextEditingValue value) {
    if (!value.selection.isValid) return TextRange.empty;
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
    if (controller == null || !controller.selection.isValid) return const [];
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
      height: 48,
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
                child: Text(
                  suggestion.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    final targetHeight =
        widget.dockedHeight?.call(context) ??
        (media.size.width / resolvedLayout.aspectRatio +
                (widget.showControlBar ? 48 : 0))
            .clamp(220.0, media.size.height * .52);
    return TweenAnimationBuilder<double>(
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: const Cubic(.23, 1, .32, 1),
      tween: Tween(end: _visible ? targetHeight : 0),
      builder: (context, inset, _) => Stack(
        children: [
          MediaQuery(
            data: media.copyWith(
              viewInsets: media.viewInsets.copyWith(
                bottom: media.viewInsets.bottom + inset,
              ),
            ),
            child: widget.child,
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
    return TextFieldTapRegion(
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
                    onKeyDown: _onKeyDown,
                    onKeyUp: _onKeyUp,
                    onAlternate: _insertText,
                    onSwipe: _handleSwipe,
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
    _activeTextField.dispose();
    _alignListener.dispose();
    _draggingListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLayout = _resolveLayout();
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
        data: widget.theme ?? const OnscreenKeyboardThemeData(),
        child: widget.presentation == OnscreenKeyboardPresentation.docked
            ? _buildDocked(context, resolvedLayout)
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
                if (_visible)
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
                                                onSwipe: _handleSwipe,
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

/// Default control bar widget used in the on-screen keyboard.
///
/// This bar typically appears at the top of the keyboard and provides:
class _ControlBar extends StatelessWidget {
  /// Creates a control bar for the on-screen keyboard.
  const _ControlBar({
    required this.dragHandle,
    this.actions,
  });

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
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: actions!,
      );
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
          children: [
            dragHandle,
            trailing,
          ],
        ),
      ),
    );
  }
}

/// An [InheritedWidget] that provides [OnscreenKeyboardController]
/// to its descendants.
class _OnscreenKeyboardProvider extends InheritedWidget {
  const _OnscreenKeyboardProvider({
    required this.state,
    required super.child,
  });

  /// The state of the nearest [OnscreenKeyboard] in the widget tree.
  final _OnscreenKeyboardState state;

  @override
  bool updateShouldNotify(_OnscreenKeyboardProvider oldWidget) =>
      oldWidget.state != state;
}

import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('docked presentation retains the app-level overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => OnscreenKeyboard(
          presentation: OnscreenKeyboardPresentation.docked,
          child: Tooltip(message: 'Global action', child: child),
        ),
        home: const Scaffold(body: Text('App')),
      ),
    );

    expect(find.byTooltip('Global action'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('docked keyboard reserves an animated bottom inset', (
    tester,
  ) async {
    final childKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: OnscreenKeyboard(
          presentation: OnscreenKeyboardPresentation.docked,
          child: SizedBox.expand(
            key: childKey,
            child: const Scaffold(body: OnscreenKeyboardTextField()),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final child = tester.getRect(find.byKey(childKey));
    final keyboard = tester.getRect(find.byType(RawOnscreenKeyboard));
    expect(child.bottom, lessThanOrEqualTo(keyboard.top));
    expect(find.byType(RawOnscreenKeyboard), findsOneWidget);
  });

  testWidgets('docked keyboard remains valid in a short landscape viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);

    expect(tester.takeException(), isNull);
    expect(find.byType(RawOnscreenKeyboard), findsOneWidget);
  });

  testWidgets('docked keyboard keeps every row inside a desktop viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);

    final keyboard = tester.getRect(find.byType(RawOnscreenKeyboard));
    final bottomRow = tester.getRect(find.text('?123'));
    expect(keyboard.height, greaterThan(250));
    expect(bottomRow.bottom, lessThanOrEqualTo(720));
    expect(bottomRow.top, greaterThan(keyboard.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('docked keyboard scrolls the focused field above its panel', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OnscreenKeyboard(
          presentation: OnscreenKeyboardPresentation.docked,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 700),
                  OnscreenKeyboardTextField(focusNode: focusNode),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 190));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final field = tester.getRect(find.byType(OnscreenKeyboardTextField));
    final keyboard = tester.getRect(find.byType(RawOnscreenKeyboard));
    final scrollable = tester.getRect(find.byType(SingleChildScrollView));
    final fieldMedia = MediaQuery.of(
      tester.element(find.byType(OnscreenKeyboardTextField)),
    );
    expect(
      field.bottom,
      lessThanOrEqualTo(keyboard.top),
      reason:
          'field=$field keyboard=$keyboard scrollable=$scrollable '
          'inset=${fieldMedia.viewInsets.bottom}',
    );
  });

  testWidgets('programmatic focus tolerates an unset selection', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OnscreenKeyboard(
          presentation: OnscreenKeyboardPresentation.docked,
          languageModel: const _StaticLanguageModel(),
          typingMode: OnscreenKeyboardTypingMode.suggestions,
          child: Scaffold(
            body: OnscreenKeyboardTextField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    expect(controller.selection.start, -1);
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(tester.takeException(), isNull);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('reduced motion applies the dock inset without translation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const OnscreenKeyboard(
              presentation: OnscreenKeyboardPresentation.docked,
              child: Scaffold(body: OnscreenKeyboardTextField()),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pump();

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byWidgetPredicate(
        (widget) => widget is TweenAnimationBuilder<double>,
      ),
    );
    expect(animation.duration, Duration.zero);
    expect(animation.tween.end, greaterThan(200));
  });

  testWidgets('runtime configuration updates locale and typing mode', (
    tester,
  ) async {
    var locale = const Locale('en');
    var typingMode = OnscreenKeyboardTypingMode.suggestions;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return OnscreenKeyboard(
              presentation: OnscreenKeyboardPresentation.docked,
              locale: locale,
              typingMode: typingMode,
              child: const Scaffold(body: OnscreenKeyboardTextField()),
            );
          },
        ),
      ),
    );
    final controller = OnscreenKeyboard.of(
      tester.element(find.byType(OnscreenKeyboardTextField)),
    );

    update(() {
      locale = const Locale('de');
      typingMode = OnscreenKeyboardTypingMode.autocorrect;
    });
    await tester.pump();

    expect(controller.locale, const Locale('de'));
    expect(controller.typingMode, OnscreenKeyboardTypingMode.autocorrect);
    expect(controller.layout, isA<PhoneKeyboardLayout>());
  });

  testWidgets(
    'runtime disable closes the keyboard and blocks controller open',
    (
      tester,
    ) async {
      var enabled = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return OnscreenKeyboard(
                enabled: enabled,
                presentation: OnscreenKeyboardPresentation.docked,
                child: const Scaffold(body: OnscreenKeyboardTextField()),
              );
            },
          ),
        ),
      );
      final controller = OnscreenKeyboard.of(
        tester.element(find.byType(OnscreenKeyboardTextField)),
      );

      await tester.tap(find.byType(OnscreenKeyboardTextField));
      await tester.pump();
      expect(controller.isVisible, isTrue);

      update(() => enabled = false);
      await tester.pump();
      expect(controller.isVisible, isFalse);

      controller.open();
      await tester.pump();
      expect(controller.isVisible, isFalse);
    },
  );

  testWidgets('shift is one-shot and double tap enables caps lock', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);
    Finder semantics(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

    expect(semantics('Shift off'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_capslock_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(semantics('Shift on'), findsOneWidget);
    await tester.tap(find.text('Q'));
    await tester.pump();
    expect(semantics('Shift off'), findsOneWidget);
    await tester.tap(find.text('w'));
    expect(controller.text, 'Qw');

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(semantics('Caps Lock on'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_capslock_rounded), findsOneWidget);
    await tester.tap(find.text('E'));
    await tester.tap(find.text('R'));
    expect(controller.text, 'QwER');

    await tester.tap(find.byIcon(Icons.keyboard_capslock_rounded));
    await tester.pump();
    expect(semantics('Shift off'), findsOneWidget);
    await tester.tap(find.text('t'));
    expect(controller.text, 'QwERt');
  });

  testWidgets('multiline field shows Return and inserts a newline', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(
      tester,
      controller: controller,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 2,
      maxLines: 3,
    );

    expect(find.byIcon(Icons.keyboard_return_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_return_rounded));
    expect(controller.text, '\n');
  });

  testWidgets('repeat backspace accelerates and cancels on release', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'abcdefghij')
      ..selection = const TextSelection.collapsed(offset: 10);
    await _pumpKeyboard(tester, controller: controller);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.backspace_outlined)),
    );
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.up();
    final afterRelease = controller.text;
    await tester.pump(const Duration(milliseconds: 300));

    expect(afterRelease.length, lessThan(9));
    expect(controller.text, afterRelease);
  });

  testWidgets('long press defaults to the base key and supports sliding', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);
    var gesture = await tester.startGesture(tester.getCenter(find.text('a')));
    // Render the pressed state before the hold threshold, as a real device
    // does on the frame immediately following pointer down.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 451));

    expect(find.text('á'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(controller.text, 'a');

    final keyboardA = find.descendant(
      of: find.byType(RawOnscreenKeyboard),
      matching: find.text('a'),
    );
    gesture = await tester.startGesture(tester.getCenter(keyboardA));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 451));
    await gesture.moveTo(tester.getCenter(find.text('á')));
    await gesture.up();
    await tester.pump();
    expect(controller.text, 'aá');
  });

  testWidgets('key previews are removed after every completed press', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);
    final preview = find.byWidgetPredicate(
      (widget) => widget is Material && widget.elevation == 5,
    );

    for (final letter in ['t', 'u', 'f', 'g', 'h']) {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(letter)),
      );
      await tester.pump();
      expect(preview, findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(preview, findsNothing);
    }
  });

  testWidgets('swipe wins over tap and inserts the decoded candidate', (
    tester,
  ) async {
    final controller = TextEditingController();
    final languageModel = _TrackingLanguageModel();
    await _pumpKeyboard(
      tester,
      controller: controller,
      languageModel: languageModel,
      typingMode: OnscreenKeyboardTypingMode.suggestions,
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('h')));
    await gesture.moveTo(tester.getCenter(find.text('e')));
    await gesture.moveTo(tester.getCenter(find.text('l')));
    await gesture.moveTo(tester.getCenter(find.text('o')));
    await tester.pump(const Duration(milliseconds: 33));

    expect(languageModel.decodeCount, 1);
    expect(controller.text, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(controller.text, 'hello ');
    expect(languageModel.lastTrace, ['h', 'e', 'l', 'o']);
    expect(languageModel.lastPoints, isNotEmpty);
    expect(languageModel.lastKeyCenters, contains('h'));
  });

  testWidgets('phone keys stay compact and backspace is in the top row', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);

    final q = tester.widget<Text>(find.text('q'));
    expect(q.style?.fontSize, 24);
    expect(
      tester.getCenter(find.byIcon(Icons.backspace_outlined)).dy,
      lessThan(tester.getCenter(find.byIcon(Icons.arrow_upward_rounded)).dy),
    );
  });

  testWidgets('key press shows an immediate visual preview', (tester) async {
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);
    final gesture = await tester.startGesture(tester.getCenter(find.text('q')));
    await tester.pump();

    final preview = find.byWidgetPredicate(
      (widget) => widget is Material && widget.elevation == 5,
    );
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.text('q')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pump();
    expect(preview, findsNothing);
  });

  testWidgets('autocorrect applies at a boundary and backspace undoes it', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'helo')
      ..selection = const TextSelection.collapsed(offset: 4);
    await _pumpKeyboard(
      tester,
      controller: controller,
      languageModel: const _StaticLanguageModel(),
      typingMode: OnscreenKeyboardTypingMode.autocorrect,
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.space_bar_rounded));
    expect(controller.text, 'hello ');

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    expect(controller.text, 'helo');
  });

  testWidgets('holding space moves the cursor without inserting a space', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello')
      ..selection = const TextSelection.collapsed(offset: 5);
    await _pumpKeyboard(tester, controller: controller);
    final center = tester.getCenter(find.byIcon(Icons.space_bar_rounded));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 281));
    await gesture.moveTo(center.translate(-30, 0));
    await gesture.up();
    await tester.pump();

    expect(controller.text, 'hello');
    expect(controller.selection.baseOffset, 3);
  });

  testWidgets(
    'double space inserts a period and punctuation consumes spacing',
    (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello')
        ..selection = const TextSelection.collapsed(offset: 5);
      await _pumpKeyboard(tester, controller: controller);
      await tester.tap(find.byIcon(Icons.space_bar_rounded));
      await tester.tap(find.byIcon(Icons.space_bar_rounded));
      expect(controller.text, 'hello. ');

      controller.value = const TextEditingValue(
        text: 'hello ',
        selection: TextSelection.collapsed(offset: 6),
      );
      await tester.tap(find.text(','));
      expect(controller.text, 'hello,');
    },
  );

  testWidgets('dragging backspace left deletes the previous word', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello world')
      ..selection = const TextSelection.collapsed(offset: 11);
    await _pumpKeyboard(tester, controller: controller);
    final center = tester.getCenter(find.byIcon(Icons.backspace_outlined));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.moveTo(center.translate(-32, 0));
    await gesture.up();
    await tester.pump();

    expect(controller.text, 'hello ');
  });

  testWidgets('backspace immediately restores the last swiped text', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(
      tester,
      controller: controller,
      languageModel: const _StaticLanguageModel(),
      typingMode: OnscreenKeyboardTypingMode.suggestions,
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('h')));
    await gesture.moveTo(tester.getCenter(find.text('e')));
    await gesture.moveTo(tester.getCenter(find.text('l')));
    await gesture.moveTo(tester.getCenter(find.text('o')));
    await gesture.up();
    await tester.pump();
    expect(controller.text, 'hello ');

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    expect(controller.text, isEmpty);
  });

  testWidgets('a low confidence swipe stays as suggestions', (tester) async {
    final controller = TextEditingController();
    await _pumpKeyboard(
      tester,
      controller: controller,
      languageModel: const _LowConfidenceLanguageModel(),
      typingMode: OnscreenKeyboardTypingMode.suggestions,
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('h')));
    await gesture.moveTo(tester.getCenter(find.text('e')));
    await gesture.moveTo(tester.getCenter(find.text('l')));
    await gesture.moveTo(tester.getCenter(find.text('o')));
    await gesture.up();
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('help'), findsOneWidget);
  });
}

Future<void> _pumpKeyboard(
  WidgetTester tester, {
  required TextEditingController controller,
  OnscreenKeyboardLanguageModel? languageModel,
  OnscreenKeyboardTypingMode typingMode = OnscreenKeyboardTypingMode.off,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  int? minLines,
  int? maxLines = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OnscreenKeyboard(
        presentation: OnscreenKeyboardPresentation.docked,
        languageModel: languageModel,
        typingMode: typingMode,
        feedback: const OnscreenKeyboardFeedback(enableHaptics: false),
        child: Scaffold(
          body: OnscreenKeyboardTextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: minLines,
            maxLines: maxLines,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(OnscreenKeyboardTextField));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

class _StaticLanguageModel implements OnscreenKeyboardLanguageModel {
  const _StaticLanguageModel();

  @override
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  ) async => const [
    OnscreenKeyboardSuggestion(word: 'hello', score: 10, confidence: .99),
  ];

  @override
  Future<void> learnAcceptedWord({
    required Locale locale,
    required String word,
    String? previousWord,
  }) async {}

  @override
  Future<List<OnscreenKeyboardSuggestion>> suggestions(
    OnscreenKeyboardSuggestionRequest request,
  ) async => const [
    OnscreenKeyboardSuggestion(word: 'hello', score: 10, confidence: .99),
    OnscreenKeyboardSuggestion(word: 'help', score: 8, confidence: .8),
  ];
}

class _TrackingLanguageModel extends _StaticLanguageModel {
  int decodeCount = 0;
  List<String> lastTrace = const [];
  List<Offset> lastPoints = const [];
  Map<String, Offset> lastKeyCenters = const {};

  @override
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  ) async {
    decodeCount++;
    lastTrace = request.trace;
    lastPoints = request.points;
    lastKeyCenters = request.keyCenters;
    return super.decodeSwipe(request);
  }
}

class _LowConfidenceLanguageModel extends _StaticLanguageModel {
  const _LowConfidenceLanguageModel();

  @override
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  ) async => const [
    OnscreenKeyboardSuggestion(word: 'hello', score: 4, confidence: .4),
    OnscreenKeyboardSuggestion(word: 'help', score: 3.95, confidence: .38),
  ];
}

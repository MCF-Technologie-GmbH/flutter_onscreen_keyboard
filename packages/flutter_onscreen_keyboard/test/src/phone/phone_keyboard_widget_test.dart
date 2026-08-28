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

  testWidgets('docked keyboard propagates an animated bottom inset', (
    tester,
  ) async {
    double observedInset = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OnscreenKeyboard(
          presentation: OnscreenKeyboardPresentation.docked,
          child: Builder(
            builder: (context) {
              observedInset = MediaQuery.viewInsetsOf(context).bottom;
              return const Scaffold(body: OnscreenKeyboardTextField());
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(observedInset, greaterThan(200));
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

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.tap(find.text('q'));
    await tester.tap(find.text('w'));
    expect(controller.text, 'Qw');

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.tap(find.text('e'));
    await tester.tap(find.text('r'));
    expect(controller.text, 'QwER');
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

  testWidgets('long press inserts an alternate without inserting base key', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(tester, controller: controller);
    final gesture = await tester.startGesture(tester.getCenter(find.text('a')));
    // Render the pressed state before the hold threshold, as a real device
    // does on the frame immediately following pointer down.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 451));

    expect(find.text('á'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(controller.text, 'á');
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

    expect(controller.text, 'hello');
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
}

Future<void> _pumpKeyboard(
  WidgetTester tester, {
  required TextEditingController controller,
  OnscreenKeyboardLanguageModel? languageModel,
  OnscreenKeyboardTypingMode typingMode = OnscreenKeyboardTypingMode.off,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OnscreenKeyboard(
        presentation: OnscreenKeyboardPresentation.docked,
        languageModel: languageModel,
        typingMode: typingMode,
        feedback: const OnscreenKeyboardFeedback(enableHaptics: false),
        child: Scaffold(
          body: OnscreenKeyboardTextField(controller: controller),
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

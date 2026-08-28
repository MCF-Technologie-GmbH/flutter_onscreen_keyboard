import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    await tester.pump(const Duration(milliseconds: 451));

    expect(find.text('á'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(controller.text, 'á');
  });

  testWidgets('swipe wins over tap and inserts the decoded candidate', (
    tester,
  ) async {
    final controller = TextEditingController();
    await _pumpKeyboard(
      tester,
      controller: controller,
      languageModel: const _StaticLanguageModel(),
      typingMode: OnscreenKeyboardTypingMode.suggestions,
    );
    final start = tester.getCenter(find.text('q'));
    final end = tester.getCenter(find.text('e'));
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(end);
    await gesture.up();
    await tester.pump();

    expect(controller.text, 'hello');
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

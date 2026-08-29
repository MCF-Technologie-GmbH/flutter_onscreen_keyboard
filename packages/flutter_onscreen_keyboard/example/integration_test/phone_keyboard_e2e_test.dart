import 'dart:ui';

import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('continuous touch swipe inserts English and German words', (
    tester,
  ) async {
    await _startPlayground(tester);
    final field = find.byKey(const ValueKey('typing-and-return-field'));

    await _swipeWord(tester, const ['h', 'e', 'l', 'o']);
    await _waitForText(tester, field, 'hello ');

    await tester.tap(find.byTooltip('EN'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('DE'), findsOneWidget);
    await _swipeWord(tester, const ['h', 'a', 'l', 'o']);
    await _acceptSwipeCandidateIfNeeded(tester, field, 'hallo');
    await _waitForText(tester, field, 'hello hallo ');
  });

  testWidgets('touch hold selects an alternate and leaves no stuck preview', (
    tester,
  ) async {
    await _startPlayground(tester);
    final field = find.byKey(const ValueKey('typing-and-return-field'));
    final gesture = await tester.startGesture(
      _keyCenter(tester, 'a'),
      // Kept explicit: this scenario verifies the touch pointer path.
      // ignore: avoid_redundant_argument_values
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 475));

    expect(find.text('ä'), findsOneWidget);
    await gesture.moveTo(tester.getCenter(find.text('ä')));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_textOf(tester, field), 'ä');
    expect(_keyPreview, findsNothing);
    expect(_alternatePopover, findsNothing);
  });

  testWidgets('disabled swipe drag produces neither a trace nor text', (
    tester,
  ) async {
    await _startPlayground(tester);
    final field = find.byKey(const ValueKey('typing-and-return-field'));
    await tester.tap(find.byTooltip('Disable experimental swipe'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      _keyCenter(tester, 'h'),
      // Kept explicit: this scenario verifies the touch pointer path.
      // ignore: avoid_redundant_argument_values
      kind: PointerDeviceKind.touch,
    );
    await gesture.moveTo(_keyCenter(tester, 'e'));
    await gesture.moveTo(_keyCenter(tester, 'l'));
    await gesture.moveTo(_keyCenter(tester, 'o'));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pump();

    expect(_textOf(tester, field), isEmpty);
  });

  testWidgets('touch hold repeats backspace and stops immediately on release', (
    tester,
  ) async {
    await _startPlayground(tester);
    final field = find.byKey(const ValueKey('typing-and-return-field'));
    for (final letter in 'abcdefghij'.characters) {
      await tester.tap(_key(letter));
    }
    await tester.pump();
    expect(_textOf(tester, field), 'abcdefghij');

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.backspace_outlined)),
      // Kept explicit: this scenario verifies the touch pointer path.
      // ignore: avoid_redundant_argument_values
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump();
    final releasedText = _textOf(tester, field);
    await tester.pump(const Duration(milliseconds: 350));

    expect(releasedText.length, lessThan(9));
    expect(_textOf(tester, field), releasedText);
    expect(_keyPreview, findsNothing);
  });

  testWidgets('Shift Caps Lock and Return work through the rendered keyboard', (
    tester,
  ) async {
    await _startPlayground(tester);
    final field = find.byKey(const ValueKey('typing-and-return-field'));

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.tap(_key('Q'));
    await tester.pump();
    await tester.tap(_key('w'));

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_capslock_rounded), findsOneWidget);
    await tester.tap(_key('E'));
    await tester.tap(_key('R'));
    await tester.tap(find.byIcon(Icons.keyboard_capslock_rounded));
    await tester.pump();
    await tester.tap(_key('t'));
    await tester.tap(find.byIcon(Icons.keyboard_return_rounded));
    await tester.pump();

    expect(_textOf(tester, field), 'QwERt\n');
  });

  testWidgets('hide and reopen retargets an interrupted dock transition', (
    tester,
  ) async {
    await _startPlayground(tester);
    final field = find.byKey(const ValueKey('typing-and-return-field'));
    final controller = OnscreenKeyboard.of(tester.element(field));
    expect(controller.isVisible, isTrue);

    await tester.tap(find.byTooltip('Hide keyboard').last);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(field);
    await tester.pump(const Duration(milliseconds: 40));

    expect(controller.isVisible, isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(RawOnscreenKeyboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final Finder _keyPreview = find.byWidgetPredicate(
  (widget) => widget is Material && widget.elevation == 5,
);

final Finder _alternatePopover = find.byWidgetPredicate(
  (widget) => widget is Material && widget.elevation == 6,
);

Future<void> _startPlayground(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  final field = find.byKey(const ValueKey('typing-and-return-field'));
  await tester.tap(field);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.byType(RawOnscreenKeyboard), findsOneWidget);
}

Finder _key(String label) => find.descendant(
  of: find.byType(RawOnscreenKeyboard),
  matching: find.text(label),
);

Offset _keyCenter(WidgetTester tester, String label) =>
    tester.getCenter(_key(label));

Future<void> _swipeWord(WidgetTester tester, List<String> trace) async {
  final gesture = await tester.startGesture(
    _keyCenter(tester, trace.first),
    // Kept explicit: the word is one uninterrupted touch pointer sequence.
    // ignore: avoid_redundant_argument_values
    kind: PointerDeviceKind.touch,
  );
  await tester.pump(const Duration(milliseconds: 16));
  for (final letter in trace.skip(1)) {
    await gesture.moveTo(_keyCenter(tester, letter));
    await tester.pump(const Duration(milliseconds: 24));
  }

  // A swipe must not commit a partial word while the finger is still down.
  final field = find.byKey(const ValueKey('typing-and-return-field'));
  expect(_textOf(tester, field), anyOf(isEmpty, endsWith(' ')));
  await gesture.up();
  await tester.pump();
}

Future<void> _waitForText(
  WidgetTester tester,
  Finder field,
  String expected,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (_textOf(tester, field) == expected) return;
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(_textOf(tester, field), expected);
}

Future<void> _acceptSwipeCandidateIfNeeded(
  WidgetTester tester,
  Finder field,
  String word,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (_textOf(tester, field).endsWith('$word ')) return;
    final candidate = find.text(word);
    if (candidate.evaluate().isNotEmpty) {
      await tester.tap(candidate.first);
      await tester.pump();
      return;
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail('Swipe produced neither an inserted word nor a $word candidate.');
}

String _textOf(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .controller
    .text;

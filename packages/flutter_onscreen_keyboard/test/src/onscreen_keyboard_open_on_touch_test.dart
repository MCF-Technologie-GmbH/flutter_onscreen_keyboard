import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two field widgets share the open rule; every case runs for both.
final _fields = <String, Widget Function(TextEditingController, FocusNode)>{
  'OnscreenKeyboardTextField': (controller, focusNode) =>
      OnscreenKeyboardTextField(controller: controller, focusNode: focusNode),
  'OnscreenKeyboardTextFormField': (controller, focusNode) =>
      OnscreenKeyboardTextFormField(
        controller: controller,
        focusNode: focusNode,
      ),
};

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;
  late FocusNode otherFocusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
    otherFocusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
    otherFocusNode.dispose();
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Widget field, {
    required bool openOnTouchOnly,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        builder: OnscreenKeyboard.builder(
          width: (_) => 200,
          openOnTouchOnly: openOnTouchOnly,
        ),
        home: Scaffold(
          body: Column(
            children: [
              TextButton(
                focusNode: otherFocusNode,
                onPressed: () {},
                child: const Text('before'),
              ),
              field,
            ],
          ),
        ),
      ),
    );
  }

  OnscreenKeyboardController keyboardOf(WidgetTester tester) =>
      OnscreenKeyboard.of(tester.element(find.byType(Scaffold)));

  for (final entry in _fields.entries) {
    group('${entry.key} with openOnTouchOnly', () {
      Widget field() => entry.value(controller, focusNode);

      testWidgets('a mouse click focuses the field but keeps the keyboard '
          'closed', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);

        await tester.tap(
          find.byType(TextField),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(focusNode.hasPrimaryFocus, isTrue);
        expect(keyboardOf(tester).isVisible, isFalse);
        expect(find.byType(RawOnscreenKeyboard), findsNothing);
      });

      testWidgets('a finger tap opens the keyboard', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isTrue);
        expect(find.byType(RawOnscreenKeyboard), findsOneWidget);
      });

      testWidgets('a stylus tap opens the keyboard', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);

        await tester.tap(
          find.byType(TextField),
          kind: PointerDeviceKind.stylus,
        );
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isTrue);
      });

      testWidgets('reaching the field with Tab keeps the keyboard closed, '
          'even after an earlier finger tap', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);
        await tester.tap(find.text('before'));
        await tester.pumpAndSettle();
        otherFocusNode.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(focusNode.hasPrimaryFocus, isTrue);
        expect(keyboardOf(tester).isVisible, isFalse);
      });

      testWidgets('a mouse click on the focused field does not reopen a '
          'closed keyboard; a finger tap does', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        keyboardOf(tester).hide();
        await tester.pumpAndSettle();

        await tester.tap(
          find.byType(TextField),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(keyboardOf(tester).isVisible, isFalse);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(keyboardOf(tester).isVisible, isTrue);
      });

      testWidgets('a real key closes the open keyboard and its character '
          'reaches the field', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(keyboardOf(tester).isVisible, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        // The platform delivers the typed text through the field's own text
        // input connection, which the closed keyboard must leave open.
        tester.testTextInput.enterText('a');
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isFalse);
        expect(focusNode.hasPrimaryFocus, isTrue);
        expect(controller.text, 'a');
      });

      testWidgets('Backspace closes the open keyboard', (tester) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isFalse);
      });

      testWidgets('a modifier key alone keeps the keyboard open', (
        tester,
      ) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isTrue);
      });

      testWidgets('controller.open() still opens after a mouse click', (
        tester,
      ) async {
        await pumpApp(tester, field(), openOnTouchOnly: true);
        await tester.tap(
          find.byType(TextField),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        keyboardOf(tester).open();
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isTrue);
      });
    });

    group('${entry.key} without openOnTouchOnly', () {
      Widget field() => entry.value(controller, focusNode);

      testWidgets('a mouse click opens the keyboard as before', (
        tester,
      ) async {
        await pumpApp(tester, field(), openOnTouchOnly: false);

        await tester.tap(
          find.byType(TextField),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isTrue);
      });

      testWidgets('a real key leaves the open keyboard open as before', (
        tester,
      ) async {
        await pumpApp(tester, field(), openOnTouchOnly: false);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pumpAndSettle();

        expect(keyboardOf(tester).isVisible, isTrue);
      });
    });
  }

  group('allowsAutomaticOpen', () {
    testWidgets('follows the last input with openOnTouchOnly', (tester) async {
      await pumpApp(
        tester,
        OnscreenKeyboardTextField(controller: controller, focusNode: focusNode),
        openOnTouchOnly: true,
      );
      final keyboard = keyboardOf(tester);
      expect(keyboard.allowsAutomaticOpen(), isFalse);
      expect(keyboard.allowsAutomaticOpen(PointerDeviceKind.touch), isTrue);
      expect(keyboard.allowsAutomaticOpen(PointerDeviceKind.mouse), isFalse);

      await tester.tap(find.text('before'));
      await tester.pumpAndSettle();
      expect(keyboard.allowsAutomaticOpen(), isTrue);

      await tester.tap(find.text('before'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(keyboard.allowsAutomaticOpen(), isFalse);

      await tester.tap(find.text('before'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pumpAndSettle();
      expect(keyboard.allowsAutomaticOpen(), isFalse);
    });

    testWidgets('is always true without openOnTouchOnly', (tester) async {
      await pumpApp(
        tester,
        OnscreenKeyboardTextField(controller: controller, focusNode: focusNode),
        openOnTouchOnly: false,
      );
      final keyboard = keyboardOf(tester);
      expect(keyboard.allowsAutomaticOpen(), isTrue);
      expect(keyboard.allowsAutomaticOpen(PointerDeviceKind.mouse), isTrue);
    });
  });
}

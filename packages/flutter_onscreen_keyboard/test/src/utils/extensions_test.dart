import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/theme/onscreen_keyboard_theme.dart';
import 'package:flutter_onscreen_keyboard/src/utils/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extensions', () {
    test('TextEditingControllerExt', () async {
      final controller = TextEditingController(text: 'abc');
      expect(controller.start, controller.selection.start);
      expect(controller.end, controller.selection.end);
    });

    group('ColorExt', () {
      test('default opacity', () async {
        const color = Colors.blue;
        expect(color.fade(), Colors.blue.withValues(alpha: 0.5));
      });

      test('specific opacity', () async {
        const color = Colors.blue;
        expect(color.fade(0.7), Colors.blue.withValues(alpha: 0.7));
      });
    });

    group('ContextExt', () {
      testWidgets('theme & controller', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: OnscreenKeyboard.builder(width: (_) => 200),
            home: const Scaffold(),
          ),
        );

        final theme = OnscreenKeyboardTheme.of(
          tester.element(find.byType(Scaffold)),
        );
        expect(theme, tester.element(find.byType(Scaffold)).theme);

        final controller = OnscreenKeyboard.of(
          tester.element(find.byType(Scaffold)),
        );
        expect(controller, tester.element(find.byType(Scaffold)).controller);
      });
    });
  });
}

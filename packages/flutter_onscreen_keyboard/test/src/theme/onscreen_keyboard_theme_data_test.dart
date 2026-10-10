import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/constants/action_key_type.dart';
import 'package:flutter_onscreen_keyboard/src/widgets/keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnscreenKeyboardThemeData', () {
    test('copyWith', () async {
      const themeData = OnscreenKeyboardThemeData();
      expect(themeData.color, isNull);
      expect(themeData.copyWith(color: Colors.red).color, Colors.red);
    });

    group('TextKeyThemeData', () {
      test('copyWith', () async {
        const themeData = TextKeyThemeData();
        expect(themeData.backgroundColor, isNull);
        expect(
          themeData.copyWith(backgroundColor: Colors.red).backgroundColor,
          Colors.red,
        );
      });
    });

    group('ActionKeyThemeData', () {
      test('copyWith', () async {
        const themeData = ActionKeyThemeData();
        expect(themeData.backgroundColor, isNull);
        expect(
          themeData.copyWith(backgroundColor: Colors.red).backgroundColor,
          Colors.red,
        );
      });
    });
  });

  group('enterKeyThemeData', () {
    test('copyWith keeps and replaces it', () {
      const enter = ActionKeyThemeData(backgroundColor: Colors.green);
      const themeData = OnscreenKeyboardThemeData(enterKeyThemeData: enter);
      expect(themeData.copyWith(color: Colors.red).enterKeyThemeData, enter);
      expect(
        themeData
            .copyWith(
              enterKeyThemeData: const ActionKeyThemeData(
                backgroundColor: Colors.blue,
              ),
            )
            .enterKeyThemeData
            ?.backgroundColor,
        Colors.blue,
      );
    });

    Color keyColor(WidgetTester tester, String name) {
      final key = find.byWidgetPredicate(
        (w) => w is ActionKeyWidget && w.actionKey.name == name,
      );
      final box = find.descendant(
        of: key.first,
        matching: find.byType(Container),
      );
      final decoration =
          tester.widget<Container>(box.first).decoration! as BoxDecoration;
      return decoration.color!;
    }

    Future<void> openKeyboard(
      WidgetTester tester,
      OnscreenKeyboardThemeData theme,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: OnscreenKeyboard.builder(theme: theme, width: (_) => 600),
          home: const Scaffold(),
        ),
      );
      OnscreenKeyboard.of(tester.element(find.byType(Scaffold))).open();
      await tester.pumpAndSettle();
    }

    testWidgets('Enter uses its own style; other action keys keep theirs', (
      tester,
    ) async {
      await openKeyboard(
        tester,
        const OnscreenKeyboardThemeData(
          actionKeyThemeData: ActionKeyThemeData(backgroundColor: Colors.grey),
          enterKeyThemeData: ActionKeyThemeData(backgroundColor: Colors.white),
        ),
      );
      expect(keyColor(tester, ActionKeyType.enter), Colors.white);
      expect(keyColor(tester, ActionKeyType.backspace), Colors.grey);
    });

    testWidgets('without it Enter falls back to the action key style', (
      tester,
    ) async {
      await openKeyboard(
        tester,
        const OnscreenKeyboardThemeData(
          actionKeyThemeData: ActionKeyThemeData(backgroundColor: Colors.grey),
        ),
      );
      expect(keyColor(tester, ActionKeyType.enter), Colors.grey);
    });
  });
}

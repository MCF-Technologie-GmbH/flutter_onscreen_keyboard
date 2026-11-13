import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holding the space bar switches the keyboard into cursor mode. Touch PCs
/// and Pis have no vibration motor, so the mode must be visible: the letter
/// labels fade and the space bar shows left/right arrows until release
/// (tapx-main-frontend#3896).
void main() {
  const marker = ValueKey('onscreen-keyboard-space-cursor-mode');
  const dimmed = Color(0xFFB0B0B0);
  const arrows = Color(0xFF0055AA);

  Future<TextEditingController> pump(
    WidgetTester tester,
    OnscreenKeyboardPresentation presentation,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: 'hello world')
      ..selection = const TextSelection.collapsed(offset: 11);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OnscreenKeyboard(
          presentation: presentation,
          feedback: const OnscreenKeyboardFeedback(enableHaptics: false),
          theme: const OnscreenKeyboardThemeData(
            textKeyThemeData: TextKeyThemeData(
              foregroundColor: Color(0xFF111111),
              cursorModeForegroundColor: dimmed,
              cursorModeIndicatorColor: arrows,
            ),
          ),
          child: Scaffold(
            body: OnscreenKeyboardTextField(controller: controller),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pumpAndSettle();
    return controller;
  }

  Color? labelColor(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color;

  for (final presentation in [
    OnscreenKeyboardPresentation.docked,
    OnscreenKeyboardPresentation.overlay,
  ]) {
    testWidgets('${presentation.name}: holding space shows cursor mode', (
      tester,
    ) async {
      final controller = await pump(tester, presentation);
      final space = find.byIcon(Icons.space_bar_rounded);
      expect(space, findsOneWidget);
      expect(find.byKey(marker), findsNothing);
      expect(labelColor(tester, 'q'), isNot(dimmed));

      final center = tester.getCenter(space);
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 300));

      // Cursor mode is on and visible.
      expect(find.byKey(marker), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(marker),
          matching: find.byIcon(Icons.keyboard_arrow_left_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(marker),
          matching: find.byIcon(Icons.keyboard_arrow_right_rounded),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(marker),
                matching: find.byIcon(Icons.keyboard_arrow_left_rounded),
              ),
            )
            .color,
        arrows,
      );
      expect(labelColor(tester, 'q'), dimmed);
      expect(labelColor(tester, 'm'), dimmed);

      // Sliding 28 px moves the cursor two letters to the left.
      await gesture.moveTo(center.translate(-28, 0));
      await tester.pump();
      expect(controller.selection.baseOffset, 9);
      expect(find.byKey(marker), findsOneWidget);

      // Release brings the normal keyboard back.
      await gesture.up();
      await tester.pump();
      expect(find.byKey(marker), findsNothing);
      expect(space, findsOneWidget);
      expect(labelColor(tester, 'q'), isNot(dimmed));
      expect(controller.text, 'hello world');
    });

    testWidgets('${presentation.name}: a short space tap types a space', (
      tester,
    ) async {
      final controller = await pump(tester, presentation);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.space_bar_rounded)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(marker), findsNothing);
      await gesture.up();
      await tester.pump();
      expect(controller.text, 'hello world ');
      expect(find.byKey(marker), findsNothing);
    });
  }
}

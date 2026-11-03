import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets show debugOnRebuildDirtyWidget;
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_onscreen_keyboard/src/widgets/keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// While the docked or overlay keyboard slides in or out, only its position
/// and the covered area change: the keys are built once and only moved.
void main() {
  Widget app(OnscreenKeyboardPresentation presentation) => MaterialApp(
    home: OnscreenKeyboard(
      presentation: presentation,
      overlayDragEnabled: presentation == OnscreenKeyboardPresentation.overlay,
      suggestionBarHeight: 56,
      child: const Scaffold(body: OnscreenKeyboardTextField()),
    ),
  );

  void usePortraitView(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  OnscreenKeyboardController keyboard(WidgetTester tester) =>
      OnscreenKeyboard.of(
        tester.element(find.byType(OnscreenKeyboardTextField)),
      );

  double panelTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(RawOnscreenKeyboard)).dy;

  /// Pumps the slide frame by frame after its first frame and returns how
  /// often a key widget was built again, plus the panel tops seen.
  Future<({int keyRebuilds, List<double> tops})> slide(
    WidgetTester tester,
    VoidCallback start,
  ) async {
    start();
    // The first frame applies the open/close itself; the slide follows.
    await tester.pump();
    var keyRebuilds = 0;
    final previous = widgets.debugOnRebuildDirtyWidget;
    widgets.debugOnRebuildDirtyWidget = (element, builtOnce) {
      final widget = element.widget;
      if (widget is TextKeyWidget || widget is ActionKeyWidget) {
        keyRebuilds++;
      }
    };
    final tops = <double>[];
    try {
      for (var frame = 0; frame < 13; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        tops.add(panelTop(tester));
      }
    } finally {
      widgets.debugOnRebuildDirtyWidget = previous;
    }
    await tester.pumpAndSettle();
    return (keyRebuilds: keyRebuilds, tops: tops);
  }

  for (final presentation in [
    OnscreenKeyboardPresentation.overlay,
    OnscreenKeyboardPresentation.docked,
  ]) {
    testWidgets('${presentation.name} keyboard keys are not rebuilt while '
        'it slides in and out', (tester) async {
      usePortraitView(tester);
      await tester.pumpWidget(app(presentation));
      await tester.tap(find.byType(OnscreenKeyboardTextField));
      await tester.pumpAndSettle();
      expect(find.byType(TextKeyWidget), findsWidgets);

      final closing = await slide(tester, keyboard(tester).hide);
      final opening = await slide(tester, keyboard(tester).open);

      // The slide really ran: the panel moved over several frames.
      expect(closing.tops.toSet().length, greaterThan(3));
      expect(opening.tops.toSet().length, greaterThan(3));
      expect(opening.tops.last, lessThan(opening.tops.first));
      expect(closing.keyRebuilds, 0, reason: 'keys rebuilt while closing');
      expect(opening.keyRebuilds, 0, reason: 'keys rebuilt while opening');
    });
  }
}

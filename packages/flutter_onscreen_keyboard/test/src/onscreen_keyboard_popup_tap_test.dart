import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// A key tap counts as a tap inside the pop-up that holds the focused field
/// (tapx-main-frontend#3869): a `MenuAnchor` menu with a search field closed
/// at the first key, so the letter and the search were lost.
void main() {
  late TextEditingController search;
  late TextEditingController other;
  late MenuController menu;

  setUp(() {
    search = TextEditingController();
    other = TextEditingController();
    menu = MenuController();
  });

  tearDown(() {
    search.dispose();
    other.dispose();
  });

  Widget app(OnscreenKeyboardPresentation presentation) => MaterialApp(
    builder: OnscreenKeyboard.builder(
      presentation: presentation,
      suggestionBarHeight: presentation == OnscreenKeyboardPresentation.overlay
          ? 56
          : 44,
    ),
    home: Scaffold(
      body: Column(
        children: [
          SizedBox(
            width: 300,
            child: OnscreenKeyboardTextField(
              key: const ValueKey('other'),
              controller: other,
            ),
          ),
          MenuAnchor(
            controller: menu,
            menuChildren: [
              SizedBox(
                width: 240,
                child: OnscreenKeyboardTextField(
                  key: const ValueKey('search'),
                  controller: search,
                ),
              ),
            ],
            builder: (context, controller, _) => TextButton(
              onPressed: controller.open,
              child: const Text('more'),
            ),
          ),
        ],
      ),
    ),
  );

  void usePortraitView(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final presentation in [
    OnscreenKeyboardPresentation.overlay,
    OnscreenKeyboardPresentation.docked,
  ]) {
    group(presentation.name, () {
      testWidgets('a key types into a menu search and the menu stays open', (
        tester,
      ) async {
        usePortraitView(tester);
        await tester.pumpWidget(app(presentation));

        await tester.tap(find.text('more'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('search')));
        await tester.pumpAndSettle();
        expect(find.text('o'), findsOneWidget, reason: 'the keyboard is open');

        await tester.tap(find.text('o'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('k'));
        await tester.pumpAndSettle();

        expect(menu.isOpen, isTrue, reason: 'the menu stays open');
        expect(search.text, 'ok', reason: 'both letters are typed');
        expect(find.text('o'), findsOneWidget, reason: 'keyboard stays open');
      });

      testWidgets('a key still closes a menu that does not hold the focused '
          'field', (tester) async {
        usePortraitView(tester);
        await tester.pumpWidget(app(presentation));

        await tester.tap(find.byKey(const ValueKey('other')));
        await tester.pumpAndSettle();
        menu.open();
        await tester.pumpAndSettle();
        expect(menu.isOpen, isTrue);

        await tester.tap(find.text('o'));
        await tester.pumpAndSettle();

        expect(menu.isOpen, isFalse);
        expect(other.text, 'o');
      });
    });
  }
}

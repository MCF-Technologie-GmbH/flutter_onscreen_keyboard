import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [360.0, 420.0, 800.0]) {
    for (final language in ['en', 'de']) {
      testWidgets('phone symbols remain reachable at $width in $language', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 700);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: OnscreenKeyboard(
              locale: Locale(language),
              presentation: OnscreenKeyboardPresentation.overlay,
              child: Scaffold(
                body: OnscreenKeyboardTextField(controller: controller),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(OnscreenKeyboardTextField));
        await tester.pumpAndSettle();
        final letterBackspace = tester.getCenter(
          find.byIcon(Icons.backspace_outlined),
        );
        expect(
          letterBackspace.dy,
          closeTo(
            tester.getCenter(find.byIcon(Icons.arrow_upward_rounded)).dy,
            1,
          ),
        );
        await tester.tap(find.text('?123'));
        await tester.pump();
        final symbolBackspace = tester.getCenter(
          find.byIcon(Icons.backspace_outlined),
        );
        expect((symbolBackspace - letterBackspace).distance, lessThan(0.001));
        for (final char in [
          '1',
          '@',
          if (language == 'de') '€' else r'$',
          '?',
        ]) {
          final key = find.descendant(
            of: find.byType(RawOnscreenKeyboard),
            matching: find.text(char),
          );
          expect(key.hitTestable(), findsOneWidget);
          await tester.tap(key);
          await tester.pump();
        }
        await tester.tap(find.text(r'=\<'));
        await tester.pump();
        expect(
          tester.getCenter(find.byIcon(Icons.backspace_outlined)),
          within(distance: 0.001, from: letterBackspace),
        );
        const extra = [
          '_',
          '=',
          r'\',
          '|',
          '~',
          '^',
          '<',
          '>',
          '[',
          ']',
          '{',
          '}',
          '°',
          '•',
          '§',
          '£',
          '¥',
        ];
        for (final char in extra) {
          final key = find.descendant(
            of: find.byType(RawOnscreenKeyboard),
            matching: find.text(char),
          );
          expect(key.hitTestable(), findsOneWidget);
          await tester.tap(key);
          await tester.pump();
        }
        expect(
          controller.text,
          '1@${language == 'de' ? '€' : r'$'}?${extra.join()}',
        );
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pump();
        expect(controller.text.endsWith('£'), isTrue);
        await tester.tap(find.text('?123'));
        await tester.pump();
        expect(find.text('1').hitTestable(), findsOneWidget);
        await tester.tap(find.text('ABC'));
        await tester.pump();
        expect(find.text('q').hitTestable(), findsOneWidget);
        await tester.tap(find.text('?123'));
        await tester.pump();
        await tester.tap(find.text(r'=\<'));
        await tester.pump();
        await tester.tap(find.text('ABC'));
        await tester.pump();
        expect(find.text('q').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('phone punctuation and currency support long press selection', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OnscreenKeyboard(
          presentation: OnscreenKeyboardPresentation.overlay,
          child: Scaffold(
            body: OnscreenKeyboardTextField(controller: controller),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pumpAndSettle();
    Future<void> selectAlternate(String base, String alternate) async {
      final key = find.descendant(
        of: find.byType(RawOnscreenKeyboard),
        matching: find.text(base),
      );
      final gesture = await tester.startGesture(tester.getCenter(key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 451));
      expect(find.text(alternate).hitTestable(), findsOneWidget);
      await gesture.moveTo(tester.getCenter(find.text(alternate)));
      await gesture.up();
      await tester.pump();
    }

    await selectAlternate('.', '…');
    await tester.tap(find.text('?123'));
    await tester.pump();
    await selectAlternate(r'$', '€');
    await selectAlternate('-', '—');
    expect(controller.text, '…€—');
    expect(tester.takeException(), isNull);
  });
}

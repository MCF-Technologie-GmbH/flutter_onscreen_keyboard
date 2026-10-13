import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Rect?> published;

  Widget app(OnscreenKeyboardPresentation presentation) => MaterialApp(
    home: OnscreenKeyboard(
      presentation: presentation,
      width: presentation == OnscreenKeyboardPresentation.floating
          ? (_) => 400
          : null,
      overlayDragEnabled: presentation == OnscreenKeyboardPresentation.overlay,
      suggestionBarHeight: presentation == OnscreenKeyboardPresentation.overlay
          ? 56
          : 44,
      child: Builder(
        builder: (context) {
          published.add(OnscreenKeyboardObscuredArea.maybeOf(context));
          return const Scaffold(body: OnscreenKeyboardTextField());
        },
      ),
    ),
  );

  void useLandscapeView(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  OnscreenKeyboardController keyboard(WidgetTester tester) =>
      OnscreenKeyboard.of(
        tester.element(find.byType(OnscreenKeyboardTextField)),
      );

  Rect panel(WidgetTester tester) => tester
      .getRect(
        find.ancestor(
          of: find.byType(RawOnscreenKeyboard),
          matching: find.byType(ClipRect),
        ),
      )
      .intersect(Offset.zero & const Size(1920, 1080));

  setUp(() => published = []);

  testWidgets('overlay publishes nothing covered while hidden', (
    tester,
  ) async {
    useLandscapeView(tester);
    await tester.pumpWidget(app(OnscreenKeyboardPresentation.overlay));

    expect(published.last, Rect.zero);
    expect(published.last!.isEmpty, isTrue);
  });

  testWidgets('overlay publishes the panel it draws at the bottom', (
    tester,
  ) async {
    useLandscapeView(tester);
    await tester.pumpWidget(app(OnscreenKeyboardPresentation.overlay));

    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pumpAndSettle();

    final covered = published.last!;
    expect(covered.bottom, 1080);
    expect(covered.left, 0);
    expect(covered.right, 1920);
    expect(covered.top, closeTo(panel(tester).top, .5));
    expect(covered.top, greaterThan(540));
    expect(covered.top, lessThan(1080));

    keyboard(tester).close();
    await tester.pumpAndSettle();
    expect(published.last, Rect.zero);
  });

  testWidgets('overlay follows the slide animation', (tester) async {
    useLandscapeView(tester);
    await tester.pumpWidget(app(OnscreenKeyboardPresentation.overlay));
    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pumpAndSettle();
    final open = published.last!;
    keyboard(tester).close();
    await tester.pumpAndSettle();

    keyboard(tester).open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final sliding = published.last!;
    expect(sliding.top, greaterThan(open.top));
    expect(sliding.top, lessThan(1080));
    expect(sliding.bottom, 1080);
    expect(sliding.top, closeTo(panel(tester).top, .5));
  });

  testWidgets('overlay publishes the panel after it is moved to the top', (
    tester,
  ) async {
    useLandscapeView(tester);
    await tester.pumpWidget(app(OnscreenKeyboardPresentation.overlay));
    await tester.tap(find.byType(OnscreenKeyboardTextField));
    await tester.pumpAndSettle();
    final atBottom = published.last!;

    keyboard(tester).moveToTop();
    await tester.pump();

    final atTop = published.last!;
    expect(atTop.top, 0);
    expect(atTop.height, closeTo(atBottom.height, .5));
    expect(atTop.bottom, closeTo(panel(tester).bottom, .5));

    await tester.drag(
      find.byKey(const ValueKey('onscreen_keyboard_overlay_drag_handle')),
      const Offset(0, 200),
    );
    await tester.pump();
    final dragged = published.last!;
    expect(dragged.top, greaterThan(150));
    expect(dragged.top, closeTo(panel(tester).top, .5));
  });

  for (final presentation in [
    OnscreenKeyboardPresentation.docked,
    OnscreenKeyboardPresentation.floating,
  ]) {
    testWidgets('${presentation.name} publishes nothing covered', (
      tester,
    ) async {
      await tester.pumpWidget(app(presentation));
      await tester.tap(find.byType(OnscreenKeyboardTextField));
      await tester.pumpAndSettle();

      expect(keyboard(tester).isVisible, isTrue);
      expect(published.last, Rect.zero);
    });
  }

  testWidgets('without a keyboard maybeOf is null and of is empty', (
    tester,
  ) async {
    Rect? maybe = Rect.largest;
    Rect? of;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          maybe = OnscreenKeyboardObscuredArea.maybeOf(context);
          of = OnscreenKeyboardObscuredArea.of(context);
          return const SizedBox();
        },
      ),
    );

    expect(maybe, isNull);
    expect(of, Rect.zero);
  });
}

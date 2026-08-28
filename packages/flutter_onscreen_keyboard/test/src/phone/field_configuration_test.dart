import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies signed decimal fields', () {
    final field = OnscreenKeyboardFieldConfiguration.fromFlutter(
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
    );

    expect(field.inputKind, OnscreenKeyboardInputKind.signedDecimal);
    expect(
      PhoneKeyboardLayout(fieldConfiguration: field).modes.keys,
      ['numbers'],
    );
  });

  test('suppresses language behavior for sensitive and restricted fields', () {
    final password = OnscreenKeyboardFieldConfiguration.fromFlutter(
      obscureText: true,
    );
    final restricted = OnscreenKeyboardFieldConfiguration.fromFlutter(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );

    expect(password.allowsSuggestions, isFalse);
    expect(password.allowsLearning, isFalse);
    expect(restricted.allowsAutocorrect, isFalse);
  });

  test('uses QWERTZ for German and QWERTY for English', () {
    final english =
        const PhoneKeyboardLayout().modes['letters']!.rows.first.keys;
    final german = const PhoneKeyboardLayout(
      locale: Locale('de'),
    ).modes['letters']!.rows.first.keys;

    expect((english[5] as TextKey).primary, 'y');
    expect((german[5] as TextKey).primary, 'z');
  });
}

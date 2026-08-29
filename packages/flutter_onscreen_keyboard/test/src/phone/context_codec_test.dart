import 'dart:typed_data';

import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('context model round trips deterministically', () {
    final entries = [
      OnscreenKeyboardContextEntry(
        words: const ['hello', 'world'],
        weight: 2.4,
      ),
      OnscreenKeyboardContextEntry(
        words: const ['how', 'are', 'you'],
        weight: 3.7,
      ),
    ];

    final first = OnscreenKeyboardContextCodec.encode(entries);
    final second = OnscreenKeyboardContextCodec.encode(entries.reversed);
    final decoded = OnscreenKeyboardContextCodec.decode(first);

    expect(first, orderedEquals(second));
    expect(decoded.map((entry) => entry.words), [
      ['hello', 'world'],
      ['how', 'are', 'you'],
    ]);
    expect(decoded.map((entry) => entry.weight), [2.4, 3.7]);
  });

  test('context model rejects corrupt and trailing bytes', () {
    expect(
      () => OnscreenKeyboardContextCodec.decode(Uint8List.fromList([1, 2])),
      throwsFormatException,
    );
    final valid = OnscreenKeyboardContextCodec.encode(
      [
        OnscreenKeyboardContextEntry(
          words: const ['hello', 'world'],
          weight: 1,
        ),
      ],
    );
    expect(
      () => OnscreenKeyboardContextCodec.decode(
        Uint8List.fromList([...valid, 0]),
      ),
      throwsFormatException,
    );
  });
}

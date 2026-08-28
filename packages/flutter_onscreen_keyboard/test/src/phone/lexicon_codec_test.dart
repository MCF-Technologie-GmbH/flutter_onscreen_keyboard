import 'dart:typed_data';

import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('binary lexicon round trips multilingual entries deterministically', () {
    const entries = [
      OnscreenKeyboardLexiconEntry('zebra', 1.25),
      OnscreenKeyboardLexiconEntry('äpfel', 8.125),
      OnscreenKeyboardLexiconEntry('apple', 9.5),
    ];

    final first = OnscreenKeyboardLexiconCodec.encode(entries);
    final second = OnscreenKeyboardLexiconCodec.encode(entries.reversed);
    final decoded = OnscreenKeyboardLexiconCodec.decode(first);

    expect(first, orderedEquals(second));
    expect(decoded.map((entry) => entry.word), ['apple', 'zebra', 'äpfel']);
    expect(decoded.map((entry) => entry.weight), [9.5, 1.25, 8.125]);
  });

  test('binary lexicon rejects invalid and trailing data', () {
    expect(
      () => OnscreenKeyboardLexiconCodec.decode(Uint8List.fromList([1, 2])),
      throwsFormatException,
    );
    final valid = OnscreenKeyboardLexiconCodec.encode(
      const [OnscreenKeyboardLexiconEntry('hello', 1)],
    );
    expect(
      () => OnscreenKeyboardLexiconCodec.decode(
        Uint8List.fromList([...valid, 0]),
      ),
      throwsFormatException,
    );
  });
}

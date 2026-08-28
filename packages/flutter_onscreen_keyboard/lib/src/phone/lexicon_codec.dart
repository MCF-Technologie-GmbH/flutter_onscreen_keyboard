import 'dart:typed_data';

import 'package:flutter_onscreen_keyboard/src/phone/language_model.dart';
import 'package:flutter_onscreen_keyboard/src/phone/lexicon_format.dart';

/// Dependency-free, deterministic front-coded lexicon format.
///
/// Entries are sorted lexicographically and store only the UTF-8 suffix that
/// differs from the previous word. Weights use fixed-point thousandths so the
/// decoder avoids text parsing and creates substantially less temporary data.
abstract final class OnscreenKeyboardLexiconCodec {
  /// Encodes entries into the deterministic OSKL binary representation.
  static Uint8List encode(Iterable<OnscreenKeyboardLexiconEntry> entries) =>
      OnscreenKeyboardLexiconFormat.encode(
        entries.map((entry) => (word: entry.word, weight: entry.weight)),
      );

  /// Decodes and validates an OSKL binary lexicon.
  static List<OnscreenKeyboardLexiconEntry> decode(Uint8List bytes) =>
      OnscreenKeyboardLexiconFormat.decode(bytes)
          .map(
            (entry) => OnscreenKeyboardLexiconEntry(entry.word, entry.weight),
          )
          .toList(growable: false);
}

import 'dart:typed_data';

import 'package:flutter_onscreen_keyboard/src/phone/context_format.dart';
import 'package:flutter_onscreen_keyboard/src/phone/language_model.dart';

/// Encodes and decodes dependency-free static keyboard context models.
abstract final class OnscreenKeyboardContextCodec {
  /// Encodes entries into deterministic OSKC bytes.
  static Uint8List encode(Iterable<OnscreenKeyboardContextEntry> entries) =>
      OnscreenKeyboardContextFormat.encode(
        entries.map((entry) => (words: entry.words, weight: entry.weight)),
      );

  /// Decodes and validates deterministic OSKC bytes.
  static List<OnscreenKeyboardContextEntry> decode(Uint8List bytes) =>
      OnscreenKeyboardContextFormat.decode(bytes)
          .map(
            (record) => OnscreenKeyboardContextEntry(
              words: List.unmodifiable(record.words),
              weight: record.weight,
            ),
          )
          .toList(growable: false);
}

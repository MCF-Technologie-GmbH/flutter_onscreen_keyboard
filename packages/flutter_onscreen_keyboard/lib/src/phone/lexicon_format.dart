import 'dart:convert';
import 'dart:typed_data';

/// Flutter-free source record used by deterministic dictionary tooling.
typedef OnscreenKeyboardLexiconRecord = ({String word, double weight});

/// Flutter-free implementation of the deterministic OSKL binary format.
abstract final class OnscreenKeyboardLexiconFormat {
  static const _magic = <int>[0x4f, 0x53, 0x4b, 0x4c, 1]; // OSKL + version.

  /// Encodes [entries] into deterministic OSKL bytes.
  static Uint8List encode(Iterable<OnscreenKeyboardLexiconRecord> entries) {
    final sorted = entries.toList(growable: false)
      ..sort((a, b) => a.word.compareTo(b.word));
    final output = BytesBuilder(copy: false)..add(_magic);
    _writeVarint(output, sorted.length);
    var previous = const <int>[];
    for (final entry in sorted) {
      final word = utf8.encode(entry.word);
      var shared = 0;
      while (shared < previous.length &&
          shared < word.length &&
          previous[shared] == word[shared]) {
        shared++;
      }
      final suffix = word.sublist(shared);
      _writeVarint(output, shared);
      _writeVarint(output, suffix.length);
      output.add(suffix);
      final weight = (entry.weight * 1000).round().clamp(0, 0xffff);
      output.add([weight & 0xff, weight >> 8]);
      previous = word;
    }
    return output.takeBytes();
  }

  /// Decodes and validates deterministic OSKL bytes.
  static List<OnscreenKeyboardLexiconRecord> decode(Uint8List bytes) {
    if (bytes.length < _magic.length ||
        !_magic.indexed.every((entry) => bytes[entry.$1] == entry.$2)) {
      throw const FormatException('Unsupported keyboard lexicon format');
    }
    var offset = _magic.length;
    final countResult = _readVarint(bytes, offset);
    final count = countResult.$1;
    offset = countResult.$2;
    final result = <OnscreenKeyboardLexiconRecord>[];
    var previous = Uint8List(0);
    for (var index = 0; index < count; index++) {
      final sharedResult = _readVarint(bytes, offset);
      final shared = sharedResult.$1;
      offset = sharedResult.$2;
      final suffixResult = _readVarint(bytes, offset);
      final suffixLength = suffixResult.$1;
      offset = suffixResult.$2;
      if (shared > previous.length ||
          offset + suffixLength + 2 > bytes.length) {
        throw const FormatException('Truncated keyboard lexicon');
      }
      final wordBytes = Uint8List(shared + suffixLength)
        ..setRange(0, shared, previous)
        ..setRange(shared, shared + suffixLength, bytes, offset);
      offset += suffixLength;
      final weight = (bytes[offset] | (bytes[offset + 1] << 8)) / 1000;
      offset += 2;
      result.add((word: utf8.decode(wordBytes), weight: weight));
      previous = wordBytes;
    }
    if (offset != bytes.length) {
      throw const FormatException('Unexpected keyboard lexicon data');
    }
    return result;
  }

  static void _writeVarint(BytesBuilder output, int value) {
    var remaining = value;
    do {
      var byte = remaining & 0x7f;
      remaining >>= 7;
      if (remaining != 0) byte |= 0x80;
      output.addByte(byte);
    } while (remaining != 0);
  }

  static (int, int) _readVarint(Uint8List bytes, int start) {
    var value = 0;
    var shift = 0;
    var offset = start;
    while (offset < bytes.length && shift <= 28) {
      final byte = bytes[offset++];
      value |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return (value, offset);
      shift += 7;
    }
    throw const FormatException('Invalid keyboard lexicon integer');
  }
}

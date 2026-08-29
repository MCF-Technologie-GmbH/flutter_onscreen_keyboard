import 'dart:convert';
import 'dart:typed_data';

/// Flutter-free record used by deterministic context-model tooling.
typedef OnscreenKeyboardContextRecord = ({List<String> words, double weight});

/// Deterministic, compact OSKC binary format for bigrams and trigrams.
abstract final class OnscreenKeyboardContextFormat {
  static const _magic = <int>[0x4f, 0x53, 0x4b, 0x43, 1]; // OSKC + version.

  /// Encodes records into deterministic OSKC bytes.
  static Uint8List encode(Iterable<OnscreenKeyboardContextRecord> records) {
    final sorted = records.toList(
      growable: false,
    )..sort((a, b) => a.words.join('\u0000').compareTo(b.words.join('\u0000')));
    final output = BytesBuilder(copy: false)..add(_magic);
    _writeVarint(output, sorted.length);
    var previous = const <int>[];
    for (final record in sorted) {
      if (record.words.length != 2 && record.words.length != 3) {
        throw const FormatException(
          'Context records must contain 2 or 3 words',
        );
      }
      final value = utf8.encode(record.words.join('\u0000'));
      var shared = 0;
      while (shared < previous.length &&
          shared < value.length &&
          previous[shared] == value[shared]) {
        shared++;
      }
      final suffix = value.sublist(shared);
      output.addByte(record.words.length);
      _writeVarint(output, shared);
      _writeVarint(output, suffix.length);
      output.add(suffix);
      final weight = (record.weight * 1000).round().clamp(0, 0xffff);
      output.add([weight & 0xff, weight >> 8]);
      previous = value;
    }
    return output.takeBytes();
  }

  /// Decodes and validates deterministic OSKC bytes.
  static List<OnscreenKeyboardContextRecord> decode(Uint8List bytes) {
    if (bytes.length < _magic.length ||
        !_magic.indexed.every((entry) => bytes[entry.$1] == entry.$2)) {
      throw const FormatException('Unsupported keyboard context format');
    }
    var offset = _magic.length;
    final countResult = _readVarint(bytes, offset);
    final count = countResult.$1;
    offset = countResult.$2;
    final result = <OnscreenKeyboardContextRecord>[];
    var previous = Uint8List(0);
    for (var index = 0; index < count; index++) {
      if (offset >= bytes.length) {
        throw const FormatException('Truncated keyboard context model');
      }
      final wordCount = bytes[offset++];
      if (wordCount != 2 && wordCount != 3) {
        throw const FormatException('Invalid keyboard context word count');
      }
      final sharedResult = _readVarint(bytes, offset);
      final shared = sharedResult.$1;
      offset = sharedResult.$2;
      final suffixResult = _readVarint(bytes, offset);
      final suffixLength = suffixResult.$1;
      offset = suffixResult.$2;
      if (shared > previous.length ||
          offset + suffixLength + 2 > bytes.length) {
        throw const FormatException('Truncated keyboard context model');
      }
      final value = Uint8List(shared + suffixLength)
        ..setRange(0, shared, previous)
        ..setRange(shared, shared + suffixLength, bytes, offset);
      offset += suffixLength;
      final weight = (bytes[offset] | (bytes[offset + 1] << 8)) / 1000;
      offset += 2;
      final words = utf8.decode(value).split('\u0000');
      if (words.length != wordCount || words.any((word) => word.isEmpty)) {
        throw const FormatException('Invalid keyboard context record');
      }
      result.add((words: words, weight: weight));
      previous = value;
    }
    if (offset != bytes.length) {
      throw const FormatException('Unexpected keyboard context data');
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
    throw const FormatException('Invalid keyboard context integer');
  }
}

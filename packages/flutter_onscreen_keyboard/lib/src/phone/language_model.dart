// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A ranked language-model result.
@immutable
class OnscreenKeyboardSuggestion {
  const OnscreenKeyboardSuggestion({
    required this.word,
    required this.score,
    this.confidence = 0,
  });

  final String word;
  final double score;
  final double confidence;
}

/// Cancellation object passed to asynchronous model work.
class OnscreenKeyboardCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const OnscreenKeyboardRequestCancelled();
  }
}

class OnscreenKeyboardRequestCancelled implements Exception {
  const OnscreenKeyboardRequestCancelled();
}

@immutable
class OnscreenKeyboardSuggestionRequest {
  const OnscreenKeyboardSuggestionRequest({
    required this.locale,
    required this.prefix,
    required this.cancellationToken,
    this.previousWord,
    this.limit = 3,
  });

  final Locale locale;
  final String prefix;
  final String? previousWord;
  final int limit;
  final OnscreenKeyboardCancellationToken cancellationToken;
}

@immutable
class OnscreenKeyboardSwipeRequest {
  const OnscreenKeyboardSwipeRequest({
    required this.locale,
    required this.trace,
    required this.cancellationToken,
    this.previousWord,
    this.limit = 3,
    this.points = const [],
    this.keyCenters = const {},
  });

  final Locale locale;
  final List<String> trace;
  final String? previousWord;
  final int limit;
  final OnscreenKeyboardCancellationToken cancellationToken;

  /// Normalized touch positions sampled continuously during the gesture.
  final List<Offset> points;

  /// Normalized center position of each printable key in the active layout.
  final Map<String, Offset> keyCenters;
}

/// Geometry captured for one continuous swipe across the keyboard.
@immutable
class OnscreenKeyboardSwipeData {
  const OnscreenKeyboardSwipeData({
    required this.trace,
    required this.points,
    required this.keyCenters,
  });

  final List<String> trace;
  final List<Offset> points;
  final Map<String, Offset> keyCenters;
}

/// Pluggable, offline language assistance.
abstract interface class OnscreenKeyboardLanguageModel {
  Future<List<OnscreenKeyboardSuggestion>> suggestions(
    OnscreenKeyboardSuggestionRequest request,
  );

  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  );

  Future<void> learnAcceptedWord({
    required Locale locale,
    required String word,
    String? previousWord,
  });
}

@immutable
class OnscreenKeyboardLearningSnapshot {
  const OnscreenKeyboardLearningSnapshot({
    this.words = const {},
    this.bigrams = const {},
  });

  final Map<String, int> words;
  final Map<String, int> bigrams;
}

/// Persistence adapter for device-local learning.
abstract interface class OnscreenKeyboardLearningStore {
  Future<OnscreenKeyboardLearningSnapshot> load(Locale locale);

  Future<void> save(Locale locale, OnscreenKeyboardLearningSnapshot snapshot);

  Future<void> clear(Locale locale);
}

@immutable
class OnscreenKeyboardLexiconEntry {
  const OnscreenKeyboardLexiconEntry(this.word, this.weight);

  final String word;
  final double weight;
}

/// Dependency-free weighted lexicon suitable for deterministic offline use.
class WeightedLexiconLanguageModel implements OnscreenKeyboardLanguageModel {
  WeightedLexiconLanguageModel({
    required Map<String, Iterable<OnscreenKeyboardLexiconEntry>> lexicons,
    this.learningStore,
    this.maximumLearnedWords = 2000,
    this.maximumLearnedBigrams = 4000,
  }) {
    _lexicons = {
      for (final entry in lexicons.entries)
        entry.key.toLowerCase(): List.unmodifiable(entry.value),
    };
    for (final language in _lexicons.entries) {
      final prefixes = <String, List<OnscreenKeyboardLexiconEntry>>{};
      final swipeEdges = <String, List<OnscreenKeyboardLexiconEntry>>{};
      for (final entry in language.value) {
        final normalized = entry.word.toLowerCase();
        for (
          var length = 1;
          length <= math.min(4, normalized.length);
          length++
        ) {
          final prefix = normalized.substring(0, length);
          prefixes.putIfAbsent(prefix, () => []).add(entry);
        }
        final edges =
            '${normalized.characters.first}\u0000'
            '${normalized.characters.last}';
        swipeEdges.putIfAbsent(edges, () => []).add(entry);
      }
      _prefixIndex[language.key] = prefixes;
      _swipeEdgeIndex[language.key] = swipeEdges;
    }
  }

  late final Map<String, List<OnscreenKeyboardLexiconEntry>> _lexicons;
  final Map<String, Map<String, List<OnscreenKeyboardLexiconEntry>>>
  _prefixIndex = {};
  final Map<String, Map<String, List<OnscreenKeyboardLexiconEntry>>>
  _swipeEdgeIndex = {};
  final OnscreenKeyboardLearningStore? learningStore;
  final int maximumLearnedWords;
  final int maximumLearnedBigrams;
  final Map<String, OnscreenKeyboardLearningSnapshot> _learning = {};
  final Set<String> _loaded = {};

  Future<void> _ensureLoaded(Locale locale) async {
    final language = locale.languageCode.toLowerCase();
    if (_loaded.add(language)) {
      _learning[language] =
          await learningStore?.load(locale) ??
          const OnscreenKeyboardLearningSnapshot();
    }
  }

  @override
  Future<List<OnscreenKeyboardSuggestion>> suggestions(
    OnscreenKeyboardSuggestionRequest request,
  ) async {
    await _ensureLoaded(request.locale);
    request.cancellationToken.throwIfCancelled();
    final prefix = request.prefix.toLowerCase();
    final language = request.locale.languageCode.toLowerCase();
    final learned = _learning[language]!;
    final candidates = <OnscreenKeyboardSuggestion>[];
    final entries =
        _lexicons[language] ?? const <OnscreenKeyboardLexiconEntry>[];
    var source = entries.take(256);
    if (prefix.isNotEmpty) {
      source = const <OnscreenKeyboardLexiconEntry>[];
      for (var length = math.min(4, prefix.length); length >= 1; length--) {
        final matches = _prefixIndex[language]?[prefix.substring(0, length)];
        if (matches != null && matches.isNotEmpty) {
          source = matches;
          break;
        }
      }
    }
    for (final entry in source) {
      request.cancellationToken.throwIfCancelled();
      final word = entry.word.toLowerCase();
      final distance = _editDistance(prefix, word);
      final begins = word.startsWith(prefix);
      if (prefix.isNotEmpty &&
          !begins &&
          distance > math.max(1, prefix.length ~/ 3)) {
        continue;
      }
      final learnedBoost = math.log(1 + (learned.words[word] ?? 0)) * 0.35;
      final bigramBoost = request.previousWord == null
          ? 0.0
          : math.log(
                  1 +
                      (learned.bigrams['${request.previousWord!.toLowerCase()}\u0000$word'] ??
                          0),
                ) *
                0.55;
      final similarity = prefix.isEmpty
          ? 0.0
          : 1 - distance / math.max(prefix.length, word.length);
      final score =
          entry.weight +
          (begins ? 1.2 : 0) +
          similarity +
          learnedBoost +
          bigramBoost;
      candidates.add(
        OnscreenKeyboardSuggestion(
          word: entry.word,
          score: score,
          confidence: (0.52 + similarity * 0.52 + (begins ? 0.08 : 0)).clamp(
            0,
            1,
          ),
        ),
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(request.limit).toList(growable: false);
  }

  @override
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  ) async {
    await _ensureLoaded(request.locale);
    request.cancellationToken.throwIfCancelled();
    final trace = _collapseTrace(request.trace);
    if (trace.isEmpty) return const [];
    final language = request.locale.languageCode.toLowerCase();
    final learned = _learning[language]!;
    final candidates = <OnscreenKeyboardSuggestion>[];
    final hasGeometry =
        request.points.length >= 2 && request.keyCenters.isNotEmpty;
    final source = _swipeCandidates(
      language,
      trace,
      request.points,
      request.keyCenters,
    );
    final sampledTrace = hasGeometry
        ? _resample(request.points, 32)
        : const <Offset>[];
    for (final entry in source) {
      request.cancellationToken.throwIfCancelled();
      final word = entry.word.toLowerCase();
      if (!hasGeometry &&
          (word.characters.first != trace.first ||
              word.characters.last != trace.last)) {
        continue;
      }
      final skeleton = _collapseTrace(word.characters.toList());
      final orderedSimilarity = _swipeSimilarity(trace, skeleton);
      var geometryScore = 0.0;
      if (hasGeometry) {
        final template = skeleton
            .map((character) => request.keyCenters[character])
            .whereType<Offset>()
            .toList(growable: false);
        if (template.length < 2) continue;
        geometryScore = _geometrySimilarity(
          sampledTrace,
          _resample(template, 32),
        );
        if (geometryScore < .2 && orderedSimilarity < .45) continue;
      } else if (orderedSimilarity < 0.3) {
        continue;
      }
      final learnedBoost = math.log(1 + (learned.words[word] ?? 0)) * 0.35;
      final swipeScore = hasGeometry
          ? geometryScore * 5.4 + orderedSimilarity * 0.8
          : orderedSimilarity * 2.5 + 1;
      candidates.add(
        OnscreenKeyboardSuggestion(
          word: entry.word,
          score: entry.weight + swipeScore + learnedBoost,
          confidence: (0.18 + geometryScore * 0.68 + orderedSimilarity * 0.14)
              .clamp(0, 1),
        ),
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(request.limit).toList(growable: false);
  }

  Iterable<OnscreenKeyboardLexiconEntry> _swipeCandidates(
    String language,
    List<String> trace,
    List<Offset> points,
    Map<String, Offset> keyCenters,
  ) {
    final index = _swipeEdgeIndex[language];
    if (index == null) return const [];
    if (points.length < 2 || keyCenters.isEmpty) {
      return index['${trace.first}\u0000${trace.last}'] ?? const [];
    }
    final starts = _nearestKeys(points.first, keyCenters, trace.first);
    final ends = _nearestKeys(points.last, keyCenters, trace.last);
    final candidates = <OnscreenKeyboardLexiconEntry>{};
    for (final start in starts) {
      for (final end in ends) {
        candidates.addAll(index['$start\u0000$end'] ?? const []);
      }
    }
    return candidates;
  }

  static List<String> _nearestKeys(
    Offset point,
    Map<String, Offset> centers,
    String fallback,
  ) {
    final entries = centers.entries.toList()
      ..sort(
        (a, b) => (a.value - point).distanceSquared.compareTo(
          (b.value - point).distanceSquared,
        ),
      );
    final result = entries.take(3).map((entry) => entry.key).toList();
    if (!result.contains(fallback)) result.add(fallback);
    return result;
  }

  @override
  Future<void> learnAcceptedWord({
    required Locale locale,
    required String word,
    String? previousWord,
  }) async {
    await _ensureLoaded(locale);
    final language = locale.languageCode.toLowerCase();
    final current = _learning[language]!;
    final words = Map<String, int>.of(current.words);
    final normalized = word.toLowerCase();
    words[normalized] = (words[normalized] ?? 0) + 1;
    _trim(words, maximumLearnedWords);
    final bigrams = Map<String, int>.of(current.bigrams);
    if (previousWord?.isNotEmpty ?? false) {
      final key = '${previousWord!.toLowerCase()}\u0000$normalized';
      bigrams[key] = (bigrams[key] ?? 0) + 1;
      _trim(bigrams, maximumLearnedBigrams);
    }
    final next = OnscreenKeyboardLearningSnapshot(
      words: words,
      bigrams: bigrams,
    );
    _learning[language] = next;
    await learningStore?.save(locale, next);
  }

  static void _trim(Map<String, int> values, int limit) {
    if (values.length <= limit) return;
    final keys = values.keys.toList()
      ..sort((a, b) {
        final byCount = values[b]!.compareTo(values[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    keys.skip(limit).forEach(values.remove);
  }

  static List<String> _collapseTrace(List<String> values) {
    final result = <String>[];
    for (final value in values.map((value) => value.toLowerCase())) {
      if (result.isEmpty || result.last != value) result.add(value);
    }
    return result;
  }

  /// Scores a word skeleton against all keys crossed by a continuous trace.
  ///
  /// A geometric swipe naturally crosses incidental keys between the letters
  /// the user intended. Ordered overlap therefore matters much more than raw
  /// edit distance, while the smaller density term still rewards direct paths.
  static double _swipeSimilarity(List<String> trace, List<String> skeleton) {
    if (trace.isEmpty || skeleton.isEmpty) return 0;
    final previous = List<int>.filled(trace.length + 1, 0);
    for (var i = 0; i < skeleton.length; i++) {
      var diagonal = previous[0];
      for (var j = 0; j < trace.length; j++) {
        final above = previous[j + 1];
        previous[j + 1] = skeleton[i] == trace[j]
            ? diagonal + 1
            : math.max(previous[j], above);
        diagonal = above;
      }
    }
    final overlap = previous.last;
    final coverage = overlap / skeleton.length;
    final density = overlap / trace.length;
    return coverage * 0.82 + density * 0.18;
  }

  static double _geometrySimilarity(
    List<Offset> trace,
    List<Offset> template,
  ) {
    if (trace.length != template.length || trace.length < 2) return 0;
    var locationDistance = 0.0;
    for (var index = 0; index < trace.length; index++) {
      locationDistance += (trace[index] - template[index]).distance;
    }
    locationDistance /= trace.length;

    final traceShape = _normalizeShape(trace);
    final templateShape = _normalizeShape(template);
    var shapeDistance = 0.0;
    for (var index = 0; index < traceShape.length; index++) {
      shapeDistance += (traceShape[index] - templateShape[index]).distance;
    }
    shapeDistance /= traceShape.length;

    final endpointDistance =
        ((trace.first - template.first).distance +
            (trace.last - template.last).distance) /
        2;
    final location = math.exp(-locationDistance * 7.5);
    final shape = math.exp(-shapeDistance * 4.5);
    final endpoints = math.exp(-endpointDistance * 10);
    return location * .42 + shape * .43 + endpoints * .15;
  }

  static List<Offset> _normalizeShape(List<Offset> points) {
    var minX = points.first.dx;
    var maxX = minX;
    var minY = points.first.dy;
    var maxY = minY;
    for (final point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    final scale = math.max(math.max(maxX - minX, maxY - minY), .0001);
    return points
        .map(
          (point) =>
              Offset((point.dx - minX) / scale, (point.dy - minY) / scale),
        )
        .toList(growable: false);
  }

  static List<Offset> _resample(List<Offset> points, int count) {
    if (points.isEmpty || count <= 0) return const [];
    if (points.length == 1) return List.filled(count, points.first);
    final distances = <double>[0];
    for (var index = 1; index < points.length; index++) {
      distances.add(
        distances.last + (points[index] - points[index - 1]).distance,
      );
    }
    final total = distances.last;
    if (total <= .0001) return List.filled(count, points.first);
    final result = <Offset>[];
    var segment = 1;
    for (var sample = 0; sample < count; sample++) {
      final target = total * sample / (count - 1);
      while (segment < distances.length - 1 && distances[segment] < target) {
        segment++;
      }
      final startDistance = distances[segment - 1];
      final segmentLength = distances[segment] - startDistance;
      final t = segmentLength <= .0001
          ? 0.0
          : (target - startDistance) / segmentLength;
      result.add(Offset.lerp(points[segment - 1], points[segment], t)!);
    }
    return result;
  }

  static int _editDistance(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 0; i < a.length; i++) {
      var diagonal = previous[0];
      previous[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final above = previous[j + 1];
        previous[j + 1] = math.min(
          math.min(previous[j] + 1, above + 1),
          diagonal + (a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1),
        );
        diagonal = above;
      }
    }
    return previous.last;
  }
}

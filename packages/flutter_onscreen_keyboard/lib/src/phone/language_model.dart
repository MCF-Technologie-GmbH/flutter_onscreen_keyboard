// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum OnscreenKeyboardSuggestionKind {
  typed,
  completion,
  correction,
  nextWord,
  swipe,
}

/// A ranked language-model result.
@immutable
class OnscreenKeyboardSuggestion {
  const OnscreenKeyboardSuggestion({
    required this.word,
    required this.score,
    this.confidence = 0,
    this.kind = OnscreenKeyboardSuggestionKind.completion,
  });

  final String word;
  final double score;
  final double confidence;
  final OnscreenKeyboardSuggestionKind kind;
}

@immutable
class OnscreenKeyboardSwipeCandidateDiagnostic {
  const OnscreenKeyboardSwipeCandidateDiagnostic({
    required this.word,
    required this.score,
    required this.confidence,
    required this.geometry,
    required this.orderedTrace,
    required this.context,
    required this.learning,
  });

  final String word;
  final double score;
  final double confidence;
  final double geometry;
  final double orderedTrace;
  final double context;
  final double learning;
}

@immutable
class OnscreenKeyboardSwipeDiagnostic {
  const OnscreenKeyboardSwipeDiagnostic({
    required this.locale,
    required this.trace,
    required this.points,
    required this.candidates,
    required this.elapsed,
  });

  final Locale locale;
  final List<String> trace;
  final List<Offset> points;
  final List<OnscreenKeyboardSwipeCandidateDiagnostic> candidates;
  final Duration elapsed;
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
    this.previousPreviousWord,
    this.limit = 3,
  });

  final Locale locale;
  final String prefix;
  final String? previousWord;
  final String? previousPreviousWord;
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
    this.previousPreviousWord,
    this.limit = 3,
    this.points = const [],
    this.keyCenters = const {},
    this.onDiagnostic,
  });

  final Locale locale;
  final List<String> trace;
  final String? previousWord;
  final String? previousPreviousWord;
  final int limit;
  final OnscreenKeyboardCancellationToken cancellationToken;

  /// Normalized touch positions sampled continuously during the gesture.
  final List<Offset> points;

  /// Normalized center position of each printable key in the active layout.
  final Map<String, Offset> keyCenters;

  /// Optional opt-in diagnostics sink. No gesture data is retained by the
  /// package when this is null.
  final ValueChanged<OnscreenKeyboardSwipeDiagnostic>? onDiagnostic;
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

/// Optional personalization operations supported by adaptive language models.
abstract interface class OnscreenKeyboardPersonalizationModel {
  Future<void> learnSwipeGesture({
    required Locale locale,
    required String word,
    required OnscreenKeyboardSwipeData gesture,
  });

  Future<void> forgetWord({required Locale locale, required String word});
}

/// Optional richer context learning while retaining the original model API.
// ignore: one_member_abstracts
abstract interface class OnscreenKeyboardContextLanguageModel {
  Future<void> learnAcceptedContext({
    required Locale locale,
    required String word,
    String? previousWord,
    String? previousPreviousWord,
  });
}

@immutable
class OnscreenKeyboardLearningSnapshot {
  const OnscreenKeyboardLearningSnapshot({
    this.words = const {},
    this.bigrams = const {},
    this.trigrams = const {},
    this.touchOffsets = const {},
    this.touchOffsetCounts = const {},
    this.blockedWords = const {},
  });

  final Map<String, int> words;
  final Map<String, int> bigrams;
  final Map<String, int> trigrams;
  final Map<String, Offset> touchOffsets;
  final Map<String, int> touchOffsetCounts;
  final Set<String> blockedWords;
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
class WeightedLexiconLanguageModel
    implements
        OnscreenKeyboardLanguageModel,
        OnscreenKeyboardPersonalizationModel,
        OnscreenKeyboardContextLanguageModel {
  WeightedLexiconLanguageModel({
    required Map<String, Iterable<OnscreenKeyboardLexiconEntry>> lexicons,
    this.learningStore,
    this.maximumLearnedWords = 2000,
    this.maximumLearnedBigrams = 4000,
    this.maximumLearnedTrigrams = 6000,
    this.maximumBlockedWords = 500,
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
        _wordIndex.putIfAbsent(language.key, () => {})[normalized] = entry;
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
  final Map<String, Map<String, OnscreenKeyboardLexiconEntry>> _wordIndex = {};
  final OnscreenKeyboardLearningStore? learningStore;
  final int maximumLearnedWords;
  final int maximumLearnedBigrams;
  final int maximumLearnedTrigrams;
  final int maximumBlockedWords;
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
    final sourceByWord = <String, OnscreenKeyboardLexiconEntry>{};
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
    } else {
      final contextualKeys = <String>{};
      final previous = request.previousWord?.toLowerCase();
      final previousPrevious = request.previousPreviousWord?.toLowerCase();
      if (previous != null) {
        for (final key in learned.bigrams.keys) {
          if (key.startsWith('$previous\u0000')) {
            contextualKeys.add(key.substring(key.lastIndexOf('\u0000') + 1));
          }
        }
      }
      if (previous != null && previousPrevious != null) {
        final prefixKey = '$previousPrevious\u0000$previous\u0000';
        for (final key in learned.trigrams.keys) {
          if (key.startsWith(prefixKey)) {
            contextualKeys.add(key.substring(key.lastIndexOf('\u0000') + 1));
          }
        }
      }
      for (final word in contextualKeys) {
        final entry = _wordIndex[language]?[word];
        if (entry != null) sourceByWord[word] = entry;
      }
    }
    for (final entry in source.take(4096)) {
      sourceByWord.putIfAbsent(entry.word.toLowerCase(), () => entry);
    }
    for (final entry in sourceByWord.values) {
      request.cancellationToken.throwIfCancelled();
      final word = entry.word.toLowerCase();
      if (learned.blockedWords.contains(word)) continue;
      final distance = _editDistance(prefix, word);
      final begins = word.startsWith(prefix);
      if (prefix.isNotEmpty &&
          !begins &&
          distance > math.max(1, prefix.length ~/ 3)) {
        continue;
      }
      final learnedBoost = math.log(1 + (learned.words[word] ?? 0)) * 0.35;
      final contextBoost = _contextBoost(
        learned,
        word,
        request.previousWord,
        request.previousPreviousWord,
      );
      final similarity = prefix.isEmpty
          ? 0.0
          : 1 - distance / math.max(prefix.length, word.length);
      final score =
          entry.weight +
          (begins ? 1.2 : 0) +
          similarity +
          learnedBoost +
          contextBoost;
      candidates.add(
        OnscreenKeyboardSuggestion(
          word: entry.word,
          score: score,
          confidence: (0.52 + similarity * 0.52 + (begins ? 0.08 : 0))
              .clamp(
                0,
                1,
              )
              .toDouble(),
          kind: prefix.isEmpty
              ? OnscreenKeyboardSuggestionKind.nextWord
              : begins
              ? OnscreenKeyboardSuggestionKind.completion
              : OnscreenKeyboardSuggestionKind.correction,
        ),
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    if (prefix.isNotEmpty) {
      candidates
        ..removeWhere(
          (candidate) => candidate.word.toLowerCase() == prefix,
        )
        ..insert(
          0,
          OnscreenKeyboardSuggestion(
            word: request.prefix,
            score: candidates.isEmpty ? 0 : candidates.first.score + .01,
            confidence: 1,
            kind: OnscreenKeyboardSuggestionKind.typed,
          ),
        );
    }
    return candidates.take(request.limit).toList(growable: false);
  }

  @override
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    await _ensureLoaded(request.locale);
    request.cancellationToken.throwIfCancelled();
    final trace = _collapseTrace(request.trace);
    if (trace.isEmpty) return const [];
    final language = request.locale.languageCode.toLowerCase();
    final learned = _learning[language]!;
    final candidates = <OnscreenKeyboardSuggestion>[];
    final diagnostics = <String, OnscreenKeyboardSwipeCandidateDiagnostic>{};
    final hasGeometry =
        request.points.length >= 2 && request.keyCenters.isNotEmpty;
    final adaptiveCenters = {
      for (final entry in request.keyCenters.entries)
        entry.key: Offset(
          (entry.value.dx + (learned.touchOffsets[entry.key]?.dx ?? 0))
              .clamp(0, 1)
              .toDouble(),
          (entry.value.dy + (learned.touchOffsets[entry.key]?.dy ?? 0))
              .clamp(0, 1)
              .toDouble(),
        ),
    };
    final source = _swipeCandidates(
      language,
      trace,
      request.points,
      adaptiveCenters,
    );
    final sampledTrace = hasGeometry
        ? _resample(request.points, 32)
        : const <Offset>[];
    for (final entry in source) {
      request.cancellationToken.throwIfCancelled();
      final word = entry.word.toLowerCase();
      if (learned.blockedWords.contains(word)) continue;
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
            .map((character) => adaptiveCenters[character])
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
      final contextBoost = _contextBoost(
        learned,
        word,
        request.previousWord,
        request.previousPreviousWord,
      );
      final swipeScore = hasGeometry
          ? geometryScore * 5.4 + orderedSimilarity * 0.8
          : orderedSimilarity * 2.5 + 1;
      final totalScore =
          entry.weight + swipeScore + learnedBoost + contextBoost;
      final confidence =
          (0.18 + geometryScore * 0.68 + orderedSimilarity * 0.14).clamp(0, 1);
      candidates.add(
        OnscreenKeyboardSuggestion(
          word: entry.word,
          score: totalScore,
          confidence: confidence.toDouble(),
          kind: OnscreenKeyboardSuggestionKind.swipe,
        ),
      );
      diagnostics[word] = OnscreenKeyboardSwipeCandidateDiagnostic(
        word: entry.word,
        score: totalScore,
        confidence: confidence.toDouble(),
        geometry: geometryScore,
        orderedTrace: orderedSimilarity,
        context: contextBoost,
        learning: learnedBoost,
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final result = candidates.take(request.limit).toList(growable: false);
    stopwatch.stop();
    request.onDiagnostic?.call(
      OnscreenKeyboardSwipeDiagnostic(
        locale: request.locale,
        trace: List.unmodifiable(trace),
        points: List.unmodifiable(request.points),
        candidates: List.unmodifiable([
          for (final candidate in candidates.take(10))
            diagnostics[candidate.word.toLowerCase()]!,
        ]),
        elapsed: stopwatch.elapsed,
      ),
    );
    return result;
  }

  static double _contextBoost(
    OnscreenKeyboardLearningSnapshot learned,
    String word,
    String? previousWord,
    String? previousPreviousWord,
  ) {
    final previous = previousWord?.toLowerCase();
    final previousPrevious = previousPreviousWord?.toLowerCase();
    final bigram = previous == null
        ? 0
        : learned.bigrams['$previous\u0000$word'] ?? 0;
    final trigram = previous == null || previousPrevious == null
        ? 0
        : learned.trigrams['$previousPrevious\u0000$previous\u0000$word'] ?? 0;
    return math.log(1 + bigram) * .55 + math.log(1 + trigram) * .8;
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
  }) => learnAcceptedContext(
    locale: locale,
    word: word,
    previousWord: previousWord,
  );

  @override
  Future<void> learnAcceptedContext({
    required Locale locale,
    required String word,
    String? previousWord,
    String? previousPreviousWord,
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
    final trigrams = Map<String, int>.of(current.trigrams);
    if ((previousWord?.isNotEmpty ?? false) &&
        (previousPreviousWord?.isNotEmpty ?? false)) {
      final key =
          '${previousPreviousWord!.toLowerCase()}\u0000'
          '${previousWord!.toLowerCase()}\u0000$normalized';
      trigrams[key] = (trigrams[key] ?? 0) + 1;
      _trim(trigrams, maximumLearnedTrigrams);
    }
    final blockedWords = Set<String>.of(current.blockedWords)
      ..remove(normalized);
    final next = OnscreenKeyboardLearningSnapshot(
      words: words,
      bigrams: bigrams,
      trigrams: trigrams,
      touchOffsets: current.touchOffsets,
      touchOffsetCounts: current.touchOffsetCounts,
      blockedWords: blockedWords,
    );
    await _save(locale, next);
  }

  @override
  Future<void> forgetWord({
    required Locale locale,
    required String word,
  }) async {
    await _ensureLoaded(locale);
    final language = locale.languageCode.toLowerCase();
    final normalized = word.toLowerCase();
    final current = _learning[language]!;
    final words = Map<String, int>.of(current.words)..remove(normalized);
    final bigrams = Map<String, int>.of(current.bigrams)
      ..removeWhere((key, _) => key.split('\u0000').contains(normalized));
    final trigrams = Map<String, int>.of(current.trigrams)
      ..removeWhere((key, _) => key.split('\u0000').contains(normalized));
    final blockedWords = Set<String>.of(current.blockedWords)..add(normalized);
    while (blockedWords.length > maximumBlockedWords) {
      blockedWords.remove(blockedWords.first);
    }
    await _save(
      locale,
      OnscreenKeyboardLearningSnapshot(
        words: words,
        bigrams: bigrams,
        trigrams: trigrams,
        touchOffsets: current.touchOffsets,
        touchOffsetCounts: current.touchOffsetCounts,
        blockedWords: blockedWords,
      ),
    );
  }

  @override
  Future<void> learnSwipeGesture({
    required Locale locale,
    required String word,
    required OnscreenKeyboardSwipeData gesture,
  }) async {
    if (gesture.points.length < 2 || gesture.keyCenters.isEmpty) return;
    await _ensureLoaded(locale);
    final language = locale.languageCode.toLowerCase();
    final current = _learning[language]!;
    final offsets = Map<String, Offset>.of(current.touchOffsets);
    final counts = Map<String, int>.of(current.touchOffsetCounts);
    final characters = word.toLowerCase().characters.toList();
    final actualPoints = _resample(gesture.points, characters.length);
    for (var index = 0; index < characters.length; index++) {
      final character = characters[index];
      final expected = gesture.keyCenters[character];
      if (expected == null) continue;
      var delta = actualPoints[index] - expected;
      if (delta.distance > .07) {
        delta = Offset.fromDirection(delta.direction, .07);
      }
      final count = counts[character] ?? 0;
      final rate = 1 / math.min(count + 1, 12);
      offsets[character] = Offset.lerp(
        offsets[character] ?? Offset.zero,
        delta,
        rate,
      )!;
      counts[character] = count + 1;
    }
    await _save(
      locale,
      OnscreenKeyboardLearningSnapshot(
        words: current.words,
        bigrams: current.bigrams,
        trigrams: current.trigrams,
        touchOffsets: offsets,
        touchOffsetCounts: counts,
        blockedWords: current.blockedWords,
      ),
    );
  }

  Future<void> _save(
    Locale locale,
    OnscreenKeyboardLearningSnapshot snapshot,
  ) async {
    final language = locale.languageCode.toLowerCase();
    _learning[language] = snapshot;
    await learningStore?.save(locale, snapshot);
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

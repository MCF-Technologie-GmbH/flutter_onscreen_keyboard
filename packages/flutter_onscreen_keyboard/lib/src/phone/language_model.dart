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
  });

  final Locale locale;
  final List<String> trace;
  final String? previousWord;
  final int limit;
  final OnscreenKeyboardCancellationToken cancellationToken;
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
        final prefix = normalized.substring(0, math.min(2, normalized.length));
        prefixes.putIfAbsent(prefix, () => []).add(entry);
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
    final source = prefix.isEmpty
        ? entries.take(256)
        : _prefixIndex[language]?[prefix.substring(
                0,
                math.min(2, prefix.length),
              )] ??
              const <OnscreenKeyboardLexiconEntry>[];
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
    final source =
        _swipeEdgeIndex[language]?['${trace.first}\u0000${trace.last}'] ??
        const <OnscreenKeyboardLexiconEntry>[];
    for (final entry in source) {
      request.cancellationToken.throwIfCancelled();
      final word = entry.word.toLowerCase();
      if (word.characters.first != trace.first ||
          word.characters.last != trace.last) {
        continue;
      }
      final skeleton = _collapseTrace(word.characters.toList());
      final similarity = _swipeSimilarity(trace, skeleton);
      if (similarity < 0.3) continue;
      final learnedBoost = math.log(1 + (learned.words[word] ?? 0)) * 0.35;
      candidates.add(
        OnscreenKeyboardSuggestion(
          word: entry.word,
          score: entry.weight + similarity * 2.5 + learnedBoost + 1,
          confidence: (0.35 + similarity * 0.65).clamp(0, 1),
        ),
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(request.limit).toList(growable: false);
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

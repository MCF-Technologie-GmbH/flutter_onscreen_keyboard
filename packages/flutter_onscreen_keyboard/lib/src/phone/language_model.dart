// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:typed_data';

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
    this.exactMatch = false,
  });

  final String word;
  final double score;
  final double confidence;
  final OnscreenKeyboardSuggestionKind kind;

  /// Whether the typed token is already valid in the active lexicon.
  final bool exactMatch;
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

/// One normalized touch sample associated with a typed character.
@immutable
class OnscreenKeyboardTapSample {
  const OnscreenKeyboardTapSample({
    required this.character,
    required this.position,
    required this.keyCenter,
    required this.timestamp,
    this.keyCenters = const {},
  });

  final String character;
  final Offset position;
  final Offset keyCenter;
  final Duration timestamp;

  /// Live centers for every visible text key in the same coordinate space as
  /// [position]. Older callers may omit this and provide request geometry
  /// separately.
  final Map<String, Offset> keyCenters;
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
    this.tapSamples = const [],
    this.keyCenters = const {},
  });

  final Locale locale;
  final String prefix;
  final String? previousWord;
  final String? previousPreviousWord;
  final int limit;
  final OnscreenKeyboardCancellationToken cancellationToken;
  final List<OnscreenKeyboardTapSample> tapSamples;
  final Map<String, Offset> keyCenters;
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
abstract interface class OnscreenKeyboardSuggestionModel {
  Future<List<OnscreenKeyboardSuggestion>> suggestions(
    OnscreenKeyboardSuggestionRequest request,
  );

  Future<void> learnAcceptedWord({
    required Locale locale,
    required String word,
    String? previousWord,
  });
}

/// Optional experimental swipe-decoding capability.
// ignore: one_member_abstracts
abstract interface class OnscreenKeyboardSwipeModel {
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  );
}

/// Backwards-compatible aggregate implemented by existing language models.
abstract interface class OnscreenKeyboardLanguageModel
    implements OnscreenKeyboardSuggestionModel, OnscreenKeyboardSwipeModel {}

/// Optional feedback capability for accepted and immediately undone fixes.
// ignore: one_member_abstracts
abstract interface class OnscreenKeyboardCorrectionLearningModel {
  Future<void> recordCorrectionOutcome({
    required Locale locale,
    required String original,
    required String replacement,
    required bool accepted,
  });
}

/// Optional explicit-suggestion personalization capability.
// ignore: one_member_abstracts
abstract interface class OnscreenKeyboardSuggestionPersonalizationModel {
  Future<void> forgetWord({required Locale locale, required String word});
}

/// Optional experimental swipe-learning capability.
// ignore: one_member_abstracts
abstract interface class OnscreenKeyboardSwipeLearningModel {
  Future<void> learnSwipeGesture({
    required Locale locale,
    required String word,
    required OnscreenKeyboardSwipeData gesture,
  });
}

/// Backwards-compatible personalization aggregate.
abstract interface class OnscreenKeyboardPersonalizationModel
    implements
        OnscreenKeyboardSuggestionPersonalizationModel,
        OnscreenKeyboardSwipeLearningModel {}

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
    this.correctionOutcomes = const {},
  });

  final Map<String, int> words;
  final Map<String, int> bigrams;
  final Map<String, int> trigrams;
  final Map<String, Offset> touchOffsets;
  final Map<String, int> touchOffsetCounts;
  final Set<String> blockedWords;
  final Map<String, int> correctionOutcomes;
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

/// Pre-indexed lexicon data that can be prepared on a background isolate.
@immutable
class OnscreenKeyboardPreparedLexicon {
  const OnscreenKeyboardPreparedLexicon._({
    required this.entries,
    required this.prefixIndex,
    required this.swipeEdgeIndex,
    required this.wordIndex,
    required _CompactLexiconTrie correctionTrie,
  }) : _correctionTrie = correctionTrie;

  factory OnscreenKeyboardPreparedLexicon.prepare(
    Iterable<OnscreenKeyboardLexiconEntry> source, {
    bool includeExperimentalSwipeIndex = true,
    bool includeLegacyLookupIndexes = true,
  }) {
    final entries = List<OnscreenKeyboardLexiconEntry>.unmodifiable(source);
    final prefixes = <String, List<OnscreenKeyboardLexiconEntry>>{};
    final swipeEdges = <String, List<OnscreenKeyboardLexiconEntry>>{};
    final words = <String, OnscreenKeyboardLexiconEntry>{};
    for (final entry in entries) {
      final normalized = entry.word.toLowerCase();
      if (includeLegacyLookupIndexes) {
        words[normalized] = entry;
        for (
          var length = 1;
          length <= math.min(4, normalized.length);
          length++
        ) {
          final prefix = normalized.substring(0, length);
          prefixes.putIfAbsent(prefix, () => []).add(entry);
        }
      }
      if (includeExperimentalSwipeIndex) {
        final edges =
            '${normalized.characters.first}\u0000'
            '${normalized.characters.last}';
        swipeEdges.putIfAbsent(edges, () => []).add(entry);
      }
    }
    return OnscreenKeyboardPreparedLexicon._(
      entries: entries,
      prefixIndex: prefixes,
      swipeEdgeIndex: swipeEdges,
      wordIndex: words,
      correctionTrie: _CompactLexiconTrie.build(entries),
    );
  }

  final List<OnscreenKeyboardLexiconEntry> entries;
  final Map<String, List<OnscreenKeyboardLexiconEntry>> prefixIndex;
  final Map<String, List<OnscreenKeyboardLexiconEntry>> swipeEdgeIndex;
  final Map<String, OnscreenKeyboardLexiconEntry> wordIndex;
  final _CompactLexiconTrie _correctionTrie;
}

/// One immutable static n-gram used for contextual ranking.
@immutable
class OnscreenKeyboardContextEntry {
  // A const constructor cannot validate a List length in the supported SDK.
  // ignore: prefer_const_constructors_in_immutables
  OnscreenKeyboardContextEntry({
    required this.words,
    required this.weight,
  }) : assert(
         words.length == 2 || words.length == 3,
         'Context entries must contain a bigram or trigram',
       );

  final List<String> words;
  final double weight;
}

/// Context indexes prepared off the UI isolate with the lexicon.
@immutable
class OnscreenKeyboardPreparedContext {
  OnscreenKeyboardPreparedContext.prepare(
    Iterable<OnscreenKeyboardContextEntry> source,
  ) {
    for (final entry in source) {
      final words = entry.words.map((word) => word.toLowerCase()).toList();
      final key = words.join('\u0000');
      if (words.length == 2) {
        bigrams[key] = entry.weight;
        nextWords.putIfAbsent(words.first, () => {})[words.last] = entry.weight;
      } else {
        trigrams[key] = entry.weight;
        nextWords.putIfAbsent(
          '${words[0]}\u0000${words[1]}',
          () => {},
        )[words.last] = entry.weight;
      }
    }
  }

  final Map<String, double> bigrams = {};
  final Map<String, double> trigrams = {};
  final Map<String, Map<String, double>> nextWords = {};
}

final class _MutableTrieNode {
  final Map<int, int> children = {};
  int terminalEntry = -1;
}

/// A compact immutable trie used for bounded edit-distance traversal.
final class _CompactLexiconTrie {
  const _CompactLexiconTrie({
    required this.firstEdge,
    required this.edgeCharacters,
    required this.edgeTargets,
    required this.terminalEntries,
    required this.bestEntries,
  });

  factory _CompactLexiconTrie.build(
    List<OnscreenKeyboardLexiconEntry> entries,
  ) {
    final nodes = <_MutableTrieNode>[_MutableTrieNode()];
    for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
      var node = 0;
      for (final rune in entries[entryIndex].word.toLowerCase().runes) {
        node = nodes[node].children.putIfAbsent(rune, () {
          nodes.add(_MutableTrieNode());
          return nodes.length - 1;
        });
      }
      nodes[node].terminalEntry = entryIndex;
    }
    final edgeCount = nodes.fold<int>(
      0,
      (total, node) => total + node.children.length,
    );
    final firstEdge = Uint32List(nodes.length + 1);
    final edgeCharacters = Uint32List(edgeCount);
    final edgeTargets = Uint32List(edgeCount);
    final terminalEntries = Int32List(nodes.length);
    final bestEntries = Int32List(nodes.length)..fillRange(0, nodes.length, -1);
    var edge = 0;
    for (var nodeIndex = 0; nodeIndex < nodes.length; nodeIndex++) {
      firstEdge[nodeIndex] = edge;
      terminalEntries[nodeIndex] = nodes[nodeIndex].terminalEntry;
      final children = nodes[nodeIndex].children.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final child in children) {
        edgeCharacters[edge] = child.key;
        edgeTargets[edge] = child.value;
        edge++;
      }
    }
    firstEdge[nodes.length] = edge;
    for (var nodeIndex = nodes.length - 1; nodeIndex >= 0; nodeIndex--) {
      var best = terminalEntries[nodeIndex];
      for (
        var childEdge = firstEdge[nodeIndex];
        childEdge < firstEdge[nodeIndex + 1];
        childEdge++
      ) {
        final childBest = bestEntries[edgeTargets[childEdge]];
        if (childBest >= 0 &&
            (best < 0 || entries[childBest].weight > entries[best].weight)) {
          best = childBest;
        }
      }
      bestEntries[nodeIndex] = best;
    }
    return _CompactLexiconTrie(
      firstEdge: firstEdge,
      edgeCharacters: edgeCharacters,
      edgeTargets: edgeTargets,
      terminalEntries: terminalEntries,
      bestEntries: bestEntries,
    );
  }

  final Uint32List firstEdge;
  final Uint32List edgeCharacters;
  final Uint32List edgeTargets;
  final Int32List terminalEntries;
  final Int32List bestEntries;

  int entryForWord(String word) {
    var node = 0;
    for (final rune in word.toLowerCase().runes) {
      var next = -1;
      for (var edge = firstEdge[node]; edge < firstEdge[node + 1]; edge++) {
        if (edgeCharacters[edge] == rune) {
          next = edgeTargets[edge];
          break;
        }
      }
      if (next < 0) return -1;
      node = next;
    }
    return terminalEntries[node];
  }

  List<int> entriesForPrefix(
    String prefix,
    List<OnscreenKeyboardLexiconEntry> entries, {
    int limit = 64,
  }) {
    var node = 0;
    for (final rune in prefix.toLowerCase().runes) {
      var next = -1;
      for (var edge = firstEdge[node]; edge < firstEdge[node + 1]; edge++) {
        if (edgeCharacters[edge] == rune) {
          next = edgeTargets[edge];
          break;
        }
      }
      if (next < 0) return const [];
      node = next;
    }
    final frontier = _TrieNodeQueue(this, entries)..add(node);
    final result = <int>[];
    while (frontier.isNotEmpty && result.length < limit) {
      final current = frontier.removeHighest();
      final terminal = terminalEntries[current];
      if (terminal >= 0) result.add(terminal);
      for (
        var edge = firstEdge[current];
        edge < firstEdge[current + 1];
        edge++
      ) {
        frontier.add(edgeTargets[edge]);
      }
    }
    return result;
  }
}

final class _TrieNodeQueue {
  _TrieNodeQueue(this.trie, this.entries);

  final _CompactLexiconTrie trie;
  final List<OnscreenKeyboardLexiconEntry> entries;
  final List<int> _nodes = [];

  bool get isNotEmpty => _nodes.isNotEmpty;

  void add(int node) {
    _nodes.add(node);
    var index = _nodes.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (!_higher(_nodes[index], _nodes[parent])) break;
      final value = _nodes[index];
      _nodes[index] = _nodes[parent];
      _nodes[parent] = value;
      index = parent;
    }
  }

  int removeHighest() {
    final result = _nodes.first;
    final last = _nodes.removeLast();
    if (_nodes.isEmpty) return result;
    _nodes[0] = last;
    var index = 0;
    while (true) {
      final left = index * 2 + 1;
      if (left >= _nodes.length) break;
      final right = left + 1;
      var child = left;
      if (right < _nodes.length && _higher(_nodes[right], _nodes[left])) {
        child = right;
      }
      if (!_higher(_nodes[child], _nodes[index])) break;
      final value = _nodes[index];
      _nodes[index] = _nodes[child];
      _nodes[child] = value;
      index = child;
    }
    return result;
  }

  bool _higher(int left, int right) {
    final leftEntry = trie.bestEntries[left];
    final rightEntry = trie.bestEntries[right];
    final byWeight = entries[leftEntry].weight.compareTo(
      entries[rightEntry].weight,
    );
    return byWeight != 0 ? byWeight > 0 : left < right;
  }
}

final class _CorrectionMatch {
  const _CorrectionMatch(this.entryIndex, this.cost);

  final int entryIndex;
  final double cost;
}

/// Dependency-free weighted lexicon suitable for deterministic offline use.
class WeightedLexiconLanguageModel
    implements
        OnscreenKeyboardLanguageModel,
        OnscreenKeyboardPersonalizationModel,
        OnscreenKeyboardContextLanguageModel,
        OnscreenKeyboardCorrectionLearningModel {
  WeightedLexiconLanguageModel({
    required Map<String, Iterable<OnscreenKeyboardLexiconEntry>> lexicons,
    Map<String, Iterable<OnscreenKeyboardContextEntry>> contexts = const {},
    this.learningStore,
    this.maximumLearnedWords = 2000,
    this.maximumLearnedBigrams = 4000,
    this.maximumLearnedTrigrams = 6000,
    this.maximumBlockedWords = 500,
    this.maximumCorrectionOutcomes = 2000,
    this.minimumAutocorrectWeight = 3.2,
  }) {
    _installPrepared({
      for (final entry in lexicons.entries)
        entry.key.toLowerCase(): OnscreenKeyboardPreparedLexicon.prepare(
          entry.value,
        ),
    });
    _installContexts({
      for (final entry in contexts.entries)
        entry.key.toLowerCase(): OnscreenKeyboardPreparedContext.prepare(
          entry.value,
        ),
    });
  }

  /// Creates a model from lexicons indexed on a background isolate.
  WeightedLexiconLanguageModel.prepared({
    required Map<String, OnscreenKeyboardPreparedLexicon> lexicons,
    Map<String, OnscreenKeyboardPreparedContext> contexts = const {},
    this.learningStore,
    this.maximumLearnedWords = 2000,
    this.maximumLearnedBigrams = 4000,
    this.maximumLearnedTrigrams = 6000,
    this.maximumBlockedWords = 500,
    this.maximumCorrectionOutcomes = 2000,
    this.minimumAutocorrectWeight = 3.2,
  }) {
    _installPrepared({
      for (final entry in lexicons.entries)
        entry.key.toLowerCase(): entry.value,
    });
    _installContexts(contexts);
  }

  void _installPrepared(Map<String, OnscreenKeyboardPreparedLexicon> prepared) {
    _lexicons = {
      for (final entry in prepared.entries) entry.key: entry.value.entries,
    };
    for (final entry in prepared.entries) {
      _swipeEdgeIndex[entry.key] = entry.value.swipeEdgeIndex;
      _correctionTries[entry.key] = entry.value._correctionTrie;
    }
  }

  void _installContexts(Map<String, OnscreenKeyboardPreparedContext> prepared) {
    for (final entry in prepared.entries) {
      final language = entry.key.toLowerCase();
      _staticBigrams[language] = entry.value.bigrams;
      _staticTrigrams[language] = entry.value.trigrams;
      _staticNextWords[language] = entry.value.nextWords;
    }
  }

  late final Map<String, List<OnscreenKeyboardLexiconEntry>> _lexicons;
  final Map<String, Map<String, List<OnscreenKeyboardLexiconEntry>>>
  _swipeEdgeIndex = {};
  final Map<String, _CompactLexiconTrie> _correctionTries = {};
  final Map<String, Map<String, double>> _staticBigrams = {};
  final Map<String, Map<String, double>> _staticTrigrams = {};
  final Map<String, Map<String, Map<String, double>>> _staticNextWords = {};
  final OnscreenKeyboardLearningStore? learningStore;
  final int maximumLearnedWords;
  final int maximumLearnedBigrams;
  final int maximumLearnedTrigrams;
  final int maximumBlockedWords;
  final int maximumCorrectionOutcomes;
  final double minimumAutocorrectWeight;
  final Map<String, OnscreenKeyboardLearningSnapshot> _learning = {};
  final Map<String, Future<void>> _loading = {};

  static const _minimumGermanAccentAutocorrectWeight = 2.7;
  static const _minimumGermanAccentRankingWeight = 4.5;
  static const _maximumGermanAccentEvidenceCost = 1.25;

  Future<void> _ensureLoaded(Locale locale) async {
    final language = locale.languageCode.toLowerCase();
    await _loading.putIfAbsent(language, () async {
      _learning[language] =
          await learningStore?.load(locale) ??
          const OnscreenKeyboardLearningSnapshot();
    });
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
    final correctionCosts = <String, double>{};
    final trie = _correctionTries[language];
    var source = trie == null
        ? entries.take(256)
        : trie
              .entriesForPrefix('', entries, limit: 256)
              .map((entryIndex) => entries[entryIndex]);
    if (prefix.isNotEmpty) {
      source = trie == null
          ? const <OnscreenKeyboardLexiconEntry>[]
          : trie
                .entriesForPrefix(prefix, entries)
                .map((entryIndex) => entries[entryIndex]);
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
      final staticNext = _staticNextWords[language];
      if (previous != null && previousPrevious != null) {
        contextualKeys.addAll(
          staticNext?['$previousPrevious\u0000$previous']?.keys ?? const [],
        );
      }
      if (previous != null) {
        contextualKeys.addAll(staticNext?[previous]?.keys ?? const []);
      }
      for (final word in contextualKeys) {
        final entryIndex = _correctionTries[language]?.entryForWord(word) ?? -1;
        if (entryIndex >= 0) sourceByWord[word] = entries[entryIndex];
      }
    }
    final centers = {
      ..._defaultKeyCenters(language),
      ...request.keyCenters,
    };
    if (language == 'de') {
      centers
        ..['ä'] = centers['a']!
        ..['ö'] = centers['o']!
        ..['ü'] = centers['u']!
        ..['ß'] = centers['s']!;
    }
    if (prefix.isNotEmpty) {
      for (final match in _correctionCandidates(
        language,
        prefix,
        request.tapSamples,
        centers,
      )) {
        final entry = entries[match.entryIndex];
        final word = entry.word.toLowerCase();
        sourceByWord[word] = entry;
        correctionCosts[word] = match.cost;
      }
    }
    for (final entry in source.take(4096)) {
      sourceByWord.putIfAbsent(entry.word.toLowerCase(), () => entry);
    }
    for (final entry in sourceByWord.values) {
      request.cancellationToken.throwIfCancelled();
      final word = entry.word.toLowerCase();
      if (learned.blockedWords.contains(word)) continue;
      final editCost =
          correctionCosts[word] ??
          _weightedWordDistance(prefix, word, const [], const {});
      final begins = word.startsWith(prefix);
      if (prefix.isNotEmpty &&
          !begins &&
          editCost > _maximumCorrectionCost(prefix)) {
        continue;
      }
      final learnedBoost = math.log(1 + (learned.words[word] ?? 0)) * 0.35;
      final contextBoost = _contextBoost(
        language,
        learned,
        word,
        request.previousWord,
        request.previousPreviousWord,
      );
      final similarity = prefix.isEmpty
          ? 0.0
          : 1 - editCost / math.max(prefix.length, word.length);
      final firstAgreement =
          prefix.isNotEmpty &&
              word.isNotEmpty &&
              prefix.characters.first == word.characters.first
          ? .55
          : -.45;
      final lastAgreement =
          prefix.isNotEmpty &&
              word.isNotEmpty &&
              prefix.characters.last == word.characters.last
          ? .4
          : -.3;
      final lengthPenalty = (prefix.length - word.length).abs() * .48;
      final rejection = learned.correctionOutcomes['$prefix\u0000$word'] ?? 0;
      final correctionPenalty = rejection < 0 ? -math.log(1 - rejection) : 0;
      final correctionAcceptance = rejection > 0 ? math.log(1 + rejection) : 0;
      final germanAccentEvidence = language == 'de'
          ? _germanAccentEvidenceCost(
              prefix,
              word,
              request.tapSamples,
              centers,
            )
          : null;
      final germanAccentBoost =
          germanAccentEvidence == 0 &&
              entry.weight >= _minimumGermanAccentRankingWeight
          ? 3.2
          : germanAccentEvidence != null &&
                entry.weight >= _minimumGermanAccentAutocorrectWeight
          ? .3
          : 0.0;
      final errorPatternBoost =
          _deterministicErrorPatternBoost(prefix, word) + germanAccentBoost;
      final germanAccentAutocorrectEligible =
          germanAccentEvidence != null &&
          entry.weight >= _minimumGermanAccentAutocorrectWeight;
      final confidenceWeight = germanAccentAutocorrectEligible
          ? math.max(entry.weight, minimumAutocorrectWeight)
          : entry.weight;
      final score = begins || prefix.isEmpty
          ? entry.weight +
                (begins ? 1.2 : 0) +
                similarity +
                learnedBoost +
                contextBoost -
                correctionPenalty +
                correctionAcceptance * .28
          : entry.weight * .42 +
                2.5 +
                similarity * 1.4 -
                editCost * 2.45 -
                lengthPenalty +
                firstAgreement +
                lastAgreement +
                errorPatternBoost +
                learnedBoost +
                contextBoost * 1.35 -
                correctionPenalty +
                correctionAcceptance * .28;
      final correctionConfidence = begins
          ? (0.72 + similarity * .2).clamp(0, 1).toDouble()
          : (confidenceWeight < minimumAutocorrectWeight
                    ? .9
                    : (0.986 +
                          (confidenceWeight - minimumAutocorrectWeight).clamp(
                                0,
                                3,
                              ) *
                              .0025 -
                          editCost * .0025 +
                          (firstAgreement > 0 ? .001 : 0) +
                          (lastAgreement > 0 ? .001 : 0) +
                          (errorPatternBoost > 0 ? .002 : 0) -
                          correctionPenalty * .02 +
                          (germanAccentEvidence != null ? .0045 : 0) +
                          correctionAcceptance * .002 +
                          contextBoost.clamp(0, 1) * .003))
                .clamp(0, .999)
                .toDouble();
      candidates.add(
        OnscreenKeyboardSuggestion(
          word: entry.word,
          score: score,
          confidence: correctionConfidence,
          kind: prefix.isEmpty
              ? OnscreenKeyboardSuggestionKind.nextWord
              : begins
              ? OnscreenKeyboardSuggestionKind.completion
              : entry.weight >= minimumAutocorrectWeight ||
                    germanAccentAutocorrectEligible
              ? OnscreenKeyboardSuggestionKind.correction
              : OnscreenKeyboardSuggestionKind.completion,
        ),
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    if (prefix.isNotEmpty) {
      final exactMatch = _isKnownWord(language, prefix);
      candidates
        ..removeWhere((candidate) => candidate.word.toLowerCase() == prefix)
        ..insert(
          0,
          OnscreenKeyboardSuggestion(
            word: request.prefix,
            score: candidates.isEmpty ? 0 : candidates.first.score + .01,
            confidence: 1,
            kind: OnscreenKeyboardSuggestionKind.typed,
            exactMatch: exactMatch,
          ),
        );
    }
    return candidates.take(request.limit).toList(growable: false);
  }

  bool _isKnownWord(String language, String word) {
    final trie = _correctionTries[language];
    if (trie == null) return false;
    final normalized = word.toLowerCase();
    if (trie.entryForWord(normalized) >= 0) return true;
    if (language != 'de' || normalized.length < 6) return false;
    final partCounts = List<int>.filled(normalized.length + 1, -1)..[0] = 0;
    for (var end = 3; end <= normalized.length; end++) {
      for (var start = 0; start <= end - 3; start++) {
        if (partCounts[start] < 0) continue;
        // Short leading words and particles create many convincing-looking
        // misspellings (for example, `vor` + `raus`). Known short compounds
        // remain exact lexicon matches; only the productive-compound fallback
        // is deliberately conservative.
        if (start == 0 && end < 4) continue;
        var component = normalized.substring(start, end);
        if (component.length > 3 && component.startsWith('s')) {
          component = component.substring(1);
        }
        if (trie.entryForWord(component) >= 0) {
          partCounts[end] = math.max(partCounts[end], partCounts[start] + 1);
        }
      }
    }
    return partCounts.last >= 2;
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
        language,
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

  double _contextBoost(
    String language,
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
    final staticBigram = previous == null
        ? 0.0
        : _staticBigrams[language]?['$previous\u0000$word'] ?? 0.0;
    final staticTrigram = previous == null || previousPrevious == null
        ? 0.0
        : _staticTrigrams[language]?['$previousPrevious\u0000'
                  '$previous\u0000$word'] ??
              0.0;
    return math.log(1 + bigram) * .55 +
        math.log(1 + trigram) * .8 +
        staticBigram * .42 +
        staticTrigram * .62;
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

  Iterable<_CorrectionMatch> _correctionCandidates(
    String language,
    String typed,
    List<OnscreenKeyboardTapSample> tapSamples,
    Map<String, Offset> keyCenters,
  ) {
    final trie = _correctionTries[language];
    if (trie == null || typed.isEmpty) return const [];
    final query = typed.toLowerCase().runes.toList(growable: false);
    final maximumCost = _maximumCorrectionCost(typed);
    final initial = List<double>.generate(
      query.length + 1,
      (index) => index.toDouble(),
    );
    final matches = <_CorrectionMatch>[];

    void visit(
      int node,
      int candidateRune,
      List<double> previous,
      List<double>? previousPrevious,
      int? previousCandidateRune,
    ) {
      final current = List<double>.filled(query.length + 1, 0)
        ..[0] = previous[0] + 1;
      var rowMinimum = current[0];
      for (var column = 1; column <= query.length; column++) {
        final queryRune = query[column - 1];
        final deletionCost = column > 1 && queryRune == query[column - 2]
            ? .55
            : 1.0;
        final insertionCost = previousCandidateRune == candidateRune
            ? .55
            : 1.0;
        final substitutionCost = _substitutionCost(
          queryRune,
          candidateRune,
          column - 1,
          tapSamples,
          keyCenters,
        );
        var cost = math.min(
          current[column - 1] + deletionCost,
          math.min(
            previous[column] + insertionCost,
            previous[column - 1] + substitutionCost,
          ),
        );
        if (previousPrevious != null &&
            previousCandidateRune != null &&
            column > 1 &&
            candidateRune == query[column - 2] &&
            previousCandidateRune == queryRune) {
          cost = math.min(cost, previousPrevious[column - 2] + .45);
        }
        current[column] = cost;
        rowMinimum = math.min(rowMinimum, cost);
      }
      final terminal = trie.terminalEntries[node];
      if (terminal >= 0 && current.last <= maximumCost) {
        matches.add(_CorrectionMatch(terminal, current.last));
      }
      if (rowMinimum > maximumCost) return;
      for (
        var edge = trie.firstEdge[node];
        edge < trie.firstEdge[node + 1];
        edge++
      ) {
        visit(
          trie.edgeTargets[edge],
          trie.edgeCharacters[edge],
          current,
          previous,
          candidateRune,
        );
      }
    }

    for (var edge = trie.firstEdge[0]; edge < trie.firstEdge[1]; edge++) {
      visit(
        trie.edgeTargets[edge],
        trie.edgeCharacters[edge],
        initial,
        null,
        null,
      );
    }
    matches.sort((a, b) {
      final byCost = a.cost.compareTo(b.cost);
      if (byCost != 0) return byCost;
      return b.entryIndex.compareTo(a.entryIndex);
    });
    return matches.take(256);
  }

  static double _maximumCorrectionCost(String typed) => switch (typed.length) {
    <= 3 => 1.05,
    <= 7 => 1.55,
    _ => 2.05,
  };

  /// Rewards deterministic physical-key error shapes before word frequency.
  ///
  /// A missing character is substantially more likely than an unrelated rare
  /// word that happens to be one edit away. Repeated keys and adjacent
  /// transpositions are similarly strong, but less ambiguous, signals. These
  /// bonuses are deliberately structural: they do not depend on user data and
  /// cannot make an exact dictionary word eligible for replacement.
  static double _deterministicErrorPatternBoost(
    String typed,
    String candidate,
  ) {
    final source = typed.characters.toList(growable: false);
    final target = candidate.characters.toList(growable: false);
    if (_isSingleInsertion(source, target)) return 3.8;
    if (_isRepeatedCharacterRemoval(source, target)) return 1.2;
    if (_isAdjacentTransposition(source, target)) return .8;
    return 0;
  }

  /// Returns bounded evidence that a German candidate was typed without the
  /// dedicated umlaut/eszett characters available through long press.
  ///
  /// A direct ASCII transliteration is strongest. One additional ordinary
  /// key error is allowed so common forms such as `entgultig` and `heufig`
  /// remain correctable, but frequency still controls automatic eligibility.
  static double? _germanAccentEvidenceCost(
    String typed,
    String candidate,
    List<OnscreenKeyboardTapSample> tapSamples,
    Map<String, Offset> keyCenters,
  ) {
    final asciiCandidate = candidate
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss');
    if (asciiCandidate == candidate) return null;
    final cost = _weightedWordDistance(
      typed,
      asciiCandidate,
      tapSamples,
      keyCenters,
    );
    return cost <= _maximumGermanAccentEvidenceCost ? cost : null;
  }

  static bool _isSingleInsertion(List<String> source, List<String> target) {
    if (target.length != source.length + 1) return false;
    var sourceIndex = 0;
    var skipped = false;
    for (final character in target) {
      if (sourceIndex < source.length && character == source[sourceIndex]) {
        sourceIndex++;
      } else if (!skipped) {
        skipped = true;
      } else {
        return false;
      }
    }
    return sourceIndex == source.length;
  }

  static bool _isRepeatedCharacterRemoval(
    List<String> source,
    List<String> target,
  ) {
    if (source.length != target.length + 1) return false;
    for (var index = 1; index < source.length; index++) {
      if (source[index] != source[index - 1]) continue;
      final withoutRepeat = [...source]..removeAt(index);
      if (_sameCharacters(withoutRepeat, target)) return true;
    }
    return false;
  }

  static bool _isAdjacentTransposition(
    List<String> source,
    List<String> target,
  ) {
    if (source.length != target.length) return false;
    final differences = <int>[];
    for (var index = 0; index < source.length; index++) {
      if (source[index] != target[index]) differences.add(index);
      if (differences.length > 2) return false;
    }
    return differences.length == 2 &&
        differences[1] == differences[0] + 1 &&
        source[differences[0]] == target[differences[1]] &&
        source[differences[1]] == target[differences[0]];
  }

  static bool _sameCharacters(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static double _weightedWordDistance(
    String typed,
    String candidate,
    List<OnscreenKeyboardTapSample> tapSamples,
    Map<String, Offset> keyCenters,
  ) {
    final source = typed.toLowerCase().runes.toList(growable: false);
    final target = candidate.toLowerCase().runes.toList(growable: false);
    var previousPrevious = <double>[];
    var previous = List<double>.generate(
      source.length + 1,
      (index) => index.toDouble(),
    );
    for (var row = 1; row <= target.length; row++) {
      final current = List<double>.filled(source.length + 1, 0)
        ..[0] = row.toDouble();
      for (var column = 1; column <= source.length; column++) {
        final sourceRune = source[column - 1];
        final targetRune = target[row - 1];
        var cost = math.min(
          current[column - 1] +
              (column > 1 && sourceRune == source[column - 2] ? .55 : 1),
          math.min(
            previous[column] +
                (row > 1 && targetRune == target[row - 2] ? .55 : 1),
            previous[column - 1] +
                _substitutionCost(
                  sourceRune,
                  targetRune,
                  column - 1,
                  tapSamples,
                  keyCenters,
                ),
          ),
        );
        if (row > 1 &&
            column > 1 &&
            targetRune == source[column - 2] &&
            target[row - 2] == sourceRune) {
          cost = math.min(cost, previousPrevious[column - 2] + .45);
        }
        current[column] = cost;
      }
      previousPrevious = previous;
      previous = current;
    }
    return previous.last;
  }

  static double _substitutionCost(
    int typedRune,
    int candidateRune,
    int typedIndex,
    List<OnscreenKeyboardTapSample> tapSamples,
    Map<String, Offset> keyCenters,
  ) {
    if (typedRune == candidateRune) return 0;
    final typed = String.fromCharCode(typedRune);
    final candidate = String.fromCharCode(candidateRune);
    if (_foldAccent(typed) == _foldAccent(candidate)) return .28;
    final candidateCenter = keyCenters[candidate];
    if (typedIndex < tapSamples.length && candidateCenter != null) {
      return (.22 +
              (tapSamples[typedIndex].position - candidateCenter).distance *
                  3.3)
          .clamp(.22, 1.25);
    }
    final typedCenter = keyCenters[typed];
    if (typedCenter != null && candidateCenter != null) {
      return (.32 + (typedCenter - candidateCenter).distance * 2.4).clamp(
        .32,
        1.25,
      );
    }
    return 1;
  }

  static String _foldAccent(String value) => switch (value) {
    'ä' || 'á' || 'à' || 'â' || 'ã' || 'å' => 'a',
    'ë' || 'é' || 'è' || 'ê' => 'e',
    'ï' || 'í' || 'ì' || 'î' => 'i',
    'ö' || 'ó' || 'ò' || 'ô' || 'õ' => 'o',
    'ü' || 'ú' || 'ù' || 'û' => 'u',
    'ß' => 's',
    _ => value,
  };

  static Map<String, Offset> _defaultKeyCenters(String language) {
    final top = language == 'de' ? 'qwertzuiop' : 'qwertyuiop';
    const middle = 'asdfghjkl';
    final bottom = language == 'de' ? 'yxcvbnm' : 'zxcvbnm';
    final result = <String, Offset>{};
    void addRow(String row, double y, double inset) {
      for (var index = 0; index < row.length; index++) {
        result[row[index]] = Offset(inset + (index + .5) * .09, y);
      }
    }

    addRow(top, .2, .05);
    addRow(middle, .5, .095);
    addRow(bottom, .8, .14);
    result
      ..['ä'] = result['a']!
      ..['ö'] = result['o']!
      ..['ü'] = result['u']!
      ..['ß'] = result['s']!;
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
      correctionOutcomes: current.correctionOutcomes,
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
        correctionOutcomes: current.correctionOutcomes,
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
        correctionOutcomes: current.correctionOutcomes,
      ),
    );
  }

  @override
  Future<void> recordCorrectionOutcome({
    required Locale locale,
    required String original,
    required String replacement,
    required bool accepted,
  }) async {
    await _ensureLoaded(locale);
    final language = locale.languageCode.toLowerCase();
    final current = _learning[language]!;
    final normalizedOriginal = original.toLowerCase();
    final normalizedReplacement = replacement.toLowerCase();
    if (normalizedOriginal.isEmpty ||
        normalizedReplacement.isEmpty ||
        normalizedOriginal == normalizedReplacement) {
      return;
    }
    final outcomes = Map<String, int>.of(current.correctionOutcomes);
    final key = '$normalizedOriginal\u0000$normalizedReplacement';
    outcomes[key] = ((outcomes[key] ?? 0) + (accepted ? 1 : -1)).clamp(
      -8,
      8,
    );
    _trimOutcomes(outcomes, maximumCorrectionOutcomes);
    await _save(
      locale,
      OnscreenKeyboardLearningSnapshot(
        words: current.words,
        bigrams: current.bigrams,
        trigrams: current.trigrams,
        touchOffsets: current.touchOffsets,
        touchOffsetCounts: current.touchOffsetCounts,
        blockedWords: current.blockedWords,
        correctionOutcomes: outcomes,
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

  static void _trimOutcomes(Map<String, int> values, int limit) {
    if (values.length <= limit) return;
    final keys = values.keys.toList()
      ..sort((a, b) {
        final byMagnitude = values[b]!.abs().compareTo(values[a]!.abs());
        return byMagnitude != 0 ? byMagnitude : a.compareTo(b);
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

  static double _geometrySimilarity(List<Offset> trace, List<Offset> template) {
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
}

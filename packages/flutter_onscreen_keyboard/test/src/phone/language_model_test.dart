import 'package:flutter/widgets.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entries = <OnscreenKeyboardLexiconEntry>[
    OnscreenKeyboardLexiconEntry('hello', 10),
    OnscreenKeyboardLexiconEntry('help', 8),
    OnscreenKeyboardLexiconEntry('hero', 6),
    OnscreenKeyboardLexiconEntry('world', 9),
  ];

  test('ranks prefix and correction candidates deterministically', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
    );
    final result = await model.suggestions(
      OnscreenKeyboardSuggestionRequest(
        locale: const Locale('en'),
        prefix: 'helo',
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );

    expect(result.first.word, 'helo');
    expect(result.first.kind, OnscreenKeyboardSuggestionKind.typed);
    expect(result[1].word, 'hello');
    expect(result[1].confidence, greaterThan(.8));
  });

  test('decodes a geometric trace that crosses incidental keys', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
    );
    final result = await model.decodeSwipe(
      OnscreenKeyboardSwipeRequest(
        locale: const Locale('en'),
        trace: const [
          'h',
          'y',
          't',
          'r',
          'e',
          'r',
          't',
          'y',
          'u',
          'i',
          'o',
          'k',
          'l',
          'k',
          'o',
        ],
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );

    expect(result.first.word, 'hello');
  });

  test('keyboard geometry separates words with similar crossed keys', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {
        'en': [
          OnscreenKeyboardLexiconEntry('hello', 7),
          OnscreenKeyboardLexiconEntry('hero', 7.4),
        ],
      },
    );
    const centers = <String, Offset>{
      'e': Offset(.25, .1),
      'r': Offset(.35, .1),
      'o': Offset(.85, .1),
      'h': Offset(.55, .5),
      'l': Offset(.85, .5),
    };
    final result = await model.decodeSwipe(
      OnscreenKeyboardSwipeRequest(
        locale: const Locale('en'),
        trace: const ['h', 'e', 'r', 'l', 'o'],
        points: const [
          Offset(.55, .5),
          Offset(.25, .1),
          Offset(.85, .5),
          Offset(.85, .1),
        ],
        keyCenters: centers,
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );

    expect(result.first.word, 'hello');
  });

  test('honors cancellation before expensive model work', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
    );
    final token = OnscreenKeyboardCancellationToken()..cancel();

    expect(
      () => model.suggestions(
        OnscreenKeyboardSuggestionRequest(
          locale: const Locale('en'),
          prefix: 'he',
          cancellationToken: token,
        ),
      ),
      throwsA(isA<OnscreenKeyboardRequestCancelled>()),
    );
  });

  test('bounds persisted learned words and bigrams', () async {
    final store = _MemoryLearningStore();
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
      learningStore: store,
      maximumLearnedWords: 2,
      maximumLearnedBigrams: 2,
    );
    for (final word in ['one', 'two', 'three']) {
      await model.learnAcceptedWord(
        locale: const Locale('en'),
        word: word,
        previousWord: 'before-$word',
      );
    }

    expect(store.snapshot.words, hasLength(2));
    expect(store.snapshot.bigrams, hasLength(2));
  });

  test('learned trigram context changes next-word ranking', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {
        'en': [
          OnscreenKeyboardLexiconEntry('now', 7),
          OnscreenKeyboardLexiconEntry('please', 7.1),
        ],
      },
    );
    for (var index = 0; index < 4; index++) {
      await model.learnAcceptedContext(
        locale: const Locale('en'),
        word: 'now',
        previousWord: 'it',
        previousPreviousWord: 'do',
      );
    }

    final result = await model.suggestions(
      OnscreenKeyboardSuggestionRequest(
        locale: const Locale('en'),
        prefix: '',
        previousWord: 'it',
        previousPreviousWord: 'do',
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );

    expect(result.first.word, 'now');
    expect(result.first.kind, OnscreenKeyboardSuggestionKind.nextWord);
  });

  test('forgotten candidates remain suppressed until accepted again', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
    );
    await model.forgetWord(locale: const Locale('en'), word: 'hello');

    var result = await model.suggestions(
      OnscreenKeyboardSuggestionRequest(
        locale: const Locale('en'),
        prefix: 'hel',
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );
    expect(result.map((candidate) => candidate.word), isNot(contains('hello')));

    await model.learnAcceptedWord(locale: const Locale('en'), word: 'hello');
    result = await model.suggestions(
      OnscreenKeyboardSuggestionRequest(
        locale: const Locale('en'),
        prefix: 'hel',
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );
    expect(result.map((candidate) => candidate.word), contains('hello'));
  });

  test('swipe reports diagnostics and learns bounded touch offsets', () async {
    final store = _MemoryLearningStore();
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
      learningStore: store,
    );
    OnscreenKeyboardSwipeDiagnostic? diagnostic;
    const centers = {
      'h': Offset(.2, .5),
      'e': Offset(.3, .2),
      'l': Offset(.7, .5),
      'o': Offset(.8, .2),
    };
    const points = [
      Offset(.22, .51),
      Offset(.32, .21),
      Offset(.72, .51),
      Offset(.82, .21),
    ];
    await model.decodeSwipe(
      OnscreenKeyboardSwipeRequest(
        locale: const Locale('en'),
        trace: const ['h', 'e', 'l', 'o'],
        points: points,
        keyCenters: centers,
        onDiagnostic: (value) => diagnostic = value,
        cancellationToken: OnscreenKeyboardCancellationToken(),
      ),
    );
    await model.learnSwipeGesture(
      locale: const Locale('en'),
      word: 'hello',
      gesture: const OnscreenKeyboardSwipeData(
        trace: ['h', 'e', 'l', 'o'],
        points: points,
        keyCenters: centers,
      ),
    );

    expect(diagnostic, isNotNull);
    expect(diagnostic!.candidates.first.geometry, greaterThan(0));
    expect(store.snapshot.touchOffsets, contains('h'));
    expect(store.snapshot.touchOffsets['h']!.distance, lessThanOrEqualTo(.07));
  });
}

class _MemoryLearningStore implements OnscreenKeyboardLearningStore {
  OnscreenKeyboardLearningSnapshot snapshot =
      const OnscreenKeyboardLearningSnapshot();

  @override
  Future<void> clear(Locale locale) async {
    snapshot = const OnscreenKeyboardLearningSnapshot();
  }

  @override
  Future<OnscreenKeyboardLearningSnapshot> load(Locale locale) async =>
      snapshot;

  @override
  Future<void> save(
    Locale locale,
    OnscreenKeyboardLearningSnapshot snapshot,
  ) async {
    this.snapshot = snapshot;
  }
}

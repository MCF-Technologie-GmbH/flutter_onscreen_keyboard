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

    expect(result.first.word, 'hello');
    expect(result.first.confidence, greaterThan(.8));
  });

  test('decodes a collapsed swipe trace with first/last agreement', () async {
    final model = WeightedLexiconLanguageModel(
      lexicons: const {'en': entries},
    );
    final result = await model.decodeSwipe(
      OnscreenKeyboardSwipeRequest(
        locale: const Locale('en'),
        trace: const ['h', 'e', 'l', 'l', 'o'],
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

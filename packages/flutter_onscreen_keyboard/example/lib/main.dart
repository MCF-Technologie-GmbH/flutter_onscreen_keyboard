import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

const _dictionaryRoot = String.fromEnvironment('KEYBOARD_DICTIONARY_ROOT');

void main() => runApp(const KeyboardPlayground());

class KeyboardPlayground extends StatefulWidget {
  const KeyboardPlayground({super.key});

  @override
  State<KeyboardPlayground> createState() => _KeyboardPlaygroundState();
}

class _KeyboardPlaygroundState extends State<KeyboardPlayground> {
  Locale _locale = const Locale('en');
  OnscreenKeyboardTypingMode _typingMode =
      OnscreenKeyboardTypingMode.suggestions;
  OnscreenKeyboardSwipeDiagnostic? _lastSwipeDiagnostic;

  late final OnscreenKeyboardLanguageModel _languageModel =
      _dictionaryRoot.isNotEmpty
      ? _FileLanguageModel(_dictionaryRoot)
      : WeightedLexiconLanguageModel(
          lexicons: {
            'en': _entries(
              'hello help helpful home house how keyboard kind language local '
              'mobile morning offline phone suggestion swipe test text there '
              'their this typing welcome world would',
            ),
            'de': _entries(
              'aber bitte danke deutsch diese guten hallo heute hier keyboard '
              'lernen lokal morgen offline schreiben schön swipe tastatur '
              'testen '
              'text tippen vorschlag willkommen würde',
            ),
          },
        );

  static Iterable<OnscreenKeyboardLexiconEntry> _entries(String words) sync* {
    final values = words.split(' ');
    for (var index = 0; index < values.length; index++) {
      yield OnscreenKeyboardLexiconEntry(
        values[index],
        (values.length - index) / values.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phone Keyboard Playground',
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6750a4)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      builder: (context, child) => OnscreenKeyboard(
        presentation: OnscreenKeyboardPresentation.docked,
        typingMode: _typingMode,
        locale: _locale,
        languageModel: _languageModel,
        onSwipeDiagnostic: (diagnostic) =>
            setState(() => _lastSwipeDiagnostic = diagnostic),
        child: child!,
      ),
      home: PlaygroundScreen(
        locale: _locale,
        typingMode: _typingMode,
        swipeDiagnostic: _lastSwipeDiagnostic,
        onLocaleChanged: (locale) => setState(() => _locale = locale),
        onTypingModeChanged: (mode) => setState(() => _typingMode = mode),
      ),
    );
  }
}

class PlaygroundScreen extends StatelessWidget {
  const PlaygroundScreen({
    required this.locale,
    required this.typingMode,
    required this.swipeDiagnostic,
    required this.onLocaleChanged,
    required this.onTypingModeChanged,
    super.key,
  });

  final Locale locale;
  final OnscreenKeyboardTypingMode typingMode;
  final OnscreenKeyboardSwipeDiagnostic? swipeDiagnostic;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<OnscreenKeyboardTypingMode> onTypingModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Keyboard Playground'),
        actions: [
          IconButton(
            tooltip: 'Hide keyboard',
            onPressed: OnscreenKeyboard.of(context).hide,
            icon: const Icon(Icons.keyboard_hide_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Tap a field, type or swipe across letters, hold a key for an '
            'alternate, and hold backspace to repeat.',
          ),
          const SizedBox(height: 8),
          Text(
            _dictionaryRoot.isEmpty
                ? 'Demo vocabulary active'
                : 'Full offline vocabulary active · 300,000 English · '
                      '200,000 German',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const OnscreenKeyboardTextField(
            autofocus: true,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Typing and Return',
              hintText: 'Try “hello” or “hallo”',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SegmentedButton<Locale>(
                segments: const [
                  ButtonSegment(value: Locale('en'), label: Text('English')),
                  ButtonSegment(value: Locale('de'), label: Text('Deutsch')),
                ],
                selected: {locale},
                onSelectionChanged: (values) => onLocaleChanged(values.single),
              ),
              SegmentedButton<OnscreenKeyboardTypingMode>(
                segments: const [
                  ButtonSegment(
                    value: OnscreenKeyboardTypingMode.off,
                    label: Text('Off'),
                  ),
                  ButtonSegment(
                    value: OnscreenKeyboardTypingMode.suggestions,
                    label: Text('Suggestions'),
                  ),
                  ButtonSegment(
                    value: OnscreenKeyboardTypingMode.autocorrect,
                    label: Text('Autocorrect'),
                  ),
                ],
                selected: {typingMode},
                onSelectionChanged: (values) =>
                    onTypingModeChanged(values.single),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SwipeDiagnosticsCard(diagnostic: swipeDiagnostic),
          const SizedBox(height: 20),
          const OnscreenKeyboardTextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: 'Email layout'),
          ),
          const SizedBox(height: 16),
          const OnscreenKeyboardTextField(
            keyboardType: TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: 'Signed decimal layout'),
          ),
          const SizedBox(height: 16),
          const OnscreenKeyboardTextField(
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: 'Ordinary single-line'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SwipeDiagnosticsCard extends StatefulWidget {
  const _SwipeDiagnosticsCard({required this.diagnostic});

  final OnscreenKeyboardSwipeDiagnostic? diagnostic;

  @override
  State<_SwipeDiagnosticsCard> createState() => _SwipeDiagnosticsCardState();
}

class _SwipeDiagnosticsCardState extends State<_SwipeDiagnosticsCard> {
  final _expectedController = TextEditingController();
  String? _savedPath;

  @override
  void dispose() {
    _expectedController.dispose();
    super.dispose();
  }

  Future<void> _saveSample() async {
    final diagnostic = widget.diagnostic;
    final expected = _expectedController.text.trim();
    if (diagnostic == null || expected.isEmpty) return;
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'phone_keyboard_swipe_corpus.jsonl',
    );
    await file.writeAsString(
      '${jsonEncode({
        'locale': diagnostic.locale.toLanguageTag(),
        'expected': expected,
        'trace': diagnostic.trace,
        'points': [
          for (final point in diagnostic.points) [point.dx, point.dy],
        ],
        'candidates': [
          for (final candidate in diagnostic.candidates) {
              'word': candidate.word,
              'score': candidate.score,
              'confidence': candidate.confidence,
              'geometry': candidate.geometry,
              'orderedTrace': candidate.orderedTrace,
              'context': candidate.context,
              'learning': candidate.learning,
            },
        ],
      })}\n',
      mode: FileMode.append,
      flush: true,
    );
    if (mounted) setState(() => _savedPath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    final diagnostic = widget.diagnostic;
    final candidates = diagnostic?.candidates
        .take(3)
        .map(
          (candidate) =>
              '${candidate.word} ${candidate.confidence.toStringAsFixed(2)}',
        )
        .join('  |  ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swipe accuracy lab',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              diagnostic == null
                  ? 'Swipe a word to inspect decoder scores.'
                  : '${diagnostic.elapsed.inMicroseconds / 1000} ms · '
                        '$candidates',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expectedController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Intended word',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: diagnostic == null ? null : _saveSample,
                  child: const Text('Save sample'),
                ),
              ],
            ),
            if (_savedPath != null) ...[
              const SizedBox(height: 6),
              Text('Saved locally: $_savedPath'),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileLanguageModel implements OnscreenKeyboardLanguageModel {
  _FileLanguageModel(this.root);

  final String root;
  final Map<String, Future<WeightedLexiconLanguageModel>> _models = {};

  Future<WeightedLexiconLanguageModel> _model(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    return _models.putIfAbsent(language, () async {
      final source = await File(
        '$root${Platform.pathSeparator}$language.tsv',
      ).readAsString();
      return WeightedLexiconLanguageModel(
        lexicons: {language: _parseLexicon(source)},
      );
    });
  }

  @override
  Future<List<OnscreenKeyboardSuggestion>> suggestions(
    OnscreenKeyboardSuggestionRequest request,
  ) async {
    request.cancellationToken.throwIfCancelled();
    final model = await _model(request.locale);
    request.cancellationToken.throwIfCancelled();
    return model.suggestions(request);
  }

  @override
  Future<List<OnscreenKeyboardSuggestion>> decodeSwipe(
    OnscreenKeyboardSwipeRequest request,
  ) async {
    request.cancellationToken.throwIfCancelled();
    final model = await _model(request.locale);
    request.cancellationToken.throwIfCancelled();
    return model.decodeSwipe(request);
  }

  @override
  Future<void> learnAcceptedWord({
    required Locale locale,
    required String word,
    String? previousWord,
  }) async {
    await (await _model(locale)).learnAcceptedWord(
      locale: locale,
      word: word,
      previousWord: previousWord,
    );
  }
}

List<OnscreenKeyboardLexiconEntry> _parseLexicon(String source) {
  final result = <OnscreenKeyboardLexiconEntry>[];
  for (final line in const LineSplitter().convert(source)) {
    final separator = line.lastIndexOf('\t');
    if (separator <= 0) continue;
    final count = int.tryParse(line.substring(separator + 1));
    if (count == null || count <= 0) continue;
    result.add(
      OnscreenKeyboardLexiconEntry(
        line.substring(0, separator),
        math.log(count) / math.ln10,
      ),
    );
  }
  return result;
}

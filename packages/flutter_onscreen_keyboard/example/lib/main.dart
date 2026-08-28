import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

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

  late final OnscreenKeyboardLanguageModel _languageModel =
      WeightedLexiconLanguageModel(
        lexicons: {
          'en': _entries(
            'hello help helpful home house how keyboard kind language local '
            'mobile morning offline phone suggestion swipe test text there '
            'their this typing welcome world would',
          ),
          'de': _entries(
            'aber bitte danke deutsch diese guten hallo heute hier keyboard '
            'lernen lokal morgen offline schreiben schön swipe tastatur testen '
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
        child: child!,
      ),
      home: PlaygroundScreen(
        locale: _locale,
        typingMode: _typingMode,
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
    required this.onLocaleChanged,
    required this.onTypingModeChanged,
    super.key,
  });

  final Locale locale;
  final OnscreenKeyboardTypingMode typingMode;
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 24),
          const OnscreenKeyboardTextField(
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Ordinary text',
              hintText: 'Try “hello” or “hallo”',
            ),
          ),
          const SizedBox(height: 16),
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
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Multiline notes'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

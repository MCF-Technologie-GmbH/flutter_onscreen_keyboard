// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/src/constants/action_key_type.dart';
import 'package:flutter_onscreen_keyboard/src/models/keys.dart';
import 'package:flutter_onscreen_keyboard/src/models/layout.dart';
import 'package:flutter_onscreen_keyboard/src/phone/typing.dart';
import 'package:flutter_onscreen_keyboard/src/utils/extensions.dart';

/// A compact, field-aware English/German phone keyboard.
class PhoneKeyboardLayout extends KeyboardLayout {
  const PhoneKeyboardLayout({
    this.locale = const Locale('en'),
    this.fieldConfiguration,
  });

  final Locale locale;
  final OnscreenKeyboardFieldConfiguration? fieldConfiguration;

  bool get _german => locale.languageCode.toLowerCase() == 'de';

  @override
  double get aspectRatio => 1.72;

  @override
  Map<String, KeyboardMode> get modes {
    final kind = fieldConfiguration?.inputKind;
    if (kind == OnscreenKeyboardInputKind.number ||
        kind == OnscreenKeyboardInputKind.signedDecimal) {
      return {
        'numbers': KeyboardMode(
          rows: _numberRows(
            signed: kind == OnscreenKeyboardInputKind.signedDecimal,
          ),
        ),
      };
    }
    if (kind == OnscreenKeyboardInputKind.phone) {
      return {'phone': KeyboardMode(rows: _phoneRows)};
    }
    return {
      'letters': KeyboardMode(rows: _letterRows),
      'symbols': KeyboardMode(rows: _symbolRows),
    };
  }

  List<KeyboardRow> get _letterRows {
    final first = _german ? 'qwertzuiop' : 'qwertyuiop';
    final third = _german ? 'yxcvbnm' : 'zxcvbnm';
    return [
      _row(first),
      KeyboardRow(
        leading: const Expanded(flex: 10, child: SizedBox.shrink()),
        keys: 'asdfghjkl'.split('').map(_letter).toList(),
        trailing: const Expanded(flex: 10, child: SizedBox.shrink()),
      ),
      KeyboardRow(
        keys: [
          const OnscreenKeyboardKey.action(
            name: ActionKeyType.shift,
            child: Icon(Icons.arrow_upward_rounded),
            flex: 28,
            canHold: true,
          ),
          ...third.split('').map(_letter),
          const OnscreenKeyboardKey.action(
            name: ActionKeyType.backspace,
            child: Icon(Icons.backspace_outlined),
            flex: 28,
            repeatable: true,
          ),
        ],
      ),
      KeyboardRow(
        keys: [
          OnscreenKeyboardKey.action(
            name: ActionKeyType.modeSwitch,
            label: '?123',
            onTap: (context) => context.controller.switchMode(),
            flex: 30,
          ),
          OnscreenKeyboardKey.action(
            name: ActionKeyType.language,
            label: _german ? 'DE' : 'EN',
            flex: 26,
          ),
          ..._contextKeys,
          OnscreenKeyboardKey.action(
            name: ActionKeyType.enter,
            child: Icon(_enterIcon(fieldConfiguration?.inputAction)),
            flex: 34,
          ),
        ],
      ),
    ];
  }

  List<OnscreenKeyboardKey> get _contextKeys =>
      switch (fieldConfiguration?.inputKind) {
        OnscreenKeyboardInputKind.email => const [
          OnscreenKeyboardKey.text(primary: '@', flex: 24),
          OnscreenKeyboardKey.text(
            primary: ' ',
            child: Icon(Icons.space_bar_rounded),
            flex: 72,
          ),
          OnscreenKeyboardKey.text(primary: '.'),
        ],
        OnscreenKeyboardInputKind.url => const [
          OnscreenKeyboardKey.text(primary: '/', flex: 22),
          OnscreenKeyboardKey.text(primary: ':', flex: 18),
          OnscreenKeyboardKey.text(primary: '.com', flex: 52),
        ],
        _ => const [
          OnscreenKeyboardKey.text(primary: ',', flex: 18),
          OnscreenKeyboardKey.text(
            primary: ' ',
            child: Icon(Icons.space_bar_rounded),
            flex: 92,
          ),
          OnscreenKeyboardKey.text(primary: '.', flex: 18),
        ],
      };

  List<KeyboardRow> get _symbolRows => [
    _row('1234567890'),
    _row(r'@#$%&-+()'),
    KeyboardRow(
      keys: [
        ...const ['*', '/', '"', "'", ':', ';', '!', '?'].map(_plain),
        const OnscreenKeyboardKey.action(
          name: ActionKeyType.backspace,
          child: Icon(Icons.backspace_outlined),
          flex: 28,
          repeatable: true,
        ),
      ],
    ),
    KeyboardRow(
      keys: [
        OnscreenKeyboardKey.action(
          name: ActionKeyType.modeSwitch,
          label: 'ABC',
          onTap: (context) => context.controller.switchMode(),
          flex: 34,
        ),
        const OnscreenKeyboardKey.text(primary: ',', flex: 18),
        const OnscreenKeyboardKey.text(
          primary: ' ',
          child: Icon(Icons.space_bar_rounded),
          flex: 100,
        ),
        const OnscreenKeyboardKey.text(primary: '.', flex: 18),
        OnscreenKeyboardKey.action(
          name: ActionKeyType.enter,
          child: Icon(_enterIcon(fieldConfiguration?.inputAction)),
          flex: 34,
        ),
      ],
    ),
  ];

  List<KeyboardRow> _numberRows({required bool signed}) => [
    _row('123'),
    _row('456'),
    _row('789'),
    KeyboardRow(
      keys: [
        if (signed) const OnscreenKeyboardKey.text(primary: '-'),
        const OnscreenKeyboardKey.text(primary: '0'),
        if (signed) const OnscreenKeyboardKey.text(primary: '.'),
        const OnscreenKeyboardKey.action(
          name: ActionKeyType.backspace,
          child: Icon(Icons.backspace_outlined),
          repeatable: true,
        ),
        OnscreenKeyboardKey.action(
          name: ActionKeyType.enter,
          child: Icon(_enterIcon(fieldConfiguration?.inputAction)),
        ),
      ],
    ),
  ];

  List<KeyboardRow> get _phoneRows => [
    _row('123'),
    _row('456'),
    _row('789'),
    const KeyboardRow(
      keys: [
        OnscreenKeyboardKey.text(primary: '+'),
        OnscreenKeyboardKey.text(primary: '0'),
        OnscreenKeyboardKey.text(primary: '#'),
        OnscreenKeyboardKey.action(
          name: ActionKeyType.backspace,
          child: Icon(Icons.backspace_outlined),
          repeatable: true,
        ),
        OnscreenKeyboardKey.action(
          name: ActionKeyType.enter,
          child: Icon(Icons.done_rounded),
        ),
      ],
    ),
  ];

  KeyboardRow _row(String keys) =>
      KeyboardRow(keys: keys.split('').map(_plain).toList());

  OnscreenKeyboardKey _plain(String key) =>
      OnscreenKeyboardKey.text(primary: key);

  OnscreenKeyboardKey _letter(String key) => OnscreenKeyboardKey.text(
    primary: key,
    alternates: _alternates[key] ?? const [],
  );

  Map<String, List<String>> get _alternates => {
    'a': const ['á', 'à', 'â', 'ä', 'ã', 'å', 'æ'],
    'c': const ['ç', 'č'],
    'e': const ['é', 'è', 'ê', 'ë'],
    'i': const ['í', 'ì', 'î', 'ï'],
    'n': const ['ñ'],
    'o': const ['ó', 'ò', 'ô', 'ö', 'õ', 'ø', 'œ'],
    's': const ['ß', 'š'],
    'u': const ['ú', 'ù', 'û', 'ü'],
    'y': const ['ý', 'ÿ'],
    'z': const ['ž'],
  };

  static IconData _enterIcon(TextInputAction? action) => switch (action) {
    TextInputAction.next => Icons.navigate_next_rounded,
    TextInputAction.go => Icons.arrow_forward_rounded,
    TextInputAction.search => Icons.search_rounded,
    TextInputAction.send => Icons.send_rounded,
    TextInputAction.newline => Icons.keyboard_return_rounded,
    _ => Icons.done_rounded,
  };
}

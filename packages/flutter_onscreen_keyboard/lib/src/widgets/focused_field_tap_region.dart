import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Makes a tap on the keyboard count as a tap inside every [TapRegion] group
/// that holds the focused field.
///
/// The keyboard is drawn apart from the application, so its keys lie outside
/// any pop-up the focused field sits in. A pop-up that closes on a tap outside
/// (a `MenuAnchor` menu, a dropdown list) would close at the first key, and
/// the letter would be lost with the field's focus. Wrapping the keyboard in a
/// [TapRegion] for each group around the focused field makes its keys part of
/// those groups, the same way [TextFieldTapRegion] keeps the field focused.
///
/// The groups follow the primary focus. A field that sits in no group with an
/// id (the usual case) adds nothing, so taps on the keyboard still close
/// pop-ups that do not hold the focused field.
class FocusedFieldTapRegion extends StatefulWidget {
  /// Creates a [FocusedFieldTapRegion] around [child].
  const FocusedFieldTapRegion({required this.child, super.key});

  /// The keyboard.
  final Widget child;

  /// The ids of the enabled [TapRegion] groups above [focus], nearest first,
  /// without [EditableText] (the keyboard is a [TextFieldTapRegion] already).
  @visibleForTesting
  static List<Object> groupsAround(FocusNode? focus) {
    final context = focus?.context;
    if (context == null || !context.mounted) return const [];
    final groups = <Object>[];
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is TapRegion && widget.enabled) {
        final id = widget.groupId;
        if (id != null && id != EditableText && !groups.contains(id)) {
          groups.add(id);
        }
      }
      return true;
    });
    return groups;
  }

  @override
  State<FocusedFieldTapRegion> createState() => _FocusedFieldTapRegionState();
}

class _FocusedFieldTapRegionState extends State<FocusedFieldTapRegion> {
  // Keeps the keyboard's state when the number of regions around it changes.
  final GlobalKey _childKey = GlobalKey();
  List<Object> _groups = const [];

  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
    _focusChanged();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    super.dispose();
  }

  // The focused field's ancestors are read after the frame: during a build
  // the field can sit in a part of the tree that is being moved or removed.
  void _focusChanged() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _updateScheduled = false;
        if (!mounted) return;
        final groups = FocusedFieldTapRegion.groupsAround(
          FocusManager.instance.primaryFocus,
        );
        if (_sameGroups(groups, _groups)) return;
        setState(() => _groups = groups);
      })
      ..ensureVisualUpdate();
  }

  static bool _sameGroups(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = KeyedSubtree(key: _childKey, child: widget.child);
    for (final group in _groups) {
      result = TapRegion(groupId: group, child: result);
    }
    return result;
  }
}

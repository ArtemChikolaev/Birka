import 'dart:async';
import 'dart:typed_data';

import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// A place to drop a file on, with a button that opens the chooser of the
/// system: a dashed frame with a glyph, a title, a line of text, the button,
/// the kinds of files it takes and a quiet note.
///
/// While it stands on the page, a file dropped past it does not make the
/// browser leave the page to show the file.
class FileDropZone extends StatefulComponent {
  /// Creates the zone.
  const FileDropZone({
    required this.title,
    required this.text,
    required this.buttonLabel,
    required this.onChoose,
    required this.onDrop,
    this.kinds = const [],
    this.note,
    this.busy = false,
    super.key,
  });

  /// What to do, such as «Перетащите выписку сюда».
  final String title;

  /// A line about the file.
  final String text;

  /// What the button says.
  final String buttonLabel;

  /// Opens the chooser of the system.
  final VoidCallback onChoose;

  /// Called with the name and the bytes of a file dropped on the zone.
  final void Function(String name, Uint8List bytes) onDrop;

  /// The kinds of files the zone takes, such as CSV.
  final List<String> kinds;

  /// A quiet line under the kinds.
  final String? note;

  /// Whether a file is being read, which holds the button.
  final bool busy;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();

  /// The styles of the zone.
  @css
  static List<StyleRule> get styles => [
    css('.file-drop').styles(
      raw: {
        'align-items': 'center',
        'border': '1.5px dashed var(--color-accent-soft)',
        'border-radius': 'var(--radius-lg)',
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
        'padding': 'var(--space-xxl) var(--space-lg)',
        'text-align': 'center',
        'transition':
            'background var(--duration-base) var(--easing-fade), '
            'border-color var(--duration-base) var(--easing-fade)',
      },
    ),
    css('.file-drop--over').styles(
      raw: {
        'background': 'var(--color-accent-soft)',
        'border-color': 'var(--color-accent)',
      },
    ),
    css('.file-drop__glyph').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent-soft)',
        'border-radius': 'var(--radius-md)',
        'color': 'var(--color-accent)',
        'display': 'flex',
        'height': '56px',
        'justify-content': 'center',
        'width': '56px',
      },
    ),
    css('.file-drop__glyph .birka-icon').styles(
      raw: {'height': '24px', 'width': '24px'},
    ),
    css('.file-drop__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.file-drop__text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0',
        'max-width': '480px',
      },
    ),
    css('.file-drop__button').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'box-shadow': 'var(--shadow-accent-glow)',
        'color': 'var(--color-on-accent)',
        'cursor': 'pointer',
        'display': 'inline-flex',
        'gap': 'var(--space-xs)',
        'height': '52px',
        'margin-top': 'var(--space-xs)',
        'padding': '0 var(--space-xl)',
        'transition': 'opacity var(--duration-fast)',
      },
    ),
    css('.file-drop__button:disabled').styles(
      raw: {'cursor': 'default', 'opacity': '0.6'},
    ),
    css('.file-drop__button:focus-visible').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '3px',
      },
    ),
    css('.file-drop__button .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    css('.file-drop__kinds').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
        'justify-content': 'center',
        'list-style': 'none',
        'margin': 'var(--space-xs) 0 0',
        'padding': '0',
      },
    ),
    css('.file-drop__kind').styles(
      raw: {
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text-secondary)',
        'padding': 'var(--space-xxs) var(--space-sm)',
      },
    ),
    css('.file-drop__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.file-drop').styles(raw: {'transition': 'none'}),
    ]),
  ];
}

class _FileDropZoneState extends State<FileDropZone> {
  /// How deep a drag is over the zone: it enters and leaves each element
  /// inside it too.
  var _over = 0;

  web.EventListener? _guard;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    // Over the rest of the page a file is neither opened nor dropped.
    final guard = ((web.Event event) {
      if (_carriesFiles(event)) event.preventDefault();
    }).toJS;
    _guard = guard;
    web.window
      ..addEventListener('dragover', guard)
      ..addEventListener('drop', guard);
  }

  @override
  void dispose() {
    if (_guard case final guard?) {
      web.window
        ..removeEventListener('dragover', guard)
        ..removeEventListener('drop', guard);
    }
    super.dispose();
  }

  static bool _carriesFiles(web.Event event) {
    final types = (event as web.DragEvent).dataTransfer?.types.toDart;
    return types?.any((type) => type.toDart == 'Files') ?? false;
  }

  void _enter(web.Event event) {
    if (!_carriesFiles(event)) return;
    event.preventDefault();
    setState(() => _over++);
  }

  void _leave(web.Event event) {
    if (_over == 0) return;
    setState(() => _over--);
  }

  void _drop(web.Event event) {
    event.preventDefault();
    setState(() => _over = 0);
    if (component.busy) return;
    final file = (event as web.DragEvent).dataTransfer?.files.item(0);
    if (file != null) unawaited(_read(file));
  }

  Future<void> _read(web.File file) async {
    final buffer = await file.arrayBuffer().toDart;
    component.onDrop(file.name, buffer.toDart.asUint8List());
  }

  @override
  Component build(BuildContext context) {
    final note = component.note;
    return div(
      classes: _over > 0 ? 'file-drop file-drop--over' : 'file-drop',
      events: {
        'dragenter': _enter,
        'dragover': (event) {
          if (_carriesFiles(event)) event.preventDefault();
        },
        'dragleave': _leave,
        'drop': _drop,
      },
      [
        const div(classes: 'file-drop__glyph', [BirkaIcon(BirkaGlyph.upload)]),
        h2(classes: 'text-heading file-drop__title', [
          .text(component.title),
        ]),
        p(classes: 'text-body file-drop__text', [.text(component.text)]),
        button(
          classes: 'text-body-strong file-drop__button',
          type: ButtonType.button,
          disabled: component.busy,
          onClick: component.onChoose,
          [
            const BirkaIcon(BirkaGlyph.upload),
            span([.text(component.buttonLabel)]),
          ],
        ),
        if (component.kinds.isNotEmpty)
          ul(classes: 'file-drop__kinds', [
            for (final kind in component.kinds)
              li(classes: 'text-caption file-drop__kind', [.text(kind)]),
          ]),
        if (note != null)
          p(classes: 'text-caption file-drop__note', [.text(note)]),
      ],
    );
  }
}

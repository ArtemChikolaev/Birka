import 'package:design_flutter/src/components/birka_button.dart';
import 'package:design_flutter/src/components/birka_chip.dart';
import 'package:design_flutter/src/components/birka_text_field.dart';
import 'package:design_flutter/src/components/choice_sheet.dart';
import 'package:design_flutter/src/components/fading_text.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Asks for one line in a sheet from the bottom of the screen, such as the
/// note of an operation or the name of a payment: a field with [label] that
/// starts with [initial], and a button that says [done]. The keyboard comes
/// at once, of [keyboardType] when one is given. A closed sheet gives `null`.
///
/// The field can end with [suffix], such as the sign of a currency. A [note]
/// under it says what the typed value means and follows each key, and a chip
/// of [suggestion] puts its value in the field.
Future<String?> showFieldSheet(
  BuildContext context, {
  required String label,
  required String done,
  String initial = '',
  String? hint,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.sentences,
  String? suffix,
  String Function(String typed)? note,
  FieldSuggestion? suggestion,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: BirkaColors.of(context).background,
    builder: (context) => _FieldSheet(
      label: label,
      done: done,
      initial: initial,
      hint: hint,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      suffix: suffix,
      note: note,
      suggestion: suggestion,
    ),
  );
}

/// A value that a chip of a field sheet puts in the field, such as half of a
/// sum: the label on the chip, and the value as it is typed.
typedef FieldSuggestion = ({String label, String value});

class _FieldSheet extends StatefulWidget {
  const _FieldSheet({
    required this.label,
    required this.done,
    required this.initial,
    required this.hint,
    required this.keyboardType,
    required this.textCapitalization,
    required this.suffix,
    required this.note,
    required this.suggestion,
  });

  final String label;
  final String done;
  final String initial;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? suffix;
  final String Function(String typed)? note;
  final FieldSuggestion? suggestion;

  @override
  State<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends State<_FieldSheet> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _done() => Navigator.of(context).pop(_field.text);

  void _suggest(String value) {
    _field.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final note = widget.note;
    final suggestion = widget.suggestion;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ChoiceSheet(
        children: [
          BirkaTextField(
            label: widget.label,
            hint: widget.hint,
            controller: _field,
            autofocus: true,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _done(),
            suffix: widget.suffix,
          ),
          // What the typed value means, which follows each key.
          if (note != null) ...[
            const SizedBox(height: BirkaTokens.spaceSm),
            ValueListenableBuilder(
              valueListenable: _field,
              builder: (context, value, _) => FadingText(
                note(value.text),
                style: styles.caption.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
          if (suggestion != null) ...[
            const SizedBox(height: BirkaTokens.spaceSm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BirkaChip(
                label: suggestion.label,
                selected: false,
                onTap: () => _suggest(suggestion.value),
              ),
            ),
          ],
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(label: widget.done, onPressed: _done),
        ],
      ),
    );
  }
}

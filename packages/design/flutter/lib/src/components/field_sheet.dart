import 'package:design_flutter/src/components/birka_button.dart';
import 'package:design_flutter/src/components/birka_text_field.dart';
import 'package:design_flutter/src/components/choice_sheet.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Asks for one line in a sheet from the bottom of the screen, such as the
/// note of an operation or the name of a payment: a field with [label] that
/// starts with [initial], and a button that says [done]. The keyboard comes
/// at once, of [keyboardType] when one is given. A closed sheet gives `null`.
Future<String?> showFieldSheet(
  BuildContext context, {
  required String label,
  required String done,
  String initial = '',
  String? hint,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.sentences,
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
    ),
  );
}

class _FieldSheet extends StatefulWidget {
  const _FieldSheet({
    required this.label,
    required this.done,
    required this.initial,
    required this.hint,
    required this.keyboardType,
    required this.textCapitalization,
  });

  final String label;
  final String done;
  final String initial;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

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

  @override
  Widget build(BuildContext context) {
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
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(label: widget.done, onPressed: _done),
        ],
      ),
    );
  }
}

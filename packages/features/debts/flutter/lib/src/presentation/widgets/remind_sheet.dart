import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:debts_flutter/src/presentation/widgets/debt_badge.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// Opens the message that reminds the other person of [debt] (ADR 0030): a
/// ready text that the person may change, sent by SMS to the number of
/// [person] or offered to another app through [phone]. Birka sends nothing
/// itself.
Future<void> showRemindSheet(
  BuildContext context, {
  required Debt debt,
  required Person? person,
  required PeoplePhone phone,
  required CivilDate today,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: BirkaColors.of(context).background,
    builder: (context) =>
        RemindSheet(debt: debt, person: person, phone: phone, today: today),
  );
}

/// The content of the sheet of a reminder by message.
class RemindSheet extends StatefulWidget {
  /// Creates the sheet of [debt] of [person].
  const RemindSheet({
    required this.debt,
    required this.person,
    required this.phone,
    required this.today,
    super.key,
  });

  /// The debt.
  final Debt debt;

  /// Its person, once read.
  final Person? person;

  /// The messages of the phone.
  final PeoplePhone phone;

  /// Today on this device.
  final CivilDate today;

  @override
  State<RemindSheet> createState() => _RemindSheetState();
}

class _RemindSheetState extends State<RemindSheet> {
  late final _text = TextEditingController(
    text: debtRemindText(widget.debt, today: widget.today),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Closes the sheet and hands the text to the phone.
  void _send(Future<void> Function(String text) send) {
    final text = _text.text.trim();
    Navigator.of(context).pop();
    unawaited(send(text));
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final words = t.debts.remind;
    final person = widget.person;
    final about = person?.about.trim() ?? '';
    final number = person?.phone;
    final phone = widget.phone;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: ChoiceSheet(
          title: words.title,
          children: [
            GlassListGroup(
              children: [
                GlassListRow(
                  leading: DebtBadge(widget.debt.account),
                  title: about.isEmpty
                      ? widget.debt.name
                      : '${widget.debt.name} · $about',
                  subtitle: number ?? words.noPhone,
                ),
              ],
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
            BirkaTextField(
              label: words.message,
              controller: _text,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: BirkaTokens.spaceSm),
            Text(
              number == null ? words.captionShare : words.caption,
              style: styles.caption.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: BirkaTokens.spaceLg),
            if (number != null) ...[
              BirkaButton(
                label: words.sms,
                onPressed: () => _send((text) => phone.sendSms(number, text)),
              ),
              const SizedBox(height: BirkaTokens.spaceSm),
              BirkaButton(
                label: words.otherApp,
                quiet: true,
                onPressed: () => _send(phone.share),
              ),
            ] else
              BirkaButton(
                label: words.share,
                onPressed: () => _send(phone.share),
              ),
          ],
        ),
      ),
    );
  }
}

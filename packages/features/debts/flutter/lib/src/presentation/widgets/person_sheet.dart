import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// What the sheet of someone new gives back: the name, who they are and the
/// number.
typedef NewPerson = ({String name, String about, String? phone});

/// Asks for someone new in a sheet from the bottom of the screen (ADR 0030):
/// the name that Birka shows, who they are and the number, typed or taken
/// from the contacts of [phone]. A name that someone of [people] has asks
/// who the new one is. A closed sheet gives `null`.
Future<NewPerson?> showPersonSheet(
  BuildContext context, {
  required List<Person> people,
  PeoplePhone? phone,
  NewPerson? initial,
}) {
  return showModalBottomSheet<NewPerson>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: BirkaColors.of(context).background,
    builder: (context) =>
        PersonSheet(people: people, phone: phone, initial: initial),
  );
}

/// The content of the sheet of someone new.
class PersonSheet extends StatefulWidget {
  /// Creates the sheet among [people], with the contacts of [phone].
  const PersonSheet({
    required this.people,
    this.phone,
    this.initial,
    super.key,
  });

  /// The people there are.
  final List<Person> people;

  /// The contacts and messages of the phone, or `null` without them.
  final PeoplePhone? phone;

  /// What the sheet starts with.
  final NewPerson? initial;

  @override
  State<PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<PersonSheet> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _about = TextEditingController(
    text: widget.initial?.about ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.initial?.phone ?? '',
  );

  /// The contact the fields came from, once one did.
  PickedContact? _contact;

  /// Whether the fields that a contact filled glow for a moment.
  var _lit = false;
  Timer? _dim;

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _about.addListener(_changed);
    _phone.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _dim?.cancel();
    _name.dispose();
    _about.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Someone there with the name typed, while who the new one is is not.
  Person? get _twin {
    final name = _name.text.trim().toLowerCase();
    if (name.isEmpty || _about.text.trim().isNotEmpty) return null;
    return widget.people
        .where((person) => person.name.trim().toLowerCase() == name)
        .firstOrNull;
  }

  Future<void> _pick() async {
    final phone = widget.phone;
    if (phone == null) return;
    final contact = await phone.pickContact();
    if (contact == null || !mounted) return;
    _dim?.cancel();
    setState(() {
      _contact = contact;
      _name.text = contact.shortName;
      _phone.text = contact.numbers.firstOrNull?.number ?? '';
      _lit = true;
    });
    _dim = Timer(BirkaMotion.slow * 2, () {
      if (mounted) setState(() => _lit = false);
    });
  }

  Future<void> _pickNumber() async {
    final contact = _contact;
    if (contact == null) return;
    final typed = _phone.text.trim();
    final current = contact.numbers
        .where((number) => number.number == typed)
        .firstOrNull;
    final picked = await showChoiceSheet<ContactNumber?>(
      context,
      title: t.debts.person.number,
      choices: [...contact.numbers, null],
      selected: current,
      labelOf: (number) =>
          number == null ? t.debts.person.noNumber : debtNumberKind(number),
      subtitleOf: (number) => number?.number ?? t.debts.person.noNumberNote,
    );
    if (picked == null || !mounted) return;
    _phone.text = picked.$1?.number ?? '';
  }

  void _done() {
    final phone = _phone.text.trim();
    Navigator.of(context).pop((
      name: _name.text.trim(),
      about: _about.text.trim(),
      phone: phone.isEmpty ? null : phone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final words = t.debts.person;
    final contact = _contact;
    final twin = _twin;
    final number = contact?.numbers
        .where((it) => it.number == _phone.text.trim())
        .firstOrNull;
    const gap = SizedBox(height: BirkaTokens.spaceMd);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: ChoiceSheet(
          title: words.newTitle,
          children: [
            if (widget.phone != null) ...[
              GlassListGroup(
                children: [
                  GlassListRow(
                    leading: GlyphBadge(
                      glyph: BirkaGlyph.contact,
                      color: colors.accent,
                    ),
                    title: words.fromContacts,
                    subtitle: words.fromContactsNote,
                    trailing: BirkaIcon(
                      BirkaGlyph.chevron,
                      size: BirkaTokens.spaceMd,
                      color: colors.textMuted,
                    ),
                    onTap: () => unawaited(_pick()),
                  ),
                ],
              ),
              gap,
            ],
            BirkaTextField(
              label: t.debts.form.name,
              hint: t.debts.form.nameHint,
              controller: _name,
              autofocus: widget.phone == null,
              textCapitalization: TextCapitalization.words,
              highlighted: _lit && _name.text.isNotEmpty,
            ),
            gap,
            BirkaTextField(
              label: words.about,
              hint: words.aboutHint,
              controller: _about,
              textCapitalization: TextCapitalization.sentences,
            ),
            // A namesake asks who the new one is, to tell them apart.
            AnimatedSize(
              duration: BirkaMotion.base,
              curve: BirkaMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: twin == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(
                        top: BirkaTokens.spaceXs,
                      ),
                      child: Text(
                        debtTwinLine(twin),
                        style: styles.caption.copyWith(
                          color: const Color(BirkaTokens.colorPaletteAmber),
                        ),
                      ),
                    ),
            ),
            gap,
            BirkaTextField(
              label: words.phone,
              hint: words.optional,
              controller: _phone,
              keyboardType: TextInputType.phone,
              highlighted: _lit && _phone.text.isNotEmpty,
              trailing: contact != null && contact.numbers.length > 1
                  ? BirkaChip(
                      label: number == null
                          ? words.noNumber.toLowerCase()
                          : debtNumberKind(number).toLowerCase(),
                      selected: false,
                      compact: true,
                      onTap: () => unawaited(_pickNumber()),
                    )
                  : null,
            ),
            gap,
            FadingText(
              contact == null
                  ? words.hint
                  : words.fromContact(contact: contact.name),
              style: styles.caption.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: BirkaTokens.spaceLg),
            BirkaButton(
              label: t.debts.done,
              onPressed: _name.text.trim().isEmpty ? null : _done,
            ),
          ],
        ),
      ),
    );
  }
}

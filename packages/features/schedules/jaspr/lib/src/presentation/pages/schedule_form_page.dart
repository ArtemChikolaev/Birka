import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_jaspr/src/presentation/components/schedule_bits.dart';

/// The days of the week, as the strings name them.
const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// The form of a regular payment on the site (ADR 0023), as the boards
/// «Регулярный платёж на сайте · форма» draw it: a page of its own with its
/// fields in the open. On a wide screen the side shows where the payment
/// came from, how it will stand in the list with its next days, and the
/// button; on a narrow one the page is the form alone.
///
/// It needs a [ScheduleFormCubit] above it.
class ScheduleFormPage extends StatefulComponent {
  /// Creates the page.
  const ScheduleFormPage({
    required this.onClose,
    required this.onDone,
    super.key,
  });

  /// Called by the cross.
  final VoidCallback onClose;

  /// Called once the payment is saved, deleted or not there, with what the
  /// list should say of it.
  final ValueChanged<String?> onDone;

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.schedule-form__pair').styles(
      raw: {
        'align-items': 'start',
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      },
    ),
    // A narrow page keeps the name and the amount one under the other.
    css.media(const MediaQuery.raw('(max-width: 900px)'), [
      css('.schedule-form__pair--wide').styles(
        raw: {'grid-template-columns': 'minmax(0, 1fr)'},
      ),
    ]),
    css('.schedule-form__field').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.schedule-form__label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedule-form__value').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-secondary)',
        'display': 'flex',
        'min-height': 'var(--size-touch-target)',
      },
    ),
    css('.schedule-form__note').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.schedule-form__note--trouble').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
    css('.schedule-form__made').styles(
      raw: {'align-items': 'center', 'display': 'flex', 'gap': '12px'},
    ),
    css('.schedule-form__made-words').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.schedule-form__made-line').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedule-form__preview').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.schedule-form__preview .text-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedule-form__preview-row').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'min-height': '48px',
      },
    ),
    css('.schedule-form__preview-words').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.schedule-form__preview-quiet').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.schedule-form__preview-meta').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedule-form__rule').styles(
      raw: {'background': 'var(--color-hairline)', 'height': '1px'},
    ),
  ];
}

class _ScheduleFormPageState extends State<ScheduleFormPage> {
  /// What is typed in the amount and in the advance: the cubit gets them
  /// once they read as money.
  String? _amount;
  String? _advance;

  /// Whether the question of deleting is open.
  bool _asking = false;

  void _listen(ScheduleFormState state) {
    final name = state.name.trim();
    switch (state.status) {
      case ScheduleFormStatus.saved:
        // A payment made of what came every month says so in the list.
        component.onDone(
          state.found == null ? null : t.schedules.madeRegular(name: name),
        );
      case ScheduleFormStatus.deleted:
        component.onDone(t.schedules.deleted(name: name));
      case ScheduleFormStatus.missing:
        component.onDone(null);
      case ScheduleFormStatus.loading ||
          ScheduleFormStatus.editing ||
          ScheduleFormStatus.saving:
        break;
    }
  }

  @override
  Component build(BuildContext context) {
    return BlocConsumer<ScheduleFormCubit, ScheduleFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, state) => _listen(state),
      builder: (context, state) => switch (state.status) {
        ScheduleFormStatus.loading ||
        ScheduleFormStatus.missing => const BirkaPlaceholder(),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, ScheduleFormState state) {
    final cubit = context.read<ScheduleFormCubit>();
    final made = state.madeFrom;
    return BirkaForm(
      title: state.editing ? state.name.trim() : t.schedules.newTitle,
      closeLabel: t.schedules.close,
      onClose: component.onClose,
      submitLabel: t.schedules.save,
      onSubmit: () => unawaited(cubit.save()),
      ready: state.valid,
      submitting: state.status == ScheduleFormStatus.saving,
      failure: state.failed ? t.schedules.failed : null,
      note: state.editing
          ? t.schedules.changeNote(date: _nextDate(state))
          : t.schedules.saveNote,
      aside: [
        if (made != null)
          div(classes: 'birka-wide-only', [
            _MadeFrom(made: made, state: state),
          ]),
        div(classes: 'birka-wide-only', [_preview(context, state)]),
        if (state.editing) _delete(context, cubit, state),
      ],
      children: [
        if (made != null)
          div(classes: 'birka-narrow-only', [
            _MadeFrom(made: made, state: state),
          ]),
        GlassSegmented<TransactionKind>(
          segments: {
            for (final kind in [
              TransactionKind.expense,
              TransactionKind.income,
              TransactionKind.transfer,
            ])
              kind: t.schedules.kinds[kind.name] ?? kind.name,
          },
          selected: state.kind,
          onChanged: cubit.kindChanged,
        ),
        div(classes: 'schedule-form__pair schedule-form__pair--wide', [
          BirkaTextField(
            label: t.schedules.name,
            value: state.name,
            hint: t.schedules.namePlaceholder,
            sentence: true,
            onChanged: cubit.nameChanged,
          ),
          div(classes: 'schedule-form__field', [
            BirkaTextField(
              label: state.halves
                  ? t.schedules.amountMonthly
                  : t.schedules.amount,
              value: _amount ?? _typed(state.amount),
              hint: '0',
              inputMode: 'decimal',
              suffix: switch (state.account) {
                final account? => currencySign(account.currency),
                null => null,
              },
              onChanged: (typed) => _amountTyped(cubit, state, typed),
            ),
            ..._amountNotes(context, state),
          ]),
        ]),
        div(classes: 'schedule-form__pair', [
          if (state.kind != TransactionKind.transfer)
            _select<String>(
              label: t.schedules.category,
              options: {
                '': t.schedules.noCategory,
                for (final category in state.categories)
                  category.id: category.name,
              },
              selected: state.categoryId ?? '',
              dot: state.category?.color,
              quiet: state.category == null,
              onChanged: (id) => cubit.categoryChanged(id.isEmpty ? null : id),
            ),
          _select<String>(
            label: switch (state.kind) {
              TransactionKind.transfer => t.schedules.fromAccount,
              TransactionKind.income => t.schedules.incomeAccount,
              _ => t.schedules.account,
            },
            options: {
              if (state.account == null) '': t.schedules.pickAccount,
              for (final account in state.accounts) account.id: account.name,
            },
            selected: state.accountId ?? '',
            quiet: state.account == null,
            onChanged: (id) {
              if (id.isNotEmpty) cubit.accountChanged(id);
            },
          ),
          if (state.kind == TransactionKind.transfer)
            _select<String>(
              label: t.schedules.toAccount,
              options: {
                if (state.toAccount == null) '': t.schedules.pickAccount,
                for (final account in state.targets) account.id: account.name,
              },
              selected: state.toAccountId ?? '',
              quiet: state.toAccount == null,
              onChanged: (id) {
                if (id.isNotEmpty) cubit.toAccountChanged(id);
              },
            ),
        ]),
        BirkaFold(
          open: state.kind == TransactionKind.income,
          children: [_parts(context, cubit, state)],
        ),
        // A salary in halves comes every month, on two days.
        BirkaFold(
          open: !state.halves,
          children: [
            BirkaChoice(
              label: t.schedules.every,
              children: [
                for (final every in ScheduleEvery.values)
                  BirkaChip(
                    label: t.schedules.everyOptions[every.name] ?? every.name,
                    selected: state.every == every,
                    onTap: () => cubit.everyChanged(every),
                  ),
              ],
            ),
          ],
        ),
        BirkaFold(
          open: state.halves,
          children: [
            div(classes: 'schedule-form__pair', [
              _select<int>(
                label: t.schedules.advanceDay,
                options: _days,
                selected: state.advanceDay ?? state.day,
                onChanged: cubit.advanceDayChanged,
              ),
              div(classes: 'schedule-form__field', [
                BirkaTextField(
                  label: t.schedules.advanceAmount,
                  value: _advance ?? _typed(state.advanceAmount, own: state),
                  hint: t.schedules.advanceHalf,
                  inputMode: 'decimal',
                  suffix: switch (state.account) {
                    final account? => currencySign(account.currency),
                    null => null,
                  },
                  onChanged: (typed) => _advanceTyped(cubit, state, typed),
                ),
                if (_advanceRest(context, state) case final rest?)
                  p(classes: 'text-caption schedule-form__note', [.text(rest)]),
              ]),
            ]),
          ],
        ),
        div(classes: 'schedule-form__pair', [
          _day(cubit, state),
          div(classes: 'schedule-form__field', [
            span(classes: 'text-caption schedule-form__label', [
              .text(t.schedules.next),
            ]),
            if (state.halves)
              span(classes: 'text-body schedule-form__value', [
                .text(_nextLabel(state)),
              ])
            else
              div([
                BirkaDateChip(
                  fieldLabel: t.schedules.next,
                  label: _nextLabel(state),
                  value: _iso(state.next),
                  first: _iso(state.today),
                  last: _iso(state.today.addMonths(60)),
                  onChanged: (typed) {
                    final day = _parseIso(typed);
                    if (day != null && day.compareTo(state.today) >= 0) {
                      cubit.nextChanged(day);
                    }
                  },
                ),
              ]),
          ]),
        ]),
        div(classes: 'schedule-form__field', [
          BirkaChoice(
            label: t.schedules.onDayTitle,
            children: [
              for (final onDay in ScheduleOnDay.values)
                BirkaChip(
                  label: t.schedules.onDay[onDay.name] ?? onDay.name,
                  selected: state.onDay == onDay,
                  onTap: () => cubit.onDayChanged(onDay),
                ),
            ],
          ),
          p(classes: 'text-caption schedule-form__note', [
            .text(
              state.onDay == ScheduleOnDay.post
                  ? t.schedules.postNote
                  : t.schedules.askNote,
            ),
          ]),
        ]),
      ],
    );
  }

  /// How an income comes: in one sum, or in halves, an advance and the rest.
  Component _parts(
    BuildContext context,
    ScheduleFormCubit cubit,
    ScheduleFormState state,
  ) {
    final advance = state.advanceDay;
    return div(classes: 'schedule-form__field', [
      BirkaChoice(
        label: t.schedules.partsTitle,
        children: [
          BirkaChip(
            label: t.schedules.parts['one'] ?? '',
            selected: !state.halves,
            onTap: () => cubit.halvesChanged(halves: false),
          ),
          BirkaChip(
            label: t.schedules.parts['two'] ?? '',
            selected: state.halves,
            onTap: () => cubit.halvesChanged(halves: true),
          ),
        ],
      ),
      p(classes: 'text-caption schedule-form__note', [
        .text(switch ((advance, state.advanceAmount, state.part)) {
          (final advance?, final own?, final rest?) when state.ownAdvance =>
            HiddenAmounts.mask(
              context,
              t.schedules.partsOwn(
                advanceAmount: formatMoney(own),
                advance: advance,
                restAmount: formatMoney(rest),
                day: state.day,
              ),
            ),
          (final advance?, _, _) when state.halves => t.schedules.partsTwo(
            advance: advance,
            day: state.day,
          ),
          _ => t.schedules.partsOne,
        }),
      ]),
    ]);
  }

  /// The day the payment comes on: of the month, of the week, of the year,
  /// or the day of the rest of a salary in halves.
  Component _day(ScheduleFormCubit cubit, ScheduleFormState state) {
    final today = state.today;
    if (state.halves) {
      return _select<int>(
        label: t.schedules.restDay,
        options: _days,
        selected: state.day,
        onChanged: (day) =>
            cubit.nextChanged(CivilDate.onDay(today.year, today.month, day)),
      );
    }
    return switch (state.every) {
      ScheduleEvery.month => _select<int>(
        label: t.schedules.dayOfMonth,
        options: _days,
        selected: state.day,
        onChanged: (day) => cubit.nextChanged(_nextOnDay(today, day)),
      ),
      ScheduleEvery.week => _select<int>(
        label: t.schedules.dayOfWeek,
        options: {
          for (var weekday = 1; weekday <= 7; weekday++)
            weekday: t.schedules.on[_weekdays[weekday - 1]] ?? '',
        },
        selected: state.next.weekday,
        onChanged: (weekday) =>
            cubit.nextChanged(today.addDays((weekday - today.weekday) % 7)),
      ),
      ScheduleEvery.year => div(classes: 'schedule-form__field', [
        span(classes: 'text-caption schedule-form__label', [
          .text(t.schedules.dayOfYear),
        ]),
        span(classes: 'text-body schedule-form__value', [
          .text(fullDate(state.next, today)),
        ]),
      ]),
    };
  }

  /// How the payment will stand in «Все регулярные», and its next days.
  Component _preview(BuildContext context, ScheduleFormState state) {
    final schedule = state.schedule;
    final name = state.name.trim();
    final times = <CivilDate>[schedule.next];
    while (times.length < 3) {
      times.add(schedule.after(times.last));
    }
    final color =
        state.category?.color ??
        (state.kind == TransactionKind.income
            ? 'var(--color-positive)'
            : 'var(--color-text-subtle)');
    return div(classes: 'glass schedule-form__preview', [
      span(classes: 'text-label', [.text(t.schedules.previewTitle)]),
      div(classes: 'schedule-form__preview-row', [
        span(
          classes: 'schedule-dot',
          styles: Styles(raw: {'background': color}),
          attributes: const {'aria-hidden': 'true'},
          const [],
        ),
        span(classes: 'schedule-form__preview-words', [
          span(
            classes: name.isEmpty
                ? 'text-body-strong schedule-form__preview-quiet'
                : 'text-body-strong',
            [.text(name.isEmpty ? t.schedules.name : name)],
          ),
          span(classes: 'text-caption schedule-form__preview-meta', [
            .text(scheduleLine(schedule, state.today)),
          ]),
        ]),
        span(classes: amountClasses(state.kind), [
          .text(HiddenAmounts.mask(context, scheduleTotal(schedule))),
        ]),
      ]),
      const div(classes: 'schedule-form__rule', []),
      span(classes: 'text-caption schedule-form__preview-meta', [
        .text(t.schedules.previewNext),
      ]),
      span(classes: 'text-body-strong', [
        .text(times.map((time) => fullDate(time, state.today)).join(' · ')),
      ]),
    ]);
  }

  Component _delete(
    BuildContext context,
    ScheduleFormCubit cubit,
    ScheduleFormState state,
  ) {
    if (_asking) {
      return GlassNotice(
        title: t.schedules.deleteTitle(name: state.name.trim()),
        text: t.schedules.deleteNote,
        actions: [
          BirkaButton(
            label: t.schedules.delete,
            danger: true,
            onPressed: () {
              setState(() => _asking = false);
              unawaited(cubit.delete());
            },
          ),
          BirkaButton(
            label: t.schedules.cancel,
            quiet: true,
            onPressed: () => setState(() => _asking = false),
          ),
        ],
      );
    }
    return GlassListGroup(
      children: [
        GlassListRow(
          title: t.schedules.delete,
          subtitle: t.schedules.deleteNote,
          danger: true,
          onTap: () => setState(() => _asking = true),
        ),
      ],
    );
  }

  List<Component> _amountNotes(BuildContext context, ScheduleFormState state) {
    final part = state.part;
    final advance = state.advanceAmount;
    return [
      if (state.halves && state.amountMinor > 0)
        p(
          classes: part == null
              ? 'text-caption schedule-form__note schedule-form__note--trouble'
              : 'text-caption schedule-form__note',
          [
            .text(switch ((part, advance)) {
              (final part?, final advance?) when state.ownAdvance =>
                HiddenAmounts.mask(
                  context,
                  t.schedules.halvesOwn(
                    advance: formatMoney(advance),
                    rest: formatMoney(part),
                  ),
                ),
              (final part?, _) => HiddenAmounts.mask(
                context,
                t.schedules.halves(amount: formatMoney(part)),
              ),
              _ => t.schedules.halvesUneven,
            }),
          ],
        ),
      if (foundRangeLabel(state) case final range?)
        p(classes: 'text-caption schedule-form__note', [
          .text(HiddenAmounts.mask(context, range)),
        ]),
    ];
  }

  /// What the salary brings after the advance of its own, or after half.
  String? _advanceRest(BuildContext context, ScheduleFormState state) {
    final month = state.amount;
    final advance = state.advanceAmount ?? state.half;
    if (month == null || advance == null) return null;
    final rest = month - advance;
    if (!rest.isPositive) return null;
    return HiddenAmounts.mask(
      context,
      t.schedules.advanceRest(amount: formatMoney(rest), day: state.day),
    );
  }

  void _amountTyped(
    ScheduleFormCubit cubit,
    ScheduleFormState state,
    String typed,
  ) {
    setState(() => _amount = typed);
    final currency = state.account?.currency;
    if (currency == null) return;
    final money = amountTyped(typed, currency);
    if (money != null) cubit.amountChanged(money.minorUnits);
  }

  void _advanceTyped(
    ScheduleFormCubit cubit,
    ScheduleFormState state,
    String typed,
  ) {
    setState(() => _advance = typed);
    final currency = state.account?.currency;
    if (currency == null) return;
    if (typed.trim().isEmpty) return cubit.advanceAmountChanged(null);
    final money = amountTyped(typed, currency);
    if (money != null) cubit.advanceAmountChanged(money.minorUnits);
  }
}

/// The operation that a new payment is made from: the days of what came
/// every month, or its day, name, amount and category.
class _MadeFrom extends StatelessComponent {
  const _MadeFrom({required this.made, required this.state});

  final Transaction made;
  final ScheduleFormState state;

  @override
  Component build(BuildContext context) {
    final categoryId = made.allocations.firstOrNull?.categoryId;
    final category = [
      ...state.expenses,
      ...state.incomes,
    ].where((it) => it.id == categoryId).firstOrNull;
    final found = state.found;
    return GlassSurface(
      child: div(classes: 'schedule-form__made', [
        const GlyphBadge(
          glyph: BirkaGlyph.repeat,
          color: 'var(--color-accent)',
        ),
        div(classes: 'schedule-form__made-words', [
          span(classes: 'text-body-strong', [
            .text(switch (found) {
              final found? => t.schedules.foundIn(
                n: found.times.length,
                count: formatCount(found.times.length),
              ),
              null => t.schedules.fromOperation(
                date: fullDate(made.occurredOn, state.today),
              ),
            }),
          ]),
          span(classes: 'text-caption schedule-form__made-line', [
            .text(switch (found) {
              final found? => findDaysLine(found, category: category?.name),
              null => HiddenAmounts.mask(
                context,
                madeFromLine(made, category: category?.name),
              ),
            }),
          ]),
        ]),
      ]),
    );
  }
}

/// A select under its label, as the fields of the form stand.
Component _select<T>({
  required String label,
  required Map<T, String> options,
  required T selected,
  required ValueChanged<T> onChanged,
  String? dot,
  bool quiet = false,
}) {
  return div(classes: 'schedule-form__field', [
    span(classes: 'text-caption schedule-form__label', [.text(label)]),
    BirkaSelect<T>(
      label: label,
      options: options,
      selected: selected,
      onChanged: onChanged,
      dot: dot,
      quiet: quiet,
    ),
  ]);
}

/// The days of a month, as the form names them: `12-го`.
final Map<int, String> _days = {
  for (var day = 1; day <= 31; day++) day: t.schedules.dayNumber(day: day),
};

/// The next [day] of a month from [today], today itself included.
CivilDate _nextOnDay(CivilDate today, int day) {
  final here = CivilDate.onDay(today.year, today.month, day);
  return here.compareTo(today) >= 0
      ? here
      : CivilDate.onDay(today.year, today.month + 1, day);
}

/// `аванс, 20 ноября, пт` or `5 декабря, сб`.
String _nextLabel(ScheduleFormState state) {
  final date =
      '${fullDate(state.next, state.today)}, ${weekdayLabel(state.next)}';
  return state.nextIsAdvance ? t.schedules.nextAdvance(date: date) : date;
}

/// The next date of a payment that changes, as the note under the button
/// says it.
String _nextDate(ScheduleFormState state) {
  final date = fullDate(state.next, state.today);
  return state.nextIsAdvance ? t.schedules.nextAdvance(date: date) : date;
}

/// What a person would type of [amount], or nothing for none.
String _typed(Money? amount, {ScheduleFormState? own}) {
  if (own != null && !own.ownAdvance) return '';
  if (amount == null || amount.isZero) return '';
  return typedAmount(amount);
}

String _iso(CivilDate day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

CivilDate? _parseIso(String typed) {
  final parts = typed.split('-');
  if (parts.length != 3) return null;
  final [year, month, day] = [for (final part in parts) int.tryParse(part)];
  if (year == null || month == null || day == null) return null;
  return CivilDate(year, month, day);
}

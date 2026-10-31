import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/big_amount.dart';
import 'package:transactions_jaspr/src/presentation/components/quick_add_tile.dart';

/// The form that records an expense, an income or a transfer.
///
/// It needs a [QuickAddCubit] above it.
class QuickAddPage extends StatelessComponent {
  /// Creates the page. [onClose] is called when it is done or cancelled.
  const QuickAddPage({
    required this.onClose,
    required this.addAccountHref,
    required this.addCategoriesHref,
    super.key,
  });

  /// Closes the form.
  final VoidCallback onClose;

  /// Where a new account opens.
  final String addAccountHref;

  /// Where the categories open.
  final String addCategoriesHref;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<QuickAddCubit, QuickAddState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, state) {
        if (state.status == QuickAddStatus.saved) onClose();
      },
      builder: (context, state) => switch (state) {
        QuickAddState(status: QuickAddStatus.loading) => const div([]),
        QuickAddState(status: QuickAddStatus.failedToRead, accounts: []) =>
          _notice(
            GlassNotice(
              text: t.transactions.failedToRead,
              actions: [
                BirkaButton(
                  label: t.app.retry,
                  onPressed: () =>
                      unawaited(context.read<QuickAddCubit>().refresh()),
                ),
              ],
            ),
          ),
        QuickAddState(accounts: []) => _notice(
          GlassNotice(
            title: t.transactions.noAccountsTitle,
            text: t.transactions.noAccountsHint,
            actions: [
              BirkaButton(
                label: t.transactions.addAccount,
                href: addAccountHref,
              ),
            ],
          ),
        ),
        _ => _Sheet(
          state: state,
          onClose: onClose,
          addAccountHref: addAccountHref,
          addCategoriesHref: addCategoriesHref,
        ),
      },
    );
  }

  /// A page with nothing to record yet.
  Component _notice(Component notice) {
    return BirkaColumn(
      children: [
        div(classes: 'quick-add__header', [
          h1(classes: 'text-heading quick-add__title', [
            .text(t.app.newOperation),
          ]),
          GlassIconButton(
            glyph: BirkaGlyph.close,
            label: t.app.close,
            onPressed: onClose,
          ),
        ]),
        notice,
      ],
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.quick-add__header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.quick-add__title').styles(raw: {'flex': '1', 'margin': '0'}),
    css('.quick-add .birka-form').styles(raw: {'gap': 'var(--space-sm)'}),
    css('.quick-add__amount').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text)',
        'display': 'flex',
        'flex-direction': 'column',
        'text-align': 'center',
      },
    ),
    // The line with the sum stays when it is empty, so that nothing jumps.
    css('.quick-add__sum').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'max-width': '100%',
        'min-height': '20px',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.quick-add__amount .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.quick-add__line').styles(
      raw: {
        'align-items': 'center',
        'background': 'none',
        'border': '0',
        'color': 'var(--color-text-subtle)',
        'cursor': 'pointer',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
        'padding': 'var(--space-xxs) 0',
        'width': '100%',
      },
    ),
    css('.quick-add__line--active').styles(raw: {'color': 'var(--color-text)'}),
    css('.quick-add__details').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.quick-add__picture').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.quick-add__targets').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.quick-add__hint').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css('.quick-add__label').styles(raw: {'color': 'var(--color-text-muted)'}),
  ];
}

class _Sheet extends StatefulComponent {
  const _Sheet({
    required this.state,
    required this.onClose,
    required this.addAccountHref,
    required this.addCategoriesHref,
  });

  final QuickAddState state;
  final VoidCallback onClose;
  final String addAccountHref;
  final String addCategoriesHref;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  static const List<TransactionKind> _kinds = [
    TransactionKind.expense,
    TransactionKind.income,
    TransactionKind.transfer,
  ];

  /// The earliest day of the calendar.
  static final DateTime _firstDay = DateTime(2000);

  /// Whether the accounts to choose from are open.
  var _pickingAccount = false;

  /// Whether every category stands on the page.
  var _allCategories = false;

  QuickAddState get _state => component.state;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<QuickAddCubit>();
    final state = _state;
    return div(classes: 'quick-add', [
      BirkaForm(
        title: state.changesExisting
            ? t.transactions.editOperation
            : t.app.newOperation,
        closeLabel: t.app.close,
        onClose: component.onClose,
        submitLabel: _saveLabel,
        onSubmit: () => unawaited(cubit.save()),
        ready: state.canSave,
        failure: switch (state.status) {
          QuickAddStatus.failed => t.transactions.failed,
          QuickAddStatus.failedToRead => t.transactions.failedToRead,
          _ => null,
        },
        children: [
          GlassSegmented<TransactionKind>(
            segments: {
              for (final kind in _kinds) kind: transactionKindLabel(kind),
            },
            selected: state.kind,
            onChanged: cubit.kindChanged,
          ),
          _amount(cubit),
          _details(cubit),
          ?_accountChoice(cubit),
          if (state.kind == TransactionKind.transfer)
            _targets(cubit)
          else
            _categories(cubit),
          GlassKeypad(
            point: decimalSeparator,
            pointLabel: t.transactions.keys.point,
            backspaceLabel: t.transactions.keys.backspace,
            operatorLabels: {
              KeypadOperator.add: t.transactions.keys.add,
              KeypadOperator.subtract: t.transactions.keys.subtract,
              KeypadOperator.multiply: t.transactions.keys.multiply,
              KeypadOperator.divide: t.transactions.keys.divide,
            },
            onDigit: cubit.digitTyped,
            onPoint: cubit.pointTyped,
            onOperator: (key) =>
                cubit.operatorTyped(AmountOperator.values.byName(key.name)),
            onBackspace: cubit.backspaceTyped,
            onEnter: () => unawaited(cubit.save()),
          ),
        ],
      ),
    ]);
  }

  String get _saveLabel {
    final target = _state.kind == TransactionKind.transfer
        ? _state.toAccount?.name
        : _state.category?.name;
    return target == null
        ? t.transactions.save
        : '${t.transactions.save} · $target';
  }

  /// The big amount, with the sum being worked out over it.
  Component _amount(QuickAddCubit cubit) {
    final state = _state;
    final account = state.account;
    if (account == null) return const div([]);
    final to = state.toAccount;
    if (state.needsTwoAmounts && to != null) {
      return div([
        _line(
          label: t.transactions.sent,
          expression: state.sent,
          account: account,
          active: !state.editingReceived,
          onTap: () => cubit.editingChanged(received: false),
        ),
        _line(
          label: t.transactions.received,
          expression: state.received,
          account: to,
          active: state.editingReceived,
          onTap: () => cubit.editingChanged(received: true),
        ),
      ]);
    }
    return div(classes: 'quick-add__amount', [
      span(classes: 'text-body quick-add__sum', [
        if (state.sent.hasOperators)
          .text(state.sent.text(separator: decimalSeparator)),
      ]),
      BigAmount(
        amountLabel(state.kind, state.sent, account.currency),
        alwaysShown: true,
      ),
    ]);
  }

  /// One of the two amounts of a transfer between currencies.
  Component _line({
    required String label,
    required AmountExpression expression,
    required Account account,
    required bool active,
    required VoidCallback onTap,
  }) {
    return button(
      classes: active
          ? 'text-body quick-add__line quick-add__line--active'
          : 'text-body quick-add__line',
      type: ButtonType.button,
      onClick: onTap,
      attributes: {'aria-pressed': '$active'},
      [
        span([.text(label)]),
        AmountText(
          amountLabel(_state.kind, expression, account.currency),
          alwaysShown: true,
          textClass: 'text-title',
        ),
      ],
    );
  }

  /// The account, the day and the note.
  Component _details(QuickAddCubit cubit) {
    final state = _state;
    final day = state.day;
    final earlier = day != state.today && day != state.yesterday;
    return div(classes: 'quick-add__details', [
      BirkaChip(
        glyph: BirkaGlyph.wallet,
        label: state.account?.name ?? t.transactions.account,
        selected: _pickingAccount,
        onTap: () => setState(() => _pickingAccount = !_pickingAccount),
      ),
      BirkaChip(
        label: t.transactions.today,
        selected: day == state.today,
        onTap: () => cubit.dayChanged(state.today),
      ),
      BirkaChip(
        label: t.transactions.yesterday,
        selected: day == state.yesterday,
        onTap: () => cubit.dayChanged(state.yesterday),
      ),
      BirkaDateChip(
        fieldLabel: t.transactions.pickDay,
        label: earlier ? dayLabel(day, today: state.today) : null,
        value: '$day',
        first: '${CivilDate.of(_firstDay)}',
        last: '${state.today}',
        onChanged: (text) => _dayPicked(cubit, text),
      ),
      BirkaChipField(
        label: '+ ${t.transactions.addNote}',
        value: state.note,
        onChanged: cubit.noteChanged,
      ),
    ]);
  }

  /// Takes a day from the calendar. A day typed by hand can be out of range.
  void _dayPicked(QuickAddCubit cubit, String text) {
    final picked = DateTime.tryParse(text);
    final today = _state.today;
    if (picked == null ||
        picked.isBefore(_firstDay) ||
        picked.isAfter(DateTime(today.year, today.month, today.day))) {
      return;
    }
    cubit.dayChanged(CivilDate.of(picked));
  }

  Component? _accountChoice(QuickAddCubit cubit) {
    if (!_pickingAccount) return null;
    final state = _state;
    return GlassListGroup(
      children: [
        for (final account in state.accounts)
          GlassListRow(
            title: account.name,
            subtitle: account.currency.code,
            leading: CardArtThumbnail(
              art: CardArt.values.byName(account.art.name),
              highlighted: account.id == state.accountId,
            ),
            onTap: () {
              cubit.accountChanged(account.id);
              setState(() => _pickingAccount = false);
            },
          ),
      ],
    );
  }

  Component _categories(QuickAddCubit cubit) {
    final state = _state;
    if (state.categories.isEmpty) {
      return _hint(
        text: t.transactions.noCategoriesHint,
        action: t.transactions.addCategories,
        href: component.addCategoriesHref,
      );
    }
    final all = _allCategories || !state.hasMoreCategories;
    return QuickAddTiles(
      tiles: [
        for (final category in all ? state.categories : state.shown)
          QuickAddTile(
            label: category.name,
            selected: category.id == state.categoryId,
            onTap: () => cubit.categoryChanged(category.id),
            picture: span(
              classes: 'quick-add__picture',
              styles: category.color == null
                  ? null
                  : Styles(raw: {'color': category.color!}),
              [BirkaIcon(BirkaGlyph.named(category.icon))],
            ),
          ),
        if (!all)
          QuickAddTile(
            label: t.transactions.more,
            selected: false,
            onTap: () => setState(() => _allCategories = true),
            picture: const span(classes: 'quick-add__picture', [
              BirkaIcon(BirkaGlyph.dots),
            ]),
          ),
      ],
    );
  }

  /// The accounts a transfer can go to.
  Component _targets(QuickAddCubit cubit) {
    final state = _state;
    if (state.targets.isEmpty) {
      return _hint(
        text: t.transactions.oneAccountHint,
        action: t.transactions.addAccount,
        href: component.addAccountHref,
      );
    }
    return div(classes: 'quick-add__targets', [
      span(classes: 'text-caption quick-add__label', [
        .text(t.transactions.to),
      ]),
      QuickAddTiles(
        tiles: [
          for (final account in state.targets)
            QuickAddTile(
              label: account.name,
              selected: account.id == state.toAccountId,
              onTap: () => cubit.toAccountChanged(account.id),
              picture: CardArtThumbnail(
                art: CardArt.values.byName(account.art.name),
              ),
            ),
        ],
      ),
    ]);
  }

  /// A line in place of what is missing, with the way to add it.
  Component _hint({
    required String text,
    required String action,
    required String href,
  }) {
    return div(classes: 'quick-add__targets', [
      p(classes: 'text-caption quick-add__hint', [.text(text)]),
      BirkaButton(label: action, quiet: true, href: href),
    ]);
  }
}

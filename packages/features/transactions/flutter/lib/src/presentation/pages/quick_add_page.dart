import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/choice_sheet.dart';
import 'package:transactions_flutter/src/presentation/widgets/quick_add_tile.dart';

/// The sheet that records an expense, an income or a transfer.
///
/// It needs a [QuickAddCubit] above it.
class QuickAddPage extends StatelessWidget {
  /// Creates the page. [onClose] is called when it is done or cancelled.
  const QuickAddPage({
    required this.onClose,
    required this.onAddAccount,
    required this.onAddCategories,
    super.key,
  });

  /// Closes the sheet.
  final VoidCallback onClose;

  /// Leads to a new account, and completes on the way back.
  final Future<void> Function() onAddAccount;

  /// Leads to the categories, and completes on the way back.
  final Future<void> Function() onAddCategories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<QuickAddCubit, QuickAddState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == QuickAddStatus.saved) onClose();
            },
            builder: (context, state) => switch (state) {
              QuickAddState(status: QuickAddStatus.loading) =>
                const SizedBox.shrink(),
              QuickAddState(
                status: QuickAddStatus.failedToRead,
                accounts: [],
              ) =>
                _Notice(
                  title: t.transactions.failedToRead,
                  action: t.app.retry,
                  onClose: onClose,
                  onAction: context.read<QuickAddCubit>().refresh,
                ),
              QuickAddState(accounts: []) => _Notice(
                title: t.transactions.noAccountsTitle,
                text: t.transactions.noAccountsHint,
                action: t.transactions.addAccount,
                onClose: onClose,
                onAction: () => _addThenRefresh(context, onAddAccount),
              ),
              _ => _Sheet(
                state: state,
                onClose: onClose,
                onAddAccount: () => _addThenRefresh(context, onAddAccount),
                onAddCategories: () =>
                    _addThenRefresh(context, onAddCategories),
              ),
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _addThenRefresh(
    BuildContext context,
    Future<void> Function() add,
  ) async {
    final cubit = context.read<QuickAddCubit>();
    await add();
    if (!cubit.isClosed) await cubit.refresh();
  }
}

/// A sheet with nothing to record yet.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.action,
    required this.onClose,
    required this.onAction,
    this.text,
  });

  final String title;
  final String? text;
  final String action;
  final VoidCallback onClose;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final text = this.text;
    return Padding(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(onClose: onClose),
          const SizedBox(height: BirkaTokens.spaceLg),
          GlassSurface(
            padding: const EdgeInsets.all(BirkaTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: styles.heading.copyWith(color: colors.text),
                ),
                if (text != null) ...[
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Text(
                    text,
                    style: styles.body.copyWith(color: colors.textMuted),
                  ),
                ],
                const SizedBox(height: BirkaTokens.spaceLg),
                BirkaButton(label: action, onPressed: onAction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, this.title});

  final VoidCallback onClose;

  /// The heading, by default the one of a new operation.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title ?? t.app.newOperation,
            style: styles.heading.copyWith(
              color: BirkaColors.of(context).text,
            ),
          ),
        ),
        GlassIconButton(
          glyph: BirkaGlyph.close,
          label: t.app.close,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.state,
    required this.onClose,
    required this.onAddAccount,
    required this.onAddCategories,
  });

  final QuickAddState state;
  final VoidCallback onClose;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCategories;

  static const List<TransactionKind> _kinds = [
    TransactionKind.expense,
    TransactionKind.income,
    TransactionKind.transfer,
  ];

  static const Widget _gap = SizedBox(height: BirkaTokens.spaceSm);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuickAddCubit>();
    final failure = switch (state.status) {
      QuickAddStatus.failed => t.transactions.failed,
      QuickAddStatus.failedToRead => t.transactions.failedToRead,
      _ => null,
    };
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BirkaTokens.spaceLg,
              BirkaTokens.spaceXs,
              BirkaTokens.spaceLg,
              BirkaTokens.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onClose: onClose,
                  title: state.changesExisting
                      ? t.transactions.editOperation
                      : null,
                ),
                _gap,
                GlassSegmented<TransactionKind>(
                  segments: {
                    for (final kind in _kinds) kind: transactionKindLabel(kind),
                  },
                  selected: state.kind,
                  onChanged: cubit.kindChanged,
                ),
                _gap,
                _Amount(state: state),
                _gap,
                _Details(state: state),
                _gap,
                if (state.kind == TransactionKind.transfer)
                  _Targets(state: state, onAddAccount: onAddAccount)
                else
                  _Categories(state: state, onAddCategories: onAddCategories),
                _gap,
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: GlassKeypad.minHeight,
                    ),
                    child: GlassKeypad(
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
                      onOperator: (key) => cubit.operatorTyped(
                        AmountOperator.values.byName(key.name),
                      ),
                      onBackspace: cubit.backspaceTyped,
                    ),
                  ),
                ),
                _gap,
                if (failure != null) ...[
                  Text(
                    failure,
                    textAlign: TextAlign.center,
                    style: BirkaTextStyles.of(
                      context,
                    ).caption.copyWith(color: BirkaColors.of(context).negative),
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                ],
                BirkaButton(
                  label: _saveLabel,
                  onPressed: state.canSave ? cubit.save : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _saveLabel {
    final target = state.kind == TransactionKind.transfer
        ? state.toAccount?.name
        : state.category?.name;
    return target == null
        ? t.transactions.save
        : '${t.transactions.save} · $target';
  }
}

/// The big amount, with the sum being worked out over it.
class _Amount extends StatelessWidget {
  const _Amount({required this.state});

  final QuickAddState state;

  /// The height of the line with the sum, which stays when it is empty, so
  /// that the sheet does not jump.
  static const double _sumHeight = 20;

  @override
  Widget build(BuildContext context) {
    final account = state.account;
    if (account == null) return const SizedBox.shrink();
    final to = state.toAccount;
    if (state.needsTwoAmounts && to != null) {
      return Column(
        children: [
          _Line(
            label: t.transactions.sent,
            expression: state.sent,
            kind: state.kind,
            account: account,
            active: !state.editingReceived,
            onTap: () => context.read<QuickAddCubit>().editingChanged(
              received: false,
            ),
          ),
          _Line(
            label: t.transactions.received,
            expression: state.received,
            kind: state.kind,
            account: to,
            active: state.editingReceived,
            onTap: () => context.read<QuickAddCubit>().editingChanged(
              received: true,
            ),
          ),
        ],
      );
    }
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Column(
      children: [
        SizedBox(
          height: _sumHeight,
          child: state.sent.hasOperators
              ? Text(
                  state.sent.text(separator: decimalSeparator),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.body.copyWith(color: colors.textMuted),
                )
              : null,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AmountText(
            amountLabel(state.kind, state.sent, account.currency),
            style: styles.display.copyWith(color: colors.text),
          ),
        ),
      ],
    );
  }
}

/// One of the two amounts of a transfer between currencies.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.expression,
    required this.kind,
    required this.account,
    required this.active,
    required this.onTap,
  });

  final String label;
  final AmountExpression expression;
  final TransactionKind kind;
  final Account account;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BirkaTokens.spaceXxs),
          child: Row(
            children: [
              Text(
                label,
                style: styles.body.copyWith(
                  color: active ? colors.text : colors.textSubtle,
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AmountText(
                      amountLabel(kind, expression, account.currency),
                      style: styles.title.copyWith(
                        color: active ? colors.text : colors.textSubtle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The account, the day and the note.
class _Details extends StatelessWidget {
  const _Details({required this.state});

  final QuickAddState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuickAddCubit>();
    final day = state.day;
    final earlier = day != state.today && day != state.yesterday;
    return Wrap(
      spacing: BirkaTokens.spaceXs,
      runSpacing: BirkaTokens.spaceXs,
      children: [
        BirkaChip(
          glyph: BirkaGlyph.wallet,
          label: state.account?.name ?? t.transactions.account,
          selected: false,
          onTap: () => _pickAccount(context),
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
        if (earlier)
          BirkaChip(
            glyph: BirkaGlyph.calendar,
            label: dayLabel(day, today: state.today),
            selected: true,
            onTap: () => _pickDay(context),
          )
        else
          GlassIconButton(
            glyph: BirkaGlyph.calendar,
            label: t.transactions.pickDay,
            onPressed: () => _pickDay(context),
          ),
        BirkaChip(
          label: state.note.isEmpty
              ? '+ ${t.transactions.addNote}'
              : state.note,
          selected: false,
          dashed: state.note.isEmpty,
          onTap: () => _editNote(context),
        ),
      ],
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final cubit = context.read<QuickAddCubit>();
    final day = state.day;
    final today = state.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(day.year, day.month, day.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) cubit.dayChanged(CivilDate.of(picked));
  }

  Future<void> _pickAccount(BuildContext context) async {
    final cubit = context.read<QuickAddCubit>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => ChoiceSheet(
        title: t.transactions.account,
        children: [
          GlassListGroup(
            children: [
              for (final account in state.accounts)
                GlassListRow(
                  title: account.name,
                  subtitle: account.currency.code,
                  leading: CardArtThumbnail(
                    art: CardArt.values.byName(account.art.name),
                    highlighted: account.id == state.accountId,
                  ),
                  onTap: () => Navigator.of(context).pop(account.id),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked != null) cubit.accountChanged(picked);
  }

  Future<void> _editNote(BuildContext context) async {
    final cubit = context.read<QuickAddCubit>();
    final note = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => _NoteSheet(initial: state.note),
    );
    if (note != null) cubit.noteChanged(note);
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.initial});

  final String initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _note = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _done() => Navigator.of(context).pop(_note.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ChoiceSheet(
        children: [
          BirkaTextField(
            label: t.transactions.note,
            controller: _note,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(label: t.transactions.done, onPressed: _done),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.state, required this.onAddCategories});

  final QuickAddState state;
  final VoidCallback onAddCategories;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuickAddCubit>();
    if (state.categories.isEmpty) {
      return _Hint(
        text: t.transactions.noCategoriesHint,
        action: t.transactions.addCategories,
        onAction: onAddCategories,
      );
    }
    return QuickAddTiles(
      tiles: [
        for (final category in state.shown)
          _CategoryTile(
            category: category,
            selected: category.id == state.categoryId,
            onTap: () => cubit.categoryChanged(category.id),
          ),
        if (state.hasMoreCategories)
          QuickAddTile(
            label: t.transactions.more,
            picture: BirkaIcon(
              BirkaGlyph.dots,
              size: 24,
              color: BirkaColors.of(context).textMuted,
            ),
            selected: false,
            onTap: () => _pickFromAll(context),
          ),
      ],
    );
  }

  Future<void> _pickFromAll(BuildContext context) async {
    final cubit = context.read<QuickAddCubit>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => ChoiceSheet(
        title: t.transactions.allCategories,
        children: [
          QuickAddTiles(
            tiles: [
              for (final category in state.categories)
                _CategoryTile(
                  category: category,
                  selected: category.id == state.categoryId,
                  onTap: () => Navigator.of(context).pop(category.id),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked != null) cubit.categoryChanged(picked);
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return QuickAddTile(
      label: category.name,
      selected: selected,
      onTap: onTap,
      picture: BirkaIcon(
        BirkaGlyph.named(category.icon),
        size: 24,
        color: color == null
            ? BirkaColors.of(context).textMuted
            : BirkaColors.fromHex(color),
      ),
    );
  }
}

/// The accounts a transfer can go to.
class _Targets extends StatelessWidget {
  const _Targets({required this.state, required this.onAddAccount});

  final QuickAddState state;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuickAddCubit>();
    if (state.targets.isEmpty) {
      return _Hint(
        text: t.transactions.oneAccountHint,
        action: t.transactions.addAccount,
        onAction: onAddAccount,
      );
    }
    final colors = BirkaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.transactions.to,
          style: BirkaTextStyles.of(
            context,
          ).caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
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
      ],
    );
  }
}

/// A line in place of what is missing, with the way to add it.
class _Hint extends StatelessWidget {
  const _Hint({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: BirkaTextStyles.of(
            context,
          ).caption.copyWith(color: BirkaColors.of(context).textMuted),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        BirkaButton(label: action, quiet: true, onPressed: onAction),
      ],
    );
  }
}

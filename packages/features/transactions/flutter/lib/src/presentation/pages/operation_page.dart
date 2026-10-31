import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/delete_sheet.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_badge.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_row.dart';

/// The card of one operation, with what can be done to it.
///
/// It needs an [OperationCubit] above it.
class OperationPage extends StatelessWidget {
  /// Creates the page.
  const OperationPage({
    required this.onClose,
    required this.onEdit,
    required this.onRepeat,
    super.key,
  });

  /// Called by the way back, and when the operation is gone.
  final VoidCallback onClose;

  /// Called by the button that changes the operation.
  final VoidCallback onEdit;

  /// Called by the button that records it once more.
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<OperationCubit, OperationState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == OperationStatus.gone) onClose();
            },
            builder: (context, state) => ListView(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
              ),
              children: [
                _Header(
                  onClose: onClose,
                  onEdit: state.operation?.canChange ?? false ? onEdit : null,
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                ...switch (state) {
                  OperationState(status: OperationStatus.failed) => [
                    const _Failure(),
                  ],
                  OperationState(:final operation?) => [
                    _Summary(operation: operation, today: state.today),
                    const SizedBox(height: BirkaTokens.spaceLg),
                    _Facts(operation: operation, today: state.today),
                    const SizedBox(height: BirkaTokens.spaceLg),
                    if (state.deleteFailed) ...[
                      Text(
                        t.transactions.failedToDelete,
                        textAlign: TextAlign.center,
                        style: BirkaTextStyles.of(context).caption.copyWith(
                          color: BirkaColors.of(context).negative,
                        ),
                      ),
                      const SizedBox(height: BirkaTokens.spaceXs),
                    ],
                    _Actions(operation: operation, onRepeat: onRepeat),
                  ],
                  _ => const <Widget>[],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onEdit});

  final VoidCallback onClose;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final onEdit = this.onEdit;
    return Row(
      children: [
        GlassIconButton(
          glyph: BirkaGlyph.back,
          label: t.transactions.back,
          onPressed: onClose,
        ),
        Expanded(
          child: Center(
            child: SectionLabel(
              t.transactions.operation,
              color: BirkaColors.of(context).textMuted,
            ),
          ),
        ),
        // Keeps the label in the middle when the other side stays empty.
        if (onEdit == null)
          const SizedBox(width: BirkaTokens.sizeTouchTarget)
        else
          BirkaChip(
            label: t.transactions.edit,
            selected: false,
            onTap: onEdit,
          ),
      ],
    );
  }
}

/// The picture, the amount, the title and when it happened.
class _Summary extends StatelessWidget {
  const _Summary({required this.operation, required this.today});

  final Operation operation;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final at = operation.transaction.occurredAt;
    final day = dayHeading(operation.day, today: today);
    final received = operation.received;
    final twoAmounts =
        received != null && received.currency != operation.amount.currency;
    return Column(
      children: [
        OperationBadge(operation, size: 72),
        const SizedBox(height: BirkaTokens.spaceMd),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AmountText(
            twoAmounts
                ? '${operationAmount(operation)} → ${formatMoney(received)}'
                : operationAmount(operation),
            tone: operationTone(operation),
            style: styles.display,
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(
          operationTitle(operation),
          textAlign: TextAlign.center,
          style: styles.heading.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(
          [
            if (at == null) day else '$day, ${timeLabel(at)}',
            sourceLabel(operation.transaction.source),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: styles.body.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

/// The accounts, the category and the date. A note is the title already.
class _Facts extends StatelessWidget {
  const _Facts({required this.operation, required this.today});

  final Operation operation;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final category = operation.category;
    final account = operation.account;
    final toAccount = operation.toAccount;
    final transfer = operation.kind == TransactionKind.transfer;
    return GlassListGroup(
      children: [
        if (account != null)
          _Fact(
            label: transfer ? t.transactions.from : t.transactions.account,
            value: _accountLine(account),
          ),
        if (toAccount != null)
          _Fact(label: t.transactions.to, value: _accountLine(toAccount)),
        if (category != null)
          _Fact(label: t.transactions.category, value: category.name),
        _Fact(
          label: t.transactions.date,
          value: dayLabel(operation.day, today: today),
        ),
      ],
    );
  }

  static String _accountLine(Account account) {
    final digits = account.lastDigits;
    return digits == null ? account.name : '${account.name} · •• $digits';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(BirkaTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: styles.body.copyWith(color: colors.textMuted)),
          const SizedBox(width: BirkaTokens.spaceMd),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: styles.bodyStrong.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.operation, required this.onRepeat});

  final Operation operation;
  final VoidCallback onRepeat;

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<OperationCubit>();
    if (await confirmDelete(context, operation)) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (operation.canChange) ...[
          Expanded(
            child: _Action(
              glyph: BirkaGlyph.copy,
              label: t.transactions.repeat,
              onTap: onRepeat,
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
        ],
        Expanded(
          child: _Action(
            glyph: BirkaGlyph.trash,
            label: t.transactions.delete,
            danger: true,
            onTap: () => _delete(context),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final BirkaGlyph glyph;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final ink = danger ? colors.negative : colors.text;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          child: Column(
            children: [
              BirkaIcon(glyph, color: ink),
              const SizedBox(height: BirkaTokens.spaceXs),
              Text(
                label,
                style: BirkaTextStyles.of(
                  context,
                ).bodyStrong.copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.transactions.failedToReadOperations,
            style: BirkaTextStyles.of(
              context,
            ).body.copyWith(color: BirkaColors.of(context).text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: () => context.read<OperationCubit>().retry(),
          ),
        ],
      ),
    );
  }
}

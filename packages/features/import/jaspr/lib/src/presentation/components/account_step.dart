import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The fourth step: where each account of the file goes, an account of the
/// ledger, a new one or nowhere, and its balance held against the bank.
class AccountStep extends StatelessComponent {
  /// Creates the step of [state].
  const AccountStep({required this.state, super.key});

  /// The import.
  final ImportState state;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final statement = state.statement!;
    final names = newAccountNames(
      statement.accounts,
      state.layout?.format,
    );
    return div(classes: 'import-stack', [
      for (final source in statement.accounts)
        _source(cubit, statement, source, names[source.key]!),
    ]);
  }

  Component _source(
    ImportCubit cubit,
    Statement statement,
    SourceAccount source,
    String newName,
  ) {
    final choice = state.choices?.accounts[source.key];
    final fresh = switch (choice) {
      final NewAccount account => account,
      _ =>
        defaultAccount(
              source,
              const [],
              newName: newName,
              fallback: state.currency,
            )
            as NewAccount,
    };
    final currency = fresh.openingBalance.currency.code;
    return section(classes: 'import-section', [
      div(classes: 'import-heading', [
        h2(classes: 'text-heading import-heading__title', [
          .text(sourceTitle(source)),
        ]),
        p(classes: 'text-body import-heading__line', [
          .text(
            t.imports.accountText(
              operations: operationsLabel(source.operations),
            ),
          ),
        ]),
      ]),
      div(
        classes: 'import-accounts',
        attributes: {'role': 'radiogroup', 'aria-label': sourceTitle(source)},
        [
          for (final account in state.accounts)
            if (!account.archived)
              _account(cubit, source, account, choice, currency),
          GlassOption(
            leading: const span(classes: 'import-new-art', []),
            title: t.imports.newAccount,
            subtitle: t.imports.newAccountText(
              name: fresh.name,
              balance: formatMoney(fresh.openingBalance),
            ),
            selected: choice is NewAccount,
            onTap: () => cubit.chooseAccount(source.key, fresh),
          ),
          GlassOption(
            leading: const GlyphBadge(
              glyph: BirkaGlyph.close,
              color: 'var(--color-text-muted)',
            ),
            title: t.imports.leaveOut,
            subtitle: t.imports.leaveOutText,
            selected: choice is LeaveOut,
            onTap: () => cubit.chooseAccount(source.key, const LeaveOut()),
          ),
        ],
      ),
      ?_balance(statement, source),
    ]);
  }

  Component _account(
    ImportCubit cubit,
    SourceAccount source,
    Account account,
    AccountChoice? choice,
    String currency,
  ) {
    final own = account.openingBalance.currency.code;
    final other = own != currency;
    final digits = account.lastDigits;
    final balance = state.balances[account.id];
    final match = other ? null : matchOf(account, source);
    return GlassOption(
      leading: CardArtThumbnail(art: CardArt.values.byName(account.art.name)),
      title: account.name,
      badge: match == null ? null : matchLabel(match),
      subtitle: other
          ? t.imports.otherCurrency(
              currency: t.app.currencies[own] ?? own,
              fileCurrency: t.app.currencies[currency] ?? currency,
            )
          : accountLine(
              currency: own,
              type: account.type.name,
              lastDigits: digits,
            ),
      trailing: balance == null
          ? null
          : AmountText(formatMoney(balance), textClass: 'text-body-strong'),
      selected: choice is IntoAccount && choice.account.id == account.id,
      dimmed: other,
      onTap: () => cubit.chooseAccount(source.key, IntoAccount(account)),
    );
  }

  /// The balance of [source] in the statement against the one after the
  /// import, when the file gives it.
  Component? _balance(Statement statement, SourceAccount source) {
    final closing = source.closing;
    final after = state.plan?.balances[source.key];
    final last = statement.to;
    if (closing == null || after == null || last == null) return null;
    final bank = bankBalance(source, after);
    final matches = bank == after;
    return div(
      classes: matches
          ? 'glass import-balance import-balance--matches'
          : 'glass import-balance',
      [
        span(classes: 'import-balance__mark', [
          BirkaIcon(matches ? BirkaGlyph.check : BirkaGlyph.close),
        ]),
        div(classes: 'import-balance__text', [
          span(classes: 'text-body-strong import-balance__title', [
            .text(
              matches ? t.imports.balanceMatches : t.imports.balanceDiffers,
            ),
          ]),
          div(classes: 'import-balance__values', [
            _value(
              t.imports.balanceInFile(
                day: dayLabel(last, thisYear: last.year),
              ),
              bank,
            ),
            _value(t.imports.balanceInBirka, after),
          ]),
          if (!matches)
            span(classes: 'text-caption import-balance__hint', [
              .text(t.imports.balanceHint),
            ]),
        ]),
      ],
    );
  }

  Component _value(String label, Money? amount) {
    return div(classes: 'import-balance__value', [
      span(classes: 'text-caption import-balance__label', [.text(label)]),
      AmountText(amount == null ? '—' : formatMoney(amount)),
    ]);
  }

  /// The styles of the step.
  @css
  static List<StyleRule> get styles => [
    css('.import-heading').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.import-heading__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.import-heading__line').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.import-accounts').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-new-art').styles(
      raw: {
        'background':
            'repeating-linear-gradient(135deg, var(--color-surface-raised) 0 '
            '6px, transparent 6px 12px)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-xs)',
        'flex': 'none',
        'height': '32px',
        'width': '52px',
      },
    ),
    css('.import-balance').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import-balance--matches').styles(
      raw: {
        'background':
            'linear-gradient(160deg, var(--color-accent-soft) 0%, '
            'var(--color-glass-fill-bottom) 100%)',
      },
    ),
    css('.import-balance__mark').styles(
      raw: {
        'align-items': 'center',
        'background':
            'color-mix(in srgb, var(--color-negative) 16%, transparent)',
        'border-radius': 'var(--radius-sm)',
        'color': 'var(--color-negative)',
        'display': 'flex',
        'flex': 'none',
        'height': '40px',
        'justify-content': 'center',
        'width': '40px',
      },
    ),
    css('.import-balance--matches .import-balance__mark').styles(
      raw: {
        'background': 'var(--color-accent-soft)',
        'color': 'var(--color-accent)',
      },
    ),
    css('.import-balance__mark .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    css('.import-balance__text').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.import-balance__title').styles(raw: {'color': 'var(--color-text)'}),
    css('.import-balance__values').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-sm) var(--space-xl)',
      },
    ),
    css('.import-balance__value').styles(
      raw: {'display': 'flex', 'flex-direction': 'column'},
    ),
    css('.import-balance__label, .import-balance__hint').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
  ];
}

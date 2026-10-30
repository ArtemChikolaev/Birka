///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element

class Translations with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => Translations(meta: meta ?? this.$meta);

  // Translations
  late final Translations$accounts$en accounts =
      Translations$accounts$en.internal(_root);
  late final Translations$app$en app = Translations$app$en.internal(_root);
}

// Path: accounts
class Translations$accounts$en {
  Translations$accounts$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Accounts'
  String get title => 'Accounts';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Add account'
  String get add => 'Add account';

  /// en: 'Capital'
  String get capital => 'Capital';

  /// en: 'and'
  String get and => 'and';

  /// en: '(one) {in $n account} (other) {in $n accounts}'
  String inAccounts({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'in ${n} account',
        other: 'in ${n} accounts',
      );

  /// en: 'main'
  String get main => 'main';

  /// en: 'No accounts yet'
  String get emptyTitle => 'No accounts yet';

  /// en: 'Add the first one to see where your money is.'
  String get emptyHint => 'Add the first one to see where your money is.';

  /// en: 'Archive'
  String get archive => 'Archive';

  /// en: 'Could not read the accounts.'
  String get failed => 'Could not read the accounts.';

  /// en: 'Try again'
  String get retry => 'Try again';

  Map<String, String> get types => {
    'cash': 'Cash',
    'debit': 'Debit card',
    'credit': 'Credit card',
    'savings': 'Savings',
    'deposit': 'Deposit',
    'loan': 'Loan',
    'debt': 'Debt',
    'investment': 'Investments',
    'crypto': 'Crypto wallet',
  };
  late final Translations$accounts$form$en form =
      Translations$accounts$form$en.internal(_root);
}

// Path: app
class Translations$app$en {
  Translations$app$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Overview'
  String get overview => 'Overview';

  /// en: 'Operations'
  String get operations => 'Operations';

  /// en: 'Reports'
  String get reports => 'Reports';

  /// en: 'More'
  String get more => 'More';

  /// en: 'New operation'
  String get newOperation => 'New operation';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'This screen is coming soon.'
  String get comingSoon => 'This screen is coming soon.';

  /// en: 'soon'
  String get soon => 'soon';

  Map<String, String> get currencies => {
    'RUB': 'Rubles',
    'USD': 'Dollars',
    'EUR': 'Euro',
    'USDT': 'USDT',
    'GEL': 'Lari',
    'TRY': 'Lira',
    'KZT': 'Tenge',
    'AED': 'Dirhams',
    'THB': 'Baht',
  };

  /// en: 'Categories'
  String get categories => 'Categories';

  /// en: 'Import'
  String get import => 'Import';

  /// en: 'Backup'
  String get backup => 'Backup';
}

// Path: accounts.form
class Translations$accounts$form$en {
  Translations$accounts$form$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'New account'
  String get newTitle => 'New account';

  /// en: 'Account'
  String get editTitle => 'Account';

  /// en: 'Name'
  String get name => 'Name';

  /// en: 'Salary card'
  String get namePlaceholder => 'Salary card';

  /// en: 'Type'
  String get type => 'Type';

  /// en: 'Currency'
  String get currency => 'Currency';

  /// en: 'Balance now'
  String get openingBalance => 'Balance now';

  /// en: 'Debt on the card'
  String get debt => 'Debt on the card';

  /// en: 'Last 4 digits of the card'
  String get lastDigits => 'Last 4 digits of the card';

  /// en: 'Look'
  String get art => 'Look';

  /// en: 'Count in the capital'
  String get includeInTotals => 'Count in the capital';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Move to the archive'
  String get archive => 'Move to the archive';

  /// en: 'Bring back from the archive'
  String get restore => 'Bring back from the archive';

  /// en: 'Give the account a name.'
  String get nameMissing => 'Give the account a name.';

  /// en: 'Enter an amount, such as 1250.50.'
  String get amountInvalid => 'Enter an amount, such as 1250.50.';

  /// en: 'Enter four digits.'
  String get lastDigitsInvalid => 'Enter four digits.';

  /// en: 'Could not save. Try again.'
  String get failed => 'Could not save. Try again.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'accounts.title' => 'Accounts',
      'accounts.back' => 'Back',
      'accounts.add' => 'Add account',
      'accounts.capital' => 'Capital',
      'accounts.and' => 'and',
      'accounts.inAccounts' =>
        ({required num n}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              n,
              one: 'in ${n} account',
              other: 'in ${n} accounts',
            ),
      'accounts.main' => 'main',
      'accounts.emptyTitle' => 'No accounts yet',
      'accounts.emptyHint' => 'Add the first one to see where your money is.',
      'accounts.archive' => 'Archive',
      'accounts.failed' => 'Could not read the accounts.',
      'accounts.retry' => 'Try again',
      'accounts.types.cash' => 'Cash',
      'accounts.types.debit' => 'Debit card',
      'accounts.types.credit' => 'Credit card',
      'accounts.types.savings' => 'Savings',
      'accounts.types.deposit' => 'Deposit',
      'accounts.types.loan' => 'Loan',
      'accounts.types.debt' => 'Debt',
      'accounts.types.investment' => 'Investments',
      'accounts.types.crypto' => 'Crypto wallet',
      'accounts.form.newTitle' => 'New account',
      'accounts.form.editTitle' => 'Account',
      'accounts.form.name' => 'Name',
      'accounts.form.namePlaceholder' => 'Salary card',
      'accounts.form.type' => 'Type',
      'accounts.form.currency' => 'Currency',
      'accounts.form.openingBalance' => 'Balance now',
      'accounts.form.debt' => 'Debt on the card',
      'accounts.form.lastDigits' => 'Last 4 digits of the card',
      'accounts.form.art' => 'Look',
      'accounts.form.includeInTotals' => 'Count in the capital',
      'accounts.form.save' => 'Save',
      'accounts.form.archive' => 'Move to the archive',
      'accounts.form.restore' => 'Bring back from the archive',
      'accounts.form.nameMissing' => 'Give the account a name.',
      'accounts.form.amountInvalid' => 'Enter an amount, such as 1250.50.',
      'accounts.form.lastDigitsInvalid' => 'Enter four digits.',
      'accounts.form.failed' => 'Could not save. Try again.',
      'app.overview' => 'Overview',
      'app.operations' => 'Operations',
      'app.reports' => 'Reports',
      'app.more' => 'More',
      'app.newOperation' => 'New operation',
      'app.close' => 'Close',
      'app.comingSoon' => 'This screen is coming soon.',
      'app.soon' => 'soon',
      'app.currencies.RUB' => 'Rubles',
      'app.currencies.USD' => 'Dollars',
      'app.currencies.EUR' => 'Euro',
      'app.currencies.USDT' => 'USDT',
      'app.currencies.GEL' => 'Lari',
      'app.currencies.TRY' => 'Lira',
      'app.currencies.KZT' => 'Tenge',
      'app.currencies.AED' => 'Dirhams',
      'app.currencies.THB' => 'Baht',
      'app.categories' => 'Categories',
      'app.import' => 'Import',
      'app.backup' => 'Backup',
      _ => null,
    };
  }
}

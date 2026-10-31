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
  late final Translations$categories$en categories =
      Translations$categories$en.internal(_root);
  late final Translations$transactions$en transactions =
      Translations$transactions$en.internal(_root);
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

  /// en: 'Try again'
  String get retry => 'Try again';

  /// en: 'Your data stays in this browser and nowhere else.'
  String get storedHere => 'Your data stays in this browser and nowhere else.';

  /// en: 'This browser cannot keep data, so it goes when you close the tab.'
  String get notStored =>
      'This browser cannot keep data, so it goes when you close the tab.';

  /// en: 'Birka is open in another tab. Close it and try again.'
  String get openElsewhere =>
      'Birka is open in another tab. Close it and try again.';

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

  /// en: 'Import'
  String get import => 'Import';

  /// en: 'Backup'
  String get backup => 'Backup';
}

// Path: categories
class Translations$categories$en {
  Translations$categories$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Categories'
  String get title => 'Categories';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Add category'
  String get add => 'Add category';

  /// en: 'Expenses'
  String get expense => 'Expenses';

  /// en: 'Income'
  String get income => 'Income';

  /// en: 'No categories yet'
  String get emptyTitle => 'No categories yet';

  /// en: 'Take a ready set or make your own.'
  String get emptyHint => 'Take a ready set or make your own.';

  /// en: 'Add a ready set'
  String get addPresets => 'Add a ready set';

  /// en: 'Make my own'
  String get addOwn => 'Make my own';

  /// en: 'Archive'
  String get archive => 'Archive';

  /// en: 'Could not read the categories.'
  String get failed => 'Could not read the categories.';

  /// en: '(one) {$n subcategory} (other) {$n subcategories}'
  String subcategories({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} subcategory',
        other: '${n} subcategories',
      );

  Map<String, String> get presets => {
    'groceries': 'Groceries',
    'cafe': 'Cafes',
    'transport': 'Transport',
    'home': 'Home',
    'health': 'Health',
    'leisure': 'Leisure',
    'subscriptions': 'Subscriptions',
    'clothes': 'Clothes',
    'travel': 'Travel',
    'education': 'Education',
    'gifts': 'Gifts',
    'salary': 'Salary',
    'freelance': 'Freelance',
    'interest': 'Interest',
    'giftsReceived': 'Gifts',
  };
  late final Translations$categories$form$en form =
      Translations$categories$form$en.internal(_root);
}

// Path: transactions
class Translations$transactions$en {
  Translations$transactions$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Expense'
  String get expense => 'Expense';

  /// en: 'Income'
  String get income => 'Income';

  /// en: 'Transfer'
  String get transfer => 'Transfer';

  /// en: 'Correction'
  String get adjustment => 'Correction';

  /// en: 'Today'
  String get today => 'Today';

  /// en: 'Yesterday'
  String get yesterday => 'Yesterday';

  /// en: 'Pick a day'
  String get pickDay => 'Pick a day';

  /// en: 'Note'
  String get note => 'Note';

  /// en: 'Note'
  String get addNote => 'Note';

  /// en: 'Done'
  String get done => 'Done';

  /// en: 'Account'
  String get account => 'Account';

  /// en: 'To'
  String get to => 'To';

  /// en: 'Leaves'
  String get sent => 'Leaves';

  /// en: 'Arrives'
  String get received => 'Arrives';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'More'
  String get more => 'More';

  /// en: 'All categories'
  String get allCategories => 'All categories';

  /// en: 'Could not save. Try again.'
  String get failed => 'Could not save. Try again.';

  /// en: 'Could not read the accounts and categories.'
  String get failedToRead => 'Could not read the accounts and categories.';

  /// en: 'No accounts yet'
  String get noAccountsTitle => 'No accounts yet';

  /// en: 'Add an account to record where the money goes.'
  String get noAccountsHint => 'Add an account to record where the money goes.';

  /// en: 'Add account'
  String get addAccount => 'Add account';

  /// en: 'A transfer needs a second account.'
  String get oneAccountHint => 'A transfer needs a second account.';

  /// en: 'Add categories to sort your money.'
  String get noCategoriesHint => 'Add categories to sort your money.';

  /// en: 'Add categories'
  String get addCategories => 'Add categories';

  /// en: 'Search'
  String get search => 'Search';

  /// en: 'Cafe, 250 or a note'
  String get searchHint => 'Cafe, 250 or a note';

  /// en: 'Clear the search'
  String get clearSearch => 'Clear the search';

  /// en: 'All'
  String get filterAll => 'All';

  /// en: 'Expenses'
  String get filterExpenses => 'Expenses';

  /// en: 'Income'
  String get filterIncome => 'Income';

  /// en: 'Transfers'
  String get filterTransfers => 'Transfers';

  /// en: 'Pick a month'
  String get pickMonth => 'Pick a month';

  /// en: 'No operations yet'
  String get noOperationsTitle => 'No operations yet';

  /// en: 'Tap the plus below to record the first one.'
  String get noOperationsHint => 'Tap the plus below to record the first one.';

  /// en: 'Nothing found'
  String get nothingFound => 'Nothing found';

  /// en: 'Could not read the operations.'
  String get failedToReadOperations => 'Could not read the operations.';

  /// en: 'Could not delete. Try again.'
  String get failedToDelete => 'Could not delete. Try again.';

  /// en: 'Operation'
  String get operation => 'Operation';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'Edit operation'
  String get editOperation => 'Edit operation';

  /// en: 'Repeat'
  String get repeat => 'Repeat';

  /// en: 'Delete'
  String get delete => 'Delete';

  /// en: 'Delete this operation?'
  String get deleteTitle => 'Delete this operation?';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Category'
  String get category => 'Category';

  /// en: 'From'
  String get from => 'From';

  /// en: 'Date'
  String get date => 'Date';

  late final Translations$transactions$sources$en sources =
      Translations$transactions$sources$en.internal(_root);
  late final Translations$transactions$keys$en keys =
      Translations$transactions$keys$en.internal(_root);

  /// en: '$month $day'
  String dayOfMonth({required Object month, required Object day}) =>
      '${month} ${day}';

  List<String> get months => [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  List<String> get monthNames => [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
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

// Path: categories.form
class Translations$categories$form$en {
  Translations$categories$form$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'New category'
  String get newTitle => 'New category';

  /// en: 'Category'
  String get editTitle => 'Category';

  /// en: 'Name'
  String get name => 'Name';

  /// en: 'Groceries'
  String get namePlaceholder => 'Groceries';

  /// en: 'Type'
  String get kind => 'Type';

  /// en: 'Inside'
  String get parent => 'Inside';

  /// en: 'On its own'
  String get noParent => 'On its own';

  /// en: 'Color'
  String get color => 'Color';

  /// en: 'Icon'
  String get icon => 'Icon';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Move to the archive'
  String get archive => 'Move to the archive';

  /// en: 'Bring back from the archive'
  String get restore => 'Bring back from the archive';

  /// en: 'Give the category a name.'
  String get nameMissing => 'Give the category a name.';

  /// en: 'Could not save. Try again.'
  String get failed => 'Could not save. Try again.';
}

// Path: transactions.sources
class Translations$transactions$sources$en {
  Translations$transactions$sources$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Manually'
  String get manual => 'Manually';

  /// en: 'Imported'
  String get import => 'Imported';

  /// en: 'From a notification'
  String get notification => 'From a notification';

  /// en: 'Recurring'
  String get recurring => 'Recurring';

  /// en: 'From the bank'
  String get bank => 'From the bank';
}

// Path: transactions.keys
class Translations$transactions$keys$en {
  Translations$transactions$keys$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Point'
  String get point => 'Point';

  /// en: 'Plus'
  String get add => 'Plus';

  /// en: 'Minus'
  String get subtract => 'Minus';

  /// en: 'Times'
  String get multiply => 'Times';

  /// en: 'Divided by'
  String get divide => 'Divided by';

  /// en: 'Erase'
  String get backspace => 'Erase';
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
      'app.retry' => 'Try again',
      'app.storedHere' => 'Your data stays in this browser and nowhere else.',
      'app.notStored' =>
        'This browser cannot keep data, so it goes when you close the tab.',
      'app.openElsewhere' =>
        'Birka is open in another tab. Close it and try again.',
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
      'app.import' => 'Import',
      'app.backup' => 'Backup',
      'categories.title' => 'Categories',
      'categories.back' => 'Back',
      'categories.add' => 'Add category',
      'categories.expense' => 'Expenses',
      'categories.income' => 'Income',
      'categories.emptyTitle' => 'No categories yet',
      'categories.emptyHint' => 'Take a ready set or make your own.',
      'categories.addPresets' => 'Add a ready set',
      'categories.addOwn' => 'Make my own',
      'categories.archive' => 'Archive',
      'categories.failed' => 'Could not read the categories.',
      'categories.subcategories' =>
        ({required num n}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              n,
              one: '${n} subcategory',
              other: '${n} subcategories',
            ),
      'categories.presets.groceries' => 'Groceries',
      'categories.presets.cafe' => 'Cafes',
      'categories.presets.transport' => 'Transport',
      'categories.presets.home' => 'Home',
      'categories.presets.health' => 'Health',
      'categories.presets.leisure' => 'Leisure',
      'categories.presets.subscriptions' => 'Subscriptions',
      'categories.presets.clothes' => 'Clothes',
      'categories.presets.travel' => 'Travel',
      'categories.presets.education' => 'Education',
      'categories.presets.gifts' => 'Gifts',
      'categories.presets.salary' => 'Salary',
      'categories.presets.freelance' => 'Freelance',
      'categories.presets.interest' => 'Interest',
      'categories.presets.giftsReceived' => 'Gifts',
      'categories.form.newTitle' => 'New category',
      'categories.form.editTitle' => 'Category',
      'categories.form.name' => 'Name',
      'categories.form.namePlaceholder' => 'Groceries',
      'categories.form.kind' => 'Type',
      'categories.form.parent' => 'Inside',
      'categories.form.noParent' => 'On its own',
      'categories.form.color' => 'Color',
      'categories.form.icon' => 'Icon',
      'categories.form.save' => 'Save',
      'categories.form.archive' => 'Move to the archive',
      'categories.form.restore' => 'Bring back from the archive',
      'categories.form.nameMissing' => 'Give the category a name.',
      'categories.form.failed' => 'Could not save. Try again.',
      'transactions.expense' => 'Expense',
      'transactions.income' => 'Income',
      'transactions.transfer' => 'Transfer',
      'transactions.adjustment' => 'Correction',
      'transactions.today' => 'Today',
      'transactions.yesterday' => 'Yesterday',
      'transactions.pickDay' => 'Pick a day',
      'transactions.note' => 'Note',
      'transactions.addNote' => 'Note',
      'transactions.done' => 'Done',
      'transactions.account' => 'Account',
      'transactions.to' => 'To',
      'transactions.sent' => 'Leaves',
      'transactions.received' => 'Arrives',
      'transactions.save' => 'Save',
      'transactions.more' => 'More',
      'transactions.allCategories' => 'All categories',
      'transactions.failed' => 'Could not save. Try again.',
      'transactions.failedToRead' =>
        'Could not read the accounts and categories.',
      'transactions.noAccountsTitle' => 'No accounts yet',
      'transactions.noAccountsHint' =>
        'Add an account to record where the money goes.',
      'transactions.addAccount' => 'Add account',
      'transactions.oneAccountHint' => 'A transfer needs a second account.',
      'transactions.noCategoriesHint' => 'Add categories to sort your money.',
      'transactions.addCategories' => 'Add categories',
      'transactions.search' => 'Search',
      'transactions.searchHint' => 'Cafe, 250 or a note',
      'transactions.clearSearch' => 'Clear the search',
      'transactions.filterAll' => 'All',
      'transactions.filterExpenses' => 'Expenses',
      'transactions.filterIncome' => 'Income',
      'transactions.filterTransfers' => 'Transfers',
      'transactions.pickMonth' => 'Pick a month',
      'transactions.noOperationsTitle' => 'No operations yet',
      'transactions.noOperationsHint' =>
        'Tap the plus below to record the first one.',
      'transactions.nothingFound' => 'Nothing found',
      'transactions.failedToReadOperations' => 'Could not read the operations.',
      'transactions.failedToDelete' => 'Could not delete. Try again.',
      'transactions.operation' => 'Operation',
      'transactions.edit' => 'Edit',
      'transactions.editOperation' => 'Edit operation',
      'transactions.repeat' => 'Repeat',
      'transactions.delete' => 'Delete',
      'transactions.deleteTitle' => 'Delete this operation?',
      'transactions.cancel' => 'Cancel',
      'transactions.back' => 'Back',
      'transactions.category' => 'Category',
      'transactions.from' => 'From',
      'transactions.date' => 'Date',
      'transactions.sources.manual' => 'Manually',
      'transactions.sources.import' => 'Imported',
      'transactions.sources.notification' => 'From a notification',
      'transactions.sources.recurring' => 'Recurring',
      'transactions.sources.bank' => 'From the bank',
      'transactions.keys.point' => 'Point',
      'transactions.keys.add' => 'Plus',
      'transactions.keys.subtract' => 'Minus',
      'transactions.keys.multiply' => 'Times',
      'transactions.keys.divide' => 'Divided by',
      'transactions.keys.backspace' => 'Erase',
      'transactions.dayOfMonth' =>
        ({required Object month, required Object day}) => '${month} ${day}',
      'transactions.months.0' => 'January',
      'transactions.months.1' => 'February',
      'transactions.months.2' => 'March',
      'transactions.months.3' => 'April',
      'transactions.months.4' => 'May',
      'transactions.months.5' => 'June',
      'transactions.months.6' => 'July',
      'transactions.months.7' => 'August',
      'transactions.months.8' => 'September',
      'transactions.months.9' => 'October',
      'transactions.months.10' => 'November',
      'transactions.months.11' => 'December',
      'transactions.monthNames.0' => 'January',
      'transactions.monthNames.1' => 'February',
      'transactions.monthNames.2' => 'March',
      'transactions.monthNames.3' => 'April',
      'transactions.monthNames.4' => 'May',
      'transactions.monthNames.5' => 'June',
      'transactions.monthNames.6' => 'July',
      'transactions.monthNames.7' => 'August',
      'transactions.monthNames.8' => 'September',
      'transactions.monthNames.9' => 'October',
      'transactions.monthNames.10' => 'November',
      'transactions.monthNames.11' => 'December',
      _ => null,
    };
  }
}

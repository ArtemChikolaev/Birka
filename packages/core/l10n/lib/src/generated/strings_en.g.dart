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
  late final Translations$backup$en backup = Translations$backup$en.internal(
    _root,
  );
  late final Translations$categories$en categories =
      Translations$categories$en.internal(_root);
  late final Translations$demo$en demo = Translations$demo$en.internal(_root);
  late final Translations$help$en help = Translations$help$en.internal(_root);
  late final Translations$imports$en imports = Translations$imports$en.internal(
    _root,
  );
  late final Translations$inbox$en inbox = Translations$inbox$en.internal(
    _root,
  );
  late final Translations$onboarding$en onboarding =
      Translations$onboarding$en.internal(_root);
  late final Translations$overview$en overview =
      Translations$overview$en.internal(_root);
  late final Translations$reports$en reports = Translations$reports$en.internal(
    _root,
  );
  late final Translations$settings$en settings =
      Translations$settings$en.internal(_root);
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

  /// en: 'soon'
  String get soon => 'soon';

  /// en: 'No category'
  String get noCategory => 'No category';

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

  /// en: 'Data'
  String get data => 'Data';

  /// en: 'Support'
  String get support => 'Support';

  /// en: 'Help and feedback'
  String get help => 'Help and feedback';

  /// en: 'your data stays on this device'
  String get keptOnDevice => 'your data stays on this device';

  /// en: 'your data stays in this browser'
  String get keptInBrowser => 'your data stays in this browser';

  /// en: 'Source code on GitHub'
  String get sourceCode => 'Source code on GitHub';
}

// Path: backup
class Translations$backup$en {
  Translations$backup$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Data'
  String get title => 'Data';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Your records live here'
  String get storedTitle => 'Your records live here';

  /// en: 'Only on this device, with no servers. A copy in a file helps you move them or keep them safe.'
  String get storedText =>
      'Only on this device, with no servers. A copy in a file helps you move them or keep them safe.';

  /// en: 'No copy yet'
  String get noCopyYet => 'No copy yet';

  /// en: 'Last copy: $when'
  String lastCopy({required Object when}) => 'Last copy: ${when}';

  /// en: 'today at $time'
  String todayAt({required Object time}) => 'today at ${time}';

  /// en: 'yesterday at $time'
  String yesterdayAt({required Object time}) => 'yesterday at ${time}';

  /// en: '$day at $time'
  String dayAt({required Object day, required Object time}) =>
      '${day} at ${time}';

  /// en: 'Operations'
  String get operations => 'Operations';

  /// en: 'Accounts'
  String get accounts => 'Accounts';

  /// en: 'Categories'
  String get categories => 'Categories';

  /// en: 'Save a copy'
  String get save => 'Save a copy';

  /// en: 'Restore from a copy'
  String get restore => 'Restore from a copy';

  /// en: 'Export'
  String get export => 'Export';

  /// en: 'Operations as CSV'
  String get exportTitle => 'Operations as CSV';

  /// en: 'For Excel and Google Sheets: date, amount, currency, account, category'
  String get exportText =>
      'For Excel and Google Sheets: date, amount, currency, account, category';

  /// en: 'Records'
  String get records => 'Records';

  /// en: 'Demo data'
  String get demo => 'Demo data';

  /// en: 'Sample accounts and operations to look around'
  String get demoText => 'Sample accounts and operations to look around';

  /// en: 'Delete all data'
  String get wipe => 'Delete all data';

  /// en: 'Files go only where you point in the window of the system.'
  String get filesNote =>
      'Files go only where you point in the window of the system.';

  /// en: 'Files go where the browser keeps its downloads.'
  String get filesNoteSite => 'Files go where the browser keeps its downloads.';

  /// en: 'Restore from a copy?'
  String get restoreTitle => 'Restore from a copy?';

  /// en: 'The records on this device will give way to the contents of the file. This cannot be undone, so save a copy of the current ones first if you need them.'
  String get restoreText =>
      'The records on this device will give way to the contents of the file. This cannot be undone, so save a copy of the current ones first if you need them.';

  /// en: 'Replace the records'
  String get replace => 'Replace the records';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Delete all data?'
  String get wipeTitle => 'Delete all data?';

  /// en: 'Accounts, operations and categories will disappear from this device. The language and other settings will stay. Without a copy, the records cannot come back.'
  String get wipeText =>
      'Accounts, operations and categories will disappear from this device. The language and other settings will stay. Without a copy, the records cannot come back.';

  /// en: 'Save a copy first'
  String get saveFirst => 'Save a copy first';

  /// en: 'Delete everything'
  String get wipeAll => 'Delete everything';

  /// en: 'Copy saved: $name'
  String saved({required Object name}) => 'Copy saved: ${name}';

  /// en: 'Records restored from the copy of $day'
  String restored({required Object day}) =>
      'Records restored from the copy of ${day}';

  /// en: 'File saved: $name'
  String exported({required Object name}) => 'File saved: ${name}';

  /// en: 'All data is gone from this device'
  String get wiped => 'All data is gone from this device';

  /// en: 'This is not a copy of Birka.'
  String get notACopy => 'This is not a copy of Birka.';

  /// en: 'A newer version of Birka made this copy. Update the app and try again.'
  String get newer =>
      'A newer version of Birka made this copy. Update the app and try again.';

  /// en: 'This copy is damaged and cannot be restored.'
  String get damaged => 'This copy is damaged and cannot be restored.';

  /// en: 'That did not work. Try again.'
  String get failed => 'That did not work. Try again.';

  /// en: '(one) {$count operation} (other) {$count operations}'
  String operationsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} operation',
        other: '${count} operations',
      );

  /// en: '(one) {$count account} (other) {$count accounts}'
  String accountsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} account',
        other: '${count} accounts',
      );

  late final Translations$backup$csv$en csv =
      Translations$backup$csv$en.internal(_root);
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

// Path: demo
class Translations$demo$en {
  Translations$demo$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Salary card'
  String get card => 'Salary card';

  /// en: 'Cash'
  String get cash => 'Cash';

  /// en: 'Savings'
  String get savings => 'Savings';

  /// en: 'Euro card'
  String get euro => 'Euro card';

  /// en: 'Advance'
  String get advance => 'Advance';

  /// en: 'Salary'
  String get salary => 'Salary';

  /// en: 'Side project'
  String get project => 'Side project';

  /// en: 'Interest on the balance'
  String get interest => 'Interest on the balance';

  /// en: 'Supermarket'
  String get supermarket => 'Supermarket';

  /// en: 'Market'
  String get market => 'Market';

  /// en: 'Bakery'
  String get bakery => 'Bakery';

  /// en: 'Coffee shop'
  String get coffee => 'Coffee shop';

  /// en: 'Lunch with colleagues'
  String get lunch => 'Lunch with colleagues';

  /// en: 'Metro'
  String get metro => 'Metro';

  /// en: 'Taxi'
  String get taxi => 'Taxi';

  /// en: 'Utilities'
  String get utilities => 'Utilities';

  /// en: 'Phone and internet'
  String get phone => 'Phone and internet';

  /// en: 'Music'
  String get music => 'Music';

  /// en: 'Movies and shows'
  String get movies => 'Movies and shows';

  /// en: 'Pharmacy'
  String get pharmacy => 'Pharmacy';

  /// en: 'Cinema'
  String get cinema => 'Cinema';

  /// en: 'Concert'
  String get concert => 'Concert';

  /// en: 'Clothes'
  String get clothes => 'Clothes';

  /// en: 'Gift'
  String get gift => 'Gift';

  /// en: 'Hotel'
  String get hotel => 'Hotel';

  /// en: 'Trip'
  String get trip => 'Trip';

  /// en: 'Cash withdrawal'
  String get toCash => 'Cash withdrawal';

  /// en: 'To savings'
  String get toSavings => 'To savings';

  /// en: 'Euros for the trip'
  String get toEuro => 'Euros for the trip';
}

// Path: help
class Translations$help$en {
  Translations$help$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Help'
  String get title => 'Help';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Search the help'
  String get search => 'Search the help';

  /// en: 'Clear the search'
  String get clearSearch => 'Clear the search';

  /// en: 'Common questions'
  String get questions => 'Common questions';

  /// en: 'Nothing found. Write to the developer: the answer will help others too and will appear here.'
  String get nothingFound =>
      'Nothing found. Write to the developer: the answer will help others too and will appear here.';

  /// en: 'Where is my data kept?'
  String get storageQuestion => 'Where is my data kept?';

  /// en: 'Only on this device or in this browser. Birka sends no records to a server and never asks for bank passwords.'
  String get storageAnswer =>
      'Only on this device or in this browser. Birka sends no records to a server and never asks for bank passwords.';

  /// en: 'How do I move my records to another device?'
  String get moveQuestion => 'How do I move my records to another device?';

  /// en: 'Save a copy in More → Data, send the file to yourself and restore it on the new device. Sync comes later.'
  String get moveAnswer =>
      'Save a copy in More → Data, send the file to yourself and restore it on the new device. Sync comes later.';

  /// en: 'Where do the exchange rates come from?'
  String get ratesQuestion => 'Where do the exchange rates come from?';

  /// en: 'They are the rates of the Bank of Russia on the day of the operation. They update once a day and stay on the device.'
  String get ratesAnswer =>
      'They are the rates of the Bank of Russia on the day of the operation. They update once a day and stay on the device.';

  /// en: 'Can I load operations from my bank?'
  String get importQuestion => 'Can I load operations from my bank?';

  /// en: 'For now operations go in by hand. Loading bank statements is the next big feature.'
  String get importAnswer =>
      'For now operations go in by hand. Loading bank statements is the next big feature.';

  /// en: 'How do I hide the amounts?'
  String get hideQuestion => 'How do I hide the amounts?';

  /// en: 'Tap the eye on Overview. To keep them hidden from the start, turn on Hide amounts in More.'
  String get hideAnswer =>
      'Tap the eye on Overview. To keep them hidden from the start, turn on Hide amounts in More.';

  /// en: 'Contact'
  String get contact => 'Contact';

  /// en: 'Write to the developer'
  String get write => 'Write to the developer';

  /// en: 'Your mail app opens'
  String get writeText => 'Your mail app opens';

  /// en: 'Report a bug'
  String get bug => 'Report a bug';

  /// en: 'The letter gets the version and the system, none of your records'
  String get bugText =>
      'The letter gets the version and the system, none of your records';

  /// en: 'Suggest an idea'
  String get idea => 'Suggest an idea';

  /// en: 'Tell what Birka lacks'
  String get ideaText => 'Tell what Birka lacks';

  /// en: 'Bugs and ideas on GitHub'
  String get github => 'Bugs and ideas on GitHub';

  /// en: 'Public: leave out amounts and account names'
  String get githubText => 'Public: leave out amounts and account names';

  /// en: 'A letter to the developer'
  String get letterTitle => 'A letter to the developer';

  /// en: 'Your mail app opens with this letter. It holds only what you see below, and you can add to it.'
  String get letterText =>
      'Your mail app opens with this letter. It holds only what you see below, and you can add to it.';

  /// en: 'To'
  String get to => 'To';

  /// en: 'Subject'
  String get subject => 'Subject';

  /// en: 'Operations, amounts and account names stay out of the letter.'
  String get letterPrivacy =>
      'Operations, amounts and account names stay out of the letter.';

  /// en: 'Open mail'
  String get openMail => 'Open mail';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Birka · question'
  String get questionSubject => 'Birka · question';

  /// en: 'Birka $version · bug'
  String bugSubject({required Object version}) => 'Birka ${version} · bug';

  /// en: 'Birka · idea'
  String get ideaSubject => 'Birka · idea';

  /// en: 'Hello! '
  String get questionBody => 'Hello!\n';

  /// en: 'What happened: What you expected:'
  String get bugBody => 'What happened:\n\nWhat you expected:';

  /// en: 'What is missing: How it would help:'
  String get ideaBody => 'What is missing:\n\nHow it would help:';

  /// en: 'English'
  String get language => 'English';

  /// en: 'Birka $version · $system · $language'
  String about({
    required Object version,
    required Object system,
    required Object language,
  }) => 'Birka ${version} · ${system} · ${language}';

  /// en: 'Mail did not open. The address is copied: $address'
  String noMail({required Object address}) =>
      'Mail did not open. The address is copied: ${address}';

  /// en: 'The page did not open. Try again.'
  String get noPage => 'The page did not open. Try again.';
}

// Path: imports
class Translations$imports$en {
  Translations$imports$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Statement account'
  String get account => 'Statement account';

  Map<String, String> get formats => {
    'alfa': 'Alfa-Bank',
    'tbank': 'T-Bank',
    'sber': 'Sberbank',
    'zenmoney': 'Zenmoney',
    'wise': 'Wise',
    'revolut': 'Revolut',
  };
  Map<String, String> get formatsOf => {
    'alfa': 'Alfa-Bank',
    'tbank': 'T-Bank',
    'sber': 'Sberbank',
    'zenmoney': 'Zenmoney',
    'wise': 'Wise',
    'revolut': 'Revolut',
  };

  /// en: 'Import a statement'
  String get title => 'Import a statement';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Step $n of $count · $what'
  String stepOf({
    required Object n,
    required Object count,
    required Object what,
  }) => 'Step ${n} of ${count} · ${what}';

  Map<String, String> get steps => {
    'file': 'File',
    'format': 'Bank',
    'columns': 'Columns',
    'account': 'Account',
    'copies': 'Duplicates',
    'done': 'Result',
  };
  Map<String, String> get stepWhat => {
    'file': 'a file from a bank or Zenmoney',
    'format': 'whose statement it is',
    'columns': 'how to read the columns',
    'account': 'where it goes',
    'copies': 'what the ledger already has',
    'done': 'the result',
  };

  /// en: 'Steps of the import'
  String get stepsLabel => 'Steps of the import';

  /// en: 'That did not work. Try again.'
  String get failed => 'That did not work. Try again.';

  /// en: 'Drop a statement here'
  String get dropTitle => 'Drop a statement here';

  /// en: 'A file from your online bank for any period. Birka tells the bank by its columns and shows how it read every row before anything is written.'
  String get dropText =>
      'A file from your online bank for any period. Birka tells the bank by its columns and shows how it read every row before anything is written.';

  /// en: 'Choose a file'
  String get choose => 'Choose a file';

  /// en: 'Reading the file…'
  String get reading => 'Reading the file…';

  List<String> get kinds => [
    'CSV',
    'Excel, XLSX',
    'Sberbank PDF',
    'Zenmoney export',
  ];

  /// en: 'PDFs of Sberbank only · up to 10,000 rows in one file'
  String get dropNote =>
      'PDFs of Sberbank only · up to 10,000 rows in one file';

  /// en: 'The file did not read'
  String get unreadableTitle => 'The file did not read';

  Map<String, String> get unreadable => {
    'pdf':
        'This PDF cannot be read. Birka reads statements of Sberbank; for other banks, take CSV or Excel.',
    'notATable':
        'The file holds no table of operations. It takes CSV, Excel or a PDF of Sberbank.',
    'damaged': 'The file is damaged. Download the statement again.',
    'empty': 'The file is empty.',
    'tooLarge':
        'The file is too large. Take a shorter statement, up to 10,000 rows.',
    'incomplete':
        'The operations of the statement miss its totals; some did not read. Download the statement again.',
  };

  /// en: 'How it works'
  String get howTitle => 'How it works';

  List<String> get how => [
    'We tell the bank by the columns of the file: Alfa-Bank, T-Bank, Sberbank, Zenmoney, Wise, Revolut or a format of your own',
    'We show every row as it will enter the ledger',
    'We never double what you have already typed in',
    'An import comes out whole, with one button, even a month later',
  ];

  /// en: 'No bank passwords'
  String get privacyTitle => 'No bank passwords';

  /// en: 'The file is read here, in the browser. Birka never signs in to your bank and sends the statement nowhere.'
  String get privacyText =>
      'The file is read here, in the browser. Birka never signs in to your bank and sends the statement nowhere.';

  /// en: 'Where to get a statement'
  String get whereTitle => 'Where to get a statement';

  /// en: 'Online bank'
  String get whereBank => 'Online bank';

  /// en: 'The section of statements or of the history of operations, as CSV or Excel for the months you need'
  String get whereBankText =>
      'The section of statements or of the history of operations, as CSV or Excel for the months you need';

  /// en: 'Zenmoney'
  String get whereZen => 'Zenmoney';

  /// en: 'The export of operations in CSV from the web version: every account, category and year at once'
  String get whereZenText =>
      'The export of operations in CSV from the web version: every account, category and year at once';

  /// en: 'Wise and Revolut'
  String get whereAbroad => 'Wise and Revolut';

  /// en: 'A statement in CSV: each operation keeps its own currency'
  String get whereAbroadText =>
      'A statement in CSV: each operation keeps its own currency';

  /// en: 'Past imports'
  String get pastTitle => 'Past imports';

  /// en: '$format · $period'
  String pastName({required Object format, required Object period}) =>
      '${format} · ${period}';

  /// en: '$operations → $where · $day'
  String pastLine({
    required Object operations,
    required Object where,
    required Object day,
  }) => '${operations} → ${where} · ${day}';

  /// en: '(one) {$count operation} (other) {$count operations}'
  String operations({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} operation',
        other: '${count} operations',
      );

  /// en: '(one) {$count account} (other) {$count accounts}'
  String accounts({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} account',
        other: '${count} accounts',
      );

  /// en: 'Undo'
  String get undo => 'Undo';

  /// en: '(one) {Take out $count operation of this file?} (other) {Take out $count operations of this file?}'
  String undoAsk({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Take out ${count} operation of this file?',
        other: 'Take out ${count} operations of this file?',
      );

  /// en: 'Take out'
  String get undoYes => 'Take out';

  /// en: 'Keep'
  String get undoNo => 'Keep';

  /// en: 'The import of «$name» is undone'
  String undone({required Object name}) => 'The import of «${name}» is undone';

  /// en: 'Looks like a statement of $bank'
  String looksLike({required Object bank}) =>
      'Looks like a statement of ${bank}';

  /// en: '(one) {$n column of $total matched. Birka reads the file by it, and you check the result on the next step.} (other) {$n columns of $total matched. Birka reads the file by them, and you check the result on the next step.}'
  String matched({
    required num n,
    required Object total,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one:
        '${n} column of ${total} matched. Birka reads the file by it, and you check the result on the next step.',
    other:
        '${n} columns of ${total} matched. Birka reads the file by them, and you check the result on the next step.',
  );

  /// en: 'The bank was not told by the columns'
  String get notKnown => 'The bank was not told by the columns';

  /// en: 'Pick it below or give the columns their roles on the next step.'
  String get notKnownText =>
      'Pick it below or give the columns their roles on the next step.';

  /// en: '$header — left out'
  String skipped({required Object header}) => '${header} — left out';

  /// en: 'Format of the statement'
  String get formatsTitle => 'Format of the statement';

  Map<String, String> get formatTexts => {
    'alfa': 'The operations of one card or account',
    'tbank': 'Cards and accounts, with the categories of the bank',
    'sber': 'The PDF statement of a card from SberBank Online',
    'zenmoney': 'Every account, category and transfer at once',
    'wise': 'Each operation in its own currency, with its rate',
    'revolut': 'Each operation in its own currency, with its fee',
  };

  /// en: 'A format of your own'
  String get own => 'A format of your own';

  /// en: 'any'
  String get ownTag => 'any';

  /// en: 'You give the columns their roles'
  String get ownText => 'You give the columns their roles';

  Map<String, String> get fileKinds => {
    'csv': 'CSV',
    'xlsx': 'Excel',
    'pdf': 'PDF',
  };

  /// en: 'What enters the ledger'
  String get summaryTitle => 'What enters the ledger';

  /// en: 'Format'
  String get summaryFormat => 'Format';

  /// en: 'Rows in the file'
  String get summaryRows => 'Rows in the file';

  /// en: 'Period'
  String get summaryPeriod => 'Period';

  /// en: 'Account'
  String get summaryAccount => 'Account';

  /// en: 'picked on step 4'
  String get accountLater => 'picked on step 4';

  /// en: 'Operations'
  String get summaryOperations => 'Operations';

  /// en: 'Spent'
  String get summarySpent => 'Spent';

  /// en: 'Received'
  String get summaryReceived => 'Received';

  /// en: 'No category'
  String get summaryUnsorted => 'No category';

  /// en: '$count → the inbox'
  String toInbox({required Object count}) => '${count} → the inbox';

  /// en: 'Balance after'
  String get summaryBalance => 'Balance after';

  /// en: 'In the file'
  String get summaryFromFile => 'In the file';

  /// en: 'Copies skipped'
  String get summaryCopies => 'Copies skipped';

  /// en: 'To add'
  String get summaryAdded => 'To add';

  Map<String, String> get next => {
    'format': 'Next: the bank',
    'columns': 'Next: the columns',
    'account': 'Next: the account',
    'copies': 'Next: duplicates',
  };

  /// en: '(one) {Import $count operation} (other) {Import $count operations}'
  String write({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Import ${count} operation',
        other: 'Import ${count} operations',
      );

  /// en: 'Nothing to add'
  String get nothingToWrite => 'Nothing to add';

  /// en: 'Counting…'
  String get planning => 'Counting…';

  /// en: 'Writing: $done of $total'
  String writing({required Object done, required Object total}) =>
      'Writing: ${done} of ${total}';

  /// en: 'The whole import can be undone with one button'
  String get writeNote => 'The whole import can be undone with one button';

  /// en: 'Columns of the file'
  String get columnsTitle => 'Columns of the file';

  Map<String, String> get roles => {
    'date': 'Date',
    'amount': 'Amount',
    'expense': 'Spent',
    'income': 'Received',
    'fee': 'Fee',
    'currency': 'Currency',
    'expenseCurrency': 'Currency spent',
    'incomeCurrency': 'Currency received',
    'account': 'Account',
    'expenseAccount': 'Account spent from',
    'incomeAccount': 'Account received on',
    'description': 'Description',
    'note': 'Note',
    'category': 'Category of the bank',
    'ownCategory': 'Your category',
    'card': 'Card',
    'balance': 'Balance',
    'status': 'Status',
    'skip': 'Leave out',
  };

  /// en: 'What the column «$header» holds'
  String roleOf({required Object header}) =>
      'What the column «${header}» holds';

  /// en: 'Money spent is written'
  String get signTitle => 'Money spent is written';

  Map<String, String> get signs => {
    'expenseNegative': 'with a minus',
    'expensePositive': 'with a plus',
    'incomePlus': 'without a sign',
  };

  /// en: 'Cents are set apart by'
  String get markTitle => 'Cents are set apart by';

  Map<String, String> get marks => {
    'comma': 'a comma',
    'dot': 'a dot',
  };

  /// en: 'Dates'
  String get datesTitle => 'Dates';

  Map<String, String> get dateOrders => {
    'dayMonthYear': 'DD.MM.YYYY',
    'monthDayYear': 'MM.DD.YYYY',
  };

  /// en: 'Mark the column of the date and the column of the amount: without them rows do not become operations.'
  String get missing =>
      'Mark the column of the date and the column of the amount: without them rows do not become operations.';

  /// en: 'How the rows enter the ledger'
  String get previewTitle => 'How the rows enter the ledger';

  /// en: 'the first $shown of $total · headers and totals do not count'
  String previewNote({required Object shown, required Object total}) =>
      'the first ${shown} of ${total} · headers and totals do not count';

  /// en: 'Date'
  String get previewDate => 'Date';

  /// en: 'Description'
  String get previewText => 'Description';

  /// en: 'Category'
  String get previewCategory => 'Category';

  /// en: 'Amount'
  String get previewAmount => 'Amount';

  /// en: 'Transfer'
  String get transfer => 'Transfer';

  /// en: 'as before'
  String get learned => 'as before';

  /// en: 'Decide in the inbox'
  String get inbox => 'Decide in the inbox';

  /// en: '(one) {$count row did not read} (other) {$count rows did not read}'
  String problems({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} row did not read',
        other: '${count} rows did not read',
      );

  /// en: 'Row $line: $fault'
  String problemLine({required Object line, required Object fault}) =>
      'Row ${line}: ${fault}';

  /// en: 'and $count more'
  String andMore({required Object count}) => 'and ${count} more';

  Map<String, String> get rowFaults => {
    'unreadableDate': 'the date does not read',
    'noSuchDay': 'there is no such day',
    'noAmount': 'no amount',
    'unreadableAmount': 'the amount does not read',
    'zeroAmount': 'the amount is zero',
    'declined': 'the operation did not go through',
  };

  /// en: 'Categories of the bank → yours'
  String get categoriesTitle => 'Categories of the bank → yours';

  /// en: 'Without a choice, operations wait in the inbox'
  String get categoriesNote => 'Without a choice, operations wait in the inbox';

  Map<String, String> get categoryKinds => {
    'expense': 'spent',
    'income': 'received',
  };

  /// en: 'No category of the bank'
  String get noBankCategory => 'No category of the bank';

  /// en: 'New: $name'
  String newCategory({required Object name}) => 'New: ${name}';

  /// en: 'Fees of the bank'
  String get fees => 'Fees of the bank';

  /// en: 'The category for «$name»'
  String categoryOf({required Object name}) => 'The category for «${name}»';

  /// en: 'Where the operations of the card ••$card go'
  String accountTitleCard({required Object card}) =>
      'Where the operations of the card ••${card} go';

  /// en: 'Where the operations of «$name» go'
  String accountTitleNamed({required Object name}) =>
      'Where the operations of «${name}» go';

  /// en: 'Where the operations go'
  String get accountTitle => 'Where the operations go';

  /// en: '$operations. Pick an account of Birka, start a new one or leave them out.'
  String accountText({required Object operations}) =>
      '${operations}. Pick an account of Birka, start a new one or leave them out.';

  /// en: 'the card matched'
  String get cardMatched => 'the card matched';

  /// en: 'the name matched'
  String get nameMatched => 'the name matched';

  /// en: '$currency, and the file has $fileCurrency'
  String otherCurrency({
    required Object currency,
    required Object fileCurrency,
  }) => '${currency}, and the file has ${fileCurrency}';

  /// en: 'A new account'
  String get newAccount => 'A new account';

  /// en: 'We start «$name» with a balance of $balance'
  String newAccountText({required Object name, required Object balance}) =>
      'We start «${name}» with a balance of ${balance}';

  /// en: 'Leave out'
  String get leaveOut => 'Leave out';

  /// en: 'The operations of this account stay out of the ledger'
  String get leaveOutText =>
      'The operations of this account stay out of the ledger';

  /// en: 'The balance meets the bank'
  String get balanceMatches => 'The balance meets the bank';

  /// en: 'The balance differs from the bank'
  String get balanceDiffers => 'The balance differs from the bank';

  /// en: 'In the statement on $day'
  String balanceInFile({required Object day}) => 'In the statement on ${day}';

  /// en: 'In Birka after the import'
  String get balanceInBirka => 'In Birka after the import';

  /// en: 'The ledger has operations that the statement lacks, or the other way round. Check the account and the duplicates.'
  String get balanceHint =>
      'The ledger has operations that the statement lacks, or the other way round. Check the account and the duplicates.';

  /// en: '(one) {$count operation is already in the ledger} (other) {$count operations are already in the ledger}'
  String copiesTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} operation is already in the ledger',
        other: '${count} operations are already in the ledger',
      );

  /// en: 'You seem to have typed them in. The copies from the statement are skipped, and your records stay as they are, with your names and categories.'
  String get copiesText =>
      'You seem to have typed them in. The copies from the statement are skipped, and your records stay as they are, with your names and categories.';

  /// en: 'No duplicates'
  String get noCopies => 'No duplicates';

  /// en: 'No operation of the statement looks like one of the ledger.'
  String get noCopiesText =>
      'No operation of the statement looks like one of the ledger.';

  /// en: 'From the statement'
  String get fromFile => 'From the statement';

  /// en: 'Already in the ledger'
  String get inLedger => 'Already in the ledger';

  Map<String, String> get reasons => {
    'imported': 'from this very file',
    'sameAmount': 'the same amount',
    'sameDay': 'the same day',
    'dayBefore': 'a day before',
    'dayAfter': 'a day after',
    'sameAccount': 'the same account',
    'similarName': 'a similar name',
  };

  /// en: 'Skip the copy'
  String get skipCopy => 'Skip the copy';

  /// en: 'Keep both'
  String get keepBoth => 'Keep both';

  /// en: '(one) {$count operation stays out of the ledger} (other) {$count operations stay out of the ledger}'
  String leftTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} operation stays out of the ledger',
        other: '${count} operations stay out of the ledger',
      );

  Map<String, String> get planFaults => {
    'otherCurrency': 'the account has another currency',
    'tooPrecise': 'more digits than the currency has',
    'unevenTransfer': 'a transfer in one currency with two amounts',
  };

  /// en: '(one) {Added $count operation} (other) {Added $count operations}'
  String doneTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Added ${count} operation',
        other: 'Added ${count} operations',
      );

  /// en: '$format, $period → $accounts'
  String doneWhere({
    required Object format,
    required Object period,
    required Object accounts,
  }) => '${format}, ${period} → ${accounts}';

  /// en: 'Received'
  String get doneIncome => 'Received';

  /// en: 'New spending'
  String get doneSpent => 'New spending';

  /// en: 'Copies skipped'
  String get doneSkipped => 'Copies skipped';

  /// en: 'Balance of the account'
  String get doneBalance => 'Balance of the account';

  /// en: 'as in the bank'
  String get asInBank => 'as in the bank';

  /// en: '(one) {$count waits for you in the inbox} (other) {$count wait for you in the inbox}'
  String unsortedTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} waits for you in the inbox',
        other: '${count} wait for you in the inbox',
      );

  /// en: 'They count in the reports already, only without a category.'
  String get unsortedText =>
      'They count in the reports already, only without a category.';

  /// en: 'Sort the inbox'
  String get sortInbox => 'Sort the inbox';

  /// en: 'Changed your mind?'
  String get undoTitle => 'Changed your mind?';

  /// en: '(one) {The undo takes out $count operation of this file. Your records and other imports stay. You can undo it later too, under «Past imports».} (other) {The undo takes out $count operations of this file. Your records and other imports stay. You can undo it later too, under «Past imports».}'
  String undoText({
    required num n,
    required Object count,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one:
        'The undo takes out ${count} operation of this file. Your records and other imports stay. You can undo it later too, under «Past imports».',
    other:
        'The undo takes out ${count} operations of this file. Your records and other imports stay. You can undo it later too, under «Past imports».',
  );

  /// en: 'Undo the import'
  String get undoImport => 'Undo the import';

  /// en: 'The import is undone'
  String get undoneTitle => 'The import is undone';

  /// en: 'The operations of this file are out of the ledger. Your records stay as they were.'
  String get undoneText =>
      'The operations of this file are out of the ledger. Your records stay as they were.';

  /// en: 'To the operations'
  String get toOperations => 'To the operations';

  /// en: 'Import another statement'
  String get another => 'Import another statement';

  List<String> get monthsWhole => [
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

  /// en: '$month $year'
  String periodMonth({required Object month, required Object year}) =>
      '${month} ${year}';

  /// en: '$month $from–$to, $year'
  String periodInMonth({
    required Object month,
    required Object from,
    required Object to,
    required Object year,
  }) => '${month} ${from}–${to}, ${year}';

  /// en: '$from – $to, $year'
  String periodInYear({
    required Object from,
    required Object to,
    required Object year,
  }) => '${from} – ${to}, ${year}';

  /// en: '$from – $to'
  String periodFar({required Object from, required Object to}) =>
      '${from} – ${to}';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Done'
  String get finish => 'Done';

  /// en: 'Reading the statement'
  String get readingTitle => 'Reading the statement';

  /// en: 'The file is read on this phone and goes nowhere'
  String get readingNote => 'The file is read on this phone and goes nowhere';

  /// en: '$bank · told by the columns'
  String knownBy({required Object bank}) => '${bank} · told by the columns';

  /// en: 'Operations for $period'
  String operationsIn({required Object period}) => 'Operations for ${period}';

  /// en: 'Already in the ledger'
  String get alreadyIn => 'Already in the ledger';

  /// en: '$count, skipped'
  String willSkip({required Object count}) => '${count}, skipped';

  /// en: 'To sort later'
  String get sortLater => 'To sort later';

  /// en: '$count in the inbox'
  String inInbox({required Object count}) => '${count} in the inbox';

  /// en: 'The format is unknown'
  String get unknownTitle => 'The format is unknown';

  /// en: '(one) {$count column} (other) {$count columns}'
  String columnsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} column',
        other: '${count} columns',
      );

  /// en: '(one) {$count row} (other) {$count rows}'
  String rowsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} row',
        other: '${count} rows',
      );

  /// en: 'Set the columns of this file, where the date and the amount are. Birka reads the rest by itself.'
  String get unknownText =>
      'Set the columns of this file, where the date and the amount are. Birka reads the rest by itself.';

  /// en: 'Choose another file'
  String get chooseAnother => 'Choose another file';

  /// en: 'Set the columns'
  String get assignColumns => 'Set the columns';

  /// en: 'Columns of the statement'
  String get columnsHeading => 'Columns of the statement';

  /// en: 'Mark where the file keeps the date and the amount, and its rows become operations.'
  String get columnsText =>
      'Mark where the file keeps the date and the amount, and its rows become operations.';

  Map<String, String> get roleNotes => {
    'date': 'the day of the operation',
    'amount': 'money out and in, in one column',
    'expense': 'only money out',
    'income': 'only money in',
    'currency': 'RUB, USD, EUR…',
    'description': 'a shop, a payee or what it was for',
    'category': 'sorted in the inbox',
    'balance': 'checked against the bank',
    'skip': 'the column is left out',
  };

  /// en: 'No amount read. Check what the file puts before the cents.'
  String get noAmounts =>
      'No amount read. Check what the file puts before the cents.';

  /// en: 'Done · $operations'
  String columnsDone({required Object operations}) => 'Done · ${operations}';

  /// en: 'columns set by you'
  String get ownColumns => 'columns set by you';
}

// Path: inbox
class Translations$inbox$en {
  Translations$inbox$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Inbox'
  String get title => 'Inbox';

  /// en: 'Back'
  String get back => 'Back';

  /// en: '(one) {$count waits for you} (other) {$count wait for you}'
  String waiting({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} waits for you',
        other: '${count} wait for you',
      );

  /// en: 'after the import of $bank'
  String afterImport({required Object bank}) => 'after the import of ${bank}';

  /// en: 'after the import of «$name»'
  String afterFile({required Object name}) => 'after the import of «${name}»';

  Map<String, String> get filters => {
    'all': 'All',
    'uncategorized': 'No category',
    'transfers': 'Transfers',
  };

  /// en: 'What to show'
  String get filtersLabel => 'What to show';

  /// en: 'All sorted'
  String get emptyTitle => 'All sorted';

  /// en: 'Operations without a category and transfers between your accounts come here from statements.'
  String get emptyText =>
      'Operations without a category and transfers between your accounts come here from statements.';

  /// en: 'Looks like a transfer between your accounts'
  String get pairTitle => 'Looks like a transfer between your accounts';

  /// en: 'Neither spending nor income: your capital stays the same'
  String get pairText =>
      'Neither spending nor income: your capital stays the same';

  /// en: 'Rate $rate for $unit'
  String rate({required Object rate, required Object unit}) =>
      'Rate ${rate} for ${unit}';

  /// en: 'the Bank of Russia that day $rate'
  String bankRate({required Object rate}) =>
      'the Bank of Russia that day ${rate}';

  /// en: 'Make it a transfer'
  String get makeTransfer => 'Make it a transfer';

  /// en: 'It is income'
  String get notTransfer => 'It is income';

  /// en: 'from the statement'
  String get fromStatement => 'from the statement';

  /// en: 'No category'
  String get uncategorized => 'No category';

  /// en: '$title · $count'
  String section({required Object title, required Object count}) =>
      '${title} · ${count}';

  /// en: 'Category'
  String get category => 'Category';

  /// en: 'Another'
  String get other => 'Another';

  /// en: 'Yes'
  String get yes => 'Yes';

  /// en: 'The category for «$name»'
  String categoryFor({required Object name}) => 'The category for «${name}»';

  /// en: '(one) {as you marked it $count time $when} (other) {as you marked it $count times $when}'
  String sameName({
    required num n,
    required Object count,
    required Object when,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one: 'as you marked it ${count} time ${when}',
    other: 'as you marked it ${count} times ${when}',
  );

  /// en: 'the same amount every month $since'
  String everyMonth({required Object since}) =>
      'the same amount every month ${since}';

  /// en: 'like «$name» in this statement'
  String sameImport({required Object name}) =>
      'like «${name}» in this statement';

  /// en: 'like «$name» $when'
  String similarName({required Object name, required Object when}) =>
      'like «${name}» ${when}';

  /// en: 'since $month'
  String since({required Object month}) => 'since ${month}';

  /// en: '(one) {and $count more operation} (other) {and $count more operations}'
  String more({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'and ${count} more operation',
        other: 'and ${count} more operations',
      );

  /// en: '(one) {$count operation picked} (other) {$count operations picked}'
  String picked({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} operation picked',
        other: '${count} operations picked',
      );

  /// en: 'The category for the picked'
  String get pickedCategory => 'The category for the picked';

  /// en: 'Pick all'
  String get pickAll => 'Pick all';

  /// en: 'Pick none'
  String get pickNone => 'Pick none';

  /// en: 'Pick «$name»'
  String pick({required Object name}) => 'Pick «${name}»';

  /// en: 'Where the hints come from'
  String get sourceTitle => 'Where the hints come from';

  /// en: 'From your past choices: how you named these places before and which categories you gave them. Counted here, on the device.'
  String get sourceText =>
      'From your past choices: how you named these places before and which categories you gave them. Counted here, on the device.';

  /// en: 'Each «Yes» teaches Birka: in the next statement such operations come with their category.'
  String get learns =>
      'Each «Yes» teaches Birka: in the next statement such operations come with their category.';

  /// en: 'While an operation is here, it already counts in the ledger and the reports, only without a category.'
  String get stillCounted =>
      'While an operation is here, it already counts in the ledger and the reports, only without a category.';

  /// en: 'That did not work. Try again.'
  String get failed => 'That did not work. Try again.';

  /// en: 'Made a transfer'
  String get madeTransfer => 'Made a transfer';

  /// en: '$category: Birka will put such ones there next time'
  String accepted({required Object category}) =>
      '${category}: Birka will put such ones there next time';

  /// en: '$category · $operations'
  String sorted({required Object category, required Object operations}) =>
      '${category} · ${operations}';

  /// en: 'Kept as income'
  String get keptIncome => 'Kept as income';

  /// en: 'Import a statement'
  String get toImport => 'Import a statement';

  /// en: 'suggested'
  String get hinted => 'suggested';

  /// en: 'New category'
  String get newCategory => 'New category';

  /// en: 'Clear'
  String get unpick => 'Clear';
}

// Path: onboarding
class Translations$onboarding$en {
  Translations$onboarding$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Skip'
  String get skip => 'Skip';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Could not save. Try again.'
  String get failed => 'Could not save. Try again.';

  late final Translations$onboarding$welcome$en welcome =
      Translations$onboarding$welcome$en.internal(_root);
  late final Translations$onboarding$account$en account =
      Translations$onboarding$account$en.internal(_root);
  late final Translations$onboarding$categories$en categories =
      Translations$onboarding$categories$en.internal(_root);
}

// Path: overview
class Translations$overview$en {
  Translations$overview$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Capital'
  String get capital => 'Capital';

  /// en: 'Bank of Russia rate on $day'
  String rateOn({required Object day}) => 'Bank of Russia rate on ${day}';

  /// en: '(one) {$n currency} (other) {$n currencies}'
  String currencies({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} currency',
        other: '${n} currencies',
      );

  /// en: 'Week'
  String get week => 'Week';

  /// en: 'Month'
  String get month => 'Month';

  /// en: 'Year'
  String get year => 'Year';

  /// en: 'this week'
  String get inWeek => 'this week';

  /// en: 'this year'
  String get inYear => 'this year';

  /// en: 'The capital over time'
  String get chart => 'The capital over time';

  /// en: 'Accounts'
  String get accounts => 'Accounts';

  /// en: 'All $n'
  String allAccounts({required Object n}) => 'All ${n}';

  /// en: 'Spending $month'
  String spendingIn({required Object month}) => 'Spending ${month}';

  List<String> get monthsIn => [
    'in January',
    'in February',
    'in March',
    'in April',
    'in May',
    'in June',
    'in July',
    'in August',
    'in September',
    'in October',
    'in November',
    'in December',
  ];

  /// en: 'Nothing spent this month yet.'
  String get noSpending => 'Nothing spent this month yet.';

  /// en: 'Spending by category'
  String get ring => 'Spending by category';

  /// en: 'Could not read the overview.'
  String get failed => 'Could not read the overview.';

  /// en: 'Hide the amounts'
  String get hideAmounts => 'Hide the amounts';

  /// en: 'Show the amounts'
  String get showAmounts => 'Show the amounts';

  List<String> get changeIn => [
    'in January',
    'in February',
    'in March',
    'in April',
    'in May',
    'in June',
    'in July',
    'in August',
    'in September',
    'in October',
    'in November',
    'in December',
  ];
}

// Path: reports
class Translations$reports$en {
  Translations$reports$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Expenses'
  String get expenses => 'Expenses';

  /// en: 'Income'
  String get income => 'Income';

  /// en: 'By month'
  String get byMonth => 'By month';

  /// en: 'average $amount'
  String average({required Object amount}) => 'average ${amount}';

  /// en: 'Nothing spent this month.'
  String get noExpenses => 'Nothing spent this month.';

  /// en: 'Nothing earned this month.'
  String get noIncome => 'Nothing earned this month.';

  /// en: 'Shares of the categories'
  String get ring => 'Shares of the categories';

  /// en: 'Bank of Russia rate on the day of each operation'
  String get dayRates => 'Bank of Russia rate on the day of each operation';

  /// en: 'Could not read the report.'
  String get failed => 'Could not read the report.';

  List<String> get against => [
    'vs January',
    'vs February',
    'vs March',
    'vs April',
    'vs May',
    'vs June',
    'vs July',
    'vs August',
    'vs September',
    'vs October',
    'vs November',
    'vs December',
  ];
  List<String> get monthsShort => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

// Path: settings
class Translations$settings$en {
  Translations$settings$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'General'
  String get general => 'General';

  /// en: 'Language'
  String get language => 'Language';

  /// en: 'Same as the device'
  String get deviceLanguage => 'Same as the device';

  /// en: 'English'
  String get english => 'English';

  /// en: 'Русский'
  String get russian => 'Русский';

  /// en: 'Base currency'
  String get baseCurrency => 'Base currency';

  /// en: 'First account'
  String get firstAccountCurrency => 'First account';

  /// en: 'Курсы ЦБ РФ в XML и JSON, API'
  String get ratesCredit => 'Курсы ЦБ РФ в XML и JSON, API';

  /// en: 'Security'
  String get security => 'Security';

  /// en: 'Hide amounts'
  String get hideAmounts => 'Hide amounts';

  /// en: 'At launch'
  String get onLaunch => 'At launch';
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

  /// en: 'Tap the plus to record the first one.'
  String get noOperationsHint => 'Tap the plus to record the first one.';

  /// en: 'Nothing has happened on this account yet.'
  String get noAccountOperations => 'Nothing has happened on this account yet.';

  /// en: 'Balance over the period'
  String get balanceChart => 'Balance over the period';

  /// en: 'This account is gone.'
  String get accountGone => 'This account is gone.';

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
  String get balance => 'Balance now';

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

// Path: backup.csv
class Translations$backup$csv$en {
  Translations$backup$csv$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Date'
  String get date => 'Date';

  /// en: 'Type'
  String get kind => 'Type';

  /// en: 'Amount'
  String get amount => 'Amount';

  /// en: 'Currency'
  String get currency => 'Currency';

  /// en: 'Account'
  String get account => 'Account';

  /// en: 'Category'
  String get category => 'Category';

  /// en: 'Subcategory'
  String get subcategory => 'Subcategory';

  /// en: 'Note'
  String get note => 'Note';

  /// en: 'Expense'
  String get expense => 'Expense';

  /// en: 'Income'
  String get income => 'Income';

  /// en: 'Transfer'
  String get transfer => 'Transfer';

  /// en: 'Adjustment'
  String get adjustment => 'Adjustment';
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

// Path: onboarding.welcome
class Translations$onboarding$welcome$en {
  Translations$onboarding$welcome$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'All your money in one place'
  String get title => 'All your money\nin one place';

  /// en: 'Accounts in any currency and no bank passwords. Your data stays on your device.'
  String get text =>
      'Accounts in any currency and no bank passwords. Your data stays on your device.';

  /// en: 'Get started'
  String get start => 'Get started';
}

// Path: onboarding.account
class Translations$onboarding$account$en {
  Translations$onboarding$account$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Your first account'
  String get title => 'Your first account';

  /// en: 'Your capital starts here. You can change the balance at any time.'
  String get text =>
      'Your capital starts here. You can change the balance at any time.';

  /// en: 'Next'
  String get next => 'Next';
}

// Path: onboarding.categories
class Translations$onboarding$categories$en {
  Translations$onboarding$categories$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Categories'
  String get title => 'Categories';

  /// en: 'Take a ready set. You can change it at any time.'
  String get text => 'Take a ready set. You can change it at any time.';

  /// en: 'Short set'
  String get short => 'Short set';

  /// en: 'Full set'
  String get full => 'Full set';

  /// en: '(one) {$n category} (other) {$n categories}'
  String count({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} category',
        other: '${n} categories',
      );

  /// en: 'Done'
  String get finish => 'Done';
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
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'in ${n} account',
                  other: 'in ${n} accounts',
                ),
          'accounts.main' => 'main',
          'accounts.emptyTitle' => 'No accounts yet',
          'accounts.emptyHint' =>
            'Add the first one to see where your money is.',
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
          'accounts.form.balance' => 'Balance now',
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
          'app.storedHere' =>
            'Your data stays in this browser and nowhere else.',
          'app.notStored' =>
            'This browser cannot keep data, so it goes when you close the tab.',
          'app.openElsewhere' =>
            'Birka is open in another tab. Close it and try again.',
          'app.soon' => 'soon',
          'app.noCategory' => 'No category',
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
          'app.data' => 'Data',
          'app.support' => 'Support',
          'app.help' => 'Help and feedback',
          'app.keptOnDevice' => 'your data stays on this device',
          'app.keptInBrowser' => 'your data stays in this browser',
          'app.sourceCode' => 'Source code on GitHub',
          'backup.title' => 'Data',
          'backup.back' => 'Back',
          'backup.storedTitle' => 'Your records live here',
          'backup.storedText' =>
            'Only on this device, with no servers. A copy in a file helps you move them or keep them safe.',
          'backup.noCopyYet' => 'No copy yet',
          'backup.lastCopy' => ({required Object when}) => 'Last copy: ${when}',
          'backup.todayAt' => ({required Object time}) => 'today at ${time}',
          'backup.yesterdayAt' =>
            ({required Object time}) => 'yesterday at ${time}',
          'backup.dayAt' =>
            ({required Object day, required Object time}) =>
                '${day} at ${time}',
          'backup.operations' => 'Operations',
          'backup.accounts' => 'Accounts',
          'backup.categories' => 'Categories',
          'backup.save' => 'Save a copy',
          'backup.restore' => 'Restore from a copy',
          'backup.export' => 'Export',
          'backup.exportTitle' => 'Operations as CSV',
          'backup.exportText' =>
            'For Excel and Google Sheets: date, amount, currency, account, category',
          'backup.records' => 'Records',
          'backup.demo' => 'Demo data',
          'backup.demoText' => 'Sample accounts and operations to look around',
          'backup.wipe' => 'Delete all data',
          'backup.filesNote' =>
            'Files go only where you point in the window of the system.',
          'backup.filesNoteSite' =>
            'Files go where the browser keeps its downloads.',
          'backup.restoreTitle' => 'Restore from a copy?',
          'backup.restoreText' =>
            'The records on this device will give way to the contents of the file. This cannot be undone, so save a copy of the current ones first if you need them.',
          'backup.replace' => 'Replace the records',
          'backup.cancel' => 'Cancel',
          'backup.wipeTitle' => 'Delete all data?',
          'backup.wipeText' =>
            'Accounts, operations and categories will disappear from this device. The language and other settings will stay. Without a copy, the records cannot come back.',
          'backup.saveFirst' => 'Save a copy first',
          'backup.wipeAll' => 'Delete everything',
          'backup.saved' => ({required Object name}) => 'Copy saved: ${name}',
          'backup.restored' =>
            ({required Object day}) =>
                'Records restored from the copy of ${day}',
          'backup.exported' =>
            ({required Object name}) => 'File saved: ${name}',
          'backup.wiped' => 'All data is gone from this device',
          'backup.notACopy' => 'This is not a copy of Birka.',
          'backup.newer' =>
            'A newer version of Birka made this copy. Update the app and try again.',
          'backup.damaged' => 'This copy is damaged and cannot be restored.',
          'backup.failed' => 'That did not work. Try again.',
          'backup.operationsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} operation',
                  other: '${count} operations',
                ),
          'backup.accountsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} account',
                  other: '${count} accounts',
                ),
          'backup.csv.date' => 'Date',
          'backup.csv.kind' => 'Type',
          'backup.csv.amount' => 'Amount',
          'backup.csv.currency' => 'Currency',
          'backup.csv.account' => 'Account',
          'backup.csv.category' => 'Category',
          'backup.csv.subcategory' => 'Subcategory',
          'backup.csv.note' => 'Note',
          'backup.csv.expense' => 'Expense',
          'backup.csv.income' => 'Income',
          'backup.csv.transfer' => 'Transfer',
          'backup.csv.adjustment' => 'Adjustment',
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
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
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
          'demo.card' => 'Salary card',
          'demo.cash' => 'Cash',
          'demo.savings' => 'Savings',
          'demo.euro' => 'Euro card',
          'demo.advance' => 'Advance',
          'demo.salary' => 'Salary',
          'demo.project' => 'Side project',
          'demo.interest' => 'Interest on the balance',
          'demo.supermarket' => 'Supermarket',
          'demo.market' => 'Market',
          'demo.bakery' => 'Bakery',
          'demo.coffee' => 'Coffee shop',
          'demo.lunch' => 'Lunch with colleagues',
          'demo.metro' => 'Metro',
          'demo.taxi' => 'Taxi',
          'demo.utilities' => 'Utilities',
          'demo.phone' => 'Phone and internet',
          'demo.music' => 'Music',
          'demo.movies' => 'Movies and shows',
          'demo.pharmacy' => 'Pharmacy',
          'demo.cinema' => 'Cinema',
          'demo.concert' => 'Concert',
          'demo.clothes' => 'Clothes',
          'demo.gift' => 'Gift',
          'demo.hotel' => 'Hotel',
          'demo.trip' => 'Trip',
          'demo.toCash' => 'Cash withdrawal',
          'demo.toSavings' => 'To savings',
          'demo.toEuro' => 'Euros for the trip',
          'help.title' => 'Help',
          'help.back' => 'Back',
          'help.search' => 'Search the help',
          'help.clearSearch' => 'Clear the search',
          'help.questions' => 'Common questions',
          'help.nothingFound' =>
            'Nothing found. Write to the developer: the answer will help others too and will appear here.',
          'help.storageQuestion' => 'Where is my data kept?',
          'help.storageAnswer' =>
            'Only on this device or in this browser. Birka sends no records to a server and never asks for bank passwords.',
          'help.moveQuestion' => 'How do I move my records to another device?',
          'help.moveAnswer' =>
            'Save a copy in More → Data, send the file to yourself and restore it on the new device. Sync comes later.',
          'help.ratesQuestion' => 'Where do the exchange rates come from?',
          'help.ratesAnswer' =>
            'They are the rates of the Bank of Russia on the day of the operation. They update once a day and stay on the device.',
          'help.importQuestion' => 'Can I load operations from my bank?',
          'help.importAnswer' =>
            'For now operations go in by hand. Loading bank statements is the next big feature.',
          'help.hideQuestion' => 'How do I hide the amounts?',
          'help.hideAnswer' =>
            'Tap the eye on Overview. To keep them hidden from the start, turn on Hide amounts in More.',
          'help.contact' => 'Contact',
          'help.write' => 'Write to the developer',
          'help.writeText' => 'Your mail app opens',
          'help.bug' => 'Report a bug',
          'help.bugText' =>
            'The letter gets the version and the system, none of your records',
          'help.idea' => 'Suggest an idea',
          'help.ideaText' => 'Tell what Birka lacks',
          'help.github' => 'Bugs and ideas on GitHub',
          'help.githubText' => 'Public: leave out amounts and account names',
          'help.letterTitle' => 'A letter to the developer',
          'help.letterText' =>
            'Your mail app opens with this letter. It holds only what you see below, and you can add to it.',
          'help.to' => 'To',
          'help.subject' => 'Subject',
          'help.letterPrivacy' =>
            'Operations, amounts and account names stay out of the letter.',
          'help.openMail' => 'Open mail',
          'help.cancel' => 'Cancel',
          'help.questionSubject' => 'Birka · question',
          'help.bugSubject' =>
            ({required Object version}) => 'Birka ${version} · bug',
          'help.ideaSubject' => 'Birka · idea',
          'help.questionBody' => 'Hello!\n',
          'help.bugBody' => 'What happened:\n\nWhat you expected:',
          'help.ideaBody' => 'What is missing:\n\nHow it would help:',
          'help.language' => 'English',
          'help.about' =>
            ({
              required Object version,
              required Object system,
              required Object language,
            }) => 'Birka ${version} · ${system} · ${language}',
          'help.noMail' =>
            ({required Object address}) =>
                'Mail did not open. The address is copied: ${address}',
          'help.noPage' => 'The page did not open. Try again.',
          'imports.account' => 'Statement account',
          'imports.formats.alfa' => 'Alfa-Bank',
          'imports.formats.tbank' => 'T-Bank',
          'imports.formats.sber' => 'Sberbank',
          'imports.formats.zenmoney' => 'Zenmoney',
          'imports.formats.wise' => 'Wise',
          'imports.formats.revolut' => 'Revolut',
          'imports.formatsOf.alfa' => 'Alfa-Bank',
          'imports.formatsOf.tbank' => 'T-Bank',
          'imports.formatsOf.sber' => 'Sberbank',
          'imports.formatsOf.zenmoney' => 'Zenmoney',
          'imports.formatsOf.wise' => 'Wise',
          'imports.formatsOf.revolut' => 'Revolut',
          'imports.title' => 'Import a statement',
          'imports.back' => 'Back',
          'imports.stepOf' =>
            ({
              required Object n,
              required Object count,
              required Object what,
            }) => 'Step ${n} of ${count} · ${what}',
          'imports.steps.file' => 'File',
          'imports.steps.format' => 'Bank',
          'imports.steps.columns' => 'Columns',
          'imports.steps.account' => 'Account',
          'imports.steps.copies' => 'Duplicates',
          'imports.steps.done' => 'Result',
          'imports.stepWhat.file' => 'a file from a bank or Zenmoney',
          'imports.stepWhat.format' => 'whose statement it is',
          'imports.stepWhat.columns' => 'how to read the columns',
          'imports.stepWhat.account' => 'where it goes',
          'imports.stepWhat.copies' => 'what the ledger already has',
          'imports.stepWhat.done' => 'the result',
          'imports.stepsLabel' => 'Steps of the import',
          'imports.failed' => 'That did not work. Try again.',
          'imports.dropTitle' => 'Drop a statement here',
          'imports.dropText' =>
            'A file from your online bank for any period. Birka tells the bank by its columns and shows how it read every row before anything is written.',
          'imports.choose' => 'Choose a file',
          'imports.reading' => 'Reading the file…',
          'imports.kinds.0' => 'CSV',
          'imports.kinds.1' => 'Excel, XLSX',
          'imports.kinds.2' => 'Sberbank PDF',
          'imports.kinds.3' => 'Zenmoney export',
          'imports.dropNote' =>
            'PDFs of Sberbank only · up to 10,000 rows in one file',
          'imports.unreadableTitle' => 'The file did not read',
          'imports.unreadable.pdf' =>
            'This PDF cannot be read. Birka reads statements of Sberbank; for other banks, take CSV or Excel.',
          'imports.unreadable.notATable' =>
            'The file holds no table of operations. It takes CSV, Excel or a PDF of Sberbank.',
          'imports.unreadable.damaged' =>
            'The file is damaged. Download the statement again.',
          'imports.unreadable.empty' => 'The file is empty.',
          'imports.unreadable.tooLarge' =>
            'The file is too large. Take a shorter statement, up to 10,000 rows.',
          'imports.unreadable.incomplete' =>
            'The operations of the statement miss its totals; some did not read. Download the statement again.',
          'imports.howTitle' => 'How it works',
          'imports.how.0' =>
            'We tell the bank by the columns of the file: Alfa-Bank, T-Bank, Sberbank, Zenmoney, Wise, Revolut or a format of your own',
          'imports.how.1' => 'We show every row as it will enter the ledger',
          'imports.how.2' => 'We never double what you have already typed in',
          'imports.how.3' =>
            'An import comes out whole, with one button, even a month later',
          'imports.privacyTitle' => 'No bank passwords',
          'imports.privacyText' =>
            'The file is read here, in the browser. Birka never signs in to your bank and sends the statement nowhere.',
          'imports.whereTitle' => 'Where to get a statement',
          'imports.whereBank' => 'Online bank',
          'imports.whereBankText' =>
            'The section of statements or of the history of operations, as CSV or Excel for the months you need',
          'imports.whereZen' => 'Zenmoney',
          'imports.whereZenText' =>
            'The export of operations in CSV from the web version: every account, category and year at once',
          'imports.whereAbroad' => 'Wise and Revolut',
          'imports.whereAbroadText' =>
            'A statement in CSV: each operation keeps its own currency',
          'imports.pastTitle' => 'Past imports',
          'imports.pastName' =>
            ({required Object format, required Object period}) =>
                '${format} · ${period}',
          'imports.pastLine' =>
            ({
              required Object operations,
              required Object where,
              required Object day,
            }) => '${operations} → ${where} · ${day}',
          'imports.operations' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} operation',
                  other: '${count} operations',
                ),
          'imports.accounts' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} account',
                  other: '${count} accounts',
                ),
          'imports.undo' => 'Undo',
          'imports.undoAsk' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Take out ${count} operation of this file?',
                  other: 'Take out ${count} operations of this file?',
                ),
          'imports.undoYes' => 'Take out',
          'imports.undoNo' => 'Keep',
          'imports.undone' =>
            ({required Object name}) => 'The import of «${name}» is undone',
          'imports.looksLike' =>
            ({required Object bank}) => 'Looks like a statement of ${bank}',
          'imports.matched' =>
            ({
              required num n,
              required Object total,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              n,
              one:
                  '${n} column of ${total} matched. Birka reads the file by it, and you check the result on the next step.',
              other:
                  '${n} columns of ${total} matched. Birka reads the file by them, and you check the result on the next step.',
            ),
          'imports.notKnown' => 'The bank was not told by the columns',
          'imports.notKnownText' =>
            'Pick it below or give the columns their roles on the next step.',
          'imports.skipped' =>
            ({required Object header}) => '${header} — left out',
          'imports.formatsTitle' => 'Format of the statement',
          'imports.formatTexts.alfa' => 'The operations of one card or account',
          'imports.formatTexts.tbank' =>
            'Cards and accounts, with the categories of the bank',
          'imports.formatTexts.sber' =>
            'The PDF statement of a card from SberBank Online',
          'imports.formatTexts.zenmoney' =>
            'Every account, category and transfer at once',
          'imports.formatTexts.wise' =>
            'Each operation in its own currency, with its rate',
          'imports.formatTexts.revolut' =>
            'Each operation in its own currency, with its fee',
          'imports.own' => 'A format of your own',
          'imports.ownTag' => 'any',
          'imports.ownText' => 'You give the columns their roles',
          'imports.fileKinds.csv' => 'CSV',
          'imports.fileKinds.xlsx' => 'Excel',
          'imports.fileKinds.pdf' => 'PDF',
          'imports.summaryTitle' => 'What enters the ledger',
          'imports.summaryFormat' => 'Format',
          'imports.summaryRows' => 'Rows in the file',
          'imports.summaryPeriod' => 'Period',
          'imports.summaryAccount' => 'Account',
          'imports.accountLater' => 'picked on step 4',
          'imports.summaryOperations' => 'Operations',
          'imports.summarySpent' => 'Spent',
          'imports.summaryReceived' => 'Received',
          'imports.summaryUnsorted' => 'No category',
          'imports.toInbox' =>
            ({required Object count}) => '${count} → the inbox',
          'imports.summaryBalance' => 'Balance after',
          'imports.summaryFromFile' => 'In the file',
          'imports.summaryCopies' => 'Copies skipped',
          'imports.summaryAdded' => 'To add',
          'imports.next.format' => 'Next: the bank',
          'imports.next.columns' => 'Next: the columns',
          'imports.next.account' => 'Next: the account',
          'imports.next.copies' => 'Next: duplicates',
          'imports.write' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Import ${count} operation',
                  other: 'Import ${count} operations',
                ),
          'imports.nothingToWrite' => 'Nothing to add',
          'imports.planning' => 'Counting…',
          'imports.writing' =>
            ({required Object done, required Object total}) =>
                'Writing: ${done} of ${total}',
          'imports.writeNote' =>
            'The whole import can be undone with one button',
          'imports.columnsTitle' => 'Columns of the file',
          'imports.roles.date' => 'Date',
          'imports.roles.amount' => 'Amount',
          'imports.roles.expense' => 'Spent',
          'imports.roles.income' => 'Received',
          'imports.roles.fee' => 'Fee',
          'imports.roles.currency' => 'Currency',
          'imports.roles.expenseCurrency' => 'Currency spent',
          'imports.roles.incomeCurrency' => 'Currency received',
          'imports.roles.account' => 'Account',
          'imports.roles.expenseAccount' => 'Account spent from',
          'imports.roles.incomeAccount' => 'Account received on',
          'imports.roles.description' => 'Description',
          'imports.roles.note' => 'Note',
          'imports.roles.category' => 'Category of the bank',
          'imports.roles.ownCategory' => 'Your category',
          'imports.roles.card' => 'Card',
          'imports.roles.balance' => 'Balance',
          'imports.roles.status' => 'Status',
          'imports.roles.skip' => 'Leave out',
          'imports.roleOf' =>
            ({required Object header}) => 'What the column «${header}» holds',
          'imports.signTitle' => 'Money spent is written',
          'imports.signs.expenseNegative' => 'with a minus',
          'imports.signs.expensePositive' => 'with a plus',
          'imports.signs.incomePlus' => 'without a sign',
          'imports.markTitle' => 'Cents are set apart by',
          'imports.marks.comma' => 'a comma',
          'imports.marks.dot' => 'a dot',
          'imports.datesTitle' => 'Dates',
          'imports.dateOrders.dayMonthYear' => 'DD.MM.YYYY',
          'imports.dateOrders.monthDayYear' => 'MM.DD.YYYY',
          'imports.missing' =>
            'Mark the column of the date and the column of the amount: without them rows do not become operations.',
          'imports.previewTitle' => 'How the rows enter the ledger',
          'imports.previewNote' =>
            ({required Object shown, required Object total}) =>
                'the first ${shown} of ${total} · headers and totals do not count',
          'imports.previewDate' => 'Date',
          'imports.previewText' => 'Description',
          'imports.previewCategory' => 'Category',
          'imports.previewAmount' => 'Amount',
          'imports.transfer' => 'Transfer',
          'imports.learned' => 'as before',
          'imports.inbox' => 'Decide in the inbox',
          'imports.problems' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} row did not read',
                  other: '${count} rows did not read',
                ),
          'imports.problemLine' =>
            ({required Object line, required Object fault}) =>
                'Row ${line}: ${fault}',
          'imports.andMore' => ({required Object count}) => 'and ${count} more',
          'imports.rowFaults.unreadableDate' => 'the date does not read',
          'imports.rowFaults.noSuchDay' => 'there is no such day',
          'imports.rowFaults.noAmount' => 'no amount',
          'imports.rowFaults.unreadableAmount' => 'the amount does not read',
          'imports.rowFaults.zeroAmount' => 'the amount is zero',
          'imports.rowFaults.declined' => 'the operation did not go through',
          'imports.categoriesTitle' => 'Categories of the bank → yours',
          'imports.categoriesNote' =>
            'Without a choice, operations wait in the inbox',
          'imports.categoryKinds.expense' => 'spent',
          'imports.categoryKinds.income' => 'received',
          'imports.noBankCategory' => 'No category of the bank',
          'imports.newCategory' => ({required Object name}) => 'New: ${name}',
          'imports.fees' => 'Fees of the bank',
          'imports.categoryOf' =>
            ({required Object name}) => 'The category for «${name}»',
          'imports.accountTitleCard' =>
            ({required Object card}) =>
                'Where the operations of the card ••${card} go',
          'imports.accountTitleNamed' =>
            ({required Object name}) => 'Where the operations of «${name}» go',
          'imports.accountTitle' => 'Where the operations go',
          'imports.accountText' =>
            ({required Object operations}) =>
                '${operations}. Pick an account of Birka, start a new one or leave them out.',
          'imports.cardMatched' => 'the card matched',
          'imports.nameMatched' => 'the name matched',
          'imports.otherCurrency' =>
            ({required Object currency, required Object fileCurrency}) =>
                '${currency}, and the file has ${fileCurrency}',
          'imports.newAccount' => 'A new account',
          'imports.newAccountText' =>
            ({required Object name, required Object balance}) =>
                'We start «${name}» with a balance of ${balance}',
          'imports.leaveOut' => 'Leave out',
          'imports.leaveOutText' =>
            'The operations of this account stay out of the ledger',
          'imports.balanceMatches' => 'The balance meets the bank',
          'imports.balanceDiffers' => 'The balance differs from the bank',
          'imports.balanceInFile' =>
            ({required Object day}) => 'In the statement on ${day}',
          'imports.balanceInBirka' => 'In Birka after the import',
          'imports.balanceHint' =>
            'The ledger has operations that the statement lacks, or the other way round. Check the account and the duplicates.',
          'imports.copiesTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} operation is already in the ledger',
                  other: '${count} operations are already in the ledger',
                ),
          'imports.copiesText' =>
            'You seem to have typed them in. The copies from the statement are skipped, and your records stay as they are, with your names and categories.',
          'imports.noCopies' => 'No duplicates',
          'imports.noCopiesText' =>
            'No operation of the statement looks like one of the ledger.',
          'imports.fromFile' => 'From the statement',
          'imports.inLedger' => 'Already in the ledger',
          'imports.reasons.imported' => 'from this very file',
          'imports.reasons.sameAmount' => 'the same amount',
          'imports.reasons.sameDay' => 'the same day',
          'imports.reasons.dayBefore' => 'a day before',
          'imports.reasons.dayAfter' => 'a day after',
          'imports.reasons.sameAccount' => 'the same account',
          'imports.reasons.similarName' => 'a similar name',
          'imports.skipCopy' => 'Skip the copy',
          'imports.keepBoth' => 'Keep both',
          'imports.leftTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} operation stays out of the ledger',
                  other: '${count} operations stay out of the ledger',
                ),
          'imports.planFaults.otherCurrency' =>
            'the account has another currency',
          'imports.planFaults.tooPrecise' =>
            'more digits than the currency has',
          'imports.planFaults.unevenTransfer' =>
            'a transfer in one currency with two amounts',
          'imports.doneTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Added ${count} operation',
                  other: 'Added ${count} operations',
                ),
          'imports.doneWhere' =>
            ({
              required Object format,
              required Object period,
              required Object accounts,
            }) => '${format}, ${period} → ${accounts}',
          'imports.doneIncome' => 'Received',
          'imports.doneSpent' => 'New spending',
          'imports.doneSkipped' => 'Copies skipped',
          'imports.doneBalance' => 'Balance of the account',
          'imports.asInBank' => 'as in the bank',
          'imports.unsortedTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} waits for you in the inbox',
                  other: '${count} wait for you in the inbox',
                ),
          'imports.unsortedText' =>
            'They count in the reports already, only without a category.',
          'imports.sortInbox' => 'Sort the inbox',
          'imports.undoTitle' => 'Changed your mind?',
          'imports.undoText' =>
            ({
              required num n,
              required Object count,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              n,
              one:
                  'The undo takes out ${count} operation of this file. Your records and other imports stay. You can undo it later too, under «Past imports».',
              other:
                  'The undo takes out ${count} operations of this file. Your records and other imports stay. You can undo it later too, under «Past imports».',
            ),
          'imports.undoImport' => 'Undo the import',
          'imports.undoneTitle' => 'The import is undone',
          'imports.undoneText' =>
            'The operations of this file are out of the ledger. Your records stay as they were.',
          'imports.toOperations' => 'To the operations',
          'imports.another' => 'Import another statement',
          'imports.monthsWhole.0' => 'January',
          'imports.monthsWhole.1' => 'February',
          'imports.monthsWhole.2' => 'March',
          'imports.monthsWhole.3' => 'April',
          'imports.monthsWhole.4' => 'May',
          'imports.monthsWhole.5' => 'June',
          'imports.monthsWhole.6' => 'July',
          'imports.monthsWhole.7' => 'August',
          'imports.monthsWhole.8' => 'September',
          'imports.monthsWhole.9' => 'October',
          'imports.monthsWhole.10' => 'November',
          'imports.monthsWhole.11' => 'December',
          'imports.periodMonth' =>
            ({required Object month, required Object year}) =>
                '${month} ${year}',
          'imports.periodInMonth' =>
            ({
              required Object month,
              required Object from,
              required Object to,
              required Object year,
            }) => '${month} ${from}–${to}, ${year}',
          'imports.periodInYear' =>
            ({
              required Object from,
              required Object to,
              required Object year,
            }) => '${from} – ${to}, ${year}',
          'imports.periodFar' =>
            ({required Object from, required Object to}) => '${from} – ${to}',
          'imports.cancel' => 'Cancel',
          'imports.finish' => 'Done',
          'imports.readingTitle' => 'Reading the statement',
          'imports.readingNote' =>
            'The file is read on this phone and goes nowhere',
          'imports.knownBy' =>
            ({required Object bank}) => '${bank} · told by the columns',
          'imports.operationsIn' =>
            ({required Object period}) => 'Operations for ${period}',
          'imports.alreadyIn' => 'Already in the ledger',
          'imports.willSkip' =>
            ({required Object count}) => '${count}, skipped',
          'imports.sortLater' => 'To sort later',
          'imports.inInbox' =>
            ({required Object count}) => '${count} in the inbox',
          'imports.unknownTitle' => 'The format is unknown',
          'imports.columnsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} column',
                  other: '${count} columns',
                ),
          'imports.rowsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} row',
                  other: '${count} rows',
                ),
          'imports.unknownText' =>
            'Set the columns of this file, where the date and the amount are. Birka reads the rest by itself.',
          'imports.chooseAnother' => 'Choose another file',
          'imports.assignColumns' => 'Set the columns',
          'imports.columnsHeading' => 'Columns of the statement',
          'imports.columnsText' =>
            'Mark where the file keeps the date and the amount, and its rows become operations.',
          'imports.roleNotes.date' => 'the day of the operation',
          'imports.roleNotes.amount' => 'money out and in, in one column',
          'imports.roleNotes.expense' => 'only money out',
          'imports.roleNotes.income' => 'only money in',
          'imports.roleNotes.currency' => 'RUB, USD, EUR…',
          'imports.roleNotes.description' =>
            'a shop, a payee or what it was for',
          'imports.roleNotes.category' => 'sorted in the inbox',
          'imports.roleNotes.balance' => 'checked against the bank',
          'imports.roleNotes.skip' => 'the column is left out',
          'imports.noAmounts' =>
            'No amount read. Check what the file puts before the cents.',
          'imports.columnsDone' =>
            ({required Object operations}) => 'Done · ${operations}',
          'imports.ownColumns' => 'columns set by you',
          'inbox.title' => 'Inbox',
          'inbox.back' => 'Back',
          'inbox.waiting' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} waits for you',
                  other: '${count} wait for you',
                ),
          'inbox.afterImport' =>
            ({required Object bank}) => 'after the import of ${bank}',
          'inbox.afterFile' =>
            ({required Object name}) => 'after the import of «${name}»',
          'inbox.filters.all' => 'All',
          'inbox.filters.uncategorized' => 'No category',
          'inbox.filters.transfers' => 'Transfers',
          'inbox.filtersLabel' => 'What to show',
          'inbox.emptyTitle' => 'All sorted',
          'inbox.emptyText' =>
            'Operations without a category and transfers between your accounts come here from statements.',
          'inbox.pairTitle' => 'Looks like a transfer between your accounts',
          'inbox.pairText' =>
            'Neither spending nor income: your capital stays the same',
          _ => null,
        } ??
        switch (path) {
          'inbox.rate' =>
            ({required Object rate, required Object unit}) =>
                'Rate ${rate} for ${unit}',
          'inbox.bankRate' =>
            ({required Object rate}) => 'the Bank of Russia that day ${rate}',
          'inbox.makeTransfer' => 'Make it a transfer',
          'inbox.notTransfer' => 'It is income',
          'inbox.fromStatement' => 'from the statement',
          'inbox.uncategorized' => 'No category',
          'inbox.section' =>
            ({required Object title, required Object count}) =>
                '${title} · ${count}',
          'inbox.category' => 'Category',
          'inbox.other' => 'Another',
          'inbox.yes' => 'Yes',
          'inbox.categoryFor' =>
            ({required Object name}) => 'The category for «${name}»',
          'inbox.sameName' =>
            ({required num n, required Object count, required Object when}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'as you marked it ${count} time ${when}',
                  other: 'as you marked it ${count} times ${when}',
                ),
          'inbox.everyMonth' =>
            ({required Object since}) => 'the same amount every month ${since}',
          'inbox.sameImport' =>
            ({required Object name}) => 'like «${name}» in this statement',
          'inbox.similarName' =>
            ({required Object name, required Object when}) =>
                'like «${name}» ${when}',
          'inbox.since' => ({required Object month}) => 'since ${month}',
          'inbox.more' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'and ${count} more operation',
                  other: 'and ${count} more operations',
                ),
          'inbox.picked' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} operation picked',
                  other: '${count} operations picked',
                ),
          'inbox.pickedCategory' => 'The category for the picked',
          'inbox.pickAll' => 'Pick all',
          'inbox.pickNone' => 'Pick none',
          'inbox.pick' => ({required Object name}) => 'Pick «${name}»',
          'inbox.sourceTitle' => 'Where the hints come from',
          'inbox.sourceText' =>
            'From your past choices: how you named these places before and which categories you gave them. Counted here, on the device.',
          'inbox.learns' =>
            'Each «Yes» teaches Birka: in the next statement such operations come with their category.',
          'inbox.stillCounted' =>
            'While an operation is here, it already counts in the ledger and the reports, only without a category.',
          'inbox.failed' => 'That did not work. Try again.',
          'inbox.madeTransfer' => 'Made a transfer',
          'inbox.accepted' =>
            ({required Object category}) =>
                '${category}: Birka will put such ones there next time',
          'inbox.sorted' =>
            ({required Object category, required Object operations}) =>
                '${category} · ${operations}',
          'inbox.keptIncome' => 'Kept as income',
          'inbox.toImport' => 'Import a statement',
          'inbox.hinted' => 'suggested',
          'inbox.newCategory' => 'New category',
          'inbox.unpick' => 'Clear',
          'onboarding.skip' => 'Skip',
          'onboarding.back' => 'Back',
          'onboarding.failed' => 'Could not save. Try again.',
          'onboarding.welcome.title' => 'All your money\nin one place',
          'onboarding.welcome.text' =>
            'Accounts in any currency and no bank passwords. Your data stays on your device.',
          'onboarding.welcome.start' => 'Get started',
          'onboarding.account.title' => 'Your first account',
          'onboarding.account.text' =>
            'Your capital starts here. You can change the balance at any time.',
          'onboarding.account.next' => 'Next',
          'onboarding.categories.title' => 'Categories',
          'onboarding.categories.text' =>
            'Take a ready set. You can change it at any time.',
          'onboarding.categories.short' => 'Short set',
          'onboarding.categories.full' => 'Full set',
          'onboarding.categories.count' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} category',
                  other: '${n} categories',
                ),
          'onboarding.categories.finish' => 'Done',
          'overview.capital' => 'Capital',
          'overview.rateOn' =>
            ({required Object day}) => 'Bank of Russia rate on ${day}',
          'overview.currencies' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} currency',
                  other: '${n} currencies',
                ),
          'overview.week' => 'Week',
          'overview.month' => 'Month',
          'overview.year' => 'Year',
          'overview.inWeek' => 'this week',
          'overview.inYear' => 'this year',
          'overview.chart' => 'The capital over time',
          'overview.accounts' => 'Accounts',
          'overview.allAccounts' => ({required Object n}) => 'All ${n}',
          'overview.spendingIn' =>
            ({required Object month}) => 'Spending ${month}',
          'overview.monthsIn.0' => 'in January',
          'overview.monthsIn.1' => 'in February',
          'overview.monthsIn.2' => 'in March',
          'overview.monthsIn.3' => 'in April',
          'overview.monthsIn.4' => 'in May',
          'overview.monthsIn.5' => 'in June',
          'overview.monthsIn.6' => 'in July',
          'overview.monthsIn.7' => 'in August',
          'overview.monthsIn.8' => 'in September',
          'overview.monthsIn.9' => 'in October',
          'overview.monthsIn.10' => 'in November',
          'overview.monthsIn.11' => 'in December',
          'overview.noSpending' => 'Nothing spent this month yet.',
          'overview.ring' => 'Spending by category',
          'overview.failed' => 'Could not read the overview.',
          'overview.hideAmounts' => 'Hide the amounts',
          'overview.showAmounts' => 'Show the amounts',
          'overview.changeIn.0' => 'in January',
          'overview.changeIn.1' => 'in February',
          'overview.changeIn.2' => 'in March',
          'overview.changeIn.3' => 'in April',
          'overview.changeIn.4' => 'in May',
          'overview.changeIn.5' => 'in June',
          'overview.changeIn.6' => 'in July',
          'overview.changeIn.7' => 'in August',
          'overview.changeIn.8' => 'in September',
          'overview.changeIn.9' => 'in October',
          'overview.changeIn.10' => 'in November',
          'overview.changeIn.11' => 'in December',
          'reports.expenses' => 'Expenses',
          'reports.income' => 'Income',
          'reports.byMonth' => 'By month',
          'reports.average' =>
            ({required Object amount}) => 'average ${amount}',
          'reports.noExpenses' => 'Nothing spent this month.',
          'reports.noIncome' => 'Nothing earned this month.',
          'reports.ring' => 'Shares of the categories',
          'reports.dayRates' =>
            'Bank of Russia rate on the day of each operation',
          'reports.failed' => 'Could not read the report.',
          'reports.against.0' => 'vs January',
          'reports.against.1' => 'vs February',
          'reports.against.2' => 'vs March',
          'reports.against.3' => 'vs April',
          'reports.against.4' => 'vs May',
          'reports.against.5' => 'vs June',
          'reports.against.6' => 'vs July',
          'reports.against.7' => 'vs August',
          'reports.against.8' => 'vs September',
          'reports.against.9' => 'vs October',
          'reports.against.10' => 'vs November',
          'reports.against.11' => 'vs December',
          'reports.monthsShort.0' => 'Jan',
          'reports.monthsShort.1' => 'Feb',
          'reports.monthsShort.2' => 'Mar',
          'reports.monthsShort.3' => 'Apr',
          'reports.monthsShort.4' => 'May',
          'reports.monthsShort.5' => 'Jun',
          'reports.monthsShort.6' => 'Jul',
          'reports.monthsShort.7' => 'Aug',
          'reports.monthsShort.8' => 'Sep',
          'reports.monthsShort.9' => 'Oct',
          'reports.monthsShort.10' => 'Nov',
          'reports.monthsShort.11' => 'Dec',
          'settings.general' => 'General',
          'settings.language' => 'Language',
          'settings.deviceLanguage' => 'Same as the device',
          'settings.english' => 'English',
          'settings.russian' => 'Русский',
          'settings.baseCurrency' => 'Base currency',
          'settings.firstAccountCurrency' => 'First account',
          'settings.ratesCredit' => 'Курсы ЦБ РФ в XML и JSON, API',
          'settings.security' => 'Security',
          'settings.hideAmounts' => 'Hide amounts',
          'settings.onLaunch' => 'At launch',
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
          'transactions.noCategoriesHint' =>
            'Add categories to sort your money.',
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
            'Tap the plus to record the first one.',
          'transactions.noAccountOperations' =>
            'Nothing has happened on this account yet.',
          'transactions.balanceChart' => 'Balance over the period',
          'transactions.accountGone' => 'This account is gone.',
          'transactions.nothingFound' => 'Nothing found',
          'transactions.failedToReadOperations' =>
            'Could not read the operations.',
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

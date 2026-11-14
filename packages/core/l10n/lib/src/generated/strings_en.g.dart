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
  late final Translations$ask$en ask = Translations$ask$en.internal(_root);
  late final Translations$backup$en backup = Translations$backup$en.internal(
    _root,
  );
  late final Translations$categories$en categories =
      Translations$categories$en.internal(_root);
  late final Translations$debts$en debts = Translations$debts$en.internal(
    _root,
  );
  late final Translations$demo$en demo = Translations$demo$en.internal(_root);
  late final Translations$help$en help = Translations$help$en.internal(_root);
  late final Translations$imports$en imports = Translations$imports$en.internal(
    _root,
  );
  late final Translations$inbox$en inbox = Translations$inbox$en.internal(
    _root,
  );
  late final Translations$notifications$en notifications =
      Translations$notifications$en.internal(_root);
  late final Translations$onboarding$en onboarding =
      Translations$onboarding$en.internal(_root);
  late final Translations$overview$en overview =
      Translations$overview$en.internal(_root);
  late final Translations$reports$en reports = Translations$reports$en.internal(
    _root,
  );
  late final Translations$schedules$en schedules =
      Translations$schedules$en.internal(_root);
  late final Translations$settings$en settings =
      Translations$settings$en.internal(_root);
  late final Translations$tags$en tags = Translations$tags$en.internal(_root);
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

// Path: ask
class Translations$ask$en {
  Translations$ask$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Ask'
  String get title => 'Ask';

  /// en: 'Ask'
  String get open => 'Ask';

  /// en: 'Ask about your money'
  String get hint => 'Ask about your money';

  /// en: 'Clear the question'
  String get clear => 'Clear the question';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'You can ask'
  String get examples => 'You can ask';

  /// en: 'Recent'
  String get recent => 'Recent';

  /// en: 'Clear'
  String get forget => 'Clear';

  /// en: 'The app answers by itself: questions and answers stay on this device.'
  String get private =>
      'The app answers by itself: questions and answers stay on this device.';

  /// en: 'Could not read the data for an answer.'
  String get failed => 'Could not read the data for an answer.';

  /// en: 'The app answers by itself: questions and answers stay in this browser.'
  String get privateWeb =>
      'The app answers by itself: questions and answers stay in this browser.';

  /// en: 'The / key opens Ask from any page.'
  String get slash => 'The / key opens Ask from any page.';

  late final Translations$ask$start$en start =
      Translations$ask$start$en.internal(_root);
  late final Translations$ask$example$en example =
      Translations$ask$example$en.internal(_root);

  /// en: 'Read as'
  String get understood => 'Read as';

  late final Translations$ask$side$en side = Translations$ask$side$en.internal(
    _root,
  );

  /// en: 'Over $amount'
  String above({required Object amount}) => 'Over ${amount}';

  /// en: 'Under $amount'
  String below({required Object amount}) => 'Under ${amount}';

  /// en: '“$word”'
  String word({required Object word}) => '“${word}”';

  /// en: 'All time'
  String get allTime => 'All time';

  late final Translations$ask$answer$en answer =
      Translations$ask$answer$en.internal(_root);
  late final Translations$ask$before$en before =
      Translations$ask$before$en.internal(_root);
  late final Translations$ask$period$en period =
      Translations$ask$period$en.internal(_root);
  late final Translations$ask$fact$en fact = Translations$ask$fact$en.internal(
    _root,
  );
  late final Translations$ask$help$en help = Translations$ask$help$en.internal(
    _root,
  );
  late final Translations$ask$places$en places =
      Translations$ask$places$en.internal(_root);
  late final Translations$ask$refused$en refused =
      Translations$ask$refused$en.internal(_root);
  late final Translations$ask$suggest$en suggest =
      Translations$ask$suggest$en.internal(_root);
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

  /// en: 'How it works'
  String get howTitle => 'How it works';

  List<String> get how => [
    'Click a category, and it opens here, beside the list.',
    'Expenses and income are separate lists: the switch above them picks one.',
    'Categories show in operations, reports and regular payments.',
  ];
}

// Path: debts
class Translations$debts$en {
  Translations$debts$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Debts'
  String get title => 'Debts';

  /// en: 'More'
  String get toMore => 'More';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'Done'
  String get done => 'Done';

  /// en: 'Show the settled ones'
  String get foldClosed => 'Show the settled ones';

  /// en: 'Who owes whom, and by what day'
  String get moreHint => 'Who owes whom, and by what day';

  /// en: 'Owed to me $owed · mine $mine'
  String moreBoth({required Object owed, required Object mine}) =>
      'Owed to me ${owed} · mine ${mine}';

  /// en: 'Owed to me $owed'
  String moreOwed({required Object owed}) => 'Owed to me ${owed}';

  /// en: 'My debts $mine'
  String moreMine({required Object mine}) => 'My debts ${mine}';

  /// en: 'Owed to me'
  String get owedToMe => 'Owed to me';

  /// en: 'My debts'
  String get myDebts => 'My debts';

  /// en: '(one) {$n person} (other) {$n people}'
  String people({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} person',
        other: '${n} people',
      );

  /// en: 'Settled · $n'
  String closed({required Object n}) => 'Settled · ${n}';

  /// en: 'Debts are not in the capital: this money is not on your accounts now.'
  String get caption =>
      'Debts are not in the capital: this money is not on your accounts now.';

  /// en: 'Debts are not in the capital: this money is not on your accounts now. Other currencies at today's CBR rate.'
  String get captionRates =>
      'Debts are not in the capital: this money is not on your accounts now. Other currencies at today\'s CBR rate.';

  /// en: 'Could not read the debts.'
  String get failed => 'Could not read the debts.';

  /// en: 'This debt is gone.'
  String get gone => 'This debt is gone.';

  /// en: 'No debts'
  String get emptyTitle => 'No debts';

  /// en: 'Write down whom you lent to or borrowed from: Birka shows how much is left and by what day.'
  String get emptyText =>
      'Write down whom you lent to or borrowed from: Birka shows how much is left and by what day.';

  /// en: 'Add a debt'
  String get add => 'Add a debt';

  /// en: 'New debt'
  String get newDebt => 'New debt';

  late final Translations$debts$line$en line =
      Translations$debts$line$en.internal(_root);
  late final Translations$debts$card$en card =
      Translations$debts$card$en.internal(_root);

  /// en: '(one) {in $n day} (other) {in $n days}'
  String inDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'in ${n} day',
        other: 'in ${n} days',
      );

  late final Translations$debts$form$en form =
      Translations$debts$form$en.internal(_root);
  late final Translations$debts$back$en back =
      Translations$debts$back$en.internal(_root);
  late final Translations$debts$steps$en steps =
      Translations$debts$steps$en.internal(_root);

  /// en: 'How it works'
  String get howItWorks => 'How it works';

  late final Translations$debts$move$en move =
      Translations$debts$move$en.internal(_root);
  late final Translations$debts$person$en person =
      Translations$debts$person$en.internal(_root);
  late final Translations$debts$remind$en remind =
      Translations$debts$remind$en.internal(_root);
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

  late final Translations$demo$people$en people =
      Translations$demo$people$en.internal(_root);
  late final Translations$demo$debtNotes$en debtNotes =
      Translations$demo$debtNotes$en.internal(_root);
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

  /// en: 'Your own format, as before'
  String get looksLikeOwn => 'Your own format, as before';

  /// en: 'Categories of the bank'
  String get categoriesHeading => 'Categories of the bank';

  /// en: '(one) {$count category in the statement} (other) {$count categories in the statement}'
  String categoriesCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} category in the statement',
        other: '${count} categories in the statement',
      );

  /// en: '$known of $total recognized by Birka'
  String categoriesKnown({required Object known, required Object total}) =>
      '${known} of ${total} recognized by Birka';

  /// en: 'Birka doesn't know them yet'
  String get categoriesNone => 'Birka doesn\'t know them yet';

  /// en: 'As in the last statement'
  String get categoriesAsBefore => 'As in the last statement';

  /// en: '$known of $total recognized by their names. Operations go straight into your categories, and without a choice they wait in the inbox.'
  String categoriesKnownText({required Object known, required Object total}) =>
      '${known} of ${total} recognized by their names. Operations go straight into your categories, and without a choice they wait in the inbox.';

  /// en: 'Choose where the operations of each category of the bank go. Without a choice they wait in the inbox.'
  String get categoriesText =>
      'Choose where the operations of each category of the bank go. Without a choice they wait in the inbox.';

  /// en: 'Your choice for the last statement of $source. Change it if something is different now.'
  String categoriesAsBeforeText({required Object source}) =>
      'Your choice for the last statement of ${source}. Change it if something is different now.';

  /// en: 'your format'
  String get ownFormatOf => 'your format';

  /// en: 'operations wait without a category'
  String get inboxNote => 'operations wait without a category';

  /// en: 'made with the import'
  String get newCategoryNote => 'made with the import';

  /// en: 'new category'
  String get newCategoryMark => 'new category';

  /// en: 'Done · $count in the inbox'
  String categoriesDone({required Object count}) =>
      'Done · ${count} in the inbox';

  /// en: 'Birka keeps the choice for statements of $source'
  String categoriesKept({required Object source}) =>
      'Birka keeps the choice for statements of ${source}';

  /// en: 'Regular payments'
  String get foundHeading => 'Regular payments';

  /// en: 'found $count: $names'
  String foundLine({required Object count, required Object names}) =>
      'found ${count}: ${names}';

  /// en: '(one) {Posted $count payment} (other) {Posted $count payments}'
  String foundDone({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Posted ${count} payment',
        other: 'Posted ${count} payments',
      );

  /// en: '$names, from the statement'
  String foundDoneText({required Object names}) =>
      '${names}, from the statement';

  /// en: 'Looks regular · $count'
  String repeatsTitle({required Object count}) => 'Looks regular · ${count}';

  /// en: '$names and $last'
  String namesAnd({required Object names, required Object last}) =>
      '${names} and ${last}';

  /// en: '(one) {$count row stays out of the ledger} (other) {$count rows stay out of the ledger}'
  String rowsLeft({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} row stays out of the ledger',
        other: '${count} rows stay out of the ledger',
      );

  /// en: '(one) {$count did not read} (other) {$count did not read}'
  String unreadCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} did not read',
        other: '${count} did not read',
      );

  /// en: '(one) {$count did not go through the bank} (other) {$count did not go through the bank}'
  String declinedCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} did not go through the bank',
        other: '${count} did not go through the bank',
      );

  /// en: '(one) {$count does not fit its account} (other) {$count do not fit their account}'
  String unfitCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} does not fit its account',
        other: '${count} do not fit their account',
      );

  /// en: '(one) {$count more is fine} (other) {the other $count are fine}'
  String restFine({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} more is fine',
        other: 'the other ${count} are fine',
      );

  /// en: 'Did not read'
  String get unreadTitle => 'Did not read';

  /// en: 'Did not go through the bank'
  String get declinedTitle => 'Did not go through the bank';

  /// en: 'Do not fit the account'
  String get unfitTitle => 'Do not fit the account';

  /// en: 'Row $line · $what'
  String rowLine({required Object line, required Object what}) =>
      'Row ${line} · ${what}';

  /// en: 'Record the unread ones by hand or download the statement again: Birka adds only what the ledger does not have yet.'
  String get leftNote =>
      'Record the unread ones by hand or download the statement again: Birka adds only what the ledger does not have yet.';

  /// en: 'Got it'
  String get understood => 'Got it';

  /// en: 'The bank has $amount'
  String bankHas({required Object amount}) => 'The bank has ${amount}';

  /// en: 'The bank has $amount: rows that did not read seem to be missing'
  String bankHasMissing({required Object amount}) =>
      'The bank has ${amount}: rows that did not read seem to be missing';

  /// en: '(one) {$count row of $total did not read} (other) {$count rows of $total did not read}'
  String mostUnread({
    required num n,
    required Object count,
    required Object total,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one: '${count} row of ${total} did not read',
    other: '${count} rows of ${total} did not read',
  );

  /// en: 'The bank seems to have changed its statement: check where its date and amount are and what comes before the cents.'
  String get mostUnreadText =>
      'The bank seems to have changed its statement: check where its date and amount are and what comes before the cents.';

  /// en: 'Check the columns'
  String get checkColumns => 'Check the columns';

  /// en: '(one) {$count operation did not go through the bank} (other) {$count operations did not go through the bank}'
  String declinedRows({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} operation did not go through the bank',
        other: '${count} operations did not go through the bank',
      );
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

  /// en: '(one) {$count waits for you in the inbox} (other) {$count wait for you in the inbox}'
  String entryTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} waits for you in the inbox',
        other: '${count} wait for you in the inbox',
      );

  /// en: '$count without a category'
  String entryUncategorized({required Object count}) =>
      '${count} without a category';

  /// en: 'a transfer from «$account»'
  String entryTransfer({required Object account}) =>
      'a transfer from «${account}»';

  /// en: '(one) {$count transfer between accounts} (other) {$count transfers between accounts}'
  String entryTransfers({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} transfer between accounts',
        other: '${count} transfers between accounts',
      );

  /// en: '$first and $second'
  String entryBoth({required Object first, required Object second}) =>
      '${first} and ${second}';

  /// en: 'Clear'
  String get unpick => 'Clear';
}

// Path: notifications
class Translations$notifications$en {
  Translations$notifications$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Notifications'
  String get title => 'Notifications';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Notifications'
  String get bell => 'Notifications';

  /// en: '(one) {Notifications, $count new} (other) {Notifications, $count new}'
  String bellNew({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Notifications, ${count} new',
        other: 'Notifications, ${count} new',
      );

  /// en: 'New · $count'
  String fresh({required Object count}) => 'New · ${count}';

  /// en: 'Mark all read'
  String get readAll => 'Mark all read';

  /// en: '(one) {$count new · 90 days of history} (other) {$count new · 90 days of history}'
  String subtitleNew({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${count} new · 90 days of history',
        other: '${count} new · 90 days of history',
      );

  /// en: 'All read · 90 days of history'
  String get subtitleRead => 'All read · 90 days of history';

  Map<String, String> get filters => {
    'all': 'All',
    'payment': 'Payments',
    'debt': 'Debts',
    'import': 'Imports',
  };

  /// en: 'Whose notifications'
  String get filtersLabel => 'Whose notifications';

  /// en: 'All quiet'
  String get emptyTitle => 'All quiet';

  /// en: 'Reminders of your payments and of the days of your debts, and the results of imports, come here.'
  String get emptyText =>
      'Reminders of your payments and of the days of your debts, and the results of imports, come here.';

  /// en: 'The results of your statement imports come here.'
  String get emptyImports => 'The results of your statement imports come here.';

  /// en: 'Could not read the notifications.'
  String get failed => 'Could not read the notifications.';

  /// en: 'Birka keeps notifications for 90 days'
  String get keeps => 'Birka keeps notifications for 90 days';

  /// en: 'yesterday'
  String get yesterday => 'yesterday';

  /// en: 'Tomorrow, $date'
  String tomorrow({required Object date}) => 'Tomorrow, ${date}';

  /// en: 'Today, waits for you'
  String get waitsToday => 'Today, waits for you';

  /// en: 'Waits for you'
  String get waits => 'Waits for you';

  /// en: 'Today, it posts itself'
  String get postsToday => 'Today, it posts itself';

  /// en: 'Posts itself'
  String get posts => 'Posts itself';

  /// en: 'Posted at $time'
  String posted({required Object time}) => 'Posted at ${time}';

  /// en: 'Posted on $date'
  String postedOn({required Object date}) => 'Posted on ${date}';

  /// en: 'Posted itself'
  String get postedItself => 'Posted itself';

  /// en: 'Skipped · next on $date'
  String skipped({required Object date}) => 'Skipped · next on ${date}';

  /// en: 'Found in a statement'
  String get found => 'Found in a statement';

  /// en: '$bank · $period'
  String importTitle({required Object bank, required Object period}) =>
      '${bank} · ${period}';

  /// en: '(one) {$n of $count waits in the inbox} (other) {$n of $count wait in the inbox}'
  String importWaiting({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} of ${count} waits in the inbox',
        other: '${n} of ${count} wait in the inbox',
      );

  /// en: '(one) {Added $count operation} (other) {Added $count operations}'
  String importAdded({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Added ${count} operation',
        other: 'Added ${count} operations',
      );

  /// en: 'Import undone'
  String get importUndone => 'Import undone';

  /// en: 'Due · $name, $amount'
  String debtTitle({required Object name, required Object amount}) =>
      'Due · ${name}, ${amount}';

  /// en: 'Due today · $name, $amount'
  String debtTitleToday({required Object name, required Object amount}) =>
      'Due today · ${name}, ${amount}';

  /// en: 'since $date'
  String debtSince({required Object date}) => 'since ${date}';

  /// en: '$note · since $date'
  String debtNoteSince({required Object note, required Object date}) =>
      '${note} · since ${date}';

  /// en: 'Paid back $date'
  String debtReturned({required Object date}) => 'Paid back ${date}';

  /// en: 'You paid back $date'
  String debtRepaid({required Object date}) => 'You paid back ${date}';

  /// en: 'Part paid back · $left left'
  String debtReturnedPart({required Object left}) =>
      'Part paid back · ${left} left';

  /// en: 'You paid back a part · $left left'
  String debtRepaidPart({required Object left}) =>
      'You paid back a part · ${left} left';

  /// en: 'Not paid back yet · $left left'
  String debtWaits({required Object left}) =>
      'Not paid back yet · ${left} left';

  /// en: 'Not paid back yet · $left left'
  String debtWaitsRepaid({required Object left}) =>
      'Not paid back yet · ${left} left';

  /// en: 'This debt is no longer here'
  String get debtGone => 'This debt is no longer here';

  /// en: 'today'
  String get today => 'today';

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

  /// en: 'What comes here'
  String get howTitle => 'What comes here';

  List<String> get how => [
    '«Payments»: a regular payment that waits for your «Post».',
    '«Imports»: what a statement brought, and what waits in the «Inbox».',
    '«Birka»: what is new in Birka itself.',
    'New ones stand on top; read ones go to the history, day by day.',
  ];
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
  List<String> get monthReport => [
    'Report for January',
    'Report for February',
    'Report for March',
    'Report for April',
    'Report for May',
    'Report for June',
    'Report for July',
    'Report for August',
    'Report for September',
    'Report for October',
    'Report for November',
    'Report for December',
  ];
}

// Path: schedules
class Translations$schedules$en {
  Translations$schedules$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Regular payments'
  String get title => 'Regular payments';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'New payment'
  String get add => 'New payment';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'Waits for you'
  String get waitingTitle => 'Waits for you';

  /// en: 'Post'
  String get post => 'Post';

  /// en: 'Skip'
  String get skip => 'Skip';

  /// en: 'When it comes in a bank statement, Birka will not count it twice.'
  String get waitingNote =>
      'When it comes in a bank statement, Birka will not count it twice.';

  /// en: '$name · $day'
  String waitingDay({required Object name, required Object day}) =>
      '${name} · ${day}';

  /// en: 'The next 30 days'
  String get ahead => 'The next 30 days';

  /// en: 'until $date $amount'
  String aheadTotal({required Object date, required Object amount}) =>
      'until ${date} ${amount}';

  /// en: 'By the salary on $date your accounts will hold ≈ $amount, before everyday spending.'
  String leftAfterPayday({required Object date, required Object amount}) =>
      'By the salary on ${date} your accounts will hold ≈ ${amount}, before everyday spending.';

  /// en: 'By the end of the month your accounts will hold ≈ $amount, before everyday spending.'
  String leftAfterMonth({required Object amount}) =>
      'By the end of the month your accounts will hold ≈ ${amount}, before everyday spending.';

  /// en: 'By the salary on $date your accounts will hold ≈ $amount with the advance, before everyday spending.'
  String leftAfterPaydayAdvance({
    required Object date,
    required Object amount,
  }) =>
      'By the salary on ${date} your accounts will hold ≈ ${amount} with the advance, before everyday spending.';

  /// en: 'By the end of the month your accounts will hold ≈ $amount with the advance, before everyday spending.'
  String leftAfterMonthAdvance({required Object amount}) =>
      'By the end of the month your accounts will hold ≈ ${amount} with the advance, before everyday spending.';

  /// en: '$title · $count'
  String section({required Object title, required Object count}) =>
      '${title} · ${count}';

  /// en: 'All regular payments'
  String get all => 'All regular payments';

  /// en: 'No regular payments yet'
  String get emptyTitle => 'No regular payments yet';

  /// en: 'Rent, subscriptions, salary: add them once, and Birka shows the month ahead and how much you can spend a day.'
  String get emptyText =>
      'Rent, subscriptions, salary: add them once, and Birka shows the month ahead and how much you can spend a day.';

  /// en: 'Add a payment'
  String get emptyAdd => 'Add a payment';

  /// en: 'every month on day $day'
  String everyMonth({required Object day}) => 'every month on day ${day}';

  /// en: 'every week, $weekday'
  String everyWeek({required Object weekday}) => 'every week, ${weekday}';

  /// en: 'once a year, $date'
  String everyYear({required Object date}) => 'once a year, ${date}';

  /// en: 'ask'
  String get asks => 'ask';

  /// en: 'posts itself'
  String get posts => 'posts itself';

  /// en: 'today'
  String get today => 'today';

  /// en: 'tomorrow'
  String get tomorrow => 'tomorrow';

  /// en: 'Posted «$name» · $amount'
  String posted({required Object name, required Object amount}) =>
      'Posted «${name}» · ${amount}';

  /// en: 'Skipped «$name» · we will ask on $date'
  String skippedAsk({required Object name, required Object date}) =>
      'Skipped «${name}» · we will ask on ${date}';

  /// en: 'Skipped «$name» · next on $date'
  String skippedPost({required Object name, required Object date}) =>
      'Skipped «${name}» · next on ${date}';

  /// en: 'Deleted «$name»'
  String deleted({required Object name}) => 'Deleted «${name}»';

  /// en: 'Found «$name» in a statement'
  String found({required Object name}) => 'Found «${name}» in a statement';

  /// en: 'Found «$name» in the statement of $bank'
  String foundOf({required Object name, required Object bank}) =>
      'Found «${name}» in the statement of ${bank}';

  /// en: '$date · $amount · marked as posted, no copy will come'
  String foundText({required Object date, required Object amount}) =>
      '${date} · ${amount} · marked as posted, no copy will come';

  /// en: 'posted today · next on $date'
  String donePosted({required Object date}) => 'posted today · next on ${date}';

  /// en: 'skipped · next on $date'
  String doneSkipped({required Object date}) => 'skipped · next on ${date}';

  /// en: 'found in a statement · next on $date'
  String doneFound({required Object date}) =>
      'found in a statement · next on ${date}';

  Map<String, String> get on => {
    'mon': 'on Mondays',
    'tue': 'on Tuesdays',
    'wed': 'on Wednesdays',
    'thu': 'on Thursdays',
    'fri': 'on Fridays',
    'sat': 'on Saturdays',
    'sun': 'on Sundays',
  };
  Map<String, String> get weekday => {
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
    'sun': 'Sun',
  };

  /// en: 'New payment'
  String get newTitle => 'New payment';

  Map<String, String> get kinds => {
    'expense': 'Expense',
    'income': 'Income',
    'transfer': 'Transfer',
  };

  /// en: 'What kind of payment'
  String get kindLabel => 'What kind of payment';

  /// en: 'Amount'
  String get amount => 'Amount';

  /// en: 'Name'
  String get name => 'Name';

  /// en: 'Rent, for example'
  String get namePlaceholder => 'Rent, for example';

  /// en: 'Category'
  String get category => 'Category';

  /// en: 'No category'
  String get noCategory => 'No category';

  /// en: 'to sort in the inbox'
  String get categoryLater => 'to sort in the inbox';

  /// en: 'Account'
  String get account => 'Account';

  /// en: 'To'
  String get toAccount => 'To';

  /// en: 'From'
  String get fromAccount => 'From';

  /// en: 'To the account'
  String get incomeAccount => 'To the account';

  /// en: 'Pick an account'
  String get pickAccount => 'Pick an account';

  /// en: 'Repeat every'
  String get every => 'Repeat every';

  Map<String, String> get everyOptions => {
    'month': 'Month',
    'week': 'Week',
    'year': 'Year',
  };

  /// en: 'Day of the month'
  String get dayOfMonth => 'Day of the month';

  /// en: 'Day of the week'
  String get dayOfWeek => 'Day of the week';

  /// en: 'Day of the year'
  String get dayOfYear => 'Day of the year';

  /// en: 'day $day'
  String dayNumber({required Object day}) => 'day ${day}';

  /// en: 'Next time'
  String get next => 'Next time';

  /// en: 'On its day'
  String get onDayTitle => 'On its day';

  Map<String, String> get onDay => {
    'ask': 'Ask me',
    'post': 'Post itself',
  };

  /// en: 'Good for an amount that changes, like utility bills: on its day the payment waits for your «Post».'
  String get askNote =>
      'Good for an amount that changes, like utility bills: on its day the payment waits for your «Post».';

  /// en: 'For subscriptions of one amount. When it comes in a bank statement, there will be no copy.'
  String get postNote =>
      'For subscriptions of one amount. When it comes in a bank statement, there will be no copy.';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Shows up in «The next payments» and in «You can spend today»'
  String get saveNote =>
      'Shows up in «The next payments» and in «You can spend today»';

  /// en: 'Changes from the next time: $date'
  String changeNote({required Object date}) =>
      'Changes from the next time: ${date}';

  /// en: 'Done'
  String get done => 'Done';

  /// en: 'Delete the payment'
  String get delete => 'Delete the payment';

  /// en: 'Past operations stay'
  String get deleteNote => 'Past operations stay';

  /// en: 'Delete «$name»?'
  String deleteTitle({required Object name}) => 'Delete «${name}»?';

  /// en: 'You can spend today'
  String get canSpend => 'You can spend today';

  /// en: 'Today is over the daily amount'
  String get overToday => 'Today is over the daily amount';

  /// en: 'of $amount a day'
  String ofPerDay({required Object amount}) => 'of ${amount} a day';

  /// en: 'Spent $amount · $days to the salary'
  String spentUntilPayday({required Object amount, required Object days}) =>
      'Spent ${amount} · ${days} to the salary';

  /// en: 'Spent $amount · $days to the end of the month'
  String spentUntilMonth({required Object amount, required Object days}) =>
      'Spent ${amount} · ${days} to the end of the month';

  /// en: 'Spent $amount · tomorrow you can spend $tomorrow a day'
  String spentOver({required Object amount, required Object tomorrow}) =>
      'Spent ${amount} · tomorrow you can spend ${tomorrow} a day';

  /// en: '$amount short until $date'
  String short({required Object amount, required Object date}) =>
      '${amount} short until ${date}';

  /// en: 'The next payments'
  String get upcoming => 'The next payments';

  /// en: 'Until the salary'
  String get noPaydayLabel => 'Until the salary';

  /// en: 'How much can you spend a day?'
  String get noPaydayTitle => 'How much can you spend a day?';

  /// en: 'Tell Birka your payday. It takes the regular payments until then away and splits the rest between the days.'
  String get noPaydayText =>
      'Tell Birka your payday. It takes the regular payments until then away and splits the rest between the days.';

  /// en: 'Set the payday'
  String get noPaydayAction => 'Set the payday';

  /// en: '(one) {$n day} (other) {$n days}'
  String days({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} day',
        other: '${n} days',
      );

  /// en: 'Money until the salary'
  String get paydayTitle => 'Money until the salary';

  /// en: '$amount a day'
  String perDay({required Object amount}) => '${amount} a day';

  /// en: '$amount short'
  String notEnough({required Object amount}) => '${amount} short';

  /// en: 'until the salary on $date · $days'
  String untilPayday({required Object date, required Object days}) =>
      'until the salary on ${date} · ${days}';

  /// en: 'until $date · $days'
  String untilDate({required Object date, required Object days}) =>
      'until ${date} · ${days}';

  /// en: 'In the accounts this morning'
  String get morning => 'In the accounts this morning';

  /// en: '(one) {$n payment until the salary} (other) {$n payments until the salary}'
  String paymentsUntilPayday({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment until the salary',
        other: '${n} payments until the salary',
      );

  /// en: '(one) {$n payment until the end of the month} (other) {$n payments until the end of the month}'
  String paymentsUntilMonth({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment until the end of the month',
        other: '${n} payments until the end of the month',
      );

  /// en: 'Keep aside'
  String get aside => 'Keep aside';

  /// en: '(one) {Left for $n day} (other) {Left for $n days}'
  String leftFor({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Left for ${n} day',
        other: 'Left for ${n} days',
      );

  /// en: 'Count until'
  String get countUntil => 'Count until';

  Map<String, String> get until => {
    'payday': 'The payday',
    'monthEnd': 'The end of the month',
  };

  /// en: 'Payday'
  String get payday => 'Payday';

  /// en: 'from the payment «$name»'
  String paydayFrom({required Object name}) => 'from the payment «${name}»';

  /// en: 'add a regular income'
  String get paydayNone => 'add a regular income';

  /// en: 'day $day'
  String paydayDay({required Object day}) => 'day ${day}';

  /// en: 'Which accounts to count'
  String get accountsTitle => 'Which accounts to count';

  /// en: 'Count «$name»'
  String count({required Object name}) => 'Count «${name}»';

  /// en: 'another currency, not counted yet'
  String get otherCurrency => 'another currency, not counted yet';

  /// en: 'Keep aside until the salary'
  String get asideRow => 'Keep aside until the salary';

  /// en: 'not to spend, even if «you can»'
  String get asideNote => 'not to spend, even if «you can»';

  /// en: 'Salary'
  String get salaryName => 'Salary';

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

  /// en: 'Advance'
  String get advance => 'Advance';

  /// en: 'the advance on day $advance and the salary on day $day'
  String everyTwice({required Object advance, required Object day}) =>
      'the advance on day ${advance} and the salary on day ${day}';

  /// en: 'advance posted today · salary on $date'
  String advancePosted({required Object date}) =>
      'advance posted today · salary on ${date}';

  /// en: 'advance skipped · salary on $date'
  String advanceSkipped({required Object date}) =>
      'advance skipped · salary on ${date}';

  /// en: 'advance found in a statement · salary on $date'
  String advanceFound({required Object date}) =>
      'advance found in a statement · salary on ${date}';

  /// en: 'salary posted today · advance on $date'
  String restPosted({required Object date}) =>
      'salary posted today · advance on ${date}';

  /// en: 'salary skipped · advance on $date'
  String restSkipped({required Object date}) =>
      'salary skipped · advance on ${date}';

  /// en: 'salary found in a statement · advance on $date'
  String restFound({required Object date}) =>
      'salary found in a statement · advance on ${date}';

  /// en: 'Advance on $date'
  String advanceOn({required Object date}) => 'Advance on ${date}';

  /// en: 'Until the advance on $date: $amount for $days'
  String nearEnough({
    required Object date,
    required Object amount,
    required Object days,
  }) => 'Until the advance on ${date}: ${amount} for ${days}';

  /// en: 'Until the advance on $date, $amount short'
  String nearShort({required Object date, required Object amount}) =>
      'Until the advance on ${date}, ${amount} short';

  /// en: 'Advance and salary'
  String get paydayTwice => 'Advance and salary';

  /// en: 'days $advance and $day'
  String paydayTwiceDays({required Object advance, required Object day}) =>
      'days ${advance} and ${day}';

  /// en: 'How it comes'
  String get partsTitle => 'How it comes';

  Map<String, String> get parts => {
    'one': 'One sum',
    'two': 'With an advance',
  };

  /// en: 'The whole sum comes on one day.'
  String get partsOne => 'The whole sum comes on one day.';

  /// en: 'Half and half: the advance on day $advance, the salary on day $day.'
  String partsTwo({required Object advance, required Object day}) =>
      'Half and half: the advance on day ${advance}, the salary on day ${day}.';

  /// en: 'The advance of $advanceAmount on day $advance, the salary of $restAmount on day $day.'
  String partsOwn({
    required Object advanceAmount,
    required Object advance,
    required Object restAmount,
    required Object day,
  }) =>
      'The advance of ${advanceAmount} on day ${advance}, the salary of ${restAmount} on day ${day}.';

  /// en: 'Amount a month'
  String get amountMonthly => 'Amount a month';

  /// en: '$amount as the advance and as the salary'
  String halves({required Object amount}) =>
      '${amount} as the advance and as the salary';

  /// en: 'the advance of $advance and the salary of $rest'
  String halvesOwn({required Object advance, required Object rest}) =>
      'the advance of ${advance} and the salary of ${rest}';

  /// en: 'The sum does not split into equal halves: change the cents'
  String get halvesUneven =>
      'The sum does not split into equal halves: change the cents';

  /// en: 'Advance'
  String get advanceDay => 'Advance';

  /// en: 'Salary'
  String get restDay => 'Salary';

  /// en: 'Advance amount'
  String get advanceAmount => 'Advance amount';

  /// en: 'half'
  String get advanceHalf => 'half';

  /// en: 'The rest comes with the salary: $amount on day $day.'
  String advanceRest({required Object amount, required Object day}) =>
      'The rest comes with the salary: ${amount} on day ${day}.';

  /// en: 'Half · $amount'
  String advanceHalfChip({required Object amount}) => 'Half · ${amount}';

  /// en: 'advance, $date'
  String nextAdvance({required Object date}) => 'advance, ${date}';

  /// en: 'The salary comes on day $day: a month can start on it, and then $month runs from $from to $to.'
  String monthStartHint({
    required Object day,
    required Object month,
    required Object from,
    required Object to,
  }) =>
      'The salary comes on day ${day}: a month can start on it, and then ${month} runs from ${from} to ${to}.';

  /// en: 'Reminders'
  String get remindTitle => 'Reminders';

  /// en: 'Notifications from Birka'
  String get remindNotify => 'Notifications from Birka';

  /// en: 'while Birka is on the phone'
  String get remindNotifyOff => 'while Birka is on the phone';

  /// en: '(one) {$n payment · at $time} (other) {$n payments · at $time}'
  String remindNotifyOn({required num n, required Object time}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment · at ${time}',
        other: '${n} payments · at ${time}',
      );

  /// en: '(one) {$n debt · at $time} (other) {$n debts · at $time}'
  String remindNotifyDebts({required num n, required Object time}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} debt · at ${time}',
        other: '${n} debts · at ${time}',
      );

  /// en: '$payments and $debts · at $time'
  String remindNotifyBoth({
    required Object payments,
    required Object debts,
    required Object time,
  }) => '${payments} and ${debts} · at ${time}';

  /// en: '(one) {$n payment} (other) {$n payments}'
  String remindPayments({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment',
        other: '${n} payments',
      );

  /// en: '(one) {$n debt} (other) {$n debts}'
  String remindDebtCount({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} debt',
        other: '${n} debts',
      );

  /// en: 'no access to notifications'
  String get remindNotifyDenied => 'no access to notifications';

  /// en: 'Calendar events'
  String get remindCalendar => 'Calendar events';

  /// en: '(one) {the «Birka» calendar · $n event} (other) {the «Birka» calendar · $n events}'
  String remindCalendarOn({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'the «Birka» calendar · ${n} event',
        other: 'the «Birka» calendar · ${n} events',
      );

  /// en: 'reminds even without Birka'
  String get remindCalendarOff => 'reminds even without Birka';

  /// en: 'no access to the calendar'
  String get remindCalendarDenied => 'no access to the calendar';

  /// en: 'Time'
  String get remindTime => 'Time';

  /// en: 'Amounts in reminders'
  String get remindSums => 'Amounts in reminders';

  /// en: 'on the lock screen and in the calendar'
  String get remindSumsNote => 'on the lock screen and in the calendar';

  /// en: 'A payment can remind on its day or the day before: each payment says which. A debt reminds on its day.'
  String get remindNoteOff =>
      'A payment can remind on its day or the day before: each payment says which. A debt reminds on its day.';

  /// en: 'Delete Birka and its reminders go with it. The calendar reminds even without it.'
  String get remindNoteOn =>
      'Delete Birka and its reminders go with it. The calendar reminds even without it.';

  /// en: 'For Birka to remind, allow its notifications in the settings of the phone.'
  String get remindNoteDenied =>
      'For Birka to remind, allow its notifications in the settings of the phone.';

  /// en: 'If the calendar syncs with iCloud or Google, the names and the amounts of the payments go there.'
  String get remindNoteCalendar =>
      'If the calendar syncs with iCloud or Google, the names and the amounts of the payments go there.';

  /// en: 'A payment is reminded of twice: by Birka and by the calendar.'
  String get remindNoteBoth =>
      'A payment is reminded of twice: by Birka and by the calendar.';

  /// en: 'For the calendar to remind, give it access in the settings of the phone.'
  String get remindNoteCalendarDenied =>
      'For the calendar to remind, give it access in the settings of the phone.';

  /// en: 'Reminders from Birka'
  String get remindAskTitle => 'Reminders from Birka';

  /// en: 'Birka reminds of a payment at $time, on its day or the day before, as the payment says. The reminders are set on this phone and need no server.'
  String remindAskText({required Object time}) =>
      'Birka reminds of a payment at ${time}, on its day or the day before, as the payment says. The reminders are set on this phone and need no server.';

  /// en: '$date, $time · a tap opens the payment'
  String remindAskExample({required Object date, required Object time}) =>
      '${date}, ${time} · a tap opens the payment';

  /// en: 'They live with Birka'
  String get remindAskLocalTitle => 'They live with Birka';

  /// en: 'Delete the app and its reminders go too. The calendar reminds even without it.'
  String get remindAskLocalText =>
      'Delete the app and its reminders go too. The calendar reminds even without it.';

  /// en: 'Allow notifications'
  String get remindAllow => 'Allow notifications';

  /// en: 'Not now'
  String get remindNotNow => 'Not now';

  /// en: 'Birka makes a calendar «Birka» and puts the regular payments in it. The calendar itself reminds, even if Birka is deleted.'
  String get remindCalendarAskText =>
      'Birka makes a calendar «Birka» and puts the regular payments in it. The calendar itself reminds, even if Birka is deleted.';

  /// en: 'The «Birka» calendar'
  String get remindCalendarAskOwnTitle => 'The «Birka» calendar';

  /// en: '(one) {$n payment · reminds at $time} (other) {$n payments · reminds at $time}'
  String remindCalendarAskOwn({required num n, required Object time}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment · reminds at ${time}',
        other: '${n} payments · reminds at ${time}',
      );

  /// en: 'If the calendar syncs'
  String get remindCalendarAskSyncTitle => 'If the calendar syncs';

  /// en: 'The names and the amounts of the payments go to iCloud or Google. The amounts can be left out in the settings.'
  String get remindCalendarAskSyncText =>
      'The names and the amounts of the payments go to iCloud or Google. The amounts can be left out in the settings.';

  /// en: 'Birka does not read other events'
  String get remindCalendarAskOthersTitle => 'Birka does not read other events';

  /// en: 'The phone asks for full access: without it Birka cannot change or delete its own events.'
  String get remindCalendarAskOthersText =>
      'The phone asks for full access: without it Birka cannot change or delete its own events.';

  /// en: 'Allow access to the calendar'
  String get remindCalendarAllow => 'Allow access to the calendar';

  /// en: 'Remove the «Birka» calendar?'
  String get remindCalendarRemoveTitle => 'Remove the «Birka» calendar?';

  /// en: '(one) {The «Birka» calendar and its $n event leave the phone, and the calendar stops reminding of the payments. Other calendars stay as they are.} (other) {The «Birka» calendar and its $n events leave the phone, and the calendar stops reminding of the payments. Other calendars stay as they are.}'
  String remindCalendarRemoveText({
    required num n,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one:
        'The «Birka» calendar and its ${n} event leave the phone, and the calendar stops reminding of the payments. Other calendars stay as they are.',
    other:
        'The «Birka» calendar and its ${n} events leave the phone, and the calendar stops reminding of the payments. Other calendars stay as they are.',
  );

  /// en: 'Remove the calendar'
  String get remindCalendarRemove => 'Remove the calendar';

  /// en: 'No access to the calendar'
  String get remindCalendarDeniedTitle => 'No access to the calendar';

  /// en: 'Access is off in the settings of the phone. Open Settings → Birka → Calendars and choose Full Access.'
  String get remindCalendarDeniedText =>
      'Access is off in the settings of the phone. Open Settings → Birka → Calendars and choose Full Access.';

  /// en: 'The payments are in the «Birka» calendar'
  String get remindCalendarOnToast =>
      'The payments are in the «Birka» calendar';

  /// en: 'The «Birka» calendar is removed'
  String get remindCalendarOffToast => 'The «Birka» calendar is removed';

  /// en: 'No access to notifications'
  String get remindDeniedTitle => 'No access to notifications';

  /// en: 'Notifications of Birka are off in the settings of the phone. Open Settings → Birka → Notifications and turn them on.'
  String get remindDeniedText =>
      'Notifications of Birka are off in the settings of the phone. Open Settings → Birka → Notifications and turn them on.';

  /// en: 'Open settings'
  String get remindOpenSettings => 'Open settings';

  /// en: 'Cancel'
  String get remindCancel => 'Cancel';

  /// en: 'Reminders are on'
  String get remindOnTitle => 'Reminders are on';

  /// en: '(one) {Birka will remind of $n payment} (other) {Birka will remind of $n payments}'
  String remindOnText({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Birka will remind of ${n} payment',
        other: 'Birka will remind of ${n} payments',
      );

  /// en: 'Mark «Remind» on the payments'
  String get remindOnNone => 'Mark «Remind» on the payments';

  /// en: 'Today. Tap to post or skip it.'
  String get remindToday => 'Today. Tap to post or skip it.';

  /// en: 'Today, it posts itself.'
  String get remindTodayAuto => 'Today, it posts itself.';

  /// en: 'Tomorrow, $date. Tap to open the payment.'
  String remindTomorrow({required Object date}) =>
      'Tomorrow, ${date}. Tap to open the payment.';

  /// en: 'Due today · $name, $amount'
  String remindDebtTitle({required Object name, required Object amount}) =>
      'Due today · ${name}, ${amount}';

  /// en: 'Due today · $name'
  String remindDebtTitleNoSum({required Object name}) => 'Due today · ${name}';

  /// en: 'The money is due back to you today. Tap to open the debt.'
  String get remindDebtLent =>
      'The money is due back to you today. Tap to open the debt.';

  /// en: 'Your debt is due today. Tap to open it.'
  String get remindDebtBorrowed => 'Your debt is due today. Tap to open it.';

  /// en: 'Payment and debt reminders'
  String get remindChannel => 'Payment and debt reminders';

  /// en: 'Regular payments on their day or the day before, and the days of debts'
  String get remindChannelNote =>
      'Regular payments on their day or the day before, and the days of debts';

  /// en: 'Remind'
  String get remindSection => 'Remind';

  Map<String, String> get reminder => {
    'onDay': 'On the day',
    'dayBefore': 'The day before',
    'none': 'Don\'t remind',
  };

  /// en: '$date at $time · $who'
  String remindLine({
    required Object date,
    required Object time,
    required Object who,
  }) => '${date} at ${time} · ${who}';

  /// en: 'Birka reminds'
  String get remindByBirka => 'Birka reminds';

  /// en: 'the «Birka» calendar reminds'
  String get remindByCalendar => 'the «Birka» calendar reminds';

  /// en: 'Birka and the calendar remind'
  String get remindByBoth => 'Birka and the calendar remind';

  /// en: 'No reminder'
  String get remindLineNone => 'No reminder';

  /// en: 'Reminders are off in More'
  String get remindLineOff => 'Reminders are off in More';

  /// en: 'Turn reminders on'
  String get remindEnable => 'Turn reminders on';

  /// en: 'Make it regular'
  String get makeRegular => 'Make it regular';

  /// en: 'Repeat $every'
  String makeRegularLine({required Object every}) => 'Repeat ${every}';

  /// en: 'Regular payment'
  String get regularPayment => 'Regular payment';

  /// en: 'From the operation of $date'
  String fromOperation({required Object date}) =>
      'From the operation of ${date}';

  /// en: 'Added to regular payments: «$name»'
  String madeRegular({required Object name}) =>
      'Added to regular payments: «${name}»';

  /// en: 'Looks regular'
  String get findsTitle => 'Looks regular';

  /// en: 'Found in your operations'
  String get findsTitleEmpty => 'Found in your operations';

  /// en: 'These came every month. Tap one to add it, or ✕ if it repeated by chance.'
  String get findsNote =>
      'These came every month. Tap one to add it, or ✕ if it repeated by chance.';

  /// en: '(one) {day $day · $count time in a row} (other) {day $day · $count times in a row}'
  String findLine({
    required num n,
    required Object day,
    required Object count,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one: 'day ${day} · ${count} time in a row',
    other: 'day ${day} · ${count} times in a row',
  );

  /// en: '(one) {about day $day · $count time} (other) {about day $day · $count times}'
  String findLineVaries({
    required num n,
    required Object day,
    required Object count,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one: 'about day ${day} · ${count} time',
    other: 'about day ${day} · ${count} times',
  );

  /// en: 'Not regular: $name'
  String findDismiss({required Object name}) => 'Not regular: ${name}';

  /// en: 'We won't suggest «$name» again'
  String findDismissed({required Object name}) =>
      'We won\'t suggest «${name}» again';

  /// en: 'Undo'
  String get findRestore => 'Undo';

  /// en: '(one) {Found in the operations · $count time} (other) {Found in the operations · $count times}'
  String foundIn({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Found in the operations · ${count} time',
        other: 'Found in the operations · ${count} times',
      );

  /// en: 'the last amount · it went from $min to $max'
  String amountRange({required Object min, required Object max}) =>
      'the last amount · it went from ${min} to ${max}';

  /// en: 'If you spend as usual'
  String get forecast => 'If you spend as usual';

  /// en: 'The money runs out on $date'
  String forecastRunsOut({required Object date}) =>
      'The money runs out on ${date}';

  /// en: 'It lasts until payday'
  String get forecastLastsPayday => 'It lasts until payday';

  /// en: 'It lasts until the month ends'
  String get forecastLastsMonth => 'It lasts until the month ends';

  /// en: 'The money is short already'
  String get forecastNone => 'The money is short already';

  /// en: 'The payments before payday take more than the accounts hold.'
  String get forecastNonePayday =>
      'The payments before payday take more than the accounts hold.';

  /// en: 'The payments before the month ends take more than the accounts hold.'
  String get forecastNoneMonth =>
      'The payments before the month ends take more than the accounts hold.';

  /// en: 'You usually spend ≈ $usual a day, and the plan allows $perDay. By $date ≈ $amount is missing.'
  String forecastShortText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object amount,
  }) =>
      'You usually spend ≈ ${usual} a day, and the plan allows ${perDay}. By ${date} ≈ ${amount} is missing.';

  /// en: 'You usually spend ≈ $usual a day: by $date ≈ $amount is left.'
  String forecastLeftText({
    required Object usual,
    required Object date,
    required Object amount,
  }) => 'You usually spend ≈ ${usual} a day: by ${date} ≈ ${amount} is left.';

  /// en: 'today'
  String get forecastToday => 'today';

  /// en: '$date · payday'
  String forecastPayday({required Object date}) => '${date} · payday';

  /// en: 'as usual'
  String get forecastUsual => 'as usual';

  /// en: 'plan: $amount a day'
  String forecastPlan({required Object amount}) => 'plan: ${amount} a day';

  /// en: 'plan'
  String get forecastPlanBare => 'plan';

  /// en: 'Usual spending is the average of 3 months on these accounts, without regular payments and transfers.'
  String get forecastNote =>
      'Usual spending is the average of 3 months on these accounts, without regular payments and transfers.';

  /// en: 'As usual, the money runs out on $date'
  String forecastLineRunsOut({required Object date}) =>
      'As usual, the money runs out on ${date}';

  /// en: 'As usual, it lasts until payday'
  String get forecastLinePayday => 'As usual, it lasts until payday';

  /// en: 'As usual, it lasts until the month ends'
  String get forecastLineMonth => 'As usual, it lasts until the month ends';

  /// en: 'You usually spend ≈ $usual a day, and until the advance the plan allows $perDay. After the advance on $date it lasts: by $end ≈ $amount is left.'
  String forecastAdvanceLastsText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object end,
    required Object amount,
  }) =>
      'You usually spend ≈ ${usual} a day, and until the advance the plan allows ${perDay}. After the advance on ${date} it lasts: by ${end} ≈ ${amount} is left.';

  /// en: 'You usually spend ≈ $usual a day, and until the advance the plan allows $perDay. With the advance on $date the money runs out again on $again: by $end ≈ $amount is missing.'
  String forecastAdvanceAgainText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object again,
    required Object end,
    required Object amount,
  }) =>
      'You usually spend ≈ ${usual} a day, and until the advance the plan allows ${perDay}. With the advance on ${date} the money runs out again on ${again}: by ${end} ≈ ${amount} is missing.';

  /// en: 'You usually spend ≈ $usual a day, and until the advance the plan allows $perDay. The advance on $date does not cover these days: by $end ≈ $amount is missing.'
  String forecastAdvanceShortText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object end,
    required Object amount,
  }) =>
      'You usually spend ≈ ${usual} a day, and until the advance the plan allows ${perDay}. The advance on ${date} does not cover these days: by ${end} ≈ ${amount} is missing.';

  /// en: 'Until the advance on $date, the payments and the money set aside take more than the accounts hold.'
  String forecastNoneAdvance({required Object date}) =>
      'Until the advance on ${date}, the payments and the money set aside take more than the accounts hold.';

  /// en: 'plan: $amount a day until the advance'
  String forecastPlanAdvance({required Object amount}) =>
      'plan: ${amount} a day until the advance';

  /// en: '$date · advance'
  String forecastAdvance({required Object date}) => '${date} · advance';

  /// en: 'Next on $date · $count'
  String subtitleNext({required Object date, required Object count}) =>
      'Next on ${date} · ${count}';

  /// en: '(one) {Today, $date · $n waits for you} (other) {Today, $date · $n wait for you}'
  String subtitleToday({required num n, required Object date}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Today, ${date} · ${n} waits for you',
        other: 'Today, ${date} · ${n} wait for you',
      );

  /// en: 'None yet'
  String get subtitleNone => 'None yet';

  /// en: '(one) {$n payment} (other) {$n payments}'
  String paymentsCount({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment',
        other: '${n} payments',
      );

  /// en: 'You can spend a day'
  String get perDayTitle => 'You can spend a day';

  /// en: 'The payments until payday are already taken off: $amount.'
  String paidAheadPayday({required Object amount}) =>
      'The payments until payday are already taken off: ${amount}.';

  /// en: 'The payments until the month ends are already taken off: $amount.'
  String paidAheadMonth({required Object amount}) =>
      'The payments until the month ends are already taken off: ${amount}.';

  /// en: 'How it works'
  String get howTitle => 'How it works';

  List<String> get how => [
    'A payment stands in the plan on its day and is already out of what you can spend today.',
    'On its day it waits for your «Post», or posts itself, as the payment says.',
    'When it comes in a bank statement, Birka will not count it twice.',
    'Birka finds what repeats in your operations and offers to add it.',
  ];

  /// en: 'Could not read the payments.'
  String get failed => 'Could not read the payments.';

  /// en: 'In the list of payments'
  String get previewTitle => 'In the list of payments';

  /// en: 'The next times'
  String get previewNext => 'The next times';

  /// en: 'Cancel'
  String get cancel => 'Cancel';
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

  /// en: 'Month starts on'
  String get monthStart => 'Month starts on';

  /// en: 'day $day'
  String monthStartDay({required Object day}) => 'day ${day}';

  /// en: 'for the overview and the reports'
  String get monthStartNote => 'for the overview and the reports';

  /// en: 'as on the calendar'
  String get monthStartCalendar => 'as on the calendar';
}

// Path: tags
class Translations$tags$en {
  Translations$tags$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Tags'
  String get title => 'Tags';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'New tag'
  String get add => 'New tag';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'Now'
  String get now => 'Now';

  /// en: 'Trips'
  String get trips => 'Trips';

  /// en: 'Tags'
  String get plain => 'Tags';

  /// en: 'Trip'
  String get trip => 'Trip';

  /// en: 'Tag'
  String get tag => 'Tag';

  /// en: 'Totals are expenses at the central bank rate of the day of each.'
  String get note =>
      'Totals are expenses at the central bank rate of the day of each.';

  /// en: 'No tags yet'
  String get emptyTitle => 'No tags yet';

  /// en: 'Tag a trip, a renovation or a holiday, and see what it took in every currency at once.'
  String get emptyText =>
      'Tag a trip, a renovation or a holiday, and see what it took in every currency at once.';

  /// en: 'Could not read the tags.'
  String get failed => 'Could not read the tags.';

  /// en: 'Last day'
  String get lastDay => 'Last day';

  /// en: 'Day $day of $total'
  String dayOf({required Object day, required Object total}) =>
      'Day ${day} of ${total}';

  /// en: '$from–$to'
  String days({required Object from, required Object to}) => '${from}–${to}';

  /// en: '$from — $to'
  String daysApart({required Object from, required Object to}) =>
      '${from} — ${to}';

  /// en: '(one) {in $n day} (other) {in $n days}'
  String inDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'in ${n} day',
        other: 'in ${n} days',
      );

  /// en: '(one) {$n operation} (other) {$n operations}'
  String operations({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} operation',
        other: '${n} operations',
      );

  /// en: 'since $date'
  String since({required Object date}) => 'since ${date}';

  /// en: 'How it works'
  String get howItWorks => 'How it works';

  late final Translations$tags$steps$en steps =
      Translations$tags$steps$en.internal(_root);
  late final Translations$tags$report$en report =
      Translations$tags$report$en.internal(_root);
  late final Translations$tags$form$en form =
      Translations$tags$form$en.internal(_root);

  /// en: 'Added the trip «$name»'
  String addedTrip({required Object name}) => 'Added the trip «${name}»';

  /// en: 'Added the tag «$name»'
  String addedTag({required Object name}) => 'Added the tag «${name}»';

  /// en: 'Saved «$name»'
  String saved({required Object name}) => 'Saved «${name}»';

  /// en: '(one) {Tagged $n expense: «$name»} (other) {Tagged $n expenses: «$name»}'
  String marked({required num n, required Object name}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Tagged ${n} expense: «${name}»',
        other: 'Tagged ${n} expenses: «${name}»',
      );

  /// en: '(one) {Took the tag off $n expense} (other) {Took the tag off $n expenses}'
  String unmarked({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Took the tag off ${n} expense',
        other: 'Took the tag off ${n} expenses',
      );

  /// en: 'Undo'
  String get undo => 'Undo';

  late final Translations$tags$picker$en picker =
      Translations$tags$picker$en.internal(_root);
  late final Translations$tags$row$en row = Translations$tags$row$en.internal(
    _root,
  );
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

  /// en: 'Tag'
  String get addTag => 'Tag';

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

  /// en: 'From the question'
  String get fromQuestion => 'From the question';

  /// en: 'Back to the answer'
  String get toAnswer => 'Back to the answer';

  /// en: 'Take off “$title”'
  String dropFocus({required Object title}) => 'Take off “${title}”';

  /// en: 'The list shows only what the question was about. Take the plaque off to see every operation of the month.'
  String get focusText =>
      'The list shows only what the question was about. Take the plaque off to see every operation of the month.';

  /// en: 'Go back to the answer'
  String get backToAnswer => 'Go back to the answer';

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

  late final Translations$transactions$debt$en debt =
      Translations$transactions$debt$en.internal(_root);
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

  /// en: '(one) {All $n operation} (other) {All $n operations}'
  String allOperations({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'All ${n} operation',
        other: 'All ${n} operations',
      );
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

// Path: ask.start
class Translations$ask$start$en {
  Translations$ask$start$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Ask about your money in words'
  String get title => 'Ask about your money in words';

  /// en: 'What, when and how much: “cafes in October”, “spending on the trip”, “over 5000 this month”. Birka reads the question, shows how it read it and counts the answer itself.'
  String get text =>
      'What, when and how much: “cafes in October”, “spending on the trip”, “over 5000 this month”. Birka reads the question, shows how it read it and counts the answer itself.';
}

// Path: ask.example
class Translations$ask$example$en {
  Translations$ask$example$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: '$category $month'
  String category({required Object category, required Object month}) =>
      '${category} ${month}';

  /// en: 'Total, comparison and the biggest'
  String get categoryText => 'Total, comparison and the biggest';

  /// en: 'Spending on the trip “$name”'
  String trip({required Object name}) => 'Spending on the trip “${name}”';

  /// en: 'What the trip took in every currency'
  String get tripText => 'What the trip took in every currency';

  /// en: 'Over 5000 this month'
  String get big => 'Over 5000 this month';

  /// en: 'The big spending of the month'
  String get bigText => 'The big spending of the month';

  /// en: 'How much can I spend'
  String get allowance => 'How much can I spend';

  /// en: 'Today and until payday'
  String get allowanceText => 'Today and until payday';

  /// en: 'When is the next payment'
  String get payments => 'When is the next payment';

  /// en: 'Regular payments by date'
  String get paymentsText => 'Regular payments by date';

  /// en: 'How to move my data'
  String get move => 'How to move my data';

  /// en: 'An answer from the help'
  String get moveText => 'An answer from the help';
}

// Path: ask.side
class Translations$ask$side$en {
  Translations$ask$side$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Spending'
  String get expenses => 'Spending';

  /// en: 'Income'
  String get income => 'Income';
}

// Path: ask.answer
class Translations$ask$answer$en {
  Translations$ask$answer$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: '$what · $when'
  String of({required Object what, required Object when}) =>
      '${what} · ${when}';

  /// en: '$what'
  String everything({required Object what}) => '${what}';

  /// en: '(one) {$n operation} (other) {$n operations}'
  String operations({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} operation',
        other: '${n} operations',
      );

  /// en: '(one) {$n payment in} (other) {$n payments in}'
  String incomes({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} payment in',
        other: '${n} payments in',
      );

  /// en: '$amount on average'
  String average({required Object amount}) => '${amount} on average';

  /// en: '$percent% of all spending $when'
  String share({required Object percent, required Object when}) =>
      '${percent}% of all spending ${when}';

  /// en: 'No such operations'
  String get none => 'No such operations';

  /// en: 'Try another period or drop part of the question.'
  String get noneText => 'Try another period or drop part of the question.';

  /// en: '(one) {Show $n operation} (other) {Show $n operations}'
  String show({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Show ${n} operation',
        other: 'Show ${n} operations',
      );

  /// en: 'The biggest'
  String get biggest => 'The biggest';

  /// en: 'Operations'
  String get operationsTitle => 'Operations';

  /// en: 'By category'
  String get sharesExpenses => 'By category';

  /// en: 'Where from'
  String get sharesIncome => 'Where from';

  /// en: 'No category'
  String get noCategory => 'No category';

  /// en: 'Counted on this device at the central bank rate of the day of each operation.'
  String get counted =>
      'Counted on this device at the central bank rate of the day of each operation.';

  /// en: 'Counted in this browser at the central bank rate of the day of each operation.'
  String get countedWeb =>
      'Counted in this browser at the central bank rate of the day of each operation.';

  /// en: 'Some amounts have no rate yet and stay out of the total.'
  String get partial =>
      'Some amounts have no rate yet and stay out of the total.';

  /// en: 'Trip report'
  String get trip => 'Trip report';

  /// en: 'Currencies, categories and days'
  String get tripText => 'Currencies, categories and days';
}

// Path: ask.before
class Translations$ask$before$en {
  Translations$ask$before$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'against $month'
  String month({required Object month}) => 'against ${month}';

  /// en: 'against $period'
  String months({required Object period}) => 'against ${period}';

  /// en: 'against $period'
  String days({required Object period}) => 'against ${period}';

  /// en: 'against the same days of $year'
  String year({required Object year}) => 'against the same days of ${year}';

  /// en: 'against $year'
  String wholeYear({required Object year}) => 'against ${year}';

  /// en: 'against $day'
  String day({required Object day}) => 'against ${day}';

  /// en: 'against last week'
  String get week => 'against last week';
}

// Path: ask.period
class Translations$ask$period$en {
  Translations$ask$period$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Period'
  String get title => 'Period';

  /// en: 'The answer is counted again'
  String get subtitle => 'The answer is counted again';

  /// en: 'Today'
  String get today => 'Today';

  /// en: 'Yesterday'
  String get yesterday => 'Yesterday';

  /// en: 'This week'
  String get thisWeek => 'This week';

  /// en: 'Last week'
  String get lastWeek => 'Last week';

  /// en: 'This month'
  String get thisMonth => 'This month';

  /// en: '(one) {Last month} (other) {Last $n months}'
  String lastMonths({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Last month',
        other: 'Last ${n} months',
      );

  /// en: 'This year'
  String get thisYear => 'This year';

  /// en: '(one) {Last day} (other) {Last $n days}'
  String lastDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'Last day',
        other: 'Last ${n} days',
      );

  /// en: '$from – $to'
  String months({required Object from, required Object to}) =>
      '${from} – ${to}';

  /// en: 'Since January 1'
  String get sinceYear => 'Since January 1';

  /// en: '$from–$to'
  String days({required Object from, required Object to}) => '${from}–${to}';

  /// en: '$from — $to'
  String daysApart({required Object from, required Object to}) =>
      '${from} — ${to}';
}

// Path: ask.fact
class Translations$ask$fact$en {
  Translations$ask$fact$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Capital · $currencies'
  String capital({required Object currencies}) => 'Capital · ${currencies}';

  /// en: '(one) {$n account} (other) {$n accounts}'
  String accounts({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} account',
        other: '${n} accounts',
      );

  /// en: 'All accounts'
  String get allAccounts => 'All accounts';

  /// en: 'Balances and history'
  String get allAccountsText => 'Balances and history';

  /// en: 'Central bank rate on $day'
  String rate({required Object day}) => 'Central bank rate on ${day}';

  /// en: 'for 1 $sign'
  String rateFor({required Object sign}) => 'for 1 ${sign}';

  /// en: 'Rates update once a day and stay on the device.'
  String get rateKept => 'Rates update once a day and stay on the device.';

  /// en: 'Rates update once a day and stay in this browser.'
  String get rateKeptWeb => 'Rates update once a day and stay in this browser.';

  /// en: 'There is no rate of this currency yet.'
  String get rateMissing => 'There is no rate of this currency yet.';

  /// en: 'Where the rate comes from'
  String get rateHelp => 'Where the rate comes from';

  /// en: 'An answer from the help'
  String get rateHelpText => 'An answer from the help';
}

// Path: ask.help
class Translations$ask$help$en {
  Translations$ask$help$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'From the help'
  String get title => 'From the help';

  /// en: 'All help'
  String get all => 'All help';
}

// Path: ask.places
class Translations$ask$places$en {
  Translations$ask$places$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Screens'
  String get title => 'Screens';

  /// en: 'Money until payday'
  String get payday => 'Money until payday';

  /// en: 'What you can spend a day, and the forecast'
  String get paydayText => 'What you can spend a day, and the forecast';

  /// en: 'Regular payments'
  String get schedules => 'Regular payments';

  /// en: 'Subscriptions, rent and salary'
  String get schedulesText => 'Subscriptions, rent and salary';

  /// en: 'Tags and trips'
  String get tags => 'Tags and trips';

  /// en: 'What trips and projects took'
  String get tagsText => 'What trips and projects took';

  /// en: 'Accounts'
  String get accounts => 'Accounts';

  /// en: 'Balances and history'
  String get accountsText => 'Balances and history';

  /// en: 'Categories'
  String get categories => 'Categories';

  /// en: 'Spending and income'
  String get categoriesText => 'Spending and income';

  /// en: 'Import a statement'
  String get imports => 'Import a statement';

  /// en: 'Operations from a bank file'
  String get importsText => 'Operations from a bank file';

  /// en: 'Inbox'
  String get inbox => 'Inbox';

  /// en: 'What waits for a decision after an import'
  String get inboxText => 'What waits for a decision after an import';

  /// en: 'Data'
  String get backup => 'Data';

  /// en: 'Copy, restore and export'
  String get backupText => 'Copy, restore and export';

  /// en: 'Help and feedback'
  String get help => 'Help and feedback';

  /// en: 'Common questions and a letter to the developer'
  String get helpText => 'Common questions and a letter to the developer';

  /// en: 'Notifications'
  String get notifications => 'Notifications';

  /// en: 'What Birka told you'
  String get notificationsText => 'What Birka told you';

  /// en: 'Reports'
  String get reports => 'Reports';

  /// en: 'Spending and income by month'
  String get reportsText => 'Spending and income by month';

  /// en: 'More'
  String get settings => 'More';

  /// en: 'Base currency, start of the month, language'
  String get settingsText => 'Base currency, start of the month, language';
}

// Path: ask.refused
class Translations$ask$refused$en {
  Translations$ask$refused$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'I give no advice on investments or rates'
  String get advice => 'I give no advice on investments or rates';

  /// en: 'Birka counts your money but does not predict rates or say what to buy.'
  String get adviceText =>
      'Birka counts your money but does not predict rates or say what to buy.';

  /// en: 'I answer only about your money'
  String get offTopic => 'I answer only about your money';

  /// en: 'Ask about spending, income, accounts, payments or the settings of Birka.'
  String get offTopicText =>
      'Ask about spending, income, accounts, payments or the settings of Birka.';

  /// en: 'I did not understand the question'
  String get unknown => 'I did not understand the question';

  /// en: 'Try it shorter: what, when and how much. For example, “cafes in October”.'
  String get unknownText =>
      'Try it shorter: what, when and how much. For example, “cafes in October”.';

  /// en: 'You can ask'
  String get suggest => 'You can ask';

  /// en: 'Write to the developer'
  String get write => 'Write to the developer';

  /// en: 'Tell what you wanted to find out'
  String get writeText => 'Tell what you wanted to find out';
}

// Path: ask.suggest
class Translations$ask$suggest$en {
  Translations$ask$suggest$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'How much money do I have'
  String get capital => 'How much money do I have';

  /// en: 'Dollar rate'
  String get rate => 'Dollar rate';

  /// en: 'How much can I spend'
  String get allowance => 'How much can I spend';

  /// en: 'When is the next payment'
  String get payments => 'When is the next payment';

  /// en: 'Income last month'
  String get income => 'Income last month';

  /// en: 'Spending this month'
  String get expenses => 'Spending this month';
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

// Path: debts.line
class Translations$debts$line$en {
  Translations$debts$line$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'due today'
  String get dueToday => 'due today';

  /// en: 'by $day'
  String dueOn({required Object day}) => 'by ${day}';

  /// en: 'was due $day'
  String overdue({required Object day}) => 'was due ${day}';

  /// en: 'since $day'
  String since({required Object day}) => 'since ${day}';

  /// en: 'paid back $day'
  String returned({required Object day}) => 'paid back ${day}';

  /// en: 'repaid $day'
  String repaid({required Object day}) => 'repaid ${day}';

  /// en: 'of $total'
  String of({required Object total}) => 'of ${total}';

  /// en: '≈ $amount'
  String approx({required Object amount}) => '≈ ${amount}';
}

// Path: debts.card
class Translations$debts$card$en {
  Translations$debts$card$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Debt'
  String get title => 'Debt';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'left to come back of $total'
  String leftToMe({required Object total}) => 'left to come back of ${total}';

  /// en: 'left to give back of $total'
  String leftToThem({required Object total}) => 'left to give back of ${total}';

  /// en: 'all paid back · $day'
  String allReturned({required Object day}) => 'all paid back · ${day}';

  /// en: 'all repaid · $day'
  String allRepaid({required Object day}) => 'all repaid · ${day}';

  /// en: 'Paid back $amount'
  String returned({required Object amount}) => 'Paid back ${amount}';

  /// en: 'Repaid $amount'
  String repaid({required Object amount}) => 'Repaid ${amount}';

  /// en: 'Due $day · we will remind you that day'
  String dueRemind({required Object day}) =>
      'Due ${day} · we will remind you that day';

  /// en: 'Due $day · $inDays'
  String dueIn({required Object day, required Object inDays}) =>
      'Due ${day} · ${inDays}';

  /// en: 'Due $day'
  String dueOn({required Object day}) => 'Due ${day}';

  /// en: 'Due today'
  String get dueToday => 'Due today';

  /// en: 'Was due $day'
  String dueWas({required Object day}) => 'Was due ${day}';

  /// en: 'No due date'
  String get noDue => 'No due date';

  /// en: 'Debt settled'
  String get closed => 'Debt settled';

  /// en: 'Debt settled · reminder removed'
  String get closedRemind => 'Debt settled · reminder removed';

  /// en: 'History'
  String get history => 'History';

  /// en: 'Paid back'
  String get returnAction => 'Paid back';

  /// en: 'Repay'
  String get repayAction => 'Repay';

  /// en: 'Lend more'
  String get lendMore => 'Lend more';

  /// en: 'Borrow more'
  String get borrowMore => 'Borrow more';

  /// en: 'New debt'
  String get newDebt => 'New debt';
}

// Path: debts.form
class Translations$debts$form$en {
  Translations$debts$form$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Lend'
  String get lend => 'Lend';

  /// en: 'Borrow'
  String get borrow => 'Borrow';

  /// en: 'Who'
  String get who => 'Who';

  /// en: 'Someone else'
  String get other => 'Someone else';

  /// en: 'Name'
  String get name => 'Name';

  /// en: 'Their name'
  String get nameHint => 'Their name';

  /// en: 'Write who it is'
  String get nameMissing => 'Write who it is';

  /// en: 'Amount'
  String get amount => 'Amount';

  /// en: 'From account'
  String get fromAccount => 'From account';

  /// en: 'To account'
  String get toAccount => 'To account';

  /// en: 'When'
  String get when => 'When';

  /// en: 'Due by'
  String get dueBy => 'Due by';

  /// en: 'No due date'
  String get noDue => 'No due date';

  /// en: 'Note'
  String get note => 'Note';

  /// en: 'Optional'
  String get noteHint => 'Optional';

  /// en: 'Remind on the due date'
  String get remind => 'Remind on the due date';

  /// en: 'A debt is not spending: the money leaves the account but stays out of the month's expenses.'
  String get lendCaption =>
      'A debt is not spending: the money leaves the account but stays out of the month\'s expenses.';

  /// en: 'A debt is not income: the money comes to the account but stays out of the month's income.'
  String get borrowCaption =>
      'A debt is not income: the money comes to the account but stays out of the month\'s income.';

  /// en: 'The debt is in $currency, and no account is in that currency.'
  String noAccount({required Object currency}) =>
      'The debt is in ${currency}, and no account is in that currency.';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Saved: $name, $amount'
  String saved({required Object name, required Object amount}) =>
      'Saved: ${name}, ${amount}';

  /// en: 'Could not save. Try again.'
  String get failed => 'Could not save. Try again.';

  /// en: 'Lend more · $name'
  String moreTitle({required Object name}) => 'Lend more · ${name}';

  /// en: 'Borrow more · $name'
  String borrowMoreTitle({required Object name}) => 'Borrow more · ${name}';

  late final Translations$debts$form$dueChoices$en dueChoices =
      Translations$debts$form$dueChoices$en.internal(_root);

  /// en: 'Today'
  String get today => 'Today';

  /// en: 'Edit the debt'
  String get editTitle => 'Edit the debt';
}

// Path: debts.back
class Translations$debts$back$en {
  Translations$debts$back$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Paid back · $name'
  String returnTitle({required Object name}) => 'Paid back · ${name}';

  /// en: 'Repay · $name'
  String repayTitle({required Object name}) => 'Repay · ${name}';

  /// en: 'All · $amount'
  String all({required Object amount}) => 'All · ${amount}';

  /// en: 'Part'
  String get part => 'Part';

  /// en: 'How much came back'
  String get howMuchReturned => 'How much came back';

  /// en: 'How much you gave back'
  String get howMuchRepaid => 'How much you gave back';

  /// en: 'More than is left'
  String get tooMuch => 'More than is left';

  /// en: 'The debt will be settled. The money comes to the account but not into income.'
  String get returnClosing =>
      'The debt will be settled. The money comes to the account but not into income.';

  /// en: 'The debt will be settled and its reminder removed. The money comes to the account but not into income.'
  String get returnClosingRemind =>
      'The debt will be settled and its reminder removed. The money comes to the account but not into income.';

  /// en: '$left will be left. The money comes to the account but not into income.'
  String returnLeft({required Object left}) =>
      '${left} will be left. The money comes to the account but not into income.';

  /// en: '$left will be left until $day. The money comes to the account but not into income.'
  String returnLeftDue({required Object left, required Object day}) =>
      '${left} will be left until ${day}. The money comes to the account but not into income.';

  /// en: 'The debt will be settled. The money leaves the account but not into expenses.'
  String get repayClosing =>
      'The debt will be settled. The money leaves the account but not into expenses.';

  /// en: 'The debt will be settled and its reminder removed. The money leaves the account but not into expenses.'
  String get repayClosingRemind =>
      'The debt will be settled and its reminder removed. The money leaves the account but not into expenses.';

  /// en: '$left will be left. The money leaves the account but not into expenses.'
  String repayLeft({required Object left}) =>
      '${left} will be left. The money leaves the account but not into expenses.';

  /// en: '$left will be left until $day. The money leaves the account but not into expenses.'
  String repayLeftDue({required Object left, required Object day}) =>
      '${left} will be left until ${day}. The money leaves the account but not into expenses.';

  /// en: 'Save the payment'
  String get save => 'Save the payment';

  /// en: '$name: debt settled'
  String closedToast({required Object name}) => '${name}: debt settled';

  /// en: 'Paid back $amount · $left left'
  String returnedToast({required Object amount, required Object left}) =>
      'Paid back ${amount} · ${left} left';

  /// en: 'Repaid $amount · $left left'
  String repaidToast({required Object amount, required Object left}) =>
      'Repaid ${amount} · ${left} left';
}

// Path: debts.steps
class Translations$debts$steps$en {
  Translations$debts$steps$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Write down whom you lent to and whom you borrowed from: the money leaves the account or comes to it.'
  String get first =>
      'Write down whom you lent to and whom you borrowed from: the money leaves the account or comes to it.';

  /// en: 'A debt is neither spending nor income: it stays out of the month's reports.'
  String get second =>
      'A debt is neither spending nor income: it stays out of the month\'s reports.';

  /// en: 'Payments settle a debt in parts, and the list shows how much is left and by what day.'
  String get third =>
      'Payments settle a debt in parts, and the list shows how much is left and by what day.';
}

// Path: debts.move
class Translations$debts$move$en {
  Translations$debts$move$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Lent'
  String get lent => 'Lent';

  /// en: 'Paid back'
  String get returned => 'Paid back';

  /// en: 'Borrowed'
  String get borrowed => 'Borrowed';

  /// en: 'Repaid'
  String get repaid => 'Repaid';
}

// Path: debts.person
class Translations$debts$person$en {
  Translations$debts$person$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: '$name is here already, $about. Say who this one is, to tell them apart.'
  String twin({required Object name, required Object about}) =>
      '${name} is here already, ${about}. Say who this one is, to tell them apart.';

  /// en: '$name is here already. Say who this one is, to tell them apart.'
  String twinPlain({required Object name}) =>
      '${name} is here already. Say who this one is, to tell them apart.';

  /// en: '$name is here already, $about. If it is the same person, pick them above; if not, say who this one is.'
  String twinPick({required Object name, required Object about}) =>
      '${name} is here already, ${about}. If it is the same person, pick them above; if not, say who this one is.';

  /// en: '$name is here already. If it is the same person, pick them above; if not, say who this one is.'
  String twinPickPlain({required Object name}) =>
      '${name} is here already. If it is the same person, pick them above; if not, say who this one is.';
}

// Path: debts.remind
class Translations$debts$remind$en {
  Translations$debts$remind$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Hi! A reminder about $amount: we said it would come back by $day.'
  String text({required Object amount, required Object day}) =>
      'Hi! A reminder about ${amount}: we said it would come back by ${day}.';

  /// en: 'Hi! A reminder about $amount.'
  String textNoDue({required Object amount}) =>
      'Hi! A reminder about ${amount}.';
}

// Path: demo.people
class Translations$demo$people$en {
  Translations$demo$people$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Masha'
  String get masha => 'Masha';

  /// en: 'Dima'
  String get dima => 'Dima';

  /// en: 'Sasha'
  String get sasha => 'Sasha';

  /// en: 'Ira'
  String get ira => 'Ira';

  /// en: 'Dad'
  String get dad => 'Dad';
}

// Path: demo.debtNotes
class Translations$demo$debtNotes$en {
  Translations$demo$debtNotes$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'for the tickets'
  String get tickets => 'for the tickets';

  /// en: 'for the flat'
  String get flat => 'for the flat';

  /// en: 'until payday'
  String get salary => 'until payday';

  /// en: 'for the concert'
  String get concert => 'for the concert';
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

// Path: tags.steps
class Translations$tags$steps$en {
  Translations$tags$steps$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'A tag gathers what a trip or a project took in every currency, at the rate of the day.'
  String get first =>
      'A tag gathers what a trip or a project took in every currency, at the rate of the day.';

  /// en: 'A trip has days: its expenses on those days get its tag by themselves, except regular payments.'
  String get second =>
      'A trip has days: its expenses on those days get its tag by themselves, except regular payments.';

  /// en: 'Tag the tickets and the stay that you bought in advance on the card of the operation.'
  String get third =>
      'Tag the tickets and the stay that you bought in advance on the card of the operation.';
}

// Path: tags.report
class Translations$tags$report$en {
  Translations$tags$report$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'today is the last day'
  String get todayLast => 'today is the last day';

  /// en: 'A day on the spot'
  String get perDay => 'A day on the spot';

  /// en: 'A month'
  String get perMonth => 'A month';

  /// en: '(one) {over $n day} (other) {over $n days}'
  String forDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: 'over ${n} day',
        other: 'over ${n} days',
      );

  /// en: 'Operations'
  String get count => 'Operations';

  /// en: '$n there'
  String there({required Object n}) => '${n} there';

  /// en: '$n in advance'
  String before({required Object n}) => '${n} in advance';

  /// en: '$n after'
  String after({required Object n}) => '${n} after';

  /// en: 'the latest on $date'
  String last({required Object date}) => 'the latest on ${date}';

  /// en: 'Currencies'
  String get currencies => 'Currencies';

  /// en: 'At the central bank rate of the day of each operation.'
  String get ratesNote =>
      'At the central bank rate of the day of each operation.';

  /// en: '(one) {$n operation on the spot} (other) {$n operations on the spot}'
  String onTheSpot({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        n,
        one: '${n} operation on the spot',
        other: '${n} operations on the spot',
      );

  /// en: 'Some days have no rate yet, and the total leaves them out.'
  String get noRate =>
      'Some days have no rate yet, and the total leaves them out.';

  /// en: 'Categories'
  String get categories => 'Categories';

  /// en: 'Operations'
  String get operations => 'Operations';

  /// en: 'No operations wear this tag yet.'
  String get nothing => 'No operations wear this tag yet.';

  /// en: 'No category'
  String get noCategory => 'No category';
}

// Path: tags.form
class Translations$tags$form$en {
  Translations$tags$form$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'New tag'
  String get newTitle => 'New tag';

  /// en: 'Trip'
  String get trip => 'Trip';

  /// en: 'Tag'
  String get plain => 'Tag';

  /// en: 'Name'
  String get name => 'Name';

  /// en: 'Batumi'
  String get namePlaceholder => 'Batumi';

  /// en: 'Dates'
  String get dates => 'Dates';

  /// en: 'From'
  String get from => 'From';

  /// en: 'To'
  String get to => 'To';

  /// en: 'Tag the expenses'
  String get marks => 'Tag the expenses';

  /// en: 'Of these days'
  String get marksOn => 'Of these days';

  /// en: 'By hand only'
  String get marksOff => 'By hand only';

  /// en: 'The expenses of these days get the tag by themselves. Regular payments stay as they are.'
  String get marksAhead =>
      'The expenses of these days get the tag by themselves. Regular payments stay as they are.';

  /// en: '(one) {These days already have $n expense, and it gets the tag now. Regular payments stay as they are.} (other) {These days already have $n expenses, and they get the tag now. Regular payments stay as they are.}'
  String marksPast({
    required num n,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
    n,
    one:
        'These days already have ${n} expense, and it gets the tag now. Regular payments stay as they are.',
    other:
        'These days already have ${n} expenses, and they get the tag now. Regular payments stay as they are.',
  );

  /// en: 'You put the tag on yourself, when you add an operation or on its card.'
  String get manual =>
      'You put the tag on yourself, when you add an operation or on its card.';

  /// en: 'You put the tag on yourself, when you add an operation or on its card. Its report gathers what it took in every currency.'
  String get plainNote =>
      'You put the tag on yourself, when you add an operation or on its card. Its report gathers what it took in every currency.';

  /// en: 'The tickets bought in advance can wear the tag too'
  String get footTrip => 'The tickets bought in advance can wear the tag too';

  /// en: 'Tags live in More → Tags'
  String get footPlain => 'Tags live in More → Tags';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Done'
  String get done => 'Done';

  /// en: 'Give the tag a name.'
  String get nameMissing => 'Give the tag a name.';

  /// en: 'Could not save. Try again.'
  String get failed => 'Could not save. Try again.';
}

// Path: tags.picker
class Translations$tags$picker$en {
  Translations$tags$picker$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Tags'
  String get title => 'Tags';

  /// en: 'Find or create'
  String get search => 'Find or create';

  /// en: 'Clear the search'
  String get clear => 'Clear the search';

  /// en: 'New tag «$name»'
  String create({required Object name}) => 'New tag «${name}»';

  /// en: 'A trip with dates or just a tag'
  String get createText => 'A trip with dates or just a tag';

  /// en: 'While a trip goes on, its tag goes onto the expenses of its days by itself.'
  String get tripsNote =>
      'While a trip goes on, its tag goes onto the expenses of its days by itself.';

  /// en: 'now'
  String get now => 'now';

  /// en: 'No tags yet'
  String get emptyTitle => 'No tags yet';

  /// en: 'Type a name: a trip, a renovation or a holiday. A tag gathers what they took in every currency.'
  String get emptyText =>
      'Type a name: a trip, a renovation or a holiday. A tag gathers what they took in every currency.';
}

// Path: tags.row
class Translations$tags$row$en {
  Translations$tags$row$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Add a tag'
  String get add => 'Add a tag';

  /// en: 'A trip, a renovation or a holiday'
  String get addText => 'A trip, a renovation or a holiday';

  /// en: 'Trip · $days'
  String trip({required Object days}) => 'Trip · ${days}';

  /// en: 'Trip · $days · by its dates'
  String byDays({required Object days}) => 'Trip · ${days} · by its dates';

  /// en: 'Tag'
  String get plain => 'Tag';

  /// en: 'and $n more'
  String more({required Object n}) => 'and ${n} more';
}

// Path: transactions.debt
class Translations$transactions$debt$en {
  Translations$transactions$debt$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Debt'
  String get title => 'Debt';

  /// en: 'lent'
  String get lent => 'lent';

  /// en: 'paid back'
  String get returned => 'paid back';

  /// en: 'borrowed'
  String get borrowed => 'borrowed';

  /// en: 'repaid'
  String get repaid => 'repaid';
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

// Path: debts.form.dueChoices
class Translations$debts$form$dueChoices$en {
  Translations$debts$form$dueChoices$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'No due date'
  String get none => 'No due date';

  /// en: 'In a week'
  String get week => 'In a week';

  /// en: 'In two weeks'
  String get twoWeeks => 'In two weeks';

  /// en: 'In a month'
  String get month => 'In a month';

  /// en: 'Pick a day'
  String get pick => 'Pick a day';
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
          'ask.title' => 'Ask',
          'ask.open' => 'Ask',
          'ask.hint' => 'Ask about your money',
          'ask.clear' => 'Clear the question',
          'ask.back' => 'Back',
          'ask.examples' => 'You can ask',
          'ask.recent' => 'Recent',
          'ask.forget' => 'Clear',
          'ask.private' =>
            'The app answers by itself: questions and answers stay on this device.',
          'ask.failed' => 'Could not read the data for an answer.',
          'ask.privateWeb' =>
            'The app answers by itself: questions and answers stay in this browser.',
          'ask.slash' => 'The / key opens Ask from any page.',
          'ask.start.title' => 'Ask about your money in words',
          'ask.start.text' =>
            'What, when and how much: “cafes in October”, “spending on the trip”, “over 5000 this month”. Birka reads the question, shows how it read it and counts the answer itself.',
          'ask.example.category' =>
            ({required Object category, required Object month}) =>
                '${category} ${month}',
          'ask.example.categoryText' => 'Total, comparison and the biggest',
          'ask.example.trip' =>
            ({required Object name}) => 'Spending on the trip “${name}”',
          'ask.example.tripText' => 'What the trip took in every currency',
          'ask.example.big' => 'Over 5000 this month',
          'ask.example.bigText' => 'The big spending of the month',
          'ask.example.allowance' => 'How much can I spend',
          'ask.example.allowanceText' => 'Today and until payday',
          'ask.example.payments' => 'When is the next payment',
          'ask.example.paymentsText' => 'Regular payments by date',
          'ask.example.move' => 'How to move my data',
          'ask.example.moveText' => 'An answer from the help',
          'ask.understood' => 'Read as',
          'ask.side.expenses' => 'Spending',
          'ask.side.income' => 'Income',
          'ask.above' => ({required Object amount}) => 'Over ${amount}',
          'ask.below' => ({required Object amount}) => 'Under ${amount}',
          'ask.word' => ({required Object word}) => '“${word}”',
          'ask.allTime' => 'All time',
          'ask.answer.of' =>
            ({required Object what, required Object when}) =>
                '${what} · ${when}',
          'ask.answer.everything' => ({required Object what}) => '${what}',
          'ask.answer.operations' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} operation',
                  other: '${n} operations',
                ),
          'ask.answer.incomes' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment in',
                  other: '${n} payments in',
                ),
          'ask.answer.average' =>
            ({required Object amount}) => '${amount} on average',
          'ask.answer.share' =>
            ({required Object percent, required Object when}) =>
                '${percent}% of all spending ${when}',
          'ask.answer.none' => 'No such operations',
          'ask.answer.noneText' =>
            'Try another period or drop part of the question.',
          'ask.answer.show' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Show ${n} operation',
                  other: 'Show ${n} operations',
                ),
          'ask.answer.biggest' => 'The biggest',
          'ask.answer.operationsTitle' => 'Operations',
          'ask.answer.sharesExpenses' => 'By category',
          'ask.answer.sharesIncome' => 'Where from',
          'ask.answer.noCategory' => 'No category',
          'ask.answer.counted' =>
            'Counted on this device at the central bank rate of the day of each operation.',
          'ask.answer.countedWeb' =>
            'Counted in this browser at the central bank rate of the day of each operation.',
          'ask.answer.partial' =>
            'Some amounts have no rate yet and stay out of the total.',
          'ask.answer.trip' => 'Trip report',
          'ask.answer.tripText' => 'Currencies, categories and days',
          'ask.before.month' => ({required Object month}) => 'against ${month}',
          'ask.before.months' =>
            ({required Object period}) => 'against ${period}',
          'ask.before.days' =>
            ({required Object period}) => 'against ${period}',
          'ask.before.year' =>
            ({required Object year}) => 'against the same days of ${year}',
          'ask.before.wholeYear' =>
            ({required Object year}) => 'against ${year}',
          'ask.before.day' => ({required Object day}) => 'against ${day}',
          'ask.before.week' => 'against last week',
          'ask.period.title' => 'Period',
          'ask.period.subtitle' => 'The answer is counted again',
          'ask.period.today' => 'Today',
          'ask.period.yesterday' => 'Yesterday',
          'ask.period.thisWeek' => 'This week',
          'ask.period.lastWeek' => 'Last week',
          'ask.period.thisMonth' => 'This month',
          'ask.period.lastMonths' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Last month',
                  other: 'Last ${n} months',
                ),
          'ask.period.thisYear' => 'This year',
          'ask.period.lastDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Last day',
                  other: 'Last ${n} days',
                ),
          'ask.period.months' =>
            ({required Object from, required Object to}) => '${from} – ${to}',
          'ask.period.sinceYear' => 'Since January 1',
          'ask.period.days' =>
            ({required Object from, required Object to}) => '${from}–${to}',
          'ask.period.daysApart' =>
            ({required Object from, required Object to}) => '${from} — ${to}',
          'ask.fact.capital' =>
            ({required Object currencies}) => 'Capital · ${currencies}',
          'ask.fact.accounts' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} account',
                  other: '${n} accounts',
                ),
          'ask.fact.allAccounts' => 'All accounts',
          'ask.fact.allAccountsText' => 'Balances and history',
          'ask.fact.rate' =>
            ({required Object day}) => 'Central bank rate on ${day}',
          'ask.fact.rateFor' => ({required Object sign}) => 'for 1 ${sign}',
          'ask.fact.rateKept' =>
            'Rates update once a day and stay on the device.',
          'ask.fact.rateKeptWeb' =>
            'Rates update once a day and stay in this browser.',
          'ask.fact.rateMissing' => 'There is no rate of this currency yet.',
          'ask.fact.rateHelp' => 'Where the rate comes from',
          'ask.fact.rateHelpText' => 'An answer from the help',
          'ask.help.title' => 'From the help',
          'ask.help.all' => 'All help',
          'ask.places.title' => 'Screens',
          'ask.places.payday' => 'Money until payday',
          'ask.places.paydayText' =>
            'What you can spend a day, and the forecast',
          'ask.places.schedules' => 'Regular payments',
          'ask.places.schedulesText' => 'Subscriptions, rent and salary',
          'ask.places.tags' => 'Tags and trips',
          'ask.places.tagsText' => 'What trips and projects took',
          'ask.places.accounts' => 'Accounts',
          'ask.places.accountsText' => 'Balances and history',
          'ask.places.categories' => 'Categories',
          'ask.places.categoriesText' => 'Spending and income',
          'ask.places.imports' => 'Import a statement',
          'ask.places.importsText' => 'Operations from a bank file',
          'ask.places.inbox' => 'Inbox',
          'ask.places.inboxText' => 'What waits for a decision after an import',
          'ask.places.backup' => 'Data',
          'ask.places.backupText' => 'Copy, restore and export',
          'ask.places.help' => 'Help and feedback',
          'ask.places.helpText' =>
            'Common questions and a letter to the developer',
          'ask.places.notifications' => 'Notifications',
          'ask.places.notificationsText' => 'What Birka told you',
          'ask.places.reports' => 'Reports',
          'ask.places.reportsText' => 'Spending and income by month',
          'ask.places.settings' => 'More',
          'ask.places.settingsText' =>
            'Base currency, start of the month, language',
          'ask.refused.advice' => 'I give no advice on investments or rates',
          'ask.refused.adviceText' =>
            'Birka counts your money but does not predict rates or say what to buy.',
          'ask.refused.offTopic' => 'I answer only about your money',
          'ask.refused.offTopicText' =>
            'Ask about spending, income, accounts, payments or the settings of Birka.',
          'ask.refused.unknown' => 'I did not understand the question',
          'ask.refused.unknownText' =>
            'Try it shorter: what, when and how much. For example, “cafes in October”.',
          'ask.refused.suggest' => 'You can ask',
          'ask.refused.write' => 'Write to the developer',
          'ask.refused.writeText' => 'Tell what you wanted to find out',
          'ask.suggest.capital' => 'How much money do I have',
          'ask.suggest.rate' => 'Dollar rate',
          'ask.suggest.allowance' => 'How much can I spend',
          'ask.suggest.payments' => 'When is the next payment',
          'ask.suggest.income' => 'Income last month',
          'ask.suggest.expenses' => 'Spending this month',
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
          'categories.howTitle' => 'How it works',
          'categories.how.0' =>
            'Click a category, and it opens here, beside the list.',
          'categories.how.1' =>
            'Expenses and income are separate lists: the switch above them picks one.',
          'categories.how.2' =>
            'Categories show in operations, reports and regular payments.',
          'debts.title' => 'Debts',
          'debts.toMore' => 'More',
          'debts.close' => 'Close',
          'debts.done' => 'Done',
          'debts.foldClosed' => 'Show the settled ones',
          'debts.moreHint' => 'Who owes whom, and by what day',
          'debts.moreBoth' =>
            ({required Object owed, required Object mine}) =>
                'Owed to me ${owed} · mine ${mine}',
          'debts.moreOwed' => ({required Object owed}) => 'Owed to me ${owed}',
          'debts.moreMine' => ({required Object mine}) => 'My debts ${mine}',
          'debts.owedToMe' => 'Owed to me',
          'debts.myDebts' => 'My debts',
          'debts.people' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} person',
                  other: '${n} people',
                ),
          'debts.closed' => ({required Object n}) => 'Settled · ${n}',
          'debts.caption' =>
            'Debts are not in the capital: this money is not on your accounts now.',
          'debts.captionRates' =>
            'Debts are not in the capital: this money is not on your accounts now. Other currencies at today\'s CBR rate.',
          'debts.failed' => 'Could not read the debts.',
          'debts.gone' => 'This debt is gone.',
          'debts.emptyTitle' => 'No debts',
          'debts.emptyText' =>
            'Write down whom you lent to or borrowed from: Birka shows how much is left and by what day.',
          'debts.add' => 'Add a debt',
          'debts.newDebt' => 'New debt',
          'debts.line.dueToday' => 'due today',
          'debts.line.dueOn' => ({required Object day}) => 'by ${day}',
          'debts.line.overdue' => ({required Object day}) => 'was due ${day}',
          'debts.line.since' => ({required Object day}) => 'since ${day}',
          'debts.line.returned' =>
            ({required Object day}) => 'paid back ${day}',
          'debts.line.repaid' => ({required Object day}) => 'repaid ${day}',
          'debts.line.of' => ({required Object total}) => 'of ${total}',
          'debts.line.approx' => ({required Object amount}) => '≈ ${amount}',
          'debts.card.title' => 'Debt',
          'debts.card.edit' => 'Edit',
          'debts.card.leftToMe' =>
            ({required Object total}) => 'left to come back of ${total}',
          'debts.card.leftToThem' =>
            ({required Object total}) => 'left to give back of ${total}',
          'debts.card.allReturned' =>
            ({required Object day}) => 'all paid back · ${day}',
          'debts.card.allRepaid' =>
            ({required Object day}) => 'all repaid · ${day}',
          'debts.card.returned' =>
            ({required Object amount}) => 'Paid back ${amount}',
          'debts.card.repaid' =>
            ({required Object amount}) => 'Repaid ${amount}',
          'debts.card.dueRemind' =>
            ({required Object day}) =>
                'Due ${day} · we will remind you that day',
          'debts.card.dueIn' =>
            ({required Object day, required Object inDays}) =>
                'Due ${day} · ${inDays}',
          'debts.card.dueOn' => ({required Object day}) => 'Due ${day}',
          'debts.card.dueToday' => 'Due today',
          'debts.card.dueWas' => ({required Object day}) => 'Was due ${day}',
          'debts.card.noDue' => 'No due date',
          'debts.card.closed' => 'Debt settled',
          'debts.card.closedRemind' => 'Debt settled · reminder removed',
          'debts.card.history' => 'History',
          'debts.card.returnAction' => 'Paid back',
          'debts.card.repayAction' => 'Repay',
          'debts.card.lendMore' => 'Lend more',
          'debts.card.borrowMore' => 'Borrow more',
          'debts.card.newDebt' => 'New debt',
          'debts.inDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'in ${n} day',
                  other: 'in ${n} days',
                ),
          'debts.form.lend' => 'Lend',
          'debts.form.borrow' => 'Borrow',
          'debts.form.who' => 'Who',
          'debts.form.other' => 'Someone else',
          'debts.form.name' => 'Name',
          'debts.form.nameHint' => 'Their name',
          'debts.form.nameMissing' => 'Write who it is',
          'debts.form.amount' => 'Amount',
          'debts.form.fromAccount' => 'From account',
          'debts.form.toAccount' => 'To account',
          'debts.form.when' => 'When',
          'debts.form.dueBy' => 'Due by',
          'debts.form.noDue' => 'No due date',
          'debts.form.note' => 'Note',
          'debts.form.noteHint' => 'Optional',
          'debts.form.remind' => 'Remind on the due date',
          'debts.form.lendCaption' =>
            'A debt is not spending: the money leaves the account but stays out of the month\'s expenses.',
          'debts.form.borrowCaption' =>
            'A debt is not income: the money comes to the account but stays out of the month\'s income.',
          'debts.form.noAccount' =>
            ({required Object currency}) =>
                'The debt is in ${currency}, and no account is in that currency.',
          'debts.form.save' => 'Save',
          'debts.form.saved' =>
            ({required Object name, required Object amount}) =>
                'Saved: ${name}, ${amount}',
          'debts.form.failed' => 'Could not save. Try again.',
          'debts.form.moreTitle' =>
            ({required Object name}) => 'Lend more · ${name}',
          'debts.form.borrowMoreTitle' =>
            ({required Object name}) => 'Borrow more · ${name}',
          'debts.form.dueChoices.none' => 'No due date',
          'debts.form.dueChoices.week' => 'In a week',
          'debts.form.dueChoices.twoWeeks' => 'In two weeks',
          'debts.form.dueChoices.month' => 'In a month',
          'debts.form.dueChoices.pick' => 'Pick a day',
          'debts.form.today' => 'Today',
          'debts.form.editTitle' => 'Edit the debt',
          'debts.back.returnTitle' =>
            ({required Object name}) => 'Paid back · ${name}',
          'debts.back.repayTitle' =>
            ({required Object name}) => 'Repay · ${name}',
          'debts.back.all' => ({required Object amount}) => 'All · ${amount}',
          'debts.back.part' => 'Part',
          'debts.back.howMuchReturned' => 'How much came back',
          'debts.back.howMuchRepaid' => 'How much you gave back',
          'debts.back.tooMuch' => 'More than is left',
          'debts.back.returnClosing' =>
            'The debt will be settled. The money comes to the account but not into income.',
          'debts.back.returnClosingRemind' =>
            'The debt will be settled and its reminder removed. The money comes to the account but not into income.',
          'debts.back.returnLeft' =>
            ({required Object left}) =>
                '${left} will be left. The money comes to the account but not into income.',
          'debts.back.returnLeftDue' =>
            ({required Object left, required Object day}) =>
                '${left} will be left until ${day}. The money comes to the account but not into income.',
          'debts.back.repayClosing' =>
            'The debt will be settled. The money leaves the account but not into expenses.',
          'debts.back.repayClosingRemind' =>
            'The debt will be settled and its reminder removed. The money leaves the account but not into expenses.',
          'debts.back.repayLeft' =>
            ({required Object left}) =>
                '${left} will be left. The money leaves the account but not into expenses.',
          'debts.back.repayLeftDue' =>
            ({required Object left, required Object day}) =>
                '${left} will be left until ${day}. The money leaves the account but not into expenses.',
          'debts.back.save' => 'Save the payment',
          'debts.back.closedToast' =>
            ({required Object name}) => '${name}: debt settled',
          'debts.back.returnedToast' =>
            ({required Object amount, required Object left}) =>
                'Paid back ${amount} · ${left} left',
          'debts.back.repaidToast' =>
            ({required Object amount, required Object left}) =>
                'Repaid ${amount} · ${left} left',
          'debts.steps.first' =>
            'Write down whom you lent to and whom you borrowed from: the money leaves the account or comes to it.',
          'debts.steps.second' =>
            'A debt is neither spending nor income: it stays out of the month\'s reports.',
          'debts.steps.third' =>
            'Payments settle a debt in parts, and the list shows how much is left and by what day.',
          'debts.howItWorks' => 'How it works',
          'debts.move.lent' => 'Lent',
          'debts.move.returned' => 'Paid back',
          'debts.move.borrowed' => 'Borrowed',
          'debts.move.repaid' => 'Repaid',
          'debts.person.twin' =>
            ({required Object name, required Object about}) =>
                '${name} is here already, ${about}. Say who this one is, to tell them apart.',
          'debts.person.twinPlain' =>
            ({required Object name}) =>
                '${name} is here already. Say who this one is, to tell them apart.',
          'debts.person.twinPick' =>
            ({required Object name, required Object about}) =>
                '${name} is here already, ${about}. If it is the same person, pick them above; if not, say who this one is.',
          'debts.person.twinPickPlain' =>
            ({required Object name}) =>
                '${name} is here already. If it is the same person, pick them above; if not, say who this one is.',
          'debts.remind.text' =>
            ({required Object amount, required Object day}) =>
                'Hi! A reminder about ${amount}: we said it would come back by ${day}.',
          'debts.remind.textNoDue' =>
            ({required Object amount}) => 'Hi! A reminder about ${amount}.',
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
          'demo.people.masha' => 'Masha',
          'demo.people.dima' => 'Dima',
          'demo.people.sasha' => 'Sasha',
          'demo.people.ira' => 'Ira',
          'demo.people.dad' => 'Dad',
          'demo.debtNotes.tickets' => 'for the tickets',
          'demo.debtNotes.flat' => 'for the flat',
          'demo.debtNotes.salary' => 'until payday',
          'demo.debtNotes.concert' => 'for the concert',
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
          _ => null,
        } ??
        switch (path) {
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
          'imports.looksLikeOwn' => 'Your own format, as before',
          'imports.categoriesHeading' => 'Categories of the bank',
          'imports.categoriesCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} category in the statement',
                  other: '${count} categories in the statement',
                ),
          'imports.categoriesKnown' =>
            ({required Object known, required Object total}) =>
                '${known} of ${total} recognized by Birka',
          'imports.categoriesNone' => 'Birka doesn\'t know them yet',
          'imports.categoriesAsBefore' => 'As in the last statement',
          'imports.categoriesKnownText' =>
            ({required Object known, required Object total}) =>
                '${known} of ${total} recognized by their names. Operations go straight into your categories, and without a choice they wait in the inbox.',
          'imports.categoriesText' =>
            'Choose where the operations of each category of the bank go. Without a choice they wait in the inbox.',
          'imports.categoriesAsBeforeText' =>
            ({required Object source}) =>
                'Your choice for the last statement of ${source}. Change it if something is different now.',
          'imports.ownFormatOf' => 'your format',
          'imports.inboxNote' => 'operations wait without a category',
          'imports.newCategoryNote' => 'made with the import',
          'imports.newCategoryMark' => 'new category',
          'imports.categoriesDone' =>
            ({required Object count}) => 'Done · ${count} in the inbox',
          'imports.categoriesKept' =>
            ({required Object source}) =>
                'Birka keeps the choice for statements of ${source}',
          'imports.foundHeading' => 'Regular payments',
          'imports.foundLine' =>
            ({required Object count, required Object names}) =>
                'found ${count}: ${names}',
          'imports.foundDone' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Posted ${count} payment',
                  other: 'Posted ${count} payments',
                ),
          'imports.foundDoneText' =>
            ({required Object names}) => '${names}, from the statement',
          'imports.repeatsTitle' =>
            ({required Object count}) => 'Looks regular · ${count}',
          'imports.namesAnd' =>
            ({required Object names, required Object last}) =>
                '${names} and ${last}',
          'imports.rowsLeft' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} row stays out of the ledger',
                  other: '${count} rows stay out of the ledger',
                ),
          'imports.unreadCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} did not read',
                  other: '${count} did not read',
                ),
          'imports.declinedCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} did not go through the bank',
                  other: '${count} did not go through the bank',
                ),
          'imports.unfitCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} does not fit its account',
                  other: '${count} do not fit their account',
                ),
          'imports.restFine' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} more is fine',
                  other: 'the other ${count} are fine',
                ),
          'imports.unreadTitle' => 'Did not read',
          'imports.declinedTitle' => 'Did not go through the bank',
          'imports.unfitTitle' => 'Do not fit the account',
          'imports.rowLine' =>
            ({required Object line, required Object what}) =>
                'Row ${line} · ${what}',
          'imports.leftNote' =>
            'Record the unread ones by hand or download the statement again: Birka adds only what the ledger does not have yet.',
          'imports.understood' => 'Got it',
          'imports.bankHas' =>
            ({required Object amount}) => 'The bank has ${amount}',
          'imports.bankHasMissing' =>
            ({required Object amount}) =>
                'The bank has ${amount}: rows that did not read seem to be missing',
          'imports.mostUnread' =>
            ({required num n, required Object count, required Object total}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} row of ${total} did not read',
                  other: '${count} rows of ${total} did not read',
                ),
          'imports.mostUnreadText' =>
            'The bank seems to have changed its statement: check where its date and amount are and what comes before the cents.',
          'imports.checkColumns' => 'Check the columns',
          'imports.declinedRows' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} operation did not go through the bank',
                  other: '${count} operations did not go through the bank',
                ),
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
          'inbox.entryTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} waits for you in the inbox',
                  other: '${count} wait for you in the inbox',
                ),
          'inbox.entryUncategorized' =>
            ({required Object count}) => '${count} without a category',
          'inbox.entryTransfer' =>
            ({required Object account}) => 'a transfer from «${account}»',
          'inbox.entryTransfers' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} transfer between accounts',
                  other: '${count} transfers between accounts',
                ),
          'inbox.entryBoth' =>
            ({required Object first, required Object second}) =>
                '${first} and ${second}',
          'inbox.unpick' => 'Clear',
          'notifications.title' => 'Notifications',
          'notifications.back' => 'Back',
          'notifications.bell' => 'Notifications',
          'notifications.bellNew' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Notifications, ${count} new',
                  other: 'Notifications, ${count} new',
                ),
          'notifications.fresh' =>
            ({required Object count}) => 'New · ${count}',
          'notifications.readAll' => 'Mark all read',
          'notifications.subtitleNew' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${count} new · 90 days of history',
                  other: '${count} new · 90 days of history',
                ),
          'notifications.subtitleRead' => 'All read · 90 days of history',
          'notifications.filters.all' => 'All',
          'notifications.filters.payment' => 'Payments',
          'notifications.filters.debt' => 'Debts',
          'notifications.filters.import' => 'Imports',
          'notifications.filtersLabel' => 'Whose notifications',
          'notifications.emptyTitle' => 'All quiet',
          'notifications.emptyText' =>
            'Reminders of your payments and of the days of your debts, and the results of imports, come here.',
          'notifications.emptyImports' =>
            'The results of your statement imports come here.',
          'notifications.failed' => 'Could not read the notifications.',
          'notifications.keeps' => 'Birka keeps notifications for 90 days',
          'notifications.yesterday' => 'yesterday',
          'notifications.tomorrow' =>
            ({required Object date}) => 'Tomorrow, ${date}',
          'notifications.waitsToday' => 'Today, waits for you',
          'notifications.waits' => 'Waits for you',
          'notifications.postsToday' => 'Today, it posts itself',
          'notifications.posts' => 'Posts itself',
          'notifications.posted' =>
            ({required Object time}) => 'Posted at ${time}',
          'notifications.postedOn' =>
            ({required Object date}) => 'Posted on ${date}',
          'notifications.postedItself' => 'Posted itself',
          'notifications.skipped' =>
            ({required Object date}) => 'Skipped · next on ${date}',
          'notifications.found' => 'Found in a statement',
          'notifications.importTitle' =>
            ({required Object bank, required Object period}) =>
                '${bank} · ${period}',
          'notifications.importWaiting' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} of ${count} waits in the inbox',
                  other: '${n} of ${count} wait in the inbox',
                ),
          'notifications.importAdded' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Added ${count} operation',
                  other: 'Added ${count} operations',
                ),
          'notifications.importUndone' => 'Import undone',
          'notifications.debtTitle' =>
            ({required Object name, required Object amount}) =>
                'Due · ${name}, ${amount}',
          'notifications.debtTitleToday' =>
            ({required Object name, required Object amount}) =>
                'Due today · ${name}, ${amount}',
          'notifications.debtSince' =>
            ({required Object date}) => 'since ${date}',
          'notifications.debtNoteSince' =>
            ({required Object note, required Object date}) =>
                '${note} · since ${date}',
          'notifications.debtReturned' =>
            ({required Object date}) => 'Paid back ${date}',
          'notifications.debtRepaid' =>
            ({required Object date}) => 'You paid back ${date}',
          'notifications.debtReturnedPart' =>
            ({required Object left}) => 'Part paid back · ${left} left',
          'notifications.debtRepaidPart' =>
            ({required Object left}) => 'You paid back a part · ${left} left',
          'notifications.debtWaits' =>
            ({required Object left}) => 'Not paid back yet · ${left} left',
          'notifications.debtWaitsRepaid' =>
            ({required Object left}) => 'Not paid back yet · ${left} left',
          'notifications.debtGone' => 'This debt is no longer here',
          'notifications.today' => 'today',
          'notifications.months.0' => 'January',
          'notifications.months.1' => 'February',
          'notifications.months.2' => 'March',
          'notifications.months.3' => 'April',
          'notifications.months.4' => 'May',
          'notifications.months.5' => 'June',
          'notifications.months.6' => 'July',
          'notifications.months.7' => 'August',
          'notifications.months.8' => 'September',
          'notifications.months.9' => 'October',
          'notifications.months.10' => 'November',
          'notifications.months.11' => 'December',
          'notifications.howTitle' => 'What comes here',
          'notifications.how.0' =>
            '«Payments»: a regular payment that waits for your «Post».',
          'notifications.how.1' =>
            '«Imports»: what a statement brought, and what waits in the «Inbox».',
          'notifications.how.2' => '«Birka»: what is new in Birka itself.',
          'notifications.how.3' =>
            'New ones stand on top; read ones go to the history, day by day.',
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
          'reports.monthReport.0' => 'Report for January',
          'reports.monthReport.1' => 'Report for February',
          'reports.monthReport.2' => 'Report for March',
          'reports.monthReport.3' => 'Report for April',
          'reports.monthReport.4' => 'Report for May',
          'reports.monthReport.5' => 'Report for June',
          'reports.monthReport.6' => 'Report for July',
          'reports.monthReport.7' => 'Report for August',
          'reports.monthReport.8' => 'Report for September',
          'reports.monthReport.9' => 'Report for October',
          'reports.monthReport.10' => 'Report for November',
          'reports.monthReport.11' => 'Report for December',
          'schedules.title' => 'Regular payments',
          'schedules.back' => 'Back',
          'schedules.add' => 'New payment',
          'schedules.close' => 'Close',
          'schedules.waitingTitle' => 'Waits for you',
          'schedules.post' => 'Post',
          'schedules.skip' => 'Skip',
          'schedules.waitingNote' =>
            'When it comes in a bank statement, Birka will not count it twice.',
          'schedules.waitingDay' =>
            ({required Object name, required Object day}) => '${name} · ${day}',
          'schedules.ahead' => 'The next 30 days',
          'schedules.aheadTotal' =>
            ({required Object date, required Object amount}) =>
                'until ${date} ${amount}',
          'schedules.leftAfterPayday' =>
            ({required Object date, required Object amount}) =>
                'By the salary on ${date} your accounts will hold ≈ ${amount}, before everyday spending.',
          'schedules.leftAfterMonth' =>
            ({required Object amount}) =>
                'By the end of the month your accounts will hold ≈ ${amount}, before everyday spending.',
          'schedules.leftAfterPaydayAdvance' =>
            ({required Object date, required Object amount}) =>
                'By the salary on ${date} your accounts will hold ≈ ${amount} with the advance, before everyday spending.',
          'schedules.leftAfterMonthAdvance' =>
            ({required Object amount}) =>
                'By the end of the month your accounts will hold ≈ ${amount} with the advance, before everyday spending.',
          'schedules.section' =>
            ({required Object title, required Object count}) =>
                '${title} · ${count}',
          _ => null,
        } ??
        switch (path) {
          'schedules.all' => 'All regular payments',
          'schedules.emptyTitle' => 'No regular payments yet',
          'schedules.emptyText' =>
            'Rent, subscriptions, salary: add them once, and Birka shows the month ahead and how much you can spend a day.',
          'schedules.emptyAdd' => 'Add a payment',
          'schedules.everyMonth' =>
            ({required Object day}) => 'every month on day ${day}',
          'schedules.everyWeek' =>
            ({required Object weekday}) => 'every week, ${weekday}',
          'schedules.everyYear' =>
            ({required Object date}) => 'once a year, ${date}',
          'schedules.asks' => 'ask',
          'schedules.posts' => 'posts itself',
          'schedules.today' => 'today',
          'schedules.tomorrow' => 'tomorrow',
          'schedules.posted' =>
            ({required Object name, required Object amount}) =>
                'Posted «${name}» · ${amount}',
          'schedules.skippedAsk' =>
            ({required Object name, required Object date}) =>
                'Skipped «${name}» · we will ask on ${date}',
          'schedules.skippedPost' =>
            ({required Object name, required Object date}) =>
                'Skipped «${name}» · next on ${date}',
          'schedules.deleted' =>
            ({required Object name}) => 'Deleted «${name}»',
          'schedules.found' =>
            ({required Object name}) => 'Found «${name}» in a statement',
          'schedules.foundOf' =>
            ({required Object name, required Object bank}) =>
                'Found «${name}» in the statement of ${bank}',
          'schedules.foundText' =>
            ({required Object date, required Object amount}) =>
                '${date} · ${amount} · marked as posted, no copy will come',
          'schedules.donePosted' =>
            ({required Object date}) => 'posted today · next on ${date}',
          'schedules.doneSkipped' =>
            ({required Object date}) => 'skipped · next on ${date}',
          'schedules.doneFound' =>
            ({required Object date}) =>
                'found in a statement · next on ${date}',
          'schedules.on.mon' => 'on Mondays',
          'schedules.on.tue' => 'on Tuesdays',
          'schedules.on.wed' => 'on Wednesdays',
          'schedules.on.thu' => 'on Thursdays',
          'schedules.on.fri' => 'on Fridays',
          'schedules.on.sat' => 'on Saturdays',
          'schedules.on.sun' => 'on Sundays',
          'schedules.weekday.mon' => 'Mon',
          'schedules.weekday.tue' => 'Tue',
          'schedules.weekday.wed' => 'Wed',
          'schedules.weekday.thu' => 'Thu',
          'schedules.weekday.fri' => 'Fri',
          'schedules.weekday.sat' => 'Sat',
          'schedules.weekday.sun' => 'Sun',
          'schedules.newTitle' => 'New payment',
          'schedules.kinds.expense' => 'Expense',
          'schedules.kinds.income' => 'Income',
          'schedules.kinds.transfer' => 'Transfer',
          'schedules.kindLabel' => 'What kind of payment',
          'schedules.amount' => 'Amount',
          'schedules.name' => 'Name',
          'schedules.namePlaceholder' => 'Rent, for example',
          'schedules.category' => 'Category',
          'schedules.noCategory' => 'No category',
          'schedules.categoryLater' => 'to sort in the inbox',
          'schedules.account' => 'Account',
          'schedules.toAccount' => 'To',
          'schedules.fromAccount' => 'From',
          'schedules.incomeAccount' => 'To the account',
          'schedules.pickAccount' => 'Pick an account',
          'schedules.every' => 'Repeat every',
          'schedules.everyOptions.month' => 'Month',
          'schedules.everyOptions.week' => 'Week',
          'schedules.everyOptions.year' => 'Year',
          'schedules.dayOfMonth' => 'Day of the month',
          'schedules.dayOfWeek' => 'Day of the week',
          'schedules.dayOfYear' => 'Day of the year',
          'schedules.dayNumber' => ({required Object day}) => 'day ${day}',
          'schedules.next' => 'Next time',
          'schedules.onDayTitle' => 'On its day',
          'schedules.onDay.ask' => 'Ask me',
          'schedules.onDay.post' => 'Post itself',
          'schedules.askNote' =>
            'Good for an amount that changes, like utility bills: on its day the payment waits for your «Post».',
          'schedules.postNote' =>
            'For subscriptions of one amount. When it comes in a bank statement, there will be no copy.',
          'schedules.save' => 'Save',
          'schedules.saveNote' =>
            'Shows up in «The next payments» and in «You can spend today»',
          'schedules.changeNote' =>
            ({required Object date}) => 'Changes from the next time: ${date}',
          'schedules.done' => 'Done',
          'schedules.delete' => 'Delete the payment',
          'schedules.deleteNote' => 'Past operations stay',
          'schedules.deleteTitle' =>
            ({required Object name}) => 'Delete «${name}»?',
          'schedules.canSpend' => 'You can spend today',
          'schedules.overToday' => 'Today is over the daily amount',
          'schedules.ofPerDay' =>
            ({required Object amount}) => 'of ${amount} a day',
          'schedules.spentUntilPayday' =>
            ({required Object amount, required Object days}) =>
                'Spent ${amount} · ${days} to the salary',
          'schedules.spentUntilMonth' =>
            ({required Object amount, required Object days}) =>
                'Spent ${amount} · ${days} to the end of the month',
          'schedules.spentOver' =>
            ({required Object amount, required Object tomorrow}) =>
                'Spent ${amount} · tomorrow you can spend ${tomorrow} a day',
          'schedules.short' =>
            ({required Object amount, required Object date}) =>
                '${amount} short until ${date}',
          'schedules.upcoming' => 'The next payments',
          'schedules.noPaydayLabel' => 'Until the salary',
          'schedules.noPaydayTitle' => 'How much can you spend a day?',
          'schedules.noPaydayText' =>
            'Tell Birka your payday. It takes the regular payments until then away and splits the rest between the days.',
          'schedules.noPaydayAction' => 'Set the payday',
          'schedules.days' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} day',
                  other: '${n} days',
                ),
          'schedules.paydayTitle' => 'Money until the salary',
          'schedules.perDay' => ({required Object amount}) => '${amount} a day',
          'schedules.notEnough' =>
            ({required Object amount}) => '${amount} short',
          'schedules.untilPayday' =>
            ({required Object date, required Object days}) =>
                'until the salary on ${date} · ${days}',
          'schedules.untilDate' =>
            ({required Object date, required Object days}) =>
                'until ${date} · ${days}',
          'schedules.morning' => 'In the accounts this morning',
          'schedules.paymentsUntilPayday' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment until the salary',
                  other: '${n} payments until the salary',
                ),
          'schedules.paymentsUntilMonth' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment until the end of the month',
                  other: '${n} payments until the end of the month',
                ),
          'schedules.aside' => 'Keep aside',
          'schedules.leftFor' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Left for ${n} day',
                  other: 'Left for ${n} days',
                ),
          'schedules.countUntil' => 'Count until',
          'schedules.until.payday' => 'The payday',
          'schedules.until.monthEnd' => 'The end of the month',
          'schedules.payday' => 'Payday',
          'schedules.paydayFrom' =>
            ({required Object name}) => 'from the payment «${name}»',
          'schedules.paydayNone' => 'add a regular income',
          'schedules.paydayDay' => ({required Object day}) => 'day ${day}',
          'schedules.accountsTitle' => 'Which accounts to count',
          'schedules.count' => ({required Object name}) => 'Count «${name}»',
          'schedules.otherCurrency' => 'another currency, not counted yet',
          'schedules.asideRow' => 'Keep aside until the salary',
          'schedules.asideNote' => 'not to spend, even if «you can»',
          'schedules.salaryName' => 'Salary',
          'schedules.monthsShort.0' => 'Jan',
          'schedules.monthsShort.1' => 'Feb',
          'schedules.monthsShort.2' => 'Mar',
          'schedules.monthsShort.3' => 'Apr',
          'schedules.monthsShort.4' => 'May',
          'schedules.monthsShort.5' => 'Jun',
          'schedules.monthsShort.6' => 'Jul',
          'schedules.monthsShort.7' => 'Aug',
          'schedules.monthsShort.8' => 'Sep',
          'schedules.monthsShort.9' => 'Oct',
          'schedules.monthsShort.10' => 'Nov',
          'schedules.monthsShort.11' => 'Dec',
          'schedules.advance' => 'Advance',
          'schedules.everyTwice' =>
            ({required Object advance, required Object day}) =>
                'the advance on day ${advance} and the salary on day ${day}',
          'schedules.advancePosted' =>
            ({required Object date}) =>
                'advance posted today · salary on ${date}',
          'schedules.advanceSkipped' =>
            ({required Object date}) => 'advance skipped · salary on ${date}',
          'schedules.advanceFound' =>
            ({required Object date}) =>
                'advance found in a statement · salary on ${date}',
          'schedules.restPosted' =>
            ({required Object date}) =>
                'salary posted today · advance on ${date}',
          'schedules.restSkipped' =>
            ({required Object date}) => 'salary skipped · advance on ${date}',
          'schedules.restFound' =>
            ({required Object date}) =>
                'salary found in a statement · advance on ${date}',
          'schedules.advanceOn' =>
            ({required Object date}) => 'Advance on ${date}',
          'schedules.nearEnough' =>
            ({
              required Object date,
              required Object amount,
              required Object days,
            }) => 'Until the advance on ${date}: ${amount} for ${days}',
          'schedules.nearShort' =>
            ({required Object date, required Object amount}) =>
                'Until the advance on ${date}, ${amount} short',
          'schedules.paydayTwice' => 'Advance and salary',
          'schedules.paydayTwiceDays' =>
            ({required Object advance, required Object day}) =>
                'days ${advance} and ${day}',
          'schedules.partsTitle' => 'How it comes',
          'schedules.parts.one' => 'One sum',
          'schedules.parts.two' => 'With an advance',
          'schedules.partsOne' => 'The whole sum comes on one day.',
          'schedules.partsTwo' =>
            ({required Object advance, required Object day}) =>
                'Half and half: the advance on day ${advance}, the salary on day ${day}.',
          'schedules.partsOwn' =>
            ({
              required Object advanceAmount,
              required Object advance,
              required Object restAmount,
              required Object day,
            }) =>
                'The advance of ${advanceAmount} on day ${advance}, the salary of ${restAmount} on day ${day}.',
          'schedules.amountMonthly' => 'Amount a month',
          'schedules.halves' =>
            ({required Object amount}) =>
                '${amount} as the advance and as the salary',
          'schedules.halvesOwn' =>
            ({required Object advance, required Object rest}) =>
                'the advance of ${advance} and the salary of ${rest}',
          'schedules.halvesUneven' =>
            'The sum does not split into equal halves: change the cents',
          'schedules.advanceDay' => 'Advance',
          'schedules.restDay' => 'Salary',
          'schedules.advanceAmount' => 'Advance amount',
          'schedules.advanceHalf' => 'half',
          'schedules.advanceRest' =>
            ({required Object amount, required Object day}) =>
                'The rest comes with the salary: ${amount} on day ${day}.',
          'schedules.advanceHalfChip' =>
            ({required Object amount}) => 'Half · ${amount}',
          'schedules.nextAdvance' =>
            ({required Object date}) => 'advance, ${date}',
          'schedules.monthStartHint' =>
            ({
              required Object day,
              required Object month,
              required Object from,
              required Object to,
            }) =>
                'The salary comes on day ${day}: a month can start on it, and then ${month} runs from ${from} to ${to}.',
          'schedules.remindTitle' => 'Reminders',
          'schedules.remindNotify' => 'Notifications from Birka',
          'schedules.remindNotifyOff' => 'while Birka is on the phone',
          'schedules.remindNotifyOn' =>
            ({required num n, required Object time}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment · at ${time}',
                  other: '${n} payments · at ${time}',
                ),
          'schedules.remindNotifyDebts' =>
            ({required num n, required Object time}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} debt · at ${time}',
                  other: '${n} debts · at ${time}',
                ),
          'schedules.remindNotifyBoth' =>
            ({
              required Object payments,
              required Object debts,
              required Object time,
            }) => '${payments} and ${debts} · at ${time}',
          'schedules.remindPayments' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment',
                  other: '${n} payments',
                ),
          'schedules.remindDebtCount' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} debt',
                  other: '${n} debts',
                ),
          'schedules.remindNotifyDenied' => 'no access to notifications',
          'schedules.remindCalendar' => 'Calendar events',
          'schedules.remindCalendarOn' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'the «Birka» calendar · ${n} event',
                  other: 'the «Birka» calendar · ${n} events',
                ),
          'schedules.remindCalendarOff' => 'reminds even without Birka',
          'schedules.remindCalendarDenied' => 'no access to the calendar',
          'schedules.remindTime' => 'Time',
          'schedules.remindSums' => 'Amounts in reminders',
          'schedules.remindSumsNote' =>
            'on the lock screen and in the calendar',
          'schedules.remindNoteOff' =>
            'A payment can remind on its day or the day before: each payment says which. A debt reminds on its day.',
          'schedules.remindNoteOn' =>
            'Delete Birka and its reminders go with it. The calendar reminds even without it.',
          'schedules.remindNoteDenied' =>
            'For Birka to remind, allow its notifications in the settings of the phone.',
          'schedules.remindNoteCalendar' =>
            'If the calendar syncs with iCloud or Google, the names and the amounts of the payments go there.',
          'schedules.remindNoteBoth' =>
            'A payment is reminded of twice: by Birka and by the calendar.',
          'schedules.remindNoteCalendarDenied' =>
            'For the calendar to remind, give it access in the settings of the phone.',
          'schedules.remindAskTitle' => 'Reminders from Birka',
          'schedules.remindAskText' =>
            ({required Object time}) =>
                'Birka reminds of a payment at ${time}, on its day or the day before, as the payment says. The reminders are set on this phone and need no server.',
          'schedules.remindAskExample' =>
            ({required Object date, required Object time}) =>
                '${date}, ${time} · a tap opens the payment',
          'schedules.remindAskLocalTitle' => 'They live with Birka',
          'schedules.remindAskLocalText' =>
            'Delete the app and its reminders go too. The calendar reminds even without it.',
          'schedules.remindAllow' => 'Allow notifications',
          'schedules.remindNotNow' => 'Not now',
          'schedules.remindCalendarAskText' =>
            'Birka makes a calendar «Birka» and puts the regular payments in it. The calendar itself reminds, even if Birka is deleted.',
          'schedules.remindCalendarAskOwnTitle' => 'The «Birka» calendar',
          'schedules.remindCalendarAskOwn' =>
            ({required num n, required Object time}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment · reminds at ${time}',
                  other: '${n} payments · reminds at ${time}',
                ),
          'schedules.remindCalendarAskSyncTitle' => 'If the calendar syncs',
          'schedules.remindCalendarAskSyncText' =>
            'The names and the amounts of the payments go to iCloud or Google. The amounts can be left out in the settings.',
          'schedules.remindCalendarAskOthersTitle' =>
            'Birka does not read other events',
          'schedules.remindCalendarAskOthersText' =>
            'The phone asks for full access: without it Birka cannot change or delete its own events.',
          'schedules.remindCalendarAllow' => 'Allow access to the calendar',
          'schedules.remindCalendarRemoveTitle' =>
            'Remove the «Birka» calendar?',
          'schedules.remindCalendarRemoveText' =>
            ({
              required num n,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              n,
              one:
                  'The «Birka» calendar and its ${n} event leave the phone, and the calendar stops reminding of the payments. Other calendars stay as they are.',
              other:
                  'The «Birka» calendar and its ${n} events leave the phone, and the calendar stops reminding of the payments. Other calendars stay as they are.',
            ),
          'schedules.remindCalendarRemove' => 'Remove the calendar',
          'schedules.remindCalendarDeniedTitle' => 'No access to the calendar',
          'schedules.remindCalendarDeniedText' =>
            'Access is off in the settings of the phone. Open Settings → Birka → Calendars and choose Full Access.',
          'schedules.remindCalendarOnToast' =>
            'The payments are in the «Birka» calendar',
          'schedules.remindCalendarOffToast' =>
            'The «Birka» calendar is removed',
          'schedules.remindDeniedTitle' => 'No access to notifications',
          'schedules.remindDeniedText' =>
            'Notifications of Birka are off in the settings of the phone. Open Settings → Birka → Notifications and turn them on.',
          'schedules.remindOpenSettings' => 'Open settings',
          'schedules.remindCancel' => 'Cancel',
          'schedules.remindOnTitle' => 'Reminders are on',
          'schedules.remindOnText' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Birka will remind of ${n} payment',
                  other: 'Birka will remind of ${n} payments',
                ),
          'schedules.remindOnNone' => 'Mark «Remind» on the payments',
          'schedules.remindToday' => 'Today. Tap to post or skip it.',
          'schedules.remindTodayAuto' => 'Today, it posts itself.',
          'schedules.remindTomorrow' =>
            ({required Object date}) =>
                'Tomorrow, ${date}. Tap to open the payment.',
          'schedules.remindDebtTitle' =>
            ({required Object name, required Object amount}) =>
                'Due today · ${name}, ${amount}',
          'schedules.remindDebtTitleNoSum' =>
            ({required Object name}) => 'Due today · ${name}',
          'schedules.remindDebtLent' =>
            'The money is due back to you today. Tap to open the debt.',
          'schedules.remindDebtBorrowed' =>
            'Your debt is due today. Tap to open it.',
          'schedules.remindChannel' => 'Payment and debt reminders',
          'schedules.remindChannelNote' =>
            'Regular payments on their day or the day before, and the days of debts',
          'schedules.remindSection' => 'Remind',
          'schedules.reminder.onDay' => 'On the day',
          'schedules.reminder.dayBefore' => 'The day before',
          'schedules.reminder.none' => 'Don\'t remind',
          'schedules.remindLine' =>
            ({
              required Object date,
              required Object time,
              required Object who,
            }) => '${date} at ${time} · ${who}',
          'schedules.remindByBirka' => 'Birka reminds',
          'schedules.remindByCalendar' => 'the «Birka» calendar reminds',
          'schedules.remindByBoth' => 'Birka and the calendar remind',
          'schedules.remindLineNone' => 'No reminder',
          'schedules.remindLineOff' => 'Reminders are off in More',
          'schedules.remindEnable' => 'Turn reminders on',
          'schedules.makeRegular' => 'Make it regular',
          'schedules.makeRegularLine' =>
            ({required Object every}) => 'Repeat ${every}',
          'schedules.regularPayment' => 'Regular payment',
          'schedules.fromOperation' =>
            ({required Object date}) => 'From the operation of ${date}',
          'schedules.madeRegular' =>
            ({required Object name}) => 'Added to regular payments: «${name}»',
          'schedules.findsTitle' => 'Looks regular',
          'schedules.findsTitleEmpty' => 'Found in your operations',
          'schedules.findsNote' =>
            'These came every month. Tap one to add it, or ✕ if it repeated by chance.',
          'schedules.findLine' =>
            ({required num n, required Object day, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'day ${day} · ${count} time in a row',
                  other: 'day ${day} · ${count} times in a row',
                ),
          'schedules.findLineVaries' =>
            ({required num n, required Object day, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'about day ${day} · ${count} time',
                  other: 'about day ${day} · ${count} times',
                ),
          'schedules.findDismiss' =>
            ({required Object name}) => 'Not regular: ${name}',
          'schedules.findDismissed' =>
            ({required Object name}) => 'We won\'t suggest «${name}» again',
          'schedules.findRestore' => 'Undo',
          'schedules.foundIn' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Found in the operations · ${count} time',
                  other: 'Found in the operations · ${count} times',
                ),
          'schedules.amountRange' =>
            ({required Object min, required Object max}) =>
                'the last amount · it went from ${min} to ${max}',
          'schedules.forecast' => 'If you spend as usual',
          'schedules.forecastRunsOut' =>
            ({required Object date}) => 'The money runs out on ${date}',
          'schedules.forecastLastsPayday' => 'It lasts until payday',
          'schedules.forecastLastsMonth' => 'It lasts until the month ends',
          'schedules.forecastNone' => 'The money is short already',
          'schedules.forecastNonePayday' =>
            'The payments before payday take more than the accounts hold.',
          'schedules.forecastNoneMonth' =>
            'The payments before the month ends take more than the accounts hold.',
          'schedules.forecastShortText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object amount,
            }) =>
                'You usually spend ≈ ${usual} a day, and the plan allows ${perDay}. By ${date} ≈ ${amount} is missing.',
          'schedules.forecastLeftText' =>
            ({
              required Object usual,
              required Object date,
              required Object amount,
            }) =>
                'You usually spend ≈ ${usual} a day: by ${date} ≈ ${amount} is left.',
          'schedules.forecastToday' => 'today',
          'schedules.forecastPayday' =>
            ({required Object date}) => '${date} · payday',
          'schedules.forecastUsual' => 'as usual',
          'schedules.forecastPlan' =>
            ({required Object amount}) => 'plan: ${amount} a day',
          'schedules.forecastPlanBare' => 'plan',
          'schedules.forecastNote' =>
            'Usual spending is the average of 3 months on these accounts, without regular payments and transfers.',
          'schedules.forecastLineRunsOut' =>
            ({required Object date}) =>
                'As usual, the money runs out on ${date}',
          'schedules.forecastLinePayday' => 'As usual, it lasts until payday',
          'schedules.forecastLineMonth' =>
            'As usual, it lasts until the month ends',
          'schedules.forecastAdvanceLastsText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object end,
              required Object amount,
            }) =>
                'You usually spend ≈ ${usual} a day, and until the advance the plan allows ${perDay}. After the advance on ${date} it lasts: by ${end} ≈ ${amount} is left.',
          'schedules.forecastAdvanceAgainText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object again,
              required Object end,
              required Object amount,
            }) =>
                'You usually spend ≈ ${usual} a day, and until the advance the plan allows ${perDay}. With the advance on ${date} the money runs out again on ${again}: by ${end} ≈ ${amount} is missing.',
          'schedules.forecastAdvanceShortText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object end,
              required Object amount,
            }) =>
                'You usually spend ≈ ${usual} a day, and until the advance the plan allows ${perDay}. The advance on ${date} does not cover these days: by ${end} ≈ ${amount} is missing.',
          'schedules.forecastNoneAdvance' =>
            ({required Object date}) =>
                'Until the advance on ${date}, the payments and the money set aside take more than the accounts hold.',
          'schedules.forecastPlanAdvance' =>
            ({required Object amount}) =>
                'plan: ${amount} a day until the advance',
          'schedules.forecastAdvance' =>
            ({required Object date}) => '${date} · advance',
          'schedules.subtitleNext' =>
            ({required Object date, required Object count}) =>
                'Next on ${date} · ${count}',
          'schedules.subtitleToday' =>
            ({required num n, required Object date}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Today, ${date} · ${n} waits for you',
                  other: 'Today, ${date} · ${n} wait for you',
                ),
          'schedules.subtitleNone' => 'None yet',
          'schedules.paymentsCount' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} payment',
                  other: '${n} payments',
                ),
          'schedules.perDayTitle' => 'You can spend a day',
          'schedules.paidAheadPayday' =>
            ({required Object amount}) =>
                'The payments until payday are already taken off: ${amount}.',
          'schedules.paidAheadMonth' =>
            ({required Object amount}) =>
                'The payments until the month ends are already taken off: ${amount}.',
          'schedules.howTitle' => 'How it works',
          'schedules.how.0' =>
            'A payment stands in the plan on its day and is already out of what you can spend today.',
          'schedules.how.1' =>
            'On its day it waits for your «Post», or posts itself, as the payment says.',
          'schedules.how.2' =>
            'When it comes in a bank statement, Birka will not count it twice.',
          'schedules.how.3' =>
            'Birka finds what repeats in your operations and offers to add it.',
          'schedules.failed' => 'Could not read the payments.',
          'schedules.previewTitle' => 'In the list of payments',
          'schedules.previewNext' => 'The next times',
          'schedules.cancel' => 'Cancel',
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
          'settings.monthStart' => 'Month starts on',
          'settings.monthStartDay' => ({required Object day}) => 'day ${day}',
          'settings.monthStartNote' => 'for the overview and the reports',
          'settings.monthStartCalendar' => 'as on the calendar',
          'tags.title' => 'Tags',
          'tags.back' => 'Back',
          'tags.add' => 'New tag',
          'tags.close' => 'Close',
          'tags.edit' => 'Edit',
          'tags.now' => 'Now',
          'tags.trips' => 'Trips',
          'tags.plain' => 'Tags',
          'tags.trip' => 'Trip',
          'tags.tag' => 'Tag',
          'tags.note' =>
            'Totals are expenses at the central bank rate of the day of each.',
          'tags.emptyTitle' => 'No tags yet',
          'tags.emptyText' =>
            'Tag a trip, a renovation or a holiday, and see what it took in every currency at once.',
          'tags.failed' => 'Could not read the tags.',
          'tags.lastDay' => 'Last day',
          'tags.dayOf' =>
            ({required Object day, required Object total}) =>
                'Day ${day} of ${total}',
          'tags.days' =>
            ({required Object from, required Object to}) => '${from}–${to}',
          'tags.daysApart' =>
            ({required Object from, required Object to}) => '${from} — ${to}',
          'tags.inDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'in ${n} day',
                  other: 'in ${n} days',
                ),
          'tags.operations' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} operation',
                  other: '${n} operations',
                ),
          'tags.since' => ({required Object date}) => 'since ${date}',
          'tags.howItWorks' => 'How it works',
          'tags.steps.first' =>
            'A tag gathers what a trip or a project took in every currency, at the rate of the day.',
          'tags.steps.second' =>
            'A trip has days: its expenses on those days get its tag by themselves, except regular payments.',
          'tags.steps.third' =>
            'Tag the tickets and the stay that you bought in advance on the card of the operation.',
          'tags.report.todayLast' => 'today is the last day',
          'tags.report.perDay' => 'A day on the spot',
          'tags.report.perMonth' => 'A month',
          'tags.report.forDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'over ${n} day',
                  other: 'over ${n} days',
                ),
          'tags.report.count' => 'Operations',
          'tags.report.there' => ({required Object n}) => '${n} there',
          'tags.report.before' => ({required Object n}) => '${n} in advance',
          'tags.report.after' => ({required Object n}) => '${n} after',
          'tags.report.last' =>
            ({required Object date}) => 'the latest on ${date}',
          'tags.report.currencies' => 'Currencies',
          'tags.report.ratesNote' =>
            'At the central bank rate of the day of each operation.',
          'tags.report.onTheSpot' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: '${n} operation on the spot',
                  other: '${n} operations on the spot',
                ),
          'tags.report.noRate' =>
            'Some days have no rate yet, and the total leaves them out.',
          'tags.report.categories' => 'Categories',
          'tags.report.operations' => 'Operations',
          'tags.report.nothing' => 'No operations wear this tag yet.',
          'tags.report.noCategory' => 'No category',
          'tags.form.newTitle' => 'New tag',
          'tags.form.trip' => 'Trip',
          'tags.form.plain' => 'Tag',
          'tags.form.name' => 'Name',
          'tags.form.namePlaceholder' => 'Batumi',
          'tags.form.dates' => 'Dates',
          'tags.form.from' => 'From',
          'tags.form.to' => 'To',
          'tags.form.marks' => 'Tag the expenses',
          'tags.form.marksOn' => 'Of these days',
          'tags.form.marksOff' => 'By hand only',
          'tags.form.marksAhead' =>
            'The expenses of these days get the tag by themselves. Regular payments stay as they are.',
          'tags.form.marksPast' =>
            ({
              required num n,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              n,
              one:
                  'These days already have ${n} expense, and it gets the tag now. Regular payments stay as they are.',
              other:
                  'These days already have ${n} expenses, and they get the tag now. Regular payments stay as they are.',
            ),
          'tags.form.manual' =>
            'You put the tag on yourself, when you add an operation or on its card.',
          'tags.form.plainNote' =>
            'You put the tag on yourself, when you add an operation or on its card. Its report gathers what it took in every currency.',
          'tags.form.footTrip' =>
            'The tickets bought in advance can wear the tag too',
          'tags.form.footPlain' => 'Tags live in More → Tags',
          'tags.form.save' => 'Save',
          'tags.form.done' => 'Done',
          'tags.form.nameMissing' => 'Give the tag a name.',
          'tags.form.failed' => 'Could not save. Try again.',
          'tags.addedTrip' =>
            ({required Object name}) => 'Added the trip «${name}»',
          'tags.addedTag' =>
            ({required Object name}) => 'Added the tag «${name}»',
          'tags.saved' => ({required Object name}) => 'Saved «${name}»',
          'tags.marked' =>
            ({required num n, required Object name}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Tagged ${n} expense: «${name}»',
                  other: 'Tagged ${n} expenses: «${name}»',
                ),
          'tags.unmarked' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'Took the tag off ${n} expense',
                  other: 'Took the tag off ${n} expenses',
                ),
          'tags.undo' => 'Undo',
          'tags.picker.title' => 'Tags',
          'tags.picker.search' => 'Find or create',
          'tags.picker.clear' => 'Clear the search',
          'tags.picker.create' =>
            ({required Object name}) => 'New tag «${name}»',
          'tags.picker.createText' => 'A trip with dates or just a tag',
          'tags.picker.tripsNote' =>
            'While a trip goes on, its tag goes onto the expenses of its days by itself.',
          'tags.picker.now' => 'now',
          'tags.picker.emptyTitle' => 'No tags yet',
          'tags.picker.emptyText' =>
            'Type a name: a trip, a renovation or a holiday. A tag gathers what they took in every currency.',
          'tags.row.add' => 'Add a tag',
          'tags.row.addText' => 'A trip, a renovation or a holiday',
          'tags.row.trip' => ({required Object days}) => 'Trip · ${days}',
          'tags.row.byDays' =>
            ({required Object days}) => 'Trip · ${days} · by its dates',
          'tags.row.plain' => 'Tag',
          'tags.row.more' => ({required Object n}) => 'and ${n} more',
          'transactions.expense' => 'Expense',
          'transactions.income' => 'Income',
          'transactions.transfer' => 'Transfer',
          'transactions.adjustment' => 'Correction',
          'transactions.today' => 'Today',
          'transactions.yesterday' => 'Yesterday',
          'transactions.pickDay' => 'Pick a day',
          'transactions.note' => 'Note',
          'transactions.addNote' => 'Note',
          'transactions.addTag' => 'Tag',
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
          'transactions.fromQuestion' => 'From the question',
          'transactions.toAnswer' => 'Back to the answer',
          'transactions.dropFocus' =>
            ({required Object title}) => 'Take off “${title}”',
          'transactions.focusText' =>
            'The list shows only what the question was about. Take the plaque off to see every operation of the month.',
          'transactions.backToAnswer' => 'Go back to the answer',
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
          'transactions.debt.title' => 'Debt',
          'transactions.debt.lent' => 'lent',
          'transactions.debt.returned' => 'paid back',
          'transactions.debt.borrowed' => 'borrowed',
          'transactions.debt.repaid' => 'repaid',
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
          'transactions.allOperations' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('en'))(
                  n,
                  one: 'All ${n} operation',
                  other: 'All ${n} operations',
                ),
          _ => null,
        };
  }
}

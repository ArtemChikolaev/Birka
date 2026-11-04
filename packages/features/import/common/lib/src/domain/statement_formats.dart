import 'package:import_common/src/domain/cell_values.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:import_common/src/domain/statement_table.dart';

/// The formats that Birka knows, in the order the hosts show them.
///
/// They follow what the banks and apps describe of their exports, and each
/// gets checked against a real file before people rely on it. A file that
/// none of them fits still reads: the person names its columns.
const List<StatementFormat> statementFormats = [
  alfa,
  tbank,
  zenmoney,
  wise,
  revolut,
];

/// Alfa-Bank: a workbook of one card or account, and the older CSV with
/// columns of money received and spent.
const alfa = StatementFormat(
  id: 'alfa',
  file: TableFile.xlsx,
  decimalMark: DecimalMark.comma,
  dateOrder: DateOrder.dayMonthYear,
  columns: {
    'дата операции': ColumnRole.date,
    'дата проводки': ColumnRole.skip,
    'описание': ColumnRole.description,
    'описание операции': ColumnRole.description,
    'сумма': ColumnRole.amount,
    'сумма в валюте счета': ColumnRole.amount,
    'приход': ColumnRole.income,
    'расход': ColumnRole.expense,
    'валюта': ColumnRole.currency,
    'категория': ColumnRole.category,
    'номер карты': ColumnRole.card,
    'код mcc': ColumnRole.skip,
    'тип счета': ColumnRole.skip,
    'номер счета': ColumnRole.skip,
    'референс проводки': ColumnRole.skip,
    'код авторизации': ColumnRole.skip,
  },
);

/// T-Bank: a CSV of one card with the categories of the bank. The amount of
/// the payment is in the currency of the card, the amount of the operation in
/// the currency of the shop.
const tbank = StatementFormat(
  id: 'tbank',
  file: TableFile.csv,
  decimalMark: DecimalMark.comma,
  dateOrder: DateOrder.dayMonthYear,
  accepted: {'ok'},
  columns: {
    'дата операции': ColumnRole.date,
    'дата платежа': ColumnRole.skip,
    'номер карты': ColumnRole.card,
    'статус': ColumnRole.status,
    'сумма операции': ColumnRole.skip,
    'валюта операции': ColumnRole.skip,
    'сумма платежа': ColumnRole.amount,
    'валюта платежа': ColumnRole.currency,
    'кэшбэк': ColumnRole.skip,
    'категория': ColumnRole.category,
    'mcc': ColumnRole.skip,
    'описание': ColumnRole.description,
    'бонусы (включая кэшбэк)': ColumnRole.skip,
    'округление на инвесткопилку': ColumnRole.skip,
    'сумма операции с округлением': ColumnRole.skip,
  },
);

/// Zenmoney: a CSV of every account, category and transfer at once. A row
/// spends from one account, receives on one, or both for a transfer.
const zenmoney = StatementFormat(
  id: 'zenmoney',
  file: TableFile.csv,
  columns: {
    'date': ColumnRole.date,
    'categoryname': ColumnRole.category,
    'payee': ColumnRole.description,
    'comment': ColumnRole.note,
    'outcomeaccountname': ColumnRole.expenseAccount,
    'outcome': ColumnRole.expense,
    'outcomecurrencyshorttitle': ColumnRole.expenseCurrency,
    'incomeaccountname': ColumnRole.incomeAccount,
    'income': ColumnRole.income,
    'incomecurrencyshorttitle': ColumnRole.incomeCurrency,
    'createddate': ColumnRole.skip,
    'changeddate': ColumnRole.skip,
    'qrcode': ColumnRole.skip,
  },
);

/// Wise: a statement in CSV, each operation in the currency of its balance.
const wise = StatementFormat(
  id: 'wise',
  file: TableFile.csv,
  decimalMark: DecimalMark.dot,
  dateOrder: DateOrder.dayMonthYear,
  columns: {
    'transferwise id': ColumnRole.skip,
    'date': ColumnRole.date,
    'amount': ColumnRole.amount,
    'currency': ColumnRole.currency,
    'description': ColumnRole.description,
    'payment reference': ColumnRole.note,
    'running balance': ColumnRole.balance,
    'exchange from': ColumnRole.skip,
    'exchange to': ColumnRole.skip,
    'exchange rate': ColumnRole.skip,
    'payer name': ColumnRole.skip,
    'payee name': ColumnRole.skip,
    'payee account number': ColumnRole.skip,
    'merchant': ColumnRole.skip,
    'card last four digits': ColumnRole.card,
    'card holder full name': ColumnRole.skip,
    'attachment': ColumnRole.skip,
    'note': ColumnRole.note,
    'total fees': ColumnRole.skip,
    'exchange to amount': ColumnRole.skip,
  },
);

/// Revolut: a statement in CSV, each operation in its currency and with its
/// fee apart.
const revolut = StatementFormat(
  id: 'revolut',
  file: TableFile.csv,
  decimalMark: DecimalMark.dot,
  accepted: {'completed'},
  columns: {
    'type': ColumnRole.skip,
    'product': ColumnRole.skip,
    'started date': ColumnRole.date,
    'completed date': ColumnRole.skip,
    'description': ColumnRole.description,
    'amount': ColumnRole.amount,
    'fee': ColumnRole.fee,
    'currency': ColumnRole.currency,
    'state': ColumnRole.status,
    'balance': ColumnRole.balance,
  },
);

import 'package:inbox_common/src/domain/transfer_pairs.dart';
import 'package:inbox_common/src/presentation/inbox_cubit.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Why [hint] suggests its category, for people: «так вы отметили его 3 раза
/// в сентябре», «та же сумма каждый месяц с июня», «как «Барбершоп» в
/// августе». A month of another year than [thisYear] says its year.
String hintLabel(CategoryHint hint, {required int thisYear}) {
  final oneMonth =
      hint.first.year == hint.last.year && hint.first.month == hint.last.month;
  return switch (hint.reason) {
    HintReason.sameName => t.inbox.sameName(
      n: hint.count,
      count: formatCount(hint.count),
      when: oneMonth
          ? inMonth(hint.last, thisYear: thisYear)
          : sinceMonth(hint.first, thisYear: thisYear),
    ),
    HintReason.everyMonth => t.inbox.everyMonth(
      since: sinceMonth(hint.first, thisYear: thisYear),
    ),
    HintReason.sameImport => t.inbox.sameImport(name: hint.like ?? ''),
    HintReason.similarName => t.inbox.similarName(
      name: hint.like ?? '',
      when: inMonth(hint.last, thisYear: thisYear),
    ),
  };
}

/// The month of [day] after «в»: «в сентябре», with the year when it is not
/// [thisYear].
String inMonth(CivilDate day, {required int thisYear}) {
  final month = t.overview.monthsIn[day.month - 1];
  return day.year == thisYear ? month : '$month ${day.year}';
}

/// The month of [day] after «с»: «с июня», with the year when it is not
/// [thisYear].
String sinceMonth(CivilDate day, {required int thisYear}) {
  final month = t.inbox.since(month: t.transactions.months[day.month - 1]);
  return day.year == thisYear ? month : '$month ${day.year}';
}

/// What waits, for the line under the title: «15 ждут решения · после
/// импорта Альфа-Банка».
String waitingLabel(InboxState state) {
  final waiting = t.inbox.waiting(
    n: state.count,
    count: formatCount(state.count),
  );
  final latest = state.latestImport;
  if (latest == null) return waiting;
  final bank = t.imports.formatsOf[latest.format ?? ''];
  return [
    waiting,
    if (bank != null)
      t.inbox.afterImport(bank: bank)
    else
      t.inbox.afterFile(name: latest.fileName),
  ].join(' · ');
}

/// The rate of [pair] between two currencies, and that of the Bank of Russia
/// on its day by [rates]: «Курс обмена 80,09 ₽ за 1 $ · ЦБ в тот день
/// 81,20 ₽». A pair in one currency has none.
String? rateLabel(TransferPair pair, RateBook rates) {
  final sent = pair.sent;
  final received = pair.received;
  if (sent.currency == received.currency) return null;
  // Rubles for a unit of the other currency, as the Bank of Russia says it.
  final (base, quote) = sent.currency == Currency.rub
      ? (received, sent)
      : (sent, received);
  final unit = Money(_pow10(base.currency.decimalDigits), base.currency);
  final rate = Money(
    (quote.minorUnits * unit.minorUnits / base.minorUnits).round(),
    quote.currency,
  );
  final bank = rates.convert(unit, quote.currency, on: pair.out.occurredOn);
  return [
    t.inbox.rate(rate: formatMoney(rate), unit: formatMoney(unit)),
    if (bank != null) t.inbox.bankRate(rate: formatMoney(bank)),
  ].join(' · ');
}

int _pow10(int digits) {
  var value = 1;
  for (var i = 0; i < digits; i++) {
    value *= 10;
  }
  return value;
}

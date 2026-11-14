import 'package:meta/meta.dart';

/// A number of a contact, with what the address book calls it, such as
/// «мобильный».
@immutable
final class ContactNumber {
  /// Creates a number.
  const ContactNumber({required this.label, required this.number});

  /// What the address book calls the number, or empty.
  final String label;

  /// The number as the address book keeps it.
  final String number;

  @override
  bool operator ==(Object other) =>
      other is ContactNumber && other.label == label && other.number == number;

  @override
  int get hashCode => Object.hash(label, number);

  @override
  String toString() => 'ContactNumber($label, $number)';
}

/// The contact that the person picked in the window of the phone (ADR 0030).
@immutable
final class PickedContact {
  /// Creates a contact.
  const PickedContact({
    required this.name,
    this.givenName = '',
    this.numbers = const [],
  });

  /// The whole name, as the address book shows it.
  final String name;

  /// The first name, or empty when the contact has none.
  final String givenName;

  /// Its numbers.
  final List<ContactNumber> numbers;

  /// The name that Birka offers: the first name, or else the whole one.
  String get shortName => givenName.trim().isEmpty ? name.trim() : givenName;

  @override
  bool operator ==(Object other) =>
      other is PickedContact &&
      other.name == name &&
      other.givenName == givenName &&
      _same(other.numbers, numbers);

  @override
  int get hashCode => Object.hash(name, givenName, Object.hashAll(numbers));
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// What the phone does for the people of the debts (ADR 0030): it picks a
/// contact in a window of its own, which gives Birka that contact alone, and
/// opens a message that the person sends themselves. The site has none.
abstract interface class PeoplePhone {
  /// Opens the window of the contacts, and gives the contact picked, or
  /// `null` when the person closed it.
  Future<PickedContact?> pickContact();

  /// Opens an SMS to [number] with [text], which the person may change and
  /// sends themselves. Where the phone sends no SMS, it shares the text.
  Future<void> sendSms(String number, String text);

  /// Offers [text] to the other apps of the phone, such as a messenger.
  Future<void> share(String text);
}

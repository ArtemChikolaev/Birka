import 'package:meta/meta.dart';

/// Someone the person lends to or borrows from (ADR 0030): the name Birka
/// shows, who they are, and a number to write to. The debts of one person
/// point at it, whichever way the money went, and wear its name.
@immutable
final class Person {
  /// Creates a person.
  const Person({
    required this.id,
    required this.name,
    this.about = '',
    this.phone,
  });

  /// The id.
  final String id;

  /// The name Birka shows, which the debts of the person wear too.
  final String name;

  /// Who they are, such as «коллега», to tell namesakes apart, or empty.
  final String about;

  /// A number to write to, as the person typed it or a contact gave it, or
  /// `null`.
  final String? phone;

  /// The same person with the given fields changed. [phone] takes a
  /// function, so that it can become `null`.
  Person copyWith({String? name, String? about, String? Function()? phone}) =>
      Person(
        id: id,
        name: name ?? this.name,
        about: about ?? this.about,
        phone: phone == null ? this.phone : phone(),
      );

  @override
  bool operator ==(Object other) =>
      other is Person &&
      other.id == id &&
      other.name == name &&
      other.about == about &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(id, name, about, phone);

  @override
  String toString() => 'Person($name${about.isEmpty ? '' : ' · $about'})';
}

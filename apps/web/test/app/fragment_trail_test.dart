import 'package:birka_web/app/fragment_trail.dart';
import 'package:test/test.dart';

void main() {
  test('a page opened on a link has nothing behind it', () {
    expect(FragmentTrail().leadsBackTo(''), isFalse);
  });

  test('a form opened from the list leads back to it', () {
    final trail = FragmentTrail()..moved(from: '', to: 'new');

    expect(trail.leadsBackTo(''), isTrue);
    expect(trail.leadsBackTo('new'), isFalse);
  });

  test('the card still leads to the list after a form on it has closed', () {
    final trail = FragmentTrail()
      ..moved(from: '', to: 'id')
      ..moved(from: 'id', to: 'edit-id');
    expect(trail.leadsBackTo('id'), isTrue);

    trail.moved(from: 'edit-id', to: 'id');

    expect(trail.leadsBackTo(''), isTrue);
  });

  test('going back all the way leaves nothing behind', () {
    final trail = FragmentTrail()
      ..moved(from: '', to: 'id')
      ..moved(from: 'id', to: '');

    expect(trail.leadsBackTo(''), isFalse);
    expect(trail.leadsBackTo('id'), isFalse);
  });

  test('the forward button adds the step again', () {
    final trail = FragmentTrail()
      ..moved(from: '', to: 'id')
      ..moved(from: 'id', to: '')
      ..moved(from: '', to: 'id');

    expect(trail.leadsBackTo(''), isTrue);
  });
}

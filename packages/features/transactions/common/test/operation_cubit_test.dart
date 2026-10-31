import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  late FakeTransactionsRepository repository;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<OperationCubit> open([String id = 'coffee']) async {
    final cubit = OperationCubit(repository, id);
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  setUp(() {
    repository = FakeTransactionsRepository(
      operations: [testOperation('coffee', amount: rub(-25000))],
    );
  });

  test('shows the operation', () async {
    final card = await open();

    expect(card.state.status, OperationStatus.ready);
    expect(card.state.operation?.id, 'coffee');
  });

  test('follows a change', () async {
    final card = await open();

    repository.operations = [testOperation('coffee', amount: rub(-100))];
    await settle();

    expect(card.state.operation?.amount, rub(-100));
  });

  test('an operation that is not there is gone', () async {
    final card = await open('missing');

    expect(card.state.status, OperationStatus.gone);
  });

  test('a delete leaves it gone', () async {
    final card = await open();

    await card.delete();
    await settle();

    expect(card.state.status, OperationStatus.gone);
    expect(repository.operations, isEmpty);
  });

  test('a failed delete keeps the operation and says so', () async {
    repository.failure = Exception('disk full');
    final card = await open();

    await card.delete();

    expect(card.state.deleteFailed, isTrue);
    expect(card.state.status, OperationStatus.ready);
    expect(card.state.operation?.id, 'coffee');
  });

  test('closing during a delete stays quiet', () async {
    repository.failure = Exception('disk full');
    final card = await open();

    final deleting = card.delete();
    await card.close();

    await expectLater(deleting, completes);
  });

  test('reports a failure and reads again', () async {
    repository.readFailure = Exception('disk');
    final card = await open();
    expect(card.state.status, OperationStatus.failed);

    repository.readFailure = null;
    await card.retry();
    await settle();

    expect(card.state.status, OperationStatus.ready);
  });
}

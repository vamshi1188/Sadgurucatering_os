import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/income/controllers/income_controller.dart';
import 'package:sadguru_catering/features/income/models/income.dart';
import 'package:sadguru_catering/features/income/services/income_service_contract.dart';

class _FakeIncomeService implements IncomeServiceContract {
  _FakeIncomeService(this.financials);

  IncomeFinancials financials;
  bool shouldFail = false;
  int loadCount = 0;
  int createCount = 0;
  int deleteCount = 0;

  @override
  Future<IncomeFinancials> getIncome(int eventId) async {
    loadCount++;
    if (shouldFail) {
      throw const ApiException(message: 'Unable to connect to the server');
    }
    return financials;
  }

  @override
  Future<Income> createIncome({
    required int eventId,
    required String description,
    required String amount,
  }) async {
    createCount++;
    return _income(2, description, amount);
  }

  @override
  Future<void> deleteIncome({
    required int eventId,
    required int incomeId,
  }) async {
    deleteCount++;
  }
}

Income _income(int id, String description, String amount) => Income(
  id: id,
  eventId: 1,
  description: description,
  amount: amount,
  createdAt: DateTime.utc(2026, 9, 3, 10),
);

void main() {
  test('loads canonical records and total', () async {
    final service = _FakeIncomeService(
      IncomeFinancials(
        eventId: 1,
        totalIncome: '50000.00',
        income: [_income(1, 'Advance', '50000.00')],
      ),
    );
    final controller = IncomeController(eventId: 1, service: service);

    await controller.load();

    expect(controller.incomes.single.description, 'Advance');
    expect(controller.totalIncome, '50000.00');
    expect(controller.error, isNull);
  });

  test('maps load error and retry recovers', () async {
    final service = _FakeIncomeService(
      const IncomeFinancials(eventId: 1, totalIncome: '0.00', income: []),
    )..shouldFail = true;
    final controller = IncomeController(eventId: 1, service: service);

    await controller.load();
    expect(controller.error, isNotNull);

    service.shouldFail = false;
    await controller.retry();
    expect(controller.error, isNull);
    expect(service.loadCount, 2);
  });

  test('create and delete use mutations and refresh state', () async {
    final service = _FakeIncomeService(
      const IncomeFinancials(eventId: 1, totalIncome: '0.00', income: []),
    );
    final controller = IncomeController(eventId: 1, service: service);

    expect(
      await controller.createIncome(description: 'Advance', amount: '10.00'),
      isTrue,
    );
    expect(await controller.deleteIncome(2), isTrue);
    expect(service.createCount, 1);
    expect(service.deleteCount, 1);
    expect(service.loadCount, 2);
  });
}

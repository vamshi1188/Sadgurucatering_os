import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/profitability/controllers/profitability_controller.dart';
import 'package:sadguru_catering/features/profitability/models/profitability.dart';
import 'package:sadguru_catering/features/profitability/services/profitability_service_contract.dart';

class _FakeProfitabilityService implements ProfitabilityServiceContract {
  _FakeProfitabilityService(this.profitability);

  Profitability profitability;
  bool shouldFail = false;
  ApiException? failure;
  Completer<Profitability>? completer;
  int getProfitabilityCallCount = 0;

  @override
  Future<Profitability> getProfitability(int eventId) async {
    getProfitabilityCallCount++;
    if (shouldFail) {
      throw failure ??
          const ApiException(message: 'Unable to connect to the server');
    }
    if (completer != null) return completer!.future;
    return profitability;
  }
}

void main() {
  const sampleProfitability = Profitability(
    eventId: 42,
    totalIncome: '1000.00',
    totalExpenses: '250.50',
    netProfit: '749.50',
  );

  test('initial state is unpopulated', () {
    final service = _FakeProfitabilityService(sampleProfitability);
    final controller = ProfitabilityController(eventId: 42, service: service);

    expect(controller.profitability, isNull);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('loads profitability successfully', () async {
    final service = _FakeProfitabilityService(sampleProfitability);
    final controller = ProfitabilityController(eventId: 42, service: service);

    await controller.load();

    expect(controller.profitability, equals(sampleProfitability));
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(service.getProfitabilityCallCount, 1);
  });

  test('exposes loading state until the request completes', () async {
    final service = _FakeProfitabilityService(sampleProfitability)
      ..completer = Completer<Profitability>();
    final controller = ProfitabilityController(eventId: 42, service: service);

    final loading = controller.load();
    expect(controller.isLoading, isTrue);

    service.completer!.complete(sampleProfitability);
    await loading;

    expect(controller.isLoading, isFalse);
    expect(controller.profitability, sampleProfitability);
  });

  test('handles load error and retry recovers', () async {
    final service = _FakeProfitabilityService(sampleProfitability)
      ..shouldFail = true;
    final controller = ProfitabilityController(eventId: 42, service: service);

    await controller.load();

    expect(controller.profitability, isNull);
    expect(controller.error, isNotNull);
    expect(controller.isLoading, isFalse);

    service.shouldFail = false;
    await controller.retry();

    expect(controller.profitability, equals(sampleProfitability));
    expect(controller.error, isNull);
    expect(service.getProfitabilityCallCount, 2);
  });

  test('surfaces contract parsing errors through AppError', () async {
    final service = _FakeProfitabilityService(sampleProfitability)
      ..shouldFail = true
      ..failure = const ApiException(
        code: 'INVALID_FINANCIALS_RESPONSE',
        message: 'Invalid financials response: profit is malformed.',
      );
    final controller = ProfitabilityController(eventId: 42, service: service);

    await controller.load();

    expect(controller.error?.code, 'INVALID_FINANCIALS_RESPONSE');
    expect(controller.error?.message, contains('profit is malformed'));
    expect(controller.error?.retryable, isFalse);
  });

  test('maps API errors through the existing handler', () async {
    final service = _FakeProfitabilityService(sampleProfitability)
      ..shouldFail = true
      ..failure = const ApiException(
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
        statusCode: 401,
      );
    final controller = ProfitabilityController(eventId: 42, service: service);

    await controller.load();

    expect(controller.error?.type.name, 'unauthorized');
    expect(controller.error?.retryable, isFalse);
  });

  test('preserves negative backend profit', () async {
    const negative = Profitability(
      eventId: 42,
      totalIncome: '500.00',
      totalExpenses: '1250.75',
      netProfit: '-750.75',
    );
    final controller = ProfitabilityController(
      eventId: 42,
      service: _FakeProfitabilityService(negative),
    );

    await controller.load();

    expect(controller.profitability?.netProfit, '-750.75');
  });

  test('refresh reloads profitability state', () async {
    final service = _FakeProfitabilityService(sampleProfitability);
    final controller = ProfitabilityController(eventId: 42, service: service);

    await controller.load();
    const updated = Profitability(
      eventId: 42,
      totalIncome: '1200.00',
      totalExpenses: '300.00',
      netProfit: '900.00',
    );
    service.profitability = updated;
    await controller.refresh();

    expect(service.getProfitabilityCallCount, 2);
    expect(controller.profitability, equals(updated));
  });

  test('clearError resets error state', () async {
    final service = _FakeProfitabilityService(sampleProfitability)
      ..shouldFail = true;
    final controller = ProfitabilityController(eventId: 42, service: service);

    await controller.load();
    expect(controller.error, isNotNull);

    controller.clearError();
    expect(controller.error, isNull);
  });
}

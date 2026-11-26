import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/profitability/models/profitability.dart';

Map<String, dynamic> _financials({
  Object? eventId = 42,
  Object? totalIncome = '1000.00',
  Object? totalExpenses = '250.50',
  Object? profit = '800.25',
  Object? income = const [],
  Object? expenses = const [],
}) {
  return {
    'event_id': eventId,
    'total_income': totalIncome,
    'total_expenses': totalExpenses,
    'profit': profit,
    'income': income,
    'expenses': expenses,
  };
}

void main() {
  group('Profitability model', () {
    test('preserves backend totals and profit without recalculating it', () {
      final model = Profitability.fromJson(_financials());

      expect(model.eventId, 42);
      expect(model.totalIncome, '1000.00');
      expect(model.totalExpenses, '250.50');
      expect(model.netProfit, '800.25');
      expect(model.toJson()['profit'], '800.25');
    });

    test('preserves negative profit', () {
      final model = Profitability.fromJson(
        _financials(
          totalIncome: '500.00',
          totalExpenses: '1250.75',
          profit: '-750.75',
        ),
      );

      expect(model.netProfit, '-750.75');
    });

    test('preserves zero financial values', () {
      final model = Profitability.fromJson(
        _financials(totalIncome: '0.00', totalExpenses: '0.00', profit: '0.00'),
      );

      expect(model.totalIncome, '0.00');
      expect(model.totalExpenses, '0.00');
      expect(model.netProfit, '0.00');
    });

    test('accepts empty income and expense arrays', () {
      final model = Profitability.fromJson(
        _financials(income: const [], expenses: const []),
      );

      expect(model.eventId, 42);
    });

    test('rejects missing required fields', () {
      for (final field in [
        'event_id',
        'total_income',
        'total_expenses',
        'profit',
        'income',
        'expenses',
      ]) {
        final json = _financials()..remove(field);

        expect(
          () => Profitability.fromJson(json),
          throwsA(isA<FormatException>()),
          reason: 'Missing $field must be rejected.',
        );
      }
    });

    test('rejects null required fields', () {
      for (final field in [
        'event_id',
        'total_income',
        'total_expenses',
        'profit',
        'income',
        'expenses',
      ]) {
        final json = _financials()..[field] = null;

        expect(
          () => Profitability.fromJson(json),
          throwsA(isA<FormatException>()),
          reason: 'Null $field must be rejected.',
        );
      }
    });

    test('rejects malformed or out-of-range monetary strings', () {
      for (final field in ['total_income', 'total_expenses', 'profit']) {
        for (final value in ['abc', '', '1.234', '10000000000.00']) {
          expect(
            () => Profitability.fromJson(_financials()..[field] = value),
            throwsA(isA<FormatException>()),
            reason: '$field value $value must be rejected.',
          );
        }
      }
    });

    test('rejects negative totals while allowing negative profit', () {
      for (final field in ['total_income', 'total_expenses']) {
        expect(
          () => Profitability.fromJson(_financials()..[field] = '-1.00'),
          throwsA(isA<FormatException>()),
          reason: '$field cannot be negative.',
        );
      }

      expect(
        Profitability.fromJson(_financials(profit: '-1.00')).netProfit,
        '-1.00',
      );
    });

    test('rejects non-string monetary values', () {
      for (final field in ['total_income', 'total_expenses', 'profit']) {
        for (final value in [100.0, null, true]) {
          expect(
            () => Profitability.fromJson(_financials()..[field] = value),
            throwsA(isA<FormatException>()),
            reason: '$field value $value must be rejected.',
          );
        }
      }
    });

    test('rejects non-integer event IDs', () {
      for (final eventId in ['42', 42.5, null, true]) {
        expect(
          () => Profitability.fromJson(_financials(eventId: eventId)),
          throwsA(isA<FormatException>()),
          reason: 'event_id $eventId must be rejected.',
        );
      }
    });

    test('rejects non-array income and expenses', () {
      for (final field in ['income', 'expenses']) {
        for (final value in [null, '[]', {}]) {
          expect(
            () => Profitability.fromJson(_financials()..[field] = value),
            throwsA(isA<FormatException>()),
            reason: '$field value $value must be rejected.',
          );
        }
      }
    });
  });
}

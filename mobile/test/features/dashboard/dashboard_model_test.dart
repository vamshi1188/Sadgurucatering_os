import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_summary.dart';

void main() {
  test('DashboardSummary parses summary and event fields', () {
    final summary = DashboardSummary.fromJson({
      'from': '2026-01-01',
      'to': '2026-01-31',
      'event_count': 1,
      'upcoming_count': 1,
      'running_count': 0,
      'completed_count': 0,
      'total_income': '1000.00',
      'total_expenses': '400.00',
      'profit': '600.00',
      'events': [
        {
          'id': 7,
          'title': 'Wedding',
          'event_date': '2026-01-15',
          'venue': 'Community Hall',
          'guest_count': 120,
          'status': 'upcoming',
          'total_income': '1000.00',
          'total_expenses': '400.00',
          'profit': '600.00',
        },
      ],
    });

    expect(summary.eventCount, 1);
    expect(summary.events.single.title, 'Wedding');
    expect(summary.events.single.guestCount, 120);
  });

  test('DashboardSummary treats a missing events list as empty', () {
    final summary = DashboardSummary.fromJson({
      'from': '2026-01-01',
      'to': '2026-01-31',
      'event_count': 0,
      'upcoming_count': 0,
      'running_count': 0,
      'completed_count': 0,
      'total_income': '0',
      'total_expenses': '0',
      'profit': '0',
    });

    expect(summary.events, isEmpty);
  });
}

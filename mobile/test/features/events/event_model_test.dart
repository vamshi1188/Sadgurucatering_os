import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/events/models/event.dart';
import 'package:sadguru_catering/features/events/models/event_status.dart';

void main() {
  test('Event parses all backend fields', () {
    final event = Event.fromJson({
      'id': 42,
      'title': 'Wedding Reception',
      'event_date': '2026-09-05',
      'venue': 'Sadguru Function Hall',
      'guest_count': 500,
      'status': 'upcoming',
      'created_at': '2026-09-03T10:00:00Z',
      'updated_at': '2026-09-03T10:00:00Z',
    });

    expect(event.id, 42);
    expect(event.title, 'Wedding Reception');
    expect(event.eventDate, '2026-09-05');
    expect(event.venue, 'Sadguru Function Hall');
    expect(event.guestCount, 500);
    expect(event.status, EventStatus.upcoming);
    expect(event.createdAt, DateTime.parse('2026-09-03T10:00:00Z'));
    expect(event.updatedAt, DateTime.parse('2026-09-03T10:00:00Z'));
  });

  test('EventStatus converts to and from backend values', () {
    expect(EventStatus.upcoming.value, 'upcoming');
    expect(EventStatus.running.value, 'running');
    expect(EventStatus.completed.value, 'completed');

    expect(EventStatus.fromValue('upcoming'), EventStatus.upcoming);
    expect(EventStatus.fromValue('running'), EventStatus.running);
    expect(EventStatus.fromValue('completed'), EventStatus.completed);
  });

  test('EventStatus rejects unknown backend values', () {
    expect(() => EventStatus.fromValue('cancelled'), throwsArgumentError);
  });
}

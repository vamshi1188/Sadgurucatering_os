import '../models/event.dart';
import '../models/event_status.dart';

abstract interface class EventServiceContract {
  Future<List<Event>> getEvents();

  Future<Event> getEvent(int id);

  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  });

  Future<Event> updateStatus(int id, EventStatus status);

  Future<void> deleteEvent(int id);
}

import '../../../core/network/api_client.dart';
import '../models/event.dart';
import '../models/event_status.dart';
import 'event_service_contract.dart';

class EventService implements EventServiceContract {
  const EventService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Event>> getEvents() async {
    final response = await _apiClient.get<List<Event>>(
      '/events',
      parser: (data) {
        final items = data as List;

        return items
            .map(
              (item) => Event.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      },
    );

    return response.data;
  }

  @override
  Future<Event> getEvent(int id) async {
    final response = await _apiClient.get<Event>(
      '/events/$id',
      parser: (data) {
        return Event.fromJson(Map<String, dynamic>.from(data as Map));
      },
    );

    return response.data;
  }

  @override
  Future<Event> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) async {
    final response = await _apiClient.post<Event>(
      '/events',
      data: {
        'title': title,
        'event_date': eventDate,
        'venue': venue,
        'guest_count': guestCount,
      },
      parser: (data) {
        return Event.fromJson(Map<String, dynamic>.from(data as Map));
      },
    );

    return response.data;
  }

  @override
  Future<Event> updateStatus(int id, EventStatus status) async {
    final response = await _apiClient.patch<Event>(
      '/events/$id/status',
      data: {'status': status.value},
      parser: (data) {
        return Event.fromJson(Map<String, dynamic>.from(data as Map));
      },
    );

    return response.data;
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _apiClient.delete('/events/$id');
  }
}

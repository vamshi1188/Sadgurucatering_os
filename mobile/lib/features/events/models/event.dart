import 'event_status.dart';

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.venue,
    required this.guestCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String eventDate;
  final String venue;
  final int guestCount;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event copyWith({
    int? id,
    String? title,
    String? eventDate,
    String? venue,
    int? guestCount,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      venue: venue ?? this.venue,
      guestCount: guestCount ?? this.guestCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      eventDate: json['event_date'] as String,
      venue: json['venue'] as String,
      guestCount: (json['guest_count'] as num).toInt(),
      status: EventStatus.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

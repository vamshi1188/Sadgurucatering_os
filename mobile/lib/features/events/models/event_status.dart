enum EventStatus {
  upcoming,
  running,
  completed;

  String get value {
    switch (this) {
      case EventStatus.upcoming:
        return 'upcoming';
      case EventStatus.running:
        return 'running';
      case EventStatus.completed:
        return 'completed';
    }
  }

  static EventStatus fromValue(String value) {
    switch (value) {
      case 'upcoming':
        return EventStatus.upcoming;
      case 'running':
        return EventStatus.running;
      case 'completed':
        return EventStatus.completed;
      default:
        throw ArgumentError('Unknown event status: $value');
    }
  }
}

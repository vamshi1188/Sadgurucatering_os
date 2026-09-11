class DashboardEvent {
  const DashboardEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.venue,
    required this.guestCount,
    required this.status,
    required this.totalIncome,
    required this.totalExpenses,
    required this.profit,
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      eventDate: json['event_date'] as String,
      venue: json['venue'] as String,
      guestCount: (json['guest_count'] as num).toInt(),
      status: json['status'] as String,
      totalIncome: json['total_income'] as String,
      totalExpenses: json['total_expenses'] as String,
      profit: json['profit'] as String,
    );
  }

  final int id;
  final String title;
  final String eventDate;
  final String venue;
  final int guestCount;
  final String status;
  final String totalIncome;
  final String totalExpenses;
  final String profit;
}

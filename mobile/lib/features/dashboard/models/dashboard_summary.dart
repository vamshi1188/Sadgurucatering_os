import 'dashboard_event.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.from,
    required this.to,
    required this.eventCount,
    required this.upcomingCount,
    required this.runningCount,
    required this.completedCount,
    required this.totalIncome,
    required this.totalExpenses,
    required this.profit,
    required this.events,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'];

    return DashboardSummary(
      from: json['from'] as String,
      to: json['to'] as String,
      eventCount: (json['event_count'] as num).toInt(),
      upcomingCount: (json['upcoming_count'] as num).toInt(),
      runningCount: (json['running_count'] as num).toInt(),
      completedCount: (json['completed_count'] as num).toInt(),
      totalIncome: json['total_income'] as String,
      totalExpenses: json['total_expenses'] as String,
      profit: json['profit'] as String,
      events: eventsJson is List
          ? eventsJson
                .map(
                  (event) => DashboardEvent.fromJson(
                    Map<String, dynamic>.from(event as Map),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final String from;
  final String to;
  final int eventCount;
  final int upcomingCount;
  final int runningCount;
  final int completedCount;
  final String totalIncome;
  final String totalExpenses;
  final String profit;
  final List<DashboardEvent> events;
}

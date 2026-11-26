class Income {
  const Income({
    required this.id,
    required this.eventId,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  final int id;
  final int eventId;
  final String description;
  final String amount;
  final DateTime createdAt;

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: (json['id'] as num).toInt(),
      eventId: (json['event_id'] as num).toInt(),
      description: json['description'] as String,
      amount: json['amount'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'description': description,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class IncomeFinancials {
  const IncomeFinancials({
    required this.eventId,
    required this.totalIncome,
    required this.income,
  });

  final int eventId;
  final String totalIncome;
  final List<Income> income;

  factory IncomeFinancials.fromJson(Map<String, dynamic> json) {
    final records = json['income'] as List;

    return IncomeFinancials(
      eventId: (json['event_id'] as num).toInt(),
      totalIncome: json['total_income'] as String,
      income: records
          .map(
            (item) => Income.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }
}

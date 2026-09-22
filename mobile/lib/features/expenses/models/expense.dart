class Expense {
  const Expense({
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

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
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

class ExpenseFinancials {
  const ExpenseFinancials({
    required this.eventId,
    required this.totalExpenses,
    required this.expenses,
  });

  final int eventId;
  final String totalExpenses;
  final List<Expense> expenses;

  factory ExpenseFinancials.fromJson(Map<String, dynamic> json) {
    final records = json['expenses'] as List;

    return ExpenseFinancials(
      eventId: (json['event_id'] as num).toInt(),
      totalExpenses: json['total_expenses'] as String,
      expenses: records
          .map(
            (item) => Expense.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }
}

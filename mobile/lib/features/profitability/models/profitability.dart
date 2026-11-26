class Profitability {
  const Profitability({
    required this.eventId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
  });

  static final RegExp _moneyPattern = RegExp(r'^-?(?:0|[1-9]\d{0,9})\.\d{2}$');

  final int eventId;
  final String totalIncome;
  final String totalExpenses;
  final String netProfit;

  factory Profitability.fromJson(Map<String, dynamic> json) {
    final eventId = json['event_id'];
    if (eventId is! int) {
      throw const FormatException(
        'Invalid financials response: event_id must be an integer.',
      );
    }

    final totalIncome = _requiredMoney(json, 'total_income');
    final totalExpenses = _requiredMoney(json, 'total_expenses');
    final profit = _requiredMoney(json, 'profit', allowNegative: true);

    if (json['income'] is! List) {
      throw const FormatException(
        'Invalid financials response: income must be an array.',
      );
    }
    if (json['expenses'] is! List) {
      throw const FormatException(
        'Invalid financials response: expenses must be an array.',
      );
    }

    return Profitability(
      eventId: eventId,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: profit,
    );
  }

  static String _requiredMoney(
    Map<String, dynamic> json,
    String field, {
    bool allowNegative = false,
  }) {
    final value = json[field];
    if (value is! String ||
        !_moneyPattern.hasMatch(value) ||
        (!allowNegative && value.startsWith('-'))) {
      throw FormatException(
        'Invalid financials response: $field must be a valid monetary string.',
      );
    }

    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'total_income': totalIncome,
      'total_expenses': totalExpenses,
      'profit': netProfit,
    };
  }
}

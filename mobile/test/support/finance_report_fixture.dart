Map<String, dynamic> financeReportJson({
  String period = 'this_month',
  String totalIncome = '50000.00',
  String totalExpenses = '18000.00',
  String profit = '32000.00',
  List<dynamic>? events,
  List<dynamic>? transactions,
  int page = 1,
  int pageSize = 20,
  int total = 0,
  int totalPages = 0,
}) => {
  'period': period,
  'from': '2026-09-01',
  'to': '2026-09-30',
  'total_income': totalIncome,
  'total_expenses': totalExpenses,
  'profit': profit,
  'events': events ?? [],
  'transactions': transactions ?? [],
  'pagination': {
    'page': page,
    'page_size': pageSize,
    'total': total,
    'total_pages': totalPages,
  },
};

Map<String, dynamic> financeEventJson({
  String income = '50000.00',
  String expenses = '18000.00',
  String profit = '32000.00',
}) => {
  'event_id': 7,
  'title': 'Wedding Reception',
  'event_date': '2026-09-20',
  'status': 'completed',
  'total_income': income,
  'total_expenses': expenses,
  'profit': profit,
};

Map<String, dynamic> financeTransactionJson({
  String type = 'income',
  int id = 1,
  String amount = '50000.00',
}) => {
  'type': type,
  'id': id,
  'event_id': 7,
  'event_title': 'Wedding Reception',
  'description': 'Catering advance',
  'amount': amount,
  'created_at': '2026-09-03 10:15:00+00',
};

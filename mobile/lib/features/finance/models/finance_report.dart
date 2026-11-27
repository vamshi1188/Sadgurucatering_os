final RegExp _financeMoneyPattern = RegExp(r'^-?(?:0|[1-9]\d*)\.\d{2}$');

class FinanceReport {
  const FinanceReport({
    required this.period,
    required this.from,
    required this.to,
    required this.totalIncome,
    required this.totalExpenses,
    required this.profit,
    required this.events,
    required this.transactions,
    required this.pagination,
  });

  factory FinanceReport.fromJson(Map<String, dynamic> json) {
    final period = _requiredString(json, 'period');
    if (!const {
      'today',
      'this_month',
      'last_30_days',
      'custom',
      'all_time',
    }.contains(period)) {
      throw const FormatException(
        'Invalid finance report response: period is unsupported.',
      );
    }
    final eventsJson = json['events'];
    final transactionsJson = json['transactions'];
    if (eventsJson is! List || transactionsJson is! List) {
      throw const FormatException(
        'Invalid finance report response: events and transactions must be arrays.',
      );
    }

    final paginationJson = json['pagination'];
    if (paginationJson is! Map) {
      throw const FormatException(
        'Invalid finance report response: pagination must be an object.',
      );
    }
    final paginationMap = Map<String, dynamic>.from(paginationJson);

    return FinanceReport(
      period: period,
      from: _optionalString(json, 'from'),
      to: _optionalString(json, 'to'),
      totalIncome: _requiredMoney(json, 'total_income'),
      totalExpenses: _requiredMoney(json, 'total_expenses'),
      profit: _requiredMoney(json, 'profit'),
      events: eventsJson
          .map((event) => FinanceEvent.fromJson(_asMap(event, 'events')))
          .toList(growable: false),
      transactions: transactionsJson
          .map(
            (transaction) => FinanceTransaction.fromJson(
              _asMap(transaction, 'transactions'),
            ),
          )
          .toList(growable: false),
      pagination: FinancePagination.fromJson(paginationMap),
    );
  }

  final String period;
  final String? from;
  final String? to;
  final String totalIncome;
  final String totalExpenses;
  final String profit;
  final List<FinanceEvent> events;
  final List<FinanceTransaction> transactions;
  final FinancePagination pagination;

  static Map<String, dynamic> _asMap(dynamic value, String field) {
    if (value is! Map) {
      throw FormatException(
        'Invalid finance report response: each $field item must be an object.',
      );
    }
    return Map<String, dynamic>.from(value);
  }

  static String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Invalid finance report response: $field must be a non-empty string.',
      );
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException(
        'Invalid finance report response: $field must be a string.',
      );
    }
    return value;
  }

  static String _requiredMoney(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || !_financeMoneyPattern.hasMatch(value)) {
      throw FormatException(
        'Invalid finance report response: $field must be a decimal string.',
      );
    }
    return value;
  }
}

class FinanceEvent {
  const FinanceEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.status,
    required this.totalIncome,
    required this.totalExpenses,
    required this.profit,
  });

  factory FinanceEvent.fromJson(Map<String, dynamic> json) => FinanceEvent(
    id: _requiredInt(json, 'event_id'),
    title: _requiredString(json, 'title'),
    eventDate: _requiredString(json, 'event_date'),
    status: _requiredString(json, 'status'),
    totalIncome: _requiredMoney(json, 'total_income'),
    totalExpenses: _requiredMoney(json, 'total_expenses'),
    profit: _requiredMoney(json, 'profit'),
  );

  final int id;
  final String title;
  final String eventDate;
  final String status;
  final String totalIncome;
  final String totalExpenses;
  final String profit;
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.type,
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    final type = _requiredString(json, 'type');
    if (type != 'income' && type != 'expense') {
      throw const FormatException(
        'Invalid finance report response: transaction type must be income or expense.',
      );
    }
    final amount = _requiredMoney(json, 'amount');
    if (amount.startsWith('-')) {
      throw const FormatException(
        'Invalid finance report response: transaction amount cannot be negative.',
      );
    }
    return FinanceTransaction(
      type: type,
      id: _requiredInt(json, 'id'),
      eventId: _requiredInt(json, 'event_id'),
      eventTitle: _requiredString(json, 'event_title'),
      description: _requiredString(json, 'description'),
      amount: amount,
      createdAt: _requiredString(json, 'created_at'),
    );
  }

  final String type;
  final int id;
  final int eventId;
  final String eventTitle;
  final String description;
  final String amount;
  final String createdAt;
}

class FinancePagination {
  const FinancePagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory FinancePagination.fromJson(Map<String, dynamic> json) =>
      _paginationFromJson(json);

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}

FinancePagination _paginationFromJson(Map<String, dynamic> json) {
  final pagination = FinancePagination(
    page: _requiredInt(json, 'page'),
    pageSize: _requiredInt(json, 'page_size'),
    total: _requiredInt(json, 'total'),
    totalPages: _requiredInt(json, 'total_pages'),
  );
  if (pagination.page < 1 ||
      pagination.pageSize < 1 ||
      pagination.total < 0 ||
      pagination.totalPages < 0) {
    throw const FormatException(
      'Invalid finance report response: pagination values are out of range.',
    );
  }
  return pagination;
}

int _requiredInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! int) {
    throw FormatException(
      'Invalid finance report response: $field must be an integer.',
    );
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.isEmpty) {
    throw FormatException(
      'Invalid finance report response: $field must be a non-empty string.',
    );
  }
  return value;
}

String _requiredMoney(Map<String, dynamic> json, String field) {
  return FinanceReport._requiredMoney(json, field);
}

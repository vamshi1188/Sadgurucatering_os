enum FinancePeriod {
  today('today'),
  thisMonth('this_month'),
  last30Days('last_30_days'),
  custom('custom'),
  allTime('all_time');

  const FinancePeriod(this.apiValue);

  final String apiValue;
}

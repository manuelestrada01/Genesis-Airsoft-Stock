import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(
  locale: 'es_AR',
  symbol: '\$',
  decimalDigits: 0,
);

String formatCurrency(double value) => _formatter.format(value);

import 'package:intl/intl.dart';

final _dateFormatter = DateFormat('dd/MMM/yy HH:mm', 'es_AR');
final _shortDateFormatter = DateFormat('dd/MM/yyyy', 'es_AR');

String formatDate(DateTime date) => _dateFormatter.format(date);
String formatShortDate(DateTime date) => _shortDateFormatter.format(date);

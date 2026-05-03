import 'package:intl/intl.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String formatCurrency(dynamic value) {
  final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
  return _fmt.format(n);
}

String formatDate(String? isoDate) {
  if (isoDate == null) return '—';
  try {
    final d = DateTime.parse(isoDate);
    return '${_p(d.day)}/${_p(d.month)}/${d.year}';
  } catch (_) {
    return isoDate;
  }
}

String formatShortDate(String? isoDate) {
  if (isoDate == null) return '—';
  try {
    final d = DateTime.parse(isoDate);
    return '${_p(d.day)}/${_p(d.month)}';
  } catch (_) {
    return isoDate;
  }
}

String formatMonth(DateTime dt) {
  const meses = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  return '${meses[dt.month]}/${dt.year}';
}

String toIso(DateTime dt) =>
    '${dt.year}-${_p(dt.month)}-${_p(dt.day)}';

String _p(int n) => n.toString().padLeft(2, '0');

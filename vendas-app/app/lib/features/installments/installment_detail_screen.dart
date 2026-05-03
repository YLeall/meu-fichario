import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final String installmentId;
  const InstallmentDetailScreen({super.key, required this.installmentId});

  @override
  State<InstallmentDetailScreen> createState() => _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiClient.get('/installments?id=${widget.installmentId}');
      if (list is List && list.isNotEmpty) setState(() => _data = list[0]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final d = _data ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Parcela')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Parcela',         '${d['numero_parcela']}/${d['total_parcelas']}'),
          _row('Valor',           formatCurrency(d['valor'])),
          _row('Vencimento',      formatDate(d['data_vencimento']?.toString())),
          _row('Status',          d['status'] ?? ''),
          if (d['data_pagamento'] != null)
            _row('Pago em', formatDate(d['data_pagamento']?.toString())),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: cinzaMuted)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class UltimasVendasCard extends StatelessWidget {
  final List<dynamic> vendas;
  const UltimasVendasCard({super.key, required this.vendas});

  @override
  Widget build(BuildContext context) {
    if (vendas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nenhuma venda ainda.', style: TextStyle(color: cinzaMuted)),
      );
    }

    return Column(
      children: vendas.map((v) {
        final status = v['status'] as String? ?? '';
        final color  = _statusColor(status);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            onTap: () => context.push('/sales/${v['id']}'),
            title: Text(v['customer_nome'] ?? v['customer_id'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${formatDate(v['data_venda']?.toString())} · ${formatCurrency(v['total_bruto'])}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(status),
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'quitado'  => verdeMsgo,
    'atrasado' => vermelhoSuave,
    _          => amareloAlerta,
  };

  String _statusLabel(String s) => switch (s) {
    'quitado'  => 'Quitado',
    'atrasado' => 'Atrasado',
    _          => 'Em dia',
  };
}

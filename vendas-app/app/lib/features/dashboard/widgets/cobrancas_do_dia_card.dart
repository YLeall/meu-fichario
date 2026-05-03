import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';

class CobrancasDoDiaCard extends StatelessWidget {
  final List<dynamic> cobrancas;
  final VoidCallback onRefresh;

  const CobrancasDoDiaCard({super.key, required this.cobrancas, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (cobrancas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nenhuma cobrança para hoje 🎉', style: TextStyle(color: cinzaMuted)),
      );
    }

    return Column(
      children: cobrancas.map((c) => _CobrancaItem(c: c, onRefresh: onRefresh)).toList(),
    );
  }
}

class _CobrancaItem extends StatelessWidget {
  final Map<String, dynamic> c;
  final VoidCallback onRefresh;

  const _CobrancaItem({required this.c, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final dias   = c['dias_atraso'] as int? ?? 0;
    final color  = dias > 0 ? vermelhoSuave : amareloAlerta;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(dias > 0 ? Icons.warning_amber_rounded : Icons.access_time, color: color),
        ),
        title:    Text(c['customer_nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${c['numero_parcela']}/${c['total_parcelas']} · ${formatCurrency(c['valor'])} · vence ${formatDate(c['data_vencimento'])}'
          '${dias > 0 ? ' · $dias dia(s) de atraso' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat, color: verdeMsgo),
          onPressed: () async {
            await abrirWhatsApp(
              nome:          c['customer_nome'] ?? '',
              telefone:      c['customer_tel'] ?? '',
              numeroParcela: c['numero_parcela'] as int,
              totalParcelas: c['total_parcelas'] as int,
              valor:         (c['valor'] as num).toDouble(),
              dataVencimento: c['data_vencimento'] as String,
              diasAtraso:    dias,
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart' show formatDate, toIso;
import '../../core/utils/whatsapp_helper.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Map<String, dynamic>? _sale;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/sales/${widget.saleId}');
      setState(() => _sale = data as Map<String, dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsPaid(Map<String, dynamic> installment) async {
    DateTime selectedDate = DateTime.now();
    final obs = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context:   context,
      isScrollControlled: true,
      builder:   (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirmar pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Parcela ${installment['numero_parcela']}/${installment['total_parcelas']} · ${formatCurrency(installment['valor'])}'),
              const SizedBox(height: 16),
              StatefulBuilder(builder: (ctx, setS) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do pagamento'),
                subtitle: Text(formatDate(selectedDate.toIso8601String().substring(0, 10))),
                trailing: const Icon(Icons.calendar_today_outlined, color: terracota),
                onTap: () async {
                  final d = await showDatePicker(
                    context:     ctx,
                    initialDate: selectedDate,
                    firstDate:   DateTime(2020),
                    lastDate:    DateTime.now(),
                  );
                  if (d != null) setS(() => selectedDate = d);
                },
              )),
              TextField(
                controller: obs,
                decoration: const InputDecoration(labelText: 'Observação (opcional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar pagamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.post('/installments/${installment['id']}/pay', {
          'data_pagamento': toIso(selectedDate),
          'observacoes':    obs.text.isEmpty ? null : obs.text,
        });
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: vermelhoSuave),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final sale         = _sale!;
    final items        = (sale['items'] as List<dynamic>?) ?? [];
    final installments = (sale['installments'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Venda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumo da venda
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Data da venda',  formatDate(sale['data_venda']?.toString())),
                  _row('Forma',          sale['forma_pagamento'] == 'pix' ? 'PIX' : 'Parcelado'),
                  _row('Total bruto',    formatCurrency(sale['total_bruto'])),
                  if ((sale['entrada_valor'] as num? ?? 0) > 0)
                    _row('Entrada',      formatCurrency(sale['entrada_valor'])),
                  _row('Total parcelado', formatCurrency(sale['total_parcelado'])),
                  _row('Status',         sale['status'] ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Itens
          const Text('Itens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: Text(item['descricao_livre'] ?? 'Produto')),
                Text('${item['quantidade']}x ${formatCurrency(item['preco_unitario'])} = ${formatCurrency(item['subtotal'])}',
                    style: const TextStyle(color: cinzaTexto)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          // Parcelas
          const Text('Parcelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...installments.map((p) => _InstallmentTile(
            installment: p,
            onPay:       () => _markAsPaid(p),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: cinzaMuted)),
        Text(value,  style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _InstallmentTile extends StatelessWidget {
  final Map<String, dynamic> installment;
  final VoidCallback onPay;

  const _InstallmentTile({required this.installment, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final status = installment['status'] as String? ?? '';
    final color  = _statusColor(status);
    final icon   = _statusIcon(status);
    final isPaid = status == 'pago';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title:   Text(
          '${installment['numero_parcela']}/${installment['total_parcelas']} · ${formatCurrency(installment['valor'])}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isPaid
              ? 'Pago em ${formatDate(installment['data_pagamento']?.toString())}'
              : 'Vence: ${formatDate(installment['data_vencimento']?.toString())}',
        ),
        trailing: isPaid
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon:      const Icon(Icons.chat, color: verdeMsgo),
                    tooltip:   'WhatsApp',
                    onPressed: () async {
                      final today = DateTime.now();
                      final venc  = DateTime.parse(installment['data_vencimento']);
                      await abrirWhatsApp(
                        nome:          '',
                        telefone:      '',
                        numeroParcela: installment['numero_parcela'] as int,
                        totalParcelas: installment['total_parcelas'] as int,
                        valor:         (installment['valor'] as num).toDouble(),
                        dataVencimento: installment['data_vencimento'],
                        diasAtraso:    today.difference(venc).inDays.clamp(0, 9999),
                      );
                    },
                  ),
                  IconButton(
                    icon:      const Icon(Icons.check_circle_outline, color: verdeMsgo),
                    tooltip:   'Marcar como pago',
                    onPressed: onPay,
                  ),
                ],
              ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pago'     => verdeMsgo,
    'atrasado' => vermelhoSuave,
    _          => amareloAlerta,
  };

  IconData _statusIcon(String s) => switch (s) {
    'pago'     => Icons.check_circle,
    'atrasado' => Icons.cancel,
    _          => Icons.radio_button_unchecked,
  };
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart' show formatDate;

class CustomerDetailScreen extends StatefulWidget {
  final String id;
  const CustomerDetailScreen({super.key, required this.id});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Map<String, dynamic>? _customer;
  Map<String, dynamic>? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/customers/${widget.id}'),
        ApiClient.get('/customers/${widget.id}/balance'),
      ]);
      setState(() {
        _customer = results[0] as Map<String, dynamic>;
        _balance  = results[1] as Map<String, dynamic>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final c     = _customer!;
    final nome  = c['nome'] as String? ?? '';
    final sales = (c['sales'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/customers/${widget.id}/edit').then((_) => _load()),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header
          Container(
            color:   terracota.withOpacity(0.08),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: terracota.withOpacity(0.2),
                  child: Text(nome[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: terracota, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('tel:${c['telefone']}')),
                        child: Text(c['telefone'] ?? '',
                            style: const TextStyle(color: terracota, decoration: TextDecoration.underline)),
                      ),
                      if (c['endereco'] != null)
                        Text(c['endereco'], style: const TextStyle(color: cinzaMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Saldo devedor
          if (_balance != null)
            Container(
              margin:  const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        vermelhoSuave.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: vermelhoSuave.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo devedor total', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    formatCurrency(_balance!['total_em_aberto']),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vermelhoSuave),
                  ),
                ],
              ),
            ),
          // Observações
          if (c['observacoes'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.note_outlined, color: cinzaMuted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c['observacoes'], style: const TextStyle(color: cinzaTexto))),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Compras
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Compras (${sales.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon:  const Icon(Icons.add, size: 18),
                  label: const Text('Nova venda'),
                  onPressed: () => context.push('/sales/new'),
                  style: TextButton.styleFrom(foregroundColor: terracota),
                ),
              ],
            ),
          ),
          ...sales.map((s) => _SaleCard(sale: s)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// Removed local formatDate — use the one from date_formatter.dart

class _SaleCard extends StatelessWidget {
  final Map<String, dynamic> sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final status      = sale['status'] as String? ?? '';
    final installments = (sale['installments'] as List<dynamic>?) ?? [];
    final pagas        = installments.where((p) => p['status'] == 'pago').length;
    final total        = installments.length;
    final color        = _statusColor(status);

    return Card(
      child: InkWell(
        onTap:        () => context.push('/sales/${sale['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDate(sale['data_venda']?.toString()),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  _badge(status, color),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatCurrency(sale['total_bruto']),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$pagas de $total parcelas pagas', style: const TextStyle(color: cinzaMuted, fontSize: 12)),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:            total > 0 ? pagas / total : 0,
                  backgroundColor:  Colors.grey.shade200,
                  valueColor:       AlwaysStoppedAnimation(color),
                  borderRadius:     BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'quitado'  => verdeMsgo,
    'atrasado' => vermelhoSuave,
    _          => amareloAlerta,
  };

  Widget _badge(String status, Color color) {
    final label = switch (status) {
      'quitado'  => 'Quitado',
      'atrasado' => 'Atrasado',
      _          => 'Em dia',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}


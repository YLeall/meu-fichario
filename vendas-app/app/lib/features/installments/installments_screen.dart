import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/whatsapp_helper.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = ['Hoje', 'Vencidas', 'Próx. 7 dias', 'Todas'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcelas'),
        bottom: TabBar(
          controller:        _tab,
          isScrollable:      true,
          labelColor:        Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor:    Colors.white,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _InstallmentsList(filter: 'today'),
          _InstallmentsList(filter: 'atrasado'),
          _InstallmentsList(filter: 'next7'),
          _InstallmentsList(filter: 'all'),
        ],
      ),
    );
  }
}

class _InstallmentsList extends StatefulWidget {
  final String filter;
  const _InstallmentsList({required this.filter});

  @override
  State<_InstallmentsList> createState() => _InstallmentsListState();
}

class _InstallmentsListState extends State<_InstallmentsList> with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final hoje = DateTime.now();
      String path;
      switch (widget.filter) {
        case 'today':
          path = '/installments?status=pendente&data_ini=${toIso(hoje)}&data_fim=${toIso(hoje)}';
        case 'atrasado':
          path = '/installments?status=atrasado';
        case 'next7':
          final fim = hoje.add(const Duration(days: 7));
          path = '/installments?status=pendente&data_ini=${toIso(hoje)}&data_fim=${toIso(fim)}';
        default:
          path = '/installments';
      }
      final data = await ApiClient.get(path);
      if (mounted) setState(() => _items = data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay(Map<String, dynamic> p) async {
    await ApiClient.post('/installments/${p['id']}/pay', {
      'data_pagamento': toIso(DateTime.now()),
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 72,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('Nenhuma parcela aqui.', style: TextStyle(color: cinzaMuted)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) => _InstallmentCard(item: _items[i], onPay: () => _pay(_items[i])),
      ),
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onPay;
  const _InstallmentCard({required this.item, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final sale     = (item['sales'] as Map?)  ?? {};
    final customer = (sale['customers'] as Map?) ?? {};
    final status   = item['status'] as String? ?? '';
    final venc     = DateTime.tryParse(item['data_vencimento'] ?? '') ?? DateTime.now();
    final dias     = DateTime.now().difference(venc).inDays.clamp(0, 9999);
    final color    = status == 'atrasado' ? vermelhoSuave : amareloAlerta;
    final isPaid   = status == 'pago';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(isPaid ? Icons.check_circle : Icons.receipt_outlined, color: color, size: 20),
        ),
        title:    Text(customer['nome'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${item['numero_parcela']}/${item['total_parcelas']} · ${formatCurrency(item['valor'])} · ${formatDate(item['data_vencimento'])}'
          '${dias > 0 && !isPaid ? ' ($dias dias)' : ''}',
        ),
        trailing: isPaid
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat, color: verdeMsgo),
                    onPressed: () => abrirWhatsApp(
                      nome:          customer['nome'] ?? '',
                      telefone:      customer['telefone'] ?? '',
                      numeroParcela: item['numero_parcela'] as int,
                      totalParcelas: item['total_parcelas'] as int,
                      valor:         (item['valor'] as num).toDouble(),
                      dataVencimento: item['data_vencimento'],
                      diasAtraso:    dias,
                    ),
                  ),
                  IconButton(
                    icon:      const Icon(Icons.check_circle_outline, color: verdeMsgo),
                    onPressed: onPay,
                  ),
                ],
              ),
      ),
    );
  }
}

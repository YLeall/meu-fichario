import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';
import 'widgets/metric_card.dart';
import 'widgets/cobrancas_do_dia_card.dart';
import 'widgets/ultimas_vendas_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _metrics;
  List<dynamic> _cobrancas = [];
  List<dynamic> _vendas    = [];
  bool _loading            = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/dashboard/metrics'),
        ApiClient.get('/dashboard/today'),
        ApiClient.get('/sales?limit=5'),
      ]);
      setState(() {
        _metrics  = results[0] as Map<String, dynamic>;
        _cobrancas = results[1] as List<dynamic>;
        _vendas   = results[2] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: vermelhoSuave),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading ? _buildShimmer() : _buildContent(),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor:     Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          6,
          (_) => Container(
            margin:       const EdgeInsets.only(bottom: 12),
            height:       80,
            decoration:   BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final m = _metrics ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount:   2,
          shrinkWrap:       true,
          physics:          const NeverScrollableScrollPhysics(),
          mainAxisSpacing:  12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            MetricCard(
              label: 'Faturado no mês',
              value: formatCurrency(m['total_faturado_mes'] ?? 0),
              icon:  Icons.monetization_on_outlined,
              color: verdeMsgo,
            ),
            MetricCard(
              label: 'Recebido no mês',
              value: formatCurrency(m['total_recebido_mes'] ?? 0),
              icon:  Icons.download_outlined,
              color: terracota,
            ),
            MetricCard(
              label: 'Parcelas vencidas',
              value: '${m['parcelas_vencidas'] ?? 0}',
              icon:  Icons.warning_amber_rounded,
              color: vermelhoSuave,
            ),
            MetricCard(
              label: 'Vencem hoje',
              value: '${m['parcelas_vencendo_hoje'] ?? 0}',
              icon:  Icons.today,
              color: amareloAlerta,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionHeader('Cobranças de hoje', Icons.notifications_outlined),
        CobrancasDoDiaCard(cobrancas: _cobrancas, onRefresh: _load),
        const SizedBox(height: 24),
        _sectionHeader('Últimas vendas', Icons.receipt_long_outlined),
        UltimasVendasCard(vendas: _vendas),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: terracota),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

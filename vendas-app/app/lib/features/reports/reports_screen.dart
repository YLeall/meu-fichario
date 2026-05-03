import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _periodo = 'mes';
  Map<String, dynamic>? _metrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final metrics = await ApiClient.get('/dashboard/metrics');
      setState(() {
        _metrics = metrics as Map<String, dynamic>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: terracota))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seletor de período
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _periodChip('mes',   'Este mês'),
                      _periodChip('3m',    'Últimos 3 meses'),
                      _periodChip('ano',   'Este ano'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Métricas
                if (_metrics != null) ...[
                  GridView.count(
                    crossAxisCount:   2,
                    shrinkWrap:       true,
                    physics:          const NeverScrollableScrollPhysics(),
                    mainAxisSpacing:  12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _MetricCard('Total Faturado',  formatCurrency(_metrics!['total_faturado_mes']), Icons.trending_up, verdeMsgo),
                      _MetricCard('Total Recebido',  formatCurrency(_metrics!['total_recebido_mes']),  Icons.download, terracota),
                      _MetricCard('Total em Aberto', formatCurrency(_metrics!['total_em_aberto']),     Icons.hourglass_empty, amareloAlerta),
                      _MetricCard('Inadimplentes',   '${_metrics!['clientes_com_debito']} clientes',  Icons.warning_amber, vermelhoSuave),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Situação das Cobranças', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_metrics != null) _PieChart(metrics: _metrics!),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _periodChip(String val, String label) {
    final sel = _periodo == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label:          Text(label),
        selected:       sel,
        onSelected:     (_) { setState(() => _periodo = val); _load(); },
        selectedColor:  terracota.withOpacity(0.2),
        checkmarkColor: terracota,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          Text(label,  style: const TextStyle(fontSize: 11, color: cinzaMuted)),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _PieChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final recebido = (metrics['total_recebido_mes'] as num?)?.toDouble() ?? 0;
    final aberto   = (metrics['total_em_aberto']    as num?)?.toDouble() ?? 0;
    final total    = recebido + aberto;

    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: recebido, color: verdeMsgo, title: 'Recebido', radius: 60),
            PieChartSectionData(value: aberto, color: amareloAlerta, title: 'Em aberto', radius: 60),
          ],
          sectionsSpace: 4,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}

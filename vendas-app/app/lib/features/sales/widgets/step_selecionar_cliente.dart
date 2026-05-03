import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class StepSelecionarCliente extends StatefulWidget {
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const StepSelecionarCliente({super.key, required this.selected, required this.onSelected});

  @override
  State<StepSelecionarCliente> createState() => _StepSelecionarClienteState();
}

class _StepSelecionarClienteState extends State<StepSelecionarCliente> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    try {
      final data = await ApiClient.get('/customers?busca=${Uri.encodeComponent(q)}');
      setState(() => _results = data as List<dynamic>);
    } finally {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecionar cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            onChanged:  _search,
            decoration: const InputDecoration(
              labelText:  'Buscar por nome ou telefone',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          if (_searching) const LinearProgressIndicator(color: terracota),
          if (widget.selected != null) ...[
            const SizedBox(height: 12),
            _SelectedCard(customer: widget.selected!),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final c = _results[i] as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: terracota.withOpacity(0.15),
                    child: Text((c['nome'] as String)[0], style: const TextStyle(color: terracota)),
                  ),
                  title:    Text(c['nome'] ?? ''),
                  subtitle: Text(c['telefone'] ?? ''),
                  onTap:    () { _ctrl.clear(); setState(() => _results = []); widget.onSelected(c); },
                );
              },
            ),
          ),
          TextButton.icon(
            icon:      const Icon(Icons.person_add_outlined),
            label:     const Text('Cadastrar nova cliente'),
            onPressed: () => context.push('/customers/new'),
            style:     TextButton.styleFrom(foregroundColor: terracota),
          ),
        ],
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  const _SelectedCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        verdeMsgo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: verdeMsgo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: verdeMsgo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(customer['telefone'] ?? '', style: const TextStyle(color: cinzaMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

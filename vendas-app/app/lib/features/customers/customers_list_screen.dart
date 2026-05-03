import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _customers = [];
  bool _loading = true;
  String _filter = 'todos';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => _load(busca: _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? busca}) async {
    setState(() => _loading = true);
    try {
      final q = StringBuffer('/customers?');
      if (busca != null && busca.isNotEmpty) q.write('busca=${Uri.encodeComponent(busca)}&');
      if (_filter == 'ativo')   q.write('status=ativo');
      if (_filter == 'inativo') q.write('status=inativo');
      final data = await ApiClient.get(q.toString().trimRight());
      if (mounted) setState(() => _customers = data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText:    'Buscar por nome ou telefone...',
                    prefixIcon:  Icon(Icons.search),
                    filled:      true,
                    fillColor:   Colors.white,
                    border:      OutlineInputBorder(borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _chip('todos',  'Todos'),
                    _chip('ativo',  'Em dia'),
                    _chip('inativo','Sem compras'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _loading
          ? _shimmer()
          : _customers.isEmpty
              ? const Center(child: Text('Nenhuma cliente encontrada.', style: TextStyle(color: cinzaMuted)))
              : ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (_, i) => _CustomerCard(c: _customers[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed:  () => context.push('/customers/new').then((_) => _load()),
        backgroundColor: terracota,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _chip(String val, String label) {
    final selected = _filter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label:           Text(label),
        selected:        selected,
        onSelected:      (_) { setState(() => _filter = val); _load(); },
        selectedColor:   terracota.withOpacity(0.2),
        checkmarkColor:  terracota,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 72,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> c;
  const _CustomerCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/customers/${c['id']}'),
        leading: CircleAvatar(
          backgroundColor: terracota.withOpacity(0.2),
          child: Text(
            (c['nome'] as String? ?? 'C')[0].toUpperCase(),
            style: const TextStyle(color: terracota, fontWeight: FontWeight.bold),
          ),
        ),
        title:    Text(c['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(c['telefone'] ?? ''),
        trailing: const Icon(Icons.chevron_right, color: cinzaMuted),
      ),
    );
  }
}

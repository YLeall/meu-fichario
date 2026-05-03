import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';

const _categorias = [
  ('todas',          'Todas'),
  ('roupa_feminina', 'Roupas Femininas'),
  ('roupa_masculina','Roupas Masculinas'),
  ('roupa_infantil', 'Infantil'),
  ('cama_mesa_banho','Cama Mesa Banho'),
  ('calcados',       'Calçados'),
  ('bolsa_acessorio','Bolsas e Acess.'),
  ('outro',          'Outros'),
];

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  List<dynamic> _products = [];
  bool _loading = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categorias.length, vsync: this);
    _tab.addListener(() => _load());
    _searchCtrl.addListener(() { _busca = _searchCtrl.text; _load(); });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cat = _categorias[_tab.index].$1;
    final q   = StringBuffer('/products?ativo=true');
    if (cat != 'todas') q.write('&categoria=$cat');
    if (_busca.isNotEmpty) q.write('&busca=${Uri.encodeComponent(_busca)}');
    try {
      final data = await ApiClient.get(q.toString());
      if (mounted) setState(() => _products = data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        bottom: TabBar(
          controller:           _tab,
          isScrollable:         true,
          labelColor:           Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor:       Colors.white,
          tabs: _categorias.map((c) => Tab(text: c.$2)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText:   'Buscar por nome, marca ou referência...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? _shimmer()
                : _products.isEmpty
                    ? const Center(child: Text('Nenhum produto nesta categoria.', style: TextStyle(color: cinzaMuted)))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (_, i) => _ProductCard(p: _products[i], onChanged: _load),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:       () => context.push('/products/new').then((_) => _load()),
        backgroundColor: terracota,
        child: const Icon(Icons.add, color: Colors.white),
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

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> p;
  final VoidCallback onChanged;
  const _ProductCard({required this.p, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/products/${p['id']}/edit').then((_) => onChanged()),
        leading: CircleAvatar(
          backgroundColor: terracota.withOpacity(0.1),
          child: const Icon(Icons.inventory_2_outlined, color: terracota),
        ),
        title:    Text(p['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([p['categoria'], p['marca']].where((v) => v != null && (v as String).isNotEmpty).join(' · ')),
        trailing: Text(
          formatCurrency(p['preco_sugerido']),
          style: const TextStyle(fontWeight: FontWeight.bold, color: terracota),
        ),
      ),
    );
  }
}

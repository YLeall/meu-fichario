import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/utils/currency_formatter.dart';

class StepAdicionarItens extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final double totalBruto;

  const StepAdicionarItens({
    super.key,
    required this.items,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
    required this.totalBruto,
  });

  @override
  State<StepAdicionarItens> createState() => _StepAdicionarItensState();
}

class _StepAdicionarItensState extends State<StepAdicionarItens> {
  List<Map<String, dynamic>> get _items => widget.items;

  void _addItem(Map<String, dynamic> item) {
    final updated = [..._items, item];
    widget.onChanged(updated);
  }

  void _removeItem(int index) {
    final updated = [..._items]..removeAt(index);
    widget.onChanged(updated);
  }

  Future<void> _showItemAvulso() async {
    final descCtrl  = TextEditingController();
    final precoCtrl = TextEditingController();
    int qty         = 1;
    String? cat;
    bool salvarCatalogo = false;

    final categorias = [
      'roupa_feminina', 'roupa_masculina', 'roupa_infantil',
      'cama_mesa_banho', 'calcados', 'bolsa_acessorio', 'outro',
    ];

    await showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Item avulso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição do produto *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value:       cat,
                hint:        const Text('Categoria (opcional)'),
                items:       categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged:   (v) => setS(() => cat = v),
                decoration:  const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:   precoCtrl,
                      keyboardType: TextInputType.number,
                      decoration:   const InputDecoration(labelText: 'Preço unitário (R\$) *'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove), onPressed: () => setS(() => qty = (qty - 1).clamp(1, 99))),
                      Text('$qty', style: const TextStyle(fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => setS(() => qty++)),
                    ],
                  ),
                ],
              ),
              CheckboxListTile(
                value:       salvarCatalogo,
                onChanged:   (v) => setS(() => salvarCatalogo = v ?? false),
                title:       const Text('Salvar no catálogo'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: terracota,
              ),
              ElevatedButton(
                onPressed: () {
                  if (descCtrl.text.isEmpty || precoCtrl.text.isEmpty) return;
                  final preco = double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0;
                  _addItem({
                    'descricao_livre': descCtrl.text,
                    'categoria_livre': cat,
                    'quantidade':      qty,
                    'preco_unitario':  preco,
                    'product_id':      null,
                  });
                  if (salvarCatalogo && cat != null) {
                    ApiClient.post('/products', {
                      'nome':           descCtrl.text,
                      'categoria':      cat,
                      'preco_sugerido': preco,
                    }).catchError((_) {});
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Adicionar'),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> _showBuscaProduto() async {
    final ctrl = TextEditingController();
    List<dynamic> results = [];

    await showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Buscar produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus:  true,
                decoration: const InputDecoration(labelText: 'Nome, marca ou referência', prefixIcon: Icon(Icons.search)),
                onChanged:  (q) async {
                  if (q.length < 2) { setS(() => results = []); return; }
                  final data = await ApiClient.get('/products?busca=${Uri.encodeComponent(q)}&ativo=true');
                  setS(() => results = data as List<dynamic>);
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final p = results[i] as Map<String, dynamic>;
                    return ListTile(
                      title:    Text(p['nome'] ?? ''),
                      subtitle: Text('${p['categoria']} · ${formatCurrency(p['preco_sugerido'])}'),
                      onTap: () {
                        _addItem({
                          'product_id':     p['id'],
                          'descricao_livre': p['nome'],
                          'categoria_livre': p['categoria'],
                          'quantidade':      1,
                          'preco_unitario':  double.tryParse(p['preco_sugerido'].toString()) ?? 0.0,
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adicionar itens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon:      const Icon(Icons.search),
                  label:     const Text('Buscar produto'),
                  onPressed: _showBuscaProduto,
                  style:     OutlinedButton.styleFrom(foregroundColor: terracota),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon:      const Icon(Icons.add),
                  label:     const Text('Item avulso'),
                  onPressed: _showItemAvulso,
                  style:     OutlinedButton.styleFrom(foregroundColor: terracota),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Nenhum item adicionado ainda.', style: TextStyle(color: cinzaMuted)))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Dismissible(
                        key:        ValueKey(i),
                        direction:  DismissDirection.endToStart,
                        background: Container(
                          color:     vermelhoSuave,
                          alignment: Alignment.centerRight,
                          padding:   const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeItem(i),
                        child: ListTile(
                          title:    Text(item['descricao_livre'] ?? ''),
                          subtitle: Text('${item['quantidade']}x ${formatCurrency(item['preco_unitario'])}'),
                          trailing: Text(formatCurrency((item['quantidade'] as int) * (item['preco_unitario'] as double)),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding:    const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bege, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(formatCurrency(widget.totalBruto),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: terracota)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: widget.onBack, child: const Text('Voltar')),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _items.isEmpty ? null : widget.onNext,
                  child: const Text('Próximo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

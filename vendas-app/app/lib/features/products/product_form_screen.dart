import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

const _categorias = [
  ('roupa_feminina',  'Roupas Femininas'),
  ('roupa_masculina', 'Roupas Masculinas'),
  ('roupa_infantil',  'Roupa Infantil'),
  ('cama_mesa_banho', 'Cama Mesa Banho'),
  ('calcados',        'Calçados'),
  ('bolsa_acessorio', 'Bolsas e Acessórios'),
  ('outro',           'Outro'),
];

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nomeCtrl  = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _tamCtrl   = TextEditingController();
  final _corCtrl   = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _refCtrl   = TextEditingController();
  final _descCtrl  = TextEditingController();

  String _categoria = _categorias.first.$1;
  bool   _ativo     = true;
  bool   _loading   = false;
  bool   _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.productId != null;
    if (_isEditing) _loadProduct();
  }

  Future<void> _loadProduct() async {
    final data = await ApiClient.get('/products?id=${widget.productId}');
    // Workaround: get from list
    if (data is List && data.isNotEmpty) _fillForm(data[0]);
  }

  void _fillForm(Map<String, dynamic> p) {
    setState(() {
      _nomeCtrl.text  = p['nome']  ?? '';
      _precoCtrl.text = p['preco_sugerido']?.toString() ?? '';
      _tamCtrl.text   = p['tamanho'] ?? '';
      _corCtrl.text   = p['cor']    ?? '';
      _marcaCtrl.text = p['marca']  ?? '';
      _refCtrl.text   = p['referencia'] ?? '';
      _descCtrl.text  = p['descricao']  ?? '';
      _categoria      = p['categoria']  ?? _categorias.first.$1;
      _ativo          = p['ativo']      ?? true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'nome':           _nomeCtrl.text.trim(),
      'categoria':      _categoria,
      'preco_sugerido': double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0,
      'tamanho':        _tamCtrl.text.trim().isEmpty   ? null : _tamCtrl.text.trim(),
      'cor':            _corCtrl.text.trim().isEmpty   ? null : _corCtrl.text.trim(),
      'marca':          _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
      'referencia':     _refCtrl.text.trim().isEmpty   ? null : _refCtrl.text.trim(),
      'descricao':      _descCtrl.text.trim().isEmpty  ? null : _descCtrl.text.trim(),
      'ativo':          _ativo,
    };

    try {
      if (_isEditing) {
        await ApiClient.put('/products/${widget.productId}', body);
      } else {
        await ApiClient.post('/products', body);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: vermelhoSuave),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Produto' : 'Novo Produto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome do produto *'),
              validator:  (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value:      _categoria,
              decoration: const InputDecoration(labelText: 'Categoria *'),
              items:      _categorias.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
              onChanged:  (v) => setState(() => _categoria = v ?? _categorias.first.$1),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:   _precoCtrl,
              keyboardType: TextInputType.number,
              decoration:   const InputDecoration(labelText: 'Preço sugerido (R\$) *', prefixText: 'R\$ '),
              validator:    (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _tamCtrl, decoration: const InputDecoration(labelText: 'Tamanho'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _corCtrl, decoration: const InputDecoration(labelText: 'Cor'))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _marcaCtrl, decoration: const InputDecoration(labelText: 'Marca'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Referência'))),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines:   3,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title:       const Text('Produto ativo'),
              subtitle:    const Text('Inativo não aparece nas vendas'),
              value:       _ativo,
              onChanged:   (v) => setState(() => _ativo = v),
              activeColor: terracota,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Salvar' : 'Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}

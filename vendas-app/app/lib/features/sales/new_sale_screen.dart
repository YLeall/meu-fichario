import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/whatsapp_helper.dart';
import 'widgets/step_selecionar_cliente.dart';
import 'widgets/step_adicionar_itens.dart';
import 'widgets/step_condicoes_pagamento.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  int _step = 0;

  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _items    = [];
  Map<String, dynamic>? _payment;
  bool _saving = false;

  double get _totalBruto => _items.fold(0.0, (s, i) => s + (i['preco_unitario'] as double) * (i['quantidade'] as int));

  Future<void> _confirmar() async {
    setState(() => _saving = true);
    try {
      final entrada      = (_payment!['entrada_valor'] as double?) ?? 0.0;
      final totalParc    = _totalBruto - entrada;
      final numParcelas  = (_payment!['num_parcelas'] as int?) ?? 1;
      final forma        = _payment!['forma_pagamento'] as String;

      final body = {
        'customer_id':             _customer!['id'],
        'forma_pagamento':         forma,
        'total_bruto':             _totalBruto,
        'entrada_valor':           entrada,
        'total_parcelado':         totalParc,
        'num_parcelas':            numParcelas,
        'data_primeiro_vencimento': toIso(_payment!['data_primeiro_vencimento'] as DateTime),
        'observacoes':             _payment!['observacoes'],
        'items': _items.map((i) => {
          'product_id':     i['product_id'],
          'descricao_livre': i['descricao_livre'],
          'categoria_livre': i['categoria_livre'],
          'quantidade':     i['quantidade'],
          'preco_unitario': i['preco_unitario'],
        }).toList(),
      };

      final sale = await ApiClient.post('/sales', body);

      // Abrir WhatsApp
      if (forma == 'pix') {
        final settings = await ApiClient.get('/settings');
        await abrirWhatsAppPix(
          nome:      _customer!['nome'],
          telefone:  _customer!['telefone'],
          valor:     _totalBruto,
          chavePix:  settings['chave_pix'] ?? '',
        );
      } else {
        final valorParcela = numParcelas > 0 ? totalParc / numParcelas : 0.0;
        final listaItens   = _items.map((i) =>
            '${i['descricao_livre'] ?? i['nome'] ?? 'Item'} (${i['quantidade']}x ${formatCurrency(i['preco_unitario'])})').toList();
        await abrirWhatsAppParcelado(
          nome:                 _customer!['nome'],
          telefone:             _customer!['telefone'],
          itens:                listaItens,
          valorTotal:           _totalBruto,
          numParcelas:          numParcelas,
          valorParcela:         valorParcela,
          dataPrimeiraParcela:  toIso(_payment!['data_primeiro_vencimento'] as DateTime),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda registrada com sucesso!'), backgroundColor: verdeMsgo),
        );
        context.go('/sales/${sale['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: vermelhoSuave),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Venda')),
      body: Column(
        children: [
          _StepIndicator(current: _step),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                StepSelecionarCliente(
                  selected: _customer,
                  onSelected: (c) => setState(() { _customer = c; _step = 1; }),
                ),
                StepAdicionarItens(
                  items: _items,
                  onChanged: (items) => setState(() => _items = items),
                  onNext: () => setState(() => _step = 2),
                  onBack: () => setState(() => _step = 0),
                  totalBruto: _totalBruto,
                ),
                StepCondicoesPagamento(
                  totalBruto: _totalBruto,
                  payment:    _payment,
                  onChanged:  (p) => setState(() => _payment = p),
                  onBack:     () => setState(() => _step = 1),
                  onConfirm:  _saving ? null : _confirmar,
                  saving:     _saving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final labels = ['Cliente', 'Itens', 'Pagamento'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done   = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                if (i > 0) Expanded(child: Divider(color: done ? terracota : Colors.grey.shade300, thickness: 2)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: done || active ? terracota : Colors.grey.shade300,
                      child: done
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text('${i + 1}', style: TextStyle(color: active ? Colors.white : cinzaMuted, fontSize: 12)),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i], style: TextStyle(fontSize: 11, color: active ? terracota : cinzaMuted)),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

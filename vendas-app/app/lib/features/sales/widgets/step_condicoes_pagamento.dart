import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart' show formatDate, toIso;

class StepCondicoesPagamento extends StatefulWidget {
  final double totalBruto;
  final Map<String, dynamic>? payment;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onBack;
  final VoidCallback? onConfirm;
  final bool saving;

  const StepCondicoesPagamento({
    super.key,
    required this.totalBruto,
    required this.payment,
    required this.onChanged,
    required this.onBack,
    required this.onConfirm,
    required this.saving,
  });

  @override
  State<StepCondicoesPagamento> createState() => _StepCondicoesPagamentoState();
}

class _StepCondicoesPagamentoState extends State<StepCondicoesPagamento> {
  String _forma        = 'parcelado';
  double _entrada      = 0.0;
  int    _numParcelas  = 1;
  DateTime _dataVenc   = DateTime.now().add(const Duration(days: 30));
  final _obsCtrl       = TextEditingController();

  double get _totalParcelado => widget.totalBruto - _entrada;
  double get _valorParcela   => _numParcelas > 0 ? _totalParcelado / _numParcelas : 0;

  void _notify() {
    widget.onChanged({
      'forma_pagamento':         _forma,
      'entrada_valor':           _entrada,
      'num_parcelas':            _numParcelas,
      'data_primeiro_vencimento': _dataVenc,
      'observacoes':             _obsCtrl.text.isEmpty ? null : _obsCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Condições de pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Forma de pagamento
          Row(
            children: [
              Expanded(child: _formaChip('pix',       'PIX')),
              const SizedBox(width: 8),
              Expanded(child: _formaChip('parcelado', 'Parcelado')),
            ],
          ),
          const SizedBox(height: 16),
          // Entrada
          _NumberField(
            label:      'Entrada (R\$)',
            value:      _entrada,
            onChanged:  (v) { setState(() => _entrada = v.clamp(0, widget.totalBruto)); _notify(); },
          ),
          const SizedBox(height: 16),
          // Parcelas (só parcelado)
          if (_forma == 'parcelado') ...[
            Row(
              children: [
                const Text('Número de parcelas:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove), onPressed: () { setState(() => _numParcelas = (_numParcelas - 1).clamp(1, 24)); _notify(); }),
                Text('$_numParcelas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add), onPressed: () { setState(() => _numParcelas = (_numParcelas + 1).clamp(1, 24)); _notify(); }),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Data 1º vencimento
          ListTile(
            contentPadding: EdgeInsets.zero,
            title:    const Text('1º vencimento', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(formatDate(toIso(_dataVenc))),
            trailing: const Icon(Icons.calendar_today_outlined, color: terracota),
            onTap: () async {
              final d = await showDatePicker(
                context:     context,
                initialDate: _dataVenc,
                firstDate:   DateTime.now(),
                lastDate:    DateTime.now().add(const Duration(days: 730)),
              );
              if (d != null) { setState(() => _dataVenc = d); _notify(); }
            },
          ),
          const SizedBox(height: 12),
          // Preview parcelas
          if (_forma == 'parcelado' && _numParcelas > 1)
            _ParcelasPreview(
              total:       _totalParcelado,
              n:           _numParcelas,
              dataBase:    _dataVenc,
              valorParcela: _valorParcela,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _obsCtrl,
            maxLines:   2,
            decoration: const InputDecoration(labelText: 'Observações (opcional)'),
            onChanged:  (_) => _notify(),
          ),
          const SizedBox(height: 24),
          // Resumo
          Container(
            padding:    const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bege, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _summaryRow('Total bruto',    formatCurrency(widget.totalBruto)),
                if (_entrada > 0) _summaryRow('Entrada', '- ${formatCurrency(_entrada)}'),
                _summaryRow('Total parcelado', formatCurrency(_totalParcelado)),
                if (_forma == 'parcelado')
                  _summaryRow('Valor por parcela', '${_numParcelas}x ${formatCurrency(_valorParcela)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(onPressed: widget.onBack, child: const Text('Voltar')),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onConfirm,
                  child: widget.saving
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar Venda'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formaChip(String val, String label) {
    final sel = _forma == val;
    return GestureDetector(
      onTap: () { setState(() { _forma = val; if (val == 'pix') _numParcelas = 1; }); _notify(); },
      child: Container(
        padding:    const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:        sel ? terracota : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: sel ? terracota : Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: sel ? Colors.white : cinzaTexto, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _summaryRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: cinzaMuted)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _NumberField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _NumberField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue:  value.toStringAsFixed(2),
      keyboardType:  const TextInputType.numberWithOptions(decimal: true),
      decoration:    InputDecoration(labelText: label),
      onChanged:     (v) => onChanged(double.tryParse(v.replaceAll(',', '.')) ?? 0),
    );
  }
}

class _ParcelasPreview extends StatelessWidget {
  final double total;
  final int n;
  final DateTime dataBase;
  final double valorParcela;

  const _ParcelasPreview({required this.total, required this.n, required this.dataBase, required this.valorParcela});

  @override
  Widget build(BuildContext context) {
    final base  = round2(total / n);
    final ajuste = round2(total - base * n);

    return Container(
      padding:    const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prévia das parcelas', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(n, (i) {
            final dt    = DateTime(dataBase.year, dataBase.month + i, dataBase.day);
            final valor = i == n - 1 ? base + ajuste : base;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${i + 1}/$n — ${formatDate(toIso(dt))}', style: const TextStyle(color: cinzaTexto)),
                  Text(formatCurrency(valor), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double round2(double v) => (v * 100).roundToDouble() / 100;
}

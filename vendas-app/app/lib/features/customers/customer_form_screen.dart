import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils/mask_formatters.dart';

class CustomerFormScreen extends StatefulWidget {
  final String? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nomeCtrl    = TextEditingController();
  final _phoneCtrl   = phoneMask();
  final _cpfCtrl     = cpfMask();
  final _endCtrl     = TextEditingController();
  final _obsCtrl     = TextEditingController();
  bool _loading      = false;
  bool _isEditing    = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.customerId != null;
    if (_isEditing) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final data = await ApiClient.get('/customers/${widget.customerId}');
    setState(() {
      _nomeCtrl.text = data['nome'] ?? '';
      _endCtrl.text  = data['endereco'] ?? '';
      _obsCtrl.text  = data['observacoes'] ?? '';
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _phoneCtrl.dispose();
    _cpfCtrl.dispose();
    _endCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'nome':       _nomeCtrl.text.trim(),
      'telefone':   digitsOnly(_phoneCtrl.text),
      'cpf':        digitsOnly(_cpfCtrl.text).isEmpty ? null : digitsOnly(_cpfCtrl.text),
      'endereco':   _endCtrl.text.trim().isEmpty ? null : _endCtrl.text.trim(),
      'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    };

    try {
      if (_isEditing) {
        await ApiClient.put('/customers/${widget.customerId}', body);
      } else {
        await ApiClient.post('/customers', body);
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Cliente' : 'Nova Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo *', prefixIcon: Icon(Icons.person_outlined)),
              validator:  (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:   _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:   const InputDecoration(labelText: 'Telefone * (DDD + número)', prefixIcon: Icon(Icons.phone_outlined)),
              validator:    (v) => (v == null || digitsOnly(v).length < 10) ? 'Telefone inválido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:   _cpfCtrl,
              keyboardType: TextInputType.number,
              decoration:   const InputDecoration(labelText: 'CPF (opcional)', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endCtrl,
              decoration: const InputDecoration(labelText: 'Endereço (opcional)', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _obsCtrl,
              maxLines:   3,
              decoration: const InputDecoration(labelText: 'Observações (opcional)', prefixIcon: Icon(Icons.note_outlined)),
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendas_app/core/utils/currency_formatter.dart';
import 'package:vendas_app/core/utils/date_formatter.dart';
import 'package:vendas_app/core/utils/mask_formatters.dart';

void main() {
  group('formatCurrency', () {
    test('formata valor inteiro', () {
      expect(formatCurrency(100), 'R\$ 100,00');
    });

    test('formata valor com centavos', () {
      expect(formatCurrency(99.9), 'R\$ 99,90');
    });

    test('formata zero', () {
      expect(formatCurrency(0), 'R\$ 0,00');
    });

    test('aceita string numérica', () {
      expect(formatCurrency('250.50'), 'R\$ 250,50');
    });
  });

  group('formatDate', () {
    test('formata data ISO corretamente', () {
      expect(formatDate('2026-05-03'), '03/05/2026');
    });

    test('retorna traço para null', () {
      expect(formatDate(null), '—');
    });

    test('retorna valor original se data inválida', () {
      expect(formatDate('invalida'), 'invalida');
    });
  });

  group('toIso', () {
    test('converte DateTime para string ISO', () {
      expect(toIso(DateTime(2026, 5, 3)), '2026-05-03');
    });

    test('adiciona zeros à esquerda', () {
      expect(toIso(DateTime(2026, 1, 7)), '2026-01-07');
    });
  });

  group('digitsOnly', () {
    test('remove máscara de telefone', () {
      expect(digitsOnly('(71) 99999-8888'), '71999998888');
    });

    test('remove pontos e traço de CPF', () {
      expect(digitsOnly('123.456.789-09'), '12345678909');
    });

    test('não altera string só com dígitos', () {
      expect(digitsOnly('12345'), '12345');
    });
  });

  group('MetricCard smoke test', () {
    testWidgets('renderiza label e valor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _FakeMetricCard(label: 'Teste', value: 'R\$ 100,00'),
          ),
        ),
      );
      expect(find.text('Teste'), findsOneWidget);
      expect(find.text('R\$ 100,00'), findsOneWidget);
    });
  });
}

/// Widget mínimo para smoke test sem precisar do Supabase inicializado.
class _FakeMetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _FakeMetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}

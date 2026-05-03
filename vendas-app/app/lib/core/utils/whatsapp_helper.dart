import 'package:url_launcher/url_launcher.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

Future<bool> abrirWhatsApp({
  required String nome,
  required String telefone,
  required int numeroParcela,
  required int totalParcelas,
  required double valor,
  required String dataVencimento,
  required int diasAtraso,
}) async {
  final tel = _formatarTelefone(telefone);
  final msg = _mensagemCobranca(
    nome:           nome,
    numeroParcela:  numeroParcela,
    totalParcelas:  totalParcelas,
    valor:          valor,
    dataVencimento: dataVencimento,
    diasAtraso:     diasAtraso,
  );
  return _abrir(tel, msg);
}

Future<bool> abrirWhatsAppPix({
  required String nome,
  required String telefone,
  required double valor,
  required String chavePix,
}) async {
  final tel = _formatarTelefone(telefone);
  final msg = 'Olá $nome! 😊 Obrigada pela compra de ${formatCurrency(valor)}!\n'
      'Para finalizar, faça o pagamento via PIX para a chave: $chavePix 🙏';
  return _abrir(tel, msg);
}

Future<bool> abrirWhatsAppParcelado({
  required String nome,
  required String telefone,
  required List<String> itens,
  required double valorTotal,
  required int numParcelas,
  required double valorParcela,
  required String dataPrimeiraParcela,
}) async {
  final tel       = _formatarTelefone(telefone);
  final listaItens = itens.map((i) => '• $i').join('\n');
  final msg = 'Olá $nome! 😊 Confirmando sua compra:\n'
      '$listaItens\n\n'
      'Total: ${formatCurrency(valorTotal)}\n'
      'Parcelado em ${numParcelas}x de ${formatCurrency(valorParcela)}\n'
      '1ª parcela: ${formatDate(dataPrimeiraParcela)}\n\n'
      'Qualquer dúvida me chame! 💛';
  return _abrir(tel, msg);
}

String _formatarTelefone(String t) {
  final digits = t.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('55') ? digits : '55$digits';
}

String _mensagemCobranca({
  required String nome,
  required int numeroParcela,
  required int totalParcelas,
  required double valor,
  required String dataVencimento,
  required int diasAtraso,
}) {
  final parcela = '$numeroParcela/$totalParcelas';
  final v       = formatCurrency(valor);

  if (diasAtraso == 0) {
    return 'Olá $nome! 😊 Passando para lembrar que sua parcela $parcela de $v '
        'vence hoje. Qualquer dúvida me chame! 🙏';
  } else if (diasAtraso <= 3) {
    return 'Olá $nome! 😊 Tudo bem? Vi aqui que sua parcela $parcela de $v '
        'venceu há $diasAtraso dia(s). Quando puder, me avisa! 💛';
  } else {
    return 'Olá $nome! Passando para avisar que sua parcela $parcela de $v '
        'está em aberto desde ${formatDate(dataVencimento)}. '
        'Podemos combinar o pagamento? 😊';
  }
}

Future<bool> _abrir(String tel, String msg) async {
  final uri = Uri.parse('https://wa.me/$tel?text=${Uri.encodeComponent(msg)}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

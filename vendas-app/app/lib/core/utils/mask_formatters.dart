import 'package:flutter_masked_text2/flutter_masked_text2.dart';

MaskedTextController phoneMask()  => MaskedTextController(mask: '(00) 00000-0000');
MaskedTextController cpfMask()    => MaskedTextController(mask: '000.000.000-00');
MaskedTextController moneyMask()  => MaskedTextController(mask: '00000,00');

String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

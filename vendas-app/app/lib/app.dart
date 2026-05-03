import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';

class VendasApp extends StatelessWidget {
  const VendasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title:        'Vendas App',
      theme:        buildTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

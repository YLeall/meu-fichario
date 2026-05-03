import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/customers'))    currentIndex = 1;
    if (location.startsWith('/installments')) currentIndex = 3;
    if (location.startsWith('/products') || location.startsWith('/reports')) currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex:     currentIndex,
        backgroundColor:   Colors.white,
        indicatorColor:    terracota.withOpacity(0.15),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/dashboard');
            case 1: context.go('/customers');
            case 2: context.go('/sales/new');
            case 3: context.go('/installments');
            case 4: context.go('/products');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),         selectedIcon: Icon(Icons.home),         label: 'Início'),
          NavigationDestination(icon: Icon(Icons.people_outline),        selectedIcon: Icon(Icons.people),       label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline),    selectedIcon: Icon(Icons.add_circle),   label: 'Nova Venda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Parcelas'),
          NavigationDestination(icon: Icon(Icons.more_horiz),            selectedIcon: Icon(Icons.more_horiz),   label: 'Mais'),
        ],
      ),
    );
  }
}

import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/customers/customers_list_screen.dart';
import '../features/customers/customer_detail_screen.dart';
import '../features/customers/customer_form_screen.dart';
import '../features/sales/new_sale_screen.dart';
import '../features/sales/sale_detail_screen.dart';
import '../features/installments/installments_screen.dart';
import '../features/products/products_screen.dart';
import '../features/products/product_form_screen.dart';
import '../features/reports/reports_screen.dart';
import 'shell_scaffold.dart';

final router = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final isLogin    = state.matchedLocation == '/login';
    if (!isLoggedIn && !isLogin) return '/login';
    if (isLoggedIn && isLogin)  return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/customers', builder: (_, __) => const CustomersListScreen()),
        GoRoute(path: '/customers/new',    builder: (_, __) => const CustomerFormScreen()),
        GoRoute(path: '/customers/:id',    builder: (_, s) => CustomerDetailScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/customers/:id/edit', builder: (_, s) => CustomerFormScreen(customerId: s.pathParameters['id'])),
        GoRoute(path: '/sales/new',        builder: (_, __) => const NewSaleScreen()),
        GoRoute(path: '/sales/:id',        builder: (_, s) => SaleDetailScreen(saleId: s.pathParameters['id']!)),
        GoRoute(path: '/installments',     builder: (_, __) => const InstallmentsScreen()),
        GoRoute(path: '/products',         builder: (_, __) => const ProductsScreen()),
        GoRoute(path: '/products/new',     builder: (_, __) => const ProductFormScreen()),
        GoRoute(path: '/products/:id/edit', builder: (_, s) => ProductFormScreen(productId: s.pathParameters['id'])),
        GoRoute(path: '/reports',          builder: (_, __) => const ReportsScreen()),
      ],
    ),
  ],
);

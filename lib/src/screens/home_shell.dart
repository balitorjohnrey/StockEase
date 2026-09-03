import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'dashboard_screen.dart';
import 'inventory_screens.dart';
import 'reports_screens.dart';
import 'sales_screens.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _destinations = [
    _ShellDestination('Dashboard', Icons.dashboard_outlined),
    _ShellDestination('Inventory', Icons.inventory_2_outlined),
    _ShellDestination('New Sale', Icons.point_of_sale),
    _ShellDestination('Sales', Icons.receipt_long_outlined),
    _ShellDestination('Reports', Icons.query_stats),
    _ShellDestination('Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final screens = [
      const DashboardScreen(),
      const InventoryScreen(),
      const NewSaleScreen(),
      const SalesHistoryScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final body = Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 32),
                const SizedBox(width: 10),
                Text(state.business?.name ?? 'StockEase'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Low-stock products',
                icon: const Icon(Icons.warning_amber_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LowStockProductsScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: screens[_index],
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) {
                    setState(() => _index = value);
                  },
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                ),
        );

        if (!useRail) return body;

        return Scaffold(
          backgroundColor: AppTheme.sky,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (value) {
                  setState(() => _index = value);
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 18),
                  child: BrandLogo(size: 48),
                ),
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

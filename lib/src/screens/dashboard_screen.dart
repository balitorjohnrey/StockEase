import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';
import 'inventory_screens.dart';
import 'sales_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardSummary>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _summary ??= _load();
  }

  Future<DashboardSummary> _load() {
    final state = context.appState;
    return state.sales.fetchDashboard(
      state.businessId,
      inventoryRepository: state.inventory,
    );
  }

  void _refresh() {
    setState(() => _summary = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error!, onRetry: _refresh);
        }
        final summary = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            children: [
              ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'Dashboard',
                      subtitle:
                          'Sales and inventory summary in Asia/Manila time.',
                      trailing: IconButton(
                        tooltip: 'Refresh',
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ResponsiveCards(
                      children: [
                        MetricCard(
                          title: "Today's total sales",
                          value: formatMoney(summary.todaySales),
                          icon: Icons.payments_outlined,
                        ),
                        MetricCard(
                          title: 'Monthly sales',
                          value: formatMoney(summary.monthSales),
                          icon: Icons.calendar_month_outlined,
                          color: AppTheme.secondary,
                        ),
                        MetricCard(
                          title: "Today's transactions",
                          value: summary.transactionCount.toString(),
                          icon: Icons.receipt_long_outlined,
                        ),
                        MetricCard(
                          title: 'Total products',
                          value: summary.totalProducts.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: AppTheme.secondary,
                        ),
                        MetricCard(
                          title: 'Low-stock products',
                          value: summary.lowStockProducts.toString(),
                          icon: Icons.warning_amber_outlined,
                          color: AppTheme.warning,
                        ),
                        MetricCard(
                          title: 'Out-of-stock products',
                          value: summary.outOfStockProducts.toString(),
                          icon: Icons.remove_shopping_cart_outlined,
                          color: AppTheme.danger,
                        ),
                        MetricCard(
                          title: 'Estimated gross profit',
                          value: formatMoney(summary.estimatedGrossProfit),
                          icon: Icons.trending_up,
                          color: AppTheme.success,
                          subtitle:
                              'Before incomplete expenses and other costs.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 860;
                        final chart = _DashboardPanel(
                          title: 'Sales performance',
                          child: SimpleBarChart(points: summary.salesChart),
                        );
                        final recent = _DashboardPanel(
                          title: 'Recent sales',
                          child: _RecentSalesList(sales: summary.recentSales),
                        );

                        if (!wide) {
                          return Column(
                            children: [
                              chart,
                              const SizedBox(height: 14),
                              recent,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: chart),
                            const SizedBox(width: 14),
                            Expanded(flex: 2, child: recent),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LowStockProductsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.warning_amber_outlined),
                          label: const Text('Low-stock products'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NewSaleScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.point_of_sale),
                          label: const Text('Start sale'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecentSalesList extends StatelessWidget {
  const _RecentSalesList({required this.sales});

  final List<SaleSummary> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No sales yet',
        message: 'Completed transactions will appear here.',
      );
    }

    return Column(
      children: [
        for (final sale in sales)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(sale.receiptNumber),
            subtitle: Text(formatManilaDateTime(sale.createdAt)),
            trailing: MoneyText(
              sale.totalAmount,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SaleDetailsScreen(saleId: sale.id),
              ),
            ),
          ),
      ],
    );
  }
}

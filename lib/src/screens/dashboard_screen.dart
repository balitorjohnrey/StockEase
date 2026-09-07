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
    setState(() {
      _summary = _load();
    });
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
                    _DashboardGraphOverview(summary: summary),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 860;
                        final chart = _DashboardPanel(
                          title: 'Transaction activity',
                          subtitle: 'Completed sales over the last 7 days.',
                          child: SimpleBarChart(
                            points: summary.transactionChart,
                            height: 190,
                            valueFormatter: (value) => value.toInt().toString(),
                          ),
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
  const _DashboardPanel({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DashboardGraphOverview extends StatelessWidget {
  const _DashboardGraphOverview({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final salesProfit = _DashboardPanel(
          title: 'Sales and profit trend',
          subtitle: 'Daily sales compared with estimated gross profit.',
          child: _DualBarChart(
            primaryPoints: summary.salesChart,
            secondaryPoints: summary.profitChart,
            primaryLabel: 'Sales',
            secondaryLabel: 'Profit',
            primaryColor: AppTheme.primary,
            secondaryColor: AppTheme.success,
            valueFormatter: formatMoney,
          ),
        );
        final inventory = _DashboardPanel(
          title: 'Inventory health',
          subtitle: 'Active products grouped by stock status.',
          child: _InventoryHealthChart(summary: summary),
        );
        final performance = _DashboardPanel(
          title: 'Business performance',
          subtitle: 'Today compared with this month.',
          child: _PerformanceBars(summary: summary),
        );

        if (!wide) {
          return Column(
            children: [
              salesProfit,
              const SizedBox(height: 14),
              inventory,
              const SizedBox(height: 14),
              performance,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: salesProfit),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  inventory,
                  const SizedBox(height: 14),
                  performance,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DualBarChart extends StatelessWidget {
  const _DualBarChart({
    required this.primaryPoints,
    required this.secondaryPoints,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.valueFormatter,
  });

  final List<ChartPoint> primaryPoints;
  final List<ChartPoint> secondaryPoints;
  final String primaryLabel;
  final String secondaryLabel;
  final Color primaryColor;
  final Color secondaryColor;
  final String Function(num value) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (primaryPoints.isEmpty) {
      return const EmptyState(
        icon: Icons.stacked_bar_chart,
        title: 'No chart data',
        message: 'Completed sales will appear here.',
      );
    }

    final totals = [
      ...primaryPoints.map((point) => point.value),
      ...secondaryPoints.map((point) => point.value),
    ];
    final maxValue = totals.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartLegend(
          items: [
            _LegendItem(
              label: primaryLabel,
              value: valueFormatter(_sum(primaryPoints)),
              color: primaryColor,
            ),
            _LegendItem(
              label: secondaryLabel,
              value: valueFormatter(_sum(secondaryPoints)),
              color: secondaryColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < primaryPoints.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Tooltip(
                      message: '${primaryPoints[index].label}\n'
                          '$primaryLabel: ${valueFormatter(primaryPoints[index].value)}\n'
                          '$secondaryLabel: ${valueFormatter(_pointValue(secondaryPoints, index))}',
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _ChartBar(
                                    value: primaryPoints[index].value,
                                    maxValue: maxValue,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _ChartBar(
                                    value: _pointValue(secondaryPoints, index),
                                    maxValue: maxValue,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            primaryPoints[index].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  double _sum(List<ChartPoint> points) {
    return points.fold<double>(0, (sum, point) => sum + point.value);
  }

  double _pointValue(List<ChartPoint> points, int index) {
    return index >= points.length ? 0 : points[index].value;
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor:
          maxValue == 0 ? 0.04 : (value / maxValue).clamp(0.04, 1).toDouble(),
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _InventoryHealthChart extends StatelessWidget {
  const _InventoryHealthChart({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final inStock = (summary.totalProducts -
            summary.lowStockProducts -
            summary.outOfStockProducts)
        .clamp(0, summary.totalProducts)
        .toInt();
    final lowStock = summary.lowStockProducts;
    final outOfStock = summary.outOfStockProducts;
    final total = summary.totalProducts;

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: CustomPaint(
            painter: _InventoryDonutPainter(
              inStock: inStock,
              lowStock: lowStock,
              outOfStock: outOfStock,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toString(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'products',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ProgressMetricRow(
          label: 'In stock',
          value: inStock.toString(),
          ratio: _ratio(inStock, total),
          color: AppTheme.success,
        ),
        const SizedBox(height: 10),
        _ProgressMetricRow(
          label: 'Low stock',
          value: lowStock.toString(),
          ratio: _ratio(lowStock, total),
          color: AppTheme.warning,
        ),
        const SizedBox(height: 10),
        _ProgressMetricRow(
          label: 'Out of stock',
          value: outOfStock.toString(),
          ratio: _ratio(outOfStock, total),
          color: AppTheme.danger,
        ),
      ],
    );
  }

  double _ratio(int value, int total) {
    return total <= 0 ? 0 : (value / total).clamp(0, 1).toDouble();
  }
}

class _InventoryDonutPainter extends CustomPainter {
  const _InventoryDonutPainter({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = AppTheme.line
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 6.283185307179586, false, basePaint);

    final total = inStock + lowStock + outOfStock;
    if (total <= 0) return;

    final paint = Paint()
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    var start = -1.5707963267948966;
    for (final segment in [
      (value: inStock, color: AppTheme.success),
      (value: lowStock, color: AppTheme.warning),
      (value: outOfStock, color: AppTheme.danger),
    ]) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * 6.283185307179586;
      paint.color = segment.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _InventoryDonutPainter oldDelegate) {
    return inStock != oldDelegate.inStock ||
        lowStock != oldDelegate.lowStock ||
        outOfStock != oldDelegate.outOfStock;
  }
}

class _PerformanceBars extends StatelessWidget {
  const _PerformanceBars({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final todayShare = summary.monthSales <= 0
        ? 0.0
        : (summary.todaySales / summary.monthSales).clamp(0, 1).toDouble();
    final grossMargin = summary.monthSales <= 0
        ? 0.0
        : (summary.estimatedGrossProfit / summary.monthSales)
            .clamp(0, 1)
            .toDouble();
    final transactionShare = summary.monthTransactionCount <= 0
        ? 0.0
        : (summary.transactionCount / summary.monthTransactionCount)
            .clamp(0, 1)
            .toDouble();

    return Column(
      children: [
        _ProgressMetricRow(
          label: 'Today sales',
          value: formatMoney(summary.todaySales),
          ratio: todayShare,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 12),
        _ProgressMetricRow(
          label: 'Month sales',
          value: formatMoney(summary.monthSales),
          ratio: summary.monthSales > 0 ? 1.0 : 0.0,
          color: AppTheme.secondary,
        ),
        const SizedBox(height: 12),
        _ProgressMetricRow(
          label: 'Gross profit',
          value: formatMoney(summary.estimatedGrossProfit),
          ratio: grossMargin,
          color: AppTheme.success,
        ),
        const SizedBox(height: 12),
        _ProgressMetricRow(
          label: 'Today transactions',
          value: '${summary.transactionCount}/${summary.monthTransactionCount}',
          ratio: transactionShare,
          color: AppTheme.warning,
        ),
      ],
    );
  }
}

class _ProgressMetricRow extends StatelessWidget {
  const _ProgressMetricRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clampedRatio = ratio.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: clampedRatio == 0 ? 0.02 : clampedRatio,
            minHeight: 9,
            backgroundColor: AppTheme.line,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(item.label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 6),
              Text(
                item.value,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
      ],
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

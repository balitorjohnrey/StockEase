import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/formatters.dart';
import 'expenses_repository.dart';
import 'inventory_repository.dart';

enum BestSellerRange { today, week, month, allTime }

class SalesRepository {
  SalesRepository(this._client);

  final SupabaseClient _client;

  static const _saleSelect = '''
    id,business_id,receipt_number,total_amount,cash_received,change_amount,
    estimated_gross_profit,status,created_at,
    sale_items(product_id,product_name_snapshot,sku_snapshot,unit_price,
    cost_price_snapshot,quantity,line_total,gross_profit)
  ''';

  Future<Receipt> completeSale({
    required String businessId,
    required List<CartLine> items,
    required double cashReceived,
  }) async {
    final response = await _client.rpc(
      'complete_sale',
      params: {
        'p_business_id': businessId,
        'p_items': [
          for (final item in items)
            {'product_id': item.product.id, 'quantity': item.quantity},
        ],
        'p_cash_received': cashReceived,
      },
    );

    return Receipt.fromJson(readMap(response));
  }

  Future<List<SaleSummary>> fetchSales(
    String businessId, {
    String search = '',
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = 200,
  }) async {
    dynamic query =
        _client.from('sales').select(_saleSelect).eq('business_id', businessId);

    if (fromUtc != null) {
      query = query.gte('created_at', fromUtc.toIso8601String());
    }
    if (toUtc != null) {
      query = query.lt('created_at', toUtc.toIso8601String());
    }

    final rows = await query.order('created_at', ascending: false).limit(limit)
        as List<dynamic>;

    var sales = [for (final row in rows) SaleSummary.fromJson(readMap(row))];
    final trimmed = search.trim().toLowerCase();
    if (trimmed.isNotEmpty) {
      sales = sales.where((sale) {
        final receiptMatch = sale.receiptNumber.toLowerCase().contains(trimmed);
        final productMatch = sale.items.any(
          (item) => item.productName.toLowerCase().contains(trimmed),
        );
        return receiptMatch || productMatch;
      }).toList();
    }
    return sales;
  }

  Future<Receipt> fetchReceipt({
    required String businessId,
    required String saleId,
    required String businessName,
  }) async {
    final row = await _client
        .from('sales')
        .select(_saleSelect)
        .eq('business_id', businessId)
        .eq('id', saleId)
        .single();
    final data = readMap(row);
    data['business_name'] = businessName;
    return Receipt.fromJson(data);
  }

  Future<DashboardSummary> fetchDashboard(
    String businessId, {
    required InventoryRepository inventoryRepository,
  }) async {
    final todayStart = manilaDayStartUtc();
    final monthStart = manilaMonthStartUtc();
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final products = await inventoryRepository.fetchProducts(
      businessId,
      activeOnly: true,
    );
    final monthSales = await fetchSales(
      businessId,
      fromUtc: monthStart,
      limit: 500,
    );
    final recentSales = await fetchSales(businessId, limit: 5);

    final todaySales = monthSales.where(
      (sale) =>
          !sale.createdAt.isBefore(todayStart) &&
          sale.createdAt.isBefore(tomorrowStart),
    );

    return DashboardSummary(
      todaySales: todaySales.fold(0, (sum, sale) => sum + sale.totalAmount),
      monthSales: monthSales.fold(0, (sum, sale) => sum + sale.totalAmount),
      transactionCount: todaySales.length,
      totalProducts: products.length,
      lowStockProducts: products.where((product) => product.isLowStock).length,
      outOfStockProducts:
          products.where((product) => product.isOutOfStock).length,
      estimatedGrossProfit:
          monthSales.fold(0, (sum, sale) => sum + sale.estimatedGrossProfit),
      recentSales: recentSales,
      salesChart: _dailyChart(monthSales),
    );
  }

  Future<List<BestSeller>> fetchBestSellers({
    required String businessId,
    required BestSellerRange range,
  }) async {
    final nowStart = manilaDayStartUtc();
    final fromUtc = switch (range) {
      BestSellerRange.today => nowStart,
      BestSellerRange.week => nowStart.subtract(const Duration(days: 6)),
      BestSellerRange.month => manilaMonthStartUtc(),
      BestSellerRange.allTime => null,
    };

    final sales = await fetchSales(businessId, fromUtc: fromUtc, limit: 1000);
    final totals = <String, BestSeller>{};

    for (final sale in sales) {
      for (final item in sale.items) {
        final key = item.productId ?? item.productName;
        final current = totals[key];
        totals[key] = BestSeller(
          productId: key,
          productName: item.productName,
          quantitySold: (current?.quantitySold ?? 0) + item.quantity,
          generatedSales: (current?.generatedSales ?? 0) + item.subtotal,
        );
      }
    }

    final bestSellers = totals.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return bestSellers;
  }

  Future<ReportSummary> fetchReportSummary({
    required String businessId,
    required ExpensesRepository expensesRepository,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    final periodStart = fromUtc ?? manilaMonthStartUtc();
    final sales = await fetchSales(
      businessId,
      fromUtc: periodStart,
      toUtc: toUtc,
      limit: 1000,
    );
    final expenses = await expensesRepository.fetchExpenses(
      businessId,
      from: toManila(periodStart),
      to: toUtc == null ? null : toManila(toUtc),
    );
    final grossProfit =
        sales.fold(0.0, (sum, sale) => sum + sale.estimatedGrossProfit);
    final expenseTotal =
        expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    return ReportSummary(
      salesTotal: sales.fold(0.0, (sum, sale) => sum + sale.totalAmount),
      estimatedGrossProfit: grossProfit,
      expenseTotal: expenseTotal,
      estimatedNetProfit: grossProfit - expenseTotal,
      transactionCount: sales.length,
    );
  }

  List<ChartPoint> _dailyChart(List<SaleSummary> sales) {
    final start = manilaDayStartUtc().subtract(const Duration(days: 6));
    final buckets = <DateTime, double>{
      for (var i = 0; i < 7; i++) start.add(Duration(days: i)): 0,
    };

    for (final sale in sales) {
      final day = manilaDayStartUtc(sale.createdAt);
      if (buckets.containsKey(day)) {
        buckets[day] = buckets[day]! + sale.totalAmount;
      }
    }

    return [
      for (final entry in buckets.entries)
        ChartPoint(
          label: '${toManila(entry.key).month}/${toManila(entry.key).day}',
          value: entry.value,
        ),
    ];
  }
}

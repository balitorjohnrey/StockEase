import '../utils/formatters.dart';

double readDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int readInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime readDate(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.now().toUtc();
}

Map<String, dynamic> readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

class Business {
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final DateTime createdAt;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'].toString(),
      ownerId: json['owner_id'].toString(),
      name: json['name']?.toString() ?? '',
      createdAt: readDate(json['created_at']),
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String businessId;
  final String name;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      businessId: json['business_id'].toString(),
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] != false,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.sku,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOutOfStock => stockQuantity <= 0;

  bool get isLowStock =>
      stockQuantity > 0 && stockQuantity <= lowStockThreshold;

  double get estimatedInventoryValue => costPrice * stockQuantity;

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = readMap(json['categories']);
    return Product(
      id: json['id'].toString(),
      businessId: json['business_id'].toString(),
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName:
          category['name']?.toString() ?? json['category_name']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      costPrice: readDouble(json['cost_price']),
      sellingPrice: readDouble(json['selling_price']),
      stockQuantity: readInt(json['stock_quantity']),
      lowStockThreshold: readInt(json['low_stock_threshold']),
      isActive: json['is_active'] != false,
      createdAt: readDate(json['created_at']),
      updatedAt: readDate(json['updated_at']),
    );
  }
}

class ProductInput {
  const ProductInput({
    required this.name,
    required this.categoryName,
    required this.sku,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.isActive,
  });

  final String name;
  final String categoryName;
  final String sku;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool isActive;

  Map<String, dynamic> toJson({
    required String businessId,
    required String? categoryId,
    bool includeStock = true,
  }) {
    return {
      'business_id': businessId,
      'category_id': categoryId,
      'name': name.trim(),
      'sku': sku.trim().isEmpty ? null : sku.trim(),
      'barcode': barcode.trim().isEmpty ? null : barcode.trim(),
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      if (includeStock) 'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive,
    };
  }
}

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.sellingPrice * quantity;

  CartLine copyWith({int? quantity}) {
    return CartLine(product: product, quantity: quantity ?? this.quantity);
  }
}

class ReceiptItem {
  const ReceiptItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
    required this.subtotal,
  });

  final String? productId;
  final String productName;
  final String? sku;
  final double unitPrice;
  final double costPrice;
  final int quantity;
  final double subtotal;

  double get grossProfit => (unitPrice - costPrice) * quantity;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      productId: json['product_id']?.toString(),
      productName: json['product_name']?.toString() ??
          json['product_name_snapshot']?.toString() ??
          '',
      sku: json['sku']?.toString() ?? json['sku_snapshot']?.toString(),
      unitPrice: readDouble(json['unit_price']),
      costPrice: readDouble(json['cost_price'] ?? json['cost_price_snapshot']),
      quantity: readInt(json['quantity']),
      subtotal: readDouble(json['subtotal'] ?? json['line_total']),
    );
  }
}

class Receipt {
  const Receipt({
    required this.saleId,
    required this.businessName,
    required this.receiptNumber,
    required this.dateTime,
    required this.items,
    required this.totalPurchase,
    required this.cashReceived,
    required this.change,
    required this.estimatedGrossProfit,
  });

  final String saleId;
  final String businessName;
  final String receiptNumber;
  final DateTime dateTime;
  final List<ReceiptItem> items;
  final double totalPurchase;
  final double cashReceived;
  final double change;
  final double estimatedGrossProfit;

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['sale_items'] ?? const [];
    return Receipt(
      saleId: (json['sale_id'] ?? json['id']).toString(),
      businessName: json['business_name']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString() ?? '',
      dateTime: readDate(json['date_time'] ?? json['created_at']),
      items: [
        for (final item in rawItems as List)
          ReceiptItem.fromJson(readMap(item)),
      ],
      totalPurchase: readDouble(json['total_purchase'] ?? json['total_amount']),
      cashReceived: readDouble(json['cash_received']),
      change: readDouble(json['change'] ?? json['change_amount']),
      estimatedGrossProfit: readDouble(json['estimated_gross_profit']),
    );
  }
}

class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.receiptNumber,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeAmount,
    required this.estimatedGrossProfit,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String receiptNumber;
  final double totalAmount;
  final double cashReceived;
  final double changeAmount;
  final double estimatedGrossProfit;
  final DateTime createdAt;
  final List<ReceiptItem> items;

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  factory SaleSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['sale_items'] ?? const [];
    return SaleSummary(
      id: json['id'].toString(),
      receiptNumber: json['receipt_number']?.toString() ?? '',
      totalAmount: readDouble(json['total_amount']),
      cashReceived: readDouble(json['cash_received']),
      changeAmount: readDouble(json['change_amount']),
      estimatedGrossProfit: readDouble(json['estimated_gross_profit']),
      createdAt: readDate(json['created_at']),
      items: [
        for (final item in rawItems as List)
          ReceiptItem.fromJson(readMap(item)),
      ],
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantityDelta,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String movementType;
  final int quantityDelta;
  final String? reason;
  final DateTime createdAt;

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      movementType: json['movement_type']?.toString() ?? '',
      quantityDelta: readInt(json['quantity_delta']),
      reason: json['reason']?.toString(),
      createdAt: readDate(json['created_at']),
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'].toString(),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString(),
      amount: readDouble(json['amount']),
      expenseDate: DateTime.tryParse(json['expense_date']?.toString() ?? '') ??
          manilaDateOnly(DateTime.now()),
      createdAt: readDate(json['created_at']),
    );
  }
}

class ExpenseInput {
  const ExpenseInput({
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
  });

  final String category;
  final String description;
  final double amount;
  final DateTime expenseDate;

  Map<String, dynamic> toJson(String businessId) {
    return {
      'business_id': businessId,
      'category': category.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'amount': amount,
      'expense_date':
          '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
    };
  }
}

class ChartPoint {
  const ChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class DashboardSummary {
  const DashboardSummary({
    required this.todaySales,
    required this.monthSales,
    required this.transactionCount,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.estimatedGrossProfit,
    required this.recentSales,
    required this.salesChart,
  });

  final double todaySales;
  final double monthSales;
  final int transactionCount;
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double estimatedGrossProfit;
  final List<SaleSummary> recentSales;
  final List<ChartPoint> salesChart;
}

class BestSeller {
  const BestSeller({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.generatedSales,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final double generatedSales;
}

class ReportSummary {
  const ReportSummary({
    required this.salesTotal,
    required this.estimatedGrossProfit,
    required this.expenseTotal,
    required this.estimatedNetProfit,
    required this.transactionCount,
  });

  final double salesTotal;
  final double estimatedGrossProfit;
  final double expenseTotal;
  final double estimatedNetProfit;
  final int transactionCount;
}

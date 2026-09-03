import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class InventoryRepository {
  InventoryRepository(this._client);

  final SupabaseClient _client;

  static const _productSelect = '''
    id,business_id,category_id,name,sku,barcode,cost_price,selling_price,
    stock_quantity,low_stock_threshold,is_active,created_at,updated_at,
    categories(name)
  ''';

  Future<List<Category>> fetchCategories(String businessId) async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('business_id', businessId)
        .order('name') as List<dynamic>;
    return [for (final row in rows) Category.fromJson(readMap(row))];
  }

  Future<List<Product>> fetchProducts(
    String businessId, {
    String search = '',
    bool activeOnly = false,
    bool lowStockOnly = false,
    bool outOfStockOnly = false,
  }) async {
    dynamic query = _client
        .from('products')
        .select(_productSelect)
        .eq('business_id', businessId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final trimmedSearch = search.trim();
    if (trimmedSearch.isNotEmpty) {
      final value = trimmedSearch.replaceAll(',', ' ');
      query = query.or(
        'name.ilike.%$value%,sku.ilike.%$value%,barcode.ilike.%$value%',
      );
    }

    final rows = await query.order('name') as List<dynamic>;
    var products = [for (final row in rows) Product.fromJson(readMap(row))];

    if (lowStockOnly) {
      products = products.where((product) => product.isLowStock).toList();
    }

    if (outOfStockOnly) {
      products = products.where((product) => product.isOutOfStock).toList();
    }

    return products;
  }

  Future<Product> fetchProduct({
    required String businessId,
    required String productId,
  }) async {
    final row = await _client
        .from('products')
        .select(_productSelect)
        .eq('business_id', businessId)
        .eq('id', productId)
        .single();
    return Product.fromJson(readMap(row));
  }

  Future<Product> createProduct({
    required String businessId,
    required ProductInput input,
  }) async {
    final categoryId = await _findOrCreateCategory(
      businessId: businessId,
      name: input.categoryName,
    );

    final row = await _client
        .from('products')
        .insert(input.toJson(businessId: businessId, categoryId: categoryId))
        .select(_productSelect)
        .single();

    return Product.fromJson(readMap(row));
  }

  Future<Product> updateProduct({
    required String businessId,
    required String productId,
    required ProductInput input,
  }) async {
    final categoryId = await _findOrCreateCategory(
      businessId: businessId,
      name: input.categoryName,
    );

    final row = await _client
        .from('products')
        .update(
          input.toJson(
            businessId: businessId,
            categoryId: categoryId,
            includeStock: false,
          ),
        )
        .eq('business_id', businessId)
        .eq('id', productId)
        .select(_productSelect)
        .single();

    return Product.fromJson(readMap(row));
  }

  Future<void> setProductActive({
    required String businessId,
    required String productId,
    required bool isActive,
  }) async {
    await _client
        .from('products')
        .update({'is_active': isActive})
        .eq('business_id', businessId)
        .eq('id', productId);
  }

  Future<void> restockProduct({
    required String businessId,
    required String productId,
    required int quantity,
    required String reason,
  }) async {
    await _client.rpc(
      'restock_product',
      params: {
        'p_business_id': businessId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_reason': reason,
      },
    );
  }

  Future<List<StockMovement>> fetchStockMovements({
    required String businessId,
    String? productId,
  }) async {
    dynamic query =
        _client.from('stock_movements').select().eq('business_id', businessId);

    if (productId != null) {
      query = query.eq('product_id', productId);
    }

    final rows = await query.order('created_at', ascending: false).limit(100)
        as List<dynamic>;
    return [for (final row in rows) StockMovement.fromJson(readMap(row))];
  }

  Future<String?> _findOrCreateCategory({
    required String businessId,
    required String name,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return null;

    final existingRows = await _client
        .from('categories')
        .select()
        .eq('business_id', businessId)
        .ilike('name', cleanedName)
        .limit(1) as List<dynamic>;

    if (existingRows.isNotEmpty) {
      return existingRows.first['id'].toString();
    }

    final row = await _client
        .from('categories')
        .insert({'business_id': businessId, 'name': cleanedName})
        .select()
        .single();
    return row['id'].toString();
  }
}

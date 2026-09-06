import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'repository_helpers.dart';

class InventoryRepository {
  InventoryRepository(this._client);

  final SupabaseClient _client;

  static const _productSelect = '''
    id,business_id,category_id,name,sku,barcode,cost_price,selling_price,
    stock_quantity,low_stock_threshold,is_active,created_at,updated_at,
    categories(name)
  ''';

  Future<List<Category>> fetchCategories(String businessId) async {
    return mapRows(
      _client.selectBusinessRows('categories', businessId: businessId).order(
            'name',
          ),
      Category.fromJson,
    );
  }

  Future<List<Product>> fetchProducts(
    String businessId, {
    String search = '',
    bool activeOnly = false,
    bool lowStockOnly = false,
    bool outOfStockOnly = false,
  }) async {
    var query = _client.selectBusinessRows(
      'products',
      businessId: businessId,
      columns: _productSelect,
    );

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final trimmedSearch = search.trim();
    if (trimmedSearch.isNotEmpty) {
      query = query.or(
        ilikeAnyFilter(
          columns: const ['name', 'sku', 'barcode'],
          value: trimmedSearch,
        ),
      );
    }

    var products = await mapRows(query.order('name'), Product.fromJson);

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
    return mapSingleRow(
      _client
          .selectBusinessRows(
            'products',
            businessId: businessId,
            columns: _productSelect,
          )
          .eq('id', productId)
          .single(),
      Product.fromJson,
    );
  }

  Future<Product> createProduct({
    required String businessId,
    required ProductInput input,
  }) async {
    final categoryId = await _findOrCreateCategory(
      businessId: businessId,
      name: input.categoryName,
    );

    return mapSingleRow(
      _client
          .from('products')
          .insert(input.toJson(businessId: businessId, categoryId: categoryId))
          .select(_productSelect)
          .single(),
      Product.fromJson,
    );
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

    return mapSingleRow(
      _client
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
          .single(),
      Product.fromJson,
    );
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
    var query = _client.selectBusinessRows(
      'stock_movements',
      businessId: businessId,
    );

    if (productId != null) {
      query = query.eq('product_id', productId);
    }

    return mapRows(
      query.order('created_at', ascending: false).limit(100),
      StockMovement.fromJson,
    );
  }

  Future<String?> _findOrCreateCategory({
    required String businessId,
    required String name,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return null;

    final existingRows = await _client
        .selectBusinessRows('categories', businessId: businessId)
        .ilike('name', cleanedName)
        .limit(1);

    if (existingRows.isNotEmpty) {
      return existingRows.first['id'].toString();
    }

    final category = await _client
        .from('categories')
        .insert({'business_id': businessId, 'name': cleanedName})
        .select()
        .single();
    return category['id'].toString();
  }
}

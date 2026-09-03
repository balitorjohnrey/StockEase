import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';

enum _InventoryFilter { all, active, lowStock, outOfStock }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  var _filter = _InventoryFilter.active;
  Future<List<Product>>? _products;

  @override
  void initState() {
    super.initState();
    _search.addListener(_reload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??= _load();
  }

  @override
  void dispose() {
    _search.removeListener(_reload);
    _search.dispose();
    super.dispose();
  }

  Future<List<Product>> _load() {
    return context.appState.inventory.fetchProducts(
      context.appState.businessId,
      search: _search.text,
      activeOnly: _filter != _InventoryFilter.all,
      lowStockOnly: _filter == _InventoryFilter.lowStock,
      outOfStockOnly: _filter == _InventoryFilter.outOfStock,
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _products = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _products,
      builder: (context, snapshot) {
        return ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                title: 'Inventory',
                subtitle: 'Search by product name, SKU, or barcode.',
                trailing: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductFormScreen(),
                      ),
                    );
                    _reload();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        labelText: 'Search inventory',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: _search.clear,
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  SegmentedButton<_InventoryFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _InventoryFilter.active,
                        icon: Icon(Icons.check_circle_outline),
                        label: Text('Active'),
                      ),
                      ButtonSegment(
                        value: _InventoryFilter.all,
                        icon: Icon(Icons.list_alt),
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: _InventoryFilter.lowStock,
                        icon: Icon(Icons.warning_amber_outlined),
                        label: Text('Low'),
                      ),
                      ButtonSegment(
                        value: _InventoryFilter.outOfStock,
                        icon: Icon(Icons.remove_shopping_cart_outlined),
                        label: Text('Out'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) {
                      setState(() {
                        _filter = value.first;
                        _products = _load();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }
                    if (snapshot.hasError) {
                      return ErrorState(
                          error: snapshot.error!, onRetry: _reload);
                    }
                    final products = snapshot.data ?? const <Product>[];
                    if (products.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products found',
                        message: 'Add products or adjust the search/filter.',
                        action: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProductFormScreen(),
                              ),
                            );
                            _reload();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add product'),
                        ),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width >= 1200
                            ? 3
                            : width >= 760
                                ? 2
                                : 1;
                        return GridView.builder(
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: width < 520 ? 1.18 : 1.55,
                          ),
                          itemBuilder: (context, index) {
                            return _ProductCard(
                              product: products[index],
                              onChanged: _reload,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onChanged});

  final Product product;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(productId: product.id),
            ),
          );
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.categoryName ?? 'Uncategorized',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!product.isActive)
                    const Icon(Icons.visibility_off, color: AppTheme.muted),
                ],
              ),
              const SizedBox(height: 12),
              StockBadge(
                quantity: product.stockQuantity,
                threshold: product.lowStockThreshold,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoPill(
                      label: 'Selling',
                      value: formatMoney(product.sellingPrice)),
                  _InfoPill(
                      label: 'Cost', value: formatMoney(product.costPrice)),
                  if ((product.sku ?? '').isNotEmpty)
                    _InfoPill(label: 'SKU', value: product.sku!),
                  if ((product.barcode ?? '').isNotEmpty)
                    _InfoPill(label: 'Barcode', value: product.barcode!),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(product: product),
                        ),
                      );
                      onChanged();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: product.isActive
                        ? () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RestockProductScreen(
                                  product: product,
                                ),
                              ),
                            );
                            onChanged();
                          }
                        : null,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Restock'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({this.product, super.key});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _cost;
  late final TextEditingController _selling;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;
  late bool _active;
  var _saving = false;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _category = TextEditingController(text: product?.categoryName ?? '');
    _sku = TextEditingController(text: product?.sku ?? '');
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _cost = TextEditingController(
      text: product == null ? '' : product.costPrice.toStringAsFixed(2),
    );
    _selling = TextEditingController(
      text: product == null ? '' : product.sellingPrice.toStringAsFixed(2),
    );
    _stock =
        TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    _threshold = TextEditingController(
      text: product?.lowStockThreshold.toString() ?? '5',
    );
    _active = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _sku.dispose();
    _barcode.dispose();
    _cost.dispose();
    _selling.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit product' : 'Add product')),
      body: SingleChildScrollView(
        child: ScreenPadding(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: _editing ? 'Product details' : 'New product',
                  subtitle: _editing
                      ? 'Price changes affect new sales only.'
                      : 'Initial stock is saved with the product.',
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _field(
                          controller: _name,
                          label: 'Product name',
                          icon: Icons.shopping_bag_outlined,
                          validator: _required,
                          width: wide ? 360 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _category,
                          label: 'Category',
                          icon: Icons.category_outlined,
                          width: wide ? 280 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _sku,
                          label: 'SKU',
                          icon: Icons.tag,
                          width: wide ? 220 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _barcode,
                          label: 'Barcode',
                          icon: Icons.qr_code_2,
                          width: wide ? 220 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _cost,
                          label: 'Cost price',
                          icon: Icons.price_change_outlined,
                          keyboardType: TextInputType.number,
                          validator: _nonNegativeMoney,
                          width: wide ? 220 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _selling,
                          label: 'Selling price',
                          icon: Icons.sell_outlined,
                          keyboardType: TextInputType.number,
                          validator: _nonNegativeMoney,
                          width: wide ? 220 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _stock,
                          label: 'Current stock quantity',
                          icon: Icons.inventory_outlined,
                          keyboardType: TextInputType.number,
                          enabled: !_editing,
                          validator: _nonNegativeInt,
                          width: wide ? 240 : constraints.maxWidth,
                        ),
                        _field(
                          controller: _threshold,
                          label: 'Low-stock threshold',
                          icon: Icons.warning_amber_outlined,
                          keyboardType: TextInputType.number,
                          validator: _nonNegativeInt,
                          width: wide ? 240 : constraints.maxWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active product'),
                  subtitle:
                      const Text('Inactive products are hidden from checkout.'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_editing ? 'Save changes' : 'Create product'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    double? width,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final input = ProductInput(
      name: _name.text,
      categoryName: _category.text,
      sku: _sku.text,
      barcode: _barcode.text,
      costPrice: double.parse(_cost.text),
      sellingPrice: double.parse(_selling.text),
      stockQuantity: int.parse(_stock.text),
      lowStockThreshold: int.parse(_threshold.text),
      isActive: _active,
    );

    try {
      final state = context.appState;
      if (_editing) {
        await state.inventory.updateProduct(
          businessId: state.businessId,
          productId: widget.product!.id,
          input: input,
        );
      } else {
        await state.inventory.createProduct(
          businessId: state.businessId,
          input: input,
        );
      }
      if (mounted) {
        showAppSnackBar(
            context, _editing ? 'Product updated.' : 'Product added.');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'Required.' : null;
  }

  String? _nonNegativeMoney(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return 'Enter a valid amount.';
    if (parsed < 0) return 'Price cannot be negative.';
    return null;
  }

  String? _nonNegativeInt(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return 'Enter a whole number.';
    if (parsed < 0) return 'Quantity cannot be negative.';
    return null;
  }
}

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({required this.productId, super.key});

  final String productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Future<Product>? _product;
  Future<List<StockMovement>>? _movements;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _product ??= _loadProduct();
    _movements ??= _loadMovements();
  }

  Future<Product> _loadProduct() {
    final state = context.appState;
    return state.inventory.fetchProduct(
      businessId: state.businessId,
      productId: widget.productId,
    );
  }

  Future<List<StockMovement>> _loadMovements() {
    final state = context.appState;
    return state.inventory.fetchStockMovements(
      businessId: state.businessId,
      productId: widget.productId,
    );
  }

  void _refresh() {
    setState(() {
      _product = _loadProduct();
      _movements = _loadMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _product,
      builder: (context, snapshot) {
        final product = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(product?.name ?? 'Product details'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const LoadingState()
              : snapshot.hasError
                  ? ErrorState(error: snapshot.error!, onRetry: _refresh)
                  : _ProductDetailsBody(
                      product: product!,
                      movements: _movements!,
                      onRefresh: _refresh,
                    ),
        );
      },
    );
  }
}

class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody({
    required this.product,
    required this.movements,
    required this.onRefresh,
  });

  final Product product;
  final Future<List<StockMovement>> movements;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                title: product.name,
                subtitle: product.categoryName ?? 'Uncategorized',
                trailing: StockBadge(
                  quantity: product.stockQuantity,
                  threshold: product.lowStockThreshold,
                ),
              ),
              const SizedBox(height: 18),
              ResponsiveCards(
                children: [
                  MetricCard(
                    title: 'Selling price',
                    value: formatMoney(product.sellingPrice),
                    icon: Icons.sell_outlined,
                  ),
                  MetricCard(
                    title: 'Cost price',
                    value: formatMoney(product.costPrice),
                    icon: Icons.price_change_outlined,
                    color: AppTheme.secondary,
                  ),
                  MetricCard(
                    title: 'Current stock',
                    value: product.stockQuantity.toString(),
                    icon: Icons.inventory_outlined,
                  ),
                  MetricCard(
                    title: 'Inventory value',
                    value: formatMoney(product.estimatedInventoryValue),
                    icon: Icons.savings_outlined,
                    color: AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RestockProductScreen(product: product),
                        ),
                      );
                      onRefresh();
                    },
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Restock'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(product: product),
                        ),
                      );
                      onRefresh();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit product'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final state = context.appState;
                      await state.inventory.setProductActive(
                        businessId: state.businessId,
                        productId: product.id,
                        isActive: !product.isActive,
                      );
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          product.isActive
                              ? 'Product deactivated.'
                              : 'Product activated.',
                        );
                      }
                      onRefresh();
                    },
                    icon: Icon(
                      product.isActive
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    label: Text(product.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Stock movement history',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              FutureBuilder<List<StockMovement>>(
                future: movements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return ErrorState(
                        error: snapshot.error!, onRetry: onRefresh);
                  }
                  final rows = snapshot.data ?? const <StockMovement>[];
                  if (rows.isEmpty) {
                    return const EmptyState(
                      icon: Icons.history,
                      title: 'No stock movements',
                      message: 'Sales and restocks will be listed here.',
                    );
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (final movement in rows)
                          ListTile(
                            leading: Icon(
                              movement.quantityDelta >= 0
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              color: movement.quantityDelta >= 0
                                  ? AppTheme.success
                                  : AppTheme.danger,
                            ),
                            title: Text(
                              '${movement.movementType} ${movement.quantityDelta > 0 ? '+' : ''}${movement.quantityDelta}',
                            ),
                            subtitle: Text(
                              '${movement.reason ?? 'No note'}\n${formatManilaDateTime(movement.createdAt)}',
                            ),
                            isThreeLine: true,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RestockProductScreen extends StatefulWidget {
  const RestockProductScreen({required this.product, super.key});

  final Product product;

  @override
  State<RestockProductScreen> createState() => _RestockProductScreenState();
}

class _RestockProductScreenState extends State<RestockProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController(text: 'Manual restock');
  var _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restock product')),
      body: SingleChildScrollView(
        child: ScreenPadding(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: widget.product.name,
                  subtitle: 'Current stock: ${widget.product.stockQuantity}',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Quantity to add',
                    prefixIcon: Icon(Icons.add_box_outlined),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a quantity greater than zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reason,
                  decoration: const InputDecoration(
                    labelText: 'Reason or note',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save restock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final state = context.appState;
      await state.inventory.restockProduct(
        businessId: state.businessId,
        productId: widget.product.id,
        quantity: int.parse(_quantity.text),
        reason: _reason.text,
      );
      if (mounted) {
        showAppSnackBar(context, 'Product restocked.');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class LowStockProductsScreen extends StatefulWidget {
  const LowStockProductsScreen({super.key});

  @override
  State<LowStockProductsScreen> createState() => _LowStockProductsScreenState();
}

class _LowStockProductsScreenState extends State<LowStockProductsScreen> {
  Future<List<Product>>? _products;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??= _load();
  }

  Future<List<Product>> _load() {
    return context.appState.inventory.fetchProducts(
      context.appState.businessId,
      activeOnly: true,
    );
  }

  void _refresh() {
    setState(() => _products = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low-stock products')),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error!, onRetry: _refresh);
          }
          final products = (snapshot.data ?? const <Product>[])
              .where((product) => product.isLowStock || product.isOutOfStock)
              .toList()
            ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'Stock levels look good',
              message: 'Low-stock and out-of-stock products will appear here.',
            );
          }

          return ListView(
            children: [
              ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Stock alerts',
                      subtitle: 'Restock directly from this list.',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          for (final product in products)
                            ListTile(
                              leading: Icon(
                                product.isOutOfStock
                                    ? Icons.remove_shopping_cart_outlined
                                    : Icons.warning_amber_outlined,
                                color: product.isOutOfStock
                                    ? AppTheme.danger
                                    : AppTheme.warning,
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                '${product.categoryName ?? 'Uncategorized'} • Threshold ${product.lowStockThreshold}',
                              ),
                              trailing: FilledButton.icon(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestockProductScreen(
                                        product: product,
                                      ),
                                    ),
                                  );
                                  _refresh();
                                },
                                icon: const Icon(Icons.add_box_outlined),
                                label: Text(product.stockQuantity.toString()),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

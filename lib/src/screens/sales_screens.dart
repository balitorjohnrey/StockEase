import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _search = TextEditingController();
  final Map<String, CartLine> _cart = {};
  Future<List<Product>>? _products;

  double get _total => _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _search.addListener(_reload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??= _loadProducts();
  }

  @override
  void dispose() {
    _search.removeListener(_reload);
    _search.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() {
    return context.appState.inventory.fetchProducts(
      context.appState.businessId,
      search: _search.text,
      activeOnly: true,
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _products = _loadProducts());
  }

  void _addProduct(Product product) {
    final current = _cart[product.id]?.quantity ?? 0;
    if (product.stockQuantity <= current) {
      showAppSnackBar(
        context,
        'Insufficient stock. Only ${product.stockQuantity} item(s) are available.',
        isError: true,
      );
      return;
    }
    setState(() {
      _cart[product.id] = CartLine(product: product, quantity: current + 1);
    });
  }

  void _setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      setState(() => _cart.remove(product.id));
      return;
    }
    if (quantity > product.stockQuantity) {
      showAppSnackBar(
        context,
        'Insufficient stock. Only ${product.stockQuantity} item(s) are available.',
        isError: true,
      );
      return;
    }
    setState(() =>
        _cart[product.id] = CartLine(product: product, quantity: quantity));
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(items: _cart.values.toList()),
      ),
    );
    if (completed == true) {
      setState(_cart.clear);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenPadding(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final productsPanel = _ProductsForSalePanel(
            products: _products,
            search: _search,
            onRetry: _reload,
            onAdd: _addProduct,
            cartQuantities: {
              for (final entry in _cart.entries)
                entry.key: entry.value.quantity,
            },
          );
          final cartPanel = _CartPanel(
            items: _cart.values.toList(),
            total: _total,
            onDecrease: (line) => _setQuantity(line.product, line.quantity - 1),
            onIncrease: (line) => _setQuantity(line.product, line.quantity + 1),
            onRemove: (line) => _setQuantity(line.product, 0),
            onClear: _cart.isEmpty ? null : () => setState(_cart.clear),
            onCheckout: _cart.isEmpty ? null : _checkout,
          );

          if (!wide) {
            return Column(
              children: [
                const SectionTitle(
                  title: 'New sale',
                  subtitle: 'Build the customer cart and continue to checkout.',
                ),
                const SizedBox(height: 14),
                Expanded(child: productsPanel),
                const SizedBox(height: 12),
                SizedBox(
                  height: constraints.maxHeight * 0.42,
                  child: cartPanel,
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'New sale',
                subtitle: 'Build the customer cart and continue to checkout.',
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: productsPanel),
                    const SizedBox(width: 14),
                    SizedBox(width: 390, child: cartPanel),
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

class _ProductsForSalePanel extends StatelessWidget {
  const _ProductsForSalePanel({
    required this.products,
    required this.search,
    required this.onRetry,
    required this.onAdd,
    required this.cartQuantities,
  });

  final Future<List<Product>>? products;
  final TextEditingController search;
  final VoidCallback onRetry;
  final ValueChanged<Product> onAdd;
  final Map<String, int> cartQuantities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: search,
          decoration: InputDecoration(
            labelText: 'Search products',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: search.clear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ErrorState(error: snapshot.error!, onRetry: onRetry);
              }
              final rows = snapshot.data ?? const <Product>[];
              if (rows.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'No products available',
                  message: 'Active products with stock appear here.',
                );
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product = rows[index];
                  final inCart = cartQuantities[product.id] ?? 0;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.14),
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.categoryName ?? 'Uncategorized'} • Stock ${product.stockQuantity}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            formatMoney(product.sellingPrice),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          IconButton.filled(
                            tooltip: 'Add to cart',
                            onPressed: product.stockQuantity > inCart
                                ? () => onAdd(product)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.items,
    required this.total,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
  });

  final List<CartLine> items;
  final double total;
  final ValueChanged<CartLine> onDecrease;
  final ValueChanged<CartLine> onIncrease;
  final ValueChanged<CartLine> onRemove;
  final VoidCallback? onClear;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Customer cart',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear cart',
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Cart is empty',
                  message: 'Select products to start a transaction.',
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final line = items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                line.product.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => onRemove(line),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(formatMoney(line.product.sellingPrice)),
                            const Spacer(),
                            IconButton.outlined(
                              tooltip: 'Decrease quantity',
                              onPressed: () => onDecrease(line),
                              icon: const Icon(Icons.remove),
                            ),
                            SizedBox(
                              width: 44,
                              child: Center(
                                child: Text(
                                  line.quantity.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            IconButton.filled(
                              tooltip: 'Increase quantity',
                              onPressed:
                                  line.quantity < line.product.stockQuantity
                                      ? () => onIncrease(line)
                                      : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Subtotal ${formatMoney(line.subtotal)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(
                  formatMoney(total),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Checkout'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({required this.items, super.key});

  final List<CartLine> items;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cash = TextEditingController();
  var _submitting = false;

  double get _total => widget.items.fold(0, (sum, line) => sum + line.subtotal);

  double get _cashReceived => double.tryParse(_cash.text.trim()) ?? 0;

  double get _change => _cashReceived - _total;

  @override
  void initState() {
    super.initState();
    _cash.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canComplete =
        !_submitting && widget.items.isNotEmpty && _cashReceived >= _total;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        children: [
          ScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: 'Checkout',
                  subtitle:
                      'Server will recheck prices and stock before saving.',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      for (final line in widget.items)
                        ListTile(
                          title: Text(line.product.name),
                          subtitle: Text(
                            '${formatMoney(line.product.sellingPrice)} x ${line.quantity}',
                          ),
                          trailing: MoneyText(line.subtotal),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cash,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cash received',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                ResponsiveCards(
                  children: [
                    MetricCard(
                      title: 'Total purchase',
                      value: formatMoney(_total),
                      icon: Icons.shopping_cart_checkout,
                    ),
                    MetricCard(
                      title: 'Cash received',
                      value: formatMoney(_cashReceived),
                      icon: Icons.payments_outlined,
                      color: AppTheme.secondary,
                    ),
                    MetricCard(
                      title: 'Change',
                      value: formatMoney(_change < 0 ? 0 : _change),
                      icon: Icons.price_check,
                      color: _change < 0 ? AppTheme.warning : AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: canComplete ? _completeSale : null,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Complete purchase'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Back to cart'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final state = context.appState;
      final receipt = await state.sales.completeSale(
        businessId: state.businessId,
        items: widget.items,
        cashReceived: _cashReceived,
      );
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: receipt)),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
        setState(() => _submitting = false);
      }
    }
  }
}

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({required this.receipt, super.key});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: ListView(
        children: [
          ScreenPadding(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          receipt.businessName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          receipt.receiptNumber,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatManilaDateTime(receipt.dateTime),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 28),
                        for (final item in receipt.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${formatMoney(item.unitPrice)} x ${item.quantity}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(formatMoney(item.subtotal)),
                              ],
                            ),
                          ),
                        const Divider(height: 28),
                        _ReceiptTotalRow(
                            'Total purchase', receipt.totalPurchase),
                        _ReceiptTotalRow('Cash received', receipt.cashReceived),
                        _ReceiptTotalRow('Change', receipt.change),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('New sale'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SaleDetailsScreen(
                                    saleId: receipt.saleId,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('View transaction'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotalRow extends StatelessWidget {
  const _ReceiptTotalRow(this.label, this.value);

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            formatMoney(value),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _search = TextEditingController();
  DateTimeRange? _range;
  Future<List<SaleSummary>>? _sales;

  @override
  void initState() {
    super.initState();
    _search.addListener(_reload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sales ??= _load();
  }

  @override
  void dispose() {
    _search.removeListener(_reload);
    _search.dispose();
    super.dispose();
  }

  Future<List<SaleSummary>> _load() {
    final from = _range == null ? null : manilaDayStartUtc(_range!.start);
    final to = _range == null
        ? null
        : manilaDayStartUtc(_range!.end).add(const Duration(days: 1));
    return context.appState.sales.fetchSales(
      context.appState.businessId,
      search: _search.text,
      fromUtc: from,
      toUtc: to,
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _sales = _load());
  }

  @override
  Widget build(BuildContext context) {
    return ScreenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Sales history',
            subtitle: 'Search by receipt number, product, or date range.',
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: 'Search sales',
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
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _range == null
                      ? 'Date filter'
                      : '${formatManilaDate(_range!.start)} to ${formatManilaDate(_range!.end)}',
                ),
              ),
              if (_range != null)
                IconButton.outlined(
                  tooltip: 'Clear date filter',
                  onPressed: () {
                    setState(() {
                      _range = null;
                      _sales = _load();
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SaleSummary>>(
              future: _sales,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  return ErrorState(error: snapshot.error!, onRetry: _reload);
                }
                final rows = snapshot.data ?? const <SaleSummary>[];
                if (rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No sales found',
                    message: 'Completed transactions will be listed here.',
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sale = rows[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(sale.receiptNumber),
                        subtitle: Text(
                          '${formatManilaDateTime(sale.createdAt)} • ${formatQuantity(sale.itemCount)}',
                        ),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _sales = _load();
      });
    }
  }
}

class SaleDetailsScreen extends StatefulWidget {
  const SaleDetailsScreen({required this.saleId, super.key});

  final String saleId;

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  Future<Receipt>? _receipt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _receipt ??= _load();
  }

  Future<Receipt> _load() {
    final state = context.appState;
    return state.sales.fetchReceipt(
      businessId: state.businessId,
      saleId: widget.saleId,
      businessName: state.business?.name ?? '',
    );
  }

  void _refresh() {
    setState(() => _receipt = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Receipt>(
        future: _receipt,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error!, onRetry: _refresh);
          }
          final receipt = snapshot.data!;
          return ListView(
            children: [
              ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: receipt.receiptNumber,
                      subtitle: formatManilaDateTime(receipt.dateTime),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          for (final item in receipt.items)
                            ListTile(
                              title: Text(item.productName),
                              subtitle: Text(
                                '${formatMoney(item.unitPrice)} x ${item.quantity}',
                              ),
                              trailing: MoneyText(item.subtotal),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ResponsiveCards(
                      children: [
                        MetricCard(
                          title: 'Total purchase',
                          value: formatMoney(receipt.totalPurchase),
                          icon: Icons.shopping_cart_checkout,
                        ),
                        MetricCard(
                          title: 'Cash received',
                          value: formatMoney(receipt.cashReceived),
                          icon: Icons.payments_outlined,
                          color: AppTheme.secondary,
                        ),
                        MetricCard(
                          title: 'Change',
                          value: formatMoney(receipt.change),
                          icon: Icons.price_check,
                          color: AppTheme.success,
                        ),
                        MetricCard(
                          title: 'Estimated gross profit',
                          value: formatMoney(receipt.estimatedGrossProfit),
                          icon: Icons.trending_up,
                          color: AppTheme.success,
                        ),
                      ],
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

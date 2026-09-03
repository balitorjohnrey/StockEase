import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/models.dart';
import '../repositories/sales_repository.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';
import 'inventory_screens.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Future<ReportSummary>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _summary ??= _load();
  }

  Future<ReportSummary> _load() {
    final state = context.appState;
    return state.sales.fetchReportSummary(
      businessId: state.businessId,
      expensesRepository: state.expenses,
    );
  }

  void _refresh() {
    setState(() => _summary = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error!, onRetry: _refresh);
        }
        final summary = snapshot.data!;
        return ListView(
          children: [
            ScreenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    title: 'Reports',
                    subtitle: 'Monthly performance and estimated profit.',
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
                        title: 'Sales total',
                        value: formatMoney(summary.salesTotal),
                        icon: Icons.payments_outlined,
                      ),
                      MetricCard(
                        title: 'Transactions',
                        value: summary.transactionCount.toString(),
                        icon: Icons.receipt_long_outlined,
                        color: AppTheme.secondary,
                      ),
                      MetricCard(
                        title: 'Estimated gross profit',
                        value: formatMoney(summary.estimatedGrossProfit),
                        icon: Icons.trending_up,
                        color: AppTheme.success,
                        subtitle: 'Uses sale-item cost and price snapshots.',
                      ),
                      MetricCard(
                        title: 'Expenses',
                        value: formatMoney(summary.expenseTotal),
                        icon: Icons.request_quote_outlined,
                        color: AppTheme.warning,
                      ),
                      MetricCard(
                        title: 'Estimated net profit',
                        value: formatMoney(summary.estimatedNetProfit),
                        icon: Icons.account_balance_wallet_outlined,
                        color: summary.estimatedNetProfit >= 0
                            ? AppTheme.success
                            : AppTheme.danger,
                        subtitle: 'Estimate may exclude unrecorded costs.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BestSellingProductsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.leaderboard_outlined),
                        label: const Text('Best sellers'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ExpensesScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.request_quote_outlined),
                        label: const Text('Expenses'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LowStockProductsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.warning_amber_outlined),
                        label: const Text('Low stock'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _ReportNote(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportNote extends StatelessWidget {
  const _ReportNote();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Profit values are estimates. They use cost-price snapshots '
                'saved at checkout and subtract recorded expenses only.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BestSellingProductsScreen extends StatefulWidget {
  const BestSellingProductsScreen({super.key});

  @override
  State<BestSellingProductsScreen> createState() =>
      _BestSellingProductsScreenState();
}

class _BestSellingProductsScreenState extends State<BestSellingProductsScreen> {
  var _range = BestSellerRange.month;
  Future<List<BestSeller>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<BestSeller>> _load() {
    return context.appState.sales.fetchBestSellers(
      businessId: context.appState.businessId,
      range: _range,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Best-selling products')),
      body: FutureBuilder<List<BestSeller>>(
        future: _future,
        builder: (context, snapshot) {
          return ListView(
            children: [
              ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'Best sellers',
                      subtitle: 'Ranked by total quantity sold.',
                      trailing: IconButton(
                        tooltip: 'Refresh',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<BestSellerRange>(
                      segments: const [
                        ButtonSegment(
                          value: BestSellerRange.today,
                          icon: Icon(Icons.today),
                          label: Text('Daily'),
                        ),
                        ButtonSegment(
                          value: BestSellerRange.week,
                          icon: Icon(Icons.view_week_outlined),
                          label: Text('Weekly'),
                        ),
                        ButtonSegment(
                          value: BestSellerRange.month,
                          icon: Icon(Icons.calendar_month_outlined),
                          label: Text('Monthly'),
                        ),
                        ButtonSegment(
                          value: BestSellerRange.allTime,
                          icon: Icon(Icons.all_inclusive),
                          label: Text('All time'),
                        ),
                      ],
                      selected: {_range},
                      onSelectionChanged: (value) {
                        setState(() {
                          _range = value.first;
                          _future = _load();
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(height: 260, child: LoadingState())
                    else if (snapshot.hasError)
                      ErrorState(error: snapshot.error!, onRetry: _reload)
                    else
                      _BestSellerResults(rows: snapshot.data ?? const []),
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

class _BestSellerResults extends StatelessWidget {
  const _BestSellerResults({required this.rows});

  final List<BestSeller> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'No best sellers yet',
        message: 'Completed sales will build this ranking.',
      );
    }

    final chartRows = [
      for (final row in rows.take(6))
        ChartPoint(label: row.productName, value: row.quantitySold.toDouble()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final chart = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantity sold',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                SimpleBarChart(
                  points: chartRows,
                  valueFormatter: (value) => value.toInt().toString(),
                ),
              ],
            ),
          ),
        );
        final list = Card(
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++)
                ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(rows[index].productName),
                  subtitle: Text('${rows[index].quantitySold} sold'),
                  trailing: MoneyText(rows[index].generatedSales),
                ),
            ],
          ),
        );

        if (!wide) {
          return Column(children: [chart, const SizedBox(height: 14), list]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: chart),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: list),
          ],
        );
      },
    );
  }
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  Future<List<Expense>>? _expenses;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expenses ??= _load();
  }

  Future<List<Expense>> _load() {
    return context.appState.expenses.fetchExpenses(context.appState.businessId);
  }

  void _reload() {
    setState(() => _expenses = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: FutureBuilder<List<Expense>>(
        future: _expenses,
        builder: (context, snapshot) {
          return ScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: 'Expenses',
                  subtitle: 'Record costs for better profit estimates.',
                  trailing: FilledButton.icon(
                    onPressed: _showExpenseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add expense'),
                  ),
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
                      final rows = snapshot.data ?? const <Expense>[];
                      if (rows.isEmpty) {
                        return EmptyState(
                          icon: Icons.request_quote_outlined,
                          title: 'No expenses recorded',
                          message:
                              'Add rent, supplies, payroll, or other costs.',
                          action: FilledButton.icon(
                            onPressed: _showExpenseDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add expense'),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final expense = rows[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.request_quote_outlined),
                              title: Text(expense.category),
                              subtitle: Text(
                                '${expense.description ?? 'No description'} • ${formatManilaDate(expense.expenseDate)}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  MoneyText(
                                    expense.amount,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    tooltip: 'Delete expense',
                                    onPressed: () => _deleteExpense(expense),
                                    icon: const Icon(Icons.delete_outline),
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _showExpenseDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExpenseDialog(),
    );
    if (added == true) _reload();
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      final state = context.appState;
      await state.expenses.deleteExpense(
        businessId: state.businessId,
        expenseId: expense.id,
      );
      if (mounted) {
        showAppSnackBar(context, 'Expense deleted.');
        _reload();
      }
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    }
  }
}

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog();

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = manilaNow();
  var _saving = false;

  @override
  void dispose() {
    _category.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Required.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Enter a valid amount.';
                  if (parsed < 0) return 'Amount cannot be negative.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(DateTime.now().year - 3),
                    lastDate: DateTime(DateTime.now().year + 1),
                    initialDate: _date,
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                icon: const Icon(Icons.today),
                label: Text(formatManilaDate(_date)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final state = context.appState;
      await state.expenses.addExpense(
        businessId: state.businessId,
        input: ExpenseInput(
          category: _category.text,
          description: _description.text,
          amount: double.parse(_amount.text),
          expenseDate: _date,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
        setState(() => _saving = false);
      }
    }
  }
}

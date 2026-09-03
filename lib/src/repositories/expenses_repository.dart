import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class ExpensesRepository {
  ExpensesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Expense>> fetchExpenses(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    dynamic query =
        _client.from('expenses').select().eq('business_id', businessId);

    if (from != null) {
      query = query.gte(_expenseDateColumn, _dateOnly(from));
    }
    if (to != null) {
      query = query.lte(_expenseDateColumn, _dateOnly(to));
    }

    final rows =
        await query.order('expense_date', ascending: false) as List<dynamic>;
    return [for (final row in rows) Expense.fromJson(readMap(row))];
  }

  Future<Expense> addExpense({
    required String businessId,
    required ExpenseInput input,
  }) async {
    final row = await _client
        .from('expenses')
        .insert(input.toJson(businessId))
        .select()
        .single();
    return Expense.fromJson(readMap(row));
  }

  Future<void> deleteExpense({
    required String businessId,
    required String expenseId,
  }) async {
    await _client
        .from('expenses')
        .delete()
        .eq('business_id', businessId)
        .eq('id', expenseId);
  }

  static const _expenseDateColumn = 'expense_date';

  String _dateOnly(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

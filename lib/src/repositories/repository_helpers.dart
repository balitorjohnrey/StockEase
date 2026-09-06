import 'package:supabase_flutter/supabase_flutter.dart';

typedef RowMapper<T> = T Function(PostgrestMap row);

extension SupabaseRepositoryQueries on SupabaseClient {
  PostgrestFilterBuilder<PostgrestList> selectRows(
    String table, {
    String columns = '*',
  }) {
    return from(table).select(columns);
  }

  PostgrestFilterBuilder<PostgrestList> selectBusinessRows(
    String table, {
    required String businessId,
    String columns = '*',
  }) {
    return selectRows(table, columns: columns).eq('business_id', businessId);
  }
}

Future<List<T>> mapRows<T>(
  Future<PostgrestList> request,
  RowMapper<T> mapper,
) async {
  final rows = await request;
  return [for (final row in rows) mapper(row)];
}

Future<T> mapSingleRow<T>(
  Future<PostgrestMap> request,
  RowMapper<T> mapper,
) async {
  final row = await request;
  return mapper(row);
}

String ilikeContainsPattern(String value, {bool replaceCommas = false}) {
  final trimmed = value.trim();
  final normalized = replaceCommas ? trimmed.replaceAll(',', ' ') : trimmed;
  return '%$normalized%';
}

String ilikeAnyFilter({
  required Iterable<String> columns,
  required String value,
}) {
  final pattern = ilikeContainsPattern(value, replaceCommas: true);
  return columns.map((column) => '$column.ilike.$pattern').join(',');
}

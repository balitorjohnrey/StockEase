const _peso = '\u20b1';
const _manilaOffset = Duration(hours: 8);

String formatMoney(num value) {
  final amount = value.isFinite ? value : 0;
  return '$_peso${amount.toStringAsFixed(2)}';
}

String formatQuantity(int value) {
  return value == 1 ? '1 item' : '$value items';
}

DateTime toManila(DateTime value) {
  return value.toUtc().add(_manilaOffset);
}

DateTime manilaNow() {
  return toManila(DateTime.now());
}

DateTime manilaDayStartUtc([DateTime? date]) {
  final local = date == null ? manilaNow() : toManila(date);
  return DateTime.utc(local.year, local.month, local.day)
      .subtract(_manilaOffset);
}

DateTime manilaMonthStartUtc([DateTime? date]) {
  final local = date == null ? manilaNow() : toManila(date);
  return DateTime.utc(local.year, local.month).subtract(_manilaOffset);
}

DateTime manilaDateOnly(DateTime date) {
  final local = toManila(date);
  return DateTime(local.year, local.month, local.day);
}

String formatManilaDate(DateTime value) {
  final local = toManila(value);
  return '${local.year}-${_two(local.month)}-${_two(local.day)}';
}

String formatManilaDateTime(DateTime value) {
  final local = toManila(value);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(hour)}:${_two(local.minute)} $suffix';
}

String _two(int value) => value.toString().padLeft(2, '0');

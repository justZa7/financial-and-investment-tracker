import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactRupiah = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  static final DateFormat _date = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dateFull = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  static String rupiah(num value) => _rupiah.format(value);

  static String rupiahCompact(num value) => _compactRupiah.format(value);

  static String rupiahSigned(num value) {
    final formatted = _rupiah.format(value.abs());
    return value >= 0 ? '+$formatted' : '-$formatted';
  }

  static String decimal(num value, {int fraction = 2}) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = fraction;
    return f.format(value);
  }

  static String percent(num value, {bool signed = true}) {
    final sign = signed && value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String date(DateTime d) => _date.format(d);
  static String dateFull(DateTime d) => _dateFull.format(d);

  static String daysUntil(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff < 0) return '${diff.abs()} hari lewat jatuh tempo';
    if (diff == 0) return 'Jatuh tempo hari ini';
    return '$diff hari lagi';
  }
}

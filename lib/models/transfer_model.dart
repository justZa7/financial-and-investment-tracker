/// Transfer dana antar akun kas MILIK SENDIRI (Tunai <-> Bank <-> E-Wallet).
/// Beda dengan CashTransactionModel (income/expense) karena transfer TIDAK
/// mempengaruhi total saldo kas keseluruhan — cuma memindah dari satu akun
/// ke akun lain, jadi tidak dihitung sebagai pemasukan/pengeluaran.
class TransferModel {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String note;

  TransferModel({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note = '',
  });
}

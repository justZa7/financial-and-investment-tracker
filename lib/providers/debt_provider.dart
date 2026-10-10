import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/debt_model.dart';

const _uuid = Uuid();

class DebtProvider extends ChangeNotifier {
  final List<DebtModel> _debts = [];

  // Tidak ada data yang di-seed -> daftar utang/piutang mulai kosong.

  List<DebtModel> get all => List.unmodifiable(
      _debts..sort((a, b) => a.dueDate.compareTo(b.dueDate)));

  List<DebtModel> get debts =>
      all.where((d) => d.type == DebtType.debt).toList();

  List<DebtModel> get receivables =>
      all.where((d) => d.type == DebtType.receivable).toList();

  DebtModel? debtById(String id) {
    for (final d in _debts) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Total Utang Anda (uang yang harus Anda bayar)
  double get totalDebt => debts
      .where((d) => d.status != DebtStatus.paid)
      .fold(0.0, (sum, d) => sum + d.remaining);

  /// Total Piutang Anda (uang yang harus dibayar orang lain ke Anda)
  double get totalReceivable => receivables
      .where((d) => d.status != DebtStatus.paid)
      .fold(0.0, (sum, d) => sum + d.remaining);

  List<DebtModel> get dueSoonAlerts =>
      all.where((d) => d.isDueSoon || d.isOverdue).toList();

  String addDebt({
    required DebtType type,
    required String counterpartyName,
    required double principal,
    required DateTime dueDate,
    String note = '',
  }) {
    final debt = DebtModel(
      id: _uuid.v4(),
      type: type,
      counterpartyName: counterpartyName,
      principal: principal,
      remaining: principal,
      dueDate: dueDate,
      note: note,
      status: DebtStatus.unpaid,
    );
    _debts.add(debt);
    notifyListeners();
    return debt.id;
  }

  /// Edit data utang/piutang. Nominal awal (`principal`) HANYA bisa diubah
  /// kalau belum ada cicilan yang dibayar — mengubah principal setelah ada
  /// pembayaran bikin `remaining`/status ambigu. Null = sukses.
  String? updateDebt({
    required String debtId,
    required String counterpartyName,
    required double principal,
    required DateTime dueDate,
    String note = '',
  }) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return 'Data tidak ditemukan';
    final old = _debts[index];

    if (principal <= 0) return 'Nominal harus lebih besar dari 0';
    if (principal != old.principal && old.payments.isNotEmpty) {
      return 'Nominal awal tidak bisa diubah karena sudah ada cicilan yang dibayar. '
          'Hapus dulu riwayat pembayarannya kalau tetap ingin mengubah nominal.';
    }

    _debts[index] = DebtModel(
      id: old.id,
      type: old.type,
      counterpartyName: counterpartyName,
      principal: principal,
      remaining: principal != old.principal ? principal : old.remaining,
      dueDate: dueDate,
      note: note,
      status: old.status,
      payments: old.payments,
    );
    notifyListeners();
    return null;
  }

  bool deleteDebt(String debtId) {
    final existed = _debts.any((d) => d.id == debtId);
    _debts.removeWhere((d) => d.id == debtId);
    if (existed) notifyListeners();
    return existed;
  }

  /// Bayar cicilan -> otomatis update sisa pinjaman & status
  void payInstallment({
    required String debtId,
    required double amount,
    DateTime? date,
  }) {
    final debt = debtById(debtId);
    if (debt == null) return;
    final payment = amount > debt.remaining ? debt.remaining : amount;
    if (payment <= 0) return;

    debt.payments.add(DebtPaymentModel(
      id: _uuid.v4(),
      amount: payment,
      date: date ?? DateTime.now(),
    ));

    _recalculateStatus(debt);
    notifyListeners();
  }

  /// Edit satu pembayaran cicilan — `remaining` & status DIHITUNG ULANG dari
  /// total SELURUH pembayaran (bukan cuma selisih), supaya konsisten
  /// apapun pembayaran yang diedit. Null = sukses.
  String? updatePayment({
    required String debtId,
    required String paymentId,
    required double amount,
    DateTime? date,
  }) {
    final debt = debtById(debtId);
    if (debt == null) return 'Data utang tidak ditemukan';

    final index = debt.payments.indexWhere((p) => p.id == paymentId);
    if (index == -1) return 'Data pembayaran tidak ditemukan';
    if (amount <= 0) return 'Nominal pembayaran harus lebih besar dari 0';

    final othersTotal = debt.payments.where((p) => p.id != paymentId).fold(0.0, (s, p) => s + p.amount);
    if (othersTotal + amount > debt.principal + 0.0001) {
      return 'Total seluruh pembayaran tidak boleh melebihi nominal pinjaman';
    }

    debt.payments[index] = DebtPaymentModel(
      id: paymentId,
      amount: amount,
      date: date ?? debt.payments[index].date,
    );
    _recalculateStatus(debt);
    notifyListeners();
    return null;
  }

  bool deletePayment({required String debtId, required String paymentId}) {
    final debt = debtById(debtId);
    if (debt == null) return false;

    final existed = debt.payments.any((p) => p.id == paymentId);
    debt.payments.removeWhere((p) => p.id == paymentId);
    if (existed) {
      _recalculateStatus(debt);
      notifyListeners();
    }
    return existed;
  }

  void _recalculateStatus(DebtModel debt) {
    final totalPaid = debt.payments.fold(0.0, (s, p) => s + p.amount);
    debt.remaining = (debt.principal - totalPaid).clamp(0.0, debt.principal).toDouble();

    if (debt.remaining <= 0.0001) {
      debt.remaining = 0;
      debt.status = DebtStatus.paid;
    } else if (totalPaid > 0) {
      debt.status = DebtStatus.partial;
    } else {
      debt.status = DebtStatus.unpaid;
    }
  }
}

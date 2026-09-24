import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/debt_model.dart';

import '../services/mock_data_service.dart';

const _uuid = Uuid();

class DebtProvider extends ChangeNotifier {
  final List<DebtModel> _debts = [];

  // Tidak ada data yang di-seed -> daftar utang/piutang mulai kosong.
  // User menambahkan datanya sendiri lewat form Input (Tab Utang/Piutang).

  // DebtProvider() {                  // tambahkan constructor ini
  //   _debts.addAll(MockDataService.debts());
  // }

  List<DebtModel> get all => List.unmodifiable(
      _debts..sort((a, b) => a.dueDate.compareTo(b.dueDate)));

  List<DebtModel> get debts =>
      all.where((d) => d.type == DebtType.debt).toList();

  List<DebtModel> get receivables =>
      all.where((d) => d.type == DebtType.receivable).toList();

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

  void addDebt({
    required DebtType type,
    required String counterpartyName,
    required double principal,
    required DateTime dueDate,
    String note = '',
  }) {
    _debts.add(DebtModel(
      id: _uuid.v4(),
      type: type,
      counterpartyName: counterpartyName,
      principal: principal,
      remaining: principal,
      dueDate: dueDate,
      note: note,
      status: DebtStatus.unpaid,
    ));
    notifyListeners();
  }

  /// Bayar cicilan -> otomatis update sisa pinjaman & status
  void payInstallment({
    required String debtId,
    required double amount,
    DateTime? date,
  }) {
    final debt = _debts.firstWhere((d) => d.id == debtId);
    final payment = amount > debt.remaining ? debt.remaining : amount;

    debt.remaining -= payment;
    debt.payments.add(DebtPaymentModel(
      id: _uuid.v4(),
      amount: payment,
      date: date ?? DateTime.now(),
    ));

    if (debt.remaining <= 0.0001) {
      debt.remaining = 0;
      debt.status = DebtStatus.paid;
    } else {
      debt.status = DebtStatus.partial;
    }

    notifyListeners();
  }
}

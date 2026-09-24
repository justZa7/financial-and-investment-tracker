/// [debt]        = Utang saya (saya berhutang ke pihak lain)
/// [receivable]  = Piutang saya (pihak lain berhutang ke saya)
enum DebtType { debt, receivable }

enum DebtStatus { unpaid, partial, paid }

extension DebtStatusLabel on DebtStatus {
  String get label {
    switch (this) {
      case DebtStatus.unpaid:
        return 'Belum Lunas';
      case DebtStatus.partial:
        return 'Cicilan Berjalan';
      case DebtStatus.paid:
        return 'Lunas';
    }
  }
}

class DebtPaymentModel {
  final String id;
  final double amount;
  final DateTime date;

  DebtPaymentModel({
    required this.id,
    required this.amount,
    required this.date,
  });
}

class DebtModel {
  final String id;
  final DebtType type;
  final String counterpartyName;
  final double principal;
  double remaining;
  final DateTime dueDate;
  final String note;
  DebtStatus status;
  final List<DebtPaymentModel> payments;

  DebtModel({
    required this.id,
    required this.type,
    required this.counterpartyName,
    required this.principal,
    required this.remaining,
    required this.dueDate,
    this.note = '',
    this.status = DebtStatus.unpaid,
    List<DebtPaymentModel>? payments,
  }) : payments = payments ?? [];

  bool get isDueSoon =>
      status != DebtStatus.paid &&
      dueDate.difference(DateTime.now()).inDays <= 7 &&
      dueDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

  bool get isOverdue =>
      status != DebtStatus.paid && dueDate.isBefore(DateTime.now());
}

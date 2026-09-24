enum CashFlowType { income, expense }

class CashTransactionModel {
  final String id;
  final CashFlowType type;
  final String accountId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String description;

  CashTransactionModel({
    required this.id,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.description = '',
  });
}

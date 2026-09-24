enum AccountType { cash, bank, eWallet }

extension AccountTypeLabel on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Tunai';
      case AccountType.bank:
        return 'Bank';
      case AccountType.eWallet:
        return 'E-Wallet';
    }
  }
}

class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  double balance;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });
}

/// Kumpulan rumus keuangan yang dipakai lintas provider.
/// Dipisah sebagai pure functions agar mudah di-unit-test.
class CalculationService {
  CalculationService._();

  /// Savings Rate (%) = (Pemasukan - Pengeluaran) / Pemasukan * 100
  static double savingsRate({
    required double totalIncome,
    required double totalExpense,
  }) {
    if (totalIncome <= 0) return 0;
    return ((totalIncome - totalExpense) / totalIncome) * 100;
  }

  /// Net Worth = Total Kas/Bank + Total Nilai Pasar Aset - Total Utang
  static double netWorth({
    required double totalCash,
    required double totalAssetValue,
    required double totalDebt,
  }) {
    return totalCash + totalAssetValue - totalDebt;
  }

  /// Annual Return (%) sederhana = Total Gain (Unrealized+Realized) / Total Cost Basis * 100
  static double annualReturnPercent({
    required double totalGain,
    required double totalCostBasis,
  }) {
    if (totalCostBasis <= 0) return 0;
    return (totalGain / totalCostBasis) * 100;
  }

  /// Weighted Average Cost Basis saat BUY
  /// New Avg Price = ((ExistingQty*ExistingAvg) + (BuyQty*BuyPrice)) / (ExistingQty+BuyQty)
  static double weightedAveragePrice({
    required double existingQty,
    required double existingAvgPrice,
    required double buyQty,
    required double buyPrice,
  }) {
    final totalQty = existingQty + buyQty;
    if (totalQty <= 0) return 0;
    return ((existingQty * existingAvgPrice) + (buyQty * buyPrice)) / totalQty;
  }

  /// Realized Gain/Loss saat SELL (berbasis avg cost, fee mengurangi hasil)
  /// Realized G/L = (SellPrice - AvgPrice) * SellQty - Fee
  static double realizedGainLoss({
    required double sellPrice,
    required double avgPrice,
    required double sellQty,
    required double fee,
  }) {
    return (sellPrice - avgPrice) * sellQty - fee;
  }
}

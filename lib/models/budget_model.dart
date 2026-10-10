/// Anggaran bulanan untuk satu kategori pengeluaran. Sifatnya RECURRING —
/// sekali diset, berlaku tiap bulan (bulan dihitung dari tanggal saat ini
/// ketika dicek, bukan disimpan per-bulan satu-satu).
class BudgetModel {
  final String id;
  final String categoryId;
  double monthlyLimit;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
  });
}

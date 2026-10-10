import 'package:flutter/material.dart';

/// Target tabungan (misal: Dana Darurat, DP Rumah, Liburan). [currentAmount]
/// bertambah/berkurang lewat kontribusi yang bisa terhubung ke akun kas
/// nyata (uangnya beneran dipindah dari akun ke "alokasi" goal ini).
class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime? targetDate;
  final IconData icon;
  final Color color;
  final List<SavingsContributionModel> contributions;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.icon = Icons.savings_rounded,
    this.color = const Color(0xFF5C7A45),
    List<SavingsContributionModel>? contributions,
  }) : contributions = contributions ?? [];

  double get progressPercent => targetAmount <= 0
      ? 0.0
      : (currentAmount / targetAmount * 100).clamp(0.0, 100.0).toDouble();

  bool get isCompleted => currentAmount >= targetAmount;

  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity).toDouble();
}

class SavingsContributionModel {
  final String id;
  final double amount; // positif = setor, negatif = tarik
  final DateTime date;
  final String? accountId; // akun kas yang dipakai, null kalau "dana baru"

  SavingsContributionModel({
    required this.id,
    required this.amount,
    required this.date,
    this.accountId,
  });
}

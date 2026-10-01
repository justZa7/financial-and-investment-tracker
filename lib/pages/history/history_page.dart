import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset_transaction_model.dart';
import '../../models/cash_transaction_model.dart';
import '../../providers/cashflow_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/sort_utils.dart';
import '../../widgets/display_currency_toggle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../widgets/transaction_tile.dart';

/// Mode urutan daftar riwayat transaksi.
/// [newest] adalah DEFAULT (sesuai urutan yang sudah ada sebelumnya: dari
/// yang paling baru tanggalnya). [amountDesc]/[amountAsc] mengurutkan
/// berdasarkan NOMINAL transaksi (bukan tanggal) memakai Merge Sort manual
/// (lihat lib/utils/sort_utils.dart), bukan `List.sort()` bawaan Dart.
enum _SortMode { newest, amountDesc, amountAsc }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTimeRange? _dateRange;
  final Set<HistoryTxKind> _selectedKinds = {...HistoryTxKind.values};
  _SortMode _sortMode = _SortMode.newest; // default: tanggal terbaru dulu

  @override
  Widget build(BuildContext context) {
    final cashFlow = context.watch<CashFlowProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final debt = context.watch<DebtProvider>();

    final items = _buildHistory(cashFlow, portfolio, debt);
    final filtered = items.where((item) {
      final inKind = _selectedKinds.contains(item.kind);
      final inRange = _dateRange == null ||
          (item.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              item.date.isBefore(_dateRange!.end.add(const Duration(days: 1))));
      return inKind && inRange;
    }).toList();

    // Merge Sort manual (O(n log n), stabil) — bukan List.sort() bawaan.
    final sorted = mergeSort(filtered, _comparatorFor(_sortMode));

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Riwayat Transaksi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                const ThemeModeToggle(),
                const DisplayCurrencyToggle(),
                IconButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                      initialDateRange: _dateRange,
                    );
                    setState(() => _dateRange = picked);
                  },
                  icon: const Icon(Icons.date_range_outlined),
                  tooltip: 'Filter tanggal',
                ),
              ],
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    '${AppFormatters.date(_dateRange!.start)} - ${AppFormatters.date(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: () => setState(() => _dateRange = null),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _kindChip('Pemasukan', HistoryTxKind.income),
                _kindChip('Pengeluaran', HistoryTxKind.expense),
                _kindChip('Beli Aset', HistoryTxKind.assetBuy),
                _kindChip('Jual Aset', HistoryTxKind.assetSell),
                _kindChip('Bayar Utang', HistoryTxKind.debtPayment),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.sort_rounded, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Urutkan:', style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _sortChip('Default', _SortMode.newest),
                        _sortChip('Nominal Terbesar', _SortMode.amountDesc),
                        _sortChip('Nominal Terkecil', _SortMode.amountAsc),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: sorted.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Tidak ada transaksi')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => TransactionTile(item: sorted[i]),
                  ),
          ),
        ],
      ),
    );
  }

  /// Comparator untuk tiap mode sort. Dipisah dari UI supaya gampang
  /// ditest/diverifikasi terpisah (lihat test/sort_utils_test.dart).
  int Function(HistoryItem, HistoryItem) _comparatorFor(_SortMode mode) {
    switch (mode) {
      case _SortMode.newest:
        return (a, b) => b.date.compareTo(a.date);
      case _SortMode.amountDesc:
        return (a, b) => b.amount.compareTo(a.amount);
      case _SortMode.amountAsc:
        return (a, b) => a.amount.compareTo(b.amount);
    }
  }

  Widget _sortChip(String label, _SortMode mode) {
    final selected = _sortMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => setState(() => _sortMode = mode),
      ),
    );
  }

  Widget _kindChip(String label, HistoryTxKind kind) {
    final selected = _selectedKinds.contains(kind);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (v) {
          setState(() {
            if (v) {
              _selectedKinds.add(kind);
            } else {
              _selectedKinds.remove(kind);
            }
          });
        },
      ),
    );
  }

  List<HistoryItem> _buildHistory(
    CashFlowProvider cashFlow,
    PortfolioProvider portfolio,
    DebtProvider debt,
  ) {
    final items = <HistoryItem>[];

    for (final t in cashFlow.transactions) {
      final account = cashFlow.accountById(t.accountId);
      final category = cashFlow.categoryById(t.categoryId);
      items.add(HistoryItem(
        kind: t.type == CashFlowType.income ? HistoryTxKind.income : HistoryTxKind.expense,
        title: category.name,
        subtitle: '${account.name}${t.description.isNotEmpty ? ' · ${t.description}' : ''}',
        amount: t.amount,
        date: t.date,
      ));
    }

    for (final t in portfolio.transactions) {
      items.add(HistoryItem(
        kind: t.type == AssetTxType.buy ? HistoryTxKind.assetBuy : HistoryTxKind.assetSell,
        title: '${t.type == AssetTxType.buy ? 'Beli' : 'Jual'} ${t.ticker}',
        subtitle: '${AppFormatters.decimal(t.qty, fraction: 4)} unit @ ${AppFormatters.rupiah(t.pricePerUnit)}',
        amount: t.grossTotal,
        date: t.date,
        realizedGainLoss: t.realizedGainLoss,
      ));
    }

    for (final d in debt.all) {
      for (final p in d.payments) {
        items.add(HistoryItem(
          kind: HistoryTxKind.debtPayment,
          title: 'Bayar ${d.type.name == 'debt' ? 'Utang' : 'Piutang'} - ${d.counterpartyName}',
          subtitle: d.note,
          amount: p.amount,
          date: p.date,
        ));
      }
    }

    return items;
  }
}

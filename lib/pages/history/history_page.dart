import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset_transaction_model.dart';
import '../../models/cash_transaction_model.dart';
import '../../models/debt_model.dart';
import '../../providers/cashflow_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/asset_validation_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/formatters.dart';
import '../../utils/sort_utils.dart';
import '../../widgets/display_currency_toggle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../widgets/transaction_tile.dart';

/// Mode urutan daftar riwayat transaksi.
/// [newest] adalah DEFAULT (dari yang paling baru tanggalnya).
/// [amountDesc]/[amountAsc] mengurutkan berdasarkan NOMINAL memakai Merge
/// Sort manual (lihat lib/utils/sort_utils.dart), bukan `List.sort()`.
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

  /// Qty tanpa format lokal (aman di-parse balik lewat double.tryParse):
  /// 100.0 -> "100", 0.015 -> "0.015".
  String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Nominal uang untuk field berformat titik-ribuan: SELALU bilangan bulat,
  /// karena `CurrencyInputHelper.unformatIdr` menganggap titik = pemisah
  /// ribuan (nilai pecahan seperti "54322.14" akan salah ter-parse).
  String _money(double v) => v.round().toString();

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
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
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
                _kindChip('Transfer', HistoryTxKind.transfer),
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
                Icon(Icons.sort_rounded, size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Urutkan:', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _sortChip('Terbaru', _SortMode.newest),
                        _sortChip('Nominal Terbesar', _SortMode.amountDesc),
                        _sortChip('Nominal Terkecil', _SortMode.amountAsc),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Tap transaksi untuk edit/hapus', style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: sorted.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Tidak ada transaksi')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final item = sorted[i];
                      return TransactionTile(
                        item: item,
                        onTap: item.isEditable ? () => _showActionSheet(item, cashFlow, portfolio, debt) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

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
        id: t.id,
        kind: t.type == CashFlowType.income ? HistoryTxKind.income : HistoryTxKind.expense,
        title: category.name,
        subtitle: '${account.name}${t.description.isNotEmpty ? ' · ${t.description}' : ''}',
        amount: t.amount,
        date: t.date,
      ));
    }

    for (final t in cashFlow.transfers) {
      final from = cashFlow.accountById(t.fromAccountId);
      final to = cashFlow.accountById(t.toAccountId);
      items.add(HistoryItem(
        id: t.id,
        kind: HistoryTxKind.transfer,
        title: 'Transfer ${from.name} → ${to.name}',
        subtitle: t.note,
        amount: t.amount,
        date: t.date,
      ));
    }

    for (final t in portfolio.transactions) {
      items.add(HistoryItem(
        id: t.id,
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
          id: p.id,
          debtId: d.id,
          kind: HistoryTxKind.debtPayment,
          title: 'Bayar ${d.type == DebtType.debt ? 'Utang' : 'Piutang'} - ${d.counterpartyName}',
          subtitle: d.note,
          amount: p.amount,
          date: p.date,
        ));
      }
    }

    return items;
  }

  // -------------------------------------------------------------------
  // EDIT & HAPUS — semua dialog memakai `context` halaman (State.context),
  // BUKAN context bottom sheet/dialog yang sudah di-pop, supaya aman.
  // -------------------------------------------------------------------
  void _showActionSheet(
    HistoryItem item,
    CashFlowProvider cashFlow,
    PortfolioProvider portfolio,
    DebtProvider debt,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.matchaDarkest),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditDialog(item, cashFlow, portfolio, debt);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.loss),
              title: const Text('Hapus'),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(item, cashFlow, portfolio, debt);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    HistoryItem item,
    CashFlowProvider cashFlow,
    PortfolioProvider portfolio,
    DebtProvider debt,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus transaksi ini?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan. Saldo/portofolio terkait akan disesuaikan otomatis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () {
              bool ok = true;
              switch (item.kind) {
                case HistoryTxKind.income:
                case HistoryTxKind.expense:
                  ok = cashFlow.deleteTransaction(item.id!);
                  break;
                case HistoryTxKind.transfer:
                  ok = cashFlow.deleteTransfer(item.id!);
                  break;
                case HistoryTxKind.assetBuy:
                case HistoryTxKind.assetSell:
                  ok = portfolio.deleteAssetTransaction(item.id!);
                  break;
                case HistoryTxKind.debtPayment:
                  ok = debt.deletePayment(debtId: item.debtId!, paymentId: item.id!);
                  break;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Transaksi berhasil dihapus'
                      : 'Gagal menghapus — penghapusan ini akan membuat transaksi jual lain melebihi stok.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    HistoryItem item,
    CashFlowProvider cashFlow,
    PortfolioProvider portfolio,
    DebtProvider debt,
  ) {
    switch (item.kind) {
      case HistoryTxKind.income:
      case HistoryTxKind.expense:
        _showEditCashDialog(item, cashFlow);
        break;
      case HistoryTxKind.transfer:
        _showEditTransferDialog(item, cashFlow);
        break;
      case HistoryTxKind.assetBuy:
      case HistoryTxKind.assetSell:
        _showEditAssetDialog(item, portfolio);
        break;
      case HistoryTxKind.debtPayment:
        _showEditPaymentDialog(item, debt);
        break;
    }
  }

  void _showEditCashDialog(HistoryItem item, CashFlowProvider cashFlow) {
    final tx = cashFlow.transactionById(item.id!);
    if (tx == null) return;
    final amountCtrl = TextEditingController(text: _money(tx.amount));
    final descCtrl = TextEditingController(text: tx.description);
    String accountId = tx.accountId;
    String categoryId = tx.categoryId;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final categories = cashFlow.categoriesFor(tx.type);
          return AlertDialog(
            title: const Text('Edit Transaksi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: accountId,
                    decoration: const InputDecoration(labelText: 'Akun'),
                    items: cashFlow.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (v) => setState(() => accountId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => categoryId = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
              FilledButton(
                onPressed: () {
                  // Nilai di field sudah berformat titik ribuan ("150.000").
                  final amount = CurrencyInputHelper.unformatIdr(amountCtrl.text);
                  if (amount <= 0) {
                    setState(() => error = 'Nominal harus lebih besar dari 0');
                    return;
                  }
                  cashFlow.updateTransaction(
                    id: tx.id,
                    type: tx.type,
                    accountId: accountId,
                    categoryId: categoryId,
                    amount: amount,
                    date: tx.date,
                    description: descCtrl.text,
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTransferDialog(HistoryItem item, CashFlowProvider cashFlow) {
    // Transfer diedit dengan cara hapus lalu buat ulang dengan nominal baru
    // (akun asal/tujuan TIDAK diubah di sini) supaya reversal saldo tetap
    // benar lewat method yang sudah ada.
    final matches = cashFlow.transfers.where((t) => t.id == item.id);
    if (matches.isEmpty) return;
    final transfer = matches.first;
    final amountCtrl = TextEditingController(text: _money(transfer.amount));
    final noteCtrl = TextEditingController(text: transfer.note);
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit Transfer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${cashFlow.accountById(transfer.fromAccountId).name} → ${cashFlow.accountById(transfer.toAccountId).name}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
              ),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final amount = CurrencyInputHelper.unformatIdr(amountCtrl.text);
                if (amount <= 0) {
                  setState(() => error = 'Nominal harus lebih besar dari 0');
                  return;
                }
                cashFlow.deleteTransfer(transfer.id);
                final err = cashFlow.addTransfer(
                  fromAccountId: transfer.fromAccountId,
                  toAccountId: transfer.toAccountId,
                  amount: amount,
                  date: transfer.date,
                  note: noteCtrl.text,
                );
                if (err != null) {
                  // Gagal (misal saldo kurang) -> pulihkan transfer lama.
                  cashFlow.addTransfer(
                    fromAccountId: transfer.fromAccountId,
                    toAccountId: transfer.toAccountId,
                    amount: transfer.amount,
                    date: transfer.date,
                    note: transfer.note,
                  );
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAssetDialog(HistoryItem item, PortfolioProvider portfolio) {
    final tx = portfolio.transactionById(item.id!);
    if (tx == null) return;
    final qtyCtrl = TextEditingController(text: _plain(tx.qty));
    final priceCtrl = TextEditingController(text: _money(tx.pricePerUnit));
    final feeCtrl = TextEditingController(text: _money(tx.fee));
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Edit ${tx.type == AssetTxType.buy ? 'Beli' : 'Jual'} ${tx.ticker}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    helperText: AssetValidationService.hintFor(tx.assetClass),
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Harga per Unit (Rp)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Fee (Rp)'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
                final price = CurrencyInputHelper.unformatIdr(priceCtrl.text);
                final fee = CurrencyInputHelper.unformatIdr(feeCtrl.text);

                // Aturan yang sama dengan form Input (misal saham wajib
                // kelipatan 1 lot) — input salah TIDAK masuk portfolio.
                final qtyError = AssetValidationService.validateQty(assetClass: tx.assetClass, qty: qty);
                if (qtyError != null) {
                  setState(() => error = qtyError);
                  return;
                }
                if (price <= 0) {
                  setState(() => error = 'Harga per unit harus lebih besar dari 0');
                  return;
                }
                final err = portfolio.updateAssetTransaction(
                  transactionId: tx.id,
                  qty: qty!,
                  pricePerUnit: price,
                  fee: fee,
                  date: tx.date,
                );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentDialog(HistoryItem item, DebtProvider debt) {
    final debtModel = debt.debtById(item.debtId!);
    if (debtModel == null) return;
    final matches = debtModel.payments.where((p) => p.id == item.id);
    if (matches.isEmpty) return;
    final payment = matches.first;
    final amountCtrl = TextEditingController(text: _money(payment.amount));
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(labelText: 'Nominal Pembayaran (Rp)'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final err = debt.updatePayment(
                  debtId: debtModel.id,
                  paymentId: payment.id,
                  amount: CurrencyInputHelper.unformatIdr(amountCtrl.text),
                );
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

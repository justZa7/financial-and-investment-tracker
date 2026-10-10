import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account_model.dart';
import '../../providers/cashflow_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/money_text.dart';
import 'cash_detail_page.dart';

class ManageAccountsPage extends StatelessWidget {
  const ManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashFlowProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Kelola Akun', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Akun'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: provider.accounts.length,
          itemBuilder: (context, i) {
            final account = provider.accounts[i];
            final color = accountTypeColor(account.type);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(accountTypeIcon(account.type), size: 18, color: color),
                ),
                title: Text(account.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(account.type.label, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(amountInIdr: account.balance, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') _showRenameDialog(context, provider, account);
                        if (v == 'delete') _showDeleteDialog(context, provider, account);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('Ganti Nama')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, CashFlowProvider provider) {
    final nameCtrl = TextEditingController();
    AccountType type = AccountType.bank;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Akun Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Akun')),
              const SizedBox(height: 14),
              DropdownButtonFormField<AccountType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                provider.addAccount(name: nameCtrl.text.trim(), type: type);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, CashFlowProvider provider, AccountModel account) {
    final ctrl = TextEditingController(text: account.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Nama Akun'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nama Akun')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              provider.renameAccount(account.id, ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CashFlowProvider provider, AccountModel account) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus "${account.name}"?'),
        content: Text(
          account.balance != 0
              ? 'Akun ini masih punya saldo Rp${account.balance.toStringAsFixed(0)}. Menghapusnya TIDAK mengubah riwayat transaksi lama, tapi akun ini tidak akan muncul lagi di pilihan form.'
              : 'Akun ini akan dihapus dari daftar pilihan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () {
              final ok = provider.deleteAccount(account.id);
              Navigator.pop(dialogContext);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akun terakhir tidak bisa dihapus — minimal harus ada satu akun.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

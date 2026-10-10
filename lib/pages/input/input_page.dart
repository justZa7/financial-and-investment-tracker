import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset_holding_model.dart';
import '../../models/cash_transaction_model.dart';
import '../../models/debt_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/cashflow_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/asset_validation_service.dart';
import '../../services/market_data_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/formatters.dart';
import '../../widgets/currency_amount_field.dart';
import '../../widgets/price_quote_card.dart';

enum _InputTab { cash, transfer, invest, debt }

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  _InputTab _tab = _InputTab.cash;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Input Transaksi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Row chip yang bisa di-scroll horizontal (BUKAN SegmentedButton):
          // dengan 4 tab + label "Utang/Piutang" yang panjang, SegmentedButton
          // memaksa semua segmen sama lebar dan berisiko overflow di layar
          // sempit (pelajaran sama dengan perbaikan bottom nav bar).
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _tabChip(_InputTab.cash, 'Kas', Icons.account_balance_wallet_outlined),
                _tabChip(_InputTab.transfer, 'Transfer', Icons.swap_horiz_rounded),
                _tabChip(_InputTab.invest, 'Investasi', Icons.show_chart),
                _tabChip(_InputTab.debt, 'Utang/Piutang', Icons.handshake_outlined),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: IndexedStack(
              index: _tab.index,
              children: const [
                _CashFlowForm(),
                _TransferForm(),
                _InvestmentForm(),
                _DebtForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(_InputTab tab, String label, IconData icon) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        avatar: Icon(icon, size: 15),
        selected: selected,
        onSelected: (_) => setState(() => _tab = tab),
      ),
    );
  }
}

// =====================================================================
// TAB BARU: TRANSFER ANTAR AKUN
// =====================================================================
class _TransferForm extends StatefulWidget {
  const _TransferForm();

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashFlowProvider>();
    final ids = provider.accounts.map((a) => a.id).toSet();
    // Akun yang dipilih bisa saja sudah dihapus lewat Kelola Akun -> reset.
    if (_fromAccountId != null && !ids.contains(_fromAccountId)) _fromAccountId = null;
    if (_toAccountId != null && !ids.contains(_toAccountId)) _toAccountId = null;
    _fromAccountId ??= provider.accounts.isNotEmpty ? provider.accounts.first.id : null;
    _toAccountId ??= provider.accounts.length > 1 ? provider.accounts[1].id : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Dari Akun'),
              DropdownButtonFormField<String>(
                value: _fromAccountId,
                items: provider.accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type.index})')))
                    .toList(),
                onChanged: (v) => setState(() => _fromAccountId = v),
              ),
              if (_fromAccountId != null) ...[
                const SizedBox(height: 6),
                _balanceCaption(context, provider.balanceOf(_fromAccountId!)),
              ],
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.matchaPale, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.matchaDarkest),
                ),
              ),
              const SizedBox(height: 16),
              _label('Ke Akun'),
              DropdownButtonFormField<String>(
                value: _toAccountId,
                items: provider.accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type.index})')))
                    .toList(),
                onChanged: (v) => setState(() => _toAccountId = v),
              ),
              if (_toAccountId != null) ...[
                const SizedBox(height: 6),
                _balanceCaption(context, provider.balanceOf(_toAccountId!)),
              ],
              const SizedBox(height: 14),
              _label('Nominal (Rp)'),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(hintText: 'Jumlah yang ditransfer'),
                validator: (v) => (v == null || v.isEmpty) ? 'Nominal wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _label('Tanggal'),
              _dateField(_date, (d) => setState(() => _date = d)),
              const SizedBox(height: 14),
              _label('Catatan (opsional)'),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(hintText: 'Misal: pindah buat belanja bulanan'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _submit(provider),
                child: const Text('Transfer Sekarang'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit(CashFlowProvider provider) {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccountId == null || _toAccountId == null) return;
    final amount = CurrencyInputHelper.unformatIdr(_amountCtrl.text);

    setState(() => _error = null);

    final err = provider.addTransfer(
      fromAccountId: _fromAccountId!,
      toAccountId: _toAccountId!,
      amount: amount,
      date: _date,
      note: _noteCtrl.text,
    );

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    _amountCtrl.clear();
    _noteCtrl.clear();
    _showSaved(context, 'Transfer berhasil disimpan');
  }
}

// =====================================================================
// TAB 1: PEMASUKAN / PENGELUARAN HARIAN
// =====================================================================
class _CashFlowForm extends StatefulWidget {
  const _CashFlowForm();

  @override
  State<_CashFlowForm> createState() => _CashFlowFormState();
}

class _CashFlowFormState extends State<_CashFlowForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountFieldKey = GlobalKey<CurrencyAmountFieldState>();
  CashFlowType _flowType = CashFlowType.expense;
  String? _accountId;
  String? _categoryId;
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashFlowProvider>();
    final exchangeRate = context.watch<ExchangeRateProvider>().rate;
    final categories = provider.categoriesFor(_flowType);
    _categoryId ??= categories.isNotEmpty ? categories.first.id : null;
    // Akun bisa dihapus lewat Kelola Akun -> pastikan pilihan masih valid.
    if (_accountId != null && !provider.accounts.any((a) => a.id == _accountId)) _accountId = null;
    _accountId ??= provider.accounts.isNotEmpty ? provider.accounts.first.id : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<CashFlowType>(
                segments: const [
                  ButtonSegment(value: CashFlowType.income, label: Text('Pemasukan')),
                  ButtonSegment(value: CashFlowType.expense, label: Text('Pengeluaran')),
                ],
                selected: {_flowType},
                onSelectionChanged: (s) => setState(() {
                  _flowType = s.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),
              _label('Akun'),
              DropdownButtonFormField<String>(
                value: _accountId,
                items: provider.accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type.index})')))
                    .toList(),
                onChanged: (v) => setState(() => _accountId = v),
              ),
              if (_accountId != null) ...[
                const SizedBox(height: 6),
                _balanceCaption(context, provider.balanceOf(_accountId!)),
              ],
              const SizedBox(height: 14),
              _label('Kategori'),
              DropdownButtonFormField<String>(
                value: _categoryId,
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 14),
              CurrencyAmountField(
                key: _amountFieldKey,
                label: 'Nominal',
                hint: 'Contoh: 150.000',
                exchangeRate: exchangeRate,
                validator: (v) => (v == null || v.isEmpty) ? 'Nominal wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _label('Tanggal'),
              _dateField(_date, (d) => setState(() => _date = d)),
              const SizedBox(height: 14),
              _label('Deskripsi (opsional)'),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(hintText: 'Catatan tambahan'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _submit(provider),
                child: const Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit(CashFlowProvider provider) {
    if (!_formKey.currentState!.validate() || _accountId == null || _categoryId == null) return;
    final amount = _amountFieldKey.currentState!.amountInIdr;
    if (amount <= 0) return;

    provider.addTransaction(
      type: _flowType,
      accountId: _accountId!,
      categoryId: _categoryId!,
      amount: amount,
      date: _date,
      description: _descCtrl.text,
    );

    _amountFieldKey.currentState!.clear();
    _descCtrl.clear();

    // Cek anggaran SETELAH transaksi tersimpan — kalau kategori ini sudah
    // dikasih budget dan jadi over/dekat limit, kasih tahu user. Transaksi
    // tetap tersimpan (budget cuma peringatan, bukan pembatas keras).
    if (_flowType == CashFlowType.expense && mounted) {
      final budget = context.read<BudgetProvider>().budgetForCategory(_categoryId!);
      if (budget != null) {
        final spent = provider.expenseThisMonthForCategory(_categoryId!);
        final categoryName = provider.categoryById(_categoryId!).name;
        if (spent > budget.monthlyLimit) {
          _showBudgetWarning(
            '⚠️ Anggaran "$categoryName" sudah lewat batas! '
            'Terpakai ${AppFormatters.rupiah(spent)} dari ${AppFormatters.rupiah(budget.monthlyLimit)}.',
          );
          return;
        } else if (spent >= budget.monthlyLimit * 0.8) {
          _showBudgetWarning(
            '"$categoryName" sudah ${(spent / budget.monthlyLimit * 100).toStringAsFixed(0)}% dari anggaran bulanan.',
          );
          return;
        }
      }
    }

    _showSaved(context, 'Transaksi kas berhasil disimpan');
  }

  void _showBudgetWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12.5)),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// =====================================================================
// TAB 2: INVESTASI BELI / JUAL
// =====================================================================
class _InvestmentForm extends StatefulWidget {
  const _InvestmentForm();

  @override
  State<_InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<_InvestmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _priceFieldKey = GlobalKey<CurrencyAmountFieldState>();
  bool _isBuy = true;
  final _tickerCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  AssetClass _assetClass = AssetClass.equity;
  final _qtyCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '0');
  final _yieldCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  // --- Sumber/tujuan dana (BARU) ---
  // false = "Dana Baru" (fresh money, TIDAK memotong saldo kas — perilaku
  // lama) / "Tidak Masuk Kas" saat jual. true = dipindah dari/ke akun kas.
  bool _useCashFunding = false;
  String? _fundingAccountId;

  // --- Live price preview (BARU) ---
  Timer? _debounce;
  AssetQuote? _quote;
  bool _quoteLoading = false;
  String? _quoteError;

  double _livePriceIdr = 0;

  @override
  void initState() {
    super.initState();
    _tickerCtrl.addListener(_scheduleQuoteFetch);
    // Qty & Fee ikut memicu rebuild supaya ringkasan "Total Pembelian" live
    // selalu up-to-date tiap kali salah satu field-nya diketik.
    _qtyCtrl.addListener(_refreshTotal);
    _feeCtrl.addListener(_refreshTotal);
  }

  void _refreshTotal() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _tickerCtrl.removeListener(_scheduleQuoteFetch);
    _qtyCtrl.removeListener(_refreshTotal);
    _feeCtrl.removeListener(_refreshTotal);
    _tickerCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _feeCtrl.dispose();
    _yieldCtrl.dispose();
    super.dispose();
  }

  void _scheduleQuoteFetch() {
    _debounce?.cancel();
    final ticker = _tickerCtrl.text.trim();
    if (ticker.isEmpty) {
      setState(() {
        _quote = null;
        _quoteError = null;
        _quoteLoading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    final ticker = _tickerCtrl.text.trim();
    if (ticker.isEmpty) return;

    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });

    if (_assetClass == AssetClass.moneyMarket) {
      if (!mounted) return;
      setState(() {
        _quoteLoading = false;
        _quote = null;
        _quoteError = 'Reksadana Pasar Uang tidak punya API harga otomatis — isi Harga per Unit secara manual.';
      });
      return;
    }

    final quote = await MarketDataService.fetchQuote(ticker, _assetClass);
    if (!mounted) return;

    setState(() {
      _quoteLoading = false;
      _quote = quote;
      _quoteError = quote == null
          ? 'Harga untuk "$ticker" tidak ditemukan. Cek penulisan ticker, atau isi harga manual.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final cashFlow = context.watch<CashFlowProvider>();
    final exchangeRate = context.watch<ExchangeRateProvider>().rate;

    if (_fundingAccountId != null && !cashFlow.accounts.any((a) => a.id == _fundingAccountId)) {
      _fundingAccountId = null;
    }
    if (_useCashFunding) {
      _fundingAccountId ??= cashFlow.accounts.isNotEmpty ? cashFlow.accounts.first.id : null;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Beli')),
                  ButtonSegment(value: false, label: Text('Jual')),
                ],
                selected: {_isBuy},
                onSelectionChanged: (s) => setState(() => _isBuy = s.first),
              ),
              const SizedBox(height: 16),
              _label('Ticker Aset'),
              TextFormField(
                controller: _tickerCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Contoh: BBCA, BTC, XAU'),
                validator: (v) => (v == null || v.isEmpty) ? 'Ticker wajib diisi' : null,
              ),
              if (_isBuy) ...[
                const SizedBox(height: 14),
                _label('Nama Aset'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Contoh: Bank Central Asia Tbk'),
                ),
              ],
              const SizedBox(height: 14),
              _label('Jenis Aset'),
              DropdownButtonFormField<AssetClass>(
                value: _assetClass,
                items: AssetClass.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _assetClass = v!;
                  _scheduleQuoteFetch();
                }),
              ),
              // --- Live price preview: angka + sparkline chart seperti exchange ---
              PriceQuoteCard(
                isLoading: _quoteLoading,
                quote: _quote,
                errorMessage: _quoteError,
                onUsePrice: () {
                  if (_quote != null) {
                    _priceFieldKey.currentState?.setAmountInIdr(_quote!.price);
                  }
                },
              ),
              const SizedBox(height: 14),
              _label('Qty'),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Jumlah unit / lembar / gram',
                  helperText: AssetValidationService.hintFor(_assetClass),
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Qty wajib diisi';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  return AssetValidationService.validateQty(assetClass: _assetClass, qty: parsed);
                },
              ),
              const SizedBox(height: 14),
              CurrencyAmountField(
                key: _priceFieldKey,
                label: 'Harga per Unit',
                hint: 'Harga eksekusi per unit',
                exchangeRate: exchangeRate,
                validator: (v) => (v == null || v.isEmpty) ? 'Harga wajib diisi' : null,
                onAmountChanged: (v) => setState(() => _livePriceIdr = v),
              ),
              const SizedBox(height: 14),
              _label('Fee / Biaya Transaksi (Rp)'),
              TextFormField(
                controller: _feeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
              ),
              // --- Ringkasan Total Pembelian/Penjualan LIVE (BARU) ---
              _buildTotalSummary(context),
              if (_isBuy && _assetClass == AssetClass.moneyMarket) ...[
                const SizedBox(height: 14),
                _label('Yield Tahunan (%) — khusus Reksadana Pasar Uang'),
                TextFormField(
                  controller: _yieldCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Contoh: 5.5'),
                ),
              ],
              const SizedBox(height: 20),
              // --- Sumber/Tujuan Dana (BARU) ---
              _label(_isBuy ? 'Sumber Dana' : 'Tujuan Dana Hasil Jual'),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(_isBuy ? 'Dana Baru' : 'Tidak Masuk Kas', style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.auto_awesome_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(_isBuy ? 'Dari Kas' : 'Masuk ke Kas', style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
                  ),
                ],
                selected: {_useCashFunding},
                onSelectionChanged: (s) => setState(() => _useCashFunding = s.first),
              ),
              const SizedBox(height: 4),
              Text(
                _isBuy
                    ? (_useCashFunding
                        ? 'Saldo akun yang dipilih akan berkurang sebesar total transaksi.'
                        : 'Dianggap dana baru dari luar — saldo akun kas TIDAK berkurang.')
                    : (_useCashFunding
                        ? 'Hasil penjualan akan ditambahkan ke saldo akun yang dipilih.'
                        : 'Hasil penjualan TIDAK masuk ke akun kas manapun di app ini.'),
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (_useCashFunding) ...[
                const SizedBox(height: 12),
                _label('Akun'),
                DropdownButtonFormField<String>(
                  value: _fundingAccountId,
                  items: cashFlow.accounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type.index})')))
                      .toList(),
                  onChanged: (v) => setState(() => _fundingAccountId = v),
                ),
                if (_fundingAccountId != null) ...[
                  const SizedBox(height: 6),
                  _balanceCaption(context, cashFlow.balanceOf(_fundingAccountId!)),
                ],
              ],
              const SizedBox(height: 14),
              _label('Tanggal'),
              _dateField(_date, (d) => setState(() => _date = d)),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _submit(provider, cashFlow),
                child: Text(_isBuy ? 'Simpan Transaksi Beli' : 'Simpan Transaksi Jual'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ringkasan "Total Pembelian" (Beli) / "Total Hasil Jual" (Jual) yang
  /// terus live ter-update mengikuti Qty, Harga per Unit, dan Fee — supaya
  /// user tahu persis berapa total uang yang akan keluar/masuk SEBELUM
  /// menekan tombol Simpan, berlaku untuk semua kelas aset (saham, crypto,
  /// emas, reksadana).
  Widget _buildTotalSummary(BuildContext context) {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final fee = CurrencyInputHelper.unformatIdr(_feeCtrl.text);
    if (qty <= 0 || _livePriceIdr <= 0) return const SizedBox(height: 14);

    final gross = qty * _livePriceIdr;
    final total = _isBuy ? gross + fee : gross - fee;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.matchaDarkest.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.matchaDarkest.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined, size: 14, color: AppColors.matchaDarkest),
                const SizedBox(width: 6),
                Text(
                  _isBuy ? 'Total Pembelian' : 'Total Hasil Jual',
                  style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.rupiah(total),
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              '${AppFormatters.decimal(qty, fraction: 4)} unit × ${AppFormatters.rupiah(_livePriceIdr)}'
              '${fee > 0 ? ' ${_isBuy ? '+' : '-'} fee ${AppFormatters.rupiah(fee)}' : ''}',
              style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(PortfolioProvider provider, CashFlowProvider cashFlow) {
    setState(() => _error = null);

    // Validasi field-level (format angka, kelipatan lot saham, dll) —
    // kalau gagal, form berhenti di sini dan TIDAK ADA apapun yang dikirim
    // ke PortfolioProvider. Berlaku sama untuk semua kelas aset.
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = _priceFieldKey.currentState!.amountInIdr;
    final fee = CurrencyInputHelper.unformatIdr(_feeCtrl.text);
    final yieldPercent = double.tryParse(_yieldCtrl.text.replaceAll(',', '.')) ?? 0;

    if (price <= 0) {
      setState(() => _error = 'Harga per Unit harus lebih besar dari 0');
      return;
    }

    // Validasi nominal minimum (butuh qty & harga sekaligus, jadi baru bisa
    // dicek di sini, bukan di validator field Qty) — khusus Reksadana.
    final minAmountError = AssetValidationService.validateMinPurchaseAmount(
      assetClass: _assetClass,
      qty: qty,
      pricePerUnit: price,
    );
    if (minAmountError != null) {
      setState(() => _error = minAmountError);
      return;
    }

    final ticker = _tickerCtrl.text.trim();

    if (_isBuy) {
      final totalCost = (qty * price) + fee;

      if (_useCashFunding) {
        if (_fundingAccountId == null) {
          setState(() => _error = 'Pilih akun sumber dana terlebih dahulu');
          return;
        }
        final balance = cashFlow.balanceOf(_fundingAccountId!);
        if (balance < totalCost) {
          setState(() => _error =
              'Saldo akun tidak cukup. Tersedia ${AppFormatters.rupiah(balance)}, dibutuhkan ${AppFormatters.rupiah(totalCost)}.');
          return;
        }
      }

      provider.buyAsset(
        ticker: ticker,
        name: _nameCtrl.text.trim().isEmpty ? ticker : _nameCtrl.text.trim(),
        assetClass: _assetClass,
        qty: qty,
        pricePerUnit: price,
        fee: fee,
        date: _date,
        annualYieldPercent: yieldPercent,
      );

      if (_useCashFunding) {
        cashFlow.adjustAccountBalance(_fundingAccountId!, -totalCost);
      }

      // Auto-update harga pasar tanpa user perlu klik refresh manual.
      provider.fetchSinglePrice(ticker, _assetClass);

      _showSaved(context, 'Transaksi beli aset berhasil disimpan');
    } else {
      final err = provider.sellAsset(
        ticker: ticker,
        qty: qty,
        pricePerUnit: price,
        fee: fee,
        date: _date,
      );
      if (err != null) {
        setState(() => _error = err);
        return;
      }

      if (_useCashFunding) {
        if (_fundingAccountId == null) {
          setState(() => _error = 'Pilih akun tujuan dana terlebih dahulu');
          return;
        }
        final proceeds = (qty * price) - fee;
        cashFlow.adjustAccountBalance(_fundingAccountId!, proceeds);
      }

      provider.fetchSinglePrice(ticker, _assetClass);

      _showSaved(context, 'Transaksi jual aset berhasil disimpan');
    }

    _tickerCtrl.clear();
    _nameCtrl.clear();
    _qtyCtrl.clear();
    _priceFieldKey.currentState!.clear();
    _feeCtrl.text = '0';
    _yieldCtrl.clear();
    setState(() {
      _quote = null;
      _quoteError = null;
      _livePriceIdr = 0;
    });
  }
}

// =====================================================================
// TAB 3: UTANG / PIUTANG
// =====================================================================
class _DebtForm extends StatefulWidget {
  const _DebtForm();

  @override
  State<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends State<_DebtForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountFieldKey = GlobalKey<CurrencyAmountFieldState>();
  DebtType _type = DebtType.debt;
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();
    final exchangeRate = context.watch<ExchangeRateProvider>().rate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<DebtType>(
                segments: const [
                  ButtonSegment(value: DebtType.debt, label: Text('Utang Saya')),
                  ButtonSegment(value: DebtType.receivable, label: Text('Piutang Saya')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              _label('Nama Pihak Kedua'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Nama orang/lembaga'),
                validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              CurrencyAmountField(
                key: _amountFieldKey,
                label: 'Nominal',
                hint: 'Jumlah pinjaman',
                exchangeRate: exchangeRate,
                validator: (v) => (v == null || v.isEmpty) ? 'Nominal wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _label('Tanggal Jatuh Tempo'),
              _dateField(_dueDate, (d) => setState(() => _dueDate = d)),
              const SizedBox(height: 14),
              _label('Catatan (opsional)'),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(hintText: 'Keterangan tambahan'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _submit(provider),
                child: const Text('Simpan Data'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit(DebtProvider provider) {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountFieldKey.currentState!.amountInIdr;
    if (amount <= 0) return;

    provider.addDebt(
      type: _type,
      counterpartyName: _nameCtrl.text.trim(),
      principal: amount,
      dueDate: _dueDate,
      note: _noteCtrl.text,
    );

    _nameCtrl.clear();
    _amountFieldKey.currentState!.clear();
    _noteCtrl.clear();
    _showSaved(context, 'Data utang/piutang berhasil disimpan');
  }
}

// =====================================================================
// SHARED HELPERS
// =====================================================================
Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );

Widget _balanceCaption(BuildContext context, double balance) {
  final scheme = Theme.of(context).colorScheme;
  return Row(
    children: [
      Icon(Icons.account_balance_wallet_outlined, size: 12, color: scheme.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(
        'Saldo tersedia: ${AppFormatters.rupiah(balance)}',
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

Widget _dateField(DateTime date, ValueChanged<DateTime> onChanged) {
  return Builder(
    builder: (context) => InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 10),
            Text(AppFormatters.date(date)),
          ],
        ),
      ),
    ),
  );
}

void _showSaved(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

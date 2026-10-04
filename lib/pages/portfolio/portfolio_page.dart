import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset_holding_model.dart';
import '../../providers/portfolio_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/formatters.dart';
import '../../widgets/display_currency_toggle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_text.dart';
import '../../widgets/portfolio_item_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/theme_mode_toggle.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  AssetClass? _filter;
  bool _isFetching = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final holdings = provider.activeHoldings
        .where((h) => _filter == null || h.assetClass == _filter)
        .toList()
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showUpdatePriceSheet(context, provider),
          icon: const Icon(Icons.price_change_outlined),
          label: const Text('Update Manual'),
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchFromApi(context, provider, silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                title: const Text('Portofolio', style: TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  const ThemeModeToggle(),
                  const DisplayCurrencyToggle(),
                  IconButton(
                    tooltip: 'Fetch Harga dari API (Crypto, Saham, Emas)',
                    onPressed: _isFetching ? null : () => _fetchFromApi(context, provider),
                    icon: _isFetching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_sync_outlined),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _summaryHeader(provider),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.swipe_down_alt_rounded, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Tarik ke bawah untuk refresh harga (Crypto/Saham/Emas otomatis)',
                          style: TextStyle(fontSize: 10.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(
                      icon: Icons.filter_list_rounded,
                      color: AppColors.matchaDarkest,
                      title: 'Holding Anda',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('Semua', null),
                          for (final c in AssetClass.values) _filterChip(c.label, c),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (holdings.isEmpty)
                      const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Belum ada aset di kategori ini',
                        subtitle: 'Tambahkan lewat tab Input > Investasi',
                      )
                    else
                      ...holdings.map((h) => PortfolioItemTile(
                            holding: h,
                            onUpdatePrice: () => _showUpdateSingleAsset(context, provider, h),
                          )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, AssetClass? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _summaryHeader(PortfolioProvider provider) {
    final gain = provider.totalGainLoss;
    final gainColor = gain >= 0 ? AppColors.gain : AppColors.loss;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.matchaDarkest, AppColors.matchaDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Nilai Portofolio', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
          const SizedBox(height: 6),
          MoneyText(
            amountInIdr: provider.totalMarketValue,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statColumn('Cost Basis', MoneyText(amountInIdr: provider.totalCostBasis, style: _statStyle)),
              ),
              Expanded(
                child: _statColumn(
                  'Total Gain/Loss',
                  MoneyText(amountInIdr: gain, signed: true, style: _statStyle),
                ),
              ),
              Expanded(
                child: _statColumn(
                  'Realized G/L',
                  MoneyText(amountInIdr: provider.totalRealizedGainLoss, signed: true, style: _statStyle),
                ),
              ),
            ],
          ),
          if (provider.totalYieldGain > 0) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 14),
            _statColumn(
              'Estimasi Yield Gain (Reksadana Pasar Uang)',
              MoneyText(amountInIdr: provider.totalYieldGain, signed: true, style: _statStyle),
            ),
          ],
        ],
      ),
    );
  }

  static const _statStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white);

  Widget _statColumn(String label, Widget valueWidget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
        const SizedBox(height: 3),
        valueWidget,
      ],
    );
  }

  void _showUpdatePriceSheet(BuildContext context, PortfolioProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Harga Pasar Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Harga selalu diisi/ditampilkan dalam Rupiah (IDR) di sini, terlepas dari mata uang tampilan yang aktif.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: provider.activeHoldings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final h = provider.activeHoldings[i];
                        return _PriceEditRow(holding: h, provider: provider);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateSingleAsset(BuildContext context, PortfolioProvider provider, AssetHoldingModel holding) {
    final ctrl = TextEditingController(text: holding.marketPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Harga ${holding.ticker}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          decoration: const InputDecoration(labelText: 'Harga pasar baru (Rp)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final price = CurrencyInputHelper.unformatIdr(ctrl.text);
              if (price > 0) {
                provider.updateMarketPrice(holding.ticker, price);
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// [silent] = true dipakai saat trigger dari pull-to-refresh (tanpa cek
  /// "belum ada aset" duluan, karena RefreshIndicator selalu perlu Future
  /// yang selesai supaya animasinya berhenti dengan benar).
  Future<void> _fetchFromApi(BuildContext context, PortfolioProvider provider, {bool silent = false}) async {
    if (provider.activeHoldings.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada aset di portofolio'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    setState(() => _isFetching = true);
    final results = await provider.fetchMarketPricesFromApi();
    if (!mounted) return;
    setState(() => _isFetching = false);

    final success = results.where((r) => r.success).toList();
    final failed = results.where((r) => !r.success).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Fetch Harga dari API'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (success.isNotEmpty) ...[
                  Text('Berhasil diperbarui (${success.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gain, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...success.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${r.ticker}: ${AppFormatters.rupiah(r.price!)}', style: const TextStyle(fontSize: 12)),
                      )),
                  const SizedBox(height: 10),
                ],
                if (failed.isNotEmpty) ...[
                  Text('Tidak bisa diperbarui otomatis (${failed.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...failed.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• ${r.ticker}: ${r.error}',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }
}

class _PriceEditRow extends StatefulWidget {
  final AssetHoldingModel holding;
  final PortfolioProvider provider;
  const _PriceEditRow({required this.holding, required this.provider});

  @override
  State<_PriceEditRow> createState() => _PriceEditRowState();
}

class _PriceEditRowState extends State<_PriceEditRow> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.holding.marketPrice.toStringAsFixed(0));

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(widget.holding.ticker, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            onSubmitted: (v) {
              final price = CurrencyInputHelper.unformatIdr(v);
              if (price > 0) {
                widget.provider.updateMarketPrice(widget.holding.ticker, price);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline, size: 20),
          onPressed: () {
            final price = CurrencyInputHelper.unformatIdr(_ctrl.text);
            if (price > 0) {
              widget.provider.updateMarketPrice(widget.holding.ticker, price);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Harga ${widget.holding.ticker} diperbarui'), behavior: SnackBarBehavior.floating),
              );
            }
          },
        ),
      ],
    );
  }
}

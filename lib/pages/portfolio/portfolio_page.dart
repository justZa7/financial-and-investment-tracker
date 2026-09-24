import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset_holding_model.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/market_data_service.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/formatters.dart';
import '../../widgets/portfolio_item_tile.dart';

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
          label: const Text('Update Harga'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Portofolio', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  tooltip: 'Fetch Harga dari API (Crypto & Saham)',
                  onPressed: _isFetching ? null : () => _fetchFromApi(context, provider),
                  icon: _isFetching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_sync_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _summaryHeader(provider),
                  const SizedBox(height: 18),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Belum ada aset di kategori ini',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ),
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
    final gainColor = gain >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Nilai Portofolio', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              AppFormatters.rupiah(provider.totalMarketValue),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _statColumn('Cost Basis', AppFormatters.rupiah(provider.totalCostBasis)),
                ),
                Expanded(
                  child: _statColumn(
                    'Total Gain/Loss',
                    AppFormatters.rupiahSigned(gain),
                    color: gainColor,
                  ),
                ),
                Expanded(
                  child: _statColumn(
                    'Realized G/L',
                    AppFormatters.rupiahSigned(provider.totalRealizedGainLoss),
                    color: provider.totalRealizedGainLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (provider.totalYieldGain > 0) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _statColumn(
                'Estimasi Yield Gain (Reksadana Pasar Uang)',
                AppFormatters.rupiahSigned(provider.totalYieldGain),
                color: Colors.teal.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
                  const Text('Update Harga Pasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Perbarui harga pasar semua aset agar nilai portofolio & chart ter-update',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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

  Future<void> _fetchFromApi(BuildContext context, PortfolioProvider provider) async {
    if (provider.activeHoldings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada aset di portofolio'), behavior: SnackBarBehavior.floating),
      );
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...success.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${r.ticker}: ${AppFormatters.rupiah(r.price!)}', style: const TextStyle(fontSize: 12)),
                      )),
                  const SizedBox(height: 10),
                ],
                if (failed.isNotEmpty) ...[
                  Text('Tidak bisa diperbarui otomatis (${failed.length})',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...failed.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• ${r.ticker}: ${r.error}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
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
      TextEditingController(text: widget.holding.marketPrice.toString());

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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            onSubmitted: (v) {
              final price = double.tryParse(v.replaceAll(',', '.'));
              if (price != null && price > 0) {
                widget.provider.updateMarketPrice(widget.holding.ticker, price);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline, size: 20),
          onPressed: () {
            final price = double.tryParse(_ctrl.text.replaceAll(',', '.'));
            if (price != null && price > 0) {
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

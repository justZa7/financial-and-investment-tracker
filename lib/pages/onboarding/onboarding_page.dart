import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardSlide({required this.icon, required this.title, required this.description});
}

const _slides = [
  _OnboardSlide(
    icon: Icons.eco_rounded,
    title: 'Selamat Datang di MatchaFin',
    description:
        'Catat arus kas harian, kelola portofolio investasi lintas aset, dan pantau utang-piutang — semua dalam satu aplikasi, tanpa ribet login.',
  ),
  _OnboardSlide(
    icon: Icons.dashboard_rounded,
    title: 'Dashboard Ringkas',
    description:
        'Lihat Net Worth, savings rate, alokasi aset, dan grafik performance sekali lihat. Tap kartu Kas untuk rincian per akun.',
  ),
  _OnboardSlide(
    icon: Icons.show_chart_rounded,
    title: 'Investasi Jadi Simpel',
    description:
        'Beli/jual saham, crypto, emas, atau reksadana dengan harga pasar live, validasi otomatis (misal kelipatan lot saham), dan pilihan pakai dana baru atau dari kas.',
  ),
  _OnboardSlide(
    icon: Icons.swap_horiz_rounded,
    title: 'Transfer, Budget & Target Tabungan',
    description:
        'Pindahkan dana antar akun, set batas pengeluaran bulanan per kategori, dan buat target tabungan (dana darurat, liburan, dll) yang terhubung ke saldo akunmu.',
  ),
  _OnboardSlide(
    icon: Icons.lock_rounded,
    title: 'Aman & Privat',
    description:
        'Aktifkan kunci PIN/biometric lewat ikon ⚙️ Pengaturan di Dashboard supaya data finansialmu tetap privat. Salah input? Tap transaksi di Riwayat untuk edit atau hapus.',
  ),
];

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.matchaBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Lewati', style: TextStyle(color: AppColors.matchaDarkest)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.matchaDarkest,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(color: AppColors.matchaDarkest.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Icon(slide.icon, size: 48, color: AppColors.latteFoam),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.matchaDarkest),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B6350)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? AppColors.matchaDarkest : AppColors.matchaPale,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.matchaDarkest,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    if (isLast) {
                      widget.onDone();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  child: Text(isLast ? 'Mulai' : 'Lanjut'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

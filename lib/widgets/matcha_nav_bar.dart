import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class MatchaNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const MatchaNavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Bottom navigation bar "pil" mengambang — satu batang hijau matcha penuh
/// rounded, item yang aktif berubah jadi kapsul krem (latte foam) berisi
/// ikon + label, item lain cuma tampil ikon. Desain mengikuti referensi
/// yang diberikan user, direcolor ke identitas MatchaFin.
///
/// CATATAN FIX OVERFLOW: versi awal memakai `Expanded` untuk membagi 5 item
/// jadi slot sama lebar — di layar sempit, slot itu lebih kecil dari ruang
/// yang dibutuhkan ikon+label item aktif, jadi overflow beberapa pixel.
/// Sekarang tiap item cuma mengambil lebar sesuai kontennya sendiri
/// (natural sizing + `MainAxisAlignment.spaceBetween`, TANPA Expanded), dan
/// label dibungkus `FittedBox` sebagai jaring pengaman kedua — kalau
/// suatu saat tetap kekurangan ruang (misal HP sangat sempit atau label
/// diganti lebih panjang), teksnya otomatis mengecil alih-alih overflow.
class MatchaNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<MatchaNavItem> items;

  const MatchaNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.matchaDarkest,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.matchaDarkest.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            return _NavPill(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onDestinationSelected(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final MatchaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavPill({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 11, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.latteFoam : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: selected ? AppColors.matchaDarkest : AppColors.latteFoam.withAlpha(55),
              ),
              // Label hanya dirender saat item aktif; AnimatedSize bikin
              // transisi muncul/hilangnya halus, FittedBox jadi jaring
              // pengaman supaya TIDAK PERNAH overflow berapapun lebar layar.
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: selected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 74),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(
                                  color: AppColors.matchaDarkest,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(width: 0, height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

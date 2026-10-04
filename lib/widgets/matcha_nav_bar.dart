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
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.matchaDarkest,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.matchaDarkest.withAlpha(35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == selectedIndex;
            final item = items[i];
            
            return Expanded(
              flex: selected ? 3 : 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDestinationSelected(i),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 12 : 0, 
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.latteFoam : Colors.transparent,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: ClipRect( // <--- PERBAIKAN 1: Memotong overflow selama animasi berjalan
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.selectedIcon : item.icon,
                            size: 20,
                            color: selected
                                ? AppColors.matchaDarkest
                                : AppColors.latteFoam.withOpacity(0.55),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: selected
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: FittedBox( // <--- PERBAIKAN 2: Menyesuaikan teks secara otomatis jika terlalu sempit
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(
                                          color: AppColors.matchaDarkest,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 0, height: 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

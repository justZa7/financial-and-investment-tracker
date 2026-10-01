/// Implementasi Merge Sort generik (manual, bukan cuma panggil List.sort()
/// bawaan Dart) — dipakai untuk mengurutkan daftar transaksi di halaman
/// History berdasarkan nominal (Terbesar/Terkecil).
///
/// Kompleksitas waktu: O(n log n) di semua kasus (best/average/worst),
/// kompleksitas ruang: O(n) karena butuh array bantu saat merge.
/// Stabil: elemen dengan nilai compare yang sama tetap mempertahankan
/// urutan relatif aslinya (penting supaya transaksi dengan nominal sama
/// tidak "loncat-loncat" urutannya tiap kali di-sort ulang).
///
/// [compare] mengikuti kontrak Comparator biasa: negatif kalau a harus
/// ditaruh sebelum b, positif kalau sebaliknya, 0 kalau setara.
List<T> mergeSort<T>(List<T> input, int Function(T a, T b) compare) {
  if (input.length <= 1) return List<T>.from(input);

  final mid = input.length ~/ 2;
  final left = mergeSort(input.sublist(0, mid), compare);
  final right = mergeSort(input.sublist(mid), compare);

  return _merge(left, right, compare);
}

List<T> _merge<T>(List<T> left, List<T> right, int Function(T a, T b) compare) {
  final result = <T>[];
  var i = 0, j = 0;

  while (i < left.length && j < right.length) {
    // "<= 0" (bukan cuma "< 0") menjaga sifat stabil: kalau nilainya sama,
    // elemen dari `left` (yang datang lebih dulu) didahulukan.
    if (compare(left[i], right[j]) <= 0) {
      result.add(left[i]);
      i++;
    } else {
      result.add(right[j]);
      j++;
    }
  }

  result.addAll(left.sublist(i));
  result.addAll(right.sublist(j));
  return result;
}

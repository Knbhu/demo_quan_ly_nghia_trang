class GiaThamKhao {
  GiaThamKhao._();

  static const int moDon = 180000000;
  static const int moDoi = 390000000;
  static const int moGiaToc = 2800000000;
  static const int oLuuTroCot = 45000000;

  static int choLo(Map<String, dynamic> plot) {
    final zone = (plot['zone_code'] ?? plot['zone'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final type = (plot['plot_type'] ?? '').toString().trim().toUpperCase();

    if (type.contains('URN') ||
        type.contains('COAT') ||
        type.contains('NICHE')) {
      return oLuuTroCot;
    }
    if (zone == 'M2' || type == 'DOUBLE') return moDoi;
    if (zone == 'M7' || zone == 'M8') return moGiaToc;
    if (const {'M1', 'M3', 'M4', 'M5', 'M6'}.contains(zone)) return moDon;

    final databasePrice = num.tryParse(plot['price']?.toString() ?? '') ?? 0;
    return databasePrice.round();
  }

  static String dinhDang(num amount) =>
      '${amount.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';
}

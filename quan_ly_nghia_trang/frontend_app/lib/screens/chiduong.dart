import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/mausala.dart';

class ChiDuongPage extends StatelessWidget {
  const ChiDuongPage({super.key, required this.hoSoMo});

  final Map<String, dynamic> hoSoMo;

  @override
  Widget build(BuildContext context) {
    final ten = (hoSoMo['full_name'] ?? hoSoMo['memorial_name'] ?? 'Hồ sơ phần mộ').toString();
    final maMo = (hoSoMo['plot_code'] ?? '').toString();
    final khu = (hoSoMo['zone_name'] ?? hoSoMo['zone_code'] ?? '').toString();
    final phapDanh = (hoSoMo['dharma_name'] ?? '').toString();
    final namSinh = _nam(hoSoMo['date_of_birth']);
    final namMat = _nam(hoSoMo['date_of_death']);
    final lat = double.tryParse('${hoSoMo['latitude'] ?? ''}');
    final lng = double.tryParse('${hoSoMo['longitude'] ?? ''}');
    return Scaffold(
      backgroundColor: MauSala.nen,
      appBar: AppBar(
        backgroundColor: MauSala.nen,
        title: Text('SALA GARDEN', style: GoogleFonts.newsreader(color: MauSala.xanhDam, fontWeight: FontWeight.w600)),
        actions: [TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home_outlined), label: const Text('Trang chủ'))],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1240), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, size: 17), label: const Text('Quay lại trang chủ')),
            const Text('/'), const Text('Tra cứu vị trí & chỉ đường', style: TextStyle(color: MauSala.xanhDam)),
          ]),
          const SizedBox(height: 12),
          Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [const CircleAvatar(backgroundColor: MauSala.xanhThe, child: Icon(Icons.location_searching, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Thông tin & vị trí phần mộ', style: GoogleFonts.newsreader(fontSize: 23, color: MauSala.xanhDam)), Text('Kết quả tra cứu công khai • Mã phần mộ $maMo', style: const TextStyle(color: MauSala.chuPhu, fontSize: 12))]))]))),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, box) {
            final compact = box.maxWidth < 820;
            final profile = _hoSo(ten, phapDanh, namSinh, namMat, maMo, khu);
            final direction = _chiDuong(context, ten, maMo, khu, lat, lng);
            return compact ? Column(children: [profile, const SizedBox(height: 16), direction]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: profile), const SizedBox(width: 18), Expanded(flex: 5, child: direction)]);
          }),
          const SizedBox(height: 16),
          _soDo(maMo, khu, hoSoMo['row_num'], hoSoMo['col_num']),
          const SizedBox(height: 18),
          Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.info_outline, color: MauSala.xanhThe), const SizedBox(width: 10), Expanded(child: Text('Trang khách vãng lai chỉ hiển thị thông tin mộ và chức năng chỉ đường. Hợp đồng cùng các dịch vụ cá nhân cần đăng nhập.', style: GoogleFonts.manrope(fontSize: 12, color: MauSala.chuPhu, height: 1.5)))]))),
        ]))),
      ]),
    );
  }

  Widget _hoSo(String ten, String phapDanh, String namSinh, String namMat, String maMo, String khu) => Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(gradient: LinearGradient(colors: [MauSala.xanhDam, MauSala.xanhThe])), child: Row(children: [
            Container(width: 86, height: 106, decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(42), border: Border.all(color: MauSala.vangThe, width: 4)), child: const Icon(Icons.person, size: 52, color: MauSala.xanhThe)),
            const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('HƯƠNG LINH TÔN KÍNH', style: TextStyle(color: Color(0xFFFFDEA5), fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(height: 6), Text(ten, style: GoogleFonts.newsreader(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600)),
              if (phapDanh.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text('Pháp danh: $phapDanh', style: const TextStyle(color: Color(0xFFBAEED9)))),
              const SizedBox(height: 10), Text('Năm sinh: $namSinh    •    Năm mất: $namMat', style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 5), Text('Mã phần mộ: $maMo', style: const TextStyle(color: Color(0xFFFFDEA5), fontWeight: FontWeight.w600)),
            ])),
          ])),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vị trí phần mộ', style: GoogleFonts.newsreader(fontSize: 21, color: MauSala.xanhDam)), const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _thongTin('Phân khu', khu.isEmpty ? 'Đang cập nhật' : khu, Icons.park_outlined),
              _thongTin('Mã phần mộ', maMo, Icons.location_on_outlined),
              _thongTin('Hàng mộ', 'R${hoSoMo['row_num'] ?? '—'}', Icons.view_agenda_outlined),
              _thongTin('Ô mộ', 'C${hoSoMo['col_num'] ?? '—'}', Icons.grid_view_outlined),
            ]),
          ])),
        ]),
      );

  Widget _chiDuong(BuildContext context, String ten, String maMo, String khu, double? lat, double? lng) => Card(
        color: Colors.white,
        child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(backgroundColor: MauSala.xanhDam, child: Icon(Icons.navigation, color: Colors.white)),
          const SizedBox(height: 14), Text('Dẫn Đường Đến Phần Mộ', style: GoogleFonts.newsreader(fontSize: 24, color: MauSala.xanhDam)),
          const SizedBox(height: 8), Text('Vị trí $maMo • $khu', style: const TextStyle(color: MauSala.vang, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12), Text(lat != null && lng != null ? 'Tọa độ: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}' : 'Tọa độ dẫn đường đang được cập nhật. Vui lòng liên hệ hotline để được hướng dẫn tại hoa viên.', style: GoogleFonts.manrope(fontSize: 13, color: MauSala.chuPhu, height: 1.6)),
          if (lat != null && lng != null) ...[
            const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _moBanDo(lat, lng), icon: const Icon(Icons.map_outlined), label: const Text('Mở chỉ đường trên bản đồ'), style: FilledButton.styleFrom(backgroundColor: MauSala.xanhDam, padding: const EdgeInsets.symmetric(vertical: 15)))),
            const SizedBox(height: 8), const Text('Mã QR tại khu mộ cũng mở đường dẫn chỉ đường này.', style: TextStyle(fontSize: 11, color: MauSala.chuPhu)),
          ],
          const SizedBox(height: 18), Container(height: 1, color: MauSala.xanhNenThe), const SizedBox(height: 14),
          Row(children: [const Icon(Icons.phone_in_talk, color: MauSala.vang), const SizedBox(width: 8), Expanded(child: Text('Cần hỗ trợ tìm đường?\nHotline 24/7: 1900 68xx', style: GoogleFonts.manrope(fontSize: 12, color: MauSala.chuPhu, height: 1.6)))]),
        ])),
      );

  Widget _soDo(String maMo, String khu, dynamic row, dynamic col) {
    final r = int.tryParse('$row') ?? 5;
    final c = int.tryParse('$col') ?? 3;
    return Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.map, color: MauSala.xanhThe), const SizedBox(width: 8), Expanded(child: Text('Sơ Đồ Phân Khu ${khu.isEmpty ? '' : '• $khu'}', style: GoogleFonts.newsreader(fontSize: 21, color: MauSala.xanhDam)))]),
      const SizedBox(height: 14), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)), child: Column(children: [
        Container(height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(4)), child: const Text('LỐI ĐI NỘI KHU', style: TextStyle(fontSize: 9, color: MauSala.chuPhu, letterSpacing: 1))),
        const SizedBox(height: 10),
        ...List.generate(5, (ri) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [SizedBox(width: 46, child: Text('R${(r - 2 + ri).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 9, color: MauSala.chuPhu))), Expanded(child: Row(children: List.generate(7, (ci) { final selected = ri == 2 && ci == 3; return Expanded(child: Container(height: 31, margin: const EdgeInsets.symmetric(horizontal: 2), alignment: Alignment.center, decoration: BoxDecoration(color: selected ? MauSala.xanhDam : Colors.white, borderRadius: BorderRadius.circular(3), border: Border.all(color: selected ? MauSala.vang : MauSala.vien, width: selected ? 2 : .5)), child: Text(selected ? maMo : 'Ô${(c - 3 + ci).abs() + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: selected ? 7 : 8, color: selected ? Colors.white : MauSala.chuPhu, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))); }))) ]))),
        Container(height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(4)), child: const Text('LỐI ĐI BỘ', style: TextStyle(fontSize: 9, color: MauSala.chuPhu, letterSpacing: 1))),
      ])),
      const SizedBox(height: 10), const Text('Sơ đồ minh họa vị trí. Hướng dẫn thực tế có thể thay đổi theo lối đi đang mở.', style: TextStyle(fontSize: 11, color: MauSala.chuPhu)),
    ])));
  }

  Widget _thongTin(String label, String value, IconData icon) => Container(width: 145, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: MauSala.vang, size: 18), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 10, color: MauSala.chuPhu)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 13, color: MauSala.xanhDam, fontWeight: FontWeight.w700))]));

  static String _nam(dynamic value) {
    if (value == null) return '—';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) return '${parsed.year}';
    return value.toString().length >= 4 ? value.toString().substring(0, 4) : value.toString();
  }

  static Future<void> _moBanDo(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

}

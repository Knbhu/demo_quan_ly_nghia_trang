import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/mausala.dart';

class ChiDuongThanNhan extends StatefulWidget {
  const ChiDuongThanNhan({
    super.key,
    required this.contracts,
    required this.onOpenContracts,
    required this.onOpenCare,
  });

  final List<dynamic> contracts;
  final VoidCallback onOpenContracts;
  final VoidCallback onOpenCare;

  @override
  State<ChiDuongThanNhan> createState() => _ChiDuongThanNhanState();
}

class _ChiDuongThanNhanState extends State<ChiDuongThanNhan> {
  int _selectedIndex = 0;

  List<Map<String, dynamic>> get _plots {
    final unique = <String, Map<String, dynamic>>{};
    for (final item in widget.contracts) {
      if (item is! Map) continue;
      final contract = Map<String, dynamic>.from(item);
      final code = contract['plot_code']?.toString();
      if (code != null && code.isNotEmpty) unique.putIfAbsent(code, () => contract);
    }
    return unique.values.toList();
  }

  Map<String, dynamic>? get _plot => _plots.isEmpty
      ? null
      : _plots[_selectedIndex.clamp(0, _plots.length - 1).toInt()];

  String _text(dynamic value, [String fallback = 'Chưa cập nhật']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty || result == 'null' ? fallback : result;
  }

  double? _number(dynamic value) => value == null ? null : double.tryParse(value.toString());

  Future<void> _openMaps() async {
    final plot = _plot;
    final lat = _number(plot?['latitude']);
    final lng = _number(plot?['longitude']);
    if (lat == null || lng == null) {
      _message('Hồ sơ mộ này chưa có tọa độ GPS. Sơ đồ dưới đây là sơ đồ minh họa nội khu; vui lòng liên hệ Sala Garden để được dẫn đường chính xác.');
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _message('Không mở được Google Maps trên thiết bị này.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final plots = _plots;
    final plot = _plot;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 980;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader(plot, plots),
          const SizedBox(height: 18),
          if (plots.isEmpty)
            _emptyState()
          else if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: _mapAndSteps(plot!)),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: _destinationPanel(plot)),
            ])
          else ...[
            _destinationPanel(plot!),
            const SizedBox(height: 14),
            _mapAndSteps(plot),
          ],
        ]),
      );
    });
  }

  Widget _pageHeader(Map<String, dynamic>? plot, List<Map<String, dynamic>> plots) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: MauSala.xanhThe, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.explore_outlined, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('HỆ THỐNG DẪN ĐƯỜNG THÂN NHÂN', style: TextStyle(color: MauSala.vang, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .8)),
              Text('Định Vị & Chỉ Đường Mộ Phần', style: GoogleFonts.newsreader(fontSize: 27, color: MauSala.xanhDam, fontWeight: FontWeight.w600)),
            ])),
            if (plot != null) _gpsBadge(plot),
          ]),
          const SizedBox(height: 12),
          if (plots.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: MauSala.vien.withValues(alpha: .4))),
              child: Row(children: [
                const Icon(Icons.location_on_outlined, color: MauSala.vang, size: 18),
                const SizedBox(width: 8),
                const Text('Hồ sơ mộ:', style: TextStyle(color: MauSala.chuPhu, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(child: DropdownButton<int>(
                  value: _selectedIndex.clamp(0, plots.length - 1).toInt(),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: List.generate(plots.length, (i) => DropdownMenuItem(value: i, child: Text('${_text(plots[i]['plot_code'])} — ${_text(plots[i]['beneficiary_display_name'], _text(plots[i]['beneficiary_name'], 'Thân nhân'))}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  onChanged: (value) => setState(() => _selectedIndex = value ?? 0),
                )),
              ]),
            ),
        ],
      );

  Widget _gpsBadge(Map<String, dynamic> plot) {
    final ready = _number(plot['latitude']) != null && _number(plot['longitude']) != null;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: ready ? const Color(0xFFDDF4E8) : MauSala.xanhNhat, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(ready ? Icons.gps_fixed : Icons.gps_not_fixed, size: 14, color: ready ? MauSala.xanhThe : MauSala.vang), const SizedBox(width: 5), Text(ready ? 'Đã có tọa độ GPS' : 'Chưa có tọa độ GPS', style: TextStyle(fontSize: 10, color: ready ? MauSala.xanhDam : MauSala.vang, fontWeight: FontWeight.w600))]));
  }

  Widget _mapAndSteps(Map<String, dynamic> plot) => Column(children: [
        _mapCard(plot),
        const SizedBox(height: 14),
        _routeSteps(plot),
      ]);

  Widget _mapCard(Map<String, dynamic> plot) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: MauSala.vien.withValues(alpha: .35)), boxShadow: const [BoxShadow(color: Color(0x0B003629), blurRadius: 14, offset: Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.route, color: MauSala.xanhThe, size: 18), const SizedBox(width: 7), const Expanded(child: Text('Sơ đồ đường đi trong hoa viên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MauSala.xanhDam))), Text('SƠ ĐỒ MINH HỌA', style: TextStyle(fontSize: 8, letterSpacing: .5, color: MauSala.chuPhu))]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 350, child: CustomPaint(size: Size.infinite, painter: _GardenMapPainter(plotCode: _text(plot['plot_code']), zone: _text(plot['zone_code'], _text(plot['zone_name'], 'Khu mộ'))), child: Stack(children: [
            Positioned(left: 12, top: 12, child: _mapLabel(Icons.circle, 'Cổng Chính', MauSala.xanhDam)),
            Positioned(right: 12, top: 12, child: _mapLabel(Icons.temple_buddhist, 'Đền Trình Sala', MauSala.xanhThe)),
            Positioned(left: 14, bottom: 14, child: _mapLabel(Icons.directions_walk, 'Bạn đang xem sơ đồ nội khu', MauSala.chuPhu)),
            Positioned(right: 14, bottom: 14, child: _mapLabel(Icons.place, _text(plot['plot_code']), const Color(0xFFB91C1C))),
          ])))),
          const SizedBox(height: 9),
          const Wrap(spacing: 14, runSpacing: 6, children: [
            _Legend(color: MauSala.xanhDam, label: 'Lối đi'),
            _Legend(color: MauSala.vangThe, label: 'Khuôn viên'),
            _Legend(color: Color(0xFFB91C1C), label: 'Mộ được chọn'),
          ]),
          const SizedBox(height: 8),
          const Text('Sơ đồ mang tính minh họa, chưa thể hiện vị trí GPS thực tế của từng lô.', style: TextStyle(fontSize: 10, color: MauSala.chuPhu)),
        ]),
      );

  Widget _mapLabel(IconData icon, String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(7), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MauSala.chu))]));

  Widget _destinationPanel(Map<String, dynamic> plot) {
    final code = _text(plot['plot_code']);
    final zone = _text(plot['zone_code'], _text(plot['zone_name'], 'Khu vực hoa viên'));
    final row = _text(plot['row_num'], '—');
    final col = _text(plot['col_num'], '—');
    final name = _text(plot['beneficiary_display_name'], _text(plot['beneficiary_name'], 'Hồ sơ thân nhân'));
    final lat = _number(plot['latitude']);
    final lng = _number(plot['longitude']);
    return Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [MauSala.xanhDam, MauSala.xanhThe], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(13), boxShadow: const [BoxShadow(color: Color(0x20003629), blurRadius: 16, offset: Offset(0, 6))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.place, color: MauSala.vangThe, size: 18), const SizedBox(width: 6), const Text('ĐIỂM ĐẾN CỦA GIA ĐÌNH', style: TextStyle(color: MauSala.vangThe, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: .7)), const Spacer(), Icon(lat != null && lng != null ? Icons.gps_fixed : Icons.gps_not_fixed, color: const Color(0xFFB8E9CC), size: 16)]),
        const SizedBox(height: 10),
        Text(name, style: GoogleFonts.newsreader(fontSize: 23, color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('Mã mộ: $code', style: const TextStyle(color: MauSala.vangThe, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 15),
        Container(height: 1, color: Colors.white24),
        const SizedBox(height: 13),
        Row(children: [Expanded(child: _metric('PHÂN KHU', zone)), Expanded(child: _metric('DÃY / Ô', 'R$row  •  Số $col'))]),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: MauSala.vangThe, borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.turn_left, color: MauSala.xanhDam)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LỘ TRÌNH GỢI Ý', style: TextStyle(color: MauSala.vangThe, fontSize: 9, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Cổng chính → Đền Trình Sala → phân khu mộ → dãy và ô theo hồ sơ đã chọn.', style: TextStyle(color: Colors.white, fontSize: 12, height: 1.45))]))])),
        const SizedBox(height: 10),
        Text(lat != null && lng != null ? 'Tọa độ: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}' : 'Chưa có tọa độ GPS cho hồ sơ này.', style: const TextStyle(color: Color(0xFFD5E8DD), fontSize: 10)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 44, child: FilledButton.icon(onPressed: _openMaps, style: FilledButton.styleFrom(backgroundColor: MauSala.vangThe, foregroundColor: MauSala.xanhDam), icon: const Icon(Icons.near_me, size: 17), label: Text(lat != null && lng != null ? 'Mở chỉ đường Google Maps' : 'Kiểm tra thông tin GPS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
      ])),
      const SizedBox(height: 12),
      _supportCard(Icons.directions_bus_filled_outlined, 'Xe điện nội khu', 'Gọi Hotline 1900 68xx để được hỗ trợ xe điện đưa đón đến phân khu.' , _call),
      const SizedBox(height: 10),
      _supportCard(Icons.volunteer_activism_outlined, 'Đặt hoa và thắp hương', 'Đăng ký chăm sóc tại mộ đã chọn và theo dõi ảnh nghiệm thu.', widget.onOpenCare),
      const SizedBox(height: 10),
      _supportCard(Icons.description_outlined, 'Thông tin hợp đồng', 'Xem hồ sơ, vị trí và người thụ hưởng đã liên kết.', widget.onOpenContracts),
    ]);
  }

  Future<void> _call() async { await launchUrl(Uri.parse('tel:19006800')); }

  Widget _metric(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFFB8E9CC), fontSize: 9, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))]);

  Widget _supportCard(IconData icon, String title, String subtitle, VoidCallback onTap) => Material(color: Colors.white, borderRadius: BorderRadius.circular(10), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: MauSala.xanhThe, size: 19)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: MauSala.xanhDam, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: MauSala.chuPhu, fontSize: 10, height: 1.4))])), const Icon(Icons.chevron_right, color: MauSala.vang, size: 19)]))));

  Widget _routeSteps(Map<String, dynamic> plot) {
    final zone = _text(plot['zone_code'], _text(plot['zone_name'], 'Khu mộ'));
    final row = _text(plot['row_num'], '—');
    final col = _text(plot['col_num'], '—');
    final steps = [
      ('01', 'Cổng Chính Hoa Viên', 'Bắt đầu từ cổng chính Sala Garden.'),
      ('02', 'Đền Trình Sala', 'Theo biển chỉ dẫn đến khu vực trung tâm.'),
      ('03', 'Phân khu $zone', 'Tiếp tục theo bảng chỉ dẫn trong phân khu.'),
      ('04', 'Mộ ${_text(plot['plot_code'])}', 'Dãy R$row, ô số $col.'),
    ];
    return Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: MauSala.vien.withValues(alpha: .35))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.alt_route, color: MauSala.xanhThe), SizedBox(width: 7), Text('Lộ trình từng chặng', style: TextStyle(fontSize: 14, color: MauSala.xanhDam, fontWeight: FontWeight.w700)), Spacer(), Text('Theo hồ sơ đã chọn', style: TextStyle(fontSize: 9, color: MauSala.chuPhu))]), const SizedBox(height: 12), LayoutBuilder(builder: (context, box) { final count = box.maxWidth < 500 ? 2 : 4; return Wrap(spacing: 8, runSpacing: 8, children: List.generate(steps.length, (i) => SizedBox(width: (box.maxWidth - 8 * (count - 1)) / count, child: _step(steps[i].$1, steps[i].$2, steps[i].$3, i == 3)))); })]));
  }

  Widget _step(String number, String title, String detail, bool destination) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: destination ? const Color(0xFFFFF3D8) : MauSala.xanhNhat, borderRadius: BorderRadius.circular(9), border: Border.all(color: destination ? MauSala.vangThe : Colors.transparent)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CHẶNG $number', style: TextStyle(fontSize: 8, color: destination ? MauSala.vang : MauSala.xanhThe, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(title, style: const TextStyle(fontSize: 12, color: MauSala.xanhDam, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(detail, style: const TextStyle(fontSize: 10, color: MauSala.chuPhu, height: 1.4))]));

  Widget _emptyState() => Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: MauSala.vien.withValues(alpha: .4))), child: Column(children: [const Icon(Icons.location_searching, color: MauSala.xanhThe, size: 42), const SizedBox(height: 12), Text('Tài khoản chưa có hồ sơ mộ liên kết', style: GoogleFonts.newsreader(fontSize: 22, color: MauSala.xanhDam, fontWeight: FontWeight.w600)), const SizedBox(height: 7), const Text('Khi hợp đồng được tạo hoặc liên kết với tài khoản, vị trí mộ sẽ xuất hiện tại đây để gia đình tra cứu đường đi.', textAlign: TextAlign.center, style: TextStyle(color: MauSala.chuPhu, fontSize: 12, height: 1.5)), const SizedBox(height: 16), FilledButton.icon(onPressed: widget.onOpenContracts, style: FilledButton.styleFrom(backgroundColor: MauSala.xanhDam), icon: const Icon(Icons.description_outlined), label: const Text('Mở mục Hợp đồng'))]));
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10, color: MauSala.chuPhu))]);
}

class _GardenMapPainter extends CustomPainter {
  const _GardenMapPainter({required this.plotCode, required this.zone});
  final String plotCode;
  final String zone;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F4EC);
    canvas.drawRect(Offset.zero & size, bg);
    final green = Paint()..color = const Color(0xFFD2E9D9);
    final pale = Paint()..color = const Color(0xFFF8FCF8);
    final road = Paint()..color = const Color(0xFFD9E8F2)..style = PaintingStyle.stroke..strokeWidth = 22..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final roadEdge = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 26..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .78)
      ..lineTo(size.width * .27, size.height * .78)
      ..lineTo(size.width * .27, size.height * .51)
      ..lineTo(size.width * .49, size.height * .51)
      ..lineTo(size.width * .49, size.height * .31)
      ..lineTo(size.width * .75, size.height * .31)
      ..lineTo(size.width * .75, size.height * .56)
      ..lineTo(size.width * .89, size.height * .56);
    canvas.drawOval(Rect.fromLTWH(size.width * .42, size.height * .06, size.width * .2, size.height * .16), green);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .08, size.height * .2, size.width * .21, size.height * .2), const Radius.circular(14)), pale);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .61, size.height * .66, size.width * .3, size.height * .2), const Radius.circular(14)), pale);
    canvas.drawPath(path, roadEdge);
    canvas.drawPath(path, road);
    final route = Paint()..color = MauSala.xanhThe..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawPath(path, route);
    final dashed = Paint()..color = MauSala.vang..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .32, size.height * .43, size.width * .32, size.height * .34), const Radius.circular(8)), dashed);
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 5; c++) {
        final rect = Rect.fromLTWH(size.width * (.35 + c * .053), size.height * (.49 + r * .075), size.width * .038, size.height * .052);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = (r == 1 && c == 3) ? const Color(0xFFB91C1C) : const Color(0xFFE7D7A7));
      }
    }
    final marker = Offset(size.width * .55, size.height * .68);
    canvas.drawCircle(marker, 12, Paint()..color = Colors.white);
    canvas.drawCircle(marker, 8, Paint()..color = const Color(0xFFB91C1C));
    canvas.drawCircle(marker, 3, Paint()..color = Colors.white);
    _drawText(canvas, zone.toUpperCase(), Offset(size.width * .35, size.height * .81), 10, MauSala.xanhDam, true);
    _drawText(canvas, 'HỒ TỊNH TÂM', Offset(size.width * .45, size.height * .13), 9, MauSala.xanhThe, true);
    _drawText(canvas, plotCode, Offset(marker.dx + 14, marker.dy - 6), 9, const Color(0xFFB91C1C), true);
  }

  void _drawText(Canvas canvas, String text, Offset position, double size, Color color, bool bold) {
    final painter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal)), textDirection: TextDirection.ltr)..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _GardenMapPainter oldDelegate) => oldDelegate.plotCode != plotCode || oldDelegate.zone != zone;
}

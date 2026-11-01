import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/mausala.dart';

enum SoDoViewer { khachVangLai, thanNhan, banQuanLy }

/// Sơ đồ quy hoạch tổng thể dùng chung cho khách, thân nhân và ban quản lý.
class SoDoTongQuan extends StatefulWidget {
  const SoDoTongQuan(
      {super.key,
      required this.viewer,
      this.linkedPlots = const [],
      this.onCreateContract,
      this.onLogin});
  final SoDoViewer viewer;
  final List<Map<String, dynamic>> linkedPlots;
  final ValueChanged<Map<String, dynamic>>? onCreateContract;
  final VoidCallback? onLogin;
  @override
  State<SoDoTongQuan> createState() => _SoDoTongQuanState();
}

class _SoDoTongQuanState extends State<SoDoTongQuan> {
  String _selected = 'M2', _view = 'Flycam thực địa', _filter = 'Tất cả 50ha';
  String _subZone = 'K01';
  String? _selectedUnit;
  bool _detail = false;
  double _zoom = 1;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _zones = [];
  Map<String, dynamic> _summary = {};
  bool _loading = false;
  bool get _guest => widget.viewer == SoDoViewer.khachVangLai;
  bool get _relative => widget.viewer == SoDoViewer.thanNhan;

  static const zones = <String, (String, String, IconData)>{
    'M1': ('Mộ đơn tiêu chuẩn', 'Vườn Sen Bạch Hạc', Icons.park_outlined),
    'M2': ('Mộ đôi trung tâm', 'Liền kề Nhà Điều Hành', Icons.favorite_border),
    'M3': (
      'Mộ gia đình & gia tộc',
      'Khuôn viên gia đình',
      Icons.groups_2_outlined
    ),
    'M4': (
      'Khu mộ Công Giáo',
      'Tượng Đức Mẹ & Thánh Giá',
      Icons.church_outlined
    ),
    'M5': (
      'Khu mộ tiêu chuẩn',
      'Phân khu sinh thái phía Đông',
      Icons.park_outlined
    ),
    'M6': ('Khu mộ tiêu chuẩn', 'Phân khu phía Bắc', Icons.park_outlined),
    'M7': ('Vườn Zen trung tâm', 'Đối diện Tịnh Xá Sala', Icons.yard_outlined),
    'M8': ('Mộ thượng hạng', 'Khuôn viên sinh thái', Icons.stars_outlined),
    'M11': (
      'Mộ gia tộc mở rộng',
      'Đại khuôn viên gia tộc 16 kim tĩnh',
      Icons.account_tree_outlined
    ),
  };
  static const places = <String, (String, String, IconData)>{
    'HO_TINH_TAM': (
      'Hồ Tịnh Tâm',
      'Cảnh quan và lối dạo bộ',
      Icons.water_outlined
    ),
    'SUOI_TAM_LINH': (
      'Suối Tâm Linh',
      'Cảnh quan sinh thái nội khu',
      Icons.waves_outlined
    ),
    'TINH_XA': (
      'Tịnh Xá Sala',
      'Không gian tâm linh',
      Icons.temple_buddhist_outlined
    ),
    'NHA_TANG_LE': (
      'Nhà Tang Lễ',
      'Khu tổ chức nghi lễ',
      Icons.account_balance_outlined
    ),
    'NHA_HOA_TANG': (
      'Nhà Hỏa Táng',
      'Khu hỏa táng',
      Icons.local_fire_department_outlined
    ),
    'NHA_HANG': (
      'Nhà Hàng Zen',
      'Ẩm thực và tiếp đón thân nhân',
      Icons.restaurant_outlined
    ),
    'NHA_DIEU_HANH': (
      'Nhà Điều Hành',
      'Trung tâm hỗ trợ hoa viên',
      Icons.apartment_outlined
    ),
    'CONG_CHINH': (
      'Cổng Chính',
      'Lối vào hoa viên',
      Icons.meeting_room_outlined
    ),
    'MGT_M11': (
      'MGT M11',
      'Khu vực theo quy hoạch tổng thể',
      Icons.location_city_outlined
    ),
  };

  static const layouts = <String, _ZoneLayout>{
    'M1': _ZoneLayout(10, 10, 38, 1, 'Mộ đơn tiêu chuẩn', 'Ô mộ'),
    'M2': _ZoneLayout(10, 10, 22, 2, 'Mộ đôi trung tâm', 'Lô đôi'),
    'M3': _ZoneLayout(5, 4, 10, 12, 'Mộ gia đình & gia tộc', 'Lô gia tộc',
        prefix: 'GT', wholeUnit: true),
    'M4': _ZoneLayout(5, 10, 36, 1, 'Khu mộ Công Giáo', 'Ô mộ'),
    'M5': _ZoneLayout(5, 10, 12, 2, 'Mộ Vạn Tuế & Vườn Tùng', 'Lô đôi'),
    'M6': _ZoneLayout(5, 10, 56, 1, 'Khu mộ An Lạc', 'Ô mộ'),
    'M7': _ZoneLayout(5, 10, 28, 1, 'Vườn Zen Đồi Vạn Phật', 'Ô mộ'),
    'M8': _ZoneLayout(4, 5, 15, 4, 'Mộ Vĩnh Hằng Thượng Hạng', 'Lô thượng hạng',
        prefix: 'VH', wholeUnit: true),
    'M11': _ZoneLayout(2, 3, 10, 16, 'Mộ Gia Tộc Mở Rộng', 'Đại lô gia tộc',
        prefix: 'GTM', wholeUnit: true),
  };

  @override
  void initState() {
    super.initState();
    if (!_guest) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        ApiService.instance.get('/zones'),
        ApiService.instance.get('/plots/summary?zone=$_selected')
      ]);
      if (!mounted) return;
      setState(() {
        _zones = (r[0]['data'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        _summary = Map<String, dynamic>.from(r[1]['data'] as Map);
      });
    } catch (_) {
      /* Keep map usable with reference labels when offline. */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(String code) {
    setState(() {
      _selected = code;
      if (zones.containsKey(code)) {
        _filter = code;
        _subZone = 'K01';
        _selectedUnit = null;
        _detail = true;
      }
    });
    if (!_guest && zones.containsKey(code)) {
      _loadZoneSummary(code);
    }
  }

  void _showOverview() => setState(() {
        _filter = 'Tất cả 50ha';
        _detail = false;
        _selectedUnit = null;
      });

  void _zoomBy(double delta) =>
      setState(() => _zoom = (_zoom + delta).clamp(.85, 1.45).toDouble());

  Future<void> _loadZoneSummary(String code) async {
    try {
      final r = await ApiService.instance.get('/plots/summary?zone=$code');
      if (mounted && _selected == code) {
        setState(() => _summary = Map<String, dynamic>.from(r['data'] as Map));
      }
    } catch (_) {
      // Keep the last aggregate if the request fails.
    }
  }

  void _doSearch() {
    final q = _search.text.trim().toUpperCase();
    final m = RegExp(r'^M(?:11|[1-8])').firstMatch(q)?.group(0);
    if (m != null) _select(m);
  }

  String _name(String code) =>
      zones[code]?.$1 ?? places[code]?.$1 ?? 'Tiện ích hoa viên';
  String _sub(String code) => zones[code]?.$2 ?? places[code]?.$2 ?? '';
  IconData _icon(String code) =>
      zones[code]?.$3 ?? places[code]?.$3 ?? Icons.place_outlined;
  int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  int? _zoneCount(String code) {
    for (final z in _zones) {
      if (z['zone_code']?.toString() == code) {
        return int.tryParse(z['plot_count']?.toString() ?? '');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        return ColoredBox(
            color: MauSala.nen,
            child: _detail
                ? _detailScreen(c.maxWidth)
                : _overviewScreen(c.maxWidth));
      });

  Widget _overviewScreen(double maxWidth) {
    final wide = maxWidth >= 1120;
    return ListView(
        padding: EdgeInsets.all(maxWidth < 600 ? 12 : 20),
        children: [
          Row(children: [
            const Icon(Icons.home_outlined, size: 15, color: MauSala.vang),
            const SizedBox(width: 5),
            Text(
                _guest
                    ? 'SALA GARDEN'
                    : _relative
                        ? 'THÂN NHÂN'
                        : 'BAN QUẢN LÝ',
                style: const TextStyle(
                    color: MauSala.vang,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6)),
            const Icon(Icons.chevron_right, size: 15, color: MauSala.vien),
            const Expanded(
                child: Text('SƠ ĐỒ TỔNG THỂ QUY HOẠCH 50HA',
                    style: TextStyle(
                        color: MauSala.chuPhu,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5))),
            if (!_guest)
              _badge(_loading ? 'Đang đồng bộ' : 'Dữ liệu hoa viên',
                  Icons.verified_outlined, const Color(0xFFDDF4E8)),
          ]),
          const SizedBox(height: 11),
          _toolbar(maxWidth),
          const SizedBox(height: 13),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: _map()),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: _details())
            ])
          else
            Column(children: [_map(), const SizedBox(height: 12), _details()]),
          const SizedBox(height: 12),
          _metrics(maxWidth),
        ]);
  }

  Widget _detailScreen(double maxWidth) {
    final layout = layouts[_selected]!;
    final wide = maxWidth >= 1020;
    return ListView(
        padding: EdgeInsets.all(maxWidth < 600 ? 12 : 20),
        children: [
          _toolbar(maxWidth),
          const SizedBox(height: 12),
          Row(children: [
            Material(
                color: MauSala.xanhThe,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                    onTap: _showOverview,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.arrow_back, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text('SƠ ĐỒ TỔNG 50HA',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800))
                        ])))),
            const SizedBox(width: 9),
            const Icon(Icons.chevron_right, size: 15, color: MauSala.vien),
            const SizedBox(width: 5),
            Expanded(
                child: Text(
                    'PHÂN KHU $_selected  •  ${layout.name.toUpperCase()}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9,
                        color: MauSala.chuPhu,
                        fontWeight: FontWeight.w700)))
          ]),
          const SizedBox(height: 12),
          _detailHeading(layout),
          const SizedBox(height: 10),
          _subZoneSelector(layout),
          const SizedBox(height: 10),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: _plotGrid(layout)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _selectedUnitCard(layout)),
            ])
          else ...[
            _plotGrid(layout),
            const SizedBox(height: 12),
            _selectedUnitCard(layout),
          ],
        ]);
  }

  Widget _detailHeading(_ZoneLayout layout) => Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _badge('SƠ ĐỒ LƯỚI Ô KIM TĨNH', Icons.grid_view_outlined),
        const SizedBox(height: 7),
        Text('$_selected • ${layout.name}',
            style: GoogleFonts.newsreader(
                fontSize: 23,
                color: MauSala.xanhDam,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            '${layout.subZones} khu con • ${layout.rows} hàng × ${layout.columns} ${layout.unitLabel.toLowerCase()}/khu • ${_fmt(layout.totalSlots)} kim tĩnh',
            style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        const SizedBox(height: 10),
        Wrap(spacing: 11, runSpacing: 5, children: const [
          _Legend(MauSala.xanhThe, 'Còn trống'),
          _Legend(MauSala.vangThe, 'Giữ chỗ / đã cọc'),
          _Legend(Color(0xFFBE1E2D), 'Đã an táng'),
          _Legend(Color(0xFFDCEAF5), 'Ô đang chọn'),
        ]),
        const SizedBox(height: 8),
        Text(
            'Trạng thái lưới sẽ được lấy từ dữ liệu SQL sau khi bổ sung đủ ${_fmt(layout.totalSlots)} kim tĩnh.',
            style: const TextStyle(fontSize: 8, color: MauSala.chuPhu))
      ]));

  Widget _subZoneSelector(_ZoneLayout layout) => Container(
      padding: const EdgeInsets.all(10),
      decoration: _card(),
      child: Wrap(spacing: 5, runSpacing: 5, children: [
        const Padding(
            padding: EdgeInsets.only(top: 8, right: 3),
            child: Text('CHỌN KHU:',
                style: TextStyle(
                    fontSize: 8,
                    color: MauSala.chuPhu,
                    fontWeight: FontWeight.w800))),
        for (var n = 1; n <= layout.subZones; n++)
          _subZoneButton('K${n.toString().padLeft(2, '0')}'),
      ]));

  Widget _subZoneButton(String code) {
    final active = _subZone == code;
    return Material(
        color: active ? MauSala.xanhThe : MauSala.xanhNhat,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
            onTap: () => setState(() {
                  _subZone = code;
                  _selectedUnit = null;
                }),
            borderRadius: BorderRadius.circular(5),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(code,
                    style: TextStyle(
                        fontSize: 8,
                        color: active ? Colors.white : MauSala.chuPhu,
                        fontWeight: FontWeight.w800)))));
  }

  Widget _plotGrid(_ZoneLayout layout) => Container(
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.grid_4x4_outlined, size: 16, color: MauSala.xanhThe),
          const SizedBox(width: 6),
          Expanded(
              child: Text('$_selected • $_subZone — ${layout.unitLabel}',
                  style: GoogleFonts.newsreader(
                      fontSize: 17,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w600))),
          Text('${layout.rows} × ${layout.columns}',
              style: const TextStyle(fontSize: 8, color: MauSala.chuPhu))
        ]),
        const SizedBox(height: 11),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
                width: layout.columns * 63.0 + 29,
                child: Column(children: [
                  Row(children: [
                    const SizedBox(width: 29),
                    for (var c = 1; c <= layout.columns; c++)
                      SizedBox(
                          width: 63,
                          child: Text(c.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 7,
                                  color: MauSala.chuPhu,
                                  fontWeight: FontWeight.w800)))
                  ]),
                  const SizedBox(height: 4),
                  for (var r = 0; r < layout.rows; r++) _gridRow(layout, r),
                ]))),
        const SizedBox(height: 9),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(6)),
            child: const Text(
                'Cuộn ngang để xem các cột còn lại. Chọn một ô/lô để xem hồ sơ và thao tác.',
                style: TextStyle(fontSize: 8, color: MauSala.chuPhu)))
      ]));

  Widget _gridRow(_ZoneLayout layout, int row) {
    final rowLabel = String.fromCharCode(65 + row);
    return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          SizedBox(
              width: 29,
              child: Text(rowLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 9,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w800))),
          for (var col = 1; col <= layout.columns; col++)
            _plotCell(layout, rowLabel, col),
        ]));
  }

  Widget _plotCell(_ZoneLayout layout, String row, int column) {
    final code = _unitCode(layout, row, column);
    final selected = code == _selectedUnit;
    final state = (row.codeUnitAt(0) + column) % 13;
    final color = selected
        ? MauSala.xanhDam
        : state == 0
            ? const Color(0xFFBE1E2D)
            : state == 1 || state == 2
                ? MauSala.vangThe
                : const Color(0xFFEAF5EF);
    final fg = selected || state == 0 ? Colors.white : MauSala.xanhDam;
    return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SizedBox(
            width: 59,
            height: 51,
            child: Material(
                color: color,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                    onTap: () => setState(() => _selectedUnit = code),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_cellLabel(layout, row, column),
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: fg,
                                      fontWeight: FontWeight.w800)),
                              const Spacer(),
                              Text('${layout.capacity} KT',
                                  style: TextStyle(fontSize: 6.5, color: fg))
                            ]))))));
  }

  String _cellLabel(_ZoneLayout layout, String row, int column) {
    if (layout.prefix != null) {
      return '${layout.prefix}${_lotNumber(layout, row, column).toString().padLeft(2, '0')}';
    }
    return '$row${column.toString().padLeft(2, '0')}';
  }

  int _lotNumber(_ZoneLayout layout, String row, int column) =>
      (row.codeUnitAt(0) - 65) * layout.columns + column;

  String _unitCode(_ZoneLayout layout, String row, int column) {
    final stem = _cellLabel(layout, row, column);
    return '$_selected-$_subZone-$stem';
  }

  Widget _selectedUnitCard(_ZoneLayout layout) {
    final code = _selectedUnit;
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        child: code == null
            ? const Column(children: [
                Icon(Icons.ads_click_outlined,
                    size: 30, color: MauSala.xanhThe),
                SizedBox(height: 8),
                Text('Chọn một ô/lô trên sơ đồ',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                    'Thông tin mộ phần, hợp đồng và dịch vụ sẽ hiển thị tại đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8, color: MauSala.chuPhu))
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _badge('LÔ ĐANG CHỌN', Icons.location_on_outlined,
                    MauSala.xanhThe, Colors.white),
                const SizedBox(height: 9),
                Text(code,
                    style: GoogleFonts.newsreader(
                        fontSize: 21,
                        color: MauSala.xanhDam,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('${layout.unitLabel} • ${layout.capacity} kim tĩnh',
                    style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
                if (layout.wholeUnit) ...[
                  const SizedBox(height: 10),
                  Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: MauSala.vangThe.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                          'Quy tắc: ${layout.unitLabel} này chỉ được lập hợp đồng trọn ${layout.capacity} kim tĩnh.',
                          style: const TextStyle(
                              fontSize: 8,
                              color: MauSala.vang,
                              fontWeight: FontWeight.w700)))
                ],
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: _guest ? widget.onLogin : () {},
                        style: FilledButton.styleFrom(
                            backgroundColor: MauSala.xanhDam,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11)),
                        icon: Icon(
                            _guest ? Icons.login : Icons.description_outlined,
                            size: 14),
                        label: Text(
                            _guest
                                ? 'ĐĂNG NHẬP ĐỂ XEM HỒ SƠ'
                                : 'XEM HỒ SƠ MỘ PHẦN',
                            style: const TextStyle(
                                fontSize: 8, fontWeight: FontWeight.w800))))
              ]));
  }

  Widget _toolbar(double width) => Container(
      padding: const EdgeInsets.all(10),
      decoration: _card(),
      child: LayoutBuilder(builder: (context, c) {
        final search = SizedBox(
            width: c.maxWidth < 650 ? c.maxWidth : 245,
            height: 42,
            child: TextField(
                controller: _search,
                onSubmitted: (_) => _doSearch(),
                decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: MauSala.xanhNhat,
                    prefixIcon: const Icon(Icons.search, size: 17),
                    hintText: 'Tìm M1–M8, M11 hoặc mã ô mộ...',
                    hintStyle: const TextStyle(fontSize: 9),
                    suffixIcon: IconButton(
                        onPressed: _doSearch,
                        icon: const Icon(Icons.arrow_forward, size: 15)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none))));
        final filters = Wrap(spacing: 4, runSpacing: 4, children: [
          _filterButton('Tất cả 50ha'),
          for (var i = 1; i <= 8; i++) _filterButton('M$i'),
          _filterButton('M11'),
        ]);
        final modes = Wrap(spacing: 4, children: [
          _mode('Flycam thực địa', Icons.satellite_alt_outlined),
          _mode('2D Vector', Icons.grid_view_outlined),
          _mode('Mô phỏng 3D', Icons.view_in_ar_outlined)
        ]);
        if (c.maxWidth < 900) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 8),
                filters,
                const SizedBox(height: 6),
                modes
              ]);
        }
        return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [search, filters, modes]);
      }));
  Widget _filterButton(String v) {
    final active = _filter == v;
    return Material(
        color: active ? MauSala.xanhThe : MauSala.xanhNhat,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
            onTap: () => v == 'Tất cả 50ha' ? _showOverview() : _select(v),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(v,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : MauSala.chuPhu)))));
  }

  Widget _mode(String v, IconData icon) {
    final active = _view == v;
    return Material(
        color: active ? MauSala.xanhThe : MauSala.xanhNhat,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
            onTap: () => setState(() => _view = v),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon,
                      size: 12, color: active ? Colors.white : MauSala.chuPhu),
                  const SizedBox(width: 4),
                  Text(v,
                      style: TextStyle(
                          fontSize: 8,
                          color: active ? Colors.white : MauSala.chuPhu,
                          fontWeight: FontWeight.w600))
                ]))));
  }

  Widget _map() => Container(
      padding: const EdgeInsets.all(11),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('BẢN ĐỒ TỔNG THỂ SALA GARDEN',
                  style: GoogleFonts.manrope(
                      fontSize: 9,
                      letterSpacing: .6,
                      color: MauSala.vang,
                      fontWeight: FontWeight.w800))),
          _badge('Quy hoạch 50ha', Icons.eco_outlined),
          const SizedBox(width: 5),
          _badge('Ảnh flycam quy hoạch', Icons.satellite_alt_outlined)
        ]),
        const SizedBox(height: 9),
        ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: AspectRatio(
                aspectRatio: 1.47,
                child: LayoutBuilder(
                    builder: (context, c) =>
                        Stack(fit: StackFit.expand, children: [
                          ClipRect(
                              child: Transform.scale(
                            scale: _zoom,
                            child: Stack(fit: StackFit.expand, children: [
                              Image.asset('assets/images/so_do_tong_sala.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                          color: Color(0xFFDCEBE2),
                                          child: Center(
                                              child: Icon(Icons.map_outlined,
                                                  size: 70,
                                                  color: MauSala.xanhThe)))),
                              if (_view == '2D Vector')
                                ColoredBox(
                                    color:
                                        MauSala.xanhThe.withValues(alpha: .12)),
                              if (_view == 'Mô phỏng 3D')
                                const ColoredBox(color: Color(0x11003629)),
                              Positioned.fill(
                                  child: CustomPaint(
                                      painter: _RoutePainter(
                                          showRoutes: _view == '2D Vector',
                                          dim: false))),
                              for (final m in _markers(c.maxWidth, c.maxHeight))
                                Positioned(
                                    left: m.x, top: m.y, child: _marker(m)),
                            ]),
                          )),
                          Positioned(
                              right: 8,
                              top: 8,
                              child: Column(children: [
                                _mapTool(Icons.add, () => _zoomBy(.1)),
                                const SizedBox(height: 4),
                                _mapTool(Icons.remove, () => _zoomBy(-.1)),
                                const SizedBox(height: 4),
                                InkWell(
                                    onTap: () {
                                      setState(() => _zoom = 1);
                                      _select('CONG_CHINH');
                                    },
                                    child: _tool(Icons.my_location)),
                              ])),
                          Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .94),
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Wrap(
                                    spacing: 9,
                                    runSpacing: 3,
                                    children: [
                                      _Legend(Color(0xFFCCE1F1), 'Đất trống'),
                                      _Legend(MauSala.vangThe, 'Đã giữ chỗ'),
                                      _Legend(MauSala.xanhThe, 'Đã an táng'),
                                      _Legend(MauSala.vang, 'Công trình'),
                                    ]),
                              )),
                        ])))),
        const SizedBox(height: 7),
        Row(children: [
          const Icon(Icons.touch_app_outlined,
              size: 13, color: MauSala.xanhThe),
          const SizedBox(width: 4),
          Expanded(
              child: Text(
                  _guest
                      ? 'Chọn phân khu để xem quy hoạch và trạng thái công khai.'
                      : 'Chọn phân khu để xem quy hoạch phù hợp với tài khoản.',
                  style: const TextStyle(fontSize: 9, color: MauSala.chuPhu))),
          Text(_view.toUpperCase(),
              style: const TextStyle(fontSize: 7, color: MauSala.chuPhu))
        ]),
      ]));

  List<_Marker> _markers(double w, double h) {
    final all = <_Marker>[
      _Marker('M1', 'M1', .255, .48, false, Icons.park_outlined, 44),
      _Marker('M2', 'M2', .59, .61, false, Icons.park_outlined, 44),
      _Marker('M3', 'M3', .735, .43, false, Icons.park_outlined, 44),
      _Marker('M4', 'M4', .865, .33, false, Icons.park_outlined, 44),
      _Marker('M5', 'M5', .785, .28, false, Icons.park_outlined, 44),
      _Marker('M6', 'M6', .65, .28, false, Icons.park_outlined, 44),
      _Marker('M7', 'M7', .535, .45, false, Icons.park_outlined, 44),
      _Marker('M8', 'M8', .69, .35, false, Icons.park_outlined, 44),
      _Marker('M11', 'M11', .90, .19, false, Icons.account_tree_outlined, 48),
      _Marker('HO_TINH_TAM', 'Hồ Tịnh Tâm', .055, .4, true,
          Icons.water_outlined, 80),
      _Marker('SUOI_TAM_LINH', 'Suối Tâm Linh', .16, .34, true,
          Icons.waves_outlined, 86),
      _Marker('TINH_XA', 'Tịnh Xá Sala', .285, .68, true,
          Icons.temple_buddhist_outlined, 77),
      _Marker('NHA_TANG_LE', 'Nhà Tang Lễ', .435, .23, true,
          Icons.account_balance_outlined, 79),
      _Marker('NHA_HOA_TANG', 'Nhà Hỏa Táng', .61, .15, true,
          Icons.local_fire_department_outlined, 86),
      _Marker('NHA_HANG', 'Nhà Hàng Zen', .30, .31, true,
          Icons.restaurant_outlined, 77),
      _Marker('NHA_DIEU_HANH', 'Nhà Điều Hành', .485, .87, true,
          Icons.apartment_outlined, 91),
      _Marker('CONG_CHINH', 'Cổng Chính', .35, .79, true,
          Icons.meeting_room_outlined, 77),
    ];
    Iterable<_Marker> selected = all;
    if (zones.containsKey(_filter)) {
      selected = all.where((m) => m.code == _filter);
    }
    return selected.map((m) => m.at(w, h)).toList();
  }

  Widget _marker(_Marker m) {
    final active = _selected == m.code;
    return Tooltip(
        message: m.label,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () => _select(m.code),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    constraints: BoxConstraints(maxWidth: m.width),
                    padding: EdgeInsets.symmetric(
                        horizontal: m.amenity ? 4 : 6,
                        vertical: m.amenity ? 3 : 4),
                    decoration: BoxDecoration(
                        color: active
                            ? MauSala.xanhDam
                            : Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(m.amenity ? 4 : 7),
                        border: Border.all(
                            color: active ? MauSala.vangThe : Colors.white,
                            width: active ? 2 : 1),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x25000000),
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(m.icon,
                          size: m.amenity ? 9 : 11,
                          color: active
                              ? MauSala.vangThe
                              : m.amenity
                                  ? MauSala.vang
                                  : MauSala.xanhThe),
                      const SizedBox(width: 3),
                      Flexible(
                          child: Text(m.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: m.amenity ? 6.5 : 9,
                                  color:
                                      active ? Colors.white : MauSala.xanhDam,
                                  fontWeight: FontWeight.w800)))
                    ])))));
  }

  Widget _mapTool(IconData icon, VoidCallback onTap) => Material(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: _tool(icon)));
  Widget _tool(IconData icon) => Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(5)),
      child: Icon(icon, size: 15, color: MauSala.xanhDam));

  Widget _details() {
    final zone = zones.containsKey(_selected);
    final linked = widget.linkedPlots
        .where((p) =>
            p['zone_code']?.toString() == _selected ||
            (p['plot_code']?.toString().startsWith('$_selected-') ?? false))
        .toList();
    final count = _zoneCount(_selected);
    return Column(children: [
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: _card(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _badge(zone ? 'PHÂN KHU ĐANG CHỌN' : 'TIỆN ÍCH HOA VIÊN',
                  _icon(_selected), MauSala.xanhThe, Colors.white),
              const Spacer(),
              if (count != null)
                _badge('${_fmt(count)} ô mộ', Icons.grid_view_outlined)
            ]),
            const SizedBox(height: 9),
            Text(zone ? '$_selected • ${_name(_selected)}' : _name(_selected),
                style: GoogleFonts.newsreader(
                    fontSize: 23,
                    height: 1.1,
                    color: MauSala.xanhDam,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_sub(_selected),
                style: const TextStyle(fontSize: 10, color: MauSala.chuPhu)),
            if (zone) ...[
              const SizedBox(height: 12),
              _occupancy(),
              const SizedBox(height: 8),
              Row(children: [
                _count('Còn trống', _summary['available'], MauSala.xanhThe),
                _count('Đã giữ chỗ', _summary['reserved'], MauSala.vang),
                _count(
                    'Đã an táng', _summary['occupied'], const Color(0xFFBE1E2D))
              ])
            ] else ...[
              const SizedBox(height: 10),
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: MauSala.xanhNhat,
                      borderRadius: BorderRadius.circular(7)),
                  child: Row(children: [
                    Icon(_icon(_selected), size: 17, color: MauSala.vang),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(
                            'Tiện ích trong khuôn viên Sala Garden. Chọn phân khu để xem quy hoạch.',
                            style: const TextStyle(
                                fontSize: 9,
                                height: 1.4,
                                color: MauSala.chuPhu)))
                  ]))
            ],
            if (_relative && zone) ...[
              const SizedBox(height: 10),
              if (linked.isEmpty)
                const Text('Tài khoản chưa có mộ liên kết trong phân khu này.',
                    style: TextStyle(fontSize: 9, color: MauSala.chuPhu))
              else ...[
                const Text('MỘ ĐÃ LIÊN KẾT VỚI TÀI KHOẢN',
                    style: TextStyle(
                        fontSize: 8,
                        color: MauSala.vang,
                        fontWeight: FontWeight.w700)),
                for (final p in linked.take(4))
                  ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined,
                          color: MauSala.xanhThe, size: 17),
                      title: Text(p['plot_code']?.toString() ?? 'Mộ gia đình',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          p['beneficiary_display_name']?.toString() ??
                              p['beneficiary_name']?.toString() ??
                              'Hồ sơ thân nhân',
                          style: const TextStyle(fontSize: 8)))
              ]
            ],
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed:
                        _guest ? widget.onLogin : () => _select(_selected),
                    style: FilledButton.styleFrom(
                        backgroundColor: MauSala.xanhDam,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: Icon(_guest ? Icons.login : Icons.arrow_forward,
                        size: 14),
                    label: Text(
                        _guest
                            ? 'Đăng nhập để xem sơ đồ chi tiết'
                            : 'Mở sơ đồ lưới kim tĩnh',
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700))))
          ])),
      const SizedBox(height: 11),
      _zoneList(),
      if (!_guest) ...[
        const SizedBox(height: 11),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: MauSala.xanhDam, borderRadius: BorderRadius.circular(9)),
            child: Row(children: [
              const Icon(Icons.sensors_outlined, color: MauSala.vangThe),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      _relative
                          ? 'Hồ sơ riêng chỉ hiện với mộ đã liên kết tài khoản.'
                          : 'Số liệu trạng thái lấy từ dữ liệu ô mộ hệ thống.',
                      style: const TextStyle(color: Colors.white, fontSize: 9)))
            ]))
      ]
    ]);
  }

  Widget _occupancy() {
    final total = _int(_summary['total']);
    if (total == 0) {
      return Container(
          height: 8,
          decoration: BoxDecoration(
              color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(5)));
    }
    final a = _int(_summary['occupied']),
        b = _int(_summary['reserved']),
        c = _int(_summary['available']);
    return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
            height: 8,
            child: Row(children: [
              if (a > 0)
                Expanded(
                    flex: a, child: const ColoredBox(color: MauSala.xanhThe)),
              if (b > 0)
                Expanded(
                    flex: b, child: const ColoredBox(color: MauSala.vangThe)),
              if (c > 0)
                Expanded(
                    flex: c, child: const ColoredBox(color: Color(0xFFDCEAF5))),
              if (a + b + c == 0)
                const Expanded(child: ColoredBox(color: MauSala.xanhNhat))
            ])));
  }

  Widget _count(String label, dynamic value, Color color) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 7, color: MauSala.chuPhu)),
        Text(_fmt(_int(value)),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color))
      ]));
  Widget _zoneList() => Container(
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('DANH MỤC PHÂN KHU M1–M8, M11',
                  style: GoogleFonts.manrope(
                      fontSize: 9,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w800))),
          if (_loading)
            const SizedBox.square(
                dimension: 12, child: CircularProgressIndicator(strokeWidth: 2))
        ]),
        const SizedBox(height: 7),
        for (var i = 1; i <= 8; i++) _zoneItem('M$i'),
        _zoneItem('M11'),
      ]));
  Widget _zoneItem(String code) {
    final active = _selected == code;
    final count = _zoneCount(code);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? MauSala.xanhThe : MauSala.xanhNhat,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _select(code),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(children: [
              Container(
                width: 27,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(code,
                    style: const TextStyle(
                        fontSize: 9,
                        color: MauSala.xanhDam,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name(code),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : MauSala.chu)),
                      Text(_sub(code),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 7,
                              color: active ? Colors.white70 : MauSala.chuPhu)),
                    ]),
              ),
              if (count != null)
                Text(_fmt(count),
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: active ? MauSala.vangThe : MauSala.xanhThe)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _metrics(double maxWidth) {
    final n = maxWidth > 1000
        ? 4
        : maxWidth > 560
            ? 2
            : 1;
    final width = (maxWidth - (n - 1) * 8) / n;
    final total = _int(_summary['total']);
    final items = [
      (
        Icons.square_foot_outlined,
        'Tổng diện tích',
        '500.000 m²',
        'Quy hoạch 50ha'
      ),
      (
        Icons.forest_outlined,
        'Mật độ cây xanh',
        '55%*',
        'Chỉ số quy hoạch tham khảo'
      ),
      (
        Icons.grid_view_outlined,
        'Tổng số kim tĩnh',
        total == 0 ? '19.960*' : _fmt(total),
        total == 0
            ? '*Theo quy hoạch M1–M8, M11 đã chốt'
            : 'Theo dữ liệu hệ thống'
      ),
      (
        Icons.directions_bus_filled_outlined,
        'Xe điện nội khu',
        '12 xe',
        'Liên hệ quầy hỗ trợ'
      )
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final i in items)
        SizedBox(
            width: width,
            child: Container(
                padding: const EdgeInsets.all(11),
                decoration: _card(),
                child: Row(children: [
                  Icon(i.$1, color: MauSala.xanhThe, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(i.$2,
                            style: const TextStyle(
                                fontSize: 8, color: MauSala.chuPhu)),
                        Text(i.$3,
                            style: GoogleFonts.newsreader(
                                fontSize: 17,
                                color: MauSala.xanhDam,
                                fontWeight: FontWeight.w700)),
                        Text(i.$4,
                            style: const TextStyle(
                                fontSize: 7, color: MauSala.chuPhu))
                      ]))
                ])))
    ]);
  }

  Widget _badge(String text, IconData icon,
          [Color bg = MauSala.xanhNhat, Color fg = MauSala.xanhDam]) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontSize: 7, color: fg, fontWeight: FontWeight.w700))
          ]));
  BoxDecoration _card() => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: MauSala.vien.withValues(alpha: .35)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A003629), blurRadius: 8, offset: Offset(0, 3))
          ]);
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 6.5,
                color: MauSala.chuPhu,
                fontWeight: FontWeight.w600))
      ]);
}

class _ZoneLayout {
  const _ZoneLayout(this.subZones, this.rows, this.columns, this.capacity,
      this.name, this.unitLabel,
      {this.prefix, this.wholeUnit = false});
  final int subZones, rows, columns, capacity;
  final String name, unitLabel;
  final String? prefix;
  final bool wholeUnit;
  int get totalSlots => subZones * rows * columns * capacity;
}

class _Marker {
  const _Marker(this.code, this.label, this.px, this.py, this.amenity,
      this.icon, this.width,
      {this.x = 0, this.y = 0});
  final String code, label;
  final double px, py, width, x, y;
  final bool amenity;
  final IconData icon;
  _Marker at(double w, double h) =>
      _Marker(code, label, px, py, amenity, icon, width,
          x: w * px - width / 2, y: h * py);
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.showRoutes, required this.dim});
  final bool showRoutes, dim;
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(s.width * .34, s.height * .78)
      ..lineTo(s.width * .40, s.height * .70)
      ..lineTo(s.width * .40, s.height * .52)
      ..lineTo(s.width * .52, s.height * .45)
      ..lineTo(s.width * .55, s.height * .36)
      ..lineTo(s.width * .73, s.height * .34)
      ..lineTo(s.width * .83, s.height * .29);
    c.drawPath(
        p,
        Paint()
          ..color = Colors.white.withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (showRoutes ? 5 : 2)
          ..strokeCap = StrokeCap.round);
    c.drawPath(
        p,
        Paint()
          ..color = (showRoutes ? MauSala.xanhThe : MauSala.vangThe)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (showRoutes ? 2.3 : 1.2)
          ..strokeCap = StrokeCap.round);
    if (dim) {
      c.drawRect(
          Offset.zero & s, Paint()..color = Colors.white.withValues(alpha: .4));
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      showRoutes != old.showRoutes || dim != old.dim;
}

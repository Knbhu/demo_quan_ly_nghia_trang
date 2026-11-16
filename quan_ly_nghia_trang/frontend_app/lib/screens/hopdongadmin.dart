import 'package:flutter/material.dart';

import '../core/api_service.dart';
import '../core/app_colors.dart';

enum HopDongTab { tatCa, duyet, traGop, quaHan, hoanTat }

class _HopDongItem {
  final int id;
  final String code, name, plot, kind, status, date, phone;
  final int total, paid, installment;
  const _HopDongItem(this.id, this.code, this.name, this.plot, this.kind,
      this.status, this.date, this.phone, this.total, this.paid, this.installment);

  factory _HopDongItem.fromJson(Map<String, dynamic> json) {
    final total = _number(json['total_amount']);
    final paid = _number(json['amount_paid']);
    final adminStatus = '${json['admin_status'] ?? ''}'.toUpperCase();
    final rawStatus = '${json['status'] ?? ''}'.toUpperCase();
    final installment = _number(json['installment_months']);
    final status = switch (adminStatus) {
      'PENDING' => 'Chờ duyệt',
      'CHANGE_REQUESTED' => 'Yêu cầu bổ sung',
      'REJECTED' => 'Đã từ chối',
      _ when total > 0 && paid >= total => 'Đã hoàn tất',
      _ when installment > 0 && rawStatus == 'ACTIVE' => 'Trả góp đúng hạn',
      _ => 'Đã duyệt',
    };
    return _HopDongItem(
      _number(json['id']), '${json['contract_code'] ?? ''}',
      '${json['customer_name'] ?? ''}', '${json['plot_code'] ?? ''}',
      '${json['plot_type'] ?? ''}', status,
      '${json['created_at'] ?? ''}'.split('T').first,
      '${json['customer_phone'] ?? ''}', total, paid, installment,
    );
  }

  static int _number(dynamic value) => value is num ? value.round() : num.tryParse('$value')?.round() ?? 0;
  int get remaining => total - paid;
}

class HopDongAdminScreen extends StatefulWidget {
  const HopDongAdminScreen({super.key});

  @override
  State<HopDongAdminScreen> createState() => _HopDongAdminScreenState();
}

class _HopDongAdminScreenState extends State<HopDongAdminScreen> {
  HopDongTab _tab = HopDongTab.tatCa;
  final _search = TextEditingController();
  int _selected = 0;
  List<_HopDongItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.instance.get('/admin/contracts');
      final raw = response['data'] as List? ?? const [];
      if (!mounted) return;
      setState(() { _items = raw.map((item) => _HopDongItem.fromJson(Map<String, dynamic>.from(item as Map))).toList(); _loading = false; _selected = 0; });
    } catch (error) { if (mounted) setState(() { _error = error.toString().replaceFirst('Exception: ', ''); _loading = false; }); }
  }

  Future<void> _contractAction(_HopDongItem item, String action) async {
    try {
      await ApiService.instance.post('/admin/contracts/${item.id}/action', {'action': action});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật hợp đồng ${item.code}.')));
      await _load();
    } catch (error) { if (mounted) _message(error.toString().replaceFirst('Exception: ', '')); }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_HopDongItem> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _items.where((item) {
      final tabMatch = switch (_tab) {
        HopDongTab.tatCa => true,
        HopDongTab.duyet => item.status.contains('duyệt'),
        HopDongTab.traGop => item.status == 'Trả góp đúng hạn',
        HopDongTab.quaHan => item.status == 'Quá hạn',
        HopDongTab.hoanTat => item.status == 'Đã hoàn tất',
      };
      final textMatch = query.isEmpty ||
          '${item.code} ${item.name} ${item.plot} ${item.kind}'
              .toLowerCase()
              .contains(query);
      return tabMatch && textMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final selected = rows.isEmpty
        ? null
        : rows[_selected.clamp(0, rows.length - 1).toInt()];
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _heading(),
          const SizedBox(height: 16),
          if (_loading) const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) _errorPanel()
          else ...[
          _summaryCards(),
          const SizedBox(height: 16),
          _tabBar(),
          const SizedBox(height: 12),
          _filters(),
          const SizedBox(height: 12),
          if (_tab == HopDongTab.duyet)
            _reviewLayout(rows, selected)
          else
            _tableLayout(rows, selected),
          const SizedBox(height: 12),
          _notice(),
          ],
        ],
      ),
    );
  }

  Widget _heading() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 560,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('KINH DOANH & KHÁCH HÀNG  /  QUẢN LÝ HỢP ĐỒNG',
                      style: TextStyle(color: AppColors.gold, fontSize: 10, letterSpacing: .7, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  const Text('Quản Lý Hợp Đồng & Kế Hoạch Trả Góp',
                      style: TextStyle(color: AppColors.forestDeep, fontSize: 26, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  const Text('Theo dõi hồ sơ duyệt, công nợ, lịch trả góp và hợp đồng đã hoàn tất.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(onPressed: () => _message('Báo cáo hợp đồng sẽ được xuất khi kết nối dữ liệu.'), icon: const Icon(Icons.download_outlined), label: const Text('Xuất báo cáo')),
                FilledButton.icon(onPressed: () => _message('Tạo hợp đồng mới từ mục sơ đồ mặt bằng.'), icon: const Icon(Icons.add), label: const Text('Lập hợp đồng mới')),
              ]),
            ],
          ),
        ),
      );

  Widget _summaryCards() {
    final total = _items.fold(0, (sum, item) => sum + item.total);
    final paid = _items.fold(0, (sum, item) => sum + item.paid);
    final pending = _items.where((item) => item.status == 'Chờ duyệt').length;
    final overdue = _items.where((item) => item.status == 'Quá hạn').length;
    final cards = <(String, String, String, IconData, Color)>[
      ('TỔNG GIÁ TRỊ KÝ KẾT', _money(total), '${_items.length} hợp đồng', Icons.account_balance_outlined, AppColors.forest),
      ('TIỀN ĐÃ THU THỰC', _money(paid), 'Dữ liệu thanh toán đã ghi nhận', Icons.payments_outlined, const Color(0xFF25836B)),
      ('CHỜ DUYỆT', '$pending', 'Hồ sơ cần thẩm định', Icons.event_available_outlined, AppColors.gold),
      ('HỢP ĐỒNG QUÁ HẠN', '$overdue', 'Hồ sơ • Cần xử lý', Icons.notifications_active_outlined, const Color(0xFFC62828)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 1120 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final card in cards)
          SizedBox(width: width, child: Card(color: Colors.white, child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card.$1, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .5)),
                const SizedBox(height: 7),
                Text(card.$2, style: TextStyle(color: card.$5, fontSize: 28, fontWeight: FontWeight.w700)),
                Text(card.$3, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ])),
              Container(width: 42, height: 42, decoration: BoxDecoration(color: card.$5.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)), child: Icon(card.$4, color: card.$5)),
            ]),
          ))),
      ]);
    });
  }

  Widget _tabBar() {
    final tabs = <(HopDongTab, String, String)>[
      (HopDongTab.tatCa, 'Tất cả', '${_items.length}'),
      (HopDongTab.duyet, 'Duyệt hợp đồng', '${_items.where((item) => item.status == 'Chờ duyệt').length}'),
      (HopDongTab.hoanTat, 'Đã hoàn tất', '${_items.where((item) => item.status == 'Đã hoàn tất').length}'),
      (HopDongTab.traGop, 'Trả góp đúng hạn', '${_items.where((item) => item.status == 'Trả góp đúng hạn').length}'),
      (HopDongTab.quaHan, 'Quá hạn nợ', '${_items.where((item) => item.status == 'Quá hạn').length}'),
    ];
    return Card(color: Colors.white, child: Padding(
      padding: const EdgeInsets.all(7),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final tab in tabs)
          Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
            selected: _tab == tab.$1,
            label: Row(mainAxisSize: MainAxisSize.min, children: [Text(tab.$2), const SizedBox(width: 7), _count(tab.$3, _tab == tab.$1)]),
            onSelected: (_) => setState(() { _tab = tab.$1; _selected = 0; }),
          )),
      ])),
    ));
  }

  Widget _filters() => Card(color: Colors.white, child: Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SizedBox(width: 340, child: TextField(
        controller: _search,
        onChanged: (_) => setState(() => _selected = 0),
        decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search), hintText: 'Tìm mã hợp đồng, thân nhân, CCCD, mã ô mộ...', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
      )),
      _filterTag('Thời gian: Tháng này'),
      _filterTag('Phân khu: Tất cả'),
      _filterTag('Loại mộ: Tất cả'),
      OutlinedButton.icon(onPressed: () { _search.clear(); setState(() => _tab = HopDongTab.tatCa); }, icon: const Icon(Icons.filter_alt_outlined), label: const Text('Xóa lọc')),
    ]),
  ));

  Widget _reviewLayout(List<_HopDongItem> rows, _HopDongItem? selected) => LayoutBuilder(builder: (context, constraints) {
    if (constraints.maxWidth < 850) return Column(children: [_reviewList(rows), if (selected != null) ...[const SizedBox(height: 10), _detail(selected)]]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 300, child: _reviewList(rows)),
      const SizedBox(width: 12),
      Expanded(child: selected == null ? _empty() : _detail(selected)),
    ]);
  });

  Widget _reviewList(List<_HopDongItem> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 8), child: Text('Danh Sách Chờ Thẩm Định  •  ${rows.length} hồ sơ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestDeep))),
    if (rows.isEmpty) _empty(),
    for (var i = 0; i < rows.length; i++)
      Card(color: Colors.white, child: InkWell(
        onTap: () => setState(() => _selected = i),
        borderRadius: BorderRadius.circular(10),
        child: Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: _selected == i ? AppColors.forest : Colors.transparent, width: 4))), padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('#${rows[i].code}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))), _status(rows[i].status)]),
          const SizedBox(height: 8),
          Text(rows[i].name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('${rows[i].kind} • ${rows[i].plot}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const Divider(height: 17),
          Row(children: [const Icon(Icons.verified_outlined, size: 15, color: AppColors.forest), const SizedBox(width: 5), Expanded(child: Text('Đã cọc ${_money(rows[i].paid)}', style: const TextStyle(fontSize: 11))), Text(_money(rows[i].total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold))]),
        ])),
      )),
  ]);

  Widget _detail(_HopDongItem item) => Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hồ Sơ Hợp Đồng #${item.code}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.forestDeep)), const SizedBox(height: 4), Text('Ngày lập: ${item.date}  •  Mã ô mộ: ${item.plot}', style: const TextStyle(color: AppColors.muted, fontSize: 12))])), _status(item.status)],),
    const SizedBox(height: 15),
    LayoutBuilder(builder: (context, c) { final wide = c.maxWidth > 700; final w = wide ? (c.maxWidth - 10) / 2 : c.maxWidth; return Wrap(spacing: 10, runSpacing: 10, children: [SizedBox(width: w, child: _infoBox('THÔNG TIN CHỦ HỢP ĐỒNG', [item.name, 'Số điện thoại: 09•• ••• •••', 'Ngày lập hồ sơ: ${item.date}', 'Trạng thái xác minh: Đã đối soát'])), SizedBox(width: w, child: _infoBox('MỤC ĐÍCH SỬ DỤNG & QUY HOẠCH', [item.kind, 'Vị trí: ${item.plot}', 'Diện tích theo hồ sơ quy hoạch', 'Hướng phong thủy: Đông Nam']))]); }),
    const SizedBox(height: 14),
    _infoBox('TÓM TẮT THANH TOÁN', ['Tổng giá trị: ${_money(item.total)}', 'Đã thanh toán: ${_money(item.paid)}', 'Còn lại: ${_money(item.remaining)}', item.installment > 0 ? 'Kỳ trả góp: ${item.installment} tháng' : 'Phương thức: Thanh toán theo hợp đồng']),
    const SizedBox(height: 14),
    const Text('ĐỐI CHIẾU PHÁP LÝ & CHỨNG TỪ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.forest)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: [for (final text in ['CCCD đã đối soát', 'Vị trí mộ đã xác nhận', 'Chứng từ thanh toán', 'Lịch trả góp']) Chip(avatar: const Icon(Icons.check_circle, color: Color(0xFF25836B), size: 17), label: Text(text))]),
    const SizedBox(height: 14),
    Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.paleBlue)), child: const Column(children: [Icon(Icons.description_outlined, color: AppColors.forest, size: 32), SizedBox(height: 6), Text('HỒ SƠ HỢP ĐỒNG', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)), Text('Trạng thái hồ sơ và thanh toán đang lấy từ cơ sở dữ liệu.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.muted))])),
    const SizedBox(height: 14),
    Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
      OutlinedButton.icon(onPressed: item.status == 'Chờ duyệt' ? () => _contractAction(item, 'REQUEST_CHANGES') : null, icon: const Icon(Icons.edit_note), label: const Text('Yêu cầu bổ sung')),
      OutlinedButton.icon(onPressed: item.status == 'Chờ duyệt' ? () => _contractAction(item, 'REJECT') : null, icon: const Icon(Icons.cancel_outlined), label: const Text('Từ chối hồ sơ')),
      FilledButton.icon(onPressed: item.status == 'Chờ duyệt' ? () => _contractAction(item, 'APPROVE') : null, icon: const Icon(Icons.draw_outlined), label: const Text('Phê duyệt')),
    ]),
  ])));

  Widget _tableLayout(List<_HopDongItem> rows, _HopDongItem? selected) => LayoutBuilder(builder: (context, constraints) {
    final showDetail = constraints.maxWidth > 1100;
    return Column(children: [
      Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Danh sách hợp đồng • ${rows.length} hồ sơ đang hiển thị', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
        const SizedBox(height: 8),
        if (rows.isEmpty) _empty() else SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          columns: const [DataColumn(label: Text('MÃ HỢP ĐỒNG')), DataColumn(label: Text('THÂN NHÂN')), DataColumn(label: Text('VỊ TRÍ MỘ')), DataColumn(label: Text('TỔNG GIÁ TRỊ')), DataColumn(label: Text('ĐÃ THU')), DataColumn(label: Text('CÒN LẠI')), DataColumn(label: Text('TRẠNG THÁI')), DataColumn(label: Text('CHI TIẾT'))],
          rows: [for (final item in rows) DataRow(selected: selected?.code == item.code, onSelectChanged: (_) => setState(() => _selected = rows.indexOf(item)), cells: [DataCell(Text(item.code)), DataCell(Text(item.name)), DataCell(Text(item.plot)), DataCell(Text(_money(item.total))), DataCell(Text(_money(item.paid))), DataCell(Text(_money(item.remaining))), DataCell(_status(item.status)), DataCell(IconButton(tooltip: 'Xem chi tiết', onPressed: () => setState(() => _selected = rows.indexOf(item)), icon: const Icon(Icons.visibility_outlined)))])],
        )),
      ]))),
      if (!showDetail && selected != null) ...[const SizedBox(height: 10), _detail(selected)],
      if (rows.isEmpty) const SizedBox.shrink(),
      if (showDetail && selected != null) ...[const SizedBox(height: 10), _detail(selected)],
    ]);
  });

  Widget _infoBox(String title, List<String> lines) => Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 7), for (final line in lines) Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(line, style: const TextStyle(fontSize: 12, color: AppColors.text)))]));

  Widget _status(String value) {
    final color = value == 'Quá hạn' ? const Color(0xFFC62828) : value == 'Đã hoàn tất' ? const Color(0xFF25836B) : value.contains('duyệt') ? AppColors.gold : AppColors.forest;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }

  Widget _count(String text, bool selected) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: .2) : AppColors.paleBlue, borderRadius: BorderRadius.circular(10)), child: Text(text, style: TextStyle(fontSize: 9, color: selected ? Colors.white : AppColors.muted)));
  Widget _filterTag(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)), child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.text)));
  Widget _empty() => Card(color: Colors.white, child: const Padding(padding: EdgeInsets.all(26), child: Center(child: Text('Không có hợp đồng phù hợp với bộ lọc.', style: TextStyle(color: AppColors.muted)))));
  Widget _notice() => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.paleBlue, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.info_outline, color: AppColors.forest), SizedBox(width: 8), Expanded(child: Text('Danh sách và trạng thái duyệt được đồng bộ từ cơ sở dữ liệu. Chức năng ký số và xuất tệp sẽ được tích hợp sau.', style: TextStyle(fontSize: 11, color: AppColors.text)))]));
  Widget _errorPanel() => Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 10), OutlinedButton(onPressed: _load, child: const Text('Thử lại'))])));
  String _money(int amount) => '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)} triệu ₫';
  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

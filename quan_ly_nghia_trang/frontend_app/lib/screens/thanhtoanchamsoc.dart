import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/gia_tham_khao.dart';
import '../core/mausala.dart';

class ThanhToanChamSoc extends StatefulWidget {
  const ThanhToanChamSoc({
    super.key,
    required this.plot,
    required this.services,
    required this.initialService,
    required this.onBack,
    required this.onCompleted,
  });

  final Map<String, dynamic> plot;
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic> initialService;
  final VoidCallback onBack;
  final Future<void> Function() onCompleted;

  @override
  State<ThanhToanChamSoc> createState() => _ThanhToanChamSocState();
}

class _ThanhToanChamSocState extends State<ThanhToanChamSoc> {
  final _prayer = TextEditingController();
  final _selected = <int>{};
  final _channels = <String, bool>{'Zalo': true, 'Email': true, 'SMS': true};
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _calendar = 'SOLAR';
  String _frequency = 'ONCE';
  String _time = '08:30 – 10:00';
  String _payment = 'VIETQR';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = _id(widget.initialService['id']);
    if (id > 0) _selected.add(id);
  }

  @override
  void dispose() {
    _prayer.dispose();
    super.dispose();
  }

  int get _subtotal => widget.services
      .where((service) => _selected.contains(_id(service['id'])))
      .fold(0, (sum, service) => sum + _price(service['price']));

  int get _discount => _frequency == 'ANNUAL' ? (_subtotal * .1).round() : 0;
  int get _total => _subtotal - _discount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 1000;
          final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _servicePanel(),
            const SizedBox(height: 14),
            _schedulePanel(),
            const SizedBox(height: 14),
            _prayerPanel(),
            const SizedBox(height: 14),
            _reportChannels(),
          ]);
          final right = Column(children: [
            _summaryPanel(),
            const SizedBox(height: 12),
            _notePanel(),
          ]);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back), label: const Text('Quay lại dịch vụ')),
                      const Spacer(),
                      const _Tag('ĐĂNG KÝ DỊCH VỤ & THANH TOÁN'),
                    ]),
                    const SizedBox(height: 8),
                    _hero(),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 7, child: left),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: right),
                      ])
                    else
                      Column(children: [left, const SizedBox(height: 14), right]),
                  ]),
                ),
              ),
            ],
          );
        },
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [MauSala.xanhDam, MauSala.xanhThe]),
        ),
        child: LayoutBuilder(builder: (context, box) {
          final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Tag('CHUẨN MỰC PHỤNG DƯỠNG TÂM LINH'),
            const SizedBox(height: 8),
            Text('Đăng Ký Dịch Vụ Chăm Sóc Mộ Phần & Lễ Vật Tâm Linh',
                style: GoogleFonts.newsreader(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            const Text('Chọn lễ vật, lịch thực hiện và kênh nhận báo cáo nghiệm thu từ xa.', style: TextStyle(color: Color(0xFFBAEED9), fontSize: 12, height: 1.5)),
          ]);
          final plot = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.yard_outlined, color: MauSala.vangThe, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('MỘ PHẦN ĐANG CHỌN', style: TextStyle(color: MauSala.vangThe, fontSize: 9, fontWeight: FontWeight.bold)),
                Text('${widget.plot['plot_code'] ?? 'Chưa rõ mã mộ'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${widget.plot['beneficiary_display_name'] ?? widget.plot['beneficiary_name'] ?? 'Mộ phần gia đình'} • ${widget.plot['zone_name'] ?? ''}', style: const TextStyle(color: Color(0xFFBAEED9), fontSize: 10)),
              ])),
            ]),
          );
          return box.maxWidth < 720 ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [details, const SizedBox(height: 16), plot]) : Row(children: [Expanded(child: details), const SizedBox(width: 20), SizedBox(width: 310, child: plot)]);
        }),
      );

  Widget _servicePanel() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(Icons.inventory_2_outlined, 'Danh Mục Lễ Vật & Dịch Vụ Phụng Dưỡng', 'Chọn một hoặc nhiều dịch vụ cho mộ phần này.'),
        const SizedBox(height: 12),
        ...widget.services.map((service) {
          final id = _id(service['id']);
          final checked = _selected.contains(id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: checked ? MauSala.xanhNhat : Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: checked ? MauSala.xanhThe : const Color(0xFFE8EDF2))),
            child: CheckboxListTile(
              value: checked,
              activeColor: MauSala.xanhThe,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: _saving ? null : (value) => setState(() => value == true ? _selected.add(id) : _selected.remove(id)),
              title: Text('${service['service_name'] ?? 'Dịch vụ chăm sóc'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MauSala.chu)),
              subtitle: Text('${service['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: MauSala.chuPhu)),
              secondary: Text(GiaThamKhao.dinhDang(_price(service['price'])), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MauSala.xanhDam)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        }),
      ]));

  Widget _schedulePanel() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(Icons.event_note_outlined, 'Lịch Trình Thực Hiện Nghi Lễ', 'Chọn ngày và khung giờ mong muốn.'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Một lần dịp này'), selected: _frequency == 'ONCE', onSelected: (_) => setState(() => _frequency = 'ONCE')),
          ChoiceChip(label: const Text('Định kỳ cả năm • giảm 10%'), selected: _frequency == 'ANNUAL', onSelected: (_) => setState(() => _frequency = 'ANNUAL')),
        ]),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Ngày dương'), selected: _calendar == 'SOLAR', onSelected: (_) => setState(() => _calendar = 'SOLAR')),
          ChoiceChip(label: const Text('Ngày âm'), selected: _calendar == 'LUNAR', onSelected: (_) => setState(() => _calendar = 'LUNAR')),
        ]),
        OutlinedButton.icon(onPressed: _saving ? null : _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text('Ngày dự kiến: ${_date(_scheduledDate)}')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: _time, decoration: const InputDecoration(labelText: 'Khung giờ mong muốn'), items: const ['08:30 – 10:00', '10:00 – 11:30', '14:00 – 15:30'].map((time) => DropdownMenuItem(value: time, child: Text(time))).toList(), onChanged: _saving ? null : (value) => setState(() => _time = value ?? _time)),
        const SizedBox(height: 6),
        Text(_calendar == 'LUNAR' ? 'Ngày được lưu theo lịch dương đã chọn; ghi chú ngày âm nếu cần.' : 'Ngày và khung giờ sẽ được nhân viên xác nhận lại.', style: const TextStyle(fontSize: 10, color: MauSala.chuPhu)),
      ]));

  Widget _prayerPanel() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(Icons.menu_book_outlined, 'Lời Dặn Dò & Văn Khấn Gia Tiên', 'Gửi lời nhắn riêng cho đội ngũ phụng dưỡng.'),
        const SizedBox(height: 10),
        TextField(controller: _prayer, minLines: 3, maxLines: 5, decoration: const InputDecoration(filled: true, fillColor: MauSala.xanhNhat, hintText: 'Ghi lời khấn nguyện, ngày âm mong muốn hoặc yêu cầu riêng...', border: OutlineInputBorder(borderSide: BorderSide.none))),
      ]));

  Widget _reportChannels() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(Icons.verified_user_outlined, 'Kênh Nhận Báo Cáo Nghiệm Thu', 'Chọn cách gia đình muốn nhận ảnh và cập nhật.'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _channels.keys.map((channel) => FilterChip(label: Text(channel), selected: _channels[channel]!, onSelected: _saving ? null : (value) => setState(() => _channels[channel] = value))).toList()),
      ]));

  Widget _summaryPanel() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [const Icon(Icons.receipt_long_outlined, color: MauSala.xanhThe), const SizedBox(width: 8), Expanded(child: Text('Phiếu Yêu Cầu Chăm Sóc', style: GoogleFonts.newsreader(fontSize: 20, color: MauSala.xanhDam))), const _Tag('CHỜ THANH TOÁN')]),
        const SizedBox(height: 12),
        ...widget.services.where((service) => _selected.contains(_id(service['id']))).map((service) => _line('${service['service_name']}', _price(service['price']))),
        if (_frequency == 'ANNUAL') _line('Ưu đãi định kỳ cả năm (10%)', -_discount, gold: true),
        const Divider(height: 22),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(7)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TỔNG THANH TOÁN DỰ KIẾN', style: TextStyle(fontSize: 9, color: MauSala.chuPhu, fontWeight: FontWeight.w700)), Text(GiaThamKhao.dinhDang(_total), style: GoogleFonts.newsreader(fontSize: 27, color: MauSala.xanhDam, fontWeight: FontWeight.w700))])),
        const SizedBox(height: 14),
        const Text('CHỌN PHƯƠNG THỨC THANH TOÁN', style: TextStyle(fontSize: 10, color: MauSala.chuPhu, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: ['VIETQR', 'MOMO', 'CARD', 'COUNTER'].map((method) => ChoiceChip(label: Text(_methodLabel(method)), selected: _payment == method, onSelected: _saving ? null : (_) => setState(() => _payment = method))).toList()),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(7)), child: Column(children: [const Icon(Icons.qr_code_2, color: MauSala.xanhDam, size: 70), Text(_payment == 'VIETQR' ? 'MÃ THANH TOÁN MINH HỌA' : _methodLabel(_payment), style: const TextStyle(fontSize: 10, color: MauSala.xanhDam, fontWeight: FontWeight.w700)), const Text('Chưa kết nối cổng ngân hàng; yêu cầu sẽ chờ nhân viên xác nhận thanh toán.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: MauSala.chuPhu))])),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _saving || _selected.isEmpty ? null : _submit, icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_outline), label: Text(_saving ? 'ĐANG LƯU YÊU CẦU…' : 'XÁC NHẬN ĐẶT DỊCH VỤ'), style: FilledButton.styleFrom(backgroundColor: MauSala.xanhDam, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48))),
        const SizedBox(height: 6),
        const Text('Chưa thu tiền trực tuyến tại bước này.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: MauSala.chuPhu)),
      ]));

  Widget _notePanel() => _panel(child: const Row(children: [Icon(Icons.support_agent_outlined, color: MauSala.vang), SizedBox(width: 8), Expanded(child: Text('Hotline hỗ trợ 24/7: 1900 68xx\nNhân viên sẽ liên hệ xác nhận lịch và phương thức thanh toán.', style: TextStyle(fontSize: 11, color: MauSala.chuPhu, height: 1.45)))]));

  Widget _line(String label, int value, {bool gold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: gold ? MauSala.vang : MauSala.chuPhu))), Text('${value < 0 ? '−' : ''}${GiaThamKhao.dinhDang(value.abs())}', style: TextStyle(fontSize: 11, color: gold ? MauSala.vang : MauSala.chu, fontWeight: FontWeight.w600))]));

  Widget _heading(IconData icon, String title, String subtitle) => Row(children: [Icon(icon, color: MauSala.xanhThe), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.newsreader(fontSize: 19, color: MauSala.xanhDam, fontWeight: FontWeight.w600)), Text(subtitle, style: const TextStyle(fontSize: 10, color: MauSala.chuPhu))]))]);

  Widget _panel({required Widget child}) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFE7EDF3)), boxShadow: const [BoxShadow(color: Color(0x0D1B4D3E), blurRadius: 12, offset: Offset(0, 3))]), child: child);

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: _scheduledDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
    if (value != null) setState(() => _scheduledDate = value);
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final result = await ApiService.instance.post('/care-orders/checkout', {
        'plotId': _id(widget.plot['plot_id']),
        'serviceIds': _selected.toList(),
        'scheduledAt': '${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}',
        'calendarType': _calendar,
        'scheduleType': _frequency,
        'timeSlot': _time,
        'prayerNote': _prayer.text.trim(),
        'reportChannels': _channels,
        'paymentMethod': _payment,
      });
      if (!mounted) return;
      final data = Map<String, dynamic>.from(result['data'] as Map);
      await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Đã lưu yêu cầu chăm sóc'), content: Text('Mã yêu cầu: ${data['batch_code'] ?? 'đang cập nhật'}\nTrạng thái: Chờ xác nhận thanh toán. Chưa có khoản tiền nào được thu trực tuyến.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))]));
      if (mounted) await widget.onCompleted();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _price(dynamic value) => value is num ? value.round() : num.tryParse('$value')?.round() ?? 0;
  int _id(dynamic value) => int.tryParse('$value') ?? 0;
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _methodLabel(String code) => const {'VIETQR':'VietQR tự động', 'MOMO':'Ví MoMo / ZaloPay', 'CARD':'Thẻ quốc tế', 'COUNTER':'Thanh toán tại quầy'}[code] ?? code;
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFFFF0CB), borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(color: MauSala.vang, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .3)));
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/gia_tham_khao.dart';
import '../core/mausala.dart';

class LapHopDongMoi extends StatefulWidget {
  const LapHopDongMoi({
    super.key,
    required this.plot,
    required this.user,
    required this.onChoosePlot,
    required this.onCancel,
    required this.onCreated,
  });

  final Map<String, dynamic>? plot;
  final Map<String, dynamic>? user;
  final VoidCallback onChoosePlot;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic> contract) onCreated;

  @override
  State<LapHopDongMoi> createState() => _LapHopDongMoiState();
}

class _LapHopDongMoiState extends State<LapHopDongMoi> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerName;
  late final TextEditingController _phone;
  final _identityCard = TextEditingController();
  final _address = TextEditingController();
  final _beneficiary = TextEditingController();
  final _relationship = TextEditingController();
  int _paymentPlan = 0;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customerName = TextEditingController(
        text: widget.user?['full_name']?.toString() ?? '');
    _phone =
        TextEditingController(text: widget.user?['phone']?.toString() ?? '');
  }

  @override
  void dispose() {
    _customerName.dispose();
    _phone.dispose();
    _identityCard.dispose();
    _address.dispose();
    _beneficiary.dispose();
    _relationship.dispose();
    super.dispose();
  }

  int get _total {
    final plot = widget.plot;
    if (plot == null) return 0;
    final quote = num.tryParse(plot['quote_price']?.toString() ?? '');
    return quote?.round() ?? GiaThamKhao.choLo(plot);
  }

  int get _deposit => _paymentPlan == 0 ? (_total * .2).round() : _total;
  int get _remaining => _total - _deposit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1050;
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading(wide),
                    const SizedBox(height: 14),
                    _steps(),
                    const SizedBox(height: 14),
                    if (widget.plot == null)
                      _plotRequired()
                    else
                      _formLayout(wide),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _heading(bool wide) {
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KINH DOANH & PHÁP LÝ  ›  LẬP HỢP ĐỒNG MỚI',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: .5,
                color: MauSala.vang,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Lập Hợp Đồng Mộ Phần',
            style: GoogleFonts.newsreader(
                fontSize: wide ? 30 : 25,
                fontWeight: FontWeight.w600,
                color: MauSala.xanhDam)),
        const SizedBox(height: 3),
        const Text(
            'Kiểm tra vị trí, thông tin thân nhân và phương thức thanh toán trước khi gửi hồ sơ xác nhận.',
            style: TextStyle(fontSize: 12, color: MauSala.chuPhu)),
      ],
    );
    final secure = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(8)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_user_outlined, color: MauSala.xanhThe, size: 20),
        SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HỒ SƠ ĐIỆN TỬ',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: MauSala.chuPhu)),
          Text('Thông tin được lưu an toàn',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: MauSala.xanhDam)),
        ]),
      ]),
    );
    if (!wide) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [intro, const SizedBox(height: 10), secure]);
    }
    return Row(children: [
      Expanded(child: intro),
      const SizedBox(width: 16),
      secure,
    ]);
  }

  Widget _steps() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _decoration(),
        child: const Row(children: [
          _StepBadge(number: '01', label: 'Vị Trí & Giá', active: true),
          _StepConnector(),
          _StepBadge(number: '02', label: 'Thân Nhân & Thụ Hưởng'),
          _StepConnector(),
          _StepBadge(number: '03', label: 'Thanh Toán & Trả Góp'),
        ]),
      );

  Widget _plotRequired() => _panel(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.map_outlined,
                color: MauSala.xanhThe, size: 30),
          ),
          const SizedBox(height: 14),
          Text('Chọn vị trí mộ trước khi lập hợp đồng',
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                  fontSize: 23,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
              'Chọn một lô còn trống trên sơ đồ. Mã lô và giá tham khảo sẽ được tự động điền vào hồ sơ này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: MauSala.chuPhu)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.onChoosePlot,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Chọn vị trí trên sơ đồ'),
            style: FilledButton.styleFrom(
                backgroundColor: MauSala.xanhDam,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13)),
          ),
        ]),
      );

  Widget _formLayout(bool wide) {
    final form = Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _plotCard(),
        const SizedBox(height: 12),
        _section(
          '02. Thông Tin Thân Nhân Đứng Tên',
          Icons.person_outline,
          Column(children: [
            _fieldRow([
              _textField(_customerName, 'Họ tên người đứng tên',
                  required: true),
              _textField(_phone, 'Số điện thoại liên hệ',
                  required: true, keyboard: TextInputType.phone),
            ]),
            const SizedBox(height: 10),
            _fieldRow([
              _textField(_identityCard, 'Số CCCD / Hộ chiếu', required: true),
              _textField(_address, 'Địa chỉ liên hệ'),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        _section(
          '03. Người Thụ Hưởng / Hương Linh',
          Icons.diversity_1_outlined,
          Column(children: [
            _fieldRow([
              _textField(_beneficiary, 'Họ tên người thụ hưởng',
                  required: true),
              _textField(_relationship, 'Mối quan hệ với người đứng tên',
                  required: true),
            ]),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Thông tin người thụ hưởng được ghi trong hồ sơ hợp đồng; việc lập hợp đồng chưa tạo hồ sơ an táng.',
                  style: TextStyle(fontSize: 11, color: MauSala.chuPhu)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _paymentPlanCard(),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _errorCard(_error!),
        ],
        const SizedBox(height: 12),
        _actions(),
      ]),
    );
    final summary = _paymentSummary();
    if (!wide) {
      return form;
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 7, child: form),
      const SizedBox(width: 14),
      Expanded(flex: 3, child: summary),
    ]);
  }

  Widget _plotCard() {
    final plot = widget.plot!;
    final code = plot['plot_code']?.toString() ?? 'Ô mộ';
    final zone = plot['zone_name']?.toString() ??
        plot['zone_code']?.toString() ??
        'Sala Garden';
    return _section(
      '01. Sản Phẩm & Kim Tĩnh Đã Chọn',
      Icons.location_on_outlined,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.grass_outlined, color: MauSala.xanhThe, size: 22),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(code,
                    style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MauSala.xanhDam)),
                Text('$zone • ${_plotType(plot)}',
                    style:
                        const TextStyle(fontSize: 11, color: MauSala.chuPhu)),
              ])),
          _tag('CÒN TRỐNG'),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(7)),
          child: Row(children: [
            const Icon(Icons.payments_outlined, color: MauSala.vang, size: 19),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('GIÁ THAM KHẢO TẠM TÍNH',
                  style: TextStyle(
                      fontSize: 10,
                      color: MauSala.chuPhu,
                      fontWeight: FontWeight.w600)),
            ),
            Text(GiaThamKhao.dinhDang(_total),
                style: GoogleFonts.newsreader(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: MauSala.xanhDam)),
          ]),
        ),
      ]),
    );
  }

  Widget _paymentPlanCard() => _section(
        '04. Lựa Chọn Phương Thức Thanh Toán',
        Icons.payments_outlined,
        Column(children: [
          _planOption(
            index: 0,
            title: 'Trả góp 12 tháng',
            subtitle: 'Đặt cọc dự kiến 20%, phần còn lại chia đều 12 kỳ.',
            amount: GiaThamKhao.dinhDang((_total * .2).round()),
          ),
          const SizedBox(height: 8),
          _planOption(
            index: 1,
            title: 'Thanh toán một lần',
            subtitle: 'Thanh toán toàn bộ sau khi hồ sơ được xác nhận.',
            amount: GiaThamKhao.dinhDang(_total),
          ),
          const SizedBox(height: 9),
          _paymentTotals(),
        ]),
      );

  Widget _planOption({
    required int index,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    final selected = _paymentPlan == index;
    return InkWell(
      onTap: () => setState(() => _paymentPlan = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7F4EE) : MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? MauSala.xanhThe : Colors.transparent),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19, color: selected ? MauSala.xanhThe : MauSala.chuPhu),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MauSala.xanhDam)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 10, color: MauSala.chuPhu)),
              ])),
          const SizedBox(width: 8),
          Text(amount,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MauSala.xanhDam)),
        ]),
      ),
    );
  }

  Widget _paymentSummary() => _section(
        'TÓM TẮT GIÁ TRỊ HỢP ĐỒNG',
        Icons.receipt_long_outlined,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sumLine('Tổng giá trị', GiaThamKhao.dinhDang(_total), bold: true),
          const Divider(height: 20),
          _sumLine(
              _paymentPlan == 0
                  ? 'Đặt cọc dự kiến (20%)'
                  : 'Thanh toán một lần',
              GiaThamKhao.dinhDang(_deposit),
              gold: true),
          if (_paymentPlan == 0) ...[
            const SizedBox(height: 8),
            _sumLine('Còn lại', GiaThamKhao.dinhDang(_remaining)),
            const SizedBox(height: 8),
            _sumLine('Mỗi kỳ (12 tháng)',
                GiaThamKhao.dinhDang((_remaining / 12).round())),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(7)),
            child: const Text(
                'Đây là số tiền dự kiến. Ban Quản Khách sẽ xác nhận giá và lịch thanh toán trước khi phát hành hợp đồng.',
                style: TextStyle(
                    fontSize: 10, height: 1.45, color: MauSala.chuPhu)),
          ),
        ]),
      );

  Widget _paymentTotals() => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFE7EDF3))),
        child: Column(children: [
          _sumLine('Tổng giá trị hợp đồng', GiaThamKhao.dinhDang(_total)),
          const SizedBox(height: 6),
          _sumLine(
              _paymentPlan == 0
                  ? 'Đặt cọc dự kiến (20%)'
                  : 'Thanh toán lần này',
              GiaThamKhao.dinhDang(_deposit),
              bold: true,
              gold: true),
          if (_paymentPlan == 0) ...[
            const SizedBox(height: 6),
            _sumLine('Còn lại sau đặt cọc', GiaThamKhao.dinhDang(_remaining)),
          ],
        ]),
      );

  Widget _actions() => _panel(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _submitting ? null : widget.onCancel,
              icon: const Icon(Icons.arrow_back, size: 17),
              label: const Text('Quay lại'),
            ),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.description_outlined, size: 17),
              label: Text(_submitting ? 'Đang gửi hồ sơ...' : 'Lập hợp đồng'),
              style: FilledButton.styleFrom(
                backgroundColor: MauSala.xanhDam,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
            ),
          ],
        ),
      );

  Widget _section(String title, IconData icon, Widget child) => _panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                  color: MauSala.xanhThe,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: MauSala.xanhThe, size: 18),
            const SizedBox(width: 7),
            Expanded(
                child: Text(title,
                    style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MauSala.xanhDam))),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _fieldRow(List<Widget> fields) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(children: [
              fields[0],
              const SizedBox(height: 9),
              fields[1],
            ]);
          }
          return Row(children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 10),
            Expanded(child: fields[1]),
          ]);
        },
      );

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập $label.'
                : null
            : null,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: MauSala.chu),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: const TextStyle(fontSize: 11, color: MauSala.chuPhu),
          filled: true,
          fillColor: MauSala.xanhNhat,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: MauSala.xanhThe)),
          errorStyle: const TextStyle(fontSize: 10),
        ),
      );

  Widget _sumLine(String label, String value,
          {bool bold = false, bool gold = false}) =>
      Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: bold ? 12 : 11,
                    color: MauSala.chuPhu,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
        const SizedBox(width: 8),
        Text(value,
            textAlign: TextAlign.end,
            style: TextStyle(
                fontSize: bold ? 13 : 11,
                color: gold ? MauSala.vang : MauSala.xanhDam,
                fontWeight: FontWeight.w700)),
      ]);

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFE7F4EE),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 9,
                color: MauSala.xanhDam,
                fontWeight: FontWeight.w700)),
      );

  Widget _errorCard(String text) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF93000A)))),
        ]),
      );

  Widget _panel({required Widget child, EdgeInsets? padding}) => Container(
        padding: padding ?? const EdgeInsets.all(14),
        decoration: _decoration(),
        child: child,
      );

  BoxDecoration _decoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7EDF3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D1B4D3E), blurRadius: 12, offset: Offset(0, 3)),
        ],
      );

  Future<void> _submit() async {
    if (widget.plot == null || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ApiService.instance.post('/contracts', {
        'plotId': widget.plot!['id'],
        'customerName': _customerName.text.trim(),
        'customerPhone': _phone.text.trim(),
        'identityCard': _identityCard.text.trim(),
        'address': _address.text.trim(),
        'beneficiaryName': _beneficiary.text.trim(),
        'beneficiaryRelationship': _relationship.text.trim(),
        'paymentType': _paymentPlan == 0 ? 'INSTALLMENT_12' : 'LUMP_SUM',
        'installmentMonths': _paymentPlan == 0 ? 12 : 0,
      });
      final contract = Map<String, dynamic>.from(result['data'] as Map);
      await widget.onCreated(contract);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _plotType(Map<String, dynamic> plot) {
    final zone = (plot['zone_code'] ?? '').toString().toUpperCase();
    final value = plot['plot_type']?.toString().toUpperCase();
    if (zone == 'M3') return 'Mộ đơn gia đình';
    if (zone == 'M7' || zone == 'M8') return 'Mộ gia tộc VVIP';
    switch (value) {
      case 'DOUBLE':
        return 'Mộ đôi liền kề';
      case 'FAMILY':
        return 'Mộ gia đình / gia tộc';
      default:
        return 'Mộ đơn tiêu chuẩn';
    }
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge(
      {required this.number, required this.label, this.active = false});

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active ? MauSala.xanhThe : MauSala.xanhNenThe,
              borderRadius: BorderRadius.circular(7),
              border: active
                  ? Border.all(color: MauSala.vangThe, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(number,
                style: TextStyle(
                    fontSize: 9,
                    color: active ? Colors.white : MauSala.chuPhu,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 7),
          Expanded(
              child: Text(label,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 10,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w600))),
        ]),
      );
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        color: MauSala.vien,
      );
}

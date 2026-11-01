import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_service.dart';
import '../core/mausala.dart';
import 'trangchuthannhan.dart';

class DangKyGiaTocScreen extends StatefulWidget {
  const DangKyGiaTocScreen({super.key});
  @override
  State<DangKyGiaTocScreen> createState() => _DangKyGiaTocScreenState();
}

class _DangKyGiaTocScreenState extends State<DangKyGiaTocScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _cccd = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _terms = true;
  bool _reminders = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _cccd.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (!_terms) {
      setState(() => _error = 'Bạn cần đồng ý với điều khoản để tiếp tục.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ApiService.instance.post('/auth/register', {
        'fullName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'nationalId': _cccd.text.trim(),
      });
      await ApiService.instance.saveToken(result['token'].toString());
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const TrangChuThanNhan()));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MauSala.nen,
    body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true, toolbarHeight: 64, backgroundColor: MauSala.nen,
        surfaceTintColor: Colors.transparent,
        title: Row(children: [
          IconButton(onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: MauSala.chuPhu)),
          if (MediaQuery.sizeOf(context).width > 620) ...[
            const Text('Quay về Trang Chủ Public', style: TextStyle(fontSize: 10, color: MauSala.chuPhu)),
            const SizedBox(width: 14), Container(width: 1, height: 22, color: MauSala.vien),
            const SizedBox(width: 14),
          ],
          const _Brand(),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width > 850) ...[
            TextButton(onPressed: () => Navigator.maybePop(context), child: const Text('Đăng Nhập')),
            const Text('Đăng Ký Gia Tộc', style: TextStyle(fontWeight: FontWeight.bold, color: MauSala.xanhDam, fontSize: 10)),
          ],
          const SizedBox(width: 12),
          const Icon(Icons.support_agent, color: MauSala.vang, size: 18),
          const SizedBox(width: 4),
          if (MediaQuery.sizeOf(context).width > 650)
            const Text('HOTLINE 24/7\n1900 636 288', style: TextStyle(fontSize: 8, color: MauSala.vang)),
        ]),
      ),
      SliverToBoxAdapter(child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1060),
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Column(children: [
              _ribbon(context),
              const SizedBox(height: 20),
              _card(context),
              const SizedBox(height: 20),
              _notice(),
            ]),
          ),
        ),
      )),
      SliverToBoxAdapter(child: Container(
        color: MauSala.xanhNhat, padding: const EdgeInsets.all(18),
        child: const Center(child: Text('SALA GARDEN  •  An Yên Miền Cực Lạc & Chăm Sóc Vĩnh Hằng  •  Chính Sách Bảo Mật',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: MauSala.chuPhu))),
      )),
    ]),
  );

  Widget _ribbon(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween, spacing: 12, runSpacing: 8,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        TextButton.icon(onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 14),
          label: const Text('Về Màn Hình Đăng Nhập', style: TextStyle(fontSize: 9)),
          style: TextButton.styleFrom(backgroundColor: MauSala.xanhNhat, foregroundColor: MauSala.xanhDam)),
        if (MediaQuery.sizeOf(context).width > 650)
          const Text('  •  HỒ SƠ ĐĂNG KÝ THÂN NHÂN CHÍNH THỨC • SALA GARDEN',
            style: TextStyle(fontSize: 8, color: MauSala.vang, letterSpacing: .5)),
      ]),
      const Text('◈ Cổng mã hóa bảo mật SSL 256-bit     ☎ Hỗ trợ 24/7: 1900 68xx',
        style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
    ],
  );

  Widget _card(BuildContext context) => Container(
    width: double.infinity, constraints: const BoxConstraints(maxWidth: 760),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Color(0x15003629), blurRadius: 26, offset: Offset(0, 12))]),
    child: Column(children: [
      Container(height: 4, decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [MauSala.vangThe, MauSala.vang, MauSala.xanhThe]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)))),
      Padding(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 28),
        child: Column(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: MauSala.vangThe.withValues(alpha: .35), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.spa, color: MauSala.vang)),
          const SizedBox(height: 8),
          const Text('KHÔNG GIAN TÂM LINH & QUẢN TRỊ GIA TỘC',
            style: TextStyle(fontSize: 8, color: MauSala.vang, letterSpacing: 1.2)),
          Text('ĐĂNG KÝ TÀI KHOẢN THÂN NHÂN',
            textAlign: TextAlign.center,
            style: GoogleFonts.newsreader(fontSize: 26, color: MauSala.xanhDam, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const Text('Khởi tạo tài khoản chính danh để quản lý phần mộ, tra cứu văn bản pháp lý, đăng ký chăm sóc định kỳ và nhận báo cáo trực tuyến.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 10, height: 1.55, color: MauSala.chuPhu)),
          const SizedBox(height: 15),
          _steps(),
          const SizedBox(height: 20),
          Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _label('Họ và tên người đại diện thân nhân', trailing: 'Theo CCCD / Sổ gia tộc'),
            const SizedBox(height: 5),
            TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
              decoration: _input(Icons.person_outline, 'Nhập họ tên đầy đủ (VD: Nguyễn Văn Bình)'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên.' : null),
            const SizedBox(height: 13),
            _phoneBlock(),
            const SizedBox(height: 13),
            _label('Số CCCD / Hộ chiếu người đứng tên hợp đồng', required: true, trailing: 'TỰ ĐỘNG KẾT NỐI HỒ SƠ'),
            const SizedBox(height: 5),
            TextFormField(controller: _cccd, decoration: _input(Icons.badge_outlined, 'Nhập số CCCD / Hộ chiếu để đối soát'),
              validator: (v) => v == null || v.trim().length < 8 ? 'Vui lòng nhập CCCD / hộ chiếu hợp lệ.' : null),
            const SizedBox(height: 4),
            const Text('* CCCD dùng để liên kết tài khoản với hồ sơ thân nhân đã có tại Sala Garden.',
              style: TextStyle(fontSize: 9, color: MauSala.chuPhu, fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, box) {
              final left = _passwordField('Mật khẩu mới', _password, _hidePassword,
                () => setState(() => _hidePassword = !_hidePassword),
                (v) => v == null || v.length < 8 ? 'Mật khẩu cần ít nhất 8 ký tự.' : null);
              final right = _passwordField('Xác nhận lại mật khẩu', _confirm, _hideConfirm,
                () => setState(() => _hideConfirm = !_hideConfirm),
                (v) => v != _password.text ? 'Mật khẩu chưa khớp.' : null);
              return box.maxWidth < 560
                ? Column(children: [left, const SizedBox(height: 13), right])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: left), const SizedBox(width: 14), Expanded(child: right)]);
            }),
            const SizedBox(height: 10),
            CheckboxListTile(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false),
              contentPadding: EdgeInsets.zero, dense: true, controlAffinity: ListTileControlAffinity.leading,
              activeColor: MauSala.xanhThe,
              title: const Text('Tôi cam kết thông tin chính xác và đồng ý Điều khoản dịch vụ & Chính sách bảo mật thân nhân.',
                style: TextStyle(fontSize: 9, height: 1.45, color: MauSala.chu))),
            CheckboxListTile(value: _reminders, onChanged: (v) => setState(() => _reminders = v ?? false),
              contentPadding: EdgeInsets.zero, dense: true, controlAffinity: ListTileControlAffinity.leading,
              activeColor: MauSala.xanhThe,
              title: const Text('Nhận thông báo ngày giỗ, tiết lễ và biên bản chăm sóc khi dịch vụ được kết nối.',
                style: TextStyle(fontSize: 9, height: 1.45, color: MauSala.chuPhu))),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Align(alignment: Alignment.centerLeft, child: Text(_error!,
                style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 11)))),
            SizedBox(height: 46, child: FilledButton.icon(
              onPressed: _busy ? null : _register,
              style: FilledButton.styleFrom(backgroundColor: MauSala.vang, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))),
              icon: _busy ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.arrow_forward, size: 17),
              label: Text(_busy ? 'ĐANG TẠO TÀI KHOẢN...' : 'TẠO TÀI KHOẢN THÂN NHÂN NGAY',
                style: const TextStyle(fontSize: 10, letterSpacing: .5, fontWeight: FontWeight.w700)),
            )),
          ])),
          const SizedBox(height: 13),
          Container(width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)),
            child: Wrap(alignment: WrapAlignment.center, spacing: 5, children: [
              const Text('Đã có tài khoản thân nhân Sala Garden rồi?', style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
              InkWell(onTap: () => Navigator.maybePop(context), child: const Text('Đăng Nhập Ngay Tại Đây',
                style: TextStyle(fontSize: 9, color: MauSala.xanhDam, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))),
            ])),
        ]),
      ),
    ]),
  );

  Widget _steps() => Container(
    constraints: const BoxConstraints(maxWidth: 430), padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      Expanded(child: _step(1, 'Thông tin & Xác thực', true)),
      Expanded(child: _step(2, 'Liên kết mã mộ phần', false)),
    ]),
  );

  Widget _step(int n, String text, bool active) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
    decoration: BoxDecoration(color: active ? MauSala.xanhDam : Colors.transparent, borderRadius: BorderRadius.circular(22)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircleAvatar(radius: 9, backgroundColor: active ? MauSala.vangThe : MauSala.xanhNenThe,
        child: Text('$n', style: TextStyle(fontSize: 9, color: active ? MauSala.xanhDam : MauSala.chuPhu))),
      const SizedBox(width: 5),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 8, color: active ? Colors.white : MauSala.chuPhu))),
    ]),
  );

  Widget _phoneBlock() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, box) {
        final phoneField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Số điện thoại đăng ký', required: true),
          const SizedBox(height: 5),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone,
            decoration: _input(Icons.smartphone, 'Nhập số điện thoại nhận thông báo'),
            validator: (v) => v == null || v.trim().length < 8 ? 'Vui lòng nhập số điện thoại hợp lệ.' : null),
        ]);
        final otp = OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.mark_email_read_outlined, size: 15),
          label: const Text('Gửi mã OTP', style: TextStyle(fontSize: 9)));
        return box.maxWidth < 500
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [phoneField, const SizedBox(height: 6), otp])
          : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: phoneField), const SizedBox(width: 9), otp]);
      }),
      const SizedBox(height: 7),
      const Text('OTP SMS/Zalo chưa được cấu hình. Hiện API tạo tài khoản và liên kết hồ sơ qua CCCD.',
        style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
    ]),
  );

  Widget _passwordField(String label, TextEditingController controller, bool hidden,
      VoidCallback toggle, String? Function(String?) validator) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label, required: true), const SizedBox(height: 5),
      TextFormField(controller: controller, obscureText: hidden,
        decoration: _input(label.startsWith('Xác') ? Icons.lock_reset : Icons.lock_outline, 'Ít nhất 8 ký tự').copyWith(
          suffixIcon: IconButton(onPressed: toggle, icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: MauSala.chuPhu))),
        validator: validator),
      if (label == 'Mật khẩu mới') ...[
        const SizedBox(height: 6),
        const LinearProgressIndicator(value: .7, minHeight: 4, color: MauSala.vang, backgroundColor: MauSala.xanhNenThe),
      ],
    ],
  );

  Widget _label(String text, {bool required = false, String? trailing}) => Row(children: [
    Flexible(child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: MauSala.chu))),
    if (required) const Text(' *', style: TextStyle(color: Color(0xFFBA1A1A))),
    if (trailing != null) ...[
      const Spacer(), Text(trailing, style: const TextStyle(fontSize: 8, color: MauSala.vang)),
    ],
  ]);

  InputDecoration _input(IconData icon, String hint) => InputDecoration(
    prefixIcon: Icon(icon, size: 17, color: MauSala.vang), hintText: hint, filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: MauSala.xanhThe)),
    errorStyle: const TextStyle(fontSize: 9),
  );

  Widget _notice() => Container(
    constraints: const BoxConstraints(maxWidth: 760), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(9)),
    child: const Row(children: [
      CircleAvatar(backgroundColor: MauSala.xanhDam, child: Icon(Icons.account_balance, color: MauSala.vangThe, size: 19)),
      SizedBox(width: 11),
      Expanded(child: Text('Đồng bộ hóa hồ sơ thân nhân\nCCCD được dùng để liên kết tài khoản với hồ sơ đã có tại Sala Garden. Cần hỗ trợ? Gọi Hotline 1900 68xx.',
        style: TextStyle(fontSize: 10, height: 1.5, color: MauSala.chuPhu))),
    ]),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 33, height: 33, decoration: BoxDecoration(color: MauSala.xanhDam, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.spa, color: MauSala.vangThe, size: 20)),
    const SizedBox(width: 7),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SALA GARDEN', style: GoogleFonts.newsreader(fontSize: 15, height: 1, color: MauSala.xanhDam, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      const Text('CÔNG VIÊN NGHĨA TRANG SINH THÁI', style: TextStyle(fontSize: 7, color: MauSala.vang, letterSpacing: .4)),
    ]),
  ]);
}

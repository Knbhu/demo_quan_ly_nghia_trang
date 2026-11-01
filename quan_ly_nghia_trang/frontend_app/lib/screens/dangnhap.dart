import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/mausala.dart';
import 'admin_dashboard_screen.dart';
import 'auth_register_screen.dart';
import 'trangchuthannhan.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _isFamily = true;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.instance.post('/auth/login', {
        'phone': _identifier.text.trim(),
        'password': _password.text,
      });
      final user = Map<String, dynamic>.from(result['user'] as Map);
      final role = (user['role_name'] ?? user['role'] ?? '').toString().toUpperCase();
      final isCustomer = role == 'CUSTOMER' || role == 'RELATIVE';
      final isStaff = role == 'ADMIN' || role == 'STAFF';

      if ((_isFamily && !isCustomer) || (!_isFamily && !isStaff)) {
        throw Exception(_isFamily
            ? 'Tài khoản này không thuộc nhóm Thân Nhân Gia Quyến.'
            : 'Tài khoản này không thuộc Ban Quản Lý.');
      }

      await ApiService.instance.saveToken(result['token'].toString());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isCustomer
              ? const TrangChuThanNhan()
              : const AdminDashboardScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSala.nen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: MauSala.nen.withValues(alpha: .96),
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: Row(children: [
              IconButton(
                tooltip: 'Quay về trang chủ',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, color: MauSala.chuPhu),
              ),
              if (MediaQuery.sizeOf(context).width > 600) ...[
                const Text('Quay về Trang Chủ Public',
                    style: TextStyle(fontSize: 12, color: MauSala.chuPhu)),
                const SizedBox(width: 18),
                Container(width: 1, height: 24, color: MauSala.vien),
                const SizedBox(width: 18),
              ],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: MauSala.xanhDam,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.spa, color: MauSala.vangThe),
              ),
              const SizedBox(width: 9),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SALA GARDEN',
                    style: GoogleFonts.newsreader(
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: MauSala.xanhDam)),
                const SizedBox(height: 4),
                const Text('CÔNG VIÊN NGHĨA TRANG SINH THÁI',
                    style: TextStyle(
                        fontSize: 8,
                        letterSpacing: .8,
                        color: MauSala.vang,
                        fontWeight: FontWeight.w700)),
              ]),
              const Spacer(),
              if (MediaQuery.sizeOf(context).width > 930)
                const Row(children: [
                  _NavLabel('Đăng Nhập', selected: true),
                  _NavLabel('Đăng Ký Gia Tộc'),
                  _NavLabel('Tra Cứu Hồ Sơ'),
                  _NavLabel('Hỗ Trợ Tang Lễ'),
                ]),
              const SizedBox(width: 12),
              if (MediaQuery.sizeOf(context).width > 700)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: MauSala.vangThe.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('HOTLINE 24/7',
                        style: TextStyle(fontSize: 8, color: MauSala.vang)),
                    Text('1900 636 288',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 16,
                backgroundColor: MauSala.xanhDam,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                  child: Column(children: [
                    _contextRibbon(context),
                    const SizedBox(height: 22),
                    LayoutBuilder(builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      final story = _story(context);
                      final loginCard = _loginCard(context);
                      return compact
                          ? Column(children: [loginCard, const SizedBox(height: 30), story])
                          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Expanded(flex: 5, child: story),
                              const SizedBox(width: 48),
                              Expanded(flex: 7, child: loginCard),
                            ]);
                    }),
                    const SizedBox(height: 42),
                    _trustBadges(context),
                  ]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _footer(context)),
        ],
      ),
    );
  }

  Widget _contextRibbon(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 18,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MauSala.vangThe.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('●  CỔNG QUẢN TRỊ & THÂN NHÂN',
                  style: TextStyle(fontSize: 9, color: MauSala.vang, letterSpacing: .4)),
            ),
            if (MediaQuery.sizeOf(context).width > 600) ...[
              const SizedBox(width: 12),
              const Text('Hệ Thống Quản Lý Dịch Vụ Sinh Thái & Hoa Viên Tưởng Niệm Sala Garden 50ha',
                  style: TextStyle(fontSize: 10, color: MauSala.chuPhu)),
            ],
          ]),
          const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_user_outlined, size: 15, color: MauSala.vang),
            SizedBox(width: 6),
            Text('Bảo mật chuẩn quốc tế SSL 256-bit',
                style: TextStyle(fontSize: 10, color: MauSala.chuPhu)),
          ]),
        ],
      );

  Widget _story(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.filter_vintage, size: 18, color: MauSala.vang),
            SizedBox(width: 7),
            Text('MIỀN DI TẢN TĨNH TẠI • NGHĨA TÌNH TRỌN VẸN',
                style: TextStyle(fontSize: 9, color: MauSala.vang, letterSpacing: 1)),
          ]),
          const SizedBox(height: 12),
          Text('Nơi Lưu Giữ Ký Ức & Kết Nối Vĩnh Hằng Của Gia Tộc',
              style: GoogleFonts.newsreader(
                  fontSize: MediaQuery.sizeOf(context).width < 600 ? 30 : 34,
                  height: 1.15,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          const Text(
            'Hệ thống chuyên biệt hỗ trợ thân nhân gia quyến cập nhật trực tuyến hiện trạng khuôn viên, đăng ký lễ cúng giỗ định kỳ, và tra cứu hồ sơ quy hoạch mộ phần an yên tại Sala Garden.',
            style: TextStyle(fontSize: 13, height: 1.7, color: MauSala.chuPhu),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDDRLVK4RRBaSyI3BjtBTlmndjNNkidgwQbRoVyFBPFRPTt6zCV8kwyFTr56yzvhumvnrL3fF6IN91vZ6N75yXL60ZS5Pwlq_17BQM_xfitBVT-nt1YTK5__taoAU2tvXAZDRSIPj9u2yP6M_J8OJRe_1Ik23_k6OY30ZzSJOdCz_OYPM0PiD0ITNM3kTIIfS2ByQd3ejZPtjLNWE1dKcQ_2eFL22_nlVgLqyuN1vRs1uoZ2gI31fpk',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: MauSala.xanhThe),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC003629)]),
                  ),
                ),
                const Positioned(left: 16, right: 16, bottom: 14,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hồ Tịnh Tâm & Rừng Sa-la',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text('KHU A1 • HOA VIÊN SINH THÁI',
                          style: TextStyle(color: MauSala.xanhNhat, fontSize: 9, letterSpacing: .8)),
                    ]),
                    Chip(avatar: Icon(Icons.nature_people, size: 15), label: Text('Sinh Thái 5 Sao'),
                      visualDensity: VisualDensity.compact),
                  ])),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _metric(Icons.account_balance, '100%', 'Minh bạch pháp lý & sở hữu vĩnh viễn')),
            const SizedBox(width: 12),
            Expanded(child: _metric(Icons.temple_buddhist, '24/7/365', 'Nghi lễ trang nghiêm & hương khói tề chỉnh', gold: true)),
          ]),
        ],
      );

  Widget _metric(IconData icon, String title, String text, {bool gold = false}) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: gold ? MauSala.vang : MauSala.xanhThe, size: 20),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: MauSala.xanhDam)),
            Text(text, style: const TextStyle(fontSize: 10, height: 1.4, color: MauSala.chuPhu)),
          ])),
        ]),
      );

  Widget _loginCard(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560),
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x18003629), blurRadius: 25, offset: Offset(0, 12))],
        ),
        child: Column(children: [
          Container(height: 4, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [MauSala.xanhDam, MauSala.vang, MauSala.xanhDam]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)))),
          const SizedBox(height: 20),
          Container(width: 58, height: 58,
            decoration: BoxDecoration(color: MauSala.vangThe.withValues(alpha: .45), shape: BoxShape.circle),
            child: const Center(child: CircleAvatar(radius: 22, backgroundColor: MauSala.xanhDam,
              child: Icon(Icons.spa, color: MauSala.vangThe, size: 25)))),
          const SizedBox(height: 12),
          Text('ĐĂNG NHẬP HỆ THỐNG',
              style: GoogleFonts.newsreader(fontSize: 24, color: MauSala.xanhDam, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Cổng thông tin quản lý dịch vụ hậu sự & tưởng niệm Sala Garden',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: MauSala.chuPhu)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(25)),
            child: Row(children: [
              Expanded(child: _roleButton('Thân Nhân Gia Quyến', Icons.diversity_1, true)),
              Expanded(child: _roleButton('Ban Quản Lý', Icons.security, false)),
            ]),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(children: [
              _labelRow('Số điện thoại hoặc Username', _isFamily ? 'HỒ SƠ GIA QUYẾN' : 'CỔNG QUẢN TRỊ'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _identifier,
                keyboardType: TextInputType.text,
                decoration: _inputDecoration(
                  icon: _isFamily ? Icons.phone_iphone : Icons.badge_outlined,
                  hint: _isFamily ? 'Nhập số điện thoại đã đăng ký' : 'Nhập username hoặc số điện thoại',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tài khoản.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _labelRow('Mật khẩu bảo mật', 'BẢO MẬT ĐA TẦNG'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(icon: Icons.lock_outline, hint: 'Nhập mật khẩu của bạn').copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: MauSala.chuPhu, size: 20),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null,
                onFieldSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Checkbox(value: _rememberMe, onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: MauSala.xanhThe, visualDensity: VisualDensity.compact),
                const Expanded(child: Text('Ghi nhớ đăng nhập trên thiết bị này',
                    style: TextStyle(fontSize: 10, color: MauSala.chuPhu))),
                TextButton(onPressed: _showForgotPassword,
                  child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 10, color: MauSala.vang))),
              ]),
              if (_error != null) ...[
                Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF0EE), borderRadius: BorderRadius.circular(7)),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12))),
              ],
              SizedBox(width: double.infinity, height: 48,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _login,
                  style: FilledButton.styleFrom(backgroundColor: MauSala.xanhDam, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  icon: _loading ? const SizedBox(width: 17, height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const SizedBox.shrink(),
                  label: Text(_loading ? 'ĐANG XÁC THỰC...' : 'ĐĂNG NHẬP VÀO HỆ THỐNG  →',
                    style: const TextStyle(fontSize: 11, letterSpacing: .7, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [const Expanded(child: Divider(color: MauSala.xanhNenThe)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('HOẶC XÁC THỰC NHANH BẰNG',
              style: TextStyle(fontSize: 8, color: MauSala.chuPhu.withValues(alpha: .8), letterSpacing: .6))),
            const Expanded(child: Divider(color: MauSala.xanhNenThe))]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _socialButton('Z', 'Tài khoản Zalo')),
            const SizedBox(width: 10),
            Expanded(child: _socialButton('G', 'Google Account', google: true)),
          ]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(9)),
            child: Row(children: [
              const Icon(Icons.family_restroom, color: MauSala.vang, size: 19),
              const SizedBox(width: 8),
              const Expanded(child: Text('Chưa đăng ký mã định danh mộ phần gia tộc?',
                style: TextStyle(fontSize: 10, color: MauSala.chu))),
              TextButton(onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AuthRegisterScreen())),
                child: const Text('Đăng Ký Ngay  ›', style: TextStyle(fontSize: 10, color: MauSala.vang))),
            ]),
          ),
        ]),
      );

  Widget _roleButton(String label, IconData icon, bool family) {
    final selected = _isFamily == family;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() { _isFamily = family; _error = null; }),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? MauSala.xanhDam : Colors.transparent,
            borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: selected ? Colors.white : MauSala.chuPhu),
          const SizedBox(width: 5),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : MauSala.chuPhu))),
        ]),
      ),
    );
  }

  Widget _labelRow(String label, String hint) => Row(children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MauSala.chu)),
        const SizedBox(width: 3),
        const Text('*', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(hint, style: const TextStyle(fontSize: 8, color: MauSala.vang, letterSpacing: .4)),
      ]);

  InputDecoration _inputDecoration({required IconData icon, required String hint}) => InputDecoration(
        prefixIcon: Icon(icon, size: 19, color: MauSala.chuPhu),
        hintText: hint,
        filled: true,
        fillColor: MauSala.xanhNhat,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: MauSala.xanhThe, width: 1.3)),
        errorStyle: const TextStyle(fontSize: 10),
      );

  Widget _socialButton(String letter, String label, {bool google = false}) => OutlinedButton.icon(
        onPressed: () => _showMessage('$label chưa được kết nối với hệ thống.'),
        icon: CircleAvatar(radius: 9, backgroundColor: google ? Colors.white : const Color(0xFF0068FF),
          child: Text(letter, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: google ? const Color(0xFF4285F4) : Colors.white))),
        label: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
        style: OutlinedButton.styleFrom(backgroundColor: MauSala.xanhNhat, foregroundColor: MauSala.chu,
          side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 12)),
      );

  Widget _trustBadges(BuildContext context) {
    final items = [
      (Icons.enhanced_encryption, 'Mã Hóa Dữ Liệu Gia Tộc', 'Bảo mật gia phả & quyền định danh tuyệt đối'),
      (Icons.history_edu, 'Minh Chứng Pháp Lý Điện Tử', 'Hợp đồng chuyển nhượng số & trích lục lưu trữ'),
      (Icons.emergency, 'Túc Trực Tang Lễ Khẩn Cấp', 'Hotline ưu tiên tiếp nhận hỗ trợ trong vòng 15 phút'),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: items.map((item) => Container(
      width: MediaQuery.sizeOf(context).width < 750 ? double.infinity : (MediaQuery.sizeOf(context).width - 100) / 3,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(9)),
      child: Row(children: [Icon(item.$1, color: MauSala.xanhThe), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.$2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          Text(item.$3, style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]))]),
    )).toList());
  }

  Widget _footer(BuildContext context) => Container(
        color: MauSala.xanhNhat,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 12, spacing: 20, children: [
          Text('SALA GARDEN  •  An Yên Miền Cực Lạc & Chăm Sóc Vĩnh Hằng',
              style: GoogleFonts.newsreader(fontSize: 14, color: MauSala.xanhDam)),
          const Text('Chính Sách Bảo Mật     Quy Định Hoa Viên     Nghi Thức Tâm Linh',
              style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
          const Text('© 2025 Sala Garden Eco-Memorial Park',
              style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]),
      );

  void _showForgotPassword() => _showMessage('Vui lòng liên hệ Hotline 1900 636 288 để được hỗ trợ khôi phục mật khẩu.');

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label, {this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(label, style: TextStyle(fontSize: 10,
          color: selected ? MauSala.xanhDam : MauSala.chuPhu,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      );
}

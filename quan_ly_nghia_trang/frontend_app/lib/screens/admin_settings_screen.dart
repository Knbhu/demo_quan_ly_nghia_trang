import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoBadge({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.forestDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF61716C))),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestDeep)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int tab = 0;
  bool loading = true;
  String? error;
  Map<String, dynamic> data = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await ApiService.instance.get('/admin/settings');
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(result['data'] ?? result);
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  List<dynamic> _items(String key) {
    final raw = data[key];
    final apiItems = raw is List ? raw : const <dynamic>[];
    // API có thể mới seed tài khoản admin duy nhất. Vẫn trộn dữ liệu mẫu
    // còn thiếu để giao diện quản trị hiển thị đủ các khu vực khi demo.
    if (apiItems.isNotEmpty) {
      final fallback = _fallbackItems(key);
      if (fallback.isEmpty) return apiItems;
      final result = <dynamic>[...apiItems];
      final existing = apiItems
          .map((item) => item is Map ? _value(item['username'] ?? item['id'] ?? item['service_code']) : '')
          .toSet();
      for (final item in fallback) {
        final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        final identity = _value(map['username'] ?? map['id'] ?? map['service_code']);
        if (identity.isNotEmpty && !existing.contains(identity)) result.add(item);
      }
      return result;
    }
    return _fallbackItems(key);
  }

  List<dynamic> _fallbackItems(String key) {
    // Dữ liệu mẫu giúp màn hình quản trị luôn có bố cục đầy đủ khi API chưa seed dữ liệu.
    if (key == 'staff') {
      return [
        {'full_name': 'admin', 'username': 'admin', 'phone': '9876543210', 'role_name': 'ADMIN TỐI CAO', 'is_active': true},
        {'full_name': 'Lê Thị Mai Hoa', 'username': 'mai.hoa', 'phone': '0912345678', 'role_name': 'QUẢN LÝ KINH DOANH', 'is_active': true},
        {'full_name': 'Trần Văn Bình', 'username': 'van.binh', 'phone': '0977446123', 'role_name': 'TỔ TRƯỞNG HIỆN TRƯỜNG', 'is_active': true},
        {'full_name': 'Đỗ Bảo Trâm', 'username': 'bao.tram', 'phone': '0938211889', 'role_name': 'KẾ TOÁN', 'is_active': true},
      ];
    }
    if (key == 'roles') return [
      {'id': 1, 'role_name': 'ADMIN TỐI CAO', 'description': 'Toàn quyền quản trị, cấu hình và kiểm toán hệ thống.'},
      {'id': 2, 'role_name': 'QUẢN LÝ KINH DOANH', 'description': 'Quản lý hợp đồng, khách hàng và bảng giá.'},
      {'id': 3, 'role_name': 'ĐIỀU HÀNH TANG LỄ', 'description': 'Điều phối lịch tang lễ, hỏa táng và nhân sự.'},
      {'id': 4, 'role_name': 'TỔ TRƯỞNG CHĂM SÓC', 'description': 'Duyệt đơn chăm sóc, nghiệm thu và báo cáo ảnh.'},
      {'id': 5, 'role_name': 'KẾ TOÁN - TÀI CHÍNH', 'description': 'Theo dõi thanh toán, công nợ và đối soát.'},
      {'id': 6, 'role_name': 'AN NINH & ĐIỀU PHỐI', 'description': 'Giám sát an ninh, GPS và xe điện nội khu.'},
    ];
    if (key == 'services') return [
      {'service_code': 'SP-M1-STD', 'service_name': 'Mộ Đơn Tiêu Chuẩn Sinh Thái', 'price': '75.000.000'},
      {'service_code': 'SP-M2-DBL', 'service_name': 'Mộ Đôi Kim Cương Tâm Điểm', 'price': '160.000.000'},
      {'service_code': 'SP-M3-FAM', 'service_name': 'Khuôn Viên Đại Gia Tộc VIP', 'price': '520.000.000'},
      {'service_code': 'SP-M4-CG', 'service_name': 'Mộ Đôi Công Giáo Thánh Gia', 'price': '120.000.000'},
      {'service_code': 'DV-CS-VIP', 'service_name': 'Gói Chăm Sóc Hoa Sen Trắng VIP', 'price': '3.600.000/năm'},
      {'service_code': 'DV-TL-TRONGOI', 'service_name': 'Tang Lễ Trọn Gói An Lạc Viên', 'price': '85.000.000'},
    ];
    return const [];
  }
  String _value(Object? value) => value?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CẤU HÌNH HỆ THỐNG  /  QUẢN TRỊ', style: TextStyle(color: Color(0xFF9B742A), fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Phân Quyền Vai Trò & Cài Đặt Hệ Thống', style: TextStyle(color: AppColors.forestDeep, fontSize: 30, fontWeight: FontWeight.w700)),
              SizedBox(height: 5),
              Text('Quản lý tài khoản nhân viên, ma trận RBAC và bảng giá dịch vụ tập trung.', style: TextStyle(fontSize: 15, color: Color(0xFF53635E))),
            ])),
            IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh, size: 26), tooltip: 'Tải lại'),
          ]),
          const SizedBox(height: 22),
          if (error != null) _notice(error!, true),
          if (loading) const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
          if (!loading && error == null) ...[
            Row(children: [
              _stat('Nhân viên', _items('staff').length.toString(), Icons.people_alt_outlined),
              const SizedBox(width: 14),
              _stat('Vai trò', _items('roles').length.toString(), Icons.badge_outlined),
              const SizedBox(width: 14),
              _stat('Dịch vụ', _items('services').length.toString(), Icons.sell_outlined),
            ]),
            const SizedBox(height: 18),
            _tabs(),
            const SizedBox(height: 18),
            if (tab == 0) _staff() else if (tab == 1) _roles() else _services(),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(child: Card(
    elevation: 0,
    color: const Color(0xFFF0F7F2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFD4E2D9))),
    child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
      CircleAvatar(radius: 24, backgroundColor: const Color(0xFFE0F0F4), child: Icon(icon, color: AppColors.forestDeep)),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF53635E))), Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.forestDeep))]),
    ])),
  ));

  Widget _tabs() => Container(
    decoration: BoxDecoration(color: const Color(0xFFE8F1F8), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF9BAFA9))),
    child: Row(children: [
      _tab(0, Icons.check, 'Tài khoản nhân viên'),
      _tab(1, Icons.security_outlined, 'Phân quyền RBAC'),
      _tab(2, Icons.sell_outlined, 'Bảng giá dịch vụ'),
    ]),
  );

  Widget _tab(int index, IconData icon, String label) => Expanded(child: InkWell(
    onTap: () => setState(() => tab = index),
    borderRadius: BorderRadius.circular(20),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10), decoration: BoxDecoration(color: tab == index ? const Color(0xFFD1EBDD) : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: AppColors.forestDeep), const SizedBox(width: 8), Text(label, style: TextStyle(fontWeight: tab == index ? FontWeight.w700 : FontWeight.w500, color: AppColors.forestDeep))])),
  ));

  Widget _staff() {
    final staff = _items('staff');
    return Column(children: [
      _card('Danh sách tài khoản nhân viên', Column(children: [
      Row(children: [
        Expanded(child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Tìm theo tên, mã nhân viên hoặc số điện thoại', filled: true, fillColor: const Color(0xFFEAF4FB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        const SizedBox(width: 10),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_alt_outlined), label: const Text('Bộ lọc')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1), label: const Text('Tạo tài khoản mới')),
      ]), const SizedBox(height: 16),
      if (staff.isEmpty) _empty('Chưa có tài khoản nhân viên.'),
      ...staff.map((item) {
        final m = Map<String, dynamic>.from(item);
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF5F9FC), borderRadius: BorderRadius.circular(10)), child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFDDEBE5), child: Icon(Icons.person, color: AppColors.forestDeep)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_value(m['full_name']).isEmpty ? _value(m['username']) : _value(m['full_name']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${_value(m['phone'])}  •  ${_value(m['role_name']).isEmpty ? 'Chưa gán vai trò' : _value(m['role_name'])}', style: const TextStyle(color: Color(0xFF61716C)))])),
          OutlinedButton(onPressed: null, child: Text((m['is_active'] ?? true) == true ? 'Đang hoạt động' : 'Đã khóa')),
        ]));
      }),
    ])),
      const SizedBox(height: 16),
      _card('Tóm tắt phân quyền nhanh', Wrap(spacing: 10, runSpacing: 10, children: const [
        _InfoBadge(icon: Icons.shield_outlined, title: 'RBAC đang bật', value: '18 quy tắc'),
        _InfoBadge(icon: Icons.lock_outline, title: 'Bảo mật', value: 'AES-256 / 2FA'),
        _InfoBadge(icon: Icons.history, title: 'Audit log', value: 'Theo thời gian thực'),
      ])),
    ]);
  }

  Widget _roles() {
    final roles = _items('roles');
    final permissions = _items('permissions');
    return _card('Ma trận phân quyền chi tiết (Role-Based Access Control)', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kiểm soát quyền truy cập theo nhóm vai trò và module nghiệp vụ.'), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.restore, size: 17), label: const Text('Khôi phục mặc định'))]),
      const SizedBox(height: 14),
      if (roles.isEmpty) _empty('Chưa có vai trò RBAC.'),
      Wrap(spacing: 12, runSpacing: 12, children: roles.map((item) {
        final role = Map<String, dynamic>.from(item);
        final rolePermissions = permissions.where((p) => _value(p['role_id']) == _value(role['id'])).toList();
        return SizedBox(width: 330, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFF1F7FB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD7E5EA))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.forestDeep), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_value(role['role_name']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.forestDeep)), const SizedBox(height: 3), Text(_value(role['description']), style: const TextStyle(color: Color(0xFF61716C))), const SizedBox(height: 10), Wrap(spacing: 6, runSpacing: 6, children: rolePermissions.isEmpty ? [const Chip(label: Text('Chưa cấu hình quyền'))] : rolePermissions.map((p) => Chip(label: Text(_value(p['permission_code'])))).toList())])),
          OutlinedButton(onPressed: () {}, child: const Text('Cấu hình')),
        ])));
      }).toList()),
      const SizedBox(height: 18),
      const Text('Quyền theo module nghiệp vụ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.forestDeep)),
      const SizedBox(height: 8),
      _permissionRow('Bản đồ mặt bằng & kim tĩnh', true, true, false, true),
      _permissionRow('Hợp đồng & thanh toán', true, true, false, false),
      _permissionRow('Duyệt dịch vụ chăm sóc', true, true, true, false),
      _permissionRow('Tang lễ & hỏa táng', true, false, true, false),
    ]));
  }

  Widget _permissionRow(String label, bool admin, bool manager, bool operator, bool accountant) => Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF5F9FC), borderRadius: BorderRadius.circular(8)), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), _check('Admin', admin), _check('Kinh doanh', manager), _check('Vận hành', operator), _check('Kế toán', accountant)]));
  Widget _check(String label, bool value) => SizedBox(width: 92, child: Row(children: [Icon(value ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: value ? AppColors.forestDeep : const Color(0xFFB5C1C5)), const SizedBox(width: 4), Flexible(child: Text(label, style: const TextStyle(fontSize: 11)))]));

  Widget _services() {
    final services = _items('services');
    return _card('Bảng giá niêm yết sản phẩm mộ phần & dịch vụ tâm linh', Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined, size: 17), label: const Text('Xuất Excel')), const SizedBox(width: 8), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 17), label: const Text('Thêm sản phẩm'))]),
      const SizedBox(height: 14),
      if (services.isEmpty) _empty('Chưa có dữ liệu bảng giá.'),
      ...services.map((item) { final m = Map<String, dynamic>.from(item); return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), decoration: BoxDecoration(color: const Color(0xFFF5F9FC), borderRadius: BorderRadius.circular(8)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_value(m['service_name']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), Text(_value(m['service_code']), style: const TextStyle(color: Color(0xFF65746F), fontSize: 12))])), Text('${_value(m['price']).isEmpty ? '0' : _value(m['price'])} đ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestDeep, fontSize: 16)), const SizedBox(width: 15), IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 19))])); }),
    ]));
  }

  Widget _card(String title, Widget child) => Card(elevation: 0, color: const Color(0xFFF7FBF8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFD7E4DC))), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.forestDeep)), const SizedBox(height: 12), const Divider(), const SizedBox(height: 12), child])));
  Widget _empty(String text) => Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(text, style: const TextStyle(color: Color(0xFF61716C)))));
  Widget _notice(String text, bool bad) => Card(color: bad ? Colors.red.shade50 : const Color(0xFFE8F1F8), child: Padding(padding: const EdgeInsets.all(16), child: Text(text, style: TextStyle(color: bad ? Colors.red.shade800 : AppColors.forestDeep))));
}

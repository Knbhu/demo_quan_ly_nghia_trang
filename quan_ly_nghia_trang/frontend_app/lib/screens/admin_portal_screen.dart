import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/api_service.dart';
import 'hopdongadmin.dart';
import 'sodotongquan.dart';
import 'danhba_thannhan_admin.dart';
import 'hosomo_qr_admin.dart';
import 'admin_dieu_hanh_tangle_screen.dart';
import 'admin_don_cham_soc_screen.dart';
import 'admin_settings_screen.dart';

enum AdminArea {
  overview,
  map,
  contracts,
  families,
  memorial,
  funeral,
  care,
  staff,
  roles,
  gps
}

const _areas = <(AdminArea, String, IconData)>[
  (AdminArea.overview, 'Tổng quan', Icons.dashboard_outlined),
  (AdminArea.map, 'Sơ đồ mặt bằng 2D/3D', Icons.grid_view_rounded),
  (AdminArea.contracts, 'Hợp đồng & trả góp', Icons.receipt_long_outlined),
  (AdminArea.families, 'Sổ bạ thân nhân', Icons.groups_outlined),
  (AdminArea.memorial, 'Hồ sơ mộ & QR', Icons.qr_code_2),
  (AdminArea.funeral, 'Điều hành tang lễ', Icons.local_florist_outlined),
  (AdminArea.care, 'Chăm sóc & ảnh thực tế', Icons.volunteer_activism_outlined),
  (AdminArea.gps, 'Định vị GPS & dẫn đường', Icons.near_me_outlined),
  (AdminArea.staff, 'Phân công vệ sinh', Icons.engineering_outlined),
  (
    AdminArea.roles,
    'Phân quyền & cài đặt',
    Icons.admin_panel_settings_outlined
  ),
];

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});
  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  AdminArea area = AdminArea.overview;
  String _adminName = 'Quản trị viên';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    try {
      final result = await ApiService.instance.get('/auth/me');
      final user = Map<String, dynamic>.from(result['user'] as Map);
      if (mounted)
        setState(() =>
            _adminName = (user['full_name'] ?? 'Quản trị viên').toString());
    } catch (_) {
      // Keep a useful fallback when the API is temporarily unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final selected = _areas.indexWhere((item) => item.$1 == area);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.park_outlined, color: AppColors.forest, size: 25),
            SizedBox(width: 8),
            Text('SALA GARDEN  •  CỔNG QUẢN TRỊ',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDeep)),
          ]),
          actions: [
            if (width > 650)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                      child: Text('Hệ thống hoạt động bình thường',
                          style: TextStyle(color: AppColors.forest)))),
            IconButton(
                tooltip: 'Thông báo',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none)),
            if (width > 760)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_adminName,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      const Text('Quản trị viên cao nhất',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.muted)),
                    ]),
              ),
            const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.account_circle, color: AppColors.forest))
          ]),
      drawer: width < 850 ? Drawer(child: _navList()) : null,
      body: Row(children: [
        if (width >= 850)
          SizedBox(
              width: 235,
              // ListTile paints selected backgrounds and ink reactions on its
              // nearest Material. A ColoredBox between them hides those paints
              // and causes a Flutter framework assertion for every tile.
              child: Material(color: Colors.white, child: _navList())),
        Expanded(
            child: AdminModuleView(
                area: area, onNavigate: (next) => setState(() => area = next))),
      ]),
      bottomNavigationBar: width < 650
          ? NavigationBar(
              selectedIndex: selected.clamp(0, 4).toInt(),
              onDestinationSelected: (i) => setState(() => area = _areas[i].$1),
              destinations: [
                  for (final item in _areas.take(5))
                    NavigationDestination(
                        icon: Icon(item.$3), label: item.$2.split(' ').first)
                ])
          : null,
    );
  }

  Widget _navList() => ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          children: [
            for (var i = 0; i < _areas.length; i++) ...[
              if (i == 0 || i == 2 || i == 5 || i == 8)
                Padding(
                  padding: EdgeInsets.fromLTRB(12, i == 0 ? 12 : 18, 8, 6),
                  child: Text(
                    i == 0
                        ? 'BÁO CÁO & TỔNG QUAN'
                        : i == 2
                            ? 'KINH DOANH & KHÁCH HÀNG'
                            : i == 5
                                ? 'DỊCH VỤ & THI CÔNG'
                                : 'CẤU HÌNH HỆ THỐNG',
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: ListTile(
                  selected: area == _areas[i].$1,
                  selectedTileColor: AppColors.forest,
                  selectedColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  leading: Icon(_areas[i].$3),
                  title:
                      Text(_areas[i].$2, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    setState(() => area = _areas[i].$1);
                    if (MediaQuery.sizeOf(context).width < 850)
                      Navigator.pop(context);
                  },
                ),
              ),
            ]
          ]);
}

class AdminModuleView extends StatelessWidget {
  final AdminArea area;
  final ValueChanged<AdminArea> onNavigate;
  const AdminModuleView(
      {super.key, required this.area, required this.onNavigate});
  static const _titles = {
    AdminArea.overview: (
      'Trung Tâm Điều Hành & Vận Hành Tổng Thể Sala Garden',
      'Giám sát khuôn viên, ô mộ, doanh thu và hoạt động trong ngày.'
    ),
    AdminArea.map: (
      'Sơ Đồ Phân Khu Quy Hoạch Mặt Bằng 50ha',
      'Tra cứu trạng thái ô mộ trong toàn khuôn viên.'
    ),
    AdminArea.contracts: (
      'Quản Lý Hợp Đồng & Kế Hoạch Trả Góp',
      'Theo dõi hợp đồng, tiến độ thanh toán và các khoản đến hạn.'
    ),
    AdminArea.families: (
      'Sổ Bạ Thân Nhân & Hồ Sơ Khách Hàng',
      'Quản lý tài khoản gia đình và thông tin liên hệ.'
    ),
    AdminArea.memorial: (
      'Danh Bạ Người Quá Cố & Quản Lý Mã QR Bia Mộ',
      'Lưu hồ sơ tưởng niệm và liên kết mã QR tại khuôn viên.'
    ),
    AdminArea.funeral: (
      'Trung Tâm Điều Hành Nghi Thức Tang Lễ & Hỏa Táng',
      'Theo dõi lịch nghi thức, phòng lễ và điều phối tiếp nhận.'
    ),
    AdminArea.care: (
      'Chăm Sóc Từ Xa & Ảnh Nghiệm Thu Thực Tế',
      'Duyệt công việc chăm sóc và đối chiếu ảnh trước/sau.'
    ),
    AdminArea.gps: (
      'Định Vị & Chỉ Đường Mộ Phần 50ha',
      'Tra cứu đường đi tới vị trí mộ và điểm hỗ trợ trong khuôn viên.'
    ),
    AdminArea.staff: (
      'Điều Phối & Phân Công Tổ Công Nhân Vệ Sinh',
      'Theo dõi tuyến công việc, nhân viên và tiến độ hoàn thành.'
    ),
    AdminArea.roles: (
      'Phân Quyền Vai Trò & Cài Đặt Hệ Thống',
      'Quản lý tài khoản nhân viên và quyền truy cập từng phân hệ.'
    ),
  };
  @override
  Widget build(BuildContext context) {
    if (area == AdminArea.funeral) {
      return const AdminDieuHanhTangLeScreen();
    }
    if (area == AdminArea.map) {
      return const SoDoTongQuan(viewer: SoDoViewer.banQuanLy);
    }
    if (area == AdminArea.contracts) return const HopDongAdminScreen();
    if (area == AdminArea.families) return const DanhBaThanNhanAdminScreen();
    if (area == AdminArea.memorial) return const HoSoMoQrAdminScreen();
    if (area == AdminArea.care) return const AdminDonChamSocScreen();
    if (area == AdminArea.roles) return const AdminSettingsScreen();
    final heading = _titles[area]!;
    return Container(
        color: AppColors.background,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('BÁO CÁO & TỔNG QUAN  /  SALA GARDEN',
              style: TextStyle(
                  color: Color(0xFF9B742A), fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(heading.$1,
              style: const TextStyle(
                  color: AppColors.forestDeep,
                  fontSize: 26,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(heading.$2, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          _stats(area),
          const SizedBox(height: 18),
          if (area == AdminArea.map)
            _mapGrid()
          else if (area == AdminArea.overview)
            _overview()
          else
            _moduleContent(area),
        ]));
  }

  Widget _stats(AdminArea a) {
    final labels = switch (a) {
      AdminArea.overview => [
          ('Mộ trống mở bán', '14.350', Icons.grid_view),
          ('Đã đặt cọc / trả góp', '8.200', Icons.receipt_long),
          ('Đã an táng', '12.450', Icons.local_florist),
          ('Doanh thu tháng này', '12.8 tỷ', Icons.payments)
        ],
      AdminArea.map => [
          ('Tổng kim tĩnh', '35.000', Icons.grid_view),
          ('Mộ có sẵn', '14.350', Icons.check_circle),
          ('Đã cọc / góp', '8.200', Icons.hourglass_bottom),
          ('Đã an táng', '12.450', Icons.spa)
        ],
      AdminArea.contracts => [
          ('Tổng giá trị', '420.5 tỷ', Icons.account_balance),
          ('Đã thu', '345.8 tỷ', Icons.payments),
          ('Đến hạn tháng này', '18.2 tỷ', Icons.event),
          ('Quá hạn', '14 hợp đồng', Icons.warning_amber)
        ],
      AdminArea.families => [
          ('Gia đình', '12.450', Icons.groups),
          ('Tài khoản kích hoạt', '8.900', Icons.verified_user),
          ('Thân nhân VIP', '1.200', Icons.stars),
          ('Hồ sơ chờ xác minh', '126', Icons.pending_actions)
        ],
      AdminArea.memorial => [
          ('Hồ sơ an vị', '12.450', Icons.person),
          ('Đã gắn QR', '11.890', Icons.qr_code),
          ('Chờ bổ sung', '512', Icons.pending),
          ('Lượt thăm trực tuyến', '48.230', Icons.visibility)
        ],
      AdminArea.funeral => [
          ('Đang diễn ra', '02', Icons.event),
          ('Chuẩn bị tiếp nhận', '03', Icons.schedule),
          ('Đã hoàn tất hôm nay', '05', Icons.task_alt),
          ('Công suất sử dụng', '65%', Icons.pie_chart)
        ],
      AdminArea.care => [
          ('Đơn chờ duyệt', '05', Icons.pending_actions),
          ('Đang thực hiện', '08', Icons.engineering),
          ('Chờ nghiệm thu', '12', Icons.photo_camera),
          ('Hoàn thành hôm nay', '24', Icons.check_circle)
        ],
      AdminArea.gps => [
          ('Điểm mộ có GPS', '12.450', Icons.location_on),
          ('Tuyến đang hoạt động', '08', Icons.route),
          ('Lượt dẫn đường', '156', Icons.directions),
          ('Điểm hỗ trợ', '12', Icons.support_agent)
        ],
      AdminArea.staff => [
          ('Nhân viên trực tuyến', '42/45', Icons.people),
          ('Nhiệm vụ hôm nay', '38', Icons.assignment),
          ('Đã hoàn thành', '26', Icons.task_alt),
          ('Chờ phân công', '05', Icons.pending)
        ],
      AdminArea.roles => [
          ('Tài khoản nhân viên', '52', Icons.people),
          ('Vai trò RBAC', '6', Icons.admin_panel_settings),
          ('Đang hoạt động', '48', Icons.check_circle),
          ('Đăng nhập gần đây', '12', Icons.login)
        ],
    };
    return Wrap(spacing: 12, runSpacing: 12, children: [
      for (final item in labels)
        SizedBox(
            width: 205,
            child: Card(
                color: Colors.white,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$3, color: AppColors.gold),
                          const SizedBox(height: 10),
                          Text(item.$2,
                              style: const TextStyle(
                                  fontSize: 23,
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.bold)),
                          Text(item.$1,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12))
                        ]))))
    ]);
  }

  Widget _mapGrid() => Card(
      color: Colors.white,
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('KHU M1 • VƯỜN SEN BẠCH HẠC',
                style: TextStyle(
                    color: AppColors.forest, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Wrap(spacing: 5, runSpacing: 5, children: [
              for (int row = 1; row <= 10; row++)
                for (int col = 1; col <= 14; col++)
                  Container(
                      width: 34,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _plotColor(row, col),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('$col',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)))
            ]),
            const SizedBox(height: 12),
            const Text('■ Còn trống     ■ Đã cọc / góp     ■ Đã an táng',
                style: TextStyle(color: AppColors.muted))
          ])));
  Color _plotColor(int r, int c) {
    final v = (r * 13 + c * 7) % 10;
    return v < 4
        ? AppColors.forest
        : v < 7
            ? const Color(0xFF9B742A)
            : const Color(0xFFC94343);
  }

  Widget _overview() => Column(children: [
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 1050;
          final map = _mapPreview();
          final schedule = _schedulePreview();
          return Column(children: [
            if (compact)
              Column(children: [map, const SizedBox(height: 14), schedule])
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: map),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: schedule),
              ]),
            const SizedBox(height: 16),
            _careReviewPanel(),
          ]);
        })
      ]);

  Widget _mapPreview() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HẠ TẦNG KHÔNG GIAN',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6)),
                      SizedBox(height: 5),
                      Text('Sơ Đồ Mặt Bằng Quy Hoạch 50ha',
                          style: TextStyle(
                              color: AppColors.forest,
                              fontSize: 19,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
              TextButton.icon(
                onPressed: () => onNavigate(AdminArea.map),
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Mở sơ đồ'),
              ),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 5, runSpacing: 5, children: [
              for (int i = 0; i < 60; i++)
                Container(
                  width: 28,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i % 7 == 0
                        ? const Color(0xFFC94343)
                        : i % 5 == 0
                            ? AppColors.gold
                            : AppColors.forest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${i + 1}'.padLeft(2, '0'),
                      style: const TextStyle(color: Colors.white, fontSize: 9)),
                ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.location_on, color: Color(0xFFC94343), size: 17),
                SizedBox(width: 7),
                Expanded(
                    child: Text(
                        'M1-R05-12  •  Cụ Nguyễn Văn A  •  Hướng Đông Nam',
                        style: TextStyle(fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 10),
            const Wrap(spacing: 12, runSpacing: 6, children: [
              _LegendDot(color: AppColors.forest, label: 'Trống (14.350)'),
              _LegendDot(color: AppColors.gold, label: 'Giữ chỗ / góp (8.200)'),
              _LegendDot(
                  color: Color(0xFFC94343), label: 'Đã an táng (12.450)'),
            ]),
          ]),
        ),
      );

  Widget _schedulePreview() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                  child: Text('Lịch Tang Lễ Hôm Nay',
                      style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 19,
                          fontWeight: FontWeight.w600))),
              Chip(
                  label:
                      const Text('06 sự kiện', style: TextStyle(fontSize: 10)),
                  backgroundColor: const Color(0xFFFFE3A6)),
            ]),
            const SizedBox(height: 8),
            for (final item in const [
              (
                '08:30',
                'Lễ an táng Cụ Nguyễn Thị A',
                'Khu M1 • Đang diễn ra',
                'Đang diễn ra'
              ),
              (
                '10:30',
                'Hỏa táng Lò Thủy Điện #2',
                'Thân nhân: Đại diện gia đình',
                'Chuẩn bị'
              ),
              (
                '14:00',
                'Cầu siêu & đọc kinh Vu Lan',
                'Tịnh Xá Sala • 45 thân nhân',
                'Chờ thực hiện'
              ),
              (
                '16:30',
                'Bàn giao tro cốt & nhập tháp',
                'Tháp An Lạc • Tầng 3',
                'Theo lịch'
              ),
            ])
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(9)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppColors.forest,
                              borderRadius: BorderRadius.circular(7)),
                          child: Text(item.$1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.$2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 3),
                            Text(item.$3,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(item.$4,
                                style: const TextStyle(
                                    color: AppColors.forest,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700))
                          ])),
                    ]),
              ),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: () => onNavigate(AdminArea.funeral),
                    icon: const Icon(Icons.arrow_forward, size: 15),
                    label: const Text('Xem lịch đầy đủ'))),
          ]),
        ),
      );

  Widget _careReviewPanel() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Duyệt Đơn Chăm Sóc & Nghiệm Thu Hiện Trường',
                        style: TextStyle(
                            color: AppColors.forest,
                            fontSize: 19,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(
                        'Kiểm định ảnh thực tế và cập nhật kết quả cho thân nhân.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12))
                  ])),
              FilledButton.icon(
                  onPressed: () => onNavigate(AdminArea.care),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Xem đơn cần duyệt')),
            ]),
            const SizedBox(height: 10),
            const Text(
              'Các đơn do thân nhân gửi sẽ được hiển thị tại danh sách duyệt. Mở từng đơn để kiểm tra thông tin, sau đó xác nhận bằng nút “Duyệt đơn”.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ]),
        ),
      );
  Widget _moduleContent(AdminArea a) {
    if (a == AdminArea.care) {
      return const SizedBox.shrink();
    }
    if (a == AdminArea.funeral) {
      return Column(children: [
        _panel(
            'Lịch nghi thức trong ngày',
            _rows([
              '08:00  •  Cụ Nguyễn Thị A  •  Phòng lễ VIP 1  •  Đang diễn ra',
              '10:30  •  Ông Trần Văn B  •  Lò TABO #2  •  Chuẩn bị',
              '14:00  •  Khóa lễ Vu Lan  •  Nhà tang lễ  •  Chờ thực hiện'
            ])),
        const SizedBox(height: 12),
        _catalog('Điều phối & nhân sự phục vụ', [
          'Đội xe điện đưa đón',
          'Đội khánh tiết & âm công',
          'Tổ vận hành lò TABO'
        ])
      ]);
    }
    if (a == AdminArea.gps) {
      return Column(children: [
        _panel(
            'Bản đồ tuyến đường trong khuôn viên',
            Container(
                height: 220,
                decoration: BoxDecoration(
                    color: const Color(0xFFDCEFE5),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child:
                        Icon(Icons.map, size: 90, color: AppColors.forest)))),
        const SizedBox(height: 12),
        _rows([
          'Cổng chính → Khu M1 → Mộ M1-R05-12 • 320m • khoảng 4 phút',
          'Điểm xe điện gần nhất • 150m',
          'Hướng dẫn viên trực tuyến • 3 nhân viên'
        ])
      ]);
    }
    if (a == AdminArea.roles) {
      return _panel(
          'Ma trận phân quyền (RBAC)',
          _rows([
            'Dashboard & báo cáo tổng hợp       ✓ Admin  ✓ Quản lý  ✓ Kế toán',
            'Sơ đồ mặt bằng & trạng thái mộ      ✓ Admin  ✓ Kinh doanh',
            'Hợp đồng, trả góp & hồ sơ khách hàng ✓ Admin  ✓ Kinh doanh  ✓ Kế toán',
            'Duyệt dịch vụ & ảnh nghiệm thu       ✓ Admin  ✓ Điều hành',
            'Cấu hình nhân viên & phân quyền       ✓ Admin'
          ]));
    }
    if (a == AdminArea.staff) {
      return _catalog('Tổ công nhân vệ sinh • Tuyến công việc', [
        'T1 • Trần Văn Bình • Khu M1-M3 • Tiến độ 68%',
        'T2 • Lê Văn Cường • Khu M4-M6 • Tiến độ 82%',
        'T3 • Phạm Thị Dung • Khu gia tộc VIP • Tiến độ 55%'
      ]);
    }
    if (a == AdminArea.contracts) {
      return _panel(
          'Danh sách hợp đồng điện tử & biểu thanh toán',
          _rows([
            'SG-2026-HD0812 • Nguyễn Văn B • Khu M7-GT02 • 80% đã thu',
            'SG-2026-HD0795 • Đỗ Văn Hùng • M2-R08-04 • Quá hạn 8 ngày',
            'SG-2025-HD0431 • Nguyễn Văn An • Đã thanh toán đủ'
          ]));
    }
    if (a == AdminArea.families) {
      return _panel(
          'Danh sách thân nhân • tìm theo họ tên, SĐT, mã hồ sơ',
          _rows([
            'KH-08921 • Anh Nguyễn Văn An • Gia tộc họ Nguyễn • 2 ô mộ',
            'KH-08915 • Luật sư Hoàng Minh • Gia tộc họ Hoàng • VIP',
            'KH-08840 • Bác Đỗ Văn Hùng • 1 mộ gia đình'
          ]));
    }
    return _panel(
        a == AdminArea.memorial
            ? 'Hồ sơ tưởng niệm & mã QR bia mộ'
            : 'Hoạt động gần đây',
        _rows([
          'M1-R05-12 • Cụ Nguyễn Văn A • Đã gắn mã QR • Hồ sơ đầy đủ',
          'M1-R05-13 • Bà Trần Thị B • Chờ xác minh thông tin',
          'M2-R03-08 • Ông Lê Văn C • Đã duyệt gia tộc'
        ]));
  }

  Widget _catalog(String title, List<String> items) => _panel(
      title,
      Column(children: [
        for (final item in items)
          Card(
              color: AppColors.background,
              child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: AppColors.paleBlue,
                      child: Icon(Icons.eco, color: AppColors.forest)),
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right)))
      ]));
  Widget _rows(List<String> items) => Column(children: [
        for (final item in items)
          ListTile(
              leading:
                  const Icon(Icons.circle, size: 10, color: AppColors.forest),
              title: Text(item, style: const TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, size: 18))
      ]);
  Widget _panel(String title, Widget child) => Card(
      color: Colors.white,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest)),
            const SizedBox(height: 10),
            child
          ])));
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ]);
}

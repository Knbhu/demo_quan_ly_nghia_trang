import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum _FamilyPage { directory, genealogy, ekyc, reminders }

class _FamilyRecord {
  final String code;
  final String name;
  final String initials;
  final String category;
  final String description;
  final String phone;
  final String email;
  final String location;
  final String plots;
  final bool verified;

  const _FamilyRecord({
    required this.code,
    required this.name,
    required this.initials,
    required this.category,
    required this.description,
    required this.phone,
    required this.email,
    required this.location,
    required this.plots,
    required this.verified,
  });
}

class DanhBaThanNhanAdminScreen extends StatefulWidget {
  const DanhBaThanNhanAdminScreen({super.key});

  @override
  State<DanhBaThanNhanAdminScreen> createState() =>
      _DanhBaThanNhanAdminScreenState();
}

class _DanhBaThanNhanAdminScreenState
    extends State<DanhBaThanNhanAdminScreen> {
  static const _records = <_FamilyRecord>[
    _FamilyRecord(
      code: 'KH-08921',
      name: 'Anh Nguyễn Văn An',
      initials: 'NA',
      category: 'VIP Kim Cương',
      description: 'Chủ hộ gia tộc họ Nguyễn (Nam Hà)',
      phone: '0918.xxx.421',
      email: 'nguyenvanan.invest@gmail.com',
      location: 'Quận 1, TP. Hồ Chí Minh',
      plots: '2 ô mộ • M1-R05-12, M7-GT02',
      verified: true,
    ),
    _FamilyRecord(
      code: 'KH-08915',
      name: 'Luật sư Hoàng Minh',
      initials: 'HM',
      category: 'VIP Kim Cương',
      description: 'Đại diện quản lý khu gia tộc Hoàng Tộc',
      phone: '0903.xxx.112',
      email: 'hoangminh.law@saigon.vn',
      location: 'Thành phố Thủ Đức',
      plots: '1 khu gia tộc • M7-GT02',
      verified: true,
    ),
    _FamilyRecord(
      code: 'KH-08840',
      name: 'Bác Đỗ Văn Hùng',
      initials: 'VH',
      category: 'VIP Vàng',
      description: 'Thân nhân hương khói Mộ Đôi Song Thân',
      phone: '0913.xxx.899',
      email: 'hung.do.dona@gmail.com',
      location: 'Biên Hòa, Đồng Nai',
      plots: '1 mộ đôi • M2-D08-04',
      verified: true,
    ),
    _FamilyRecord(
      code: 'KH-08732',
      name: 'Chị Phạm Mỹ Linh',
      initials: 'ML',
      category: 'Thân nhân tiêu chuẩn',
      description: 'Người thừa kế di nguyện mộ chi',
      phone: '0988.xxx.345',
      email: 'mylinh.pham@outlook.com',
      location: 'Bình Thạnh, TP. Hồ Chí Minh',
      plots: '1 mộ đơn • M4-A12-09',
      verified: true,
    ),
    _FamilyRecord(
      code: 'KH-08655',
      name: 'Trần Vũ Lâm',
      initials: 'TL',
      category: 'Chờ xác minh',
      description: 'Đại diện thân nhân • hồ sơ mới cập nhật',
      phone: '0977.xxx.122',
      email: 'lam.tran@example.vn',
      location: 'Long Thành, Đồng Nai',
      plots: 'M3-G01-04',
      verified: false,
    ),
  ];

  final _searchController = TextEditingController();
  String _filter = 'Tất cả';
  String _query = '';
  late _FamilyRecord _selected;
  _FamilyPage _page = _FamilyPage.directory;

  @override
  void initState() {
    super.initState();
    _selected = _records.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FamilyRecord> get _visibleRecords => _records.where((record) {
        final matchesFilter = switch (_filter) {
          'VIP Kim Cương' => record.category == 'VIP Kim Cương',
          'Thường xuyên viếng' => record.verified,
          'Tiềm năng' => !record.verified,
          _ => true,
        };
        final q = _query.toLowerCase().trim();
        final matchesQuery = q.isEmpty ||
            '${record.name} ${record.code} ${record.phone} ${record.email} ${record.plots}'
                .toLowerCase()
                .contains(q);
        return matchesFilter && matchesQuery;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: _page == _FamilyPage.directory
          ? _buildDirectory()
          : _buildChildPage(),
    );
  }

  Widget _buildDirectory() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _breadcrumb('SỔ BẠ THÂN NHÂN'),
          const SizedBox(height: 10),
          _directoryHeader(),
          const SizedBox(height: 16),
          _metricCards(),
          const SizedBox(height: 16),
          _searchAndFilters(),
          const SizedBox(height: 12),
          _directoryTable(),
          const SizedBox(height: 16),
          _quickTools(),
        ],
      );

  Widget _breadcrumb(String current) => Row(children: [
        const Text('BQL SALA GARDEN   ›   KINH DOANH & KHÁCH HÀNG   ›   ',
            style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        Text(current,
            style: const TextStyle(
                color: AppColors.forestDeep,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ]);

  Widget _directoryHeader() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final intro = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CƠ SỞ DỮ LIỆU THÂN NHÂN  •  ĐỒNG BỘ SALA CLOUD 2.4',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 7),
                Text('Sổ Bạ Thân Nhân & Hồ Sơ Khách Hàng',
                    style: TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 26,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 5),
                Text(
                    'Tra cứu thân nhân, thông tin liên hệ và các phần mộ đang liên kết với gia đình tại Sala Garden.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            );
            final actions = Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                  onPressed: () => _showNotice('Đã chuẩn bị danh bạ để xuất.'),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Xuất danh bạ')),
              FilledButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Thêm hồ sơ')),
            ]);
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [intro, const SizedBox(height: 14), actions])
                : Row(children: [
                    Expanded(child: intro),
                    const SizedBox(width: 14),
                    actions,
                  ]);
          }),
        ),
      );

  Widget _metricCards() {
    final metrics = [
      ('Tổng khách hàng thân nhân', '12.450', 'gia đình', Icons.groups_2_outlined,
          '+185 khách mới ký hợp đồng trong tháng'),
      ('Tài khoản đã kích hoạt', '8.900', '71,5%', Icons.verified_user_outlined,
          'Liên kết OTP, Zalo và CCCD chip'),
      ('Khách hàng thân thiết VIP', '1.200', 'hội viên', Icons.workspace_premium_outlined,
          'Hạng Kim Cương & Bạch Kim'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 1050
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in metrics)
            SizedBox(
              width: width,
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(item.$1.toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700))),
                        Icon(item.$4, color: AppColors.forest, size: 22),
                      ]),
                      const SizedBox(height: 9),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(item.$2,
                            style: const TextStyle(
                                color: AppColors.forestDeep,
                                fontSize: 29,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 7),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(item.$3,
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(7)),
                        child: Text(item.$5,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _searchAndFilters() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            LayoutBuilder(builder: (context, constraints) {
              final search = SizedBox(
                width: constraints.maxWidth > 800 ? 330 : double.infinity,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Tìm họ tên, SĐT, mã hồ sơ, mã mộ…',
                    filled: true,
                    fillColor: AppColors.background,
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              );
              final chips = Wrap(spacing: 6, runSpacing: 6, children: [
                for (final filter in const [
                  'Tất cả',
                  'VIP Kim Cương',
                  'Thường xuyên viếng',
                  'Tiềm năng'
                ])
                  ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    selectedColor: AppColors.forest,
                    labelStyle: TextStyle(
                        color: _filter == filter ? Colors.white : AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    backgroundColor: AppColors.paleBlue,
                    visualDensity: VisualDensity.compact,
                  ),
              ]);
              return constraints.maxWidth > 800
                  ? Row(children: [search, const SizedBox(width: 10), Expanded(child: chips)])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      search,
                      const SizedBox(height: 10),
                      chips,
                    ]);
            }),
            const Divider(height: 20),
            Row(children: [
              Expanded(
                  child: Text(
                      'ĐANG HIỂN THỊ  ${_visibleRecords.length} / ${_records.length} hồ sơ mẫu  •  Khuôn viên: Tất cả phân khu M1–M11',
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600))),
              TextButton.icon(
                  onPressed: () => setState(() {
                        _filter = 'Tất cả';
                        _query = '';
                        _searchController.clear();
                      }),
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Đặt lại')),
            ]),
          ]),
        ),
      );

  Widget _directoryTable() => Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            color: AppColors.paleBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: const Row(children: [
              Expanded(flex: 2, child: _TableLabel('MÃ KH & NGÀY TẠO')),
              Expanded(flex: 4, child: _TableLabel('HỌ & TÊN THÂN NHÂN')),
              Expanded(flex: 3, child: _TableLabel('CCCD / EKYC')),
              Expanded(flex: 3, child: _TableLabel('LIÊN HỆ')),
              Expanded(flex: 2, child: _TableLabel('MỘ PHẦN SỞ HỮU')),
              SizedBox(width: 34),
            ]),
          ),
          if (_visibleRecords.isEmpty)
            const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy hồ sơ phù hợp.'))
          else
            for (final record in _visibleRecords)
              InkWell(
                onTap: () => setState(() => _selected = record),
                child: Container(
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.paleBlue))),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(children: [
                    Expanded(
                        flex: 2,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(record.code,
                              style: const TextStyle(
                                  color: AppColors.forestDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('18/02/2023', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                        ])),
                    Expanded(
                        flex: 4,
                        child: Row(children: [
                          CircleAvatar(
                              radius: 18,
                              backgroundColor: record.verified ? AppColors.forest : AppColors.gold,
                              child: Text(record.initials,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 9),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(record.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 3),
                            Text(record.category, style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                            Text(record.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                          ])),
                        ])),
                    Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(record.verified ? '●  eKYC chip hợp lệ' : '●  Chờ xác minh',
                              style: TextStyle(color: record.verified ? AppColors.forest : Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('CCCD ••••••••', style: TextStyle(fontSize: 11)),
                        ])),
                    Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(record.phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(record.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        ])),
                    Expanded(
                        flex: 2,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(record.plots, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.forestDeep, fontSize: 10, fontWeight: FontWeight.w600)),
                          Text(record.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
                        ])),
                    IconButton(
                        tooltip: 'Mở hồ sơ thân nhân',
                        onPressed: () => _showContactDetails(record),
                        icon: const Icon(Icons.chevron_right, color: AppColors.forest)),
                  ]),
                ),
              ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              const Expanded(child: Text('Hiển thị dữ liệu minh họa • Kết nối API/SQL ở bước tích hợp dữ liệu.', style: TextStyle(color: AppColors.muted, fontSize: 10))),
              TextButton(onPressed: () {}, child: const Text('‹   1   2   3   ›')),
            ]),
          ),
        ]),
      );

  Widget _quickTools() => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 560 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: width, child: _toolCard(
              'Cây phả hệ gia tộc', 'Quản lý thế hệ, người đại diện và phân vị kim tĩnh.',
              Icons.account_tree_outlined, AppColors.forest, _FamilyPage.genealogy)),
          SizedBox(width: width, child: _toolCard(
              'Kiểm tra định danh eKYC', 'Đối soát CCCD, VNeID và hồ sơ pháp lý thân nhân.',
              Icons.fact_check_outlined, AppColors.gold, _FamilyPage.ekyc)),
          SizedBox(width: width, child: _toolCard(
              'Nhắc giỗ & thư ngỏ tự động', 'Cấu hình lịch âm, nội dung và kênh gửi thông báo.',
              Icons.event_repeat_outlined, AppColors.forest, _FamilyPage.reminders)),
        ]);
      });

  Widget _toolCard(String title, String description, IconData icon, Color color,
          _FamilyPage destination) =>
      Card(
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
              backgroundColor: AppColors.paleBlue,
              child: Icon(icon, color: color)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(description, style: const TextStyle(fontSize: 11, color: AppColors.muted))),
          trailing: const Icon(Icons.arrow_forward, color: AppColors.forest),
          onTap: () => setState(() => _page = destination),
        ),
      );

  Widget _buildChildPage() {
    final config = switch (_page) {
      _FamilyPage.genealogy => (
          'Trung Tâm Quản Lý Phả Hệ & Quyền Thừa Kế',
          'Gia tộc họ Nguyễn • Khu đại tộc M7 • Hợp đồng SG-HD/2021-089',
          Icons.account_tree_outlined
        ),
      _FamilyPage.ekyc => (
          'Kiểm Tra Báo Cáo Định Danh eKYC & VNeID',
          'Theo dõi trạng thái xác minh CCCD và đối soát hồ sơ thân nhân.',
          Icons.verified_user_outlined
        ),
      _FamilyPage.reminders => (
          'Hệ Thống Lịch Âm & Nhắc Ngày Giỗ Tự Động',
          'Quản lý quy tắc nhắc giỗ, lịch gửi và mẫu tin cho thân nhân.',
          Icons.event_repeat_outlined
        ),
      _ => ('Sổ Bạ Thân Nhân', '', Icons.groups_outlined),
    };
    return ListView(padding: const EdgeInsets.all(20), children: [
      _breadcrumb('SỔ BẠ THÂN NHÂN  ›  ${config.$1.toUpperCase()}'),
      const SizedBox(height: 10),
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    tooltip: 'Quay lại danh bạ',
                    onPressed: () => setState(() => _page = _FamilyPage.directory),
                    icon: const Icon(Icons.arrow_back, color: AppColors.forest)),
                const SizedBox(width: 5),
                Icon(config.$3, color: AppColors.gold),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(config.$1, style: const TextStyle(color: AppColors.forestDeep, fontSize: 23, fontWeight: FontWeight.w700)),
                    Text(config.$2, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
              ]),
              OutlinedButton.icon(
                  onPressed: () => setState(() => _page = _FamilyPage.directory),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Danh bạ thân nhân')),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_page == _FamilyPage.genealogy) _genealogyPage(),
      if (_page == _FamilyPage.ekyc) _ekycPage(),
      if (_page == _FamilyPage.reminders) _remindersPage(),
    ]);
  }

  Widget _genealogyPage() => LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final tree = _whitePanel('Cây phả hệ • Gia tộc họ Nguyễn', Column(children: [
          _generationNode('ĐỜI 1 • TIỀN BỐI KHỞI TỔ', 'Cụ Ông Nguyễn Văn Phúc  •  Cụ Bà Lê Thị Mùi', 'Đã an nghỉ'),
          const Icon(Icons.south, color: AppColors.muted),
          _generationNode('ĐỜI 2 • THẾ HỆ PHỤ THÂN', 'Nguyễn Văn Hùng  •  Trưởng tộc đời 2', 'Đã an táng'),
          const Icon(Icons.south, color: AppColors.muted),
          _generationNode('ĐỜI 3 • ĐẠI DIỆN THỪA KẾ', 'Nguyễn Văn An  •  Người đại diện pháp lý', 'Đang sinh sống'),
          const SizedBox(height: 14),
          const Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text('14 thành viên')),
            Chip(label: Text('6/14 kim tĩnh đã sử dụng')),
            Chip(label: Text('2 vị trí dự phòng')),
          ]),
        ]));
        final legal = _whitePanel('Hồ sơ pháp lý & quyền hạn', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detailLine('Đại diện gia tộc', 'Nguyễn Văn An'),
          _detailLine('Hồ sơ hợp đồng', 'SG-2024/M7-02'),
          _detailLine('Quyền sử dụng', 'Vĩnh viễn'),
          const Divider(),
          const Text('Quyền hạn được giao', style: TextStyle(fontWeight: FontWeight.w700)),
          for (final text in ['Đăng ký dịch vụ chăm sóc định kỳ', 'Quản lý thông tin thành viên gia tộc', 'Thực hiện thủ tục thừa kế theo hồ sơ công chứng'])
            CheckboxListTile(value: true, onChanged: null, dense: true, contentPadding: EdgeInsets.zero, title: Text(text, style: const TextStyle(fontSize: 12))),
          FilledButton.icon(onPressed: () => _showNotice('Mở biểu mẫu thêm thành viên gia tộc.'), icon: const Icon(Icons.person_add_alt), label: const Text('Thêm thành viên / thế hệ')),
        ]));
        return compact ? Column(children: [tree, const SizedBox(height: 12), legal]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: tree), const SizedBox(width: 12), Expanded(flex: 2, child: legal)]);
      });

  Widget _generationNode(String generation, String people, String status) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: status == 'Đang sinh sống' ? AppColors.paleBlue : AppColors.forestDeep,
            borderRadius: BorderRadius.circular(9)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(generation, style: TextStyle(color: status == 'Đang sinh sống' ? AppColors.gold : const Color(0xFFBFEEDC), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(people, style: TextStyle(color: status == 'Đang sinh sống' ? AppColors.forestDeep : Colors.white, fontWeight: FontWeight.w700)),
          Text(status, style: TextStyle(color: status == 'Đang sinh sống' ? AppColors.muted : const Color(0xFFBFEEDC), fontSize: 11)),
        ]),
      );

  Widget _ekycPage() => Column(children: [
        _metricCards(),
        const SizedBox(height: 12),
        _whitePanel('Danh sách báo cáo thẩm định eKYC chi tiết', Column(children: [
          for (final record in _records)
            ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.paleBlue, child: Text(record.initials, style: const TextStyle(color: AppColors.forest))),
              title: Text(record.name),
              subtitle: Text('${record.code}  •  CCCD ••••••••  •  ${record.plots}'),
              trailing: Chip(
                label: Text(record.verified ? 'Hợp lệ' : 'Chờ bổ sung'),
                backgroundColor: record.verified ? const Color(0xFFDDF3E9) : const Color(0xFFFFE3A6),
              ),
              onTap: () => setState(() => _selected = record),
            ),
        ])),
        const SizedBox(height: 12),
        _whitePanel('Quy trình xác minh', const Text('Kiểm tra giấy tờ tùy thân, đối soát thông tin người đại diện và lưu vết thay đổi hồ sơ. Dữ liệu hiện đang là mẫu giao diện; thao tác xác minh cần kết nối API nghiệp vụ.', style: TextStyle(color: AppColors.muted, height: 1.5))),
      ]);

  Widget _remindersPage() => Column(children: [
        _metricCards(),
        const SizedBox(height: 12),
        _whitePanel('Khu vực thiết lập quy tắc kích hoạt', Column(children: [
          _reminderRule('Nhắc trước 15 ngày', 'Gửi lời nhắc chuẩn bị hoa và dịch vụ trước ngày giỗ.', true),
          _reminderRule('Nhắc trước 7 ngày', 'Thông báo thân nhân kiểm tra lịch và thông tin nghi lễ.', true),
          _reminderRule('Nhắc trước 1 ngày', 'Gửi thông báo xác nhận lần cuối qua kênh đã đăng ký.', true),
          _reminderRule('Ngày giỗ chính', 'Gửi lời tưởng niệm theo mẫu đã được gia đình chấp thuận.', false),
        ])),
        const SizedBox(height: 12),
        _whitePanel('Lịch giỗ sắp tới', Column(children: [
          for (final row in const [
            ('12/10 âm lịch', 'Cụ Cửu Văn Bình', 'M1-A04-12', 'Zalo ZNS'),
            ('13/10 âm lịch', 'Phật Thị Nguyên Thị Huệ', 'M3-C02-08', 'SMS'),
            ('14/10 âm lịch', 'Ông Trần Minh Quân', 'M5-VIP-03', 'Zalo ZNS'),
          ])
            ListTile(leading: const Icon(Icons.event, color: AppColors.gold), title: Text(row.$2), subtitle: Text('${row.$1}  •  ${row.$3}'), trailing: Text(row.$4, style: const TextStyle(color: AppColors.forest, fontSize: 11))),
        ])),
      ]);

  Widget _reminderRule(String title, String detail, bool initialValue) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: initialValue,
        activeThumbColor: AppColors.forest,
        onChanged: (value) => _showNotice('$title: ${value ? 'đã bật' : 'đã tắt'} trong bản xem thử.'),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      );

  Widget _whitePanel(String title, Widget child) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppColors.forestDeep, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12))), Text(value, style: const TextStyle(color: AppColors.forestDeep, fontWeight: FontWeight.w700, fontSize: 12))]),
      );

  void _showContactDetails(_FamilyRecord record) {
    setState(() => _selected = record);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.name),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${record.code}  •  ${record.category}'),
          const SizedBox(height: 10),
          Text('Điện thoại: ${record.phone}'),
          Text('Email: ${record.email}'),
          Text('Địa chỉ: ${record.location}'),
          Text('Mộ phần: ${record.plots}'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          FilledButton.icon(onPressed: () { Navigator.pop(context); setState(() => _page = _FamilyPage.genealogy); }, icon: const Icon(Icons.account_tree), label: const Text('Mở phả hệ')),
        ],
      ),
    );
  }

  void _addContact() => showDialog<void>(
        context: context,
        builder: (context) {
          final nameController = TextEditingController();
          final phoneController = TextEditingController();
          return AlertDialog(
            title: const Text('Thêm hồ sơ thân nhân'),
            content: SizedBox(
              width: 420,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại'), keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                const Text('Biểu mẫu giao diện; cần kết nối API để lưu hồ sơ.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              FilledButton(onPressed: () { Navigator.pop(context); _showNotice('Đã nhận thông tin ${nameController.text.isEmpty ? 'thân nhân mới' : nameController.text} trong bản xem thử.'); }, child: const Text('Tiếp tục')),
            ],
          );
        },
      );

  void _showNotice(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _TableLabel extends StatelessWidget {
  final String text;
  const _TableLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.forestDeep, fontSize: 9, fontWeight: FontWeight.w700));
}

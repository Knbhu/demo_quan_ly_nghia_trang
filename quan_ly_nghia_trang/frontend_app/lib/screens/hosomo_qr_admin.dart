import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum _QrPage { directory, registration, editor, preview }

class _MemorialRecord {
  String code;
  String name;
  String alias;
  String plot;
  String family;
  String dates;
  String qrCode;
  String status;
  bool isPublic;
  bool guestbookEnabled;
  bool incenseEnabled;
  int relatives;

  _MemorialRecord({
    required this.code,
    required this.name,
    required this.alias,
    required this.plot,
    required this.family,
    required this.dates,
    required this.qrCode,
    required this.status,
    this.isPublic = true,
    this.guestbookEnabled = true,
    this.incenseEnabled = true,
    this.relatives = 1,
  });
}

class HoSoMoQrAdminScreen extends StatefulWidget {
  const HoSoMoQrAdminScreen({super.key});

  @override
  State<HoSoMoQrAdminScreen> createState() => _HoSoMoQrAdminScreenState();
}

class _HoSoMoQrAdminScreenState extends State<HoSoMoQrAdminScreen> {
  final _records = <_MemorialRecord>[
    _MemorialRecord(
      code: 'HS-2024-0512',
      name: 'Cụ Ông Nguyễn Văn An',
      alias: 'Nhuận Từ',
      plot: 'M1-R05-12',
      family: 'Nguyễn Văn An (Trưởng nam)',
      dates: '1940 – 2022  •  Hưởng thọ 83 tuổi',
      qrCode: 'QR-M1-0512-SALA',
      status: 'Đã gắn bia đồng',
      relatives: 3,
    ),
    _MemorialRecord(
      code: 'HS-2024-0513',
      name: 'Cụ Bà Trần Thị Mai',
      alias: 'Diệu Tâm',
      plot: 'M1-R05-13',
      family: 'Nguyễn Văn An (Trưởng nam)',
      dates: '1945 – 2021  •  Hưởng thọ 77 tuổi',
      qrCode: 'QR-M1-0513-SALA',
      status: 'Đã gắn bia đồng',
      relatives: 4,
    ),
    _MemorialRecord(
      code: 'HS-2023-0308',
      name: 'Ông Giuse Lê Văn Cường',
      alias: 'Giuse',
      plot: 'M2-R03-08',
      family: 'Lê Thị Thanh Hương (Trưởng nữ)',
      dates: '1955 – 2023  •  Hưởng thọ 69 tuổi',
      qrCode: 'QR-M2-0308-SALA',
      status: 'Đã gắn bia đồng',
      relatives: 2,
    ),
    _MemorialRecord(
      code: 'HS-2025-0892',
      name: 'Cụ Ông Hoàng Văn Đức',
      alias: 'Hoàng Tộc',
      plot: 'M7-GT02-01',
      family: 'Hoàng Trọng Nghĩa (Cháu đích tôn)',
      dates: '1932 – 2020  •  Đã an táng',
      qrCode: 'QR-M7-GT02-01',
      status: 'Chờ duyệt hồ sơ',
      isPublic: false,
      relatives: 5,
    ),
    _MemorialRecord(
      code: 'HS-2025-0901',
      name: 'Bà Maria Vũ Thị Lan',
      alias: 'Maria',
      plot: 'M4-CG03-08',
      family: 'Phạm Đức Toàn (Chồng)',
      dates: '1960 – 2024  •  Hưởng thọ 65 tuổi',
      qrCode: 'QR-M4-CG03-08',
      status: 'Bản nháp',
      isPublic: false,
      relatives: 2,
    ),
    _MemorialRecord(
      code: 'HS-2024-0702',
      name: 'Cụ Bà Đặng Thị Nga',
      alias: 'Tịnh Quang',
      plot: 'M3-R07-02',
      family: 'Vũ Hoàng Minh (Con rể)',
      dates: '1938 – 2024  •  Hưởng thọ 86 tuổi',
      qrCode: 'QR-M3-R07-02',
      status: 'Đã duyệt, chờ gắn QR',
      relatives: 3,
    ),
  ];

  final _search = TextEditingController();
  String _query = '';
  String _filter = 'Tất cả';
  _QrPage _page = _QrPage.directory;
  _MemorialRecord? _active;
  int _wizardStep = 0;
  int _pendingCondolences = 3;
  bool _newIsPublic = true;
  bool _newGuestbookEnabled = true;
  bool _newIncenseEnabled = true;
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _graveController = TextEditingController();
  final _familyController = TextEditingController();
  final _relativeController = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _nameController.dispose();
    _aliasController.dispose();
    _graveController.dispose();
    _familyController.dispose();
    _relativeController.dispose();
    super.dispose();
  }

  List<_MemorialRecord> get _visibleRecords => _records.where((record) {
        final query = _query.toLowerCase().trim();
        final searchMatches = query.isEmpty ||
            '${record.name} ${record.alias} ${record.plot} ${record.family} ${record.qrCode}'
                .toLowerCase()
                .contains(query);
        final filterMatches = switch (_filter) {
          'QR hoạt động' => record.status == 'Đã gắn bia đồng',
          'Chờ duyệt' => record.status.contains('Chờ duyệt'),
          'Bản nháp' => record.status == 'Bản nháp',
          _ => true,
        };
        return searchMatches && filterMatches;
      }).toList();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.background,
        child: switch (_page) {
          _QrPage.directory => _directoryPage(),
          _QrPage.registration => _registrationPage(),
          _QrPage.editor => _editorPage(),
          _QrPage.preview => _memorialPreview(),
        },
      );

  Widget _directoryPage() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _crumb('HỒ SƠ TƯỞNG NIỆM & MÃ QR BIA MỘ'),
          const SizedBox(height: 10),
          _directoryHeader(),
          const SizedBox(height: 14),
          _stats(),
          const SizedBox(height: 14),
          _filters(),
          const SizedBox(height: 12),
          _recordGrid(),
          const SizedBox(height: 14),
          _moderationPanel(),
          const SizedBox(height: 14),
          _publicInfoPanel(),
        ],
      );

  Widget _crumb(String label) => Row(children: [
        const Text('BQL SALA GARDEN   ›   KINH DOANH & KHÁCH HÀNG   ›   ',
            style: TextStyle(color: AppColors.muted, fontSize: 10)),
        Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.forestDeep,
                    fontSize: 10,
                    fontWeight: FontWeight.w700))),
      ]);

  Widget _directoryHeader() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(builder: (context, constraints) {
            final actions = Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                  onPressed: () => _notify('Đã chuẩn bị danh sách mã QR để in.'),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('In QR hàng loạt')),
              FilledButton.icon(
                  onPressed: _startRegistration,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Đăng ký hồ sơ mới')),
            ]);
            final intro = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BIA ĐÁ ĐỒNG BỘ • LƯU GIỮ KÝ ỨC VĨNH HẰNG',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Danh Bạ Người Quá Cố & Quản Lý Mã QR Bia Mộ',
                    style: TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 25,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 5),
                Text(
                    'Quản lý hồ sơ an táng, vị trí mộ, thân nhân và trang tưởng niệm trực tuyến tại Sala Garden.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            );
            return constraints.maxWidth < 800
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    intro,
                    const SizedBox(height: 14),
                    actions,
                  ])
                : Row(children: [Expanded(child: intro), const SizedBox(width: 14), actions]);
          }),
        ),
      );

  Widget _stats() {
    final active = _records.where((r) => r.status == 'Đã gắn bia đồng').length;
    final waiting = _records.where((r) => r.status.contains('Chờ duyệt')).length;
    final drafts = _records.where((r) => r.status == 'Bản nháp').length;
    final items = [
      ('Tổng hồ sơ an vị', '${_records.length}', 'Hồ sơ trong danh bạ', Icons.person_search_outlined, AppColors.forest),
      ('QR đã gắn bia', '$active', 'Mã đang hoạt động', Icons.qr_code_2, AppColors.forest),
      ('Chờ duyệt / gắn QR', '$waiting', 'Cần xử lý', Icons.pending_actions, AppColors.gold),
      ('Lời viếng cần kiểm duyệt', '$_pendingCondolences', 'Hàng chờ công khai', Icons.rate_review_outlined, const Color(0xFFB53B31)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 950 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final item in items)
          SizedBox(
            width: width,
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item.$1.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700))),
                    Icon(item.$4, color: item.$5, size: 21),
                  ]),
                  const SizedBox(height: 7),
                  Text(item.$2, style: TextStyle(color: item.$5, fontSize: 27, fontWeight: FontWeight.w700)),
                  Text(item.$3, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }

  Widget _filters() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(children: [
            LayoutBuilder(builder: (context, constraints) {
              final search = TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm người quá cố, pháp danh, thân nhân, mã mộ hoặc QR…',
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              );
              final filters = Wrap(spacing: 6, runSpacing: 6, children: [
                for (final value in const ['Tất cả', 'QR hoạt động', 'Chờ duyệt', 'Bản nháp'])
                  ChoiceChip(
                    label: Text(value),
                    selected: _filter == value,
                    onSelected: (_) => setState(() => _filter = value),
                    selectedColor: AppColors.forest,
                    backgroundColor: AppColors.paleBlue,
                    labelStyle: TextStyle(color: _filter == value ? Colors.white : AppColors.text, fontSize: 10, fontWeight: FontWeight.w600),
                    visualDensity: VisualDensity.compact,
                  ),
              ]);
              return constraints.maxWidth > 800
                  ? Row(children: [SizedBox(width: 350, child: search), const SizedBox(width: 10), Expanded(child: filters)])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [search, const SizedBox(height: 8), filters]);
            }),
            const Divider(height: 18),
            Row(children: [
              Expanded(child: Text('Hiển thị ${_visibleRecords.length} / ${_records.length} hồ sơ  •  Dữ liệu mẫu để xem giao diện', style: const TextStyle(color: AppColors.muted, fontSize: 10))),
              TextButton.icon(onPressed: () => setState(() { _query = ''; _filter = 'Tất cả'; _search.clear(); }), icon: const Icon(Icons.refresh, size: 15), label: const Text('Đặt lại')),
            ]),
          ]),
        ),
      );

  Widget _recordGrid() => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 1050 ? 3 : constraints.maxWidth > 650 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        if (_visibleRecords.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Không có hồ sơ phù hợp với bộ lọc.'))));
        }
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final record in _visibleRecords)
            SizedBox(width: width, child: _recordCard(record)),
        ]);
      });

  Widget _recordCard(_MemorialRecord record) {
    final active = record.status == 'Đã gắn bia đồng';
    final pending = record.status.contains('Chờ');
    final statusColor = active ? AppColors.forest : pending ? AppColors.gold : AppColors.muted;
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 3, color: statusColor),
        Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _smallTag(record.plot, AppColors.paleBlue, AppColors.forestDeep)),
              const SizedBox(width: 5),
              Flexible(child: _smallTag(record.status, active ? const Color(0xFFDDF3E9) : const Color(0xFFFFE9C1), statusColor)),
            ]),
            const SizedBox(height: 11),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 66,
                height: 78,
                decoration: BoxDecoration(color: AppColors.paleBlue, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.portrait, size: 38, color: AppColors.forest),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(record.alias.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(record.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.forestDeep, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(record.dates, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                const SizedBox(height: 5),
                Text('${record.relatives} thân nhân liên kết', style: const TextStyle(color: AppColors.forest, fontSize: 10, fontWeight: FontWeight.w600)),
              ])),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(7)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _pair('Phân khu', record.plot.split('-').first),
                _pair('Thân nhân đại diện', record.family),
              ]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: AppColors.paleBlue, borderRadius: BorderRadius.circular(7)),
              child: Row(children: [
                const _QrMark(size: 42),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MÃ QR TƯỞNG NIỆM', style: TextStyle(color: AppColors.muted, fontSize: 8, fontWeight: FontWeight.w700)),
                  Text(record.qrCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.forestDeep, fontSize: 10, fontWeight: FontWeight.w700)),
                  Text(record.isPublic ? 'Trang công khai' : 'Đang ẩn trang', style: TextStyle(color: record.isPublic ? AppColors.forest : AppColors.gold, fontSize: 9)),
                ])),
                IconButton(tooltip: 'Sao chép mã', onPressed: () => _notify('Đã sao chép mã ${record.qrCode}.'), icon: const Icon(Icons.copy, size: 16)),
              ]),
            ),
          ]),
        ),
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Wrap(alignment: WrapAlignment.spaceAround, children: [
            TextButton.icon(onPressed: () => _openEditor(record), icon: const Icon(Icons.edit_outlined, size: 14), label: const Text('Sửa', style: TextStyle(fontSize: 10))),
            TextButton.icon(onPressed: () => _notify('Đã đưa ${record.qrCode} vào hàng đợi in.'), icon: const Icon(Icons.print_outlined, size: 14), label: const Text('In QR', style: TextStyle(fontSize: 10))),
            TextButton.icon(onPressed: () { setState(() { _active = record; _page = _QrPage.preview; }); }, icon: const Icon(Icons.open_in_new, size: 14), label: const Text('Xem online', style: TextStyle(fontSize: 10))),
          ]),
        ),
      ]),
    );
  }

  Widget _moderationPanel() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.rate_review_outlined, color: AppColors.gold),
              const SizedBox(width: 8),
              const Expanded(child: Text('Lời kính viếng chờ kiểm duyệt', style: TextStyle(color: AppColors.forestDeep, fontSize: 16, fontWeight: FontWeight.w700))),
              _smallTag('$_pendingCondolences chờ', const Color(0xFFFFE9C1), AppColors.gold),
            ]),
            const SizedBox(height: 8),
            const Text('Nội dung chỉ hiển thị trên trang tưởng niệm sau khi được quản trị viên duyệt.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 10),
            for (final message in const [
              ('Nguyễn Văn Bình', 'Kính nhớ ông, mong ông an nghỉ nơi miền an lạc.', 'HS-2024-0512'),
              ('Trần Thị My', 'Gia đình xin gửi lời tri ân và tưởng niệm.', 'HS-2024-0513'),
              ('Lê Hoàng Minh', 'Thành kính phân ưu cùng toàn thể gia quyến.', 'HS-2023-0308'),
            ].take(_pendingCondolences))
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: LayoutBuilder(builder: (context, constraints) {
                  final buttons = Wrap(spacing: 6, children: [
                    OutlinedButton(onPressed: () => setState(() => _pendingCondolences = (_pendingCondolences - 1).clamp(0, 99).toInt()), child: const Text('Từ chối')),
                    FilledButton.icon(onPressed: () => setState(() => _pendingCondolences = (_pendingCondolences - 1).clamp(0, 99).toInt()), icon: const Icon(Icons.check, size: 15), label: const Text('Duyệt')),
                  ]);
                  final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${message.$1}  •  ${message.$3}', style: const TextStyle(color: AppColors.forestDeep, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('“${message.$2}”', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ]);
                  return constraints.maxWidth > 600
                      ? Row(children: [Expanded(child: details), buttons])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [details, const SizedBox(height: 8), buttons]);
                }),
              ),
          ]),
        ),
      );

  Widget _publicInfoPanel() => Card(
        color: AppColors.forestDeep,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Wrap(spacing: 20, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: const [
            Icon(Icons.lock_outline, color: Color(0xFFFFDEA5), size: 24),
            SizedBox(width: 300, child: Text('Bảo vệ thông tin gia đình', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            SizedBox(width: 640, child: Text('Trang tưởng niệm công khai chỉ chứa nội dung được gia đình cho phép. CCCD, điện thoại, giấy tờ pháp lý và dữ liệu riêng tư không hiển thị cho khách viếng.', style: TextStyle(color: Color(0xFFD2E8DD), fontSize: 11))),
          ]),
        ),
      );

  Widget _registrationPage() {
    const steps = ['Hương linh & danh xưng', 'Kim tĩnh & hợp đồng', 'Thân nhân & đại diện', 'Bia mộ & QR'];
    return ListView(padding: const EdgeInsets.all(20), children: [
      _subHeader('Kê Khai Hồ Sơ An Táng & Cấp Mã QR Bia Mộ', 'Bản nháp sẽ được lưu nội bộ; hồ sơ cần được duyệt trước khi QR hoạt động.', Icons.assignment_add),
      const SizedBox(height: 12),
      Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < steps.length; i++) _stepChip(i + 1, steps[i], _wizardStep == i)]))),
      const SizedBox(height: 12),
      if (_wizardStep == 0) _formSectionFields('Định danh hương linh & danh xưng', Icons.person_outline, [
        _input('Họ và tên khai sinh *', _nameController, hint: 'Ví dụ: Nguyễn Văn Thành'),
        _input('Pháp danh / tên thánh', _aliasController, hint: 'Nếu có'),
        _input('Ngày sinh', null, hint: 'dd/mm/yyyy'),
        _input('Ngày mất', null, hint: 'dd/mm/yyyy'),
        _input('Quê quán', null, hint: 'Xã, huyện, tỉnh'),
        _input('Tiểu sử ngắn', null, lines: 3),
      ]),
      if (_wizardStep == 1) _formSectionFields('Vị trí kim tĩnh & hợp đồng', Icons.place_outlined, [
        _input('Mã vị trí mộ *', _graveController, hint: 'Ví dụ: M1-R05-12'),
        _input('Mã hợp đồng', null, hint: 'Tra cứu hợp đồng đã xác thực'),
        _input('Phân khu / loại mộ', null, hint: 'Chọn từ sơ đồ mặt bằng'),
        _input('Hướng mộ / ghi chú vị trí', null),
        const _InfoBanner('Chỉ chọn vị trí trống hoặc vị trí đã được liên kết hợp đồng. Kiểm tra trùng hồ sơ trước khi tiếp tục.'),
      ]),
      if (_wizardStep == 2) _formSectionFields('Thân nhân bảo trợ & đại diện', Icons.groups_outlined, [
        _input('Người đại diện gia quyến *', _familyController, hint: 'Tìm trong Sổ bạ thân nhân'),
        _input('Thân nhân liên kết', _relativeController, hint: 'Tìm và thêm nhiều thân nhân'),
        _input('Mối quan hệ với hương linh', null, hint: 'Trưởng nam, cháu, người giám hộ…'),
        const _InfoBanner('Một hồ sơ có thể có nhiều thân nhân quản lý. Mỗi người chỉ được xem hoặc chỉnh sửa theo quyền được cấp.'),
      ]),
      if (_wizardStep == 3) _qrSettingsForm(),
      const SizedBox(height: 12),
      _bottomActions(
        left: TextButton.icon(onPressed: _backToDirectory, icon: const Icon(Icons.close), label: const Text('Hủy')),
        middle: OutlinedButton.icon(onPressed: _saveDraft, icon: const Icon(Icons.save_outlined), label: const Text('Lưu bản nháp')),
        right: FilledButton.icon(
          onPressed: _wizardStep < 3 ? () => setState(() => _wizardStep++) : _submitNewRecord,
          icon: Icon(_wizardStep < 3 ? Icons.arrow_forward : Icons.send_outlined),
          label: Text(_wizardStep < 3 ? 'Tiếp tục' : 'Gửi duyệt hồ sơ'),
        ),
      ),
    ]);
  }

  Widget _qrSettingsForm() => Column(children: [
        _formSectionFields('Cấu hình bia mộ & cấp mã QR', Icons.qr_code_2, [
          _input('Loại bia / vật liệu', null, hint: 'Granite Kim Sa Đen / đồng khắc'),
          _input('Mã QR dự kiến', null, hint: 'Tự sinh sau khi lưu hồ sơ'),
          const _InfoBanner('QR là mã định danh ngẫu nhiên, không chứa CCCD hay thông tin nhạy cảm. Mã chính thức chỉ kích hoạt sau khi hồ sơ được duyệt.'),
        ]),
        const SizedBox(height: 10),
        _formSectionFields('Quyền riêng tư trang tưởng niệm', Icons.privacy_tip_outlined, [
          SwitchListTile(value: _newIsPublic, onChanged: (v) => setState(() => _newIsPublic = v), title: const Text('Cho phép khách viếng xem trang công khai')),
          SwitchListTile(value: _newGuestbookEnabled, onChanged: (v) => setState(() => _newGuestbookEnabled = v), title: const Text('Cho phép gửi lời kính viếng (kiểm duyệt trước khi đăng)')),
          SwitchListTile(value: _newIncenseEnabled, onChanged: (v) => setState(() => _newIncenseEnabled = v), title: const Text('Cho phép thắp hương / dâng hoa trực tuyến')),
          const _InfoBanner('Thông tin giấy tờ, số điện thoại và địa chỉ thân nhân luôn riêng tư.'),
        ]),
      ]);

  Widget _editorPage() {
    final record = _active!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      _subHeader('Chỉnh Sửa Hồ Sơ Tưởng Niệm', '${record.name}  •  ${record.plot}', Icons.edit_note),
      const SizedBox(height: 12),
      _formSectionFields('Thông tin hương linh & tâm linh', Icons.person_outline, [
        _input('Họ và tên khai sinh', _nameController),
        _input('Pháp danh / tên thánh', _aliasController),
        _input('Ngày sinh và ngày mất', null, hint: record.dates),
        _input('Tiểu sử / gia huấn', null, lines: 4, hint: 'Nội dung hiển thị trên trang tưởng niệm'),
      ]),
      const SizedBox(height: 12),
      _formSectionFields('Liên kết vị trí và thân nhân', Icons.hub_outlined, [
        _input('Mã vị trí mộ', _graveController),
        _input('Thân nhân đại diện', _familyController),
        _input('Thân nhân được cấp quyền', _relativeController, hint: '${record.relatives} người đang liên kết'),
        const _InfoBanner('Thay đổi vị trí mộ hoặc người đại diện cần được lưu vào lịch sử và xác nhận bởi quản lý.'),
      ]),
      const SizedBox(height: 12),
      _formSectionFields('Quyền riêng tư và chức năng tưởng niệm', Icons.lock_outline, [
        SwitchListTile(value: record.isPublic, onChanged: (value) => setState(() => record.isPublic = value), title: const Text('Công khai trang tưởng niệm')),
        SwitchListTile(value: record.guestbookEnabled, onChanged: (value) => setState(() => record.guestbookEnabled = value), title: const Text('Cho phép gửi lời kính viếng (cần duyệt)')),
        SwitchListTile(value: record.incenseEnabled, onChanged: (value) => setState(() => record.incenseEnabled = value), title: const Text('Cho phép thắp hương / dâng hoa trực tuyến')),
        const _InfoBanner('Không đưa CCCD, điện thoại, email hoặc hồ sơ pháp lý lên trang công khai.'),
      ]),
      const SizedBox(height: 12),
      _changeHistory(),
      const SizedBox(height: 12),
      _bottomActions(
        left: TextButton.icon(onPressed: _backToDirectory, icon: const Icon(Icons.arrow_back), label: const Text('Quay lại')),
        middle: OutlinedButton.icon(onPressed: () { setState(() => _page = _QrPage.preview); }, icon: const Icon(Icons.visibility_outlined), label: const Text('Xem trước')),
        right: FilledButton.icon(onPressed: _saveEditedRecord, icon: const Icon(Icons.save_outlined), label: const Text('Lưu thay đổi')),
      ),
    ]);
  }

  Widget _changeHistory() => _formSection('Lịch sử thay đổi hồ sơ', Icons.history, Column(children: [
        for (final row in const [
          ('24/05/2024  •  10:45', 'Ban Quản lý Sala', 'Tạo hồ sơ an táng'),
          ('28/05/2024  •  14:20', 'Nguyễn Văn An', 'Cập nhật tiểu sử tưởng niệm'),
          ('Hôm nay  •  Bản nháp', 'Quản trị viên', 'Các thay đổi mới sẽ được ghi nhận khi lưu'),
        ])
          ListTile(dense: true, leading: const Icon(Icons.circle, size: 9, color: AppColors.gold), title: Text(row.$3, style: const TextStyle(fontSize: 12)), subtitle: Text('${row.$1}  •  ${row.$2}', style: const TextStyle(fontSize: 10, color: AppColors.muted))),
      ]));

  Widget _memorialPreview() {
    final record = _active!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      _subHeader('Xem Trước Trang Tưởng Niệm Online', 'Khách viếng sẽ thấy nội dung được gia đình cho phép; hồ sơ riêng tư không xuất hiện.', Icons.public),
      const SizedBox(height: 12),
      Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.forestDeep, AppColors.forest], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(children: [
              const Icon(Icons.spa_outlined, color: Color(0xFFFFDEA5), size: 28),
              const SizedBox(height: 10),
              Text(record.alias.toUpperCase(), style: const TextStyle(color: Color(0xFFFFDEA5), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.w700)),
              Text(record.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
              Text(record.dates, style: const TextStyle(color: Color(0xFFD2E8DD), fontSize: 12)),
              const SizedBox(height: 14),
              Text('“Tâm sáng đức dày – Để phúc cho muôn đời con cháu.”', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFFFFDEA5), fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Text('Vị trí an nghỉ: ${record.plot}', style: const TextStyle(color: Color(0xFFD2E8DD), fontSize: 11)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('Dâng nén tâm hương & nguyện cầu', style: TextStyle(color: AppColors.forestDeep, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                _previewAction(Icons.local_fire_department, 'Thắp tâm hương', enabled: record.incenseEnabled),
                _previewAction(Icons.local_florist_outlined, 'Dâng sen trắng', enabled: record.incenseEnabled),
                _previewAction(Icons.volunteer_activism_outlined, 'Dâng hoa đăng', enabled: record.incenseEnabled),
                _previewAction(Icons.menu_book_outlined, 'Gửi lời tưởng niệm', enabled: record.guestbookEnabled),
              ]),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final bio = _formSection('Tiểu sử & cuộc đời', Icons.auto_stories_outlined, const Text('Thông tin tiểu sử và gia huấn do gia đình cung cấp sẽ được trình bày tại đây sau khi duyệt.', style: TextStyle(height: 1.6, color: AppColors.text)));
                final memories = _formSection('Thư viện ký ức', Icons.photo_library_outlined, const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ảnh gia đình • 12 tệp hình ảnh'), SizedBox(height: 8), Text('Video tưởng niệm • 02 thước phim'), SizedBox(height: 8), Text('Lời dặn dò • 01 bản ghi âm') ]));
                return compact ? Column(children: [bio, const SizedBox(height: 10), memories]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: bio), const SizedBox(width: 10), Expanded(child: memories)]);
              }),
              const SizedBox(height: 12),
              _formSection('Những dòng tri ân & lời kính viếng', Icons.forum_outlined, Column(children: [
                for (final message in const [('Nguyễn Văn Bình', 'Kính nhớ ông, mong ông an nghỉ nơi miền an lạc.'), ('Trần Thị My', 'Gia đình xin gửi lời tri ân và tưởng niệm.')])
                  ListTile(leading: const CircleAvatar(child: Text('T')), title: Text(message.$1), subtitle: Text(message.$2)),
                if (record.guestbookEnabled) TextField(decoration: InputDecoration(hintText: 'Viết lời kính viếng…', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 3),
              ])),
              const SizedBox(height: 12),
              TextButton.icon(onPressed: _backToDirectory, icon: const Icon(Icons.arrow_back), label: const Text('Quay lại quản lý QR')),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _previewAction(IconData icon, String label, {required bool enabled}) => OutlinedButton.icon(
        onPressed: enabled ? () => _notify('Thao tác xem trước: $label.') : null,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );

  Widget _subHeader(String title, String subtitle, IconData icon) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(children: [
            IconButton(onPressed: _backToDirectory, tooltip: 'Quay lại danh bạ', icon: const Icon(Icons.arrow_back, color: AppColors.forest)),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.gold, size: 26),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppColors.forestDeep, fontSize: 23, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ])),
            OutlinedButton.icon(onPressed: _backToDirectory, icon: const Icon(Icons.qr_code_2), label: const Text('Danh bạ QR')),
          ]),
        ),
      );

  Widget _formSectionFields(String title, IconData icon, List<Widget> children) => _formSection(title, icon, Column(children: children));

  Widget _formSection(String title, IconData icon, Widget content) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, color: AppColors.forest, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: AppColors.forestDeep, fontSize: 16, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 12),
            content,
          ]),
        ),
      );

  Widget _input(String label, TextEditingController? controller, {String? hint, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _stepChip(int number, String label, bool selected) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: selected ? AppColors.forest : AppColors.background, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 12, backgroundColor: selected ? const Color(0xFFFFDEA5) : AppColors.paleBlue, child: Text('$number', style: TextStyle(color: selected ? AppColors.forestDeep : AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.text, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _bottomActions({required Widget left, required Widget middle, required Widget right}) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [left, middle, right]),
        ),
      );

  Widget _smallTag(String label, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 8, fontWeight: FontWeight.w700)),
      );

  Widget _pair(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [SizedBox(width: 90, child: Text('$label:', style: const TextStyle(color: AppColors.muted, fontSize: 9))), Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 9, fontWeight: FontWeight.w600)))]),
      );

  void _startRegistration() {
    _active = null;
    _wizardStep = 0;
    _nameController.clear();
    _aliasController.clear();
    _graveController.clear();
    _familyController.clear();
    _relativeController.clear();
    _newIsPublic = true;
    _newGuestbookEnabled = true;
    _newIncenseEnabled = true;
    setState(() => _page = _QrPage.registration);
  }

  void _openEditor(_MemorialRecord record) {
    _active = record;
    _nameController.text = record.name;
    _aliasController.text = record.alias;
    _graveController.text = record.plot;
    _familyController.text = record.family;
    _relativeController.text = '${record.relatives} thân nhân đã liên kết';
    setState(() => _page = _QrPage.editor);
  }

  void _submitNewRecord() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _notify('Nhập họ tên hương linh trước khi gửi duyệt.');
      return;
    }
    if (_graveController.text.trim().isEmpty || _familyController.text.trim().isEmpty) {
      _notify('Cần nhập vị trí mộ và thân nhân đại diện trước khi gửi duyệt.');
      return;
    }
    _insertDraft(status: 'Chờ duyệt hồ sơ');
    _notify('Đã tạo hồ sơ mẫu và chuyển sang trạng thái chờ duyệt.');
  }

  void _saveDraft() {
    if (_nameController.text.trim().isEmpty) {
      _notify('Nhập họ tên hương linh để lưu bản nháp.');
      return;
    }
    _insertDraft(status: 'Bản nháp');
    _notify('Đã lưu hồ sơ nháp trong phiên xem thử.');
  }

  void _insertDraft({required String status}) {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    setState(() {
      _records.insert(0, _MemorialRecord(
        code: 'HS-2026-$suffix',
        name: _nameController.text.trim(),
        alias: _aliasController.text.trim().isEmpty ? 'Chưa cập nhật pháp danh' : _aliasController.text.trim(),
        plot: _graveController.text.trim().isEmpty ? 'Chưa liên kết vị trí' : _graveController.text.trim(),
        family: _familyController.text.trim().isEmpty ? 'Chưa liên kết thân nhân' : _familyController.text.trim(),
        dates: 'Chờ bổ sung ngày sinh / ngày mất',
        qrCode: 'QR-PENDING-$suffix',
        status: status,
        isPublic: _newIsPublic,
        guestbookEnabled: _newGuestbookEnabled,
        incenseEnabled: _newIncenseEnabled,
        relatives: _relativeController.text.trim().isEmpty ? 1 : 2,
      ));
      _page = _QrPage.directory;
      _filter = 'Tất cả';
      _query = '';
      _search.clear();
    });
  }

  void _saveEditedRecord() {
    final record = _active!;
    setState(() {
      if (_nameController.text.trim().isNotEmpty) record.name = _nameController.text.trim();
      if (_aliasController.text.trim().isNotEmpty) record.alias = _aliasController.text.trim();
      if (_graveController.text.trim().isNotEmpty) record.plot = _graveController.text.trim();
      if (_familyController.text.trim().isNotEmpty) record.family = _familyController.text.trim();
      record.status = 'Chờ duyệt thay đổi';
    });
    _notify('Đã lưu bản chỉnh sửa mẫu. Cần quản lý duyệt trước khi công khai.');
  }

  void _backToDirectory() => setState(() => _page = _QrPage.directory);

  void _notify(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _QrMark extends StatelessWidget {
  final double size;
  const _QrMark({this.size = 54});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
        child: GridView.count(
          crossAxisCount: 7,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
          children: [for (var i = 0; i < 49; i++) _cell(i)],
        ),
      );

  Widget _cell(int index) {
    final row = index ~/ 7;
    final col = index % 7;
    final finder = (row < 3 && col < 3) || (row < 3 && col > 3) || (row > 3 && col < 3);
    if (finder) {
      final r = row < 3 ? row : row - 4;
      final c = col < 3 ? col : col - 4;
      final edge = r == 0 || r == 2 || c == 0 || c == 2;
      return Container(color: edge || (r == 1 && c == 1) ? AppColors.forestDeep : Colors.white);
    }
    return Container(color: (index * 7 + row * 3 + col) % 4 == 0 ? AppColors.gold : (index + row) % 3 == 0 ? AppColors.forest : Colors.white);
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.paleBlue, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.info_outline, color: AppColors.forest, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 11, height: 1.4)))]),
      );
}

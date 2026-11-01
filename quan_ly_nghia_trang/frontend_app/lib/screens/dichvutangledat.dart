import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/mausala.dart';

class DichVuTangLeDat extends StatefulWidget {
  const DichVuTangLeDat({super.key, this.fullName});

  final String? fullName;

  @override
  State<DichVuTangLeDat> createState() => _DichVuTangLeDatState();
}

class _FuneralPackage {
  const _FuneralPackage({
    required this.name,
    required this.kicker,
    required this.description,
    required this.price,
    required this.badge,
    required this.icon,
    required this.features,
    required this.color,
  });

  final String name;
  final String kicker;
  final String description;
  final int price;
  final String badge;
  final IconData icon;
  final List<String> features;
  final Color color;
}

class _DichVuTangLeDatState extends State<DichVuTangLeDat> {
  static const _packages = [
    _FuneralPackage(
      name: 'Hỏa Táng Tiêu Chuẩn Sinh Thái',
      kicker: 'TIÊU CHUẨN XANH SINH THÁI',
      description:
          'Quy trình văn minh, không khói mùi, bảo tồn nguyện tro cốt thuần khiết cho người đã khuất.',
      price: 45000000,
      badge: 'Tư vấn phổ biến',
      icon: Icons.local_florist_outlined,
      color: MauSala.xanhThe,
      features: [
        'Áo quan hỏa táng gỗ tự nhiên, thân thiện môi trường',
        'Buồng đốt Thụy Điển TABO, kiểm soát nhiệt độ',
        'Hũ lưu tro cốt gốm sứ trang nhã',
        'Xe chuyên dụng và xe đưa đón thân nhân',
        'Thiết kế hoa tươi, không gian lễ trang nghiêm',
      ],
    ),
    _FuneralPackage(
      name: 'An Táng Truyền Thống Cao Cấp',
      kicker: 'ĐƯỢC LỰA CHỌN NHIỀU',
      description:
          'Đậm nét đẹp truyền thống phương Đông, chu toàn nghi thức và vĩnh cửu.',
      price: 85000000,
      badge: 'Trọn gói',
      icon: Icons.account_balance_outlined,
      color: MauSala.vang,
      features: [
        'Áo quan danh mộc quý, hoàn thiện thủ công',
        'Kim tĩnh bê tông nguyên khối chống sụt lún',
        'Nghi thức Phật giáo hoặc linh mục theo gia đình',
        'Xe rồng hoa và xe dẫn đường',
        'Đội phụng tang và lễ phục theo nghi thức',
      ],
    ),
    _FuneralPackage(
      name: 'Gói Tôn Giáo Biệt Lập VIP',
      kicker: 'ĐẲNG CẤP GIA TỘC VIP',
      description:
          'Thiết kế nghi thức riêng, không gian biệt lập theo tôn giáo và nguyện vọng gia đình.',
      price: 150000000,
      badge: 'Đặc quyền 72H',
      icon: Icons.account_balance_outlined,
      color: MauSala.xanhDam,
      features: [
        'Đại sảnh riêng, phục vụ đoàn khách quy mô lớn',
        'Nghi lễ tùy chỉnh theo tôn giáo và gia phong',
        'Áo quan và vật phẩm cao cấp tuyển chọn',
        'Đội nghi lễ, xe đưa đón và điều phối riêng',
        'Tiệc chay và phòng nghỉ cho gia quyến',
      ],
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _deceasedName = TextEditingController();
  final _birthYear = TextEditingController();
  final _deathYear = TextEditingController();
  final _dharmaName = TextEditingController();
  final _plotCode = TextEditingController();
  final _representative = TextEditingController();
  final _phone = TextEditingController();
  final _identity = TextEditingController();
  final _relationship = TextEditingController();
  final _address = TextEditingController();
  final _wishes = TextEditingController();

  int _selectedPackage = 1;
  int _page = 0;
  int _paymentPlan = 0;
  String _religion = 'Phật Giáo';
  String _flowerColor = 'Trắng thanh tịnh';
  String _paymentMethod = 'VietQR / ATM';
  DateTime? _ceremonyDate;
  bool _addTea = true;
  bool _addMusic = false;
  bool _addShuttle = false;
  bool _termsAccepted = false;

  _FuneralPackage get _package => _packages[_selectedPackage];

  int get _extrasTotal =>
      (_addTea ? 3500000 : 0) +
      (_addMusic ? 5000000 : 0) +
      (_addShuttle ? 1200000 : 0);

  int get _grandTotal => _package.price + _extrasTotal;

  int get _amountDue =>
      _paymentPlan == 0 ? (_grandTotal * .3).round() : _grandTotal;

  @override
  void initState() {
    super.initState();
    _representative.text = widget.fullName ?? '';
  }

  @override
  void dispose() {
    _deceasedName.dispose();
    _birthYear.dispose();
    _deathYear.dispose();
    _dharmaName.dispose();
    _plotCode.dispose();
    _representative.dispose();
    _phone.dispose();
    _identity.dispose();
    _relationship.dispose();
    _address.dispose();
    _wishes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: _page == 0 ? _catalog(wide) : _booking(wide),
                ),
              ),
            ],
          );
        },
      );

  Widget _catalog(bool wide) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _catalogHeading(wide),
          const SizedBox(height: 16),
          _catalogTabs(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NGHI THỨC TÔN NGHIÊM',
                        style: TextStyle(
                            fontSize: 8,
                            letterSpacing: .8,
                            color: MauSala.vang,
                            fontWeight: FontWeight.w700)),
                    Text('Bộ Giải Pháp Tang Lễ Trọn Gói Tiêu Chuẩn Quốc Tế',
                        style: GoogleFonts.newsreader(
                            fontSize: wide ? 24 : 20,
                            color: MauSala.xanhDam,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
            if (wide)
              const Row(children: [
                Icon(Icons.verified_user_outlined,
                    size: 14, color: MauSala.vang),
                SizedBox(width: 5),
                Text('Minh bạch chi phí • Không phát sinh phụ phí',
                    style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
              ]),
          ]),
          const SizedBox(height: 12),
          _packageGrid(wide),
          const SizedBox(height: 20),
          _standardsPanel(),
          const SizedBox(height: 16),
          _consultationBanner(),
        ],
      );

  Widget _catalogHeading(bool wide) => LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 980;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 7, runSpacing: 5, children: [
                _microTag('Hệ sinh thái An Viên 50ha', gold: true),
                const Text('KHU PHỨC HỢP HẬU SỰ KHÉP KÍN CHUẨN QUỐC TẾ',
                    style: TextStyle(
                        fontSize: 8, letterSpacing: .5, color: MauSala.chuPhu)),
              ]),
              const SizedBox(height: 5),
              Text('Quản Lý & Đặt Dịch Vụ Tang Lễ Trọn Gói',
                  style: GoogleFonts.newsreader(
                      fontSize: wide ? 30 : 24,
                      height: 1.1,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống điều phối Nhà Tang Lễ Trung Tâm và công nghệ hỏa táng TABO, đồng hành cùng gia đình chu toàn nghi thức trang nghiêm.',
                style: TextStyle(
                    color: MauSala.chuPhu, fontSize: 10, height: 1.45),
              ),
            ],
          );
          final actions = Wrap(spacing: 8, runSpacing: 8, children: [
            _trustCard(Icons.verified_outlined, 'Quy chuẩn sinh thái',
                '100% khí thải sạch TABO'),
            FilledButton.icon(
              onPressed: () => _startBooking(1),
              style: FilledButton.styleFrom(
                  backgroundColor: MauSala.xanhDam,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
              icon: const Icon(Icons.post_add, size: 16),
              label: const Text('Tạo Hồ Sơ Mới',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]);
          return horizontal
              ? Row(children: [
                  Expanded(child: title),
                  const SizedBox(width: 14),
                  actions,
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: 10), actions],
                );
        },
      );

  Widget _catalogTabs() => Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)),
        child: Wrap(spacing: 5, runSpacing: 5, children: [
          _catalogTab('Gói Tang Lễ Trọn Gói', Icons.workspace_premium, true),
          _catalogTab('Lịch Đặt Nhà Tang Lễ', Icons.calendar_month, false),
          _catalogTab('Công Nghệ Hỏa Táng TABO', Icons.autorenew, false),
          _catalogTab(
              'Tiện Ích & Tiếp Đón Thân Nhân', Icons.room_service, false),
        ]),
      );

  Widget _catalogTab(String text, IconData icon, bool active) => InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: active
            ? null
            : () => _showInfo('$text sẽ được cung cấp bởi Ban Quản Khách.'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: active ? MauSala.xanhThe : Colors.transparent,
              borderRadius: BorderRadius.circular(5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: active ? Colors.white : MauSala.chuPhu),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    fontSize: 9,
                    color: active ? Colors.white : MauSala.chuPhu,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      );

  Widget _packageGrid(bool wide) => LayoutBuilder(builder: (context, c) {
        final count = c.maxWidth >= 900
            ? 3
            : c.maxWidth >= 560
                ? 2
                : 1;
        const gap = 12.0;
        final width = (c.maxWidth - (count - 1) * gap) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(
            _packages.length,
            (index) => SizedBox(
              width: width,
              child: _packageCard(_packages[index], index),
            ),
          ),
        );
      });

  Widget _packageCard(_FuneralPackage package, int index) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE7EDF3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D1B4D3E), blurRadius: 12, offset: Offset(0, 3)),
          ],
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child:
                _microTag(package.kicker, gold: index == 1, green: index != 1),
          ),
          const SizedBox(height: 9),
          Container(
            height: 145,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  package.color.withValues(alpha: .30),
                  package.color,
                  MauSala.xanhDam,
                ],
              ),
            ),
            child: Stack(children: [
              Positioned(
                right: -8,
                top: -16,
                child: Icon(package.icon,
                    size: 142, color: Colors.white.withValues(alpha: .10)),
              ),
              Positioned(
                top: 13,
                left: 13,
                child: Icon(package.icon, size: 29, color: MauSala.vangThe),
              ),
              Positioned(
                left: 13,
                right: 13,
                bottom: 12,
                child: Row(children: [
                  Expanded(
                    child: Text(package.badge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  _microTag(index == 0 ? '90 phút/ca' : 'Trọn gói', gold: true),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 9),
          Text(package.name,
              style: GoogleFonts.newsreader(
                  color: MauSala.xanhDam,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(package.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: MauSala.chuPhu, fontSize: 9, height: 1.45)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
                color: index == 1 ? const Color(0xFFFFF7E8) : MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(5)),
            child: Row(children: [
              const Expanded(
                child: Text('CHI PHÍ THAM KHẢO',
                    style: TextStyle(
                        color: MauSala.chuPhu,
                        fontSize: 7,
                        letterSpacing: .35)),
              ),
              Text(_money(package.price),
                  style: GoogleFonts.newsreader(
                      color: package.color,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 9),
          ...package.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: package.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(feature,
                            style: const TextStyle(
                                color: MauSala.chuPhu,
                                fontSize: 8,
                                height: 1.35)),
                      ),
                    ]),
              )),
          const SizedBox(height: 3),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _startBooking(index),
                style: FilledButton.styleFrom(
                    backgroundColor: package.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Chọn Gói Này',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 7),
            OutlinedButton(
              onPressed: () => _showPackageDetails(package),
              style: OutlinedButton.styleFrom(
                  foregroundColor: MauSala.xanhDam,
                  side: const BorderSide(color: MauSala.xanhNenThe),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 11)),
              child: const Text('Chi Tiết', style: TextStyle(fontSize: 9)),
            ),
          ]),
        ]),
      );

  Widget _standardsPanel() => _panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.tune, size: 16, color: MauSala.vang),
            const SizedBox(width: 7),
            const Expanded(
              child: Text('Minh Bạch Các Hạng Mục Kỹ Thuật & Cam Kết Vận Hành',
                  style: TextStyle(
                      fontSize: 11,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w700)),
            ),
            if (MediaQuery.sizeOf(context).width > 900)
              const Text('TIÊU CHUẨN HẬU SỰ',
                  style: TextStyle(
                      fontSize: 7, letterSpacing: .6, color: MauSala.chuPhu)),
          ]),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final count = c.maxWidth > 750
                ? 4
                : c.maxWidth > 430
                    ? 2
                    : 1;
            const gap = 8.0;
            final width = (c.maxWidth - (count - 1) * gap) / count;
            const items = [
              (
                Icons.filter_vintage,
                '100% Hoa Tươi',
                'Cắt tuyển mới, phối màu gia đình chỉ định'
              ),
              (
                Icons.speed,
                'Thời Gian Chuẩn',
                'Điều phối nghi thức theo tiến độ gia đình'
              ),
              (
                Icons.air,
                'Hệ Thống Lọc Khí',
                'Kiểm soát khí thải, hạn chế mùi'
              ),
              (
                Icons.shield_outlined,
                'Bảo Mật & Tôn Nghiêm',
                'Bảo vệ riêng tư và thông tin gia quyến'
              ),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: items
                  .map((item) => SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: MauSala.xanhNhat,
                              borderRadius: BorderRadius.circular(6)),
                          child: Column(children: [
                            Icon(item.$1, size: 20, color: MauSala.xanhThe),
                            const SizedBox(height: 6),
                            Text(item.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: MauSala.xanhDam,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(item.$3,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: MauSala.chuPhu,
                                    fontSize: 8,
                                    height: 1.35)),
                          ]),
                        ),
                      ))
                  .toList(),
            );
          }),
        ]),
      );

  Widget _consultationBanner() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: MauSala.xanhDam,
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
                colors: [MauSala.xanhDam, Color(0xFF0B4F3D)])),
        child: LayoutBuilder(builder: (context, c) {
          final narrow = c.maxWidth < 600;
          final copy = Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: MauSala.vangThe,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.call_outlined, color: MauSala.vang),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cần Tư Vấn Nghi Lễ Theo Phong Tục Riêng Biệt?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                        'Đội ngũ tư vấn luôn sẵn sàng lắng nghe nguyện vọng và hỗ trợ gia đình.',
                        style: TextStyle(
                            color: MauSala.xanhNenThe,
                            fontSize: 9,
                            height: 1.35)),
                  ]),
            ),
          ]);
          final actions = Wrap(spacing: 7, children: [
            FilledButton.icon(
              onPressed: () => _showInfo('Hotline tư vấn: 1900 68xx'),
              style: FilledButton.styleFrom(
                  backgroundColor: MauSala.vang, foregroundColor: Colors.white),
              icon: const Icon(Icons.call, size: 13),
              label: const Text('Gọi Tư Vấn', style: TextStyle(fontSize: 9)),
            ),
            OutlinedButton(
              onPressed: () => _startBooking(_selectedPackage),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30)),
              child:
                  const Text('Để Lại Lời Nhắn', style: TextStyle(fontSize: 9)),
            ),
          ]);
          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      copy,
                      const SizedBox(height: 12),
                      actions,
                    ])
              : Row(children: [
                  Expanded(child: copy),
                  const SizedBox(width: 14),
                  actions
                ]);
        }),
      );

  Widget _booking(bool wide) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bookingHeading(),
          const SizedBox(height: 10),
          _packagePicker(),
          const SizedBox(height: 12),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: _bookingMain()),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _bookingAside()),
            ])
          else
            Column(children: [
              _bookingMain(),
              const SizedBox(height: 12),
              _bookingAside(),
            ]),
        ],
      );

  Widget _bookingHeading() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
              spacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _page = 0),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Danh mục dịch vụ',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const Text('›', style: TextStyle(color: MauSala.vien)),
                const Text('ĐĂNG KÝ GÓI & THANH TOÁN',
                    style: TextStyle(
                        color: MauSala.vang,
                        fontSize: 9,
                        letterSpacing: .5,
                        fontWeight: FontWeight.w700)),
              ]),
          const SizedBox(height: 4),
          Text('Đăng Ký Dịch Vụ Tang Lễ',
              style: GoogleFonts.newsreader(
                  color: MauSala.xanhDam,
                  fontSize: 28,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Wrap(spacing: 7, runSpacing: 6, children: [
            Text('Gói đang chọn: ${_package.name}',
                style: const TextStyle(
                    fontSize: 11,
                    color: MauSala.chuPhu,
                    fontWeight: FontWeight.w500)),
            _microTag('Mã hồ sơ cấp sau khi xác nhận', green: true),
          ]),
        ],
      );

  Widget _packagePicker() => _panel(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, c) {
          final count = c.maxWidth > 900
              ? 3
              : c.maxWidth > 560
                  ? 2
                  : 1;
          const gap = 7.0;
          final width = (c.maxWidth - (count - 1) * gap) / count;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(_packages.length, (index) {
              final package = _packages[index];
              final active = _selectedPackage == index;
              return InkWell(
                onTap: () => setState(() => _selectedPackage = index),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: width,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active ? MauSala.xanhThe : Colors.white,
                    border: Border.all(
                        color: active ? MauSala.xanhThe : MauSala.xanhNenThe),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    Icon(package.icon,
                        size: 17, color: active ? Colors.white : package.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(package.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: active ? Colors.white : MauSala.xanhDam,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(_compactMoney(package.price),
                        style: TextStyle(
                            color: active ? MauSala.vangThe : package.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            }),
          );
        }),
      );

  Widget _bookingMain() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _serviceSummary(),
            const SizedBox(height: 10),
            _includedItems(),
            const SizedBox(height: 10),
            _deceasedForm(),
            const SizedBox(height: 10),
            _familyForm(),
            const SizedBox(height: 8),
            _bookingConsent(),
          ],
        ),
      );

  Widget _serviceSummary() => _panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _microTag('GÓI TANG LỄ TRỌN GÓI', gold: true),
            const SizedBox(width: 6),
            _microTag('Chi phí tham khảo', green: true),
          ]),
          const SizedBox(height: 9),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Text(_money(_package.price),
                  style: GoogleFonts.newsreader(
                      fontSize: 30,
                      height: 1,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w700)),
            ),
            const Text('VND',
                style: TextStyle(
                    fontSize: 11,
                    color: MauSala.chuPhu,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          Text(_package.name,
              style: GoogleFonts.newsreader(
                  fontSize: 19,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_package.description,
              style: const TextStyle(
                  color: MauSala.chuPhu, fontSize: 10, height: 1.45)),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _fact(Icons.verified_user_outlined, 'Báo giá minh bạch'),
            _fact(Icons.schedule, 'Điều phối theo lịch gia đình'),
            _fact(Icons.groups_outlined, 'Hỗ trợ gia quyến'),
            _fact(Icons.shield_outlined, 'Bảo vệ thông tin'),
          ]),
        ]),
      );

  Widget _includedItems() => _section(
        'Danh Mục Chi Tiết Hạng Mục Bao Gồm',
        Icons.inventory_2_outlined,
        Column(
            children: List.generate(_package.features.length, (index) {
          final feature = _package.features[index];
          final icons = [
            Icons.business_center_outlined,
            Icons.account_balance_outlined,
            Icons.directions_car_outlined,
            Icons.local_florist_outlined,
            Icons.support_agent,
          ];
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(6)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                    color: MauSala.xanhThe,
                    borderRadius: BorderRadius.circular(5)),
                child: Icon(icons[index % icons.length],
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. $feature',
                          style: const TextStyle(
                              color: MauSala.xanhDam,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        index == 0
                            ? 'Nhân viên sẽ xác nhận lựa chọn và quy cách cùng gia đình trước khi thực hiện.'
                            : 'Thời gian và chi tiết cung cấp được thống nhất trong quá trình xác nhận hồ sơ.',
                        style: const TextStyle(
                            color: MauSala.chuPhu, fontSize: 9, height: 1.4),
                      ),
                    ]),
              ),
            ]),
          );
        })),
      );

  Widget _deceasedForm() => _section(
        '1. Thông Tin Người Quá Cố & Nghi Lễ Yêu Cầu',
        Icons.person_outline,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _fieldRow([
            _textField(_deceasedName, 'Họ và tên người quá cố',
                hint: 'Nhập họ tên đầy đủ', required: true),
            _textField(_birthYear, 'Năm sinh', hint: 'VD: 1952'),
            _textField(_deathYear, 'Năm mất / hưởng thọ', hint: 'VD: 2026'),
          ]),
          const SizedBox(height: 9),
          _fieldRow([
            _dropdownField(
                'Tôn giáo cử hành tang lễ',
                _religion,
                ['Phật Giáo', 'Công Giáo', 'Tin Lành', 'Không theo tôn giáo'],
                (value) => setState(() => _religion = value!)),
            _textField(_dharmaName, 'Pháp danh / Tên Thánh (nếu có)',
                hint: 'Thông tin tùy chọn'),
          ]),
          const SizedBox(height: 9),
          _dateSelector(),
          const SizedBox(height: 9),
          _fieldRow([
            _textField(_plotCode, 'Vị trí / mã mộ tại Sala Garden',
                hint: 'VD: M1-R05-12'),
            _dropdownField(
                'Tông màu hoa tang lễ',
                _flowerColor,
                ['Trắng thanh tịnh', 'Vàng trang nhã', 'Theo yêu cầu'],
                (value) => setState(() => _flowerColor = value!)),
          ]),
          const SizedBox(height: 9),
          _textField(
              _wishes, 'Yêu cầu đặc biệt về tâm linh hoặc ý nguyện gia đình',
              hint: 'Chia sẻ nguyện vọng để đội ngũ tư vấn chuẩn bị chu đáo...',
              maxLines: 3),
        ]),
      );

  Widget _familyForm() => _section(
        '2. Thông Tin Thân Nhân Đại Diện Đăng Ký',
        Icons.groups_outlined,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _fieldRow([
            _textField(_representative, 'Họ tên người đại diện',
                hint: 'Nguyễn Văn A', required: true),
            _textField(_phone, 'Số điện thoại liên hệ 24/7',
                hint: '09xx xxx xxx', required: true, phone: true),
          ]),
          const SizedBox(height: 9),
          _fieldRow([
            _textField(_identity, 'Số CCCD / Hộ chiếu',
                hint: 'Thông tin đối soát'),
            _textField(_relationship, 'Mối quan hệ với người quá cố',
                hint: 'Con trai, con gái...'),
          ]),
          const SizedBox(height: 9),
          _textField(_address, 'Địa chỉ tiếp nhận / đưa đón',
              hint: 'Số nhà, đường, phường, tỉnh/thành'),
        ]),
      );

  Widget _bookingConsent() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: MauSala.xanhNenThe),
        ),
        child: CheckboxListTile(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          activeColor: MauSala.xanhThe,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          title: const Text(
            'Tôi xác nhận thông tin đăng ký là chính xác và đồng ý để Ban Quản Khách liên hệ xác nhận dịch vụ tang lễ.',
            style: TextStyle(color: MauSala.chuPhu, fontSize: 9, height: 1.4),
          ),
        ),
      );

  Widget _dateSelector() => InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: _inputDecoration('Ngày dự kiến tổ chức nghi lễ',
              icon: Icons.calendar_month_outlined),
          child: Row(children: [
            Expanded(
              child: Text(
                _ceremonyDate == null
                    ? 'Chọn ngày để Ban Quản Khách xác nhận lịch'
                    : DateFormat('dd/MM/yyyy').format(_ceremonyDate!),
                style: TextStyle(
                    color: _ceremonyDate == null
                        ? MauSala.chuPhu.withValues(alpha: .7)
                        : MauSala.xanhDam,
                    fontSize: 10),
              ),
            ),
            const Icon(Icons.expand_more, color: MauSala.chuPhu, size: 18),
          ]),
        ),
      );

  Widget _bookingAside() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryPanel(),
          const SizedBox(height: 10),
          _addonsPanel(),
          const SizedBox(height: 10),
          _paymentOptions(),
          const SizedBox(height: 10),
          _confirmPanel(),
          const SizedBox(height: 10),
          _funeralHotlineCard(),
        ],
      );

  Widget _funeralHotlineCard() => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2D9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFE1A8)),
        ),
        child: Row(children: [
          const Icon(Icons.support_agent, color: MauSala.vang, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HỖ TRỢ TANG LỄ 24/7',
                    style: TextStyle(
                        color: MauSala.vang,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .35)),
                SizedBox(height: 3),
                Text('1900 68xx',
                    style: TextStyle(
                        color: MauSala.xanhDam,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          FilledButton(
            onPressed: _callFuneralHotline,
            style: FilledButton.styleFrom(
              backgroundColor: MauSala.vang,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              minimumSize: Size.zero,
            ),
            child: const Text('Gọi hỗ trợ',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _summaryPanel() => _section(
        'PHIẾU XÁC NHẬN DỊCH VỤ',
        Icons.receipt_long_outlined,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _microTag('BÁO GIÁ THAM KHẢO', gold: true),
          const SizedBox(height: 7),
          Text(_package.name,
              style: GoogleFonts.newsreader(
                  fontSize: 18,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _summaryLine('Gói dịch vụ', _money(_package.price)),
          if (_extrasTotal > 0) ...[
            const SizedBox(height: 5),
            _summaryLine('Dịch vụ tăng thêm', _money(_extrasTotal)),
          ],
          const Divider(height: 16, color: MauSala.xanhNenThe),
          _summaryLine('Tổng dự kiến', _money(_grandTotal), bold: true),
          const SizedBox(height: 7),
          _summaryLine(
            _paymentPlan == 0
                ? 'Thanh toán đợt này • 30%'
                : 'Thanh toán đợt này • 100%',
            _money(_amountDue),
            bold: true,
            gold: true,
          ),
          const SizedBox(height: 5),
          _summaryLine(
            'Còn lại sau đợt này',
            _money(_grandTotal - _amountDue),
          ),
          const SizedBox(height: 8),
          const Text(
              'Giá cuối cùng sẽ được nhân viên xác nhận trước khi thanh toán.',
              style:
                  TextStyle(fontSize: 9, height: 1.4, color: MauSala.chuPhu)),
        ]),
      );

  Widget _addonsPanel() => _section(
        'DỊCH VỤ GIA TĂNG TÙY CHỌN',
        Icons.add_circle_outline,
        Column(children: [
          _addonTile('Tiệc trà đón tiếp', 'Phục vụ khách viếng', 3500000,
              _addTea, (v) => setState(() => _addTea = v)),
          _addonTile('Đội kèn đồng / nhạc lễ', 'Theo phong tục gia đình',
              5000000, _addMusic, (v) => setState(() => _addMusic = v)),
          _addonTile('Xe điện đưa đón nội khu', 'Theo lịch điều phối', 1200000,
              _addShuttle, (v) => setState(() => _addShuttle = v)),
        ]),
      );

  Widget _addonTile(String title, String subtitle, int price, bool checked,
          ValueChanged<bool> onChanged) =>
      InkWell(
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                  value: checked,
                  activeColor: MauSala.xanhThe,
                  onChanged: (value) => onChanged(value ?? false)),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: MauSala.xanhDam,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: const TextStyle(
                             color: MauSala.chuPhu, fontSize: 9)),
                  ]),
            ),
            Text('+${_compactMoney(price)}',
                style: const TextStyle(
                    color: MauSala.xanhThe,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _paymentOptions() => _section(
        'HÌNH THỨC THANH TOÁN DỰ KIẾN',
        Icons.account_balance_wallet_outlined,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _planTile(0, 'Đặt cọc giữ lịch', '30% • phần còn lại xác nhận sau'),
          const SizedBox(height: 6),
          _planTile(
              1, 'Thanh toán trọn gói', '100% • theo xác nhận của tư vấn viên'),
          const SizedBox(height: 10),
          const Text('KÊNH THANH TOÁN',
              style: TextStyle(
                   fontSize: 9,
                  color: MauSala.chuPhu,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 5, runSpacing: 5, children: [
            _methodChip('VietQR / ATM', Icons.qr_code_2),
            _methodChip('Visa / Master / JCB', Icons.credit_card_outlined),
            _methodChip(
                'MoMo / ZaloPay', Icons.account_balance_wallet_outlined),
            _methodChip('Tiền mặt tại Sala', Icons.payments_outlined),
          ]),
          if (_paymentMethod == 'VietQR / ATM') ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: MauSala.xanhNhat,
                  borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.qr_code_2, size: 34, color: MauSala.xanhThe),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'QR thanh toán sẽ được cấp sau khi Ban Quản Khách xác nhận hồ sơ và số tiền. Không dùng mã minh họa để chuyển khoản.',
                    style: TextStyle(
                        color: MauSala.chuPhu, fontSize: 9, height: 1.4),
                  ),
                ),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: MauSala.xanhNhat,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                _paymentMethod == 'Tiền mặt tại Sala'
                    ? 'Ban Quản Khách sẽ hướng dẫn địa điểm và thời gian thanh toán sau khi xác nhận lịch tang lễ.'
                    : 'Cổng thanh toán ${_paymentMethod.split(' / ').first} sẽ được mở sau khi hồ sơ và chi phí được xác nhận.',
                style: const TextStyle(
                    color: MauSala.chuPhu, fontSize: 9, height: 1.4),
              ),
            ),
          ],
        ]),
      );

  Widget _planTile(int value, String title, String subtitle) {
    final active = _paymentPlan == value;
    return InkWell(
      onTap: () => setState(() => _paymentPlan = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE7F4EE) : MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: active ? MauSala.xanhThe : Colors.transparent),
        ),
        child: Row(children: [
          Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16, color: active ? MauSala.xanhThe : MauSala.chuPhu),
          const SizedBox(width: 7),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 9,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w700)),
              Text(subtitle,
                   style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
            ]),
          ),
          Text(
              value == 0
                  ? _money((_grandTotal * .3).round())
                  : _money(_grandTotal),
              style: const TextStyle(
                  color: MauSala.xanhThe,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _methodChip(String name, IconData icon) {
    final active = _paymentMethod == name;
    return ChoiceChip(
      selected: active,
      onSelected: (_) => setState(() => _paymentMethod = name),
      avatar:
          Icon(icon, size: 13, color: active ? Colors.white : MauSala.xanhThe),
      label: Text(name,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      selectedColor: MauSala.xanhThe,
      backgroundColor: MauSala.xanhNhat,
      labelStyle: TextStyle(color: active ? Colors.white : MauSala.chuPhu),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _confirmPanel() => _panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: MauSala.xanhThe),
            const SizedBox(width: 5),
            const Expanded(
              child: Text('Xác nhận thông tin yêu cầu',
                  style: TextStyle(
                      fontSize: 10,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Gửi thông tin đăng ký gói tang lễ để chuyên viên xác nhận lịch, hạng mục và báo giá cuối cùng. Việc chọn phương thức thanh toán chưa tạo giao dịch.',
            style: TextStyle(fontSize: 9, height: 1.45, color: MauSala.chuPhu),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _submitRequest,
            style: FilledButton.styleFrom(
                backgroundColor: MauSala.xanhDam,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            icon: const Icon(Icons.check_circle_outline, size: 15),
            label: const Text('Xác Nhận & Tiếp Tục Thanh Toán',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          const Text('Không thu tiền trên màn hình này.',
              textAlign: TextAlign.center,
               style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]),
      );

  Widget _section(String title, IconData icon, Widget child) => _panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                  color: MauSala.xanhThe,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 7),
            Icon(icon, size: 15, color: MauSala.xanhThe),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.newsreader(
                      fontSize: 17,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );

  Widget _panel(
          {required Widget child,
          EdgeInsets padding = const EdgeInsets.all(12)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EDF3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D1B4D3E), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _fieldRow(List<Widget> fields) => LayoutBuilder(
        builder: (context, c) {
          final stacked = c.maxWidth < 500;
          if (stacked) {
            return Column(
                children: fields
                    .map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: field,
                        ))
                    .toList());
          }
          return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields
                  .map((field) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: field,
                        ),
                      ))
                  .toList());
        },
      );

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    bool phone = false,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập $label.'
                : null
            : null,
        decoration: _inputDecoration(label, hint: hint, required: required),
        style: const TextStyle(
            fontSize: 10, color: MauSala.chu, fontWeight: FontWeight.w500),
      );

  Widget _dropdownField(String label, String current, List<String> values,
          ValueChanged<String?> onChanged) =>
      DropdownButtonFormField<String>(
        initialValue: current,
        decoration: _inputDecoration(label),
        icon: const Icon(Icons.expand_more, size: 17),
        style: const TextStyle(
            fontSize: 10, color: MauSala.chu, fontWeight: FontWeight.w500),
        items: values
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
      );

  InputDecoration _inputDecoration(String label,
          {String? hint, bool required = false, IconData? icon}) =>
      InputDecoration(
        label: RichText(
            text: TextSpan(
                text: label,
                style: const TextStyle(
                    fontSize: 9,
                    color: MauSala.chuPhu,
                    fontWeight: FontWeight.w600),
                children: required
                    ? const [
                        TextSpan(
                            text: ' *',
                            style: TextStyle(color: Color(0xFFBA1A1A)))
                      ]
                    : const [])),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 9, color: MauSala.vien),
        prefixIcon: icon == null ? null : Icon(icon, size: 15),
        filled: true,
        fillColor: MauSala.xanhNhat,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: MauSala.xanhThe)),
        errorStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
      );

  Widget _microTag(String label, {bool gold = false, bool green = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: gold
              ? const Color(0xFFFFE5B5)
              : green
                  ? const Color(0xFFE3EFFB)
                  : MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: gold ? MauSala.vang : MauSala.xanhDam,
                fontSize: 9,
                letterSpacing: .2,
                fontWeight: FontWeight.w700)),
      );

  Widget _trustCard(IconData icon, String title, String subtitle) => Container(
        constraints: const BoxConstraints(maxWidth: 158),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
            color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Icon(icon, size: 17, color: MauSala.xanhThe),
          const SizedBox(width: 7),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                   style: const TextStyle(color: MauSala.chuPhu, fontSize: 9)),
              Text(subtitle,
                  style: const TextStyle(
                      color: MauSala.xanhDam,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );

  Widget _fact(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: MauSala.xanhThe),
          const SizedBox(width: 4),
          Text(label,
               style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]),
      );

  Widget _summaryLine(String label, String value,
          {bool bold = false, bool gold = false}) =>
      Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: MauSala.chuPhu,
                  fontSize: bold ? 10 : 9,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ),
        Text(value,
            style: TextStyle(
                color: gold
                    ? MauSala.vang
                    : bold
                        ? MauSala.xanhDam
                        : MauSala.chuPhu,
                fontSize: bold ? 11 : 9,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
      ]);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _ceremonyDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: 'Chọn ngày dự kiến tổ chức',
      cancelText: 'Hủy',
      confirmText: 'Chọn ngày',
    );
    if (selected != null) setState(() => _ceremonyDate = selected);
  }

  void _startBooking(int index) {
    setState(() {
      _selectedPackage = index;
      _page = 1;
    });
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      _showInfo('Vui lòng xác nhận thông tin đăng ký dịch vụ tang lễ.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.fact_check_outlined, color: MauSala.xanhThe),
        title: Text('Thông tin yêu cầu đã sẵn sàng',
            style: GoogleFonts.newsreader(
                color: MauSala.xanhDam, fontWeight: FontWeight.w600)),
        content: Text(
          'Gói ${_package.name} • ${_money(_amountDue)} dự kiến thanh toán.\n\nĐây hiện là giao diện thử; yêu cầu chưa được gửi lên máy chủ và chưa phát sinh thanh toán. Vui lòng liên hệ Ban Quản Khách để xác nhận lịch và báo giá chính thức.',
          style: const TextStyle(fontSize: 12, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu')),
        ],
      ),
    );
  }

  void _showPackageDetails(_FuneralPackage package) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: SafeArea(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(package.name,
                        style: GoogleFonts.newsreader(
                            fontSize: 22,
                            color: MauSala.xanhDam,
                            fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ]),
                Text(package.description,
                    style: const TextStyle(
                        color: MauSala.chuPhu, fontSize: 11, height: 1.45)),
                const SizedBox(height: 12),
                ...package.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: MauSala.xanhThe, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(feature,
                                style: const TextStyle(fontSize: 10))),
                      ]),
                    )),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: Text('Giá tham khảo: ${_money(package.price)}',
                          style: const TextStyle(
                              color: MauSala.vang,
                              fontSize: 12,
                              fontWeight: FontWeight.w700))),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final index = _packages.indexOf(package);
                        _startBooking(index);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: MauSala.xanhThe),
                      child: const Text('Chọn gói này')),
                ]),
              ]),
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _callFuneralHotline() async {
    await launchUrl(Uri.parse('tel:19006800'));
  }

  String _money(num amount) =>
      '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount).trim()} ₫';

  String _compactMoney(num amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).round()} triệu';
    }
    return _money(amount);
  }
}

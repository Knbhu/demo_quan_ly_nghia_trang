import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/mausala.dart';
import 'auth_login_screen.dart';
import 'chiduong.dart';
import 'sodotongquan.dart';

class TrangChuKhachVangLai extends StatefulWidget {
  const TrangChuKhachVangLai({super.key});

  @override
  State<TrangChuKhachVangLai> createState() => _TrangChuKhachVangLaiState();
}

class _TrangChuKhachVangLaiState extends State<TrangChuKhachVangLai> {
  final _traCuuKey = GlobalKey();
  final _sanPhamKey = GlobalKey();
  final _scrollController = ScrollController();
  final _ten = TextEditingController();
  final _maMo = TextEditingController();
  final _maDinhDanh = TextEditingController();
  final _namSinh = TextEditingController();
  bool _dangTim = false;
  String? _loi;

  @override
  void dispose() {
    _ten.dispose();
    _maMo.dispose();
    _maDinhDanh.dispose();
    _namSinh.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _traCuu() async {
    if (_ten.text.trim().isEmpty ||
        _maMo.text.trim().isEmpty ||
        _maDinhDanh.text.trim().isEmpty ||
        _namSinh.text.trim().isEmpty) {
      setState(() => _loi = 'Vui lòng nhập đủ 4 thông tin để tra cứu.');
      return;
    }
    setState(() {
      _dangTim = true;
      _loi = null;
    });
    try {
      final result = await ApiService.instance.post('/public/graves/lookup', {
        'fullName': _ten.text.trim(),
        'plotCode': _maMo.text.trim(),
        'plotIdentifier': _maDinhDanh.text.trim(),
        'birthYear': int.tryParse(_namSinh.text.trim()),
      });
      if (!mounted) return;
      final grave = Map<String, dynamic>.from(result['data'] as Map);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChiDuongPage(hoSoMo: grave)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loi = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _dangTim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSala.nen,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 76,
            backgroundColor: MauSala.nen.withValues(alpha: .97),
            titleSpacing: 22,
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              const CircleAvatar(
                  backgroundColor: MauSala.xanhThe,
                  child: Icon(Icons.spa, color: Color(0xFFBAEED9))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SALA GARDEN',
                    style: GoogleFonts.newsreader(
                        fontSize: 20,
                        color: MauSala.xanhDam,
                        fontWeight: FontWeight.w600)),
                Text('HOA VIÊN NGHĨA TRANG SINH THÁI',
                    style: GoogleFonts.manrope(
                        fontSize: 8, color: MauSala.vang, letterSpacing: 1.1)),
              ]),
            ]),
            actions: [
              if (MediaQuery.sizeOf(context).width > 950) ...[
                _nav('Giới thiệu', () => _scroll('gioi-thieu')),
                _nav('Sản phẩm', () => _scroll('san-pham')),
                _nav('Tra cứu', () => _scroll('tra-cuu')),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FilledButton.tonalIcon(
                  onPressed: () => _showLoginMessage(context),
                  icon: const Icon(Icons.key, size: 17),
                  label: const Text('Portal thân nhân'),
                  style: FilledButton.styleFrom(
                      backgroundColor: MauSala.vangThe,
                      foregroundColor: MauSala.vang),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _noiDung()),
        ],
      ),
    );
  }

  Widget _noiDung() => Column(children: [
        _hero(),
        _loiTat(),
        _sanPham(),
        _traCuuSection(),
        _giaTri(),
        _danhGia(),
        _chanTrang(),
      ]);

  Widget _hero() => Container(
        width: double.infinity,
        color: MauSala.xanhDam,
        child: Stack(children: [
          Positioned.fill(
              child: Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC4CsFxoK1dpW6hYZ8Usx4ejNTW_M4zo6dICTDj7h2EvPh70__QbBhlE5pQsm9Hq68ZSIqKIaXZnLwTeQSkGTmR4228sR390mEu6QRRq4vblzRxPkZdn7onpEabikVLv016FTrtPkjG3Kn4FI5NU_JVZFAt6p1YZxoE0RA6izwR9PDkdZU3oYiaIDVKewSO6PpWq9NQCItA28mTlbgU_9B5OR8Z-4aYQKCdNWIwvTG0f--X5iv32VUx',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: MauSala.xanhDam),
          )),
          Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                MauSala.xanhDam.withValues(alpha: .94),
                const Color(0xFF0B4F36).withValues(alpha: .88),
                const Color(0xFF003623).withValues(alpha: .96)
              ])))),
          _khung(
              maxWidth: 1440,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
                child: LayoutBuilder(builder: (context, box) {
                  final narrow = box.maxWidth < 800;
                  final intro = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nhan('HOA VIÊN SINH THÁI CHUẨN 5 SAO • 50 HECTA',
                            light: true),
                        const SizedBox(height: 20),
                        Text('Nơi An Nghỉ An Yên,\nTrọn Vẹn Đạo Hiếu Ngàn Đời',
                            style: GoogleFonts.newsreader(
                                fontSize: narrow ? 34 : 48,
                                height: 1.16,
                                color: Colors.white)),
                        const SizedBox(height: 16),
                        Text(
                            'Không gian sinh thái an nhiên, nơi gìn giữ những giá trị gia đình và kết nối các thế hệ.',
                            style: GoogleFonts.manrope(
                                fontSize: 15,
                                height: 1.8,
                                color: const Color(0xFFBAEED9))),
                        const SizedBox(height: 22),
                        Wrap(spacing: 12, runSpacing: 10, children: [
                          FilledButton.icon(
                              onPressed: () => _scroll('gioi-thieu'),
                              icon: const Icon(Icons.view_in_ar),
                              label: const Text('Khám phá hoa viên 360°'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: MauSala.vang,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16))),
                          OutlinedButton.icon(
                              onPressed: () => _scroll('tra-cuu'),
                              icon: const Icon(Icons.search),
                              label: const Text('Tra cứu phần mộ'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.all(16))),
                        ]),
                        const SizedBox(height: 26),
                        const Wrap(spacing: 36, runSpacing: 16, children: [
                          _ChiSo(value: '50 Ha', label: 'Quy hoạch sinh thái'),
                          _ChiSo(value: '100%', label: 'Sở hữu vĩnh viễn'),
                          _ChiSo(value: '35 Phút', label: 'Từ TP. Hồ Chí Minh'),
                        ]),
                      ]);
                  final event = Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: MauSala.trang,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                            top: BorderSide(color: MauSala.vang, width: 4)),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 24,
                              offset: Offset(0, 12))
                        ]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _nhan('PHẬT SỰ TRỌNG THỂ'),
                          const SizedBox(height: 12),
                          Text('Đại Lễ Cầu Siêu Vu Lan Báo Hiếu 2026',
                              style: GoogleFonts.newsreader(
                                  fontSize: 24, color: MauSala.xanhDam)),
                          const SizedBox(height: 8),
                          Text(
                              'Nghi thức truyền thống cầu nguyện quốc thái dân an, tưởng nhớ tiên linh và hồi hướng công đức gia tiên.',
                              style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: MauSala.chuPhu,
                                  height: 1.6)),
                          const SizedBox(height: 16),
                          Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: MauSala.xanhNhat,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _ChiSo(value: '18', label: 'Ngày'),
                                    _ChiSo(value: '06', label: 'Giờ'),
                                    _ChiSo(value: '42', label: 'Phút'),
                                    _ChiSo(value: '49', label: 'Giây')
                                  ])),
                          const SizedBox(height: 16),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                  onPressed: () => _showLoginMessage(context),
                                  child: const Text('Đăng ký tham dự'))),
                        ]),
                  );
                  return narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [intro, const SizedBox(height: 32), event])
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                              Expanded(flex: 7, child: intro),
                              const SizedBox(width: 48),
                              Expanded(flex: 5, child: event)
                            ]);
                }),
              )),
        ]),
      );

  Widget _loiTat() => _khung(
        maxWidth: 1440,
        child: Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(builder: (context, box) {
                  final count = box.maxWidth > 1000
                      ? 4
                      : box.maxWidth > 600
                          ? 2
                          : 1;
                  return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _loiTatCard(
                            Icons.map_outlined,
                            'Sơ Đồ 3D & Mặt Bằng',
                            'Khám phá quy hoạch 50ha và các phân khu.',
                            _openMasterMap),
                        _loiTatCard(
                            Icons.manage_search,
                            'Tra Cứu Vị Trí Mộ Phần',
                            'Tìm vị trí theo thông tin người quá cố.',
                            () => _scroll('tra-cuu')),
                        _loiTatCard(
                            Icons.filter_vintage,
                            'Dịch Vụ Chăm Sóc',
                            'Dâng hoa, thắp hương và chăm sóc mộ.',
                            () => _showLoginMessage(context)),
                        _loiTatCard(
                            Icons.auto_stories,
                            'Tưởng Niệm Trực Tuyến',
                            'Lưu giữ ký ức và lời tri ân gia đình.',
                            () => _showLoginMessage(context)),
                      ]
                          .map((w) => SizedBox(
                              width: (box.maxWidth - (count - 1) * 16) / count,
                              child: w))
                          .toList());
                }))),
      );

  Widget _sanPham() => _khung(
      maxWidth: 1440,
      child: Padding(
          key: _sanPhamKey,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _nhan('DANH MỤC BẤT ĐỘNG SẢN DƯỠNG SANH'),
            const SizedBox(height: 8),
            Text('Sản Phẩm Mộ Phần Quy Chuẩn Châu Âu',
                style: GoogleFonts.newsreader(
                    fontSize: 32, color: MauSala.xanhDam)),
            const SizedBox(height: 10),
            Text(
                'Quy hoạch đồng bộ trong không gian xanh an lành, trang nghiêm và hài hòa với thiên nhiên.',
                style:
                    GoogleFonts.manrope(fontSize: 14, color: MauSala.chuPhu)),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, box) {
              final columns = box.maxWidth >= 1050
                  ? 4
                  : box.maxWidth >= 650
                      ? 2
                      : 1;
              const items = [
                (
                  'Mộ Đơn Tiêu Chuẩn',
                  'Khu M1 - M3',
                  '4.8 m²',
                  'Khuôn viên thiền tịnh, thảm cỏ xanh và kim tĩnh nguyên khối.',
                  '180 Triệu',
                  Icons.park_outlined
                ),
                (
                  'Mộ Đôi Liền Kề Cao Cấp',
                  'Khu M2 & M4',
                  '9.6 - 12 m²',
                  'Không gian hài hòa dành cho song thân và gia đình.',
                  '390 Triệu',
                  Icons.favorite_border
                ),
                (
                  'Mộ Gia Tộc VVIP',
                  'Khu M7 - M8',
                  '48 - 295 m²',
                  'Khuôn viên gia tộc riêng biệt với cảnh quan trang trọng.',
                  '2.8 Tỷ',
                  Icons.account_balance
                ),
                (
                  'Tường Lưu Tro Cốt',
                  'Tịnh Xá Sala',
                  'Ô lưu đơn/đôi',
                  'Không gian lưu giữ trang nghiêm bên Tịnh Xá.',
                  '45 Triệu',
                  Icons.temple_buddhist
                ),
              ];
              return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: items
                      .map((item) => SizedBox(
                          width: (box.maxWidth - (columns - 1) * 18) / columns,
                          child: _sanPhamCard(item.$1, item.$2, item.$3,
                              item.$4, item.$5, item.$6)))
                      .toList());
            }),
          ])));

  Widget _traCuuSection() => Container(
      key: _traCuuKey,
      color: MauSala.xanhNenThe.withValues(alpha: .65),
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 20),
      child: _khung(
          maxWidth: 1360,
          child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: MauSala.trang,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 20,
                        offset: Offset(0, 6))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nhan('HỆ THỐNG ĐỊNH VỊ MỘ PHẦN SALA GARDEN'),
                    const SizedBox(height: 8),
                    Text('Tra Cứu Tọa Độ & Sơ Đồ Chỉ Đường',
                        style: GoogleFonts.newsreader(
                            fontSize: 28, color: MauSala.xanhDam)),
                    const SizedBox(height: 8),
                    Text(
                        'Nhập đủ thông tin để xác nhận hồ sơ. Khách chưa đăng nhập chỉ xem thông tin mộ được phép công khai và đường đi.',
                        style: GoogleFonts.manrope(
                            fontSize: 13, color: MauSala.chuPhu, height: 1.6)),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, box) {
                      final columns = box.maxWidth > 800
                          ? 4
                          : box.maxWidth > 500
                              ? 2
                              : 1;
                      final fieldWidth =
                          (box.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            _input('Họ tên người đã mất', _ten,
                                'Ví dụ: Nguyễn Văn An', fieldWidth),
                            _input('Mã phần mộ', _maMo, 'Ví dụ: M1-R05-12',
                                fieldWidth),
                            _input('Mã định danh mộ (riêng)', _maDinhDanh,
                                'Nhập mã trên hồ sơ', fieldWidth),
                            SizedBox(
                                width: fieldWidth,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Năm sinh',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: MauSala.chuPhu)),
                                      const SizedBox(height: 6),
                                      TextField(
                                          controller: _namSinh,
                                          keyboardType: TextInputType.number,
                                          decoration:
                                              _inputDecoration('Ví dụ: 1948'))
                                    ])),
                            SizedBox(
                                width: box.maxWidth,
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                        onPressed: _dangTim ? null : _traCuu,
                                        icon: _dangTim
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : const Icon(Icons.search),
                                        label: Text(_dangTim
                                            ? 'Đang tra cứu...'
                                            : 'Tìm vị trí mộ'),
                                        style: FilledButton.styleFrom(
                                            backgroundColor: MauSala.xanhDam,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 26,
                                                vertical: 16))))),
                          ]);
                    }),
                    if (_loi != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(_loi!,
                              style:
                                  const TextStyle(color: Color(0xFFBA1A1A)))),
                  ]))));

  Widget _giaTri() => _khung(
      maxWidth: 1440,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          child: Column(children: [
            _nhan('GIÁ TRỊ CỐT LÕI'),
            const SizedBox(height: 8),
            Text('Hệ Sinh Thái Hoàn Hảo & Tiêu Chuẩn Xanh',
                textAlign: TextAlign.center,
                style: GoogleFonts.newsreader(
                    fontSize: 32, color: MauSala.xanhDam)),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, box) {
              final cardWidth =
                  box.maxWidth > 900 ? (box.maxWidth - 36) / 3 : box.maxWidth;
              return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _giaTriCard(Icons.eco, 'Công Nghệ Xử Lý Ngầm Châu Âu',
                        'Gìn giữ môi trường sinh thái trong lành và bền vững.'),
                    _giaTriCard(Icons.near_me, 'Vị Trí Phong Thủy Long Mạch',
                        'Không gian an yên, kết nối thuận tiện từ TP. Hồ Chí Minh.'),
                    _giaTriCard(
                        Icons.account_balance,
                        'Tiện Ích Tang Lễ Khép Kín',
                        'Dịch vụ chu toàn trong khuôn viên Sala Garden.'),
                  ].map((w) => SizedBox(width: cardWidth, child: w)).toList());
            }),
            const SizedBox(height: 28),
            ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [MauSala.xanhDam, Color(0xFF2D6A4F)])),
                    child: const Center(
                        child: Icon(Icons.forest,
                            size: 86, color: Color(0xFFBAEED9))))),
          ])));

  Widget _danhGia() => Container(
      color: MauSala.xanhNhat,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: _khung(
          maxWidth: 1360,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nhan('SỰ TIN TƯỞNG VỮNG BỀN'),
                    const SizedBox(height: 8),
                    Text('Hàng Ngàn Gia Tộc Trao Gửi An Yên',
                        style: GoogleFonts.newsreader(
                            fontSize: 30, color: MauSala.xanhDam)),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, box) {
                      final cardWidth = box.maxWidth > 900
                          ? (box.maxWidth - 32) / 3
                          : box.maxWidth;
                      return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _danhGiaCard(
                                '“Cảnh quan thanh tịnh, dịch vụ chăm sóc chu đáo khiến gia đình tôi rất yên tâm.”',
                                'Ông Trần Trọng Tín'),
                            _danhGiaCard(
                                '“Quy trình trang nghiêm và đội ngũ nhân viên tận tâm trong những thời khắc quan trọng.”',
                                'Bà Lê Hoàng Oanh'),
                            _danhGiaCard(
                                '“Không gian xanh và quy hoạch minh bạch giúp gia đình an lòng.”',
                                'KTS. Vũ Hoàng Dũng'),
                          ]
                              .map((w) => SizedBox(width: cardWidth, child: w))
                              .toList());
                    }),
                  ]))));

  Widget _chanTrang() => Container(
      color: MauSala.xanhDam,
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      child: _khung(
          maxWidth: 1360,
          child: Wrap(spacing: 40, runSpacing: 24, children: [
            SizedBox(
                width: 250,
                child: _footerCol('SALA GARDEN',
                    'Công viên nghĩa trang sinh thái, gìn giữ đạo hiếu và an lạc muôn đời.')),
            SizedBox(
                width: 220,
                child: _footerCol('ĐỊA CHỈ & VỊ TRÍ',
                    'Tân Hiệp, Long Thành, Đồng Nai. Chỉ đường và thông tin thăm viếng.')),
            SizedBox(
                width: 220,
                child: _footerCol('QUY HOẠCH & SẢN PHẨM',
                    'Mộ đơn, mộ đôi, khu mộ gia tộc và dịch vụ hậu sự.')),
            SizedBox(
                width: 220,
                child: _footerCol('HỖ TRỢ 24/7', 'Hotline: 1900 68xx')),
          ])));

  Widget _nav(String text, VoidCallback onTap) => TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: MauSala.chuPhu)));
  Widget _khung({required double maxWidth, required Widget child}) => Center(
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: child));
  Widget _nhan(String text, {bool light = false}) => Text(text,
      style: TextStyle(
          color: light ? const Color(0xFFFFDEA5) : MauSala.vang,
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700));
  Widget _input(String label, TextEditingController controller, String hint,
          double width) =>
      SizedBox(
          width: width,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MauSala.chuPhu)),
            const SizedBox(height: 6),
            TextField(
                controller: controller, decoration: _inputDecoration(hint))
          ]));
  InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: MauSala.nen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: MauSala.vien)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: MauSala.vien)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: MauSala.xanhThe, width: 2)));

  Widget _loiTatCard(
          IconData icon, String title, String body, VoidCallback onTap) =>
      Card(
          color: Colors.white,
          elevation: 2,
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                            backgroundColor: MauSala.xanhNhat,
                            child: Icon(icon, color: MauSala.xanhDam)),
                        const SizedBox(height: 12),
                        Text(title,
                            style: GoogleFonts.newsreader(
                                fontSize: 19, color: MauSala.xanhDam)),
                        const SizedBox(height: 6),
                        Text(body,
                            style: GoogleFonts.manrope(
                                fontSize: 12, color: MauSala.chuPhu)),
                        const SizedBox(height: 12),
                        const Text('Khám phá →',
                            style: TextStyle(
                                color: MauSala.xanhThe,
                                fontWeight: FontWeight.w700,
                                fontSize: 11))
                      ]))));
  Widget _sanPhamCard(String title, String zone, String area,
          String description, String price, IconData icon) =>
      Card(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                height: 140,
                width: double.infinity,
                color: MauSala.xanhNhat,
                child: Icon(icon, size: 54, color: MauSala.xanhThe)),
            Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _nhan(zone),
                      const SizedBox(height: 6),
                      Text(title,
                          style: GoogleFonts.newsreader(
                              fontSize: 21, color: MauSala.xanhDam)),
                      Text(area,
                          style: const TextStyle(
                              color: MauSala.vang,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(description,
                          style: GoogleFonts.manrope(
                              fontSize: 12,
                              height: 1.5,
                              color: MauSala.chuPhu)),
                      const SizedBox(height: 14),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Từ $price',
                                style: const TextStyle(
                                    color: MauSala.vang,
                                    fontWeight: FontWeight.bold)),
                            TextButton(
                                onPressed: () => _showLoginMessage(context),
                                child: const Text('Chi tiết'))
                          ])
                    ]))
          ]));
  Widget _giaTriCard(IconData icon, String title, String body) => Card(
      color: Colors.white,
      child: Padding(
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: MauSala.xanhThe, size: 30),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.newsreader(
                    fontSize: 20, color: MauSala.xanhDam)),
            const SizedBox(height: 8),
            Text(body,
                style: GoogleFonts.manrope(
                    fontSize: 12, height: 1.6, color: MauSala.chuPhu))
          ])));
  Widget _danhGiaCard(String quote, String name) => Card(
      color: Colors.white,
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('★★★★★',
                style: TextStyle(color: MauSala.vang, letterSpacing: 3)),
            const SizedBox(height: 12),
            Text(quote,
                style: GoogleFonts.manrope(
                    fontSize: 13,
                    height: 1.6,
                    color: MauSala.chuPhu,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(
                    color: MauSala.xanhDam, fontWeight: FontWeight.w700))
          ])));
  Widget _footerCol(String title, String text) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFFFDEA5),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        Text(text,
            style: const TextStyle(
                color: Color(0xFFBAEED9), fontSize: 12, height: 1.6))
      ]);
  void _scroll(String key) {
    final target = key == 'tra-cuu'
        ? _traCuuKey.currentContext
        : key == 'san-pham'
            ? _sanPhamKey.currentContext
            : null;
    if (target != null) {
      Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    } else if (key == 'gioi-thieu' && _scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    }
  }

  void _showLoginMessage(BuildContext context) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const AuthLoginScreen()));

  void _openMasterMap() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => Scaffold(
                backgroundColor: MauSala.nen,
                appBar: AppBar(
                    title: const Text('Sơ đồ tổng thể Sala Garden'),
                    backgroundColor: Colors.white,
                    foregroundColor: MauSala.xanhDam),
                body: SoDoTongQuan(
                    viewer: SoDoViewer.khachVangLai,
                    onLogin: () => _showLoginMessage(context)),
              )));
}

class _ChiSo extends StatelessWidget {
  const _ChiSo({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: GoogleFonts.newsreader(fontSize: 22, color: MauSala.vang)),
        Text(label,
            style: GoogleFonts.manrope(fontSize: 10, color: MauSala.chuPhu))
      ]);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/mausala.dart';
import '../auth_login_screen.dart';
import '../sodotongquan.dart';

class TrangChuScreen extends StatefulWidget {
  const TrangChuScreen({super.key});

  @override
  State<TrangChuScreen> createState() => _TrangChuScreenState();
}

class _TrangChuScreenState extends State<TrangChuScreen> {
  final _scrollController = ScrollController();
  final _gioiThieuKey = GlobalKey();
  final _sanPhamKey = GlobalKey();
  final _dichVuKey = GlobalKey();
  final _thamQuanKey = GlobalKey();
  final _lienHeKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 650), curve: Curves.easeInOut);
    }
  }

  void _openMap() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SoDoTongQuan(viewer: SoDoViewer.khachVangLai),
        ),
      );

  void _openLogin() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthLoginScreen()),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfffdf9f1),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _topBar()),
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xfffffdfa),
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 78,
              titleSpacing: 0,
              title: _container(_navigation()),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _hero(),
                  _location(),
                  KeyedSubtree(key: _gioiThieuKey, child: _amenities()),
                  KeyedSubtree(key: _dichVuKey, child: _services()),
                  KeyedSubtree(key: _sanPhamKey, child: _products()),
                  KeyedSubtree(key: _thamQuanKey, child: _tour()),
                  _testimonials(),
                  _news(),
                  KeyedSubtree(key: _lienHeKey, child: _consultation()),
                  _footer(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _container(Widget child, {double maxWidth = 1360}) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
        ),
      );

  Widget _topBar() => Container(
        color: const Color(0xff1c1c17),
        child: _container(Row(
          children: [
            const Icon(Icons.call_outlined, color: Color(0xffffdea6), size: 15),
            const SizedBox(width: 7),
            const Text('Hotline 24/7: 0971.66.66.16',
                style: TextStyle(color: Colors.white, fontSize: 11)),
            const SizedBox(width: 20),
            const Icon(Icons.location_on_outlined,
                color: Color(0xffffdea6), size: 15),
            const SizedBox(width: 5),
            const Expanded(
              child: Text('Long Thành, Đồng Nai (35 phút từ TP.HCM)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xfff4f0e8), fontSize: 11)),
            ),
            TextButton.icon(
              onPressed: () => _scroll(_thamQuanKey),
              icon: const Icon(Icons.threesixty, size: 17),
              label: const Text('Tham quan Online 360°'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffffdea6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        )),
      );

  Widget _navigation() => LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 950;
        return Row(children: [
          const Icon(Icons.spa, color: Color(0xff785600), size: 30),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SALA GARDEN',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff1c1c17))),
            const Text('HOA VIÊN SINH THÁI 5 SAO',
                style: TextStyle(
                    color: Color(0xff785600),
                    fontSize: 8,
                    letterSpacing: 1.15,
                    fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          if (!compact)
            ...[
              _nav('Trang chủ', () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500), curve: Curves.easeOut)),
              _nav('Giới thiệu', () => _scroll(_gioiThieuKey)),
              _nav('Sản phẩm', () => _scroll(_sanPhamKey)),
              _nav('Dịch vụ', () => _scroll(_dichVuKey)),
              _nav('Tiện ích', () => _scroll(_gioiThieuKey)),
              _nav('Tham quan online', () => _scroll(_thamQuanKey)),
              _nav('Tin tức', () => _scroll(_thamQuanKey)),
              _nav('Liên hệ', () => _scroll(_lienHeKey)),
            ]
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Color(0xff785600)),
              onSelected: (value) {
                final targets = {
                  'Giới thiệu': _gioiThieuKey,
                  'Sản phẩm': _sanPhamKey,
                  'Dịch vụ': _dichVuKey,
                  'Tham quan online': _thamQuanKey,
                  'Liên hệ': _lienHeKey,
                };
                _scroll(targets[value] ?? _gioiThieuKey);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Giới thiệu', child: Text('Giới thiệu')),
                PopupMenuItem(value: 'Sản phẩm', child: Text('Sản phẩm')),
                PopupMenuItem(value: 'Dịch vụ', child: Text('Dịch vụ')),
                PopupMenuItem(value: 'Tham quan online', child: Text('Tham quan online')),
                PopupMenuItem(value: 'Liên hệ', child: Text('Liên hệ')),
              ],
            ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _openLogin,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff785600),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            icon: const Icon(Icons.account_circle_outlined, size: 18),
            label: const Text('Đăng nhập'),
          ),
        ]);
      });

  Widget _nav(String label, VoidCallback onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
            foregroundColor: const Color(0xff1c1c17),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        child: Text(label),
      );

  Widget _hero() => Container(
        height: 670,
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/trangchu/trangchu.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xc91a1714), Color(0x661a1714), Color(0x181a1714)]),
          ),
          child: _container(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _eyebrow('Hoa Viên Sinh Thái 5 Sao Đẳng Cấp Hoàng Gia', light: true),
              const SizedBox(height: 17),
              SizedBox(
                width: 790,
                child: Text('HOA VIÊN NGHĨA TRANG SINH THÁI SALA GARDEN',
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 54,
                        height: 1.12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 680,
                child: Text('“Miền Cực Lạc An Yên Giữa Miền Xanh Sinh Thái – Nơi Gìn Giữ Đạo Hiếu Và Phụng Sự Muôn Đời”',
                    style: GoogleFonts.playfairDisplay(
                        color: const Color(0xffffdea6), fontSize: 22, height: 1.45)),
              ),
              const SizedBox(height: 28),
              Wrap(spacing: 13, runSpacing: 13, children: [
                _heroMetric('35', 'Phút', 'Từ Trung tâm TP.HCM\nCao tốc Long Thành - Dầu Giây'),
                _heroMetric('10', 'Phút', 'Sân bay Quốc tế Long Thành\nKết nối giao thương tương lai'),
                _heroMetric('Tiêu Chuẩn', 'Công Nghệ Châu Âu', 'Kim tĩnh ngầm, không ô nhiễm'),
                _heroMetric('100%', 'Sổ Hồng Vĩnh Viễn', 'Pháp lý minh bạch hoàn chỉnh'),
              ]),
              const SizedBox(height: 28),
              Wrap(spacing: 12, runSpacing: 12, children: [
                FilledButton.icon(
                  onPressed: () => _scroll(_thamQuanKey),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffb8860b),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                  icon: const Icon(Icons.threesixty),
                  label: const Text('Khám Phá VR Tour 360° Trực Tuyến'),
                ),
                OutlinedButton.icon(
                  onPressed: _openMap,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xffffdea6)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Xem Sơ Đồ Mộ Phần'),
                ),
              ]),
            ],
          )),
        ),
      );

  Widget _heroMetric(String first, String second, String detail) => Container(
        width: 182,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: const Color(0x22ffffff),
            border: Border.all(color: const Color(0x66ffdea6)),
            borderRadius: BorderRadius.circular(4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(
              text: TextSpan(children: [
            TextSpan(text: first, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700)),
            TextSpan(text: ' $second', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ])),
          const SizedBox(height: 5),
          Text(detail, style: const TextStyle(fontSize: 9, height: 1.35)),
        ]),
      );

  Widget _location() => Container(
        color: const Color(0xfff1ede6),
        padding: const EdgeInsets.symmetric(vertical: 82),
        child: _container(LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 850;
          final description = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _eyebrow('Địa Linh Vượng Khí • Đắc Địa Trường Lưu'),
            const SizedBox(height: 12),
            _title('Vị Trí Phong Thủy Độc Tôn\nÔm Trọn Bởi Vành Đai Tâm Linh Trăm Năm'),
            const SizedBox(height: 17),
            const Text('Tọa lạc tại xã Phước Thái, huyện Long Thành, tỉnh Đồng Nai, Sala Garden ngự trị trên vùng đất cao ráo, thoai thoải hình mai rùa – thế đất “Huyệt Cát” tụ hội linh khí trời đất mang đến sự an nghỉ an lạc vĩnh hằng cho người đã khuất và phước trạch muôn đời cho hậu thế.', style: TextStyle(color: Color(0xff4f4535), height: 1.65)),
            const SizedBox(height: 22),
            _feature(Icons.temple_buddhist, 'Thiền Viện Thường Chiếu', 'Trung tâm thiền phái Trúc Lâm uy nghiêm, hộ trì vượng khí an hòa.'),
            _feature(Icons.church_outlined, 'Giáo Xứ Hiền Hòa', 'Cộng đồng đức tin trang trọng, phù hộ bình an và sự bao dung.'),
            _feature(Icons.commute_outlined, 'Kết Nối Siêu Tốc', 'Chỉ 35 phút lái xe thuận lợi, lộ trình thông thoáng không kẹt xe.'),
            const SizedBox(height: 13),
            TextButton.icon(onPressed: _openMap, icon: const Icon(Icons.near_me), label: const Text('Xem Lộ Trình Di Chuyển Trên Google Maps →')),
          ]);
          final image = ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/images/trangchu/nennhangyenlong.jpg', height: narrow ? 290 : 490, width: double.infinity, fit: BoxFit.cover));
          return narrow ? Column(children: [description, const SizedBox(height: 30), image]) : Row(children: [Expanded(flex: 11, child: description), const SizedBox(width: 50), Expanded(flex: 9, child: image)]);
        })),
      );

  Widget _feature(IconData icon, String title, String detail) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xff785600), size: 23),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xff4f4535), height: 1.4))]))
        ]),
      );

  Widget _amenities() => _section(
        heading: 'Khuôn Viên 50 Ha Hệ Sinh Thái Toàn Diện',
        label: 'Tiện Ích 5 Sao Bậc Nhất Việt Nam',
        description: 'Sala Garden không chỉ là nơi an nghỉ, mà còn là công viên sinh thái thanh tịnh để gia đình sum vầy, tưởng nhớ và thanh lọc tâm hồn.',
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth > 950 ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth > 620 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
          final items = [
            ('dendinhtrangnghiem.jpg', 'Đền Trình Trang Nghiêm', 'Nơi đón tiếp và dâng hương kính cáo các vị chư Phật, chư Thần linh trước khi tổ chức nghi lễ.'),
            ('quangtruong.jpg', 'Tịnh Xá Sala & Quảng Trường', 'Nơi chủ trì các Đại lễ tâm linh thường niên tầm cỡ quốc gia.'),
            ('hotinhtam.jpg', 'Hồ Tịnh Tâm & Đồi Tự Tại', 'Mặt nước phẳng lặng như gương, điều hòa vi khí hậu mát mẻ.'),
            ('hoatanglacvien.jpg', 'Hỏa Táng Hòa Lạc Viên (TABO)', 'Công nghệ hỏa táng TABO từ Thụy Điển: không khói, không mùi.'),
            ('lutrutrocot.jpg', 'Tường Lưu Tro Cốt Zen', 'Không gian lưu giữ tro cốt ấm cúng, trang trọng và bảo dưỡng định kỳ.'),
            ('anhxedien.png', 'Hệ Thống Nhà Chờ & Xe Điện', 'Xe điện nội khu êm ái, nhà hàng phục vụ gia quyến chu đáo.'),
          ];
          return Wrap(spacing: 16, runSpacing: 16, children: [for (final item in items) SizedBox(width: width, child: _imageCard(item.$1, item.$2, item.$3))]);
        }),
      );

  Widget _services() => Container(
        color: const Color(0xff1c1c17),
        padding: const EdgeInsets.symmetric(vertical: 84),
        child: _container(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _eyebrow('Tận Tâm • Chu Toàn • Chuyên Nghiệp', light: true),
          const SizedBox(height: 12),
          _title('Quản Lý & Vận Hành\nTiêu Chuẩn Quốc Tế', light: true),
          const SizedBox(height: 15),
          const SizedBox(width: 760, child: Text('Sala Garden được cố vấn vận hành trực tiếp bởi các tập đoàn nghĩa trang sinh thái hàng đầu đến từ Đài Loan, Malaysia và Nhật Bản. Chúng tôi đảm bảo mọi quy trình chăm sóc và tổ chức diễn ra trang nghiêm, văn minh và tận tâm nhất.', style: TextStyle(color: Color(0xffe6e2da), height: 1.65))),
          const SizedBox(height: 32),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth > 850 ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth > 530 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
            final services = [
              (Icons.verified_user_outlined, 'Cam Kết Chăm Sóc Vĩnh Viễn', 'Hương khói, tỉa cây hoa, dọn dẹp sạch sẽ vào mỗi ngày mùng 1 và ngày rằm hàng tháng.'),
              (Icons.diversity_1_outlined, 'Tư Vấn & Tang Lễ Trọn Gói', 'Thực hiện chuẩn mực theo mọi tín ngưỡng: Phật giáo, Công giáo, Tin lành.'),
              (Icons.local_florist_outlined, 'Mai Táng & Hỏa Táng Văn Minh', 'Áp dụng công nghệ xử lý vi sinh Châu Âu khép kín, bảo vệ nguồn nước ngầm.'),
              (Icons.yard_outlined, 'Bảo Dưỡng Cảnh Quan 24/7', 'Đội ngũ nghệ nhân duy trì thảm cỏ xanh mướt quanh năm như khu nghỉ dưỡng.'),
              (Icons.self_improvement_outlined, 'Tổ Chức Nghi Lễ Tâm Linh', 'Tổ chức cúng cơm, tụng kinh hồi hướng công đức, cầu siêu định kỳ.'),
              (Icons.support_agent_outlined, 'Hỗ Trợ Gia Quyến 24/7', 'Tổng đài tư vấn và đội ngũ chăm sóc luôn đồng hành cùng gia đình.'),
            ];
            return Wrap(spacing: 16, runSpacing: 16, children: [for (final item in services) SizedBox(width: width, child: _darkFeature(item.$1, item.$2, item.$3))]);
          }),
        ])),
      );

  Widget _darkFeature(IconData icon, String title, String detail) => Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(border: Border.all(color: const Color(0x66c5a880))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xffffdea6), size: 31), const SizedBox(height: 14),
          Text(title, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8), Text(detail, style: const TextStyle(color: Color(0xffd3c4af), fontSize: 12, height: 1.55)),
        ]),
      );

  Widget _products() => _section(
        label: 'Tuyệt Tác Trường Tồn',
        heading: 'Sản Phẩm Mộ Phần Sinh Thái',
        description: 'Quy hoạch đồng bộ theo tiêu chuẩn resort cao cấp. Hệ thống kim tĩnh đúc sẵn bê tông công nghệ Châu Âu, bao bọc bởi thảm cỏ nhung Nhật Bản và hoa lá bốn mùa ngát hương.',
        child: Column(children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final code in ['M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8']) _zoneChip(code)])),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth > 960 ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth > 620 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
            final products = [
              ('Mo-don.jpg', 'Tiêu Chuẩn Châu Âu', 'Mộ Đơn & Mộ Đôi Tiểu Cảnh', 'Diện tích: 4.5m² – 9m²\nQuy cách: 1 – 2 Huyệt Mộ'),
              ('Mo-gia-toc-48m.jpg', 'Khu Vực An Nhiên', 'Mộ Gia Tộc 48m² (Đoàn Viên)', 'Diện tích khuôn viên: 48m²\nSức chứa: 8 Huyệt Mộ Tiêu Chuẩn'),
              ('Mo-gia-toc-100m.jpg', 'Cổng Tam Quan Riêng Biệt', 'Mộ Gia Tộc 100m² (Vinh Hoa)', 'Diện tích: 95m² – 159m²\nSức chứa: 12 – 16 Huyệt Mộ'),
              ('Mo-gia-toc-200m.jpg', 'Tuyệt Tác Gia Tộc', 'Mộ Gia Tộc Đại Phát 200m²', 'Diện tích: 195m² – 259m²\nĐặc quyền: KTS quốc tế thiết kế riêng'),
              ('Mo-xong-than.jpg', 'Món Quà Hiếu Đạo', 'Mộ Song Thân Hiếu Đạo', 'Ý nghĩa: Bách niên giai lão\nDịch vụ: Chăm sóc hương khói vĩnh cửu'),
              ('monhatbanhoa.png', 'Đa Dạng Tín Ngưỡng', 'Mộ Nhật Bản & Mộ Người Hoa', 'Thiết kế: Đúng chuẩn văn hóa & tâm linh\nVị trí: Phân khu biệt lập tĩnh tại'),
            ];
            return Wrap(spacing: 16, runSpacing: 16, children: [for (final product in products) SizedBox(width: width, child: _productCard(product.$1, product.$2, product.$3, product.$4))]);
          }),
          const SizedBox(height: 30),
          FilledButton.icon(onPressed: _openMap, icon: const Icon(Icons.grid_view_rounded), label: const Text('Xem Sơ Đồ Mộ Phần & Vị Trí Còn Trống'), style: FilledButton.styleFrom(backgroundColor: const Color(0xff785600), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
        ]),
      );

  Widget _zoneChip(String code) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: OutlinedButton(onPressed: _openMap, child: Text(code)),
      );

  Widget _productCard(String image, String label, String title, String detail) => Container(
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 1.42, child: Image.asset('assets/images/trangchu/$image', fit: BoxFit.cover)),
          Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _eyebrow(label), const SizedBox(height: 7),
            Text(title, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600)), const SizedBox(height: 9),
            Text(detail, style: const TextStyle(fontSize: 12, height: 1.55, color: Color(0xff4f4535))), const SizedBox(height: 13),
            TextButton(onPressed: _openMap, child: const Text('Xem vị trí trên sơ đồ →')),
          ])),
        ]),
      );

  Widget _tour() => Container(
        color: const Color(0xfff1ede6),
        padding: const EdgeInsets.symmetric(vertical: 82),
        child: _container(LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 820;
          final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _eyebrow('Tham Quan Sala Garden Online'), const SizedBox(height: 12),
            _title('Trải Nghiệm Góc Nhìn Thực Tế Toàn Cảnh 360°'), const SizedBox(height: 14),
            const Text('Trải nghiệm góc nhìn thực tế toàn cảnh 360 độ từ trên cao với đầy đủ các vị trí tiện ích tâm linh, hồ cảnh quan và hệ thống phân khu sinh thái.', style: TextStyle(height: 1.65, color: Color(0xff4f4535))), const SizedBox(height: 20),
            const Wrap(spacing: 8, runSpacing: 8, children: [Chip(label: Text('8 Phân khu Mộ (M1 - M8)')), Chip(label: Text('Đền Trình & Nhà Tang Lễ')), Chip(label: Text('Hồ Cảnh Quan & Hồ Tịnh Tâm'))]), const SizedBox(height: 22),
            FilledButton.icon(onPressed: _openMap, icon: const Icon(Icons.view_in_ar), label: const Text('Khám Phá Ngay Tour VR 360°'), style: FilledButton.styleFrom(backgroundColor: const Color(0xff785600), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))),
          ]);
          final image = ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(fit: StackFit.expand, children: [Image.asset('assets/images/trangchu/thamquan.jpg', fit: BoxFit.cover), const ColoredBox(color: Color(0x331a1714)), const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 76))]));
          return narrow ? Column(children: [text, const SizedBox(height: 30), SizedBox(height: 300, child: image)]) : Row(children: [Expanded(child: text), const SizedBox(width: 48), Expanded(child: SizedBox(height: 390, child: image))]);
        })),
      );

  Widget _testimonials() => _section(
        label: 'Niềm Tin Trọn Vẹn', heading: 'Khách Hàng & Báo Chí Nói Về Chúng Tôi', description: 'Bằng tất cả sự trân trọng và biết ơn, đội ngũ Sala Garden luôn nỗ lực gìn giữ trọn vẹn sự an yên cho mỗi gia đình trao gửi niềm tin.',
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth > 950 ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth > 610 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
          final quotes = [
            ('HP', '“Nghĩa trang Hoa Viên Sala Garden rất ấn tượng với gia đình tôi. Dự án uy tín, thi công đúng tiến độ. Chăm sóc bảo dưỡng phần mộ cảnh quan rất tốt.”', 'Hương Phạm • Khách hàng Mộ Gia Tộc • TP. Hồ Chí Minh'),
            ('NH', '“Dịch vụ tại mộ phần chu đáo, tận tình từng chút từ hạ huyệt, cúng chay tang tại nghĩa trang đều được Sala giúp chu đáo.”', 'Nguyễn Phú Hân • Khách hàng Mộ Đôi • Đồng Nai'),
            ('NM', '“Tôi rất hài lòng với dịch vụ tận tâm của Sala Garden. Từ quy trình tiếp đón đến công tác hỗ trợ phong thủy đều rất chuẩn mực.”', 'Nguyễn Đại Mạc • Khách hàng Mộ Song Thân'),
          ];
          return Wrap(spacing: 16, runSpacing: 16, children: [for (final quote in quotes) SizedBox(width: width, child: _quoteCard(quote.$1, quote.$2, quote.$3))]);
        }),
      );

  Widget _quoteCard(String initials, String quote, String author) => Container(
        padding: const EdgeInsets.all(23), decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.format_quote, color: Color(0xffb8860b), size: 36), Text(quote, style: GoogleFonts.playfairDisplay(fontSize: 18, height: 1.55)), const SizedBox(height: 19), Row(children: [CircleAvatar(backgroundColor: const Color(0xfff1ede6), child: Text(initials, style: const TextStyle(color: Color(0xff785600), fontWeight: FontWeight.bold))), const SizedBox(width: 10), Expanded(child: Text(author, style: const TextStyle(fontSize: 11, color: Color(0xff4f4535), height: 1.4)))])]),
      );

  Widget _news() => Container(
        color: const Color(0xfff7f3eb), padding: const EdgeInsets.symmetric(vertical: 82),
        child: _container(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _eyebrow('Góc Tri Thức & Hoạt Động'), const SizedBox(height: 11), _title('Bản Tin & Cẩm Nang Tâm Linh'), const SizedBox(height: 26),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth > 950 ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth > 610 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(width: width, child: _newsCard('vu_lan_mua_hieu_hanh.jpg', 'Sự Kiện Tâm Linh', 'Đại Lễ Vu Lan Báo Hiếu Tại Sala Garden: Lan Tỏa Hạnh Hiếu Đạo', '24/08/2023 • Vườn Sala')),
              SizedBox(width: width, child: _newsCard('conemuatruocdat.jpg', 'Thường Thức Đời Sống', 'Nén Nhang Yên Lòng: Ý Nghĩa Ngày Tảo Mộ Cuối Năm', '02/02/2023 • Vườn Sala')),
              SizedBox(width: width, child: _newsCard('sanphammosinhthai.png', 'Cẩm Nang Phong Thủy', 'Có Nên Mua Trước Đất Sinh Phần Cho Người Còn Sống?', '01/09/2022 • Vườn Sala')),
            ]);
          }),
        ])),
      );

  Widget _newsCard(String image, String label, String title, String date) => Container(
        decoration: _cardDecoration(), clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AspectRatio(aspectRatio: 1.7, child: Image.asset('assets/images/trangchu/$image', fit: BoxFit.cover)), Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_eyebrow(label), const SizedBox(height: 7), Text(title, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3)), const SizedBox(height: 10), Text(date, style: const TextStyle(fontSize: 11, color: Color(0xff725b38))), const SizedBox(height: 6), TextButton(onPressed: () {}, child: const Text('Đọc tiếp →'))]))]),
      );

  Widget _consultation() => Container(
        color: const Color(0xff1c1c17), padding: const EdgeInsets.symmetric(vertical: 84),
        child: _container(LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 840;
          final information = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _eyebrow('Đặc Quyền Khách Hàng', light: true), const SizedBox(height: 12), _title('Đăng Ký Tư Vấn & Xếp Lịch Tham Quan Miễn Phí', light: true), const SizedBox(height: 16), const Text('Sala Garden luôn sẵn sàng hỗ trợ xe đưa đón tận nơi hoàn toàn miễn phí xuất phát từ trung tâm TP. Hồ Chí Minh và xe điện đưa rước thăm viếng tiện nghi trong nội khu hoa viên.', style: TextStyle(color: Color(0xffe6e2da), height: 1.65)), const SizedBox(height: 22),
            _contactBenefit(Icons.directions_car_outlined, 'Xe đưa đón TP.HCM – Sala Garden miễn phí 100%'), _contactBenefit(Icons.menu_book_outlined, 'Tặng ấn phẩm cẩm nang chọn huyệt mộ phong thủy'), _contactBenefit(Icons.restaurant_outlined, 'Phục vụ trà đạo và tiệc chay thanh đạm khi ghé thăm'), const SizedBox(height: 20), const Text('Tư Vấn Trực Tiếp 24/7\n0971.66.66.16', style: TextStyle(color: Color(0xffffdea6), fontSize: 20, fontWeight: FontWeight.w700, height: 1.4)),
          ]);
          final form = _form();
          return narrow ? Column(children: [information, const SizedBox(height: 30), form]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: information), const SizedBox(width: 60), Expanded(child: form)]);
        })),
      );

  Widget _contactBenefit(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(children: [Icon(icon, color: const Color(0xffffdea6), size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Color(0xfff4f0e8), fontSize: 12)))]));

  Widget _form() => Container(
        padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xfffffdfa), borderRadius: BorderRadius.circular(6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Để Lại Thông Tin', style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w600)), const SizedBox(height: 5), const Text('Đội ngũ chuyên viên Sala Garden sẽ liên hệ trong thời gian sớm nhất.', style: TextStyle(fontSize: 11, color: Color(0xff4f4535))), const SizedBox(height: 18),
          _input('Họ và tên Quý khách *'), _input('Số điện thoại liên hệ *'), _input('Địa chỉ Email'), _input('Ngày dự kiến tham quan', icon: Icons.calendar_today_outlined), _input('Sản phẩm mộ phần quan tâm *', icon: Icons.expand_more), _input('Nhu cầu phong thủy / Lời nhắn thêm', lines: 3), const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('Gửi Thông Tin & Nhận Báo Giá Chi Tiết'), style: FilledButton.styleFrom(backgroundColor: const Color(0xff785600), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))))), const SizedBox(height: 10), const Text('* Cam kết bảo mật thông tin cá nhân khách hàng tuyệt đối 100%.', style: TextStyle(fontSize: 10, color: Color(0xff725b38))),
        ]),
      );

  Widget _input(String hint, {IconData? icon, int lines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 11), child: TextField(maxLines: lines, decoration: InputDecoration(hintText: hint, suffixIcon: icon == null ? null : Icon(icon, size: 18), hintStyle: const TextStyle(fontSize: 12, color: Color(0xff725b38)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: const BorderSide(color: Color(0xffc5a880))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: const BorderSide(color: Color(0xffd3c4af))))));

  Widget _footer() => Container(
        color: const Color(0xff12120f), padding: const EdgeInsets.symmetric(vertical: 54),
        child: _container(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth > 850 ? (constraints.maxWidth - 72) / 4 : constraints.maxWidth > 520 ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
            return Wrap(spacing: 24, runSpacing: 28, children: [
              SizedBox(width: width, child: _footerIntro()), SizedBox(width: width, child: _footerColumn('Hệ Thống Văn Phòng', ['Phòng Kinh Doanh Long Thành', 'Tổ 1, Ấp 1, Xã Phước Thái, Long Thành, Đồng Nai', '0971.66.66.16'])), SizedBox(width: width, child: _footerColumn('Thông Tin Chung', ['Giới thiệu', 'Sản phẩm & Bảng giá', 'Dịch vụ tang lễ & hoả táng', 'Tiện ích hoa viên', 'Tham quan online 360°', 'Tin tức & Sự kiện'])), SizedBox(width: width, child: _footerColumn('Kết Nối Với Chúng Tôi', ['Facebook', 'Zalo', 'YouTube', 'Hotline 24/7: 0971.66.66.16'])),
            ]);
          }),
          const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Divider(color: Color(0x44c5a880))),
          const Text('© 2024 Sala Garden. Bản quyền thuộc về Công ty CP Sala Garden. Hoa viên nghĩa trang sinh thái 5 sao hàng đầu Việt Nam.', style: TextStyle(color: Color(0xffd3c4af), fontSize: 10)),
        ])),
      );

  Widget _footerIntro() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.spa, color: Color(0xffffdea6), size: 32), const SizedBox(height: 10), Text('SALA GARDEN', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)), const SizedBox(height: 9), const Text('Hoa viên nghĩa trang sinh thái 5 sao hàng đầu Việt Nam. Nơi tôn vinh nét đẹp văn hóa hiếu đạo, gìn giữ ký ức gia tộc muôn đời.', style: TextStyle(color: Color(0xffd3c4af), fontSize: 11, height: 1.6))]);

  Widget _footerColumn(String title, List<String> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: const TextStyle(color: Color(0xffffdea6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(height: 13), for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(item, style: const TextStyle(color: Color(0xffd3c4af), fontSize: 11, height: 1.35)))]);

  Widget _imageCard(String image, String title, String detail) => Container(decoration: _cardDecoration(), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AspectRatio(aspectRatio: 1.55, child: Image.asset('assets/images/trangchu/$image', fit: BoxFit.cover)), Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.playfairDisplay(fontSize: 21, fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(detail, style: const TextStyle(fontSize: 12, height: 1.55, color: Color(0xff4f4535)))]))]));

  Widget _section({required String label, required String heading, required String description, required Widget child}) => Padding(padding: const EdgeInsets.symmetric(vertical: 83), child: _container(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_eyebrow(label), const SizedBox(height: 10), _title(heading), const SizedBox(height: 12), SizedBox(width: 780, child: Text(description, style: const TextStyle(color: Color(0xff4f4535), height: 1.65))), const SizedBox(height: 31), child])));

  Widget _eyebrow(String text, {bool light = false}) => Text(text.toUpperCase(), style: TextStyle(color: light ? const Color(0xffffdea6) : const Color(0xff785600), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3));
  Widget _title(String text, {bool light = false}) => Text(text, style: GoogleFonts.playfairDisplay(color: light ? Colors.white : const Color(0xff1c1c17), fontSize: 40, height: 1.17, fontWeight: FontWeight.w600));
  BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0x66c5a880)), borderRadius: BorderRadius.circular(5));
}

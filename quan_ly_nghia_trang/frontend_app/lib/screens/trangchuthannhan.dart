import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_service.dart';
import '../core/mausala.dart';
import 'chamsocmophan.dart';
import 'chiduongthannhan.dart';
import 'sodotongquan.dart';
import 'dichvutangledat.dart';
import 'hopdongthannhan.dart';
import 'tuongniemonline.dart';
import 'trangchukhachvanglai.dart';

class TrangChuThanNhan extends StatefulWidget {
  const TrangChuThanNhan({super.key});

  @override
  State<TrangChuThanNhan> createState() => _TrangChuThanNhanState();
}

class _TrangChuThanNhanState extends State<TrangChuThanNhan> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Map<String, dynamic>? _user;
  Map<String, dynamic> _summary = {};
  List<dynamic> _contracts = [];
  List<dynamic> _careOrders = [];
  Map<String, dynamic>? _contractDraftPlot;
  bool _loading = true;
  String? _error;
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await ApiService.instance.get('/auth/me');
      final user = Map<String, dynamic>.from(me['user'] as Map);
      final id = user['id'];
      final results = await Future.wait([
        ApiService.instance.get('/customer/dashboard-summary'),
        ApiService.instance.get('/contracts/customer/$id'),
        ApiService.instance.get('/care-orders'),
      ]);
      if (!mounted) return;
      setState(() {
        _user = user;
        _summary = Map<String, dynamic>.from(results[0]['data'] as Map);
        _contracts = List<dynamic>.from(results[1]['data'] as List);
        _careOrders = List<dynamic>.from(results[2]['data'] as List);
      });
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final sidebar = _sidebar(wide: wide);
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: MauSala.nen,
        drawer: wide ? null : Drawer(child: SafeArea(child: sidebar)),
        body: wide
            ? Column(children: [
                _topBar(compact: false),
                Expanded(
                    child: Row(children: [
                  sidebar,
                  Expanded(child: _selectedContent()),
                ])),
              ])
            : Column(children: [
                _topBar(compact: true),
                Expanded(child: _selectedContent()),
              ]),
      );
    });
  }

  Widget _selectedContent() {
    if (_selectedNav == 1) {
      return SoDoTongQuan(
        viewer: SoDoViewer.thanNhan,
        linkedPlots: _contracts
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        onCreateContract: _openContractForPlot,
      );
    }
    if (_selectedNav == 2) {
      return HopDongThanNhan(
        contracts: _contracts,
        user: _user,
        loading: _loading,
        error: _error,
        onRefresh: _load,
        onChoosePlot: () => setState(() => _selectedNav = 1),
        initialPlot: _contractDraftPlot,
        onContractCreated: _contractCreated,
        onCancelDraft: _cancelContractDraft,
      );
    }
    if (_selectedNav == 3) {
      return DichVuTangLeDat(fullName: _user?['full_name']?.toString());
    }
    if (_selectedNav == 4) {
      return ChamSocMoPhan(
        contracts: _contracts,
        orders: _careOrders,
        onRefresh: _load,
        onOpenContracts: _showContracts,
      );
    }
    if (_selectedNav == 5) {
      return TuongNiemOnline(
        fullName: _user?['full_name']?.toString(),
        onOpenContracts: _showContracts,
      );
    }
    if (_selectedNav == 6) {
      return ChiDuongThanNhan(
        contracts: _contracts,
        onOpenContracts: _showContracts,
        onOpenCare: _showCareOrders,
      );
    }
    return _dashboardBody();
  }

  Widget _topBar({required bool compact}) => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5EDF4))),
        ),
        child: Row(children: [
          if (compact)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.menu, color: MauSala.xanhDam),
            ),
          Transform.translate(
            offset: const Offset(0, 4),
            child: const _Logo(compact: true),
          ),
          if (!compact) const SizedBox(width: 24),
          if (!compact)
            Expanded(
              flex: 5,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _searchBox(),
              ),
            ),
          if (compact) const Spacer(),
          if (compact)
            IconButton(
              tooltip: 'Tìm hồ sơ',
              onPressed: _openSearch,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search, color: MauSala.xanhDam),
            ),
          const SizedBox(width: 12),
          if (!compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(children: [
                Icon(Icons.support_agent, size: 17, color: MauSala.vang),
                SizedBox(width: 6),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('HOTLINE 24/7',
                          style: TextStyle(fontSize: 8, color: MauSala.chuPhu)),
                      Text('1900 68xx',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MauSala.vang)),
                    ]),
              ]),
            ),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => _showMessage('Bạn chưa có thông báo mới.'),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.notifications_none, color: MauSala.chuPhu),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: MauSala.xanhNenThe,
              child: Text(_initials(_user?['full_name']),
                  style: const TextStyle(
                      fontSize: 10,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      );

  Widget _searchBox() => TextField(
        controller: _searchController,
        onSubmitted: (_) => _openSearch(),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: MauSala.xanhNhat,
          prefixIcon: const Icon(Icons.search, size: 18, color: MauSala.chuPhu),
          hintText:
              'Tra cứu theo SĐT, tên người quá cố, mã kim tĩnh (vd: M1-R05-12)...',
          hintStyle: const TextStyle(fontSize: 10, color: MauSala.chuPhu),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none),
        ),
      );

  Widget _sidebar({required bool wide}) => Container(
        width: wide ? 205 : double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 2, 8, 8),
            child: Text('PHÂN HỆ THÂN NHÂN & DỊCH VỤ',
                style: TextStyle(
                    fontSize: 8, letterSpacing: .7, color: MauSala.chuPhu)),
          ),
          _navItem(0, 'Tổng quan & Dashboard', Icons.dashboard_outlined),
          _navItem(1, 'Sơ đồ Mặt bằng 50ha', Icons.map_outlined),
          _navItem(2, 'Hợp đồng & Trả góp', Icons.description_outlined),
          _navItem(
              3, 'Dịch vụ Tang lễ Trọn gói', Icons.account_balance_outlined),
          _navItem(4, 'Chăm sóc Từ xa & Ảnh thực tế',
              Icons.volunteer_activism_outlined),
          _navItem(5, 'Tưởng niệm Online', Icons.auto_stories_outlined),
          _navItem(6, 'Định vị GPS & Dẫn đường', Icons.near_me_outlined),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(7)),
            child: const Row(children: [
              Icon(Icons.spa_outlined, size: 17, color: MauSala.xanhThe),
              SizedBox(width: 7),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Sala Garden Zen Park',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700)),
                    Text('Hoa viên sinh thái 50ha',
                        style: TextStyle(fontSize: 8, color: MauSala.chuPhu)),
                  ])),
            ]),
          ),
          if (!wide) const SizedBox(height: 12),
        ]),
      );

  Widget _navItem(int index, String title, IconData icon) {
    final active = _selectedNav == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: active ? MauSala.xanhThe : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () => _selectNav(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(children: [
              Icon(icon,
                  size: 17, color: active ? Colors.white : MauSala.chuPhu),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 10,
                          color: active ? Colors.white : MauSala.chu))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _dashboardBody() => RefreshIndicator(
        onRefresh: _load,
        color: MauSala.xanhThe,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (_error != null) _errorBanner(),
              _heroArea(),
              const SizedBox(height: 22),
              _sectionHeading('Chỉ Số Vận Hành & Quỹ Đất Kim Tĩnh',
                  'Số liệu cập nhật từ hệ thống Sala Garden'),
              const SizedBox(height: 10),
              _statistics(),
              const SizedBox(height: 22),
              _sectionHeading('Thao Tác & Nghiệp Vụ Trực Tiếp',
                  'Truy cập nhanh các dịch vụ dành cho thân nhân'),
              const SizedBox(height: 10),
              _quickActions(),
              const SizedBox(height: 22),
              _personalPanels(),
              const SizedBox(height: 18),
              _consultationBanner(),
            ]),
      );

  Widget _errorBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined,
              color: Color(0xFFBA1A1A), size: 17),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_error!,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFFBA1A1A)))),
          TextButton(
              onPressed: _load,
              child: const Text('Tải lại', style: TextStyle(fontSize: 10))),
        ]),
      );

  Widget _heroArea() => LayoutBuilder(builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        final hero = _eventCard();
        final side = _environmentColumn();
        return stacked
            ? Column(children: [hero, const SizedBox(height: 12), side])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 7, child: hero),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: side),
              ]);
      });

  Widget _eventCard() => ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 300,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC4CsFxoK1dpW6hYZ8Usx4ejNTW_M4zo6dICTDj7h2EvPh70__QbBhlE5pQsm9Hq68ZSIqKIaXZnLwTeQSkGTmR4228sR390mEu6QRRq4vblzRxPkZdn7onpEabikVLv016FTrtPkjG3Kn4FI5NU_JVZFAt6p1YZxoE0RA6izwR9PDkdZU3oYiaIDVKewSO6PpWq9NQCItA28mTlbgU_9B5OR8Z-4aYQKCdNWIwvTG0f--X5iv32VUx',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: MauSala.xanhDam),
            ),
            const DecoratedBox(
                decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x223F5E4A), Color(0xEE003629)],
                  stops: [0.16, 1]),
            )),
            const Positioned(
                left: 16,
                top: 16,
                child: Row(children: [
                  _HeroTag('ĐẠI LỄ PHẬT GIÁO 2026'),
                  SizedBox(width: 6),
                  _HeroTag('TỊNH XÁ SALA • SUỐI TÂM LINH'),
                ])),
            Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SỰ KIỆN TÂM LINH TRỌNG THỂ',
                          style: TextStyle(
                              color: MauSala.vangThe,
                              fontSize: 8,
                              letterSpacing: .8,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Đại Lễ Cầu Siêu Vu Lan Báo Hiếu 2026',
                          style: GoogleFonts.newsreader(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const SizedBox(height: 5),
                      const Text(
                          'Cùng chư Tôn Đức Tăng Ni cầu quốc thái dân an, siêu độ hương linh phụ mẫu.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Color(0xFFD5E8DD),
                              fontSize: 10,
                              height: 1.4)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 7, children: [
                        FilledButton.icon(
                            onPressed: () => _showMessage(
                                'Thông tin sự kiện sẽ được cập nhật tại Ban Quản Khách.'),
                            style: FilledButton.styleFrom(
                                backgroundColor: MauSala.vang,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                visualDensity: VisualDensity.compact),
                            icon: const Icon(Icons.event_available, size: 15),
                            label: const Text('Xem Chi Tiết & Đăng Ký Dâng Đèn',
                                style: TextStyle(fontSize: 9))),
                        const _EventCountdown(),
                      ]),
                    ])),
          ]),
        ),
      );

  Widget _environmentColumn() => SizedBox(
      height: 300,
      child: Column(children: [
        Expanded(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: MauSala.vien.withValues(alpha: .35))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.eco_outlined, size: 15, color: MauSala.xanhThe),
              SizedBox(width: 6),
              Text('HIỆN TRẠNG HOA VIÊN',
                  style: TextStyle(
                      fontSize: 8, color: MauSala.chuPhu, letterSpacing: .5)),
              Spacer(),
              _Badge('50 Hecta Đạt chuẩn', gold: false)
            ]),
            const SizedBox(height: 9),
            Text('Hạ Tầng Sinh Thái Tiêu Chuẩn Châu Âu',
                style:
                    GoogleFonts.newsreader(fontSize: 18, color: MauSala.chu)),
            const SizedBox(height: 6),
            const Text(
                'Không gian xanh thanh tịnh, hệ thống xử lý môi trường và cảnh quan được chăm sóc định kỳ.',
                style: TextStyle(
                    fontSize: 9, color: MauSala.chuPhu, height: 1.45)),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: _smallEnvironmentMetric(
                      Icons.park_outlined, '50 ha', 'Quy mô hoa viên')),
              const SizedBox(width: 8),
              Expanded(
                  child: _smallEnvironmentMetric(
                      Icons.spa_outlined, 'Sinh thái', 'Không gian xanh')),
            ]),
            const SizedBox(height: 9),
            InkWell(
                onTap: _openSearch,
                child: const Row(children: [
                  Icon(Icons.verified_user_outlined,
                      size: 13, color: MauSala.vang),
                  SizedBox(width: 5),
                  Expanded(
                      child: Text('Sở hữu và hồ sơ được quản lý an toàn',
                          style:
                              TextStyle(fontSize: 8, color: MauSala.chuPhu))),
                  Icon(Icons.chevron_right, size: 15, color: MauSala.xanhThe),
                ])),
          ]),
        )),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 11, 12),
          decoration: BoxDecoration(
              color: MauSala.xanhDam, borderRadius: BorderRadius.circular(7)),
          child: Row(children: [
            const CircleAvatar(
                radius: 16,
                backgroundColor: MauSala.xanhThe,
                child: Icon(Icons.power_settings_new,
                    color: MauSala.vangThe, size: 17)),
            const SizedBox(width: 9),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Tiếp Nhận Tang Lễ 24/7',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text('Đội xe và ban nghi lễ sẵn sàng hỗ trợ',
                      style: TextStyle(color: Color(0xFFBAEED9), fontSize: 8)),
                ])),
            TextButton(
                onPressed: _callHotline,
                style: TextButton.styleFrom(
                    backgroundColor: MauSala.vangThe,
                    foregroundColor: MauSala.chu,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 8)),
                child:
                    const Text('Gọi Khẩn Cấp', style: TextStyle(fontSize: 9))),
          ]),
        ),
      ]));

  Widget _smallEnvironmentMetric(IconData icon, String value, String label) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(5)),
        child: Row(children: [
          Icon(icon, size: 17, color: MauSala.xanhThe),
          const SizedBox(width: 6),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MauSala.xanhDam)),
                Text(label,
                    style: const TextStyle(fontSize: 7, color: MauSala.chuPhu)),
              ])),
        ]),
      );

  Widget _sectionHeading(String title, String subtitle) =>
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.newsreader(fontSize: 20, color: MauSala.chu)),
          Text(subtitle,
              style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ])),
        if (!_loading)
          const Text('Cập nhật vừa xong',
              style: TextStyle(fontSize: 8, color: MauSala.chuPhu)),
      ]);

  Widget _statistics() => LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 560
            ? 4
            : constraints.maxWidth >= 360
                ? 2
                : 1;
        final gap = 10.0;
        final width = (constraints.maxWidth - (count - 1) * gap) / count;
        final items = [
          _StatData(
              Icons.grid_view_rounded,
              'TỔNG SỐ KIM TĨNH',
              _format(_summary['totalPlots']),
              'Quy hoạch phần mộ toàn khu',
              MauSala.xanhThe),
          _StatData(
              Icons.account_balance_outlined,
              'ĐÃ AN TÁNG',
              _format(_summary['deceasedCount']),
              'Hồ sơ phần mộ đã có thân nhân',
              const Color(0xFFB71C1C)),
          _StatData(
              Icons.description_outlined,
              'HỢP ĐỒNG GIA ĐÌNH',
              _format(_summary['customerContracts']),
              'Hồ sơ đang liên kết tài khoản',
              MauSala.vang),
          _StatData(
              Icons.park_outlined,
              'Ô MỘ CÒN TRỐNG',
              _format(_summary['availablePlots']),
              'Thông tin từ quy hoạch toàn khu',
              const Color(0xFF2D6A4F)),
        ];
        return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: items
                .map((item) => SizedBox(width: width, child: _statCard(item)))
                .toList());
      });

  Widget _statCard(_StatData item) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: MauSala.vien.withValues(alpha: .25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: item.color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(5)),
                child: Icon(item.icon, color: item.color, size: 19)),
            const Spacer(),
            const _Badge('Hệ thống', gold: false),
          ]),
          const SizedBox(height: 9),
          Text(item.label,
              style: const TextStyle(
                  fontSize: 8, color: MauSala.chuPhu, letterSpacing: .3)),
          const SizedBox(height: 2),
          Text(item.value,
              style: GoogleFonts.newsreader(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: MauSala.chu)),
          Text(item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 8, height: 1.35, color: MauSala.chuPhu)),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 4,
                  color: item.color,
                  backgroundColor: MauSala.xanhNenThe)),
        ]),
      );

  Widget _quickActions() => LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 560
            ? 4
            : constraints.maxWidth >= 360
                ? 2
                : 1;
        const gap = 9.0;
        final width = (constraints.maxWidth - (count - 1) * gap) / count;
        final actions = [
          _QuickAction(
              Icons.map_outlined,
              'Bản Đồ 2D/3D',
              'Sơ đồ phần mộ và trạng thái từng lô',
              () => _openSearch(),
              MauSala.xanhDam),
          _QuickAction(
              Icons.description_outlined,
              'Hợp Đồng',
              'Theo dõi hồ sơ và lịch thanh toán',
              _showContracts,
              MauSala.xanhThe),
          _QuickAction(
              Icons.account_balance_outlined,
              'Dịch Vụ Tang Lễ',
              'Tư vấn nghi lễ và thủ tục',
              _showFuneralServices,
              MauSala.xanhThe),
          _QuickAction(
              Icons.volunteer_activism_outlined,
              'Đặt Chăm Sóc Mộ',
              'Theo dõi dịch vụ chăm sóc định kỳ',
              _showCareOrders,
              MauSala.xanhThe),
          _QuickAction(Icons.location_searching, 'Tra Cứu Vị Trí',
              'Tìm thông tin và đường đến mộ', _openSearch, MauSala.vang),
          _QuickAction(Icons.payments_outlined, 'Đóng Phí Định Kỳ',
              'Xem hợp đồng gia đình', _showContracts, MauSala.vang),
          _QuickAction(
              Icons.auto_awesome_outlined,
              'Tháp Lưu Tro Cốt',
              'Tư vấn vị trí tại Tịnh Xá Sala',
              () => _showSupport('Tháp lưu tro cốt'),
              MauSala.vang),
          _QuickAction(
              Icons.menu_book_outlined,
              'Sổ Tang Online',
              'Gửi lời tưởng niệm người thân',
              () => setState(() => _selectedNav = 5),
              MauSala.vang),
        ];
        return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: actions
                .map((item) => SizedBox(width: width, child: _actionCard(item)))
                .toList());
      });

  Widget _actionCard(_QuickAction item) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: item.onTap,
          child: Container(
            height: 98,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: MauSala.vien.withValues(alpha: .2))),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: MauSala.xanhNhat,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(item.icon, size: 19, color: item.color)),
              const SizedBox(height: 6),
              Text(item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MauSala.chu)),
              Text(item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 7, color: MauSala.chuPhu)),
            ]),
          ),
        ),
      );

  Widget _personalPanels() => LayoutBuilder(builder: (context, constraints) {
        final left = _schedulePanel();
        final right = _carePanel();
        if (constraints.maxWidth < 560) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: left),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: right),
        ]);
      });

  Widget _schedulePanel() => _panel(
        title: 'Lịch & Hồ Sơ Gia Đình',
        subtitle: 'Hợp đồng và dịch vụ gần đây của bạn',
        trailing: _Badge('${_contracts.length + _careOrders.length} hồ sơ',
            gold: false),
        child: _loading
            ? const _LoadingRows()
            : _contracts.isEmpty && _careOrders.isEmpty
                ? _empty('Chưa có hợp đồng hoặc lịch dịch vụ',
                    Icons.event_note_outlined)
                : Column(children: [
                    ..._careOrders.take(3).map((item) => _timelineRow(
                          _date(item['scheduled_date']),
                          (item['service_name'] ?? 'Dịch vụ chăm sóc')
                              .toString(),
                          '${item['plot_code'] ?? ''} • ${item['zone_name'] ?? ''}',
                          _statusLabel(item['status']),
                          Icons.spa_outlined,
                        )),
                    ..._contracts.take(3).map((item) => _timelineRow(
                          'HĐ',
                          (item['contract_code'] ?? 'Hợp đồng phần mộ')
                              .toString(),
                          '${item['plot_code'] ?? ''} • ${item['zone_name'] ?? ''}',
                          _statusLabel(item['status']),
                          Icons.description_outlined,
                        )),
                  ]),
        footer: TextButton.icon(
            onPressed: _showContracts,
            icon: const Icon(Icons.arrow_forward, size: 13),
            label: const Text('Xem toàn bộ hợp đồng & lịch dịch vụ',
                style: TextStyle(fontSize: 9))),
      );

  Widget _timelineRow(String date, String title, String detail, String status,
          IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(5)),
        child: Row(children: [
          Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Text(date,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: MauSala.xanhDam))),
          const SizedBox(width: 10),
          Icon(icon, size: 15, color: MauSala.xanhThe),
          const SizedBox(width: 7),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700)),
                Text(detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8, color: MauSala.chuPhu)),
              ])),
          const SizedBox(width: 7),
          _Badge(status, gold: !_isComplete(status)),
        ]),
      );

  Widget _carePanel() => _panel(
        title: 'Chăm Sóc Từ Xa',
        subtitle: 'Đơn dịch vụ và trạng thái nghiệm thu',
        trailing: _Badge('${_careOrders.length} đơn', gold: true),
        child: _loading
            ? const _LoadingRows()
            : _careOrders.isEmpty
                ? _empty(
                    'Chưa có đơn chăm sóc', Icons.volunteer_activism_outlined)
                : Column(
                    children: _careOrders
                        .take(4)
                        .map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                  color: MauSala.xanhNhat,
                                  borderRadius: BorderRadius.circular(5)),
                              child: Row(children: [
                                const CircleAvatar(
                                    radius: 17,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.local_florist_outlined,
                                        color: MauSala.xanhThe, size: 17)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          (item['service_name'] ??
                                                  'Dịch vụ chăm sóc')
                                              .toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          '${item['plot_code'] ?? ''} • ${_date(item['scheduled_date'])}',
                                          style: const TextStyle(
                                              fontSize: 8,
                                              color: MauSala.chuPhu)),
                                    ])),
                                _Badge(_statusLabel(item['status']),
                                    gold: !_isComplete(
                                        (item['status'] ?? '').toString())),
                              ]),
                            ))
                        .toList()),
        footer: TextButton.icon(
            onPressed: _showCareOrders,
            icon: const Icon(Icons.fact_check_outlined, size: 14),
            label: const Text('Xem tất cả đơn chăm sóc',
                style: TextStyle(fontSize: 9))),
      );

  Widget _panel(
          {required String title,
          required String subtitle,
          required Widget trailing,
          required Widget child,
          Widget? footer}) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: MauSala.vien.withValues(alpha: .25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: GoogleFonts.newsreader(
                          fontSize: 18, color: MauSala.chu)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 8, color: MauSala.chuPhu)),
                ])),
            trailing,
          ]),
          const SizedBox(height: 12),
          child,
          if (footer != null)
            Align(alignment: Alignment.centerLeft, child: footer),
        ]),
      );

  Widget _empty(String text, IconData icon) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(5)),
        child: Column(children: [
          Icon(icon, size: 26, color: MauSala.xanhThe),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]),
      );

  Widget _consultationBanner() => LayoutBuilder(
      builder: (context, constraints) => Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(7)),
            child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 12,
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                      width: constraints.maxWidth < 470
                          ? constraints.maxWidth - 30
                          : 420,
                      child: const Row(children: [
                        CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.explore_outlined,
                                color: MauSala.vang)),
                        SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Tư Vấn Phong Thủy & Hướng Đặt Mộ Phần',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: MauSala.chu)),
                              Text(
                                  'Đội ngũ tư vấn hỗ trợ thông tin quy hoạch và hướng dẫn thăm viếng tại hoa viên.',
                                  style: TextStyle(
                                      fontSize: 8,
                                      height: 1.4,
                                      color: MauSala.chuPhu)),
                            ])),
                      ])),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                        onPressed: _openSearch,
                        icon: const Icon(Icons.menu_book_outlined, size: 14),
                        label: const Text('Tải Sách Phong Thủy 50ha',
                            style: TextStyle(fontSize: 9))),
                    FilledButton.icon(
                        onPressed: _callHotline,
                        icon: const Icon(Icons.event_available, size: 14),
                        style: FilledButton.styleFrom(
                            backgroundColor: MauSala.xanhDam),
                        label: const Text('Đặt Lịch Tư Vấn',
                            style: TextStyle(fontSize: 9))),
                  ]),
                ]),
          ));

  void _showContracts() => setState(() => _selectedNav = 2);

  void _openContractForPlot(Map<String, dynamic> plot) => setState(() {
        _contractDraftPlot = Map<String, dynamic>.from(plot);
        _selectedNav = 2;
      });

  Future<void> _contractCreated(Map<String, dynamic> contract) {
    setState(() {
      _contracts = [
        contract,
        ..._contracts.where((existing) =>
            (existing as Map)['id']?.toString() != contract['id']?.toString()),
      ];
      _selectedNav = 2;
      _contractDraftPlot = null;
      _error = null;
    });
    // Render the server-created contract first. Refresh the dashboard and
    // server-side contract list only after that frame so a slow API cannot
    // keep the create-contract flow waiting on the payment/contract screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
    return Future<void>.value();
  }

  void _cancelContractDraft() {
    if (_contractDraftPlot != null) {
      setState(() => _contractDraftPlot = null);
    }
  }

  void _showFuneralServices() => setState(() => _selectedNav = 3);
  void _showCareOrders() => setState(() => _selectedNav = 4);

  void _selectNav(int index) {
    setState(() {
      _selectedNav = index;
      if (index != 2) _contractDraftPlot = null;
    });
    if (MediaQuery.sizeOf(context).width < 760) Navigator.pop(context);
    switch (index) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        break;
    }
  }

  Future<void> _openSearch() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const TrangChuKhachVangLai()));
  }

  Future<void> _callHotline() async {
    final uri = Uri.parse('tel:19006800');
    await launchUrl(uri);
  }

  Future<void> _logout() async {
    await ApiService.instance.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TrangChuKhachVangLai()),
        (_) => false);
  }

  void _showSupport(String service) =>
      _showMessage('Liên hệ Hotline 1900 68xx để được tư vấn $service.');

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _format(dynamic value) {
    final number = int.tryParse(value?.toString() ?? '');
    if (number == null) return _loading ? '…' : '0';
    final digits = number.toString();
    final groups = <String>[];
    for (var index = digits.length; index > 0; index -= 3) {
      final start = index - 3 < 0 ? 0 : index - 3;
      groups.insert(0, digits.substring(start, index));
    }
    return groups.join('.');
  }

  String _date(dynamic value) {
    if (value == null) return 'Chưa xếp lịch';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _statusLabel(dynamic value) {
    final status = (value ?? '').toString();
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ tiếp nhận';
      case 'IN_PROGRESS':
        return 'Đang thực hiện';
      case 'COMPLETED':
      case 'DONE':
        return 'Đã hoàn thành';
      case 'PAID':
        return 'Đã thanh toán';
      case 'ACTIVE':
        return 'Còn hiệu lực';
      case 'RESERVED':
        return 'Đã đặt chỗ';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'OVERDUE':
        return 'Quá hạn';
      default:
        return status.isEmpty ? 'Mới' : status.replaceAll('_', ' ');
    }
  }

  String _initials(dynamic value) {
    final words = (value ?? 'SG').toString().trim().split(RegExp(r'\s+'));
    return words
        .take(2)
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
        .join();
  }

  bool _isComplete(String status) => const {
        'COMPLETED',
        'DONE',
        'PAID',
        'HOÀN THÀNH',
        'ĐÃ THANH TOÁN'
      }.contains(status.toUpperCase());
}

class _Logo extends StatelessWidget {
  const _Logo({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: compact ? 27 : 30,
            height: compact ? 27 : 30,
            decoration: BoxDecoration(
                color: MauSala.xanhThe, borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.spa, color: Color(0xFFBAEED9), size: 18)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SALA GARDEN',
              style: GoogleFonts.newsreader(
                  fontSize: compact ? 15 : 17,
                  height: 1,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          const Text('HOA VIÊN NGHĨA TRANG SINH THÁI',
              style: TextStyle(
                  fontSize: 7, letterSpacing: .6, color: MauSala.vang)),
        ]),
      ]);
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 7,
                color: MauSala.xanhDam,
                fontWeight: FontWeight.w700)),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.gold});
  final String text;
  final bool gold;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: gold
              ? MauSala.vangThe.withValues(alpha: .65)
              : MauSala.xanhNenThe,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 7,
                color: gold ? MauSala.vang : MauSala.xanhDam,
                fontWeight: FontWeight.w600)),
      );
}

class _EventCountdown extends StatelessWidget {
  const _EventCountdown();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(5)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event, size: 13, color: MauSala.vangThe),
          SizedBox(width: 5),
          Text('Lịch sự kiện sắp tới',
              style: TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _StatData {
  const _StatData(
      this.icon, this.label, this.value, this.description, this.color)
      : progress = .7;
  final IconData icon;
  final String label;
  final String value;
  final String description;
  final Color color;
  final double progress;
}

class _QuickAction {
  const _QuickAction(
      this.icon, this.title, this.subtitle, this.onTap, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
            child: CircularProgressIndicator(
                color: MauSala.xanhThe, strokeWidth: 2)),
      );
}

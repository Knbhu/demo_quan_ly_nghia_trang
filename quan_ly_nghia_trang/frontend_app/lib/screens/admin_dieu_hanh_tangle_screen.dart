import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Daily funeral and crematorium operations dashboard, matching the first
/// approved reference screen. Data is currently sample data until the APIs are
/// connected.
class AdminDieuHanhTangLeScreen extends StatelessWidget {
  const AdminDieuHanhTangLeScreen({super.key});

  static const _events = <_FuneralEvent>[
    _FuneralEvent(
      code: 'TL-01',
      time: '07:00 – 09:30',
      status: 'ĐÃ HOÀN TẤT',
      person: 'Cụ Ông Vũ Văn Đức',
      detail:
          'Hưởng thọ 84 tuổi • Nghi thức Phật giáo Bắc Tông • Sảnh An Lạc (Tầng 1)',
      note: 'Chủ lễ: Thích Thiện Tâm    Đại diện: Vũ Đức Minh (Trưởng nam)',
      sideTitle: 'Bàn giao hũ tro',
      sideValue: '10:15',
      sideNote: 'Đã lưu Tháp Sen Vạn An',
      color: AppColors.forest,
    ),
    _FuneralEvent(
      code: 'TL-02',
      time: '09:30 – 12:30',
      status: 'ĐÃ HOÀN TẤT',
      person: 'Cụ Bà Nguyễn Thị Lan',
      detail:
          'Hưởng thọ 79 tuổi • Thành lễ an táng Công giáo • Sảnh Vạn Phúc (Tầng 2)',
      note: 'Linh mục: Giuse Trần Văn Hùng    Đội nghi thức Khánh Tiết #1',
      sideTitle: 'An táng Kim Tĩnh M4',
      sideValue: '12:20',
      sideNote: 'Khu Vườn Bình An',
      color: AppColors.forest,
    ),
    _FuneralEvent(
      code: 'TL-03',
      time: '13:30 – 17:00',
      status: 'ĐANG DIỄN RA',
      person: 'Cụ Ông Hoàng Minh Tuấn',
      detail:
          'Hưởng thọ 72 tuổi • Nghi thức Tiêu chuẩn • Sảnh Vạn Phúc (Tầng 1)',
      note: 'Tiến trình buồng thụ cấp (1.105°C)',
      sideTitle: 'Lò TABO #02 • 65%',
      sideValue: 'ĐANG CHẠY',
      sideNote: 'Ước tính còn 25 phút',
      color: AppColors.gold,
    ),
    _FuneralEvent(
      code: 'TL-04',
      time: '16:30 – 19:30',
      status: 'ĐANG VIẾNG TANG',
      person: 'Cụ Bà Lê Thị Mai',
      detail:
          'Hưởng thượng thọ 91 tuổi • Nghi thức Phật giáo • Sảnh Vĩnh Hằng VIP',
      note: 'Tiếp đón: 4 đoàn viếng đang hiện diện',
      sideTitle: 'Khóa lễ cầu siêu',
      sideValue: '20:00',
      sideNote: 'Sẽ gửi mã QR đến gia quyến',
      color: AppColors.forest,
    ),
    _FuneralEvent(
      code: 'TL-05',
      time: '19:30 – 21:30',
      status: 'SẮP TIẾP NHẬN',
      person: 'Tiếp nhận linh cữu BV Chợ Rẫy',
      detail:
          'Khu Tiếp Nhận & Bảo Quản Lạnh (-4°C) • Đội xe chuyên dụng Fleet #04',
      note: 'Dự kiến đến cổng lúc 19:15 • Đã chuẩn bị buồng lạnh VIP 2',
      sideTitle: 'Dự kiến đến cổng',
      sideValue: '19:15',
      sideNote: 'Đội xe đang trên đường',
      color: Color(0xFF9EAAA5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      // The admin page is embedded in a Row. If a parent/route accidentally
      // passes an unbounded width, the dashboard's Expanded/Wrap children get
      // infinite constraints and Flutter skips painting the affected cards.
      final pageWidth = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : viewport.width - (viewport.width >= 850 ? 235 : 0);
      final pageHeight = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : viewport.height;

      return SizedBox(
        width: pageWidth,
        height: pageHeight,
        child: Container(
          color: AppColors.background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            children: [
              _header(context),
              const SizedBox(height: 10),
              _kpis(),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, contentConstraints) {
                final maxWidth = contentConstraints.maxWidth;
                if (!contentConstraints.hasBoundedWidth || maxWidth < 920) {
                  return Column(children: [
                    _dailyTimeline(context),
                    const SizedBox(height: 10),
                    _taboMonitor(),
                    const SizedBox(height: 10),
                    _urnHandover(),
                  ]);
                }
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: _dailyTimeline(context)),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 9,
                          child: Column(children: [
                            _taboMonitor(),
                            const SizedBox(height: 10),
                            _urnHandover(),
                          ])),
                    ]);
              }),
              const SizedBox(height: 10),
              _bottomPanels(context),
            ],
          ),
        ),
      );
    });
  }

  Widget _header(BuildContext context) => _SurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: LayoutBuilder(
            builder: (context, constraints) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Wrap(
                              spacing: 8,
                              runSpacing: 5,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const _Tag('BÁO CÁO VẬN HÀNH THỰC ĐỊA',
                                    color: AppColors.forest,
                                    foreground: Colors.white),
                                Text(
                                    '•  HÔM NAY, 28/11/2026 (ÂM LỊCH: 20/10 BÍNH NGỌ)',
                                    style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: constraints.maxWidth < 500
                                            ? 9
                                            : 10)),
                              ]),
                          const SizedBox(height: 5),
                          const Text(
                              'Nhật Ký Vận Hành Tang Lễ & Báo Cáo Hỏa Táng Trong Ngày',
                              style: TextStyle(
                                  fontFamily: 'Newsreader',
                                  fontSize: 23,
                                  height: 1.08,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forestDeep)),
                          const SizedBox(height: 4),
                          const Text(
                              'Báo cáo giám sát toàn diện tiến độ các ca tang lễ, công suất lò hỏa táng TABO Thụy Điển, kiểm soát khí thải Euro 6 và đánh giá mức độ hài lòng của gia quyến tại Công Viên Nghĩa Trang Sinh Thái Sala Garden.',
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: AppColors.muted)),
                        ])),
                    if (constraints.maxWidth > 590) ...[
                      const SizedBox(width: 14),
                      ConstrainedBox(
                          constraints:
                              const BoxConstraints.tightFor(width: 190),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 190,
                                    child: _ActionButton(
                                        icon: Icons.table_view_outlined,
                                        label: 'Xuất Báo Cáo (.XLSX)',
                                        onTap: () => _message(context,
                                            'Đang chuẩn bị báo cáo Excel.'))),
                                const SizedBox(height: 5),
                                SizedBox(
                                    width: 190,
                                    child: _ActionButton(
                                        icon: Icons.fact_check_outlined,
                                        label: 'Biên Bản Ca Trực (PDF)',
                                        onTap: () => _message(context,
                                            'Đang tạo biên bản ca trực PDF.'))),
                                const SizedBox(height: 5),
                                SizedBox(
                                    width: 190,
                                    child: _ActionButton(
                                        icon: Icons.send_outlined,
                                        label: 'Gửi Ban Giám Đốc',
                                        dark: true,
                                        onTap: () => _message(context,
                                            'Báo cáo đã sẵn sàng gửi Ban Giám Đốc.'))),
                              ])),
                    ] else
                      PopupMenuButton<String>(
                        tooltip: 'Tác vụ báo cáo',
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) => _message(context, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'Đang chuẩn bị báo cáo Excel.',
                              child: Text('Xuất Báo Cáo (.XLSX)')),
                          PopupMenuItem(
                              value: 'Đang tạo biên bản ca trực PDF.',
                              child: Text('Biên Bản Ca Trực (PDF)')),
                          PopupMenuItem(
                              value: 'Báo cáo đã sẵn sàng gửi Ban Giám Đốc.',
                              child: Text('Gửi Ban Giám Đốc')),
                        ],
                      ),
                  ],
                )),
      );

  Widget _kpis() => LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
                ? 3
                : 2;
        final width = (constraints.maxWidth - (count - 1) * 8) / count;
        const items = [
          _KpiData(
              'TỔNG CA TANG LỄ',
              '05',
              'Ca trong ngày',
              '3 Hoàn tất • 1 Đang lễ • 1 Ca tối',
              Icons.event_note,
              AppColors.forest),
          _KpiData(
              'HỎA TÁNG TABO',
              '08',
              'Lượt thực hiện',
              'TB 72 phút/ca • 18% Điện năng',
              Icons.local_fire_department_outlined,
              AppColors.gold),
          _KpiData(
              'TIẾN ĐỘ SLA NGHI THỨC',
              '100%',
              'TUYỆT ĐỐI',
              'Chuẩn giờ khởi đạo pháp & di quan',
              Icons.schedule,
              AppColors.forest),
          _KpiData(
              'KHÍ THẢI LÒ ĐỐT',
              '0.02',
              'mg/Nm³',
              'Chuẩn Euro 6 • Khí hồi lưu: Mới',
              Icons.eco_outlined,
              AppColors.forest),
          _KpiData(
              'MỨC HÀI LÒNG (CSAT)',
              '4.96',
              '/ 5.0',
              '18 đánh giá Zalo OA thân nhân',
              Icons.sentiment_satisfied_alt,
              AppColors.gold),
        ];
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final item in items)
            SizedBox(width: width, child: _KpiCard(item)),
        ]);
      });

  Widget _dailyTimeline(BuildContext context) => Column(children: [
        _SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.event_note, size: 18, color: AppColors.forest),
              const SizedBox(width: 8),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Nhật Ký Tiến Độ Tang Lễ Các Ca Trực',
                        style: TextStyle(
                            fontFamily: 'Newsreader',
                            fontSize: 16,
                            color: AppColors.forestDeep,
                            fontWeight: FontWeight.w600)),
                    Text(
                        'Giám sát thực địa theo dòng thời gian tại các Nhà Tang Lễ & Sảnh Viếng',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  ])),
              const _Tag('Trực tiếp từ Trạm Điều Hành',
                  color: AppColors.paleBlue, foreground: AppColors.forestDeep),
            ])),
        const SizedBox(height: 8),
        for (final event in _events) ...[
          _EventCard(
              event: event,
              onTap: () => _message(
                  context, 'Mở chi tiết ca ${event.code}: ${event.person}')),
          const SizedBox(height: 7),
        ],
        _fieldPhotos(context),
      ]);

  Widget _fieldPhotos(BuildContext context) => _SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.photo_camera_outlined,
                size: 16, color: AppColors.gold),
            const SizedBox(width: 6),
            const Expanded(
                child: Text('Tư Liệu Hiện Trường Ca Trực',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.forestDeep))),
            TextButton(
                onPressed: () =>
                    _message(context, 'Mở thư viện ảnh hiện trường.'),
                child: const Text('Cập nhật kiểm tra lúc 15:30',
                    style: TextStyle(fontSize: 9))),
          ]),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final imageWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              _FieldPhoto(
                  width: imageWidth,
                  title: 'Sảnh Vĩnh Hằng VIP',
                  subtitle:
                      'Hoàn thiện bày trí hoa lan trắng nhập khẩu & đèn trầm',
                  tag: 'Đạt Chuẩn 5 Sao',
                  icon: Icons.church_outlined),
              _FieldPhoto(
                  width: imageWidth,
                  title: 'Khu TABO Thụy Điển',
                  subtitle: 'Hệ thống cấp nhiệt tự động & kiểm soát khí thải',
                  tag: 'An Toàn Tuyệt Đối',
                  icon: Icons.thermostat_outlined),
            ]);
          }),
        ]),
      );

  Widget _taboMonitor() => _SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.precision_manufacturing_outlined,
                color: AppColors.forest, size: 17),
            const SizedBox(width: 6),
            const Expanded(
                child: Text('Giám Sát Lò TABO Thụy Điển',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.forestDeep))),
            const _Tag('ONLINE 24/7',
                color: AppColors.paleBlue, foreground: AppColors.forestDeep),
          ]),
          const SizedBox(height: 4),
          const Text('TIÊU CHUẨN KHÍ THẢI EURO 6',
              style: TextStyle(
                  fontSize: 9, letterSpacing: .5, color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(children: [
            const Expanded(
                child: _MonitorMetric(
                    title: 'BUỒNG SƠ CẤP',
                    value: '912°C',
                    note: 'Cài đặt: 850°C – 950°C',
                    icon: Icons.device_thermostat,
                    color: AppColors.forest)),
            const SizedBox(width: 7),
            const Expanded(
                child: _MonitorMetric(
                    title: 'BUỒNG THỨ CẤP',
                    value: '1.105°C',
                    note: 'Chuẩn liên tục: 1.050°C',
                    icon: Icons.local_fire_department,
                    color: AppColors.gold)),
          ]),
          const SizedBox(height: 8),
          const _MeasureRow(
              label: 'Khí CO (Monoxide)',
              value: '1.8 ppm',
              limit: 'Ngưỡng: < 20 ppm',
              progress: .12),
          const _MeasureRow(
              label: 'Hợp chất NOx',
              value: '24 mg/m³',
              limit: 'Ngưỡng: < 150 mg/m³',
              progress: .22),
          const _MeasureRow(
              label: 'Khí lưu huỳnh SO₂',
              value: '0.01 mg/m³',
              limit: 'Ngưỡng: < 150 mg/m³',
              progress: .08),
          const SizedBox(height: 5),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(7)),
              child: const Row(children: [
                Icon(Icons.filter_alt_outlined,
                    size: 14, color: AppColors.forest),
                SizedBox(width: 6),
                Expanded(
                    child: Text('Lọc khói & Than hoạt tính',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.forestDeep))),
                Text('100% Hoàn nguyên',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700)),
              ])),
        ]),
      );

  Widget _urnHandover() => _SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.forest),
            SizedBox(width: 6),
            Expanded(
                child: Text('Phân Loại Hũ Tro Cốt Bàn Giao',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forestDeep)))
          ]),
          const Text('TỔNG CỘNG: 08 HŨ NGHIỆM THU HÔM NAY',
              style: TextStyle(fontSize: 9, color: AppColors.muted)),
          const SizedBox(height: 7),
          const _HandoverRow(
              number: '05',
              title: 'Gốm Bát Tràng Tráng Men Cao Cấp',
              place: 'Tháp An Lạc • Tầng Sen Vạn An',
              tag: 'Đã nhập tháp',
              color: AppColors.paleBlue),
          const SizedBox(height: 6),
          const _HandoverRow(
              number: '02',
              title: 'Ngọc Bích Phong Thủy Đặc Biệt',
              place: 'Lưu Tháp Xá Lợi Sala Garden',
              tag: 'Thượng tọa chứng từ',
              color: Color(0xFFFFE7B8)),
          const SizedBox(height: 6),
          const _HandoverRow(
              number: '01',
              title: 'Kim Loại Titan Hàng Không',
              place: 'Chuyển huyện Hạ Long về Hà Nội',
              tag: 'Đóng niêm phong',
              color: AppColors.paleBlue),
          const SizedBox(height: 7),
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(7)),
              child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        color: AppColors.gold, size: 16),
                    SizedBox(width: 7),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Chứng Thực Tro Cốt Sáng Tinh Khiết',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestDeep)),
                          Text(
                              '100% ca hỏa táng đều đạt chuẩn tro cốt trắng ngà tinh khiết, đã cấp Giấy Chứng Nhận Hỏa Táng có dấu mộc đỏ BQL Sala Garden và trao tận tay thân nhân cùng sổ hương linh.',
                              style: TextStyle(
                                  fontSize: 9,
                                  height: 1.3,
                                  color: AppColors.muted)),
                        ])),
                  ])),
        ]),
      );

  Widget _bottomPanels(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final items = [
          _testimonial(context),
          _crewAwards(context),
          _approval(context),
        ];
        if (!constraints.hasBoundedWidth || constraints.maxWidth < 900) {
          return Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1) const SizedBox(height: 8),
            ],
          ]);
        }

        // Use fixed, finite child widths in the vertical ListView. This avoids
        // asking flex children to resolve against an unbounded scroll-axis size.
        final availableWidth = constraints.maxWidth - 18;
        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            SizedBox(width: availableWidth * 10 / 24, child: items[0]),
            SizedBox(width: availableWidth * 8 / 24, child: items[1]),
            SizedBox(width: availableWidth * 6 / 24, child: items[2]),
          ],
        );
      });

  Widget _testimonial(BuildContext context) => _SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.rate_review_outlined,
              size: 15, color: AppColors.gold),
          const SizedBox(width: 5),
          const Expanded(
              child: Text('Ý KIẾN & LỜI TRI ÂN TỪ THÂN NHÂN',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold))),
          const Text('★ ★ ★ ★ ★  5.0 / 5.0',
              style: TextStyle(
                  fontSize: 9,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700))
        ]),
        const SizedBox(height: 7),
        const Text(
            '“Gia đình chúng tôi vô cùng xúc động trước sự trang nghiêm, chu đáo và thành tình của Sala Garden. Lễ hỏa táng cho bố diễn ra đúng giờ, không gian tĩnh lặng và hữu tư cốt được BQL xử lý sạch sẽ, ấm cúng khiến chúng tôi an lòng trọn vẹn.”',
            style: TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 14,
                height: 1.3,
                fontStyle: FontStyle.italic,
                color: AppColors.forestDeep)),
        const SizedBox(height: 9),
        Row(children: [
          const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.paleBlue,
              child: Text('N',
                  style: TextStyle(fontSize: 10, color: AppColors.forest))),
          const SizedBox(width: 7),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Ông Hoàng Trọng Nghĩa',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                Text('Thân nhân ca tang lễ #TL-01 (Phản hồi qua Zalo OA)',
                    style: TextStyle(fontSize: 8, color: AppColors.muted))
              ])),
          const Text('11:15 • 28/11/2026',
              style: TextStyle(fontSize: 8, color: AppColors.muted))
        ]),
      ]));

  Widget _crewAwards(BuildContext context) => _SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.workspace_premium_outlined,
              color: AppColors.gold, size: 15),
          SizedBox(width: 6),
          Text('KHEN THƯỞNG ĐỘI NGŨ CA TRỰC',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold))
        ]),
        const SizedBox(height: 8),
        _crewRow(Icons.person, 'Nguyễn Trọng Nghĩa',
            'Trưởng Ban Tang Lễ • Điều phối chuẩn xác 5 ca', 'A'),
        const SizedBox(height: 6),
        _crewRow(Icons.groups, 'Tổ Phục Vụ Khánh Tiết Số 2',
            'Đón tiếp chu đáo hơn 250 lượt khách viếng', 'A'),
        const SizedBox(height: 8),
        const Align(
            alignment: Alignment.centerRight,
            child: Text('ĐỀ XUẤT KHEN THƯỞNG NGÀY: HẠNG A',
                style: TextStyle(
                    fontSize: 8,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700))),
      ]));

  Widget _crewRow(IconData icon, String name, String info, String grade) =>
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(7)),
          child: Row(children: [
            CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.forest,
                child: Icon(icon, size: 12, color: Colors.white)),
            const SizedBox(width: 7),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestDeep)),
                  Text(info,
                      style:
                          const TextStyle(fontSize: 8, color: AppColors.muted))
                ])),
            _Tag(grade,
                color: const Color(0xFFFFDE9A),
                foreground: AppColors.forestDeep),
          ]));

  Widget _approval(BuildContext context) => _SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.draw_outlined, size: 15, color: AppColors.gold),
          SizedBox(width: 6),
          Text('PHÊ DUYỆT BAN QUẢN LÝ',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold))
        ]),
        const SizedBox(height: 9),
        const Row(children: [
          Icon(Icons.verified_outlined, size: 15, color: AppColors.forest),
          SizedBox(width: 6),
          Expanded(
              child: Text('Đã Ký Số Điện Tử BQL',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestDeep)))
        ]),
        const Text(
            'Xác thực bởi Trưởng BQL Công Viên Nghĩa Trang Sinh Thái Sala Garden.',
            style:
                TextStyle(fontSize: 9, height: 1.35, color: AppColors.muted)),
        const SizedBox(height: 8),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.paleBlue,
                borderRadius: BorderRadius.circular(7)),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nguyễn Văn Quản Lý',
                      style: TextStyle(
                          fontFamily: 'Newsreader',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forestDeep)),
                  Text('Ký duyệt: 17:30 - 28/11/2026',
                      style: TextStyle(fontSize: 8, color: AppColors.muted)),
                  Text('SHA-256: 4e8b...9f2a (BQL_SG_OFFICIAL)',
                      style: TextStyle(fontSize: 8, color: AppColors.muted)),
                ])),
      ]));

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }
}

class _FuneralEvent {
  final String code,
      time,
      status,
      person,
      detail,
      note,
      sideTitle,
      sideValue,
      sideNote;
  final Color color;
  const _FuneralEvent(
      {required this.code,
      required this.time,
      required this.status,
      required this.person,
      required this.detail,
      required this.note,
      required this.sideTitle,
      required this.sideValue,
      required this.sideNote,
      required this.color});
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _SurfaceCard(
      {required this.child, this.padding = const EdgeInsets.all(12)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5EDF2)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08003329), blurRadius: 8, offset: Offset(0, 2))
            ]),
        child: child,
      );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color, foreground;
  const _Tag(this.label, {required this.color, required this.foreground});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 8,
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: .2)));
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.dark = false});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 30,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
            backgroundColor: dark ? AppColors.forestDeep : AppColors.paleBlue,
            foregroundColor: dark ? Colors.white : AppColors.forestDeep,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
        icon: Icon(icon, size: 13),
        label: Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      ));
}

class _KpiData {
  final String title, value, unit, note;
  final IconData icon;
  final Color accent;
  const _KpiData(
      this.title, this.value, this.unit, this.note, this.icon, this.accent);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard(this.data);
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5EDF2))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(children: [
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 3, color: data.accent)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(data.title,
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .25))),
                      Icon(data.icon, size: 15, color: data.accent)
                    ]),
                    const SizedBox(height: 5),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(data.value,
                          style: TextStyle(
                              fontFamily: 'Newsreader',
                              fontSize: 24,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: data.accent)),
                      const SizedBox(width: 4),
                      Flexible(
                          child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(data.unit,
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.muted))))
                    ]),
                    const SizedBox(height: 5),
                    Text(data.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 8, height: 1.25, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: .72,
                            minHeight: 3,
                            backgroundColor: AppColors.paleBlue,
                            color: data.accent)),
                  ]),
            ),
          ]),
        ),
      );
}

class _EventCard extends StatelessWidget {
  final _FuneralEvent event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE5EDF2))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(width: 3, color: event.color)),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        _Tag('#${event.code}',
                            color: AppColors.paleBlue,
                            foreground: AppColors.forestDeep),
                        const SizedBox(height: 5),
                        Text(event.time.split('–').first.trim(),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.muted)),
                      ]),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(event.person,
                                      style: const TextStyle(
                                          fontFamily: 'Newsreader',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.forestDeep)),
                                  _Tag(event.status,
                                      color: event.color.withValues(alpha: .14),
                                      foreground: event.color)
                                ]),
                            const SizedBox(height: 3),
                            Text(event.detail,
                                style: const TextStyle(
                                    fontSize: 9,
                                    height: 1.25,
                                    color: AppColors.muted)),
                            const SizedBox(height: 5),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: AppColors.paleBlue
                                        .withValues(alpha: .65),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(event.note,
                                    style: const TextStyle(
                                        fontSize: 8,
                                        color: AppColors.forestDeep))),
                          ])),
                      const SizedBox(width: 8),
                      if (MediaQuery.sizeOf(context).width > 700)
                        SizedBox(
                            width: 118,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(event.sideTitle,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 8, color: AppColors.muted)),
                                  const SizedBox(height: 2),
                                  Text(event.sideValue,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: event.color)),
                                  Text(event.sideNote,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 8, color: AppColors.muted)),
                                ])),
                    ]),
              ),
            ]),
          ),
        ),
      );
}

class _MonitorMetric extends StatelessWidget {
  final String title, value, note;
  final IconData icon;
  final Color color;
  const _MonitorMetric(
      {required this.title,
      required this.value,
      required this.note,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: AppColors.paleBlue.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 8, color: AppColors.muted))),
          Icon(icon, size: 12, color: color)
        ]),
        Text(value,
            style: TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color)),
        Text(note, style: const TextStyle(fontSize: 8, color: AppColors.muted)),
      ]));
}

class _MeasureRow extends StatelessWidget {
  final String label, value, limit;
  final double progress;
  const _MeasureRow(
      {required this.label,
      required this.value,
      required this.limit,
      required this.progress});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 9, color: AppColors.muted))),
          Text(value,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestDeep)),
          const SizedBox(width: 5),
          Text('($limit)',
              style: const TextStyle(fontSize: 8, color: AppColors.muted))
        ]),
        const SizedBox(height: 3),
        ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: AppColors.paleBlue,
                color: AppColors.forest)),
      ]));
}

class _HandoverRow extends StatelessWidget {
  final String number, title, place, tag;
  final Color color;
  const _HandoverRow(
      {required this.number,
      required this.title,
      required this.place,
      required this.tag,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(5)),
            child: Text(number,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDeep))),
        const SizedBox(width: 7),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestDeep)),
          Text(place,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, color: AppColors.muted))
        ])),
        const SizedBox(width: 5),
        _Tag(tag, color: color, foreground: AppColors.forestDeep),
      ]));
}

class _FieldPhoto extends StatelessWidget {
  final double width;
  final String title, subtitle, tag;
  final IconData icon;
  const _FieldPhoto(
      {required this.width,
      required this.title,
      required this.subtitle,
      required this.tag,
      required this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      child: Container(
          decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                height: 86,
                width: double.infinity,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                      Color(0xFFB9D3C4),
                      Color(0xFF668978),
                      Color(0xFF254D3F)
                    ])),
                child: Stack(children: [
                  const Positioned.fill(
                      child: Opacity(
                          opacity: .18,
                          child: Icon(Icons.forest,
                              size: 82, color: Colors.white))),
                  Positioned(
                      left: 6,
                      top: 6,
                      child: _Tag(title,
                          color: AppColors.forestDeep,
                          foreground: Colors.white)),
                  Center(
                      child: Icon(icon,
                          size: 30, color: Colors.white.withValues(alpha: .9))),
                ])),
            Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 8, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Text('Giám sát: Trần Bình Quyền     15:30 Hôm Nay',
                          style: const TextStyle(
                              fontSize: 7,
                              color: AppColors.forestDeep,
                              fontWeight: FontWeight.w600))
                    ])),
          ])));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/gia_tham_khao.dart';
import '../core/mausala.dart';
import 'thanhtoanchamsoc.dart';

class ChamSocMoPhan extends StatefulWidget {
  const ChamSocMoPhan({
    super.key,
    required this.contracts,
    required this.orders,
    required this.onRefresh,
    required this.onOpenContracts,
  });

  final List<dynamic> contracts;
  final List<dynamic> orders;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenContracts;

  @override
  State<ChamSocMoPhan> createState() => _ChamSocMoPhanState();
}

class _ChamSocMoPhanState extends State<ChamSocMoPhan> {
  final _catalogKey = GlobalKey();
  final _reviewController = TextEditingController();
  List<Map<String, dynamic>> _services = [];
  bool _loadingServices = true;
  bool _sendingReview = false;
  int _rating = 5;
  String? _selectedPlotCode;
  Map<String, dynamic>? _checkoutService;
  String? _serviceError;

  List<Map<String, dynamic>> get _plots {
    final seen = <String>{};
    return widget.contracts
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) {
      final plotId = row['plot_id']?.toString();
      final plotCode = row['plot_code']?.toString();
      final status = row['status']?.toString().toUpperCase();
      return plotId != null &&
          plotCode != null &&
          status != 'CANCELLED' &&
          seen.add(plotId);
    }).toList();
  }

  Map<String, dynamic>? get _selectedPlot {
    final plots = _plots;
    if (plots.isEmpty) return null;
    for (final plot in plots) {
      if (plot['plot_code']?.toString() == _selectedPlotCode) return plot;
    }
    return plots.first;
  }

  List<Map<String, dynamic>> get _orders => widget.orders
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();

  Map<String, dynamic>? get _selectedOrder {
    final plotCode = _selectedPlot?['plot_code']?.toString();
    if (plotCode == null) return null;
    for (final order in _orders) {
      if (order['plot_code']?.toString() == plotCode) return order;
    }
    return null;
  }

  List<Map<String, dynamic>> get _proofImages {
    final raw = _selectedOrder?['proof_images'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return [];
  }

  bool get _hasCompletedOrder {
    final status = _selectedOrder?['status']?.toString().toUpperCase();
    return const {'COMPLETED', 'DONE', 'FULFILLED'}.contains(status);
  }

  @override
  void initState() {
    super.initState();
    _selectedPlotCode = _orders.isNotEmpty
        ? _orders.first['plot_code']?.toString()
        : _plots.isEmpty
            ? null
            : _plots.first['plot_code']?.toString();
    _loadServices();
  }

  @override
  void didUpdateWidget(covariant ChamSocMoPhan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contracts != widget.contracts ||
        oldWidget.orders != widget.orders) {
      final valid = _plots
          .any((plot) => plot['plot_code']?.toString() == _selectedPlotCode);
      if (!valid) {
        _selectedPlotCode = _orders.isNotEmpty
            ? _orders.first['plot_code']?.toString()
            : _plots.isEmpty
                ? null
                : _plots.first['plot_code']?.toString();
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
      _serviceError = null;
    });
    try {
      final response = await ApiService.instance.get('/care-services');
      final rows = (response['data'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (mounted) setState(() => _services = rows);
    } catch (error) {
      if (mounted) {
        setState(() => _serviceError = _errorText(error));
      }
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([widget.onRefresh(), _loadServices()]);
  }

  @override
  Widget build(BuildContext context) {
    final checkoutService = _checkoutService;
    if (checkoutService != null && _selectedPlot != null) {
      return ThanhToanChamSoc(
        plot: _selectedPlot!,
        services: _services,
        initialService: checkoutService,
        onBack: () => setState(() => _checkoutService = null),
        onCompleted: () async {
          if (mounted) setState(() => _checkoutService = null);
          await widget.onRefresh();
        },
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: MauSala.xanhThe,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _plotHeader(),
                    const SizedBox(height: 16),
                    if (_selectedOrder == null)
                      _noReportPanel()
                    else
                      _reportArea(wide),
                    const SizedBox(height: 16),
                    _reviewPanel(),
                    const SizedBox(height: 24),
                    _serviceCatalog(wide),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _plotHeader() {
    final plot = _selectedPlot;
    final order = _selectedOrder;
    final completed = _isCompleted(order?['status']);
    return _panel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final selector = Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.roofing_outlined,
                  color: MauSala.xanhThe, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wrap(spacing: 6, children: [
                    _Tag('HỒ SƠ PHỤNG DƯỠNG', green: true),
                    _Tag('CHĂM SÓC TỪ XA'),
                  ]),
                  const SizedBox(height: 5),
                  if (_plots.isEmpty)
                    const Text('Chưa có mộ phần liên kết với tài khoản')
                  else
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPlot?['plot_code']?.toString(),
                        isExpanded: true,
                        items: _plots
                            .map((row) => DropdownMenuItem(
                                  value: row['plot_code'].toString(),
                                  child: Text(
                                    '${row['plot_code']} — ${row['beneficiary_display_name'] ?? row['beneficiary_name'] ?? row['zone_name'] ?? 'Mộ phần gia đình'}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedPlotCode = value),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
        final latest = Container(
          width: compact ? double.infinity : 240,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: MauSala.xanhNhat,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.circle,
                size: 11,
                color: order == null
                    ? MauSala.vien
                    : completed
                        ? MauSala.xanhDam
                        : MauSala.vang),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order == null
                          ? 'Chưa có lịch chăm sóc'
                          : completed
                              ? 'Dịch vụ đã hoàn tất'
                              : 'Dịch vụ đang xử lý',
                      style: const TextStyle(
                          fontSize: 13,
                          color: MauSala.xanhDam,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order == null
                          ? 'Đặt dịch vụ để nhận báo cáo tại đây.'
                          : '${order['service_name'] ?? 'Dịch vụ chăm sóc'} • ${_date(order['scheduled_date'])}',
                      style:
                          const TextStyle(fontSize: 10, color: MauSala.chuPhu),
                    ),
                  ]),
            ),
          ]),
        );
        return compact
            ? Column(children: [selector, const SizedBox(height: 12), latest])
            : Row(children: [
                Expanded(child: selector),
                const SizedBox(width: 18),
                latest
              ]);
      }),
    );
  }

  Widget _reportArea(bool wide) {
    final order = _selectedOrder!;
    final main = _comparisonPanel(order);
    final side = Column(children: [
      _receiptPanel(order),
      const SizedBox(height: 12),
      _photoGallery(),
    ]);
    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 6, child: main),
            const SizedBox(width: 14),
            Expanded(flex: 4, child: side),
          ])
        : Column(children: [main, const SizedBox(height: 12), side]);
  }

  Widget _comparisonPanel(Map<String, dynamic> order) => _panel(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Eyebrow('MINH CHỨNG THỰC TẾ'),
          const SizedBox(height: 4),
          Text('So sánh tương tác Trước & Sau',
              style: GoogleFonts.newsreader(
                  fontSize: 24,
                  height: 1.15,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _photoTile(
                    title: 'TRƯỚC KHI CHĂM SÓC',
                    url: null,
                    icon: Icons.grass_outlined,
                    dark: false)),
            const SizedBox(width: 8),
            Expanded(
              child: _photoTile(
                title: 'SAU KHI CHĂM SÓC',
                url: _proofImages.isEmpty
                    ? order['latest_proof_image_url']?.toString()
                    : _proofImages.first['image_url']?.toString(),
                icon: Icons.park_outlined,
                dark: true,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _infoLine(Icons.verified_outlined,
              'Ảnh nghiệm thu được gửi từ hồ sơ dịch vụ của gia đình.'),
          const SizedBox(height: 5),
          _infoLine(
              Icons.spa_outlined,
              (order['note'] ?? 'Nhân viên đã cập nhật tình trạng chăm sóc.')
                  .toString()),
        ]),
      );

  Widget _photoTile({
    required String title,
    required String? url,
    required IconData icon,
    required bool dark,
  }) =>
      AspectRatio(
        aspectRatio: 1.12,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(fit: StackFit.expand, children: [
            if (url != null && url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _scenicPlaceholder(icon, dark),
              )
            else
              _scenicPlaceholder(icon, dark),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .18), Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: dark
                      ? MauSala.xanhThe
                      : Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(title,
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: .25,
                        color: dark ? Colors.white : MauSala.xanhDam,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (url == null || url.isEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 40,
                        color: dark ? Colors.white70 : MauSala.xanhDam),
                    const SizedBox(height: 6),
                    Text(
                      title.contains('TRƯỚC')
                          ? 'Chưa có ảnh gốc trong hồ sơ'
                          : 'Chưa có ảnh nghiệm thu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.white : MauSala.xanhDam,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ),
      );

  Widget _scenicPlaceholder(IconData icon, bool dark) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFFBFD7C3), Color(0xFF1B4D3E)]
                : const [Color(0xFFDDEAF5), Color(0xFF96B7A7)],
          ),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
              top: 18,
              right: 20,
              child: Icon(Icons.wb_sunny_outlined,
                  color: Colors.white.withValues(alpha: .55), size: 26)),
          Positioned(
              bottom: 15,
              left: 18,
              child: Icon(Icons.grass,
                  color: Colors.white.withValues(alpha: .55), size: 42)),
          Icon(icon, color: Colors.white.withValues(alpha: .85), size: 48),
        ]),
      );

  Widget _receiptPanel(Map<String, dynamic> order) => _panel(
        padding: const EdgeInsets.all(15),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.fact_check_outlined,
                color: MauSala.xanhThe, size: 21),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Phiếu Xác Nhận Công Tác',
                    style: TextStyle(
                        fontSize: 16,
                        color: MauSala.chu,
                        fontWeight: FontWeight.w700))),
            _Tag('MÃ: ${order['order_code'] ?? 'ĐANG CẬP NHẬT'}', green: true),
          ]),
          const Divider(height: 20),
          _detailTile(Icons.schedule_outlined, 'Ngày thực hiện',
              _date(order['scheduled_date'])),
          const SizedBox(height: 8),
          _detailTile(
              Icons.person_pin_circle_outlined,
              'Nhân viên phụ trách',
              _proofImages.isEmpty
                  ? (order['worker_name'] ?? 'Chưa cập nhật').toString()
                  : (_proofImages.first['worker_name'] ?? 'Chưa cập nhật')
                      .toString()),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(7)),
            child: Text(
              (order['latest_proof_note'] ??
                      order['note'] ??
                      'Chưa có ghi chú nghiệm thu cho dịch vụ này.')
                  .toString(),
              style: const TextStyle(
                  color: MauSala.chuPhu, fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _proofImages.isEmpty
                  ? null
                  : () => _openProof(_proofImages.first['image_url']),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Mở ảnh nghiệm thu'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyText(
                  order['order_code']?.toString() ?? '', 'Đã sao chép mã đơn.'),
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Sao chép mã'),
            ),
          ]),
        ]),
      );

  Widget _photoGallery() => _panel(
        padding: const EdgeInsets.all(13),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Eyebrow('ẢNH NGHIỆM THU'),
          const SizedBox(height: 8),
          if (_proofImages.isEmpty)
            Container(
              height: 108,
              decoration: BoxDecoration(
                  color: MauSala.xanhNhat,
                  borderRadius: BorderRadius.circular(7)),
              child: const Center(
                  child: Text('Chưa có ảnh nghiệm thu được tải lên.',
                      style: TextStyle(fontSize: 11, color: MauSala.chuPhu))),
            )
          else
            GridView.builder(
              itemCount: _proofImages.length.clamp(1, 4).toInt(),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 1.5),
              itemBuilder: (context, index) {
                final proof = _proofImages[index];
                final url = proof['image_url']?.toString() ?? '';
                return InkWell(
                  onTap: () => _openProof(url),
                  borderRadius: BorderRadius.circular(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _scenicPlaceholder(Icons.photo_outlined, true)),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(6),
                          color: Colors.black54,
                          child: Text('Ảnh nghiệm thu ${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
        ]),
      );

  Widget _noReportPanel() => _panel(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.spa_outlined,
                size: 31, color: MauSala.xanhThe),
          ),
          const SizedBox(height: 12),
          Text(
            _plots.isEmpty
                ? 'Chưa có mộ phần liên kết để chăm sóc'
                : 'Chưa có báo cáo chăm sóc cho mộ này',
            textAlign: TextAlign.center,
            style: GoogleFonts.newsreader(
                fontSize: 23,
                color: MauSala.xanhDam,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _plots.isEmpty
                ? 'Khi hợp đồng mộ phần được liên kết với tài khoản, bạn có thể đặt dịch vụ chăm sóc từ xa tại đây.'
                : 'Đặt dịch vụ chăm sóc để theo dõi lịch thực hiện và nhận ảnh nghiệm thu trực tuyến.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: MauSala.chuPhu, height: 1.5),
          ),
          const SizedBox(height: 12),
          if (_plots.isEmpty)
            FilledButton.icon(
                onPressed: widget.onOpenContracts,
                icon: const Icon(Icons.description_outlined, size: 17),
                label: const Text('Xem hợp đồng gia đình'),
                style: FilledButton.styleFrom(
                    backgroundColor: MauSala.xanhThe,
                    foregroundColor: Colors.white))
          else
            OutlinedButton.icon(
                onPressed: () => _scrollToCatalog(),
                icon: const Icon(Icons.arrow_downward, size: 16),
                label: const Text('Chọn dịch vụ chăm sóc')),
        ]),
      );

  Widget _reviewPanel() {
    final order = _selectedOrder;
    final existingRating =
        int.tryParse(order?['review_rating']?.toString() ?? '');
    final alreadyReviewed = existingRating != null;
    return _panel(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _Eyebrow('NGHIỆM THU DỊCH VỤ TỪ XA'),
        const SizedBox(height: 4),
        Text('Kiểm Duyệt Kết Quả & Đánh Giá Chất Lượng',
            textAlign: TextAlign.center,
            style: GoogleFonts.newsreader(
                fontSize: 27, color: MauSala.chu, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Text(
          order == null
              ? 'Đánh giá sẽ mở sau khi gia đình có đơn chăm sóc hoàn tất.'
              : 'Sự hài lòng của gia đình giúp đội ngũ chăm sóc hoàn thiện chất lượng phục vụ.',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 12, color: MauSala.chuPhu, height: 1.5),
        ),
        const SizedBox(height: 12),
        if (order != null) ...[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                tooltip: '$i sao',
                onPressed: !_hasCompletedOrder || alreadyReviewed
                    ? null
                    : () => setState(() => _rating = i),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  i <= (existingRating ?? _rating)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 30,
                  color: MauSala.vang,
                ),
              ),
            const SizedBox(width: 4),
            Text(
              alreadyReviewed
                  ? '$existingRating.0 — Đã gửi đánh giá'
                  : '${_rating.toString()}.0 — ${_rating >= 5 ? 'Rất Hài Lòng' : 'Hài Lòng'}',
              style: const TextStyle(
                  fontSize: 12,
                  color: MauSala.vang,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              alreadyReviewed
                  ? 'LỜI NHẮN CỦA GIA ĐÌNH'
                  : 'LỜI CẢM ƠN HOẶC CĂN DẶN RIÊNG CHO ĐỘI NGŨ CHĂM SÓC',
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: .35,
                  color: MauSala.vang,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 5),
          if (alreadyReviewed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: MauSala.xanhNhat,
                  borderRadius: BorderRadius.circular(7)),
              child: Text(
                (order['review_comment'] ?? 'Gia đình đã xác nhận nghiệm thu.')
                    .toString(),
                style: const TextStyle(
                    fontSize: 12, color: MauSala.chuPhu, height: 1.45),
              ),
            )
          else
            TextField(
              controller: _reviewController,
              minLines: 2,
              maxLines: 4,
              enabled: _hasCompletedOrder && !_sendingReview,
              decoration: InputDecoration(
                hintText: _hasCompletedOrder
                    ? 'Ví dụ: Cảm ơn các bạn đã chăm sóc chu đáo...'
                    : 'Chỉ đánh giá sau khi dịch vụ hoàn tất.',
                hintStyle: const TextStyle(fontSize: 11, color: MauSala.chuPhu),
                filled: true,
                fillColor: MauSala.xanhNhat,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed:
                    !_hasCompletedOrder || alreadyReviewed || _sendingReview
                        ? null
                        : () => _submitReview(order),
                icon: _sendingReview
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(alreadyReviewed
                    ? 'Đã Xác Nhận Nghiệm Thu'
                    : 'Xác Nhận Nghiệm Thu Đạt Chuẩn'),
                style: FilledButton.styleFrom(
                    backgroundColor: MauSala.xanhDam,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14)),
              ),
              OutlinedButton.icon(
                onPressed: () => _scrollToCatalog(),
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('Gửi Yêu Cầu Chăm Sóc Thêm'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: MauSala.vang,
                    side: const BorderSide(color: MauSala.xanhNenThe),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14)),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 6),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _scrollToCatalog(),
              icon: const Icon(Icons.spa_outlined, size: 17),
              label: const Text('Xem dịch vụ chăm sóc'),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _serviceCatalog(bool wide) => Column(
        key: _catalogKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('PHỤNG DƯỠNG CHU TOÀN'),
                    Text('Danh Mục Dịch Vụ Chăm Sóc Đặt Thêm',
                        style: GoogleFonts.newsreader(
                            fontSize: 27,
                            color: MauSala.chu,
                            fontWeight: FontWeight.w500)),
                  ]),
            ),
            if (wide && _plots.isNotEmpty)
              FilledButton.icon(
                onPressed: _services.isEmpty
                    ? null
                    : () => _bookService(_services.first),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Đặt Thêm Dịch Vụ Mới'),
                style: FilledButton.styleFrom(
                    backgroundColor: MauSala.xanhDam,
                    foregroundColor: Colors.white),
              ),
          ]),
          const SizedBox(height: 12),
          if (_serviceError != null) _errorNotice(_serviceError!),
          if (_loadingServices)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                  child: CircularProgressIndicator(color: MauSala.xanhThe)),
            )
          else if (_services.isEmpty)
            _panel(
                child: const Text('Chưa có dịch vụ chăm sóc trong danh mục.',
                    style: TextStyle(color: MauSala.chuPhu, fontSize: 12)))
          else
            LayoutBuilder(builder: (context, constraints) {
              final count = constraints.maxWidth >= 1050
                  ? 4
                  : constraints.maxWidth >= 650
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _services.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 350,
                ),
                itemBuilder: (context, index) =>
                    _serviceCard(_services[index], index),
              );
            }),
        ],
      );

  Widget _serviceCard(Map<String, dynamic> service, int index) {
    final icon = switch (index % 4) {
      0 => Icons.local_florist_outlined,
      1 => Icons.cleaning_services_outlined,
      2 => Icons.ramen_dining_outlined,
      _ => Icons.park_outlined,
    };
    final badge = switch (index % 4) {
      0 => 'PHỔ BIẾN NHẤT',
      1 => 'CHUYÊN SÂU',
      2 => 'NGHI LỄ TRỌN GÓI',
      _ => 'ĐỊNH KỲ THÁNG',
    };
    final price = _number(service['price']);
    return _panel(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(fit: StackFit.expand, children: [
              _scenicPlaceholder(icon, index.isEven),
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: index == 0 ? MauSala.vang : MauSala.xanhThe,
                      borderRadius: BorderRadius.circular(3)),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          letterSpacing: .3,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(service['service_name']?.toString() ?? 'Dịch vụ chăm sóc',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.newsreader(
                fontSize: 18,
                height: 1.15,
                color: MauSala.chu,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Expanded(
          child: Text(
            service['description']?.toString() ??
                'Đội ngũ Sala Garden thực hiện chu đáo theo lịch gia đình lựa chọn.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11, color: MauSala.chuPhu, height: 1.45),
          ),
        ),
        Row(children: [
          const Expanded(
              child: Text('CHI PHÍ THAM KHẢO',
                  style: TextStyle(
                      fontSize: 9,
                      color: MauSala.chuPhu,
                      fontWeight: FontWeight.w600))),
          Text(GiaThamKhao.dinhDang(price),
              style: GoogleFonts.newsreader(
                  fontSize: 18,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _plots.isEmpty
              ? widget.onOpenContracts
              : () => _bookService(service),
          icon: Icon(
              _plots.isEmpty
                  ? Icons.description_outlined
                  : Icons.add_shopping_cart_outlined,
              size: 16),
          label: Text(_plots.isEmpty ? 'Liên Kết Hợp Đồng' : 'Chọn Đăng Ký'),
          style: FilledButton.styleFrom(
            backgroundColor: index == 2 ? MauSala.vang : MauSala.xanhNhat,
            foregroundColor: index == 2 ? Colors.white : MauSala.xanhDam,
            minimumSize: const Size.fromHeight(40),
          ),
        ),
      ]),
    );
  }

  Future<void> _bookService(Map<String, dynamic> service) async {
    if (_plots.isEmpty) {
      widget.onOpenContracts();
      return;
    }
    setState(() => _checkoutService = service);
  }

  Future<void> _submitReview(Map<String, dynamic> order) async {
    setState(() => _sendingReview = true);
    try {
      await ApiService.instance.post('/care-orders/${order['id']}/review', {
        'rating': _rating,
        'comment': _reviewController.text.trim(),
      });
      if (!mounted) return;
      _showMessage('Đã lưu xác nhận nghiệm thu và đánh giá của gia đình.');
      await widget.onRefresh();
    } catch (error) {
      if (mounted) _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _sendingReview = false);
    }
  }

  void _scrollToCatalog() {
    final target = _catalogKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: .08);
    }
  }

  Future<void> _openProof(dynamic value) async {
    final url = value?.toString() ?? '';
    if (url.isEmpty) {
      _showMessage('Đơn này chưa có ảnh nghiệm thu.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) _showMessage('Đã sao chép liên kết ảnh nghiệm thu.');
  }

  Future<void> _copyText(String text, String message) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showMessage(message);
  }

  Widget _detailTile(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Icon(icon, color: MauSala.xanhThe, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 10, color: MauSala.chuPhu))),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 11,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _infoLine(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MauSala.vang, size: 15),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 10, color: MauSala.chuPhu, height: 1.4))),
        ],
      );

  Widget _errorNotice(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 17),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF93000A)))),
          TextButton(onPressed: _loadServices, child: const Text('Thử lại')),
        ]),
      );

  Widget _panel({required Widget child, EdgeInsets? padding}) => Container(
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE7EDF3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D1B4D3E), blurRadius: 12, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  String _date(dynamic value) {
    if (value == null) return 'Chưa lên lịch';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  bool _isCompleted(dynamic status) => const {'COMPLETED', 'DONE', 'FULFILLED'}
      .contains(status?.toString().toUpperCase());

  int _number(dynamic value) => value is num
      ? value.round()
      : num.tryParse(value?.toString() ?? '')?.round() ?? 0;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.green = false});
  final String text;
  final bool green;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: green ? const Color(0xFFDDEFE6) : MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: green ? MauSala.xanhDam : MauSala.chuPhu,
                fontSize: 8,
                letterSpacing: .3,
                fontWeight: FontWeight.w700)),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 9,
          color: MauSala.vang,
          letterSpacing: .65,
          fontWeight: FontWeight.w700));
}

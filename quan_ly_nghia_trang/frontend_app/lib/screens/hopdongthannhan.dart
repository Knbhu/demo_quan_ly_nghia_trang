import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/api_service.dart';
import '../core/mausala.dart';
import 'laphopdongmoi.dart';

class HopDongThanNhan extends StatefulWidget {
  const HopDongThanNhan({
    super.key,
    required this.contracts,
    required this.user,
    required this.loading,
    this.error,
    this.initialPlot,
    required this.onRefresh,
    required this.onChoosePlot,
    required this.onContractCreated,
    required this.onCancelDraft,
  });

  final List<dynamic> contracts;
  final Map<String, dynamic>? user;
  final bool loading;
  final String? error;
  final Map<String, dynamic>? initialPlot;
  final Future<void> Function() onRefresh;
  final VoidCallback onChoosePlot;
  final Future<void> Function(Map<String, dynamic> contract) onContractCreated;
  final VoidCallback onCancelDraft;

  @override
  State<HopDongThanNhan> createState() => _HopDongThanNhanState();
}

class _HopDongThanNhanState extends State<HopDongThanNhan> {
  int _tab = 0;
  int _selectedIndex = 0;
  bool _showNewContract = false;
  Future<List<Map<String, dynamic>>>? _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _showNewContract = widget.initialPlot != null;
  }

  @override
  void didUpdateWidget(covariant HopDongThanNhan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contracts != widget.contracts) _paymentsFuture = null;
    if (oldWidget.initialPlot?['plot_code'] !=
            widget.initialPlot?['plot_code'] &&
        widget.initialPlot != null) {
      _showNewContract = true;
      _tab = 0;
    }
  }

  Map<String, dynamic>? get _contract {
    if (widget.contracts.isEmpty) return null;
    final index = _selectedIndex.clamp(0, widget.contracts.length - 1).toInt();
    return Map<String, dynamic>.from(widget.contracts[index] as Map);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: MauSala.xanhThe,
            child: ListView(
              // Reset the scroll position when switching between the form,
              // contract detail and payment history. Otherwise a long form's
              // saved offset can leave the newly selected screen scrolled past
              // its visible content.
              key: PageStorageKey<String>(
                  'hop-dong-$_tab-${_showNewContract ? "new" : _selectedIndex}'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _pageHeading(wide),
                        const SizedBox(height: 14),
                        _toolbar(),
                        if (widget.error != null) ...[
                          const SizedBox(height: 10),
                          _errorNotice(widget.error!),
                        ],
                        if (!_showNewContract &&
                            _tab == 0 &&
                            widget.contracts.length > 1) ...[
                          const SizedBox(height: 12),
                          _contractPicker(),
                        ],
                        const SizedBox(height: 14),
                        if (_showNewContract)
                          _newContractScreen()
                        else if (widget.loading && widget.contracts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: MauSala.xanhThe)),
                          )
                        else if (_tab == 1)
                          _paymentHistory()
                        else
                          _contractWorkspace(wide),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _pageHeading(bool wide) {
    final contract = _contract;
    final code = contract?['contract_code']?.toString();
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Text('KINH DOANH & PHÁP LÝ',
              style: TextStyle(
                  fontSize: 9, letterSpacing: .7, color: MauSala.chuPhu)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.chevron_right, size: 14, color: MauSala.vien),
          ),
          Flexible(
            child: Text('QUẢN LÝ HỢP ĐỒNG & THANH TOÁN',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: .5,
                    color: MauSala.vang,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Hợp Đồng Dưỡng Sanh & Trả Góp',
            style: GoogleFonts.newsreader(
                fontSize: wide ? 27 : 23,
                height: 1.1,
                color: MauSala.xanhDam,
                fontWeight: FontWeight.w600)),
      ],
    );
    final badges = Wrap(spacing: 8, runSpacing: 8, children: [
      _trustPill(Icons.verified_user_outlined, 'HỢP ĐỒNG ĐIỆN TỬ',
          'Hồ sơ được lưu an toàn'),
      _trustPill(Icons.account_balance_outlined, 'THANH TOÁN',
          'Theo thông tin hợp đồng'),
      if (code != null && code.isNotEmpty) _tag('Mã hồ sơ: $code', gold: true),
    ]);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 10), badges],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        Flexible(child: badges),
      ],
    );
  }

  Widget _toolbar() => Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFDDEAF5))),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _tabButton(
              'Hợp Đồng Của Tôi',
              Icons.description_outlined,
              selected: !_showNewContract && _tab == 0,
              onTap: () => setState(() {
                _tab = 0;
                _showNewContract = false;
              }),
            ),
            _tabButton(
              'Lịch Sử Giao Dịch & Thanh Toán',
              Icons.receipt_long_outlined,
              selected: _tab == 1,
              onTap: _showPayments,
            ),
            _tabButton(
              'Lập Hợp Đồng Mới',
              Icons.note_add_outlined,
              selected: _showNewContract,
              onTap: () => setState(() {
                _tab = 0;
                _showNewContract = true;
              }),
              gold: true,
            ),
          ],
        ),
      );

  Widget _contractWorkspace(bool wide) {
    final contract = _contract;
    if (contract == null) {
      return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 7, child: _emptyContract()),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: _emptyPaymentSide()),
            ])
          : Column(children: [
              _emptyContract(),
              const SizedBox(height: 12),
              _emptyPaymentSide(),
            ]);
    }

    final main =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _steps(activeStep: 3),
      const SizedBox(height: 12),
      _productSection(contract),
      const SizedBox(height: 12),
      _peopleSection(contract),
      const SizedBox(height: 12),
      _paymentSection(contract),
      const SizedBox(height: 12),
      _bottomActions(contract),
    ]);
    final side =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (contract['status']?.toString().toUpperCase() == 'PENDING')
        _pendingPaymentCard(contract)
      else
        _paymentCard(contract),
      const SizedBox(height: 12),
      _progressCard(contract),
      const SizedBox(height: 12),
      _legalCard(contract),
    ]);
    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 7, child: main),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: side),
          ])
        : Column(children: [main, const SizedBox(height: 12), side]);
  }

  Widget _newContractScreen() => LapHopDongMoi(
        plot: widget.initialPlot,
        user: widget.user,
        onChoosePlot: widget.onChoosePlot,
        onCancel: () {
          widget.onCancelDraft();
          setState(() => _showNewContract = false);
        },
        onCreated: (contract) async {
          setState(() {
            _showNewContract = false;
            _tab = 0;
          });
          await widget.onContractCreated(contract);
        },
      );

  Widget _contractPicker() => _panel(
        child: Row(children: [
          const Icon(Icons.folder_open_outlined,
              color: MauSala.xanhThe, size: 18),
          const SizedBox(width: 8),
          const Text('Chọn hồ sơ',
              style: TextStyle(
                  fontSize: 11,
                  color: MauSala.chuPhu,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedIndex
                    .clamp(0, widget.contracts.length - 1)
                    .toInt(),
                isExpanded: true,
                items: List.generate(widget.contracts.length, (index) {
                  final item =
                      Map<String, dynamic>.from(widget.contracts[index] as Map);
                  return DropdownMenuItem(
                    value: index,
                    child: Text(
                      '${item['contract_code'] ?? 'Hợp đồng'}  •  ${item['plot_code'] ?? 'Chưa có mã mộ'}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedIndex = value);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tải lại dữ liệu hợp đồng',
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ]),
      );

  Widget _steps({required int activeStep}) => _panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          _stepItem('01', 'Vị Trí & Kim Tĩnh', activeStep >= 1),
          _stepLine(activeStep >= 2),
          _stepItem('02', 'Thân Nhân & Thụ Hưởng', activeStep >= 2),
          _stepLine(activeStep >= 3),
          _stepItem('03', 'Thanh Toán & Trả Góp', activeStep >= 3),
        ]),
      );

  Widget _stepItem(String number, String label, bool active) => Expanded(
        child: Row(children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: active ? MauSala.xanhThe : MauSala.xanhNenThe,
              borderRadius: BorderRadius.circular(7),
              border: active
                  ? Border.all(color: MauSala.vangThe, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(number,
                style: TextStyle(
                    color: active ? Colors.white : MauSala.chuPhu,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BƯỚC $number',
                    style: const TextStyle(
                        color: MauSala.vang,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: MauSala.xanhDam,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      );

  Widget _stepLine(bool active) => Container(
        width: 18,
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: active ? MauSala.vang : MauSala.vien,
      );

  Widget _productSection(Map<String, dynamic> contract) => _section(
        title: '01. Sản Phẩm & Kim Tĩnh Đã Chọn',
        icon: Icons.landscape_outlined,
        trailing: _tag(_statusLabel(contract['status']),
            gold: _statusLabel(contract['status']) != 'Đang hiệu lực'),
        // This section sits inside a vertical ListView, so its height is
        // unbounded. A stretched Row there can pass an infinite height to its
        // children and make Flutter stop building the whole page after a new
        // contract is created. IntrinsicHeight gives the two cards a finite,
        // shared height before stretching them to match.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 142),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB9D5C6), Color(0xFF1B4D3E)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.park_outlined,
                          size: 27, color: Colors.white),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (contract['zone_name'] ?? 'Phân khu Sala Garden')
                                .toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 9),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (contract['plot_code'] ?? 'Mã mộ đang cập nhật')
                                .toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MauSala.xanhNhat,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoPair(
                          'LOẠI MỘ PHẦN', _plotType(contract['plot_type'])),
                      const SizedBox(height: 10),
                      _infoPair(
                        'PHÂN KHU',
                        (contract['zone_name'] ?? 'Đang cập nhật').toString(),
                      ),
                      const SizedBox(height: 10),
                      _infoPair(
                        'MÃ KIM TĨNH',
                        (contract['plot_code'] ?? 'Đang cập nhật').toString(),
                      ),
                      const SizedBox(height: 10),
                      _infoPair(
                        'MÃ HỒ SƠ',
                        (contract['contract_code'] ?? 'Đang cập nhật')
                            .toString(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _peopleSection(Map<String, dynamic> contract) => _section(
        title: '02. Thông Tin Khách Hàng & Người Thụ Hưởng',
        icon: Icons.groups_outlined,
        trailing: _tag('Theo hồ sơ đã liên kết'),
        child: LayoutBuilder(builder: (context, constraints) {
          final stacked = constraints.maxWidth < 500;
          final customer = (widget.user?['full_name'] ??
                  contract['customer_name'] ??
                  'Thân nhân Sala Garden')
              .toString();
          final beneficiary = (contract['beneficiary_display_name'] ??
                  contract['beneficiary_name'])
              ?.toString();
          final cards = [
            _personCard(
              title: 'BÊN ĐỨNG TÊN HỢP ĐỒNG',
              name: customer,
              detail: (widget.user?['phone'] ??
                      contract['customer_phone'] ??
                      'Thông tin liên hệ được bảo mật')
                  .toString(),
              icon: Icons.person_outline,
              background: MauSala.xanhNhat,
            ),
            _personCard(
              title: 'NGƯỜI THỤ HƯỞNG / HƯƠNG LINH',
              name: (beneficiary == null || beneficiary.isEmpty)
                  ? 'Chưa có thông tin thụ hưởng'
                  : beneficiary,
              detail: (contract['beneficiary_relationship'] ??
                      contract['dharma_name'] ??
                      'Thông tin thụ hưởng theo hợp đồng')
                  .toString(),
              icon: Icons.account_circle_outlined,
              background: const Color(0xFFF6F7F4),
            ),
          ];
          return stacked
              ? Column(
                  children: [cards[0], const SizedBox(height: 8), cards[1]])
              : Row(children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[1]),
                ]);
        }),
      );

  Widget _paymentSection(Map<String, dynamic> contract) {
    final total = _number(contract['total_amount']);
    final paid = _paidAmount(contract);
    final remaining = (total - paid).clamp(0, total);
    return _section(
      title: '03. Tiến Độ Thanh Toán',
      icon: Icons.payments_outlined,
      trailing: _tag(_paymentType(contract['payment_type']), gold: true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: _amountTile('TỔNG GIÁ TRỊ HỢP ĐỒNG', _money(total))),
          const SizedBox(width: 8),
          Expanded(
              child: _amountTile('ĐÃ GHI NHẬN', _money(paid), green: true)),
          const SizedBox(width: 8),
          Expanded(
              child: _amountTile('CÒN LẠI', _money(remaining), gold: true)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0).toDouble(),
            backgroundColor: MauSala.xanhNenThe,
            valueColor: const AlwaysStoppedAnimation(MauSala.xanhThe),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${_percent(total <= 0 ? 0 : paid / total)}% giá trị đã được ghi nhận trong hồ sơ.',
          style: const TextStyle(fontSize: 10, color: MauSala.chuPhu),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE5EDF4)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.history, size: 16, color: MauSala.vang),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_number(contract['payment_count']).toInt()} giao dịch đã ghi nhận',
              style: const TextStyle(
                  fontSize: 10,
                  color: MauSala.chuPhu,
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (contract['last_payment_at'] != null)
            Text('Gần nhất: ${_date(contract['last_payment_at'])}',
                style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]),
      ]),
    );
  }

  Widget _paymentCard(Map<String, dynamic> contract) {
    final total = _number(contract['total_amount']);
    final paid = _paidAmount(contract);
    final remaining = (total - paid).clamp(0, total);
    return _panel(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: 4,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            gradient: LinearGradient(
                colors: [MauSala.vang, MauSala.vangThe, MauSala.xanhThe]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.qr_code_2, color: MauSala.xanhThe, size: 20),
              const SizedBox(width: 7),
              const Expanded(
                child: Text('THANH TOÁN HỢP ĐỒNG',
                    style: TextStyle(
                        fontSize: 10,
                        color: MauSala.xanhDam,
                        fontWeight: FontWeight.w700)),
              ),
              _tag('An toàn'),
            ]),
            const SizedBox(height: 12),
            Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 70, color: MauSala.xanhThe),
                    SizedBox(height: 4),
                    Text('MÃ THANH TOÁN',
                        style: TextStyle(
                            fontSize: 8,
                            letterSpacing: .7,
                            color: MauSala.chuPhu,
                            fontWeight: FontWeight.w700)),
                  ]),
            ),
            const SizedBox(height: 10),
            const Text('SỐ DƯ CÒN LẠI THEO HỒ SƠ',
                style: TextStyle(fontSize: 8, color: MauSala.chuPhu)),
            const SizedBox(height: 3),
            Text(_money(remaining),
                style: GoogleFonts.newsreader(
                    fontSize: 20,
                    color: MauSala.vang,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: MauSala.xanhNhat,
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: MauSala.vang, size: 15),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mã QR thanh toán sẽ được cấp theo chứng từ xác thực của hợp đồng.',
                        style: TextStyle(
                            fontSize: 9, height: 1.35, color: MauSala.chuPhu),
                      ),
                    ),
                  ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _pendingPaymentCard(Map<String, dynamic> contract) => _panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.hourglass_top_rounded,
              color: MauSala.vang, size: 34),
          const SizedBox(height: 8),
          Text('Hồ sơ đang chờ xác nhận',
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                  fontSize: 18,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(
            'Ban Quản Khách sẽ xác nhận giá, phương thức thanh toán và lịch dự kiến cho hồ sơ ${contract['contract_code'] ?? ''}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, height: 1.45, color: MauSala.chuPhu),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Cập nhật trạng thái'),
            style: FilledButton.styleFrom(
                backgroundColor: MauSala.xanhDam,
                foregroundColor: Colors.white),
          ),
          const SizedBox(height: 5),
          const Text('Chưa tạo mã QR và chưa ghi nhận thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: MauSala.chuPhu)),
        ]),
      );

  Widget _progressCard(Map<String, dynamic> contract) {
    final total = _number(contract['total_amount']);
    final paid = _paidAmount(contract);
    return _section(
      title: 'Tiến Độ Thu Tiền',
      icon: Icons.donut_large,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: total <= 0
                      ? 0.0
                      : (paid / total).clamp(0.0, 1.0).toDouble(),
                  strokeWidth: 7,
                  backgroundColor: MauSala.xanhNenThe,
                  valueColor: const AlwaysStoppedAnimation(MauSala.xanhThe),
                ),
              ),
              Text('${_percent(total <= 0 ? 0 : paid / total)}%',
                  style: const TextStyle(
                      color: MauSala.xanhDam,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _miniAmount('ĐÃ GHI NHẬN', _money(paid)),
              const SizedBox(height: 9),
              _miniAmount(
                  'DƯ NỢ CÒN LẠI', _money((total - paid).clamp(0, total)),
                  gold: true),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _infoNotice(Icons.verified_user_outlined,
            'Số tiền và tiến độ được tính từ dữ liệu giao dịch đã lưu trong hệ thống.'),
      ]),
    );
  }

  Widget _legalCard(Map<String, dynamic> contract) => _section(
        title: 'Hồ Sơ Pháp Lý',
        icon: Icons.folder_open_outlined,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _fileRow(Icons.description_outlined,
              'Hợp đồng ${contract['contract_code'] ?? ''}'),
          const SizedBox(height: 7),
          _fileRow(Icons.landscape_outlined,
              'Thông tin vị trí ${contract['plot_code'] ?? ''}'),
          const SizedBox(height: 9),
          const Text(
            'Tệp PDF và chứng thư số sẽ xuất hiện khi được tải lên hồ sơ.',
            style: TextStyle(fontSize: 9, color: MauSala.chuPhu, height: 1.35),
          ),
        ]),
      );

  Widget _bottomActions(Map<String, dynamic> contract) => _panel(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 260,
              child: Text(
                'Hồ sơ ${contract['contract_code'] ?? ''}  •  ${_statusLabel(contract['status'])}',
                style: const TextStyle(
                    fontSize: 10,
                    color: MauSala.chuPhu,
                    fontWeight: FontWeight.w600),
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh, size: 14),
              label:
                  const Text('Cập Nhật Hồ Sơ', style: TextStyle(fontSize: 10)),
            ),
            FilledButton.icon(
              onPressed: widget.onChoosePlot,
              style: FilledButton.styleFrom(
                  backgroundColor: MauSala.xanhDam,
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.map_outlined, size: 14),
              label: const Text('Mở Sơ Đồ Mặt Bằng',
                  style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      );

  Widget _paymentHistory() {
    if (widget.contracts.isEmpty) {
      return _emptyPanel(
        icon: Icons.receipt_long_outlined,
        title: 'Chưa có lịch sử thanh toán',
        body:
            'Giao dịch sẽ hiển thị tại đây sau khi được ghi nhận vào hợp đồng của bạn.',
        action: 'Xem hợp đồng của tôi',
        onPressed: () => setState(() => _tab = 0),
      );
    }
    _paymentsFuture ??= _loadPayments();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(44),
            child: Center(
                child: CircularProgressIndicator(color: MauSala.xanhThe)),
          );
        }
        if (snapshot.hasError) {
          return _emptyPanel(
            icon: Icons.cloud_off_outlined,
            title: 'Chưa tải được lịch sử giao dịch',
            body: snapshot.error.toString().replaceFirst('Exception: ', ''),
            action: 'Thử lại',
            onPressed: _showPayments,
          );
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return _emptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch được ghi nhận',
            body:
                'Khi có khoản thanh toán được lưu vào hợp đồng, biên nhận và trạng thái sẽ xuất hiện ở đây.',
            action: 'Xem hợp đồng của tôi',
            onPressed: () => setState(() => _tab = 0),
          );
        }
        return _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('LỊCH SỬ GIAO DỊCH THỰC TẾ',
                  style: TextStyle(
                      fontSize: 10,
                      color: MauSala.vang,
                      letterSpacing: .6,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...rows.map(_paymentRow),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPayments() async {
    final rows = <Map<String, dynamic>>[];
    for (final value in widget.contracts) {
      final contract = Map<String, dynamic>.from(value as Map);
      final id = contract['id'];
      if (id == null) continue;
      final result = await ApiService.instance.get('/contracts/$id/payments');
      for (final payment in List<dynamic>.from(result['data'] as List)) {
        rows.add({
          ...Map<String, dynamic>.from(payment as Map),
          'contract_code': contract['contract_code'],
          'plot_code': contract['plot_code'],
        });
      }
    }
    return rows;
  }

  void _showPayments() {
    setState(() {
      _tab = 1;
      _showNewContract = false;
      _paymentsFuture = _loadPayments();
    });
  }

  Widget _paymentRow(Map<String, dynamic> payment) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.receipt_long_outlined,
                color: MauSala.xanhThe, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${payment['contract_code'] ?? 'Hợp đồng'}  •  Đợt ${payment['payment_phase'] ?? ''}',
                style: const TextStyle(
                    color: MauSala.xanhDam,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '${payment['plot_code'] ?? ''}  •  ${_date(payment['payment_date'])}  •  ${_paymentMethod(payment['payment_method'])}',
                style: const TextStyle(color: MauSala.chuPhu, fontSize: 9),
              ),
              if (payment['note'] != null &&
                  payment['note'].toString().trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(payment['note'].toString(),
                    style: const TextStyle(color: MauSala.chuPhu, fontSize: 8)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Text(_money(_number(payment['amount'])),
              style: const TextStyle(
                  color: MauSala.xanhThe,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  String _paymentMethod(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'BANK_TRANSFER':
        return 'Chuyển khoản';
      case 'CASH':
        return 'Tiền mặt';
      case 'CARD':
        return 'Thẻ ngân hàng';
      default:
        return value?.toString() ?? 'Phương thức chưa cập nhật';
    }
  }

  Widget _emptyContract() => Column(children: [
        _steps(activeStep: 1),
        const SizedBox(height: 12),
        _emptyPanel(
          icon: widget.error == null
              ? Icons.description_outlined
              : Icons.cloud_off_outlined,
          title: widget.error == null
              ? 'Tài khoản chưa có hợp đồng liên kết'
              : 'Chưa tải được dữ liệu hợp đồng',
          body: widget.error == null
              ? 'Khi hợp đồng được lập hoặc liên kết với tài khoản của bạn, thông tin kim tĩnh, người thụ hưởng, tiến độ trả góp và chứng từ sẽ xuất hiện tại đây.'
              : 'Tải lại dữ liệu để kiểm tra các hợp đồng đang liên kết với tài khoản của bạn.',
          action: widget.error == null ? 'Lập hợp đồng mới' : 'Thử tải lại',
          onPressed: widget.error == null
              ? () => setState(() => _showNewContract = true)
              : widget.onRefresh,
        ),
        const SizedBox(height: 12),
        _infoNotice(Icons.lock_outline,
            'Hồ sơ hợp đồng chỉ hiển thị sau khi được xác thực và liên kết với tài khoản thân nhân.'),
      ]);

  Widget _emptyPaymentSide() => Column(children: [
        _panel(
          child: Column(children: [
            const Icon(Icons.qr_code_2, color: MauSala.xanhThe, size: 36),
            const SizedBox(height: 8),
            Text('Thanh Toán Hợp Đồng',
                style: GoogleFonts.newsreader(
                    fontSize: 18,
                    color: MauSala.xanhDam,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            const Text(
              'Mã thanh toán sẽ được tạo theo hợp đồng đã xác thực.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: MauSala.chuPhu, fontSize: 10, height: 1.4),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _section(
          title: 'Quy Trình Tiếp Theo',
          icon: Icons.timeline,
          child: Column(children: [
            _workflowRow('01', 'Chọn vị trí mộ trên sơ đồ'),
            _workflowRow('02', 'Ban tư vấn xác nhận hồ sơ'),
            _workflowRow('03', 'Theo dõi hợp đồng và thanh toán'),
          ]),
        ),
      ]);

  Widget _workflowRow(String number, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: MauSala.xanhNhat, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(
                    color: MauSala.xanhThe,
                    fontSize: 8,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
          ),
        ]),
      );

  Widget _emptyPanel({
    required IconData icon,
    required String title,
    required String body,
    required String action,
    required VoidCallback onPressed,
  }) =>
      _panel(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: MauSala.xanhThe, size: 27),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                  fontSize: 21,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, height: 1.5, color: MauSala.chuPhu)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: MauSala.xanhDam,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: Text(action, style: const TextStyle(fontSize: 10)),
          ),
        ]),
      );

  Widget _section({
    required String title,
    required Widget child,
    IconData? icon,
    Widget? trailing,
  }) =>
      _panel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 5,
              height: 17,
              decoration: BoxDecoration(
                  color: MauSala.xanhThe,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            if (icon != null) ...[
              Icon(icon, size: 15, color: MauSala.xanhThe),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(title,
                  style: GoogleFonts.newsreader(
                      fontSize: 16,
                      color: MauSala.xanhDam,
                      fontWeight: FontWeight.w600)),
            ),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 11),
          child,
        ]),
      );

  Widget _panel(
          {required Widget child,
          EdgeInsets padding = const EdgeInsets.all(14)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE7EDF3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D1B4D3E), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _tabButton(String title, IconData icon,
          {required bool selected,
          required VoidCallback onTap,
          bool gold = false}) =>
      Material(
        color: selected
            ? (gold ? MauSala.vang : MauSala.xanhThe)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 14, color: selected ? Colors.white : MauSala.chuPhu),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 10,
                      color: selected ? Colors.white : MauSala.chuPhu,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _trustPill(IconData icon, String title, String subtitle) => Container(
        constraints: const BoxConstraints(minWidth: 155),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: MauSala.xanhNenThe, borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17, color: MauSala.xanhThe),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 7,
                    letterSpacing: .4,
                    color: MauSala.chuPhu,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 9,
                    color: MauSala.xanhDam,
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
      );

  Widget _tag(String text, {bool gold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: gold ? const Color(0xFFFFF2D5) : const Color(0xFFE2F3EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 8,
                color: gold ? MauSala.vang : MauSala.xanhDam,
                fontWeight: FontWeight.w700)),
      );

  Widget _infoPair(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 7,
                  color: MauSala.chuPhu,
                  letterSpacing: .4,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _personCard({
    required String title,
    required String name,
    required String detail,
    required IconData icon,
    required Color background,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: MauSala.vang, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 7,
                        color: MauSala.vang,
                        letterSpacing: .35,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: MauSala.xanhDam,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 8, height: 1.3, color: MauSala.chuPhu)),
              ])),
        ]),
      );

  Widget _amountTile(String label, String value,
          {bool green = false, bool gold = false}) =>
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: green
              ? const Color(0xFFE7F4EE)
              : gold
                  ? const Color(0xFFFFF5E1)
                  : MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 7, height: 1.2, color: MauSala.chuPhu)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: green
                      ? MauSala.xanhThe
                      : gold
                          ? MauSala.vang
                          : MauSala.xanhDam,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _miniAmount(String label, String value, {bool gold = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 7, color: MauSala.chuPhu)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 10,
                  color: gold ? MauSala.vang : MauSala.xanhDam,
                  fontWeight: FontWeight.w700)),
        ],
      );

  Widget _infoNotice(IconData icon, String text) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(6)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 14, color: MauSala.xanhThe),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 9, height: 1.35, color: MauSala.chuPhu)),
          ),
        ]),
      );

  Widget _errorNotice(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined,
              color: Color(0xFFBA1A1A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 9)),
          ),
          TextButton(
            onPressed: widget.onRefresh,
            child: const Text('Tải lại', style: TextStyle(fontSize: 9)),
          ),
        ]),
      );

  Widget _fileRow(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(5)),
        child: Row(children: [
          Icon(icon, size: 14, color: MauSala.xanhThe),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
          ),
        ]),
      );

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  double _paidAmount(Map<String, dynamic> contract) =>
      _number(contract['amount_paid'] ?? contract['deposit_amount']);

  String _money(num value) =>
      '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(value).trim()} ₫';

  String _percent(double value) =>
      (value * 100).round().clamp(0, 100).toString();

  String _date(dynamic value) {
    if (value == null) return 'Chưa có giao dịch';
    final date = DateTime.tryParse(value.toString());
    return date == null
        ? 'Chưa có giao dịch'
        : DateFormat('dd/MM/yyyy').format(date);
  }

  String _plotType(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'SINGLE':
      case 'SINGLE_PLOT':
        return 'Mộ đơn tiêu chuẩn';
      case 'DOUBLE':
      case 'DOUBLE_PLOT':
        return 'Mộ đôi liền kề';
      case 'FAMILY':
      case 'FAMILY_PLOT':
        return 'Khu mộ gia tộc';
      default:
        return value?.toString() ?? 'Mộ phần Sala Garden';
    }
  }

  String _paymentType(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'INSTALLMENT':
      case 'INSTALLMENTS':
      case 'INSTALLMENT_12':
        return 'Trả góp';
      case 'LUMP_SUM':
        return 'Thanh toán một lần';
      default:
        return value?.toString() ?? 'Theo hợp đồng';
    }
  }

  String _statusLabel(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hiệu lực';
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'COMPLETED':
      case 'PAID':
        return 'Đã hoàn tất';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return value?.toString() ?? 'Đang cập nhật';
    }
  }
}

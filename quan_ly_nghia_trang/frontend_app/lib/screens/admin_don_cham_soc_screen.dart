import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_service.dart';
import '../core/app_colors.dart';

enum _CareFilter { all, pending, approved, rework }

class AdminDonChamSocScreen extends StatefulWidget {
  const AdminDonChamSocScreen({super.key});

  @override
  State<AdminDonChamSocScreen> createState() => _AdminDonChamSocScreenState();
}

class _AdminDonChamSocScreenState extends State<AdminDonChamSocScreen> {
  final _searchController = TextEditingController();
  final _moneyFormat = NumberFormat('#,##0', 'vi_VN');
  List<Map<String, dynamic>> _orders = [];
  _CareFilter _filter = _CareFilter.all;
  bool _loading = true;
  String? _error;
  int? _approvingId;

  static const _pendingStatuses = {'PENDING', 'WAITING', 'SUBMITTED'};
  static const _approvedStatuses = {'CONFIRMED', 'ACCEPTED', 'APPROVED'};
  static const _reworkStatuses = {
    'NEEDS_REVISION',
    'REQUESTED_REDO',
    'REWORK',
    'REVISION_REQUIRED',
    'REJECTED',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _status(Map<String, dynamic> order) =>
      (order['status'] ?? '').toString().trim().toUpperCase();

  bool _isPending(Map<String, dynamic> order) =>
      _pendingStatuses.contains(_status(order));

  bool _isApproved(Map<String, dynamic> order) =>
      _approvedStatuses.contains(_status(order));

  bool _isRework(Map<String, dynamic> order) =>
      _reworkStatuses.contains(_status(order));

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('/admin/care-orders');
      final raw = response is Map ? response['data'] : null;
      final orders = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _visibleOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesFilter = switch (_filter) {
        _CareFilter.all => true,
        _CareFilter.pending => _isPending(order),
        _CareFilter.approved => _isApproved(order),
        _CareFilter.rework => _isRework(order),
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final searchable = [
        order['order_code'],
        order['customer_name'],
        order['customer_phone'],
        order['plot_code'],
        order['zone_name'],
        order['service_name'],
      ].whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  String _filterLabel(_CareFilter filter) => switch (filter) {
        _CareFilter.all => 'Tất cả',
        _CareFilter.pending => 'Chờ duyệt',
        _CareFilter.approved => 'Đã duyệt',
        _CareFilter.rework => 'Yêu cầu làm lại',
      };

  int _count(_CareFilter filter) => _orders.where((order) {
        return switch (filter) {
          _CareFilter.all => true,
          _CareFilter.pending => _isPending(order),
          _CareFilter.approved => _isApproved(order),
          _CareFilter.rework => _isRework(order),
        };
      }).length;

  String _statusLabel(String status) {
    if (_pendingStatuses.contains(status)) return 'Chờ duyệt';
    if (_approvedStatuses.contains(status)) return 'Đã duyệt';
    if (_reworkStatuses.contains(status)) return 'Yêu cầu làm lại';
    return status.isEmpty ? 'Chưa rõ trạng thái' : status;
  }

  Color _statusColor(String status) {
    if (_pendingStatuses.contains(status)) return const Color(0xFF9A6A12);
    if (_approvedStatuses.contains(status)) return AppColors.forest;
    if (_reworkStatuses.contains(status)) return const Color(0xFFB3261E);
    return AppColors.muted;
  }

  Color _statusBackground(String status) {
    if (_pendingStatuses.contains(status)) return const Color(0xFFFFE8B5);
    if (_approvedStatuses.contains(status)) return const Color(0xFFDDF4E9);
    if (_reworkStatuses.contains(status)) return const Color(0xFFFFE2DF);
    return AppColors.paleBlue;
  }

  String _date(dynamic value) {
    final date = value == null ? null : DateTime.tryParse(value.toString());
    return date == null
        ? 'Chưa có lịch'
        : DateFormat('dd/MM/yyyy').format(date);
  }

  String _price(dynamic value) {
    final amount = value is num ? value : num.tryParse(value?.toString() ?? '');
    return amount == null ? 'Liên hệ' : '${_moneyFormat.format(amount)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _count(_CareFilter.pending);
    final approvedCount = _count(_CareFilter.approved);
    final reworkCount = _count(_CareFilter.rework);
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          _pageHeading(),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 580
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard('Tổng đơn', '${_orders.length}',
                    Icons.receipt_long_outlined, AppColors.forest, width),
                _summaryCard('Chờ Ban Quản Lý duyệt', '$pendingCount',
                    Icons.pending_actions, const Color(0xFF9A6A12), width),
                _summaryCard('Đã duyệt', '$approvedCount', Icons.task_alt,
                    AppColors.forest, width),
                _summaryCard('Yêu cầu làm lại', '$reworkCount',
                    Icons.replay_outlined, const Color(0xFFB3261E), width),
              ],
            );
          }),
          const SizedBox(height: 16),
          _filters(),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorPanel()
          else if (_visibleOrders.isEmpty)
            _emptyPanel()
          else
            ..._visibleOrders.map(_orderCard),
        ],
      ),
    );
  }

  Widget _pageHeading() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(builder: (context, constraints) {
            final actions = Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _loadOrders,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tải lại'),
              ),
            ]);
            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DỊCH VỤ & THI CÔNG  /  DUYỆT ĐƠN CHĂM SÓC',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6)),
                const SizedBox(height: 7),
                const Text('Đơn Dịch Vụ Chăm Sóc Mộ Phần',
                    style: TextStyle(
                        color: AppColors.forestDeep,
                        fontSize: 26,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                const Text(
                    'Xem thông tin đơn do thân nhân đặt, kiểm tra lịch và dịch vụ rồi duyệt đơn.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            );
            if (constraints.maxWidth < 700) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), actions]);
            }
            return Row(children: [Expanded(child: title), actions]);
          }),
        ),
      );

  Widget _summaryCard(String label, String value, IconData icon, Color color,
          double width) =>
      SizedBox(
        width: width,
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .35)),
                      const SizedBox(height: 8),
                      Text(value,
                          style: TextStyle(
                              color: color,
                              fontSize: 28,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withOpacity(.1),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color),
              ),
            ]),
          ),
        ),
      );

  Widget _filters() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final filter in _CareFilter.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      selected: _filter == filter,
                      selectedColor: AppColors.forest,
                      backgroundColor: AppColors.paleBlue,
                      label: Text('${_filterLabel(filter)}  ${_count(filter)}'),
                      labelStyle: TextStyle(
                          color:
                              _filter == filter ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText:
                    'Tìm theo mã đơn, tên thân nhân, số điện thoại, mã mộ hoặc dịch vụ',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        }),
              ),
            ),
          ]),
        ),
      );

  Widget _orderCard(Map<String, dynamic> order) {
    final status = _status(order);
    final isPending = _isPending(order);
    final id = int.tryParse(order['id']?.toString() ?? '');
    final proofImages = order['proof_images'] is List
        ? order['proof_images'] as List
        : const [];
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final info =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 9,
                runSpacing: 6,
                children: [
                  Text(
                      (order['order_code'] ?? 'Đơn #${order['id'] ?? ''}')
                          .toString(),
                      style: const TextStyle(
                          color: AppColors.forestDeep,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  _statusBadge(status),
                  Text('Đặt ngày ${_date(order['created_at'])}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ]),
            const SizedBox(height: 12),
            Wrap(spacing: 18, runSpacing: 12, children: [
              _infoBlock(
                  Icons.person_outline,
                  'THÂN NHÂN',
                  (order['customer_name'] ?? 'Chưa có tên').toString(),
                  order['customer_phone']?.toString()),
              _infoBlock(
                  Icons.location_on_outlined,
                  'VỊ TRÍ MỘ',
                  (order['plot_code'] ?? 'Chưa liên kết').toString(),
                  order['zone_name']?.toString()),
              _infoBlock(
                  Icons.spa_outlined,
                  'DỊCH VỤ',
                  (order['service_name'] ?? 'Chưa rõ dịch vụ').toString(),
                  _price(order['service_price'])),
              _infoBlock(
                  Icons.event_outlined,
                  'NGÀY DỰ KIẾN',
                  _date(order['scheduled_date']),
                  proofImages.isEmpty
                      ? null
                      : '${proofImages.length} ảnh minh chứng'),
            ]),
            if ((order['note'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Ghi chú: ${order['note']}',
                    style:
                        const TextStyle(color: AppColors.text, fontSize: 12)),
              ),
            ],
          ]);
          final actions = Wrap(
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDetails(order),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Xem thông tin'),
                ),
                if (isPending)
                  FilledButton.icon(
                    onPressed: id == null || _approvingId == id
                        ? null
                        : () => _confirmApproval(order),
                    icon: _approvingId == id
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Duyệt đơn'),
                  ),
              ]);
          if (compact) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 14), actions]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: info),
            const SizedBox(width: 18),
            SizedBox(width: 270, child: actions)
          ]);
        }),
      ),
    );
  }

  Widget _infoBlock(
          IconData icon, String label, String value, String? detail) =>
      SizedBox(
        width: 205,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: AppColors.forest),
          const SizedBox(width: 7),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(detail,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ])),
        ]),
      );

  Widget _statusBadge(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: _statusBackground(status),
            borderRadius: BorderRadius.circular(20)),
        child: Text(_statusLabel(status),
            style: TextStyle(
                color: _statusColor(status),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );

  Widget _errorPanel() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.text))),
            TextButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại')),
          ]),
        ),
      );

  Widget _emptyPanel() => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 20),
          child: Column(children: [
            const Icon(Icons.inbox_outlined, color: AppColors.forest, size: 42),
            const SizedBox(height: 10),
            Text(
                _searchController.text.isNotEmpty
                    ? 'Không tìm thấy đơn phù hợp'
                    : 'Chưa có đơn ở mục này',
                style: const TextStyle(
                    color: AppColors.forestDeep,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text(
                'Danh sách được tải từ các đơn dịch vụ thân nhân đã gửi lên hệ thống.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
      );

  Future<void> _confirmApproval(Map<String, dynamic> order) async {
    final code = (order['order_code'] ?? 'đơn này').toString();
    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận duyệt đơn'),
        content:
            Text('Duyệt $code? Trạng thái đơn sẽ được lưu thành “Đã duyệt”.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Để sau')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check),
              label: const Text('Duyệt đơn')),
        ],
      ),
    );
    if (shouldApprove != true) return;
    await _approve(order);
  }

  Future<bool> _approve(Map<String, dynamic> order) async {
    final id = int.tryParse(order['id']?.toString() ?? '');
    if (id == null) return false;
    setState(() => _approvingId = id);
    try {
      await ApiService.instance.post('/admin/care-orders/$id/approve', {});
      await _loadOrders();
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt đơn chăm sóc.')));
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không duyệt được đơn: $message')));
      return false;
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  Future<void> _showDetails(Map<String, dynamic> order) async {
    final id = int.tryParse(order['id']?.toString() ?? '');
    final proofs = order['proof_images'] is List
        ? order['proof_images'] as List
        : const [];
    var approving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
          child: StatefulBuilder(builder: (context, setDialogState) {
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
                child: Row(children: [
                  const Icon(Icons.fact_check_outlined,
                      color: AppColors.forest),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text((order['order_code'] ?? 'Chi tiết đơn').toString(),
                            style: const TextStyle(
                                color: AppColors.forestDeep,
                                fontSize: 19,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        _statusBadge(_status(order)),
                      ])),
                  IconButton(
                      tooltip: 'Đóng',
                      onPressed:
                          approving ? null : () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(22), children: [
                  _detailSection('Thông tin người đặt', [
                    (
                      'Họ tên',
                      (order['customer_name'] ?? 'Chưa có tên').toString()
                    ),
                    (
                      'Số điện thoại',
                      (order['customer_phone'] ?? 'Chưa có số điện thoại')
                          .toString()
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection('Dịch vụ và vị trí', [
                    (
                      'Dịch vụ',
                      (order['service_name'] ?? 'Chưa rõ dịch vụ').toString()
                    ),
                    ('Chi phí', _price(order['service_price'])),
                    (
                      'Mã mộ',
                      (order['plot_code'] ?? 'Chưa liên kết').toString()
                    ),
                    ('Phân khu', (order['zone_name'] ?? 'Chưa rõ').toString()),
                    ('Ngày đặt', _date(order['created_at'])),
                    ('Ngày dự kiến', _date(order['scheduled_date'])),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection('Ghi chú của thân nhân', [
                    (
                      'Nội dung',
                      (order['note'] ?? '').toString().trim().isEmpty
                          ? 'Không có ghi chú.'
                          : order['note'].toString()
                    ),
                  ]),
                  if (proofs.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text('Ảnh minh chứng đính kèm',
                        style: TextStyle(
                            color: AppColors.forestDeep,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: proofs
                            .whereType<Map>()
                            .map((proof) => _proofCard(proof))
                            .toList()),
                  ],
                ]),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                          onPressed: approving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const Text('Đóng')),
                      if (_isPending(order))
                        FilledButton.icon(
                          onPressed: approving || id == null
                              ? null
                              : () async {
                                  setDialogState(() => approving = true);
                                  final approved = await _approve(order);
                                  if (dialogContext.mounted) {
                                    if (approved) {
                                      Navigator.pop(dialogContext);
                                    } else {
                                      setDialogState(() => approving = false);
                                    }
                                  }
                                },
                          icon: approving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Duyệt đơn'),
                        ),
                    ]),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<(String, String)> values) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(9)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.forest,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 125,
                    child: Text(value.$1,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12))),
                Expanded(
                    child: Text(value.$2,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
              ]),
            ),
        ]),
      );

  Widget _proofCard(Map proof) {
    final url = (proof['image_url'] ?? '').toString();
    final note = (proof['note'] ?? '').toString();
    final resolved = _resolveImageUrl(url);
    return SizedBox(
      width: 205,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 132,
            width: 205,
            child: resolved.isEmpty
                ? const ColoredBox(
                    color: AppColors.paleBlue,
                    child: Icon(Icons.image_not_supported_outlined))
                : Image.network(resolved,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppColors.paleBlue,
                        child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AppColors.muted)))),
          ),
        ),
        if (note.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 11))),
      ]),
    );
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    final root =
        ApiService.instance.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return '$root/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

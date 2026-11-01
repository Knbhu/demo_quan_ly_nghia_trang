import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_service.dart';
import '../core/mausala.dart';

class TuongNiemOnline extends StatefulWidget {
  const TuongNiemOnline({super.key, this.fullName, this.onOpenContracts});

  final String? fullName;
  final VoidCallback? onOpenContracts;

  @override
  State<TuongNiemOnline> createState() => _TuongNiemOnlineState();
}

class _TuongNiemOnlineState extends State<TuongNiemOnline> {
  final _guestbookFormKey = GlobalKey<FormState>();
  final _authorController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _memorials = [];
  List<Map<String, dynamic>> _guestbook = [];
  String? _selectedId;
  bool _loading = true;
  bool _loadingGuestbook = false;
  bool _sendingMessage = false;
  final Set<String> _busyActions = {};
  String? _error;

  Map<String, dynamic>? get _selected {
    for (final memorial in _memorials) {
      if (memorial['id'].toString() == _selectedId) return memorial;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _authorController.text = widget.fullName ?? '';
    _loadMemorials();
  }

  @override
  void dispose() {
    _authorController.dispose();
    _relationshipController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMemorials() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('/customer/memorials');
      final data = List<Map<String, dynamic>>.from(
        (response['data'] as List)
            .map((row) => Map<String, dynamic>.from(row as Map)),
      );
      if (!mounted) return;
      setState(() {
        _memorials = data;
        if (!data.any((row) => row['id'].toString() == _selectedId)) {
          _selectedId = data.isEmpty ? null : data.first['id'].toString();
        }
      });
      if (_selectedId != null) await _loadGuestbook();
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadGuestbook() async {
    final memorial = _selected;
    if (memorial == null) return;
    setState(() => _loadingGuestbook = true);
    try {
      final response = await ApiService.instance
          .get('/customer/memorials/${memorial['id']}/guestbook');
      if (!mounted || _selectedId != memorial['id'].toString()) return;
      setState(() {
        _guestbook = List<Map<String, dynamic>>.from(
          (response['data'] as List)
              .map((row) => Map<String, dynamic>.from(row as Map)),
        );
      });
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _loadingGuestbook = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: MauSala.xanhThe)),
                      )
                    : _error != null
                        ? _errorPanel()
                        : _memorials.isEmpty
                            ? _emptyPanel()
                            : _memorialPage(constraints.maxWidth >= 900),
              ),
            ),
          ],
        ),
      );

  Widget _memorialPage(bool wide) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identityRibbon(),
          const SizedBox(height: 12),
          if (_memorials.length > 1) ...[
            _memorialPicker(),
            const SizedBox(height: 12),
          ],
          _profileCard(wide),
          const SizedBox(height: 16),
          _ritualPanel(wide),
          const SizedBox(height: 18),
          _lifeAndMemories(wide),
          const SizedBox(height: 18),
          _guestbookSection(wide),
          const SizedBox(height: 16),
          _careNotice(),
        ],
      );

  Widget _identityRibbon() {
    final memorial = _selected!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: MauSala.xanhDam,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              color: Color(0x151B4D3E), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_stories_outlined,
                color: MauSala.vangThe, size: 18),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('KHÔNG GIAN TƯỞNG NIỆM TRỰC TUYẾN',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: .55,
                      fontWeight: FontWeight.w700)),
              Text(
                'Hồ sơ ${_value(memorial['plot_code'], 'đã liên kết với gia đình')}',
                style: const TextStyle(color: MauSala.xanhNenThe, fontSize: 8),
              ),
            ]),
          ]),
          if (_canManageAccess(memorial))
            OutlinedButton.icon(
              onPressed: _shareMemorial,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: const Icon(Icons.group_add_outlined, size: 14),
              label: const Text('Mời thân nhân xem',
                  style: TextStyle(fontSize: 8)),
            ),
        ],
      ),
    );
  }

  Widget _memorialPicker() => _panel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          const Icon(Icons.person_search_outlined,
              color: MauSala.xanhThe, size: 18),
          const SizedBox(width: 9),
          const Text('Hồ sơ tưởng niệm',
              style: TextStyle(
                  fontSize: 10,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedId,
                isExpanded: true,
                items: _memorials
                    .map((row) => DropdownMenuItem(
                          value: row['id'].toString(),
                          child: Text(
                            '${_value(row['full_name'], 'Hồ sơ')} • ${_value(row['plot_code'], 'Chưa có mã mộ')}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() {
                    _selectedId = value;
                    _guestbook = [];
                  });
                  await _loadGuestbook();
                },
              ),
            ),
          ),
        ]),
      );

  Widget _profileCard(bool wide) {
    final memorial = _selected!;
    final portrait = _value(memorial['avatar_url'], '');
    final start = _formatDate(memorial['date_of_birth']);
    final end = _formatDate(memorial['date_of_death']);
    return _panel(
      padding: const EdgeInsets.all(14),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _portrait(portrait, large: true),
              const SizedBox(width: 18),
              Expanded(child: _profileDetails(memorial, start, end)),
            ])
          : Column(children: [
              _portrait(portrait, large: false),
              const SizedBox(height: 14),
              _profileDetails(memorial, start, end),
            ]),
    );
  }

  Widget _portrait(String url, {required bool large}) => Container(
        width: large ? 170 : 142,
        height: large ? 190 : 156,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MauSala.vien.withValues(alpha: .65)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: url.isEmpty
              ? _portraitFallback()
              : Image.network(url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _portraitFallback()),
        ),
      );

  Widget _portraitFallback() => Container(
        color: MauSala.xanhNenThe,
        child: const Center(
          child: Icon(Icons.person_outline, color: MauSala.xanhThe, size: 64),
        ),
      );

  Widget _profileDetails(
      Map<String, dynamic> memorial, String birth, String death) {
    final name = _value(memorial['full_name'], 'Hồ sơ tưởng niệm');
    final dharma = _value(memorial['dharma_name'], '');
    final biography = _value(memorial['biography'], '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 6, runSpacing: 5, children: [
          _tag('HƯƠNG LINH GIA QUYẾN', green: true),
          if (dharma.isNotEmpty) _tag('Pháp danh: $dharma', gold: true),
          _tag('Hồ sơ gia đình', green: true),
        ]),
        const SizedBox(height: 7),
        Text(name.toUpperCase(),
            style: GoogleFonts.newsreader(
                fontSize: 30,
                height: 1.05,
                color: MauSala.xanhDam,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(spacing: 18, runSpacing: 7, children: [
          _inlineInfo(Icons.calendar_month_outlined, 'Sinh: $birth'),
          _inlineInfo(Icons.spa_outlined, 'Tạ thế: $death'),
        ]),
        const SizedBox(height: 5),
        _inlineInfo(Icons.location_on_outlined,
            'Vị trí an nghỉ: ${_value(memorial['plot_code'], 'Đang cập nhật')} • ${_value(memorial['zone_name'], 'Sala Garden')}'),
        if (biography.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: MauSala.xanhNhat,
                borderRadius: BorderRadius.circular(7)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.format_quote, color: MauSala.vang, size: 20),
              const SizedBox(width: 7),
              Expanded(
                child: Text(biography,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.newsreader(
                        fontSize: 15,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        color: MauSala.xanhDam)),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _ritualPanel(bool wide) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MauSala.xanhDam,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
                color: Color(0x19111D25), blurRadius: 16, offset: Offset(0, 5)),
          ],
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064638), MauSala.xanhDam]),
        ),
        child: Column(children: [
          const Text('KHÔNG GIAN TÂM LINH ONLINE',
              style: TextStyle(
                  color: MauSala.vangThe,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('Linh Đường Bàn Thờ Ảo Thanh Tịnh',
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(_value(_selected!['full_name'], ''),
              style: const TextStyle(
                  color: MauSala.xanhNenThe,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          LayoutBuilder(builder: (context, constraints) {
            final stacked = constraints.maxWidth < 650;
            final cards = [
              _ritualCard(
                title: 'Dâng hoa sen tươi',
                detail: 'Gửi một lời thành kính đến hương linh.',
                count: _count('FLOWER'),
                icon: Icons.filter_vintage,
                action: 'Dâng Hoa Sen Tươi',
                actionType: 'FLOWER',
              ),
              _incenseCard(),
              _ritualCard(
                title: 'Mâm ngũ quả phước lộc',
                detail: 'Gửi lời tưởng nhớ từ gia quyến.',
                count: _count('FRUIT'),
                icon: Icons.local_florist_outlined,
                action: 'Dâng Trái Cây Tươi',
                actionType: 'FRUIT',
                secondaryAction: 'Gõ Chuông Cầu An',
                secondaryType: 'BELL',
              ),
            ];
            if (stacked) {
              return Column(children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 9),
                  cards[i],
                ],
              ]);
            }
            return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[2]),
                ]);
          }),
        ]),
      );

  Widget _incenseCard() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _tag('GIA QUYẾN THÀNH KÍNH', gold: true),
          const SizedBox(height: 9),
          const Icon(Icons.local_fire_department_outlined,
              color: MauSala.vangThe, size: 38),
          const SizedBox(height: 3),
          Text(_count('INCENSE'),
              style: GoogleFonts.newsreader(
                  color: MauSala.vangThe,
                  fontSize: 29,
                  fontWeight: FontWeight.w700)),
          const Text('LƯỢT THẮP HƯƠNG',
              style: TextStyle(
                  color: MauSala.xanhNenThe, fontSize: 8, letterSpacing: .5)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _recordAction('INCENSE'),
              style: FilledButton.styleFrom(
                  backgroundColor: MauSala.vangThe,
                  foregroundColor: MauSala.xanhDam,
                  padding: const EdgeInsets.symmetric(vertical: 11)),
              icon: _busyActions.contains('INCENSE')
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.local_fire_department_outlined, size: 16),
              label: const Text('Thắp Nén Hương Ảo',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );

  Widget _ritualCard({
    required String title,
    required String detail,
    required String count,
    required IconData icon,
    required String action,
    required String actionType,
    String? secondaryAction,
    String? secondaryType,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Align(
              alignment: Alignment.centerRight,
              child: _tag('Đã dâng $count', gold: true)),
          const SizedBox(height: 4),
          Icon(icon, color: MauSala.vangThe, size: 32),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: MauSala.xanhNenThe, fontSize: 8, height: 1.3)),
          const SizedBox(height: 9),
          _actionButton(action, actionType, outlined: secondaryAction != null),
          if (secondaryAction != null && secondaryType != null) ...[
            const SizedBox(height: 6),
            _actionButton(secondaryAction, secondaryType),
          ],
        ]),
      );

  Widget _actionButton(String label, String type, {bool outlined = false}) =>
      SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(
                onPressed: () => _recordAction(type),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 9)),
                child: Text(label, style: const TextStyle(fontSize: 8)),
              )
            : FilledButton.icon(
                onPressed: () => _recordAction(type),
                style: FilledButton.styleFrom(
                    backgroundColor: MauSala.vangThe,
                    foregroundColor: MauSala.xanhDam,
                    padding: const EdgeInsets.symmetric(vertical: 9)),
                icon: _busyActions.contains(type)
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.volunteer_activism_outlined, size: 13),
                label: Text(label,
                    style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w700)),
              ),
      );

  Widget _lifeAndMemories(bool wide) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('HÀNH TRÌNH NHÂN THẾ VẸN TOÀN',
              'Tiểu Sử Cuộc Đời & Ký Ức Kỷ Niệm'),
          const SizedBox(height: 10),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _lifeTimeline()),
              const SizedBox(width: 12),
              Expanded(flex: 7, child: _memoryAlbum()),
            ])
          else
            Column(children: [
              _lifeTimeline(),
              const SizedBox(height: 10),
              _memoryAlbum(),
            ]),
        ],
      );

  Widget _lifeTimeline() {
    final memorial = _selected!;
    final birth = _formatDate(memorial['date_of_birth']);
    final death = _formatDate(memorial['date_of_death']);
    final bio =
        _value(memorial['biography'], 'Gia quyến chưa bổ sung tiểu sử.');
    return _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history_edu_outlined, color: MauSala.vang, size: 18),
          const SizedBox(width: 7),
          Text('Cột Mốc Cuộc Đời',
              style: GoogleFonts.newsreader(
                  color: MauSala.xanhDam,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        _timelinePoint(birth, 'Chào đời', 'Ngày sinh được lưu trong hồ sơ.'),
        if (bio.isNotEmpty) _timelinePoint('Kỷ niệm', 'Dấu ấn cuộc đời', bio),
        _timelinePoint(
            death, 'An nhiên xả báo', 'Ngày tạ thế được gia đình ghi nhớ.'),
        if (memorial['burial_date'] != null)
          _timelinePoint(
              _formatDate(memorial['burial_date']),
              'An nghỉ tại Sala Garden',
              'Hồ sơ mộ ${_value(memorial['plot_code'], '')}'),
      ]),
    );
  }

  Widget _timelinePoint(String date, String title, String detail) => Padding(
        padding: const EdgeInsets.only(left: 1, bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            const Icon(Icons.circle, color: MauSala.xanhThe, size: 10),
            Container(width: 1, height: 36, color: MauSala.xanhNenThe),
          ]),
          const SizedBox(width: 9),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _tag(date, gold: true),
              const SizedBox(height: 3),
              Text(title,
                  style: const TextStyle(
                      color: MauSala.xanhDam,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              Text(detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: MauSala.chuPhu, fontSize: 8, height: 1.35)),
            ]),
          ),
        ]),
      );

  Widget _memoryAlbum() {
    final url = _value(_selected!['avatar_url'], '');
    return _panel(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (url.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            child: Image.network(url,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _albumFallback()),
          )
        else
          _albumFallback(),
        Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _tag('KÝ ỨC GIA ĐÌNH', gold: true),
            const SizedBox(height: 5),
            Text(
                _value(_selected!['memorial_name'],
                    'Những ngày tháng thân thương'),
                style: GoogleFonts.newsreader(
                    color: MauSala.xanhDam,
                    fontSize: 19,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              _value(_selected!['biography'],
                  'Gia đình có thể bổ sung tiểu sử và hình ảnh kỷ niệm cho hồ sơ này.'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: MauSala.chuPhu, fontSize: 9, height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _albumFallback() => Container(
        height: 190,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB9D3C5), Color(0xFFEAF5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.photo_library_outlined,
              color: MauSala.xanhThe, size: 44),
        ),
      );

  Widget _guestbookSection(bool wide) {
    final rows = Column(
      children: _guestbook.isEmpty
          ? [
              _panel(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: _loadingGuestbook
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: MauSala.xanhThe),
                          ),
                        )
                      : const Center(
                          child: Text(
                              'Chưa có lời tri ân. Gia đình có thể gửi lời đầu tiên.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 9, color: MauSala.chuPhu)),
                        ),
                ),
              )
            ]
          : _guestbook.map(_guestbookCard).toList(),
    );
    final form = _guestbookForm();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeading('TÂM TÌNH & CẦU NGUYỆN', 'Sổ Tang Điện Tử & Lời Tri Ân'),
      const SizedBox(height: 10),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: rows),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: form),
        ])
      else
        Column(children: [rows, const SizedBox(height: 12), form]),
    ]);
  }

  Widget _guestbookCard(Map<String, dynamic> entry) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: MauSala.xanhThe,
                child: Text(
                    _initials(_value(entry['author_name'], 'Gia quyến')),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_value(entry['author_name'], 'Gia quyến'),
                    style: const TextStyle(
                        color: MauSala.xanhDam,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
              _tag(_formatDate(entry['created_at']), green: true),
            ]),
            if (_value(entry['relationship'], '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_value(entry['relationship'], ''),
                  style: const TextStyle(fontSize: 8, color: MauSala.chuPhu)),
            ],
            const SizedBox(height: 7),
            Text(_value(entry['message'], ''),
                style: const TextStyle(
                    color: MauSala.chuPhu,
                    fontSize: 9,
                    height: 1.45,
                    fontStyle: FontStyle.italic)),
          ]),
        ),
      );

  Widget _guestbookForm() => _panel(
        child: Form(
          key: _guestbookFormKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.edit_note, color: MauSala.vang, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Gửi Lời Tưởng Niệm Lên Bàn Thờ Ảo',
                    style: GoogleFonts.newsreader(
                        color: MauSala.xanhDam,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
                'Lời tri ân sẽ được lưu giữ và hiển thị ngay cho các thành viên được cấp quyền xem hồ sơ.',
                style: TextStyle(
                    fontSize: 8, color: MauSala.chuPhu, height: 1.35)),
            const SizedBox(height: 9),
            _formField(_authorController, 'Họ và tên người gửi',
                required: true),
            const SizedBox(height: 7),
            _formField(_relationshipController, 'Mối quan hệ với hương linh'),
            const SizedBox(height: 7),
            _formField(_messageController, 'Lời nhắn gửi / lời cầu nguyện',
                required: true, maxLines: 4),
            const SizedBox(height: 9),
            FilledButton.icon(
              onPressed: _sendingMessage ? null : _sendGuestbook,
              style: FilledButton.styleFrom(
                  backgroundColor: MauSala.xanhDam,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: _sendingMessage
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_outlined, size: 14),
              label: const Text('Gửi Lời Tưởng Niệm',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      );

  Widget _careNotice() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: MauSala.xanhNhat, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.volunteer_activism_outlined,
              color: MauSala.xanhThe, size: 20),
          const SizedBox(width: 9),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Chăm sóc & dâng hoa tại kim tĩnh',
                  style: TextStyle(
                      color: MauSala.xanhDam,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              Text(
                  'Gia đình có thể đặt dịch vụ chăm sóc trực tiếp tại mục Chăm sóc từ xa.',
                  style: TextStyle(fontSize: 8, color: MauSala.chuPhu)),
            ]),
          ),
        ]),
      );

  Widget _emptyPanel() => _panel(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
                color: MauSala.xanhNhat, shape: BoxShape.circle),
            child: const Icon(Icons.spa_outlined,
                color: MauSala.xanhThe, size: 34),
          ),
          const SizedBox(height: 12),
          Text('Chưa có hồ sơ mộ phần được liên kết',
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                  fontSize: 23,
                  color: MauSala.xanhDam,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Khi hợp đồng mộ phần được liên kết với tài khoản thân nhân, hồ sơ tưởng niệm sẽ xuất hiện tại đây. Các nghi lễ trực tuyến sẽ được mở cùng hồ sơ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MauSala.chuPhu, fontSize: 10, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadMemorials,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Tải lại hồ sơ',
                      style: TextStyle(fontSize: 9)),
                ),
                if (widget.onOpenContracts != null)
                  FilledButton.icon(
                    onPressed: widget.onOpenContracts,
                    style: FilledButton.styleFrom(
                        backgroundColor: MauSala.xanhThe,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.description_outlined, size: 15),
                    label: const Text('Xem hợp đồng gia đình',
                        style: TextStyle(fontSize: 9)),
                  ),
              ]),
        ]),
      );

  Widget _errorPanel() => _panel(
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 10))),
          TextButton.icon(
              onPressed: _loadMemorials,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Thử lại')),
        ]),
      );

  Widget _sectionHeading(String eyebrow, String title) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: const TextStyle(
                  color: MauSala.vang,
                  fontSize: 8,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w700)),
          Text(title,
              style: GoogleFonts.newsreader(
                  color: MauSala.xanhDam,
                  fontSize: 23,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _inlineInfo(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MauSala.vang, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                style: const TextStyle(fontSize: 9, color: MauSala.chuPhu)),
          ),
        ],
      );

  Widget _tag(String text, {bool gold = false, bool green = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: gold
              ? MauSala.vangThe.withValues(alpha: .26)
              : green
                  ? MauSala.xanhNenThe
                  : MauSala.xanhNhat,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: gold ? MauSala.vang : MauSala.xanhDam,
                fontSize: 7,
                letterSpacing: .2,
                fontWeight: FontWeight.w700)),
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

  Widget _formField(TextEditingController controller, String label,
          {bool required = false, int maxLines = 1}) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập $label.'
                : null
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: const TextStyle(fontSize: 9, color: MauSala.chuPhu),
          filled: true,
          fillColor: MauSala.xanhNhat,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: MauSala.xanhThe)),
          errorStyle: const TextStyle(fontSize: 8),
        ),
        style: const TextStyle(fontSize: 9, color: MauSala.chu),
      );

  Future<void> _recordAction(String actionType) async {
    final memorial = _selected;
    if (memorial == null || _busyActions.contains(actionType)) return;
    setState(() => _busyActions.add(actionType));
    try {
      final response = await ApiService.instance.post(
        '/customer/memorials/${memorial['id']}/actions',
        {'actionType': actionType},
      );
      final returned = Map<String, dynamic>.from(response['data'] as Map);
      if (!mounted) return;
      setState(() => memorial['action_counts'] = returned['action_counts']);
      _showMessage(_actionSuccess(actionType));
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _busyActions.remove(actionType));
    }
  }

  Future<void> _sendGuestbook() async {
    if (!_guestbookFormKey.currentState!.validate()) return;
    final memorial = _selected;
    if (memorial == null) return;
    setState(() => _sendingMessage = true);
    try {
      final response = await ApiService.instance.post(
        '/customer/memorials/${memorial['id']}/guestbook',
        {
          'authorName': _authorController.text.trim(),
          'relationship': _relationshipController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _guestbook.insert(
            0, Map<String, dynamic>.from(response['data'] as Map));
        _messageController.clear();
      });
      _showMessage('Lời tri ân đã được lưu vào sổ tang gia đình.');
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _shareMemorial() async {
    final memorial = _selected;
    if (memorial == null) return;
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Mời thân nhân xem hồ sơ',
            style: GoogleFonts.newsreader(
                color: MauSala.xanhDam, fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Nhập số điện thoại đã đăng ký tài khoản. Người được mời sẽ thấy hồ sơ và các lời tri ân sau khi được liên kết.',
              style: TextStyle(fontSize: 10, height: 1.4)),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Số điện thoại tài khoản',
                prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: relationController,
            decoration: const InputDecoration(
                labelText: 'Mối quan hệ (không bắt buộc)',
                prefixIcon: Icon(Icons.people_outline)),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: MauSala.xanhThe),
              child: const Text('Cấp quyền xem')),
        ],
      ),
    );
    if (shouldShare != true) {
      phoneController.dispose();
      relationController.dispose();
      return;
    }
    try {
      await ApiService.instance.post(
        '/customer/memorials/${memorial['id']}/members',
        {
          'phone': phoneController.text.trim(),
          'relationship': relationController.text.trim(),
        },
      );
      if (mounted) _showMessage('Đã cấp quyền xem hồ sơ cho thân nhân.');
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    } finally {
      phoneController.dispose();
      relationController.dispose();
    }
  }

  bool _canManageAccess(Map<String, dynamic> memorial) =>
      memorial['can_manage_access'] == true ||
      memorial['can_manage_access'].toString() == '1';

  String _count(String actionType) {
    final counts = _selected?['action_counts'];
    if (counts is Map) return (counts[actionType] ?? 0).toString();
    return '0';
  }

  String _actionSuccess(String actionType) => switch (actionType) {
        'INCENSE' => 'Đã thắp hương và lưu vào hồ sơ tưởng niệm.',
        'FLOWER' => 'Đã dâng hoa và lưu vào hồ sơ tưởng niệm.',
        'FRUIT' => 'Đã dâng trái cây và lưu vào hồ sơ tưởng niệm.',
        'BELL' => 'Đã ghi nhận tiếng chuông cầu an.',
        _ => 'Đã lưu nghi lễ.',
      };

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Chưa cập nhật';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _value(dynamic value, String fallback) =>
      value == null || value.toString().trim().isEmpty
          ? fallback
          : value.toString();

  String _initials(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'GQ';
    return words
        .take(2)
        .map((word) => word.isEmpty ? '' : word[0])
        .join()
        .toUpperCase();
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

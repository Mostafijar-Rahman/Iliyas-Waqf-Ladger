import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../utils/bn_digits.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  bool _isLoading = true;
  List<dynamic> _vouchers = [];

  String? _selectedType; // null = সব ধরন
  DateTime? _startDate;
  DateTime? _endDate;

  // সার্চ ও একসঙ্গে ডাউনলোড
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _downloading = false;

  // ভাউচার টাইপ -> (বাংলা লেবেল, রং)
  static const Map<String, Map<String, dynamic>> _typeMeta = {
    'income': {'label': 'আয় ভাউচার', 'color': Colors.green},
    'expense': {'label': 'ব্যয় ভাউচার', 'color': Colors.red},
    'cash': {'label': 'ক্যাশ ভাউচার', 'color': Colors.teal},
    'bank': {'label': 'ব্যাংক ভাউচার', 'color': Colors.blue},
    'loan_repayment': {'label': 'ঋণ পরিশোধ ভাউচার', 'color': Colors.orange},
    'staff_salary': {'label': 'স্টাফ বেতন ভাউচার', 'color': Colors.indigo},
    'staff_advance': {'label': 'স্টাফ অগ্রিম ভাউচার', 'color': Colors.purple},
    'partner_allowance': {'label': 'অংশীদার ভাতা ভাউচার', 'color': Colors.brown},
  };

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);

    final res = await ApiService.getVoucherList(
      voucherType: _selectedType,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );

    if (mounted) {
      setState(() {
        _vouchers = res['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _loadVouchers();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadVouchers();
  }

  // ---------- দ্রুত তারিখ বাছাই: আজ / এই সপ্তাহ / এই মাস / গত মাস ----------
  DateTimeRange _quickRange(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (key) {
      case 'today':
        return DateTimeRange(start: today, end: today);
      case 'week':
        final start = today.subtract(Duration(days: today.weekday - 1)); // সোমবার থেকে
        return DateTimeRange(start: start, end: start.add(const Duration(days: 6)));
      case 'month':
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: DateTime(today.year, today.month + 1, 0),
        );
      default: // 'lastMonth'
        return DateTimeRange(
          start: DateTime(today.year, today.month - 1, 1),
          end: DateTime(today.year, today.month, 0),
        );
    }
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isQuickActive(String key) {
    if (_startDate == null || _endDate == null) return false;
    final r = _quickRange(key);
    return _sameDay(_startDate!, r.start) && _sameDay(_endDate!, r.end);
  }

  void _applyQuick(String key) {
    if (_isQuickActive(key)) {
      _clearDateRange(); // আবার চাপলে ফিল্টার উঠে যাবে
      return;
    }
    final r = _quickRange(key);
    setState(() {
      _startDate = r.start;
      _endDate = r.end;
    });
    _loadVouchers();
  }

  // ---------- সার্চ ----------
  // বাংলা অঙ্কে লিখলেও যেন ইংরেজি অঙ্কের ডেটার সঙ্গে মেলে
  static String _normalize(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = bn.indexOf(ch);
      buf.write(i >= 0 ? '$i' : ch);
    }
    return buf.toString();
  }

  List<dynamic> get _filtered {
    final q = _normalize(_query.trim());
    if (q.isEmpty) return _vouchers;
    return _vouchers.where((v) {
      final hay = _normalize('${v['voucher_no'] ?? ''} ${v['remarks'] ?? ''} ${v['amount'] ?? ''}');
      return hay.contains(q);
    }).toList();
  }

  // ---------- স্ক্রিনে যে ভাউচারগুলো দেখা যাচ্ছে, সব একসঙ্গে PDF ----------
  Future<void> _downloadAll(List<dynamic> list) async {
    if (_downloading || list.isEmpty) return;
    setState(() => _downloading = true);
    try {
      await PdfService.printVouchers(list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF তৈরি করা যায়নি: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showVoucherDetails(Map<String, dynamic> v) {
    final meta = _typeMeta[v['voucher_type']] ??
        {'label': v['voucher_type'] ?? '-', 'color': Colors.grey};
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(v['voucher_no'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ধরন', meta['label']),
            _detailRow('তারিখ', v['voucher_date'] ?? '-'),
            _detailRow('বিবরণ', v['remarks'] ?? '-'),
            _detailRow('পরিমাণ', '৳ ${toBnDigits('${v['amount'] ?? 0}')}'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => PdfService.printVoucher(v),
            icon: const Icon(Icons.print),
            label: const Text('প্রিন্ট'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = (_startDate != null && _endDate != null)
        ? '${DateFormat('yyyy-MM-dd').format(_startDate!)} — ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
        : 'তারিখ-রেঞ্জ নির্বাচন করুন';

    final list = _filtered;
    final countBn = toBnDigits('${list.length}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('অফিশিয়াল ভাউচার সেন্টার', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'রিফ্রেশ',
                onPressed: _loadVouchers,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'আয়, ব্যয়, ক্যাশ/ব্যাংক লেনদেন, ঋণ পরিশোধ, স্টাফ বেতন বা অংশীদার ভাতা এন্ট্রি করলে ভাউচার স্বয়ংক্রিয়ভাবে তৈরি হয়ে এখানে যুক্ত হয়।',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // ফিল্টার সারি
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String?>(
                  value: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ভাউচারের ধরন',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('সব ধরন', overflow: TextOverflow.ellipsis),
                    ),
                    ..._typeMeta.entries.map(
                          (e) => DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value['label'], overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedType = val);
                    _loadVouchers();
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(dateLabel),
              ),
              if (_startDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'তারিখ ফিল্টার মুছুন',
                  onPressed: _clearDateRange,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // দ্রুত তারিখ বাছাই
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('দ্রুত বাছাই:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ChoiceChip(
                label: const Text('আজ'),
                selected: _isQuickActive('today'),
                onSelected: (_) => _applyQuick('today'),
              ),
              ChoiceChip(
                label: const Text('এই সপ্তাহ'),
                selected: _isQuickActive('week'),
                onSelected: (_) => _applyQuick('week'),
              ),
              ChoiceChip(
                label: const Text('এই মাস'),
                selected: _isQuickActive('month'),
                onSelected: (_) => _applyQuick('month'),
              ),
              ChoiceChip(
                label: const Text('গত মাস'),
                selected: _isQuickActive('lastMonth'),
                onSelected: (_) => _applyQuick('lastMonth'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // সার্চ + সংখ্যা + সব ডাউনলোড
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'ভাউচার নং, বিবরণ বা টাকা দিয়ে খুঁজুন',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'সার্চ মুছুন',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                  ),
                ),
              ),
              if (!_isLoading)
                Text('$countBn টি ভাউচার', style: const TextStyle(color: Colors.grey)),
              ElevatedButton.icon(
                onPressed: (_downloading || _isLoading || list.isEmpty) ? null : () => _downloadAll(list),
                icon: _downloading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.download),
                label: Text(_downloading ? 'প্রস্তুত হচ্ছে...' : 'সব ডাউনলোড (${countBn}টি)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_vouchers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('কোনো ভাউচার পাওয়া যায়নি', style: TextStyle(color: Colors.grey)),
              ),
            )
          else if (list.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('সার্চের সঙ্গে মেলে এমন কোনো ভাউচার নেই', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('ভাউচার নং', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ধরন', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('বিবরণ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('পরিমাণ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('তারিখ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: list.map<DataRow>((v) {
                            final meta = _typeMeta[v['voucher_type']] ??
                                {'label': v['voucher_type'] ?? '-', 'color': Colors.grey};
                            return DataRow(cells: [
                              DataCell(Text(v['voucher_no'] ?? '-')),
                              DataCell(Chip(
                                label: Text(meta['label'], style: const TextStyle(fontSize: 11)),
                                backgroundColor: (meta['color'] as Color).withOpacity(0.1),
                              )),
                              DataCell(Text(v['remarks'] ?? '-')),
                              DataCell(Text('৳ ${toBnDigits('${v['amount'] ?? 0}')}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(v['voucher_date'] ?? '-')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                      tooltip: 'প্রিভিউ',
                                      onPressed: () => _showVoucherDetails(v),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.print, color: Colors.teal),
                                      tooltip: 'প্রিন্ট ভাউচার',
                                      onPressed: () => PdfService.printVoucher(v),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}
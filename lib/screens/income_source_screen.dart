import 'package:flutter/material.dart';
import '../services/api_service.dart';

// --- ডিজাইন টোকেন (partner_screen.dart এর সাথে সামঞ্জস্যপূর্ণ) ---
class _C {
  static const primary = Color(0xFF0F4C3A);
  static const gold = Color(0xFFB8860B);
  static const goldLight = Color(0xFFF3E7C9);
  static const background = Color(0xFFFAF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E3D8);
  static const textPrimary = Color(0xFF1A2E24);
  static const textSecondary = Color(0xFF6B7563);
  static const danger = Color(0xFFB3261E);
  static const success = Color(0xFF1E8A4C);
}

const _heading = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _C.textPrimary);
const _subheading = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.textPrimary);
const _caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _C.textSecondary);

const _banglaMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
];

const _paymentMethods = {'cash': 'নগদ (Cash)', 'bank': 'ব্যাংক (Bank)', 'bkash': 'বিকাশ (bKash)', 'nagad': 'নগদ (Nagad)'};

InputDecoration _fieldDecoration(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  prefixIcon: icon != null ? Icon(icon, size: 20, color: _C.textSecondary) : null,
  filled: true,
  fillColor: _C.surface,
  labelStyle: const TextStyle(color: _C.textSecondary, fontSize: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _addCommas(String s) {
  if (s.length <= 3) return s;
  final rev = s.split('').reversed.join();
  final parts = <String>[];
  parts.add(rev.substring(0, 3));
  int i = 3;
  while (i < rev.length) {
    final end = (i + 2 <= rev.length) ? i + 2 : rev.length;
    parts.add(rev.substring(i, end));
    i += 2;
  }
  return parts.join(',').split('').reversed.join();
}

String _money(dynamic v) {
  final n = _num(v);
  final isNegative = n < 0;
  final formatted = n.abs().toStringAsFixed(0);
  final withComma = _addCommas(formatted);
  return '৳ ${isNegative ? '-' : ''}$withComma';
}

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return _C.success;
    case 'partial':
      return _C.gold;
    default:
      return _C.danger;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'paid':
      return 'পরিশোধিত';
    case 'partial':
      return 'আংশিক বকেয়া';
    default:
      return 'বকেয়া';
  }
}

String _monthLabel(String ym) {
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  final y = parts[0];
  final m = int.tryParse(parts[1]) ?? 1;
  return '${_banglaMonths[m - 1]} $y';
}

String _todayStr() => DateTime.now().toIso8601String().split('T')[0];

// ---------------------------------------------------------------------------
// মূল স্ক্রিন — একটা নির্দিষ্ট ক্যাটাগরির (যেমন "দোকান ভাড়া") সোর্স ও মাসভিত্তিক
// আদায়/বকেয়া দেখায় ও ম্যানেজ করে।
// ---------------------------------------------------------------------------
class IncomeSourceScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const IncomeSourceScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<IncomeSourceScreen> createState() => _IncomeSourceScreenState();
}

class _IncomeSourceScreenState extends State<IncomeSourceScreen> {
  List<dynamic> _statusData = []; // status.php থেকে — প্রতিটা সোর্স + মাসভিত্তিক ব্রেকডাউন
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getIncomeSourceStatus(categoryId: widget.categoryId);
    if (!mounted) return;
    setState(() {
      _statusData = data;
      _loading = false;
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? _C.danger : _C.primary,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddSourceDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    DateTime joinDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('নতুন সোর্স — ${widget.categoryName}', style: _subheading),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: _fieldDecoration('নাম (যেমন: দোকান নং ৫ / রহিম স্টোর)', icon: Icons.storefront)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('মাসিক নির্ধারিত টাকা (৳)', icon: Icons.payments),
                ),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: _fieldDecoration('মোবাইল (ঐচ্ছিক)', icon: Icons.phone)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: joinDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => joinDate = picked);
                  },
                  child: InputDecorator(
                    decoration: _fieldDecoration('হিসাব শুরুর তারিখ', icon: Icons.calendar_today),
                    child: Text('${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.gold, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (name.isEmpty || amount == null || amount <= 0) {
                        _snack('নাম ও সঠিক মাসিক টাকা দিন', error: true);
                        return;
                      }
                      setDialogState(() => saving = true);
                      final res = await ApiService.addIncomeSource(
                        categoryId: widget.categoryId,
                        sourceName: name,
                        monthlyTargetAmount: amount,
                        phone: phoneCtrl.text.trim(),
                        joinDate: '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}',
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        _snack('নতুন সোর্স যুক্ত হয়েছে!');
                        _load();
                      } else {
                        _snack(res['message']?.toString() ?? 'ব্যর্থ হয়েছে', error: true);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('যোগ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateDialog(Map<String, dynamic> row) {
    DateTime endDate = DateTime.now();
    bool saving = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${row['source_name']}-কে নিষ্ক্রিয় করবেন?', style: _subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ডিলিট হবে না — শুধু নিষ্ক্রিয় হবে, পুরনো আদায়-বকেয়ার হিস্ট্রি অক্ষত থাকবে।', style: _caption),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (picked != null) setDialogState(() => endDate = picked);
                },
                child: InputDecorator(
                  decoration: _fieldDecoration('ছাড়ার তারিখ', icon: Icons.calendar_today),
                  child: Text('${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.danger, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final res = await ApiService.toggleIncomeSourceStatus(
                        sourceId: int.parse(row['source_id'].toString()),
                        isActive: false,
                        endDate: '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        _snack('নিষ্ক্রিয় করা হয়েছে।');
                        _load();
                      } else {
                        _snack(res['message']?.toString() ?? 'ব্যর্থ হয়েছে', error: true);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('নিষ্ক্রিয় করুন'),
            ),
          ],
        ),
      ),
    );
  }

  // 'unpaid' মাস -> প্রথম আদায় জমা (pay_source), 'partial' মাস -> বকেয়া পরিশোধ (settle_due)
  void _openMonthDialog(Map<String, dynamic> sourceRow, Map<String, dynamic> monthRow) {
    final status = (monthRow['status'] ?? 'unpaid').toString();
    final sourceId = int.parse(sourceRow['source_id'].toString());
    final sourceName = (sourceRow['source_name'] ?? '').toString();
    final targetAmount = _num(monthRow['expected_amount']);
    final due = _num(monthRow['due_amount']);
    final paymentId = monthRow['payment_id'];

    final amountCtrl = TextEditingController(text: (status == 'partial' ? due : targetAmount).toStringAsFixed(0));
    String paymentMethod = 'cash';
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$sourceName — ${_monthLabel(monthRow['month_label'].toString())}', style: _subheading),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'partial'
                      ? 'নির্ধারিত: ${_money(targetAmount)}  •  বর্তমান বকেয়া: ${_money(due)}'
                      : 'নির্ধারিত: ${_money(targetAmount)}',
                  style: _caption,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration(status == 'partial' ? 'পরিশোধের পরিমাণ (৳)' : 'আদায়ের পরিমাণ (৳)', icon: Icons.payments),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: _fieldDecoration('প্রদানের মাধ্যম'),
                  items: _paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDialogState(() => paymentMethod = v ?? paymentMethod),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (amount <= 0) {
                        _snack('সঠিক পরিমাণ দিন', error: true);
                        return;
                      }
                      if (status == 'partial' && amount > due) {
                        _snack('বকেয়ার (${_money(due)}) চেয়ে বেশি দেওয়া যাবে না', error: true);
                        return;
                      }
                      setDialogState(() => saving = true);

                      Map<String, dynamic> res;
                      if (status == 'partial') {
                        res = await ApiService.settleIncomeSourceDue(
                          paymentId: int.parse(paymentId.toString()),
                          settleAmount: amount,
                          paymentDate: _todayStr(),
                          paymentMethod: paymentMethod,
                        );
                      } else {
                        final remainingDue = (targetAmount - amount) > 0 ? (targetAmount - amount) : 0.0;
                        res = await ApiService.payIncomeSource(
                          sourceId: sourceId,
                          incomeMonth: (monthRow['month'] ?? '').toString(),
                          paidAmount: amount,
                          paymentDate: _todayStr(),
                          paymentMethod: paymentMethod,
                          targetAmount: targetAmount,
                          dueAmount: remainingDue,
                        );
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        _snack('আদায় সফলভাবে জমা হয়েছে — ভাউচার নং: ${res['voucher_no'] ?? '-'}');
                        _load();
                      } else {
                        _snack(res['message']?.toString() ?? 'ব্যর্থ হয়েছে', error: true);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('জমা করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        title: Text('সোর্স ও বকেয়া — ${widget.categoryName}'),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSourceDialog,
        backgroundColor: _C.gold,
        icon: const Icon(Icons.add),
        label: const Text('নতুন সোর্স'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : _statusData.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text('এই ক্যাটাগরিতে এখনো কোনো সোর্স (ভাড়াটিয়া/দোকান) যোগ করা হয়নি।', style: _caption, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  color: _C.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _statusData.length,
                    itemBuilder: (context, i) {
                      final row = Map<String, dynamic>.from(_statusData[i]);
                      final months = List<Map<String, dynamic>>.from(row['months'] ?? []);
                      final unpaidCount = months.where((m) => m['status'] != 'paid').length;
                      final totalDue = _num(row['total_due']);
                      final isActive = row['is_active'] == 1 || row['is_active'] == true;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _C.border)),
                        child: ExpansionTile(
                          initiallyExpanded: unpaidCount > 0,
                          leading: Icon(Icons.storefront, color: isActive ? _C.primary : _C.textSecondary),
                          title: Text(
                            (row['source_name'] ?? '').toString(),
                            style: _subheading.copyWith(color: isActive ? _C.textPrimary : _C.textSecondary),
                          ),
                          subtitle: Text(
                            'মাসিক টার্গেট: ${_money(row['monthly_target_amount'])}'
                            '${totalDue > 0 ? '  •  মোট বকেয়া: ${_money(totalDue)}' : '  •  কোনো বকেয়া নেই'}'
                            '${isActive ? '' : '  •  নিষ্ক্রিয়'}',
                            style: TextStyle(fontSize: 12, color: totalDue > 0 ? _C.danger : _C.success),
                          ),
                          trailing: isActive
                              ? IconButton(
                            tooltip: 'নিষ্ক্রিয় করুন',
                            icon: const Icon(Icons.person_off_outlined, color: _C.textSecondary),
                            onPressed: () => _showDeactivateDialog(row),
                          )
                              : IconButton(
                            tooltip: 'সক্রিয় করুন',
                            icon: const Icon(Icons.person_add_alt_1, color: _C.primary),
                            onPressed: () async {
                              final res = await ApiService.toggleIncomeSourceStatus(
                                sourceId: int.parse(row['source_id'].toString()),
                                isActive: true,
                              );
                              if (res['status'] == true) {
                                _load();
                              }
                            },
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: months.map((m) {
                                  final status = (m['status'] ?? 'unpaid').toString();
                                  final color = _statusColor(status);
                                  return InkWell(
                                    onTap: status == 'paid' ? null : () => _openMonthDialog(row, m),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.10),
                                        border: Border.all(color: color.withOpacity(0.4)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_monthLabel(m['month_label'].toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                                          Text(_statusLabel(status), style: TextStyle(fontSize: 11, color: color)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

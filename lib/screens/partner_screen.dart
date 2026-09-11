import 'package:flutter/material.dart';
import '../services/api_service.dart';

// --- ডিজাইন টোকেন (অন্যান্য স্ক্রিনের সাথে সামঞ্জস্যপূর্ণ) ---
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

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  List<dynamic> _partners = [];
  bool _loading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    final list = await ApiService.getPartners(includeInactive: _showInactive);
    if (!mounted) return;
    setState(() {
      _partners = list;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  const Text('অংশীদারদের ভাতা ব্যবস্থাপনা', style: _heading),
                  Row(
                mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showMonthlyStatusDialog,
                        icon: const Icon(Icons.calendar_month, color: _C.primary),
                        label: const Text('মাসিক স্ট্যাটাস', style: TextStyle(color: _C.primary)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.primary)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _showReportDialog,
                        icon: const Icon(Icons.bar_chart, color: _C.primary),
                        label: const Text('রিপোর্ট', style: TextStyle(color: _C.primary)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.primary)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _showAddPartnerDialog,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('নতুন অংশীদার'),
                        style: ElevatedButton.styleFrom(backgroundColor: _C.gold, foregroundColor: Colors.white),
                      ),
                  ],
                ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _showInactive,
                  activeColor: _C.primary,
                  onChanged: (val) {
                    setState(() => _showInactive = val);
                    _loadPartners();
                  },
                ),
                const Text('নিষ্ক্রিয় অংশীদারও দেখান', style: _caption),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: _C.primary)))
            else if (_partners.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Center(child: Text('এখনো কোনো অংশীদার যোগ করা হয়নি', style: _caption)),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(_C.goldLight),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('অংশীদারের নাম', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('মোবাইল', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('মাসিক ভাতা', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('মোট প্রদত্ত', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('মোট বকেয়া', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('সর্বশেষ প্রদান', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('স্ট্যাটাস', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _partners.map((p) {
                            final due = _num(p['total_due']);
                            final isActive = (int.tryParse(p['is_active'].toString()) ?? 1) == 1;
                            return DataRow(cells: [
                              DataCell(Text(
                                p['partner_name']?.toString() ?? '',
                                style: isActive ? null : const TextStyle(decoration: TextDecoration.lineThrough, color: _C.textSecondary),
                              )),
                              DataCell(Text(p['phone']?.toString().isNotEmpty == true ? p['phone'].toString() : '-')),
                              DataCell(Text(_money(p['monthly_allowance']))),
                              DataCell(Text(_money(p['total_paid']), style: const TextStyle(color: _C.primary, fontWeight: FontWeight.bold))),
                              DataCell(Text(
                                _money(p['total_due']),
                                style: TextStyle(color: due > 0 ? _C.danger : _C.textSecondary, fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(p['last_payment_date']?.toString() ?? '-')),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF1E8A4C).withOpacity(0.1) : _C.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়',
                                  style: TextStyle(fontSize: 12, color: isActive ? const Color(0xFF1E8A4C) : _C.danger, fontWeight: FontWeight.w600),
                                ),
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'ভাতা প্রদান',
                                    icon: const Icon(Icons.payments, color: _C.gold, size: 20),
                                    onPressed: () => _showPayAllowanceDialog(p),
                                  ),
                                  IconButton(
                                    tooltip: 'পেমেন্ট হিস্ট্রি ও ভাউচার',
                                    icon: const Icon(Icons.receipt_long, color: _C.primary, size: 20),
                                    onPressed: () => _showHistoryDialog(p),
                                  ),
                                  IconButton(
                                    tooltip: isActive ? 'নিষ্ক্রিয় করুন' : 'আবার সক্রিয় করুন',
                                    icon: Icon(isActive ? Icons.person_off_outlined : Icons.person_add_alt_1, size: 20, color: isActive ? _C.danger : const Color(0xFF1E8A4C)),
                                    onPressed: () => isActive ? _showDeactivatePartnerDialog(p) : _reactivatePartner(p),
                                  ),
                                ],
                              )),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // নতুন অংশীদার যোগ করা
  // ---------------------------------------------------------------------------
  void _showAddPartnerDialog() {
    final nameCtrl = TextEditingController();
    final allowanceCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    DateTime joinDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('নতুন অংশীদার যোগ করুন'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: _fieldDecoration('অংশীদারের নাম', icon: Icons.person)),
                const SizedBox(height: 12),
                TextField(
                  controller: allowanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('মাসিক ভাতার পরিমাণ (৳)', icon: Icons.attach_money),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration('মোবাইল নম্বর (ঐচ্ছিক)', icon: Icons.phone),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: joinDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => joinDate = picked);
                  },
                  child: InputDecorator(
                    decoration: _fieldDecoration('যোগদানের তারিখ', icon: Icons.calendar_today),
                    child: Text('${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Align(alignment: Alignment.centerLeft, child: Text('এই তারিখ থেকেই মাসভিত্তিক ভাতার হিসাব (কোন মাস পরিশোধিত/বকেয়া) শুরু হবে', style: _caption)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.gold, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final allowance = double.tryParse(allowanceCtrl.text.trim());
                      if (name.isEmpty || allowance == null || allowance <= 0) {
                        _snack('নাম ও সঠিক মাসিক ভাতার পরিমাণ দিন', error: true);
                        return;
                      }
                      setDialogState(() => saving = true);
                      final res = await ApiService.addPartner(
                        partnerName: name,
                        monthlyAllowance: allowance,
                        phone: phoneCtrl.text.trim(),
                        joinDate: '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}',
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        _snack(res['message'] ?? 'অংশীদার যুক্ত হয়েছে');
                        _loadPartners();
                      } else {
                        _snack(res['message'] ?? 'সংরক্ষণ ব্যর্থ হয়েছে', error: true);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ভাতা প্রদান
  // ---------------------------------------------------------------------------
  void _showPayAllowanceDialog(Map partner) {
    final allowance = _num(partner['monthly_allowance']);
    final paidCtrl = TextEditingController(text: allowance.toStringAsFixed(0));
    final dueCtrl = TextEditingController(text: '0');
    DateTime paymentDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String paymentMethod = 'cash';
    bool saving = false;

    void recalcDue(StateSetter setDialogState) {
      final paid = double.tryParse(paidCtrl.text.trim()) ?? 0;
      final due = allowance - paid;
      setDialogState(() => dueCtrl.text = (due > 0 ? due : 0).toStringAsFixed(0));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('ভাতা প্রদান — ${partner['partner_name']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('নির্ধারিত মাসিক ভাতা: ${_money(allowance)}', style: _caption),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: _fieldDecoration('মাস'),
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(value: m, child: Text(_banglaMonths[m - 1])))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedMonth = v ?? selectedMonth),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: _fieldDecoration('বছর'),
                        items: List.generate(6, (i) => DateTime.now().year - 2 + i)
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedYear = v ?? selectedYear),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('প্রদত্ত ভাতা (৳)', icon: Icons.payments),
                  onChanged: (_) => recalcDue(setDialogState),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('বকেয়া ভাতা (৳)', icon: Icons.pending_actions),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: _fieldDecoration('প্রদানের মাধ্যম'),
                  items: _paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDialogState(() => paymentMethod = v ?? paymentMethod),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => paymentDate = picked);
                  },
                  child: InputDecorator(
                    decoration: _fieldDecoration('প্রদানের তারিখ', icon: Icons.calendar_today),
                    child: Text('${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final paid = double.tryParse(paidCtrl.text.trim());
                      final due = double.tryParse(dueCtrl.text.trim()) ?? 0;
                      if (paid == null || paid < 0) {
                        _snack('প্রদত্ত ভাতার সঠিক পরিমাণ দিন', error: true);
                        return;
                      }
                      setDialogState(() => saving = true);
                      final monthStr = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-01';
                      final dateStr =
                          '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}';
                      final res = await ApiService.payAllowance(
                        partnerId: int.parse(partner['id'].toString()),
                        paidAmount: paid,
                        paymentDate: dateStr,
                        allowanceMonth: monthStr,
                        paymentMethod: paymentMethod,
                        dueAmount: due,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        _snack('ভাতা প্রদান সম্পন্ন — ভাউচার নং: ${res['voucher_no'] ?? '-'}');
                        _loadPartners();
                      } else {
                        _snack(res['message'] ?? 'ব্যর্থ হয়েছে', error: true);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('প্রদান নিশ্চিত করুন'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // পেমেন্ট হিস্ট্রি ও ভাউচার
  // ---------------------------------------------------------------------------
  void _showHistoryDialog(Map partner) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _HistoryDialogBody(
        partner: partner,
        onSettled: _loadPartners,
        snack: _snack,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // মাসিক ও বার্ষিক রিপোর্ট
  // ---------------------------------------------------------------------------
  void _showReportDialog() {
    bool isMonthly = true;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    Map<String, dynamic>? reportData;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> loadReport() async {
            setDialogState(() => loading = true);
            final res = isMonthly
                ? await ApiService.getMonthlyReport(selectedMonth.toString().padLeft(2, '0'), selectedYear.toString())
                : await ApiService.getYearlyReport(selectedYear.toString());
            setDialogState(() {
              reportData = res;
              loading = false;
            });
          }

          if (reportData == null && !loading) {
            WidgetsBinding.instance.addPostFrameCallback((_) => loadReport());
          }

          final total = reportData != null ? _num(reportData!['partner_allowance_total']) : 0.0;
          final due = reportData != null ? _num(reportData!['partner_allowance_due_total']) : 0.0;

          return AlertDialog(
            title: const Text('অংশীদারদের ভাতার রিপোর্ট'),
            content: SizedBox(
              width: 480,
              height: 460,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('মাসিক'),
                          selected: isMonthly,
                          selectedColor: _C.goldLight,
                          onSelected: (v) {
                            setDialogState(() {
                              isMonthly = true;
                              reportData = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('বার্ষিক'),
                          selected: !isMonthly,
                          selectedColor: _C.goldLight,
                          onSelected: (v) {
                            setDialogState(() {
                              isMonthly = false;
                              reportData = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isMonthly) ...[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: _fieldDecoration('মাস'),
                            items: List.generate(12, (i) => i + 1)
                                .map((m) => DropdownMenuItem(value: m, child: Text(_banglaMonths[m - 1])))
                                .toList(),
                            onChanged: (v) {
                              setDialogState(() {
                                selectedMonth = v ?? selectedMonth;
                                reportData = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: _fieldDecoration('বছর'),
                          items: List.generate(6, (i) => DateTime.now().year - 2 + i)
                              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                              .toList(),
                          onChanged: (v) {
                            setDialogState(() {
                              selectedYear = v ?? selectedYear;
                              reportData = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator(color: _C.primary))
                        : reportData == null
                            ? const SizedBox()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: _C.goldLight, borderRadius: BorderRadius.circular(8)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('মোট প্রদত্ত ভাতা', style: _caption),
                                              Text(_money(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(8)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('মোট বকেয়া ভাতা', style: _caption),
                                              Text(_money(due), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _C.danger)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('অংশীদারভিত্তিক / এন্ট্রিভিত্তিক বিবরণ', style: _subheading),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: _buildReportBreakdown(isMonthly, reportData!),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ করুন'))],
          );
        },
      ),
    );
  }

  Widget _buildReportBreakdown(bool isMonthly, Map<String, dynamic> data) {
    if (isMonthly) {
      final payments = (data['partner_allowance_payments'] as List?) ?? [];
      if (payments.isEmpty) return Center(child: Text('এই মাসে কোনো ভাতা প্রদান হয়নি', style: _caption));
      return ListView.separated(
        itemCount: payments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = payments[i];
          return ListTile(
            dense: true,
            title: Text(p['partner_name']?.toString() ?? ''),
            subtitle: Text('তারিখ: ${p['payment_date']}  •  ভাউচার: ${p['voucher_no'] ?? '-'}'),
            trailing: Text(_money(p['paid_amount']), style: const TextStyle(color: _C.primary, fontWeight: FontWeight.bold)),
          );
        },
      );
    } else {
      final byPartner = (data['partner_allowance_by_partner'] as List?) ?? [];
      if (byPartner.isEmpty) return Center(child: Text('এই বছরে কোনো ভাতা প্রদান হয়নি', style: _caption));
      return ListView.separated(
        itemCount: byPartner.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = byPartner[i];
          final due = _num(p['total_due']);
          return ListTile(
            dense: true,
            title: Text(p['partner_name']?.toString() ?? ''),
            subtitle: due > 0 ? Text('বকেয়া: ${_money(due)}', style: const TextStyle(color: _C.danger)) : null,
            trailing: Text(_money(p['total_paid']), style: const TextStyle(color: _C.primary, fontWeight: FontWeight.bold)),
          );
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // মাসিক স্ট্যাটাস — কোন পার্টনারের কোন মাসের ভাতা পরিশোধিত/বকেয়া তা দেখায়
  // ---------------------------------------------------------------------------
  void _showMonthlyStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 520,
          height: 560,
          child: _MonthlyAllowanceStatusBody(
            onPaid: () async {
              await _loadPartners();
            },
          ),
        ),
      ),
    );
  }

  void _showDeactivatePartnerDialog(Map<String, dynamic> partner) {
    DateTime endDate = DateTime.now();
    bool saving = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${partner['partner_name']}-কে নিষ্ক্রিয় করবেন?', style: _subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ডিলিট হবে না — শুধু নিষ্ক্রিয় হবে, পুরনো ভাতা হিস্ট্রি অক্ষত থাকবে। পরে চাইলে আবার সক্রিয় করা যাবে।', style: _caption),
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
                      final res = await ApiService.togglePartnerStatus(
                        id: int.tryParse(partner['id'].toString()) ?? 0,
                        active: false,
                        endDate: '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        await _loadPartners();
                      } else if (mounted) {
                        _snack(res['message']?.toString() ?? 'নিষ্ক্রিয় করা যায়নি', error: true);
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

  Future<void> _reactivatePartner(Map<String, dynamic> partner) async {
    final res = await ApiService.togglePartnerStatus(id: int.tryParse(partner['id'].toString()) ?? 0, active: true);
    if (!mounted) return;
    if (res['status'] == true) {
      await _loadPartners();
    } else {
      _snack(res['message']?.toString() ?? 'সক্রিয় করা যায়নি', error: true);
    }
  }
}

// ---------------------------------------------------------------------------
// মাসিক ভাতা স্ট্যাটাস — প্রতিটা পার্টনারের জন্য join_date থেকে বর্তমান মাস
// পর্যন্ত সব মাসের Paid/Partial/Unpaid অবস্থা দেখায়, ট্যাপ করলে সেই মাসের
// ভাতা সরাসরি প্রদান করা যায়
// ---------------------------------------------------------------------------
class _MonthlyAllowanceStatusBody extends StatefulWidget {
  final Future<void> Function() onPaid;
  const _MonthlyAllowanceStatusBody({required this.onPaid});

  @override
  State<_MonthlyAllowanceStatusBody> createState() => _MonthlyAllowanceStatusBodyState();
}

class _MonthlyAllowanceStatusBodyState extends State<_MonthlyAllowanceStatusBody> {
  bool _loading = true;
  List<dynamic> _statusData = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAllowanceStatus();
    if (!mounted) return;
    setState(() {
      _statusData = data;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF1E8A4C);
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

  void _openPayForMonth(Map<String, dynamic> partnerRow, Map<String, dynamic> monthRow) {
    final partnerId = int.tryParse(partnerRow['partner_id'].toString()) ?? 0;
    final partnerName = (partnerRow['partner_name'] ?? '').toString();
    final monthlyAllowance = _num(partnerRow['monthly_allowance']);
    final due = _num(monthRow['due_amount']);
    final allowanceMonth = (monthRow['month'] ?? '').toString(); // YYYY-MM-01
    final amountCtrl = TextEditingController(text: (due > 0 ? due : monthlyAllowance).toStringAsFixed(0));
    String paymentMethod = 'cash';
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$partnerName — ${_monthLabel(monthRow['month_label'].toString())} ভাতা', style: _subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('প্রদানের পরিমাণ')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: _fieldDecoration('পরিশোধের মাধ্যম'),
                value: paymentMethod,
                items: _paymentMethods.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) => setDialogState(() => paymentMethod = val ?? 'cash'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text) ?? 0;
                      if (amount <= 0) return;
                      setDialogState(() => saving = true);
                      final remainingDue = (monthlyAllowance - amount) > 0 ? (monthlyAllowance - amount) : 0;
                      final res = await ApiService.payAllowance(
                        partnerId: partnerId,
                        paidAmount: amount,
                        paymentDate: DateTime.now().toIso8601String().split('T')[0],
                        allowanceMonth: allowanceMonth,
                        paymentMethod: paymentMethod,
                        dueAmount: remainingDue.toDouble(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        await _load();
                        await widget.onPaid();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'ভাতা প্রদান ব্যর্থ হয়েছে')));
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('প্রদান করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              const Expanded(child: Text('মাসিক ভাতা স্ট্যাটাস', style: _heading)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _C.primary))
              : _statusData.isEmpty
                  ? Center(child: Text('কোনো অংশীদার নেই', style: _caption))
                  : RefreshIndicator(
                      color: _C.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _statusData.length,
                        itemBuilder: (context, i) {
                          final row = Map<String, dynamic>.from(_statusData[i]);
                          final months = List<Map<String, dynamic>>.from(row['months'] ?? []);
                          final unpaidCount = months.where((m) => m['status'] != 'paid').length;
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _C.border)),
                            child: ExpansionTile(
                              initiallyExpanded: unpaidCount > 0,
                              title: Text((row['partner_name'] ?? '').toString(), style: _subheading),
                              subtitle: Text(
                                unpaidCount == 0 ? 'সব মাসের ভাতা পরিশোধিত' : '$unpaidCount মাসের ভাতা বকেয়া/আংশিক',
                                style: TextStyle(fontSize: 12, color: unpaidCount == 0 ? const Color(0xFF1E8A4C) : _C.danger),
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
                                        onTap: status == 'paid' ? null : () => _openPayForMonth(row, m),
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
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// পেমেন্ট হিস্ট্রি ডায়ালগ — নিজস্ব state আছে যাতে বকেয়া পরিশোধের পর তালিকা রিফ্রেশ হয়
// ---------------------------------------------------------------------------
class _HistoryDialogBody extends StatefulWidget {
  final Map partner;
  final VoidCallback onSettled;
  final void Function(String msg, {bool error}) snack;

  const _HistoryDialogBody({required this.partner, required this.onSettled, required this.snack});

  @override
  State<_HistoryDialogBody> createState() => _HistoryDialogBodyState();
}

class _HistoryDialogBodyState extends State<_HistoryDialogBody> {
  List<dynamic> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getAllowancePayments(partnerId: int.parse(widget.partner['id'].toString()));
    if (!mounted) return;
    setState(() {
      _payments = list;
      _loading = false;
    });
  }

  void _showSettleDueDialog(Map payment) {
    final due = _num(payment['due_amount']);
    final amountCtrl = TextEditingController(text: due.toStringAsFixed(0));
    DateTime settleDate = DateTime.now();
    String paymentMethod = 'cash';
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('বকেয়া ভাতা পরিশোধ'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('মাস: ${payment['allowance_month']}  •  বর্তমান বকেয়া: ${_money(due)}', style: _caption),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('পরিশোধের পরিমাণ (৳)', icon: Icons.payments),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: _fieldDecoration('প্রদানের মাধ্যম'),
                  items: _paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDialogState(() => paymentMethod = v ?? paymentMethod),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: settleDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => settleDate = picked);
                  },
                  child: InputDecorator(
                    decoration: _fieldDecoration('পরিশোধের তারিখ', icon: Icons.calendar_today),
                    child: Text('${settleDate.year}-${settleDate.month.toString().padLeft(2, '0')}-${settleDate.day.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        widget.snack('সঠিক পরিমাণ দিন', error: true);
                        return;
                      }
                      if (amount > due) {
                        widget.snack('বকেয়ার (${_money(due)}) চেয়ে বেশি দেওয়া যাবে না', error: true);
                        return;
                      }
                      setDialogState(() => saving = true);
                      final dateStr =
                          '${settleDate.year}-${settleDate.month.toString().padLeft(2, '0')}-${settleDate.day.toString().padLeft(2, '0')}';
                      final res = await ApiService.settleAllowanceDue(
                        paymentId: int.parse(payment['id'].toString()),
                        settleAmount: amount,
                        paymentDate: dateStr,
                        paymentMethod: paymentMethod,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        widget.snack('বকেয়া পরিশোধ সম্পন্ন — ভাউচার নং: ${res['voucher_no'] ?? '-'}');
                        _load();
                        widget.onSettled();
                      } else {
                        widget.snack(res['message'] ?? 'ব্যর্থ হয়েছে', error: true);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('পরিশোধ নিশ্চিত করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('পেমেন্ট হিস্ট্রি — ${widget.partner['partner_name']}'),
      content: SizedBox(
        width: 500,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _C.primary))
            : _payments.isEmpty
                ? Center(child: Text('কোনো পেমেন্ট রেকর্ড নেই', style: _caption))
                : ListView.separated(
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = _payments[i];
                      final month = p['allowance_month']?.toString() ?? '';
                      final due = _num(p['due_amount']);
                      return ListTile(
                        dense: true,
                        title: Text('মাস: $month  •  ভাউচার: ${p['voucher_no'] ?? '-'}'),
                        subtitle: Text('তারিখ: ${p['payment_date']}${due > 0 ? '  •  বকেয়া: ${_money(due)}' : ''}'),
                        trailing: due > 0
                            ? TextButton(
                                onPressed: () => _showSettleDueDialog(p),
                                style: TextButton.styleFrom(foregroundColor: _C.danger),
                                child: const Text('পরিশোধ করুন'),
                              )
                            : Text(_money(p['paid_amount']), style: const TextStyle(color: _C.primary, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ করুন'))],
    );
  }
}

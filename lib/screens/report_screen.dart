import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

enum _PeriodType { daily, weekly, monthly, yearly, audit }

class _ReportScreenState extends State<ReportScreen> {
  _PeriodType _periodType = _PeriodType.monthly;

  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)); // চলতি সপ্তাহের সোমবার
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTimeRange? _auditRange;

  bool _isLoading = false;
  Map<String, dynamic>? _report;

  // কোন কোন সেকশন দেখানো হবে (রিপোর্ট "ফোকাস" — ব্যবহারকারীর তালিকার প্রতিটা রিপোর্ট নামের সাথে মিলিয়ে)
  final Set<String> _visibleSections = {
    'income', 'expense', 'cash_bank', 'loan', 'staff_salary', 'partner_allowance', 'vouchers'
  };

  static const Map<String, String> _sectionLabels = {
    'income': 'আয় রিপোর্ট',
    'expense': 'ব্যয় রিপোর্ট',
    'cash_bank': 'ক্যাশ ও ব্যাংক রিপোর্ট',
    'loan': 'ঋণ রিপোর্ট',
    'staff_salary': 'স্টাফ বেতন রিপোর্ট',
    'partner_allowance': 'অংশীদারদের ভাতা রিপোর্ট',
    'vouchers': 'ভাউচার রিপোর্ট',
  };

  static const List<String> _bnMonthNames = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> res = {};

    switch (_periodType) {
      case _PeriodType.daily:
        res = await ApiService.getDailyReport(DateFormat('yyyy-MM-dd').format(_selectedDate));
        break;
      case _PeriodType.weekly:
        res = await ApiService.getWeeklyReport(DateFormat('yyyy-MM-dd').format(_weekStart));
        break;
      case _PeriodType.monthly:
        res = await ApiService.getMonthlyReport(
          _selectedMonth.toString().padLeft(2, '0'),
          _selectedYear.toString(),
        );
        break;
      case _PeriodType.yearly:
        res = await ApiService.getYearlyReport(_selectedYear.toString());
        break;
      case _PeriodType.audit:
        res = await ApiService.getAuditReport(
          startDate: _auditRange != null ? DateFormat('yyyy-MM-dd').format(_auditRange!.start) : null,
          endDate: _auditRange != null ? DateFormat('yyyy-MM-dd').format(_auditRange!.end) : null,
        );
        break;
    }

    if (mounted) {
      setState(() {
        _report = res;
        _isLoading = false;
      });
    }
  }

  String _periodLabel() {
    switch (_periodType) {
      case _PeriodType.daily:
        return 'দৈনিক রিপোর্ট — ${DateFormat('yyyy-MM-dd').format(_selectedDate)}';
      case _PeriodType.weekly:
        final weekEnd = _weekStart.add(const Duration(days: 6));
        return 'সাপ্তাহিক রিপোর্ট — ${DateFormat('yyyy-MM-dd').format(_weekStart)} থেকে ${DateFormat('yyyy-MM-dd').format(weekEnd)}';
      case _PeriodType.monthly:
        return 'মাসিক রিপোর্ট — ${_bnMonthNames[_selectedMonth - 1]} $_selectedYear';
      case _PeriodType.yearly:
        return 'বার্ষিক রিপোর্ট / আর্থিক বিবরণী — $_selectedYear';
      case _PeriodType.audit:
        return _auditRange != null
            ? 'অডিট রিপোর্ট — ${DateFormat('yyyy-MM-dd').format(_auditRange!.start)} থেকে ${DateFormat('yyyy-MM-dd').format(_auditRange!.end)}'
            : 'অডিট রিপোর্ট — সম্পূর্ণ সময়কাল';
    }
  }

  Future<void> _pickDailyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _generateReport();
    }
  }

  // ব্যবহারকারী যেকোনো দিন বেছে নিলে সেই দিন যে সপ্তাহে পড়ে তার সোমবারকেই _weekStart ধরা হয়
  Future<void> _pickWeekStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final monday = picked.subtract(Duration(days: picked.weekday - 1));
      setState(() => _weekStart = monday);
      _generateReport();
    }
  }

  Future<void> _pickAuditRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _auditRange,
    );
    if (range != null) {
      setState(() => _auditRange = range);
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('অডিট ও আর্থিক রিপোর্ট সেন্টার', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'রিফ্রেশ',
                    onPressed: _generateReport,
                  ),
                  OutlinedButton.icon(
                    onPressed: (_report == null || _isLoading)
                        ? null
                        : () => PdfService.printReport(
                      report: _report!,
                      periodLabel: _periodLabel(),
                      visibleSections: _visibleSections,
                      isAudit: _periodType == _PeriodType.audit,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildSectionChips(),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
          else if (_report == null || _report!['status'] != true)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Text('রিপোর্ট আনা যায়নি — আবার চেষ্টা করুন', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            _buildReportBody(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // পিরিয়ড সিলেক্টর (দৈনিক / মাসিক / বার্ষিক / কাস্টম রেঞ্জ-অডিট)
  // ---------------------------------------------------------------------------
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<_PeriodType>(
              value: _periodType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'রিপোর্টের ভিত্তি', border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(
                  value: _PeriodType.daily,
                  child: Text('দৈনিক রিপোর্ট', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: _PeriodType.weekly,
                  child: Text('সাপ্তাহিক রিপোর্ট', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: _PeriodType.monthly,
                  child: Text('মাসিক রিপোর্ট', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: _PeriodType.yearly,
                  child: Text('বার্ষিক রিপোর্ট / আর্থিক বিবরণী', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: _PeriodType.audit,
                  child: Text('অডিট রিপোর্ট (কাস্টম রেঞ্জ)', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() => _periodType = val);
                _generateReport();
              },
            ),
          ),
          if (_periodType == _PeriodType.daily)
            OutlinedButton.icon(
              onPressed: _pickDailyDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            ),
          if (_periodType == _PeriodType.weekly)
            OutlinedButton.icon(
              onPressed: _pickWeekStart,
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(
                '${DateFormat('yyyy-MM-dd').format(_weekStart)} — ${DateFormat('yyyy-MM-dd').format(_weekStart.add(const Duration(days: 6)))}',
              ),
            ),
          if (_periodType == _PeriodType.monthly) ...[
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<int>(
                value: _selectedMonth,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'মাস', border: OutlineInputBorder(), isDense: true),
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(value: m, child: Text(_bnMonthNames[m - 1], overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedMonth = val);
                  _generateReport();
                },
              ),
            ),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(labelText: 'বছর', border: OutlineInputBorder(), isDense: true),
                items: List.generate(8, (i) => DateTime.now().year - 5 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedYear = val);
                  _generateReport();
                },
              ),
            ),
          ],
          if (_periodType == _PeriodType.yearly)
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(labelText: 'বছর', border: OutlineInputBorder(), isDense: true),
                items: List.generate(8, (i) => DateTime.now().year - 5 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedYear = val);
                  _generateReport();
                },
              ),
            ),
          if (_periodType == _PeriodType.audit)
            OutlinedButton.icon(
              onPressed: _pickAuditRange,
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(
                _auditRange != null
                    ? '${DateFormat('yyyy-MM-dd').format(_auditRange!.start)} — ${DateFormat('yyyy-MM-dd').format(_auditRange!.end)}'
                    : 'সম্পূর্ণ সময়কাল (রেঞ্জ বেছে নিন)',
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // কোন কোন সেকশন দেখানো হবে তার চিপ (আয়/ব্যয়/ক্যাশ-ব্যাংক/ঋণ/স্টাফ/অংশীদার/ভাউচার)
  // ---------------------------------------------------------------------------
  Widget _buildSectionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sectionLabels.entries.map((e) {
        final selected = _visibleSections.contains(e.key);
        return FilterChip(
          label: Text(e.value, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _visibleSections.add(e.key);
              } else {
                _visibleSections.remove(e.key);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // রিপোর্টের মূল অংশ
  // ---------------------------------------------------------------------------
  Widget _buildReportBody() {
    final r = _report!;
    final isAudit = _periodType == _PeriodType.audit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // সারসংক্ষেপ কার্ড
        LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 700;
          return GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              if (!isAudit) _statCard('মোট আয়', r['total_income'], Colors.green),
              if (!isAudit) _statCard('মোট ব্যয়', r['total_expense'], Colors.red),
              if (!isAudit) _statCard('নিট ব্যালেন্স', r['net_balance'], Colors.blueGrey),
              _statCard('ক্যাশ ব্যালেন্স', r['cash_balance'], Colors.teal),
              _statCard('ব্যাংক ব্যালেন্স', r['bank_balance'], Colors.blue),
              if (r['bkash_balance'] != null) _statCard('বিকাশ ব্যালেন্স', r['bkash_balance'], Colors.pink),
              if (r['nagad_balance'] != null) _statCard('নগদ ব্যালেন্স', r['nagad_balance'], Colors.orange),
              if (r['total_balance'] != null) _statCard('মোট ব্যালেন্স (সব মাধ্যম)', r['total_balance'], Colors.deepPurple),
            ],
          );
        }),
        const SizedBox(height: 24),

        if (_visibleSections.contains('income') && r['income_by_category'] != null)
          _categoryTable('খাতভিত্তিক আয় (Income Report)', r['income_by_category'], Colors.green),

        if (_visibleSections.contains('expense') && r['expense_by_category'] != null)
          _categoryTable('খাতভিত্তিক ব্যয় (Expense Report)', r['expense_by_category'], Colors.red),

        if (_visibleSections.contains('loan') && r['loan_payments'] != null)
          _paymentsSection(
            'ঋণ পরিশোধ রিপোর্ট',
            r['loan_payments'],
            r['loan_payment_total'],
            nameKey: 'lender_name',
            amountKey: 'amount_paid',
          ),
        if (_visibleSections.contains('loan') && isAudit && r['loans'] != null)
          _rawTable('ঋণের তালিকা (সব)', r['loans'], ['lender_name', 'loan_amount', 'remaining_amount', 'loan_date']),

        if (_visibleSections.contains('staff_salary') && r['staff_salary_payments'] != null)
          _paymentsSection(
            'স্টাফ বেতন রিপোর্ট',
            r['staff_salary_payments'],
            r['staff_salary_total'],
            nameKey: 'staff_name',
            amountKey: 'paid_amount',
          ),
        if (_visibleSections.contains('staff_salary') && isAudit && r['staff_salary'] != null)
          _rawTable('স্টাফ বেতন (সম্পূর্ণ ইতিহাস)', r['staff_salary'], ['staff_name', 'salary_month', 'paid_amount', 'payment_date']),

        if (_visibleSections.contains('partner_allowance') && r['partner_allowance_payments'] != null)
          _paymentsSection(
            'অংশীদারদের ভাতা রিপোর্ট',
            r['partner_allowance_payments'],
            r['partner_allowance_total'],
            nameKey: 'partner_name',
            amountKey: 'paid_amount',
          ),
        if (_visibleSections.contains('partner_allowance') && isAudit && r['partner_allowance'] != null)
          _rawTable('অংশীদার ভাতা (সম্পূর্ণ ইতিহাস)', r['partner_allowance'], ['partner_name', 'allowance_month', 'paid_amount', 'payment_date']),

        if (_visibleSections.contains('vouchers') && r['vouchers'] != null)
          _rawTable('ভাউচার রিপোর্ট', r['vouchers'], ['voucher_no', 'voucher_type', 'amount', 'voucher_date']),

        if (isAudit && r['audit_trail'] != null)
          _rawTable('সম্পূর্ণ আয়-ব্যয় লেজার (Audit Trail)', r['audit_trail'], ['type', 'description', 'amount', 'transaction_date']),
      ],
    );
  }

  Widget _statCard(String title, dynamic value, Color color) {
    final amount = (value is num) ? value : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9))),
          const SizedBox(height: 4),
          Text('৳ ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _categoryTable(String title, List<dynamic> rows, Color color) {
    if (rows.isEmpty) {
      return _sectionCard(title, const Text('কোনো ডেটা নেই', style: TextStyle(color: Colors.grey)));
    }
    return _sectionCard(
      title,
      Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row['category_name'] ?? '-'),
                Text('৳ ${row['total'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _paymentsSection(String title, List<dynamic> rows, dynamic total, {required String nameKey, required String amountKey}) {
    return _sectionCard(
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('মোট: ৳ ${total ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          if (rows.isEmpty)
            const Text('এই সময়কালে কোনো পেমেন্ট হয়নি', style: TextStyle(color: Colors.grey))
          else
            ...rows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row[nameKey] ?? '-'),
                    Text('৳ ${row[amountKey] ?? 0}  (${row['payment_date'] ?? '-'})', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _rawTable(String title, List<dynamic> rows, List<String> columns) {
    if (rows.isEmpty) {
      return _sectionCard(title, const Text('কোনো ডেটা নেই', style: TextStyle(color: Colors.grey)));
    }
    return _sectionCard(
      title,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
          rows: rows.map<DataRow>((row) {
            return DataRow(cells: columns.map((c) => DataCell(Text('${row[c] ?? '-'}'))).toList());
          }).toList(),
        ),
      ),
    );
  }
}
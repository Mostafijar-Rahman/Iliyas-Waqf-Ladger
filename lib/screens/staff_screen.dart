import 'package:flutter/material.dart';
import '../services/api_service.dart';

// --- ডিজাইন টোকেন ---
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

const _heading = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _C.textPrimary);
const _subheading = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.textPrimary);
const _caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _C.textSecondary);

InputDecoration _fieldDecoration(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  prefixIcon: icon != null ? Icon(icon, size: 18, color: _C.textSecondary) : null,
  filled: true,
  fillColor: _C.surface,
  labelStyle: const TextStyle(color: _C.textSecondary, fontSize: 13),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
);

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

// 'YYYY-MM-DD' -> 'DD-MM-YYYY' (সার্ভার থেকে আসা তারিখ দিন সহ দেখানোর জন্য)
String _formatDate(dynamic raw) {
  final s = (raw ?? '').toString();
  if (s.length < 10) return s;
  final parts = s.substring(0, 10).split('-');
  if (parts.length != 3) return s;
  return '${parts[2]}-${parts[1]}-${parts[0]}';
}

String _paymentMethodLabel(dynamic method) {
  switch ((method ?? '').toString()) {
    case 'cash':
      return 'ক্যাশ';
    case 'bank':
      return 'ব্যাংক';
    case 'bkash':
      return 'বিকাশ';
    case 'nagad':
      return 'নগদ';
    default:
      return '-';
  }
}

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  bool _showInactive = false;
  List<Map<String, dynamic>> _staffs = [];
  List<Map<String, dynamic>> _salaryLogs = [];
  List<Map<String, dynamic>> _advances = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getStaffs(includeInactive: _showInactive),
      ApiService.getSalaryLogs(),
      ApiService.getAdvances(),
    ]);
    if (!mounted) return;
    setState(() {
      _staffs = List<Map<String, dynamic>>.from(results[0]);
      _salaryLogs = List<Map<String, dynamic>>.from(results[1]);
      _advances = List<Map<String, dynamic>>.from(results[2]);
      _loading = false;
    });
  }

  // একজন স্টাফের সমস্ত বকেয়া অগ্রিম এন্ট্রি (remaining_amount > 0), পুরনো তারিখ আগে
  List<Map<String, dynamic>> _outstandingAdvancesFor(int staffId) {
    final list = _advances
        .where((a) => _asInt(a['staff_id']) == staffId && _asDouble(a['remaining_amount']) > 0)
        .toList();
    list.sort((a, b) => (a['advance_date'] ?? '').toString().compareTo((b['advance_date'] ?? '').toString()));
    return list;
  }

  double _totalOutstandingFor(int staffId) {
    return _outstandingAdvancesFor(staffId).fold(0.0, (sum, a) => sum + _asDouble(a['remaining_amount']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        title: const Text('স্টাফ ও পে-রোল ম্যানেজমেন্ট', style: TextStyle(color: _C.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: _C.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAll,
            icon: const Icon(Icons.refresh, color: _C.primary),
            tooltip: 'রিফ্রেশ করুন',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _C.primary,
          unselectedLabelColor: _C.textSecondary,
          indicatorColor: _C.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'স্টাফ তালিকা'),
            Tab(text: 'বেতন দিন'),
            Tab(text: 'অগ্রিম (Advance)'),
            Tab(text: 'মাসিক স্ট্যাটাস'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildStaffListTab(),
          _buildPaySalaryTab(),
          _buildAdvanceTab(),
          _MonthlyStatusTab(staffs: _staffs),
        ],
      ),
    );
  }

  // ================= ১. স্টাফ তালিকা =================
  Widget _buildStaffListTab() {
    return RefreshIndicator(
      color: _C.primary,
      onRefresh: _loadAll,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Switch(
                      value: _showInactive,
                      activeColor: _C.primary,
                      onChanged: (val) {
                        setState(() => _showInactive = val);
                        _loadAll();
                      },
                    ),
                    const Text('নিষ্ক্রিয় স্টাফও দেখান', style: _caption),
                  ],
                ),
              ),
              Expanded(
                child: _staffs.isEmpty
                    ? ListView(
                  padding: const EdgeInsets.all(40),
                  children: const [
                    Center(child: Text('কোনো স্টাফের তথ্য পাওয়া যায়নি', style: _caption)),
                  ],
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _staffs.length,
                  itemBuilder: (context, index) {
                    final s = _staffs[index];
                    final name = (s['staff_name'] ?? '').toString();
                    final isActive = _asInt(s['is_active']) == 1;
                    final outstanding = _totalOutstandingFor(_asInt(s['id']));
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isActive ? _C.surface : const Color(0xFFF2F2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isActive ? _C.border : const Color(0xFFD8D8D8))),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? _C.goldLight : const Color(0xFFE0E0E0),
                          child: Text(name.isNotEmpty ? name[0] : 'S', style: TextStyle(color: isActive ? _C.gold : _C.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name, style: isActive ? _subheading : _subheading.copyWith(color: _C.textSecondary, decoration: TextDecoration.lineThrough)),
                        subtitle: Text(
                          '${s['designation'] ?? ''} • ${s['phone'] ?? ''}'
                              '${!isActive ? '\nনিষ্ক্রিয় — ছাড়ার তারিখ: ${_formatDate(s['end_date'])}' : ''}'
                              '${isActive && outstanding > 0 ? '\nবকেয়া অগ্রিম: ৳${outstanding.toStringAsFixed(0)}' : ''}',
                          style: !isActive ? const TextStyle(fontSize: 12, color: _C.danger) : _caption,
                        ),
                        isThreeLine: !isActive || (isActive && outstanding > 0),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('৳${_asDouble(s['monthly_salary']).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? _C.primary : _C.textSecondary, fontSize: 14)),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: _C.textSecondary),
                              tooltip: 'পদবি/বেতন এডিট করুন',
                              onPressed: () => _showEditStaffDialog(s),
                            ),
                            IconButton(
                              icon: Icon(isActive ? Icons.person_off_outlined : Icons.person_add_alt_1, size: 18, color: isActive ? _C.danger : const Color(0xFF1E8A4C)),
                              tooltip: isActive ? 'নিষ্ক্রিয় করুন' : 'আবার সক্রিয় করুন',
                              onPressed: () => isActive ? _showDeactivateDialog(s) : _reactivateStaff(s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              backgroundColor: _C.primary,
              onPressed: _showAddStaffDialog,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('নতুন স্টাফ', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // ================= ২. বেতন প্রদান =================
  Widget _buildPaySalaryTab() {
    return RefreshIndicator(
      color: _C.primary,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('বেতন শিট এন্ট্রি', style: _heading),
            const SizedBox(height: 12),
            _SalaryForm(
              staffs: _staffs,
              outstandingAdvancesFor: _outstandingAdvancesFor,
              onPaid: () async {
                await _loadAll();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বেতন সফলভাবে প্রদান করা হয়েছে')));
              },
            ),
            const SizedBox(height: 20),
            const Text('সাম্প্রতিক বেতন প্রদানের ইতিহাস', style: _subheading),
            const SizedBox(height: 10),
            if (_salaryLogs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('এখনো কোনো বেতন দেওয়া হয়নি', style: _caption))),
            ..._salaryLogs.map((log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((log['staff_name'] ?? '').toString(), style: _subheading),
                        Text(
                          '${_formatDate(log['payment_date'])} • মাস: ${(log['salary_month'] ?? '').toString().substring(0, 7)} • ${_paymentMethodLabel(log['payment_method'])}'
                              '${_asDouble(log['advance_deducted']) > 0 ? ' • অগ্রিম কর্তন ৳${_asDouble(log['advance_deducted']).toStringAsFixed(0)}' : ''}',
                          style: _caption,
                        ),
                      ],
                    ),
                  ),
                  Text('৳${_asDouble(log['paid_amount']).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: _C.primary, fontSize: 15)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ================= ৩. অগ্রিম (Advance) =================
  Widget _buildAdvanceTab() {
    return _AdvanceTabBody(
      staffs: _staffs,
      advances: _advances,
      onSaved: () async {
        await _loadAll();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অগ্রিম এন্ট্রি সেভ হয়েছে')));
      },
    );
  }

  // --- নতুন স্টাফ যোগ করার ডায়ালগ ---
  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    DateTime joinDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('নতুন স্টাফ যোগ করুন', style: _heading),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: _fieldDecoration('স্টাফের নাম')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _fieldDecoration('মোবাইল নম্বর')),
                const SizedBox(height: 8),
                TextField(controller: desigCtrl, decoration: _fieldDecoration('পদবি')),
                const SizedBox(height: 8),
                TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('নির্ধারিত বেতন')),
                const SizedBox(height: 8),
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
                  child: Align(alignment: Alignment.centerLeft, child: Text('এই তারিখ থেকেই মাসভিত্তিক বেতনের হিসাব (কোন মাস পরিশোধিত/বকেয়া) শুরু হবে', style: _caption)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
              onPressed: saving
                  ? null
                  : () async {
                final salary = double.tryParse(salaryCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || salary <= 0) return;
                setDialogState(() => saving = true);
                final res = await ApiService.addStaff(
                  staffName: nameCtrl.text.trim(),
                  monthlySalary: salary,
                  designation: desigCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  joinDate: '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}',
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res['status'] == true) {
                  await _loadAll();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'স্টাফ যুক্ত করা যায়নি')));
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('সেভ করুন', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  // --- স্টাফের পদবি/বেতন/নাম/মোবাইল এডিট করার ডায়ালগ ---
  void _showEditStaffDialog(Map<String, dynamic> staff) {
    final nameCtrl = TextEditingController(text: (staff['staff_name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (staff['phone'] ?? '').toString());
    final desigCtrl = TextEditingController(text: (staff['designation'] ?? '').toString());
    final salaryCtrl = TextEditingController(text: _asDouble(staff['monthly_salary']).toStringAsFixed(0));
    DateTime joinDate = DateTime.tryParse((staff['join_date'] ?? '').toString()) ?? DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('স্টাফের তথ্য এডিট করুন', style: _heading),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: _fieldDecoration('স্টাফের নাম')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _fieldDecoration('মোবাইল নম্বর')),
                const SizedBox(height: 8),
                TextField(controller: desigCtrl, decoration: _fieldDecoration('পদবি')),
                const SizedBox(height: 8),
                TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('নির্ধারিত বেতন')),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
              onPressed: saving
                  ? null
                  : () async {
                final salary = double.tryParse(salaryCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || salary <= 0) return;
                setDialogState(() => saving = true);
                final res = await ApiService.updateStaff(
                  id: _asInt(staff['id']),
                  staffName: nameCtrl.text.trim(),
                  monthlySalary: salary,
                  designation: desigCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  joinDate: '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}',
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res['status'] == true) {
                  await _loadAll();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'তথ্য আপডেট করা যায়নি')));
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('আপডেট করুন', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showDeactivateDialog(Map<String, dynamic> staff) {
    DateTime endDate = DateTime.now();
    bool saving = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${staff['staff_name']}-কে নিষ্ক্রিয় করবেন?', style: _subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ডিলিট হবে না — শুধু নিষ্ক্রিয় হবে, পুরনো বেতন হিস্ট্রি অক্ষত থাকবে। পরে চাইলে আবার সক্রিয় করা যাবে।', style: _caption),
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
              style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
              onPressed: saving
                  ? null
                  : () async {
                setDialogState(() => saving = true);
                final res = await ApiService.toggleStaffStatus(
                  id: _asInt(staff['id']),
                  active: false,
                  endDate: '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res['status'] == true) {
                  await _loadAll();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'নিষ্ক্রিয় করা যায়নি')));
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('নিষ্ক্রিয় করুন', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reactivateStaff(Map<String, dynamic> staff) async {
    final res = await ApiService.toggleStaffStatus(id: _asInt(staff['id']), active: true);
    if (!mounted) return;
    if (res['status'] == true) {
      await _loadAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'সক্রিয় করা যায়নি')));
    }
  }
}

// --- বেতন ডাইনামিক ফর্ম (রিয়েল ব্যাকএন্ড + অগ্রিম সমন্বয় সহ) ---
class _SalaryForm extends StatefulWidget {
  final List<Map<String, dynamic>> staffs;
  final List<Map<String, dynamic>> Function(int staffId) outstandingAdvancesFor;
  final Future<void> Function() onPaid;

  const _SalaryForm({
    required this.staffs,
    required this.outstandingAdvancesFor,
    required this.onPaid,
  });

  @override
  State<_SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends State<_SalaryForm> {
  Map<String, dynamic>? _selectedStaff;
  late final TextEditingController _basicCtrl;
  late final TextEditingController _bonusCtrl;
  late final TextEditingController _deductCtrl; // অন্যান্য কর্তন (অগ্রিম বাদে)
  late final TextEditingController _advanceSettleCtrl; // অগ্রিম থেকে কর্তন

  String _paymentMethod = 'cash';
  bool _saving = false;
  int _selectedMonthNum = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  String get _selectedMonth => '$_selectedYear-${_selectedMonthNum.toString().padLeft(2, '0')}-01'; // YYYY-MM-01 ফরম্যাটে সার্ভারে যায়

  static const _banglaMonths = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  @override
  void initState() {
    super.initState();
    _basicCtrl = TextEditingController();
    _bonusCtrl = TextEditingController(text: '0');
    _deductCtrl = TextEditingController(text: '0');
    _advanceSettleCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _basicCtrl.dispose();
    _bonusCtrl.dispose();
    _deductCtrl.dispose();
    _advanceSettleCtrl.dispose();
    super.dispose();
  }

  double get _outstandingAdvance {
    if (_selectedStaff == null) return 0;
    return widget.outstandingAdvancesFor(_asInt(_selectedStaff!['id']))
        .fold(0.0, (sum, a) => sum + _asDouble(a['remaining_amount']));
  }

  double get _netPayable {
    final basic = double.tryParse(_basicCtrl.text) ?? 0;
    final bonus = double.tryParse(_bonusCtrl.text) ?? 0;
    final deduct = double.tryParse(_deductCtrl.text) ?? 0;
    final advanceSettle = double.tryParse(_advanceSettleCtrl.text) ?? 0;
    final total = (basic + bonus) - deduct - advanceSettle;
    return total < 0 ? 0 : total;
  }

  void _resetForm() {
    setState(() {
      _selectedStaff = null;
      _basicCtrl.clear();
      _bonusCtrl.text = '0';
      _deductCtrl.text = '0';
      _advanceSettleCtrl.text = '0';
      _paymentMethod = 'cash';
    });
  }

  // অগ্রিম সমন্বয়ের টাকাটা বকেয়া অগ্রিমগুলোর উপর পুরনো থেকে নতুন ক্রমে ভাগ করে দেয়
  List<Map<String, dynamic>> _distributeAdvanceSettlement(double amount) {
    final outstanding = widget.outstandingAdvancesFor(_asInt(_selectedStaff!['id']));
    final result = <Map<String, dynamic>>[];
    double remaining = amount;
    for (final adv in outstanding) {
      if (remaining <= 0) break;
      final take = remaining >= _asDouble(adv['remaining_amount']) ? _asDouble(adv['remaining_amount']) : remaining;
      if (take > 0) {
        result.add({'advance_id': _asInt(adv['id']), 'amount': take});
        remaining -= take;
      }
    }
    return result;
  }

  Future<void> _submit() async {
    if (_selectedStaff == null || _netPayable <= 0 || _saving) return;
    final advanceSettle = double.tryParse(_advanceSettleCtrl.text) ?? 0;
    if (advanceSettle > _outstandingAdvance) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('বকেয়া অগ্রিমের (৳${_outstandingAdvance.toStringAsFixed(0)}) চেয়ে বেশি কর্তন করা যাবে না')));
      return;
    }
    setState(() => _saving = true);

    final res = await ApiService.paySalary(
      staffId: _asInt(_selectedStaff!['id']),
      paidAmount: _netPayable,
      paymentDate: DateTime.now().toIso8601String().split('T')[0],
      salaryMonth: _selectedMonth,
      paymentMethod: _paymentMethod,
      advanceDeductions: advanceSettle > 0 ? _distributeAdvanceSettlement(advanceSettle) : null,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['status'] == true) {
      _resetForm();
      await widget.onPaid();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'বেতন প্রদান ব্যর্থ হয়েছে')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            decoration: _fieldDecoration('স্টাফ বেছে নিন'),
            value: _selectedStaff,
            items: widget.staffs.map((s) => DropdownMenuItem(value: s, child: Text((s['staff_name'] ?? '').toString()))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedStaff = val;
                _basicCtrl.text = (_asDouble(val?['monthly_salary'])).toStringAsFixed(0);
                _advanceSettleCtrl.text = '0';
              });
            },
          ),
          if (_selectedStaff != null && _outstandingAdvance > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: _C.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('এই স্টাফের বকেয়া অগ্রিম: ৳${_outstandingAdvance.toStringAsFixed(0)}', style: const TextStyle(color: _C.danger, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  decoration: _fieldDecoration('বেতনের মাস'),
                  value: _selectedMonthNum,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(value: m, child: Text(_banglaMonths[m - 1])))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMonthNum = val ?? _selectedMonthNum),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  decoration: _fieldDecoration('বছর'),
                  value: _selectedYear,
                  items: List.generate(6, (i) => DateTime.now().year - 2 + i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedYear = val ?? _selectedYear),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _basicCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('মূল বেতন'), onChanged: (_) => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _bonusCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('বোনাস'), onChanged: (_) => setState(() {}))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _deductCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('অন্যান্য কর্তন'), onChanged: (_) => setState(() {})),
          if (_selectedStaff != null && _outstandingAdvance > 0) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _advanceSettleCtrl,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration('অগ্রিম থেকে কর্তন (সর্বোচ্চ ৳${_outstandingAdvance.toStringAsFixed(0)})', icon: Icons.request_quote_outlined),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _C.goldLight, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('সর্বমোট প্রদানযোগ্য নিট বেতন:', style: _subheading),
                Text('৳${_netPayable.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('বেতন কনফার্ম করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- অগ্রিম (Advance) ট্যাব — এন্ট্রি ফর্ম + তালিকা ---
class _AdvanceTabBody extends StatefulWidget {
  final List<Map<String, dynamic>> staffs;
  final List<Map<String, dynamic>> advances;
  final Future<void> Function() onSaved;

  const _AdvanceTabBody({required this.staffs, required this.advances, required this.onSaved});

  @override
  State<_AdvanceTabBody> createState() => _AdvanceTabBodyState();
}

class _AdvanceTabBodyState extends State<_AdvanceTabBody> {
  Map<String, dynamic>? _selectedStaff;
  final TextEditingController _amountCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (_selectedStaff == null || amount <= 0 || _saving) return;
    setState(() => _saving = true);

    final res = await ApiService.giveAdvance(
      staffId: _asInt(_selectedStaff!['id']),
      advanceAmount: amount,
      advanceDate: DateTime.now().toIso8601String().split('T')[0],
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['status'] == true) {
      setState(() {
        _amountCtrl.clear();
        _selectedStaff = null;
        _paymentMethod = 'cash';
      });
      await widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'অগ্রিম এন্ট্রি ব্যর্থ হয়েছে')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('অগ্রিম / ধার প্রদান এন্ট্রি', style: _heading),
          const SizedBox(height: 12),
          DropdownButtonFormField<Map<String, dynamic>>(
            decoration: _fieldDecoration('স্টাফ সিলেক্ট করুন'),
            value: _selectedStaff,
            items: widget.staffs.map((s) => DropdownMenuItem(value: s, child: Text((s['staff_name'] ?? '').toString()))).toList(),
            onChanged: (val) => setState(() => _selectedStaff = val),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('টাকার পরিমাণ'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: _fieldDecoration('পরিশোধের মাধ্যম'),
            value: _paymentMethod,
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('ক্যাশ')),
              DropdownMenuItem(value: 'bank', child: Text('ব্যাংক')),
              DropdownMenuItem(value: 'bkash', child: Text('বিকাশ')),
              DropdownMenuItem(value: 'nagad', child: Text('নগদ')),
            ],
            onChanged: (val) => setState(() => _paymentMethod = val ?? 'cash'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.gold, padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('অগ্রিম টাকা সেভ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('অগ্রিম প্রদানের তালিকা', style: _subheading),
          const SizedBox(height: 10),
          Expanded(
            child: widget.advances.isEmpty
                ? const Center(child: Text('কোনো অগ্রিম লেনদেন নেই', style: _caption))
                : ListView.builder(
              itemCount: widget.advances.length,
              itemBuilder: (context, i) {
                final adv = widget.advances[i];
                final remaining = _asDouble(adv['remaining_amount']);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.border)),
                  child: ListTile(
                    title: Text((adv['staff_name'] ?? '').toString(), style: _subheading),
                    subtitle: Text(
                      '${adv['advance_date'] ?? ''} • মোট ৳${_asDouble(adv['advance_amount']).toStringAsFixed(0)}'
                          '${remaining > 0 ? ' • বকেয়া ৳${remaining.toStringAsFixed(0)}' : ' • সম্পূর্ণ সমন্বয় হয়েছে'}',
                      style: _caption,
                    ),
                    trailing: Text(
                      '৳${remaining.toStringAsFixed(0)}',
                      style: TextStyle(color: remaining > 0 ? _C.danger : _C.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// --- মাসিক স্ট্যাটাস ট্যাব — প্রতিটা স্টাফের কোন মাস পরিশোধিত/বকেয়া তা দেখায় ---
class _MonthlyStatusTab extends StatefulWidget {
  final List<Map<String, dynamic>> staffs;
  const _MonthlyStatusTab({required this.staffs});

  @override
  State<_MonthlyStatusTab> createState() => _MonthlyStatusTabState();
}

class _MonthlyStatusTabState extends State<_MonthlyStatusTab> {
  bool _loading = true;
  List<dynamic> _statusData = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getSalaryStatus();
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

  // মাস লেবেল যেমন '2026-09' -> 'সেপ্টেম্বর 2026'
  String _monthLabel(String ym) {
    const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final y = parts[0];
    final m = int.tryParse(parts[1]) ?? 1;
    return '${months[m - 1]} $y';
  }

  void _openPayForMonth(Map<String, dynamic> staffRow, Map<String, dynamic> monthRow) {
    final staffId = _asInt(staffRow['staff_id']);
    final staffName = (staffRow['staff_name'] ?? '').toString();
    final monthlySalary = _asDouble(staffRow['monthly_salary']);
    final due = _asDouble(monthRow['due_amount']);
    final salaryMonth = (monthRow['month'] ?? '').toString(); // YYYY-MM-01
    final amountCtrl = TextEditingController(text: (due > 0 ? due : monthlySalary).toStringAsFixed(0));
    String paymentMethod = 'cash';
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$staffName — ${_monthLabel(monthRow['month_label'].toString())} বেতন', style: _subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: _fieldDecoration('প্রদানের পরিমাণ')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: _fieldDecoration('পরিশোধের মাধ্যম'),
                value: paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('ক্যাশ')),
                  DropdownMenuItem(value: 'bank', child: Text('ব্যাংক')),
                  DropdownMenuItem(value: 'bkash', child: Text('বিকাশ')),
                  DropdownMenuItem(value: 'nagad', child: Text('নগদ')),
                ],
                onChanged: (val) => setDialogState(() => paymentMethod = val ?? 'cash'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text) ?? 0;
                      if (amount <= 0) return;
                      setDialogState(() => saving = true);
                      final remainingDue = (monthlySalary - amount) > 0 ? (monthlySalary - amount) : 0;
                      final res = await ApiService.paySalary(
                        staffId: staffId,
                        paidAmount: amount,
                        paymentDate: DateTime.now().toIso8601String().split('T')[0],
                        salaryMonth: salaryMonth,
                        paymentMethod: paymentMethod,
                        dueAmount: remainingDue.toDouble(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (res['status'] == true) {
                        await _load();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'বেতন প্রদান ব্যর্থ হয়েছে')));
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('প্রদান করুন', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _C.primary));
    if (_statusData.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('কোনো স্টাফ নেই', style: _caption)));
    }
    return RefreshIndicator(
      color: _C.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _statusData.length,
        itemBuilder: (context, i) {
          final row = Map<String, dynamic>.from(_statusData[i]);
          final months = List<Map<String, dynamic>>.from(row['months'] ?? []);
          final unpaidCount = months.where((m) => m['status'] != 'paid').length;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _C.border)),
            child: ExpansionTile(
              initiallyExpanded: unpaidCount > 0,
              title: Text((row['staff_name'] ?? '').toString(), style: _subheading),
              subtitle: Text(
                unpaidCount == 0 ? 'সব মাসের বেতন পরিশোধিত' : '$unpaidCount মাসের বেতন বকেয়া/আংশিক',
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
    );
  }
}

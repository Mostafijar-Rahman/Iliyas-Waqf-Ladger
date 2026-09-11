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

const _heading = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _C.textPrimary);
const _subheading = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.textPrimary);
const _body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _C.textPrimary, height: 1.5);
const _caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _C.textSecondary);

InputDecoration _fieldDecoration(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  prefixIcon: icon != null ? Icon(icon, size: 20, color: _C.textSecondary) : null,
  filled: true,
  fillColor: _C.surface,
  labelStyle: const TextStyle(color: _C.textSecondary, fontSize: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.danger)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _expenseList = [];
  bool _loading = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _filterCategory;
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cats = await ApiService.getExpenseCategories();
    final list = await ApiService.getExpenses();
    setState(() {
      _categories = cats;
      _expenseList = list;
      _loading = false;
    });
  }

  // রিকার্সিভলি ফিল্টার ক্যাটাগরির অন্তর্ভুক্ত সকল আইডি সংগ্রহ করা
  Set<dynamic> _getAllSubCategoryIds(Map<String, dynamic> category) {
    final Set<dynamic> ids = {category['id']};
    final subs = (category['subcategories'] ?? []) as List<dynamic>;
    for (var sub in subs) {
      if (sub is Map<String, dynamic>) {
        ids.addAll(_getAllSubCategoryIds(sub));
      }
    }
    return ids;
  }

  Set<dynamic> get _filterCategoryIds {
    if (_filterCategory == null) return {};
    return _getAllSubCategoryIds(_filterCategory!);
  }

  List<dynamic> get _filteredList {
    return _expenseList.where((item) {
      if (_searchQuery.isNotEmpty) {
        final desc = (item['description'] ?? '').toString().toLowerCase();
        final voucher = (item['voucher_no'] ?? '').toString().toLowerCase();
        final cat = (item['category_name'] ?? '').toString().toLowerCase();
        if (!desc.contains(_searchQuery) && !voucher.contains(_searchQuery) && !cat.contains(_searchQuery)) {
          return false;
        }
      }
      if (_filterCategory != null && !_filterCategoryIds.contains(item['category_id'])) {
        return false;
      }
      if (_filterDateRange != null) {
        final date = DateTime.tryParse(item['expense_date'] ?? '');
        if (date == null) return false;
        final start = DateTime(_filterDateRange!.start.year, _filterDateRange!.start.month, _filterDateRange!.start.day);
        final end = DateTime(_filterDateRange!.end.year, _filterDateRange!.end.month, _filterDateRange!.end.day, 23, 59, 59);
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters => _searchQuery.isNotEmpty || _filterCategory != null || _filterDateRange != null;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterCategory = null;
      _filterDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.primary));
    }

    final filtered = _filteredList;

    return Container(
      color: _C.background,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ব্যয়ের তালিকা', style: _heading),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      style: _body,
                      decoration: _fieldDecoration('বিবরণ, ভাউচার বা খাত দিয়ে খুঁজুন', icon: Icons.search).copyWith(
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _searchController.clear())
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _filterButton(
                            icon: Icons.category_outlined,
                            label: _filterCategory != null ? _filterCategory!['category_name'] : 'খাত ফিল্টার',
                            active: _filterCategory != null,
                            onTap: _showCategoryFilterSheet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _filterButton(
                            icon: Icons.date_range_outlined,
                            label: _filterDateRange != null
                                ? '${_fmtDate(_filterDateRange!.start)} - ${_fmtDate(_filterDateRange!.end)}'
                                : 'তারিখ রেঞ্জ',
                            active: _filterDateRange != null,
                            onTap: _pickDateRange,
                          ),
                        ),
                      ],
                    ),
                    if (_hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.filter_alt_off, size: 16, color: _C.danger),
                            label: const Text('ফিল্টার মুছুন', style: TextStyle(color: _C.danger, fontSize: 13)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text(
                    _hasActiveFilters ? 'ফিল্টার অনুযায়ী কিছু পাওয়া যায়নি' : 'এখনো কোনো ব্যয় যোগ করা হয়নি',
                    style: _caption,
                  ),
                )
                    : RefreshIndicator(
                  color: _C.primary,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _expenseListTile(filtered[index]),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              backgroundColor: _C.primary,
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('নতুন ব্যয়', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _filterButton({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? _C.goldLight : _C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _C.gold : _C.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? _C.gold : _C.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: _caption.copyWith(color: active ? _C.gold : _C.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*void _showCategoryFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('খাত অনুযায়ী ফিল্টার', style: _subheading),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.clear_all, color: _C.textSecondary),
                        title: const Text('সব খাত', style: _body),
                        onTap: () {
                          setState(() => _filterCategory = null);
                          Navigator.pop(context);
                        },
                      ),
                      ..._categories.map((cat) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.folder_outlined, color: _C.gold),
                        title: Text(cat['category_name'] ?? '', style: _body),
                        onTap: () {
                          setState(() => _filterCategory = cat);
                          Navigator.pop(context);
                        },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }*/
  void _showCategoryFilterSheet() {
    Map<String, dynamic>? tempMainCat;
    Map<String, dynamic>? tempSubCat;
    Map<String, dynamic>? tempChildCat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final List<dynamic> subCats = (tempMainCat != null && tempMainCat!['subcategories'] != null)
                ? tempMainCat!['subcategories']
                : [];

            final List<dynamic> childCats = (tempSubCat != null && tempSubCat!['subcategories'] != null)
                ? tempSubCat!['subcategories']
                : [];

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('খাত অনুযায়ী ফিল্টার করুন', style: _subheading),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- ১. প্রধান খাত ---
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: _fieldDecoration('প্রধান খাত (Main Category)'),
                      style: _body,
                      dropdownColor: _C.surface,
                      isExpanded: true,
                      value: tempMainCat,
                      items: _categories.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                        final cat = c as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat['category_name'] ?? '', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          tempMainCat = val;
                          tempSubCat = null;
                          tempChildCat = null;
                        });
                      },
                    ),

                    // --- ২. সাব-ক্যাটাগরি ---
                    if (subCats.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: _fieldDecoration('সাব-ক্যাটাগরি (Subcategory)'),
                        style: _body,
                        dropdownColor: _C.surface,
                        isExpanded: true,
                        value: tempSubCat,
                        items: subCats.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                          final cat = c as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat['category_name'] ?? '', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            tempSubCat = val;
                            tempChildCat = null;
                          });
                        },
                      ),
                    ],

                    // --- ৩. উপ-সাব-ক্যাটাগরি ---
                    if (childCats.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: _fieldDecoration('উপ-সাব-ক্যাটাগরি (Child Subcategory)'),
                        style: _body,
                        dropdownColor: _C.surface,
                        isExpanded: true,
                        value: tempChildCat,
                        items: childCats.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                          final cat = c as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat['category_name'] ?? '', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() => tempChildCat = val);
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    // --- ফিল্টার প্রয়োগের বাটন ---
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setState(() => _filterCategory = null);
                              Navigator.pop(context);
                            },
                            child: const Text('সব খাত দেখুন', style: TextStyle(color: _C.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final selected = tempChildCat ?? tempSubCat ?? tempMainCat;
                              setState(() => _filterCategory = selected);
                              Navigator.pop(context);
                            },
                            child: const Text('ফিল্টার করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _filterDateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _C.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _filterDateRange = picked);
  }

  Widget _expenseListTile(dynamic item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showEditDialog(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: _C.danger.withOpacity(0.1), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_upward, size: 18, color: _C.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['amount']} টাকা', style: _subheading),
                  const SizedBox(height: 2),
                  Text(
                    '${item['category_name'] ?? ''} • ${item['expense_date']}${(item['description'] ?? '').toString().isNotEmpty ? ' • ${item['description']}' : ''}',
                    style: _caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item['voucher_no'] ?? '-', style: _caption.copyWith(color: _C.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Icon(Icons.edit_outlined, size: 16, color: _C.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _ExpenseAddForm(categories: _categories, onSaved: _loadData),
        ),
      ),
    );
  }

  void _showEditDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _ExpenseAddForm(categories: _categories, onSaved: _loadData, existingItem: item),
        ),
      ),
    );
  }
}

class _ExpenseAddForm extends StatefulWidget {
  final List<dynamic> categories;
  final VoidCallback onSaved;
  final dynamic existingItem;

  const _ExpenseAddForm({required this.categories, required this.onSaved, this.existingItem});

  bool get isEditMode => existingItem != null;

  @override
  State<_ExpenseAddForm> createState() => _ExpenseAddFormState();
}

class _ExpenseAddFormState extends State<_ExpenseAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  // ধাপে ধাপে সিলেক্ট করার জন্য ৩টি ভ্যারিয়েবল
  Map<String, dynamic>? _selectedMainCategory;
  Map<String, dynamic>? _selectedSubCategory;
  Map<String, dynamic>? _selectedChildCategory;

  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      final item = widget.existingItem as Map;
      _amountController.text = '${item['amount'] ?? ''}';
      _descController.text = (item['description'] ?? '').toString();
      _paymentMethod = (item['payment_method'] ?? 'cash').toString();
      final parsedDate = DateTime.tryParse((item['expense_date'] ?? '').toString());
      if (parsedDate != null) _selectedDate = parsedDate;

      final path = _findCategoryPath(widget.categories, item['category_id']);
      if (path.isNotEmpty) {
        _selectedMainCategory = path.length > 0 ? path[0] : null;
        _selectedSubCategory = path.length > 1 ? path[1] : null;
        _selectedChildCategory = path.length > 2 ? path[2] : null;
      }
    }
  }

  List<Map<String, dynamic>> _findCategoryPath(List<dynamic> categories, dynamic targetId) {
    for (var c in categories) {
      final cat = c as Map<String, dynamic>;
      if (cat['id'] == targetId) return [cat];
      final subs = (cat['subcategories'] ?? []) as List<dynamic>;
      if (subs.isNotEmpty) {
        final subPath = _findCategoryPath(subs, targetId);
        if (subPath.isNotEmpty) return [cat, ...subPath];
      }
    }
    return [];
  }

  // বর্তমান সিলেকশন থেকে চূড়ান্ত ক্যাটাগরি আইডি বের করা (ডিভাইস ডিপেপেকট সাব/চাইল্ড সিলেক্ট করা থাকলে সেটাকে নিবে)
  Map<String, dynamic>? get _finalSelectedCategory {
    return _selectedChildCategory ?? _selectedSubCategory ?? _selectedMainCategory;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_finalSelectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('একটি খাত সিলেক্ট করুন')));
      return;
    }

    setState(() => _submitting = true);

    final categoryId = _finalSelectedCategory!['id'];
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    bool success;
    if (widget.isEditMode) {
      success = await ApiService.updateExpense({
        'id': (widget.existingItem as Map)['id'],
        'category_id': categoryId,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'expense_date': dateStr,
        'description': _descController.text,
        'payment_method': _paymentMethod,
      });
    } else {
      success = await ApiService.createExpense({
        'category_id': categoryId,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'expense_date': dateStr,
        'description': _descController.text,
        'payment_method': _paymentMethod,
      });
    }

    setState(() => _submitting = false);

    if (success) {
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _C.primary,
            content: Text(
              widget.isEditMode ? 'ব্যয় সফলভাবে আপডেট হয়েছে' : 'ব্যয় সফলভাবে সেভ হয়েছে',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: _C.danger, content: Text('সেভ করতে সমস্যা হয়েছে, আবার চেষ্টা করুন', style: TextStyle(color: Colors.white))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ২য় লেভেলের লিস্ট
    final List<dynamic> subCategories = (_selectedMainCategory != null && _selectedMainCategory!['subcategories'] != null)
        ? _selectedMainCategory!['subcategories']
        : [];

    // ৩য় লেভেলের লিস্ট
    final List<dynamic> childCategories = (_selectedSubCategory != null && _selectedSubCategory!['subcategories'] != null)
        ? _selectedSubCategory!['subcategories']
        : [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.isEditMode ? 'ব্যয় এন্ট্রি এডিট করুন' : 'নতুন ব্যয় এন্ট্রি', style: _heading),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),

              // --- ১. প্রধান খাত (Main Category Dropdown) ---
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: _fieldDecoration('প্রধান খাত (Main Category)'),
                style: _body,
                dropdownColor: _C.surface,
                isExpanded: true,
                value: _selectedMainCategory,
                items: widget.categories.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                  final cat = c as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat['category_name'] ?? '', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMainCategory = val;
                    _selectedSubCategory = null; // রিসেট
                    _selectedChildCategory = null; // রিসেট
                  });
                },
                validator: (val) => val == null ? 'প্রধান খাত সিলেক্ট করুন' : null,
              ),

              // --- ২. সাব-ক্যাটাগরি (Subcategory Dropdown) ---
              if (subCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: _fieldDecoration('সাব-ক্যাটাগরি (Subcategory)'),
                  style: _body,
                  dropdownColor: _C.surface,
                  isExpanded: true,
                  value: _selectedSubCategory,
                  items: subCategories.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                    final cat = c as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat['category_name'] ?? '', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubCategory = val;
                      _selectedChildCategory = null; // রিসেট
                    });
                  },
                ),
              ],

              // --- ৩. চাইল্ড সাব-ক্যাটাগরি (Child Subcategory Dropdown) ---
              if (childCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: _fieldDecoration('উপ-সাব-ক্যাটাগরি (Child Subcategory)'),
                  style: _body,
                  dropdownColor: _C.surface,
                  isExpanded: true,
                  value: _selectedChildCategory,
                  items: childCategories.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                    final cat = c as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat['category_name'] ?? '', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedChildCategory = val);
                  },
                ),
              ],

              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                style: _body,
                decoration: _fieldDecoration('টাকার পরিমাণ'),
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.isEmpty) ? 'টাকার পরিমাণ দিন' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                style: _body,
                decoration: _fieldDecoration('বিবরণ'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('কোন মাধ্যমে পরিশোধ', style: _caption)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _paymentChip('cash', 'ক্যাশ', Icons.payments_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _paymentChip('bank', 'ব্যাংক', Icons.account_balance_outlined)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _paymentChip('bkash', 'বিকাশ', Icons.phone_android_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _paymentChip('nagad', 'নগদ', Icons.phone_android_outlined)),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.border)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: _C.textSecondary),
                      const SizedBox(width: 10),
                      Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}', style: _body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : Text(widget.isEditMode ? 'পরিবর্তন সংরক্ষণ করুন' : 'ব্যয় সেভ করুন', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _C.goldLight : _C.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _C.gold : _C.border, width: selected ? 1.4 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? _C.gold : _C.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: (selected ? _subheading : _body).copyWith(color: selected ? _C.gold : _C.textSecondary)),
          ],
        ),
      ),
    );
  }
}
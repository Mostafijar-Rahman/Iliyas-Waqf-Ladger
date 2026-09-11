import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'income_source_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _incomeCategories = [];
  List<dynamic> _expenseCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final inc = await ApiService.getIncomeCategories();
    final exp = await ApiService.getExpenseCategories();
    setState(() {
      _incomeCategories = inc;
      _expenseCategories = exp;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(text: 'আয়ের খাত'),
            Tab(text: 'ব্যয়ের খাত'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(_incomeCategories, isIncome: true),
              _buildCategoryList(_expenseCategories, isIncome: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<dynamic> categories, {required bool isIncome}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(isIncome: isIncome, parentId: null, parentName: null),
              icon: const Icon(Icons.add),
              label: const Text('নতুন ক্যাটাগরি'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text('কোনো ক্যাটাগরি পাওয়া যায়নি।'))
                : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _buildCategoryNode(cat, isIncome: isIncome, depth: 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  // যেকোনো গভীরতার (unlimited nesting) ক্যাটাগরি ট্রি রিকার্সিভভাবে দেখানোর জন্য।
  // প্রতিটা লেভেলেই "সাবক্যাটাগরি যোগ করুন" বাটন থাকবে, তাই সাবক্যাটাগরির আন্ডারেও
  // আবার সাবক্যাটাগরি অ্যাড করা যাবে - কোনো লেভেল-সীমা নেই।
  Widget _buildCategoryNode(dynamic cat, {required bool isIncome, required int depth}) {
    final subs = (cat['subcategories'] ?? []) as List<dynamic>;
    final indent = depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: depth == 0 ? null : Colors.teal.withOpacity(0.04),
        child: ExpansionTile(
          leading: depth == 0
              ? const Icon(Icons.folder, color: Colors.teal)
              : const Icon(Icons.subdirectory_arrow_right, size: 18),
          title: Text(
            cat['category_name'] ?? '',
            style: TextStyle(fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500),
          ),
          subtitle: Text('${subs.length} টি সাবক্যাটাগরি'),
          /*trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
            tooltip: 'এর আন্ডারে সাবক্যাটাগরি যোগ করুন',
            onPressed: () => _showAddDialog(
              isIncome: isIncome,
              parentId: cat['id'],
              parentName: cat['category_name'],
            ),
          ),*/
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
            tooltip: 'এর আন্ডারে সাবক্যাটাগরি যোগ করুন',
              onPressed: () {
                _showAddDialog(
                  isIncome: isIncome,
                  parentId: int.tryParse(cat['id'].toString()),
                  parentName: cat['category_name'],
                );
              },
          ),
          children: [
            // শুধু আয়ের ক্যাটাগরিতে "নির্ধারিত মাসিক টার্গেট + আদায়-বকেয়া" ট্র্যাকিং টগল করা যাবে।
            // যেমন: দোকান ভাড়া, ব্যাংক ভাড়া — যেখানে প্রতি মাসে কত পাওয়ার কথা তা আগে থেকেই জানা থাকে।
            // দান বাক্সের মতো ক্যাটাগরিতে এটা বন্ধ রাখাই ভালো, কারণ সেখানে কোনো নির্ধারিত টার্গেট নেই।
            if (isIncome)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
                child: Row(
                  children: [
                    Switch(
                      value: (cat['has_due_tracking'].toString() == '1' || cat['has_due_tracking'] == true),
                      activeColor: Colors.teal,
                      onChanged: (val) async {
                        final res = await ApiService.toggleCategoryDueTracking(
                          categoryId: int.parse(cat['id'].toString()),
                          hasDueTracking: val,
                        );
                        if (mounted) {
                          if (res['status'] == true) {
                            _loadAll();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message']?.toString() ?? 'সমস্যা হয়েছে')),
                            );
                          }
                        }
                      },
                    ),
                    const Expanded(child: Text('আদায়-বকেয়া ট্র্যাকিং (নির্ধারিত মাসিক টার্গেট থাকলে চালু করুন)', style: TextStyle(fontSize: 12))),
                    if (cat['has_due_tracking'].toString() == '1' || cat['has_due_tracking'] == true)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncomeSourceScreen(
                                categoryId: int.parse(cat['id'].toString()),
                                categoryName: cat['category_name']?.toString() ?? '',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long, size: 18, color: Colors.teal),
                        label: const Text('সোর্স ও বকেয়া', style: TextStyle(color: Colors.teal)),
                      ),
                  ],
                ),
              ),
            ...(subs.isEmpty
                ? [const Padding(padding: EdgeInsets.all(12), child: Text('কোনো সাবক্যাটাগরি নেই।'))]
                : subs.map<Widget>((sub) => _buildCategoryNode(sub, isIncome: isIncome, depth: depth + 1)).toList()),
          ],
        ),
      ),
    );
  }

  void _showAddDialog({required bool isIncome, int? parentId, String? parentName}) {
    final controller = TextEditingController();
    final isSubcategory = parentId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSubcategory ? '"$parentName" এর সাবক্যাটাগরি যোগ করুন' : 'নতুন ${isIncome ? "আয়ের" : "ব্যয়ের"} ক্যাটাগরি'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: isSubcategory ? 'সাবক্যাটাগরির নাম' : 'ক্যাটাগরির নাম'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final success = isIncome
                  ? await ApiService.createIncomeCategory(name, parentId: parentId)
                  : await ApiService.createExpenseCategory(name, parentId: parentId);

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _loadAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isSubcategory ? 'সাবক্যাটাগরি যোগ হয়েছে!' : 'ক্যাটাগরি যোগ হয়েছে!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('কোনো একটা সমস্যা হয়েছে, আবার চেষ্টা করুন।')),
                  );
                }
              }
            },
            child: const Text('সেভ করুন'),
          ),
        ],
      ),
    );
  }
}
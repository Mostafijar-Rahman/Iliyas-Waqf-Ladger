import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getLoans();
    if (!mounted) return;
    setState(() {
      _loans = data;
      _isLoading = false;
    });
  }

  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('করজে হাসানা ও ঋণ ব্যবস্থাপনা',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddLoanDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('নতুন ঋণ এন্ট্রি'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_loans.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('এখনো কোনো ঋণ এন্ট্রি করা হয়নি।', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
            // রেসপন্সিভ ও ফুল-উইডথ টেবিল
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
                            DataColumn(label: Text('আইডি', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ঋণদাতার নাম', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('তারিখ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('মোট ঋণ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('পরিশোধিত', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('অবশিষ্ট (বাকি)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('অবস্থা', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('একশন', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _loans.map((loan) {
                            final total = _toDouble(loan['loan_amount']);
                            final due = _toDouble(loan['remaining_amount']);
                            final paid = total - due;
                            final isPaidOff = due <= 0;

                            return DataRow(cells: [
                              DataCell(Text('LN-${loan['id']}')),
                              DataCell(Text(loan['lender_name']?.toString() ?? '')),
                              DataCell(Text(loan['loan_date']?.toString() ?? '')),
                              DataCell(Text('৳ ${total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('৳ ${paid.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              DataCell(Text('৳ ${due.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                              DataCell(Chip(
                                label: Text(isPaidOff ? 'পরিশোধিত' : 'চলমান',
                                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: isPaidOff ? Colors.green : Colors.orange,
                              )),
                              DataCell(
                                isPaidOff
                                    ? const SizedBox.shrink()
                                    : TextButton(
                                  onPressed: () => _showPayLoanDialog(context, loan, due),
                                  child: const Text('পরিশোধ করুন'),
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
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context) {
    final lenderCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String paymentMethod = 'cash';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('নতুন ঋণ এন্ট্রি করুন (ঋণ গ্রহণ)'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: lenderCtrl,
                      decoration: const InputDecoration(labelText: 'ঋণদাতার নাম'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'মোট টাকার পরিমাণ (৳)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('ক্যাশ')),
                        DropdownMenuItem(value: 'bank', child: Text('ব্যাংক')),
                        DropdownMenuItem(value: 'bkash', child: Text('বিকাশ')),
                        DropdownMenuItem(value: 'nagad', child: Text('নগদ')),
                      ],
                      onChanged: (val) => setDialogState(() => paymentMethod = val ?? 'cash'),
                      decoration: const InputDecoration(labelText: 'কোথায় টাকা জমা হবে'),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          'তারিখ: ${selectedDate.toIso8601String().split('T')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'বিবরণ (ঐচ্ছিক)'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                onPressed: isSaving
                    ? null
                    : () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (lenderCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('নাম ও সঠিক টাকার পরিমাণ দিন।')),
                    );
                    return;
                  }
                  setDialogState(() => isSaving = true);
                  final res = await ApiService.createLoan(
                    lenderName: lenderCtrl.text.trim(),
                    loanAmount: amount,
                    loanDate: selectedDate.toIso8601String().split('T')[0],
                    paymentMethod: paymentMethod,
                    description: descCtrl.text.trim(),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message']?.toString() ?? 'সম্পন্ন হয়েছে')),
                  );
                  if (res['status'] == true) {
                    _loadLoans();
                  }
                },
                child: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('সংরক্ষণ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPayLoanDialog(BuildContext context, dynamic loan, double dueAmount) {
    final amountCtrl = TextEditingController(text: dueAmount.toStringAsFixed(0));
    DateTime selectedDate = DateTime.now();
    String paymentMethod = 'cash';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('ঋণ পরিশোধ — ${loan['lender_name']}'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('বর্তমান বাকি: ৳ ${dueAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'পরিশোধের পরিমাণ (৳)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('ক্যাশ')),
                      DropdownMenuItem(value: 'bank', child: Text('ব্যাংক')),
                      DropdownMenuItem(value: 'bkash', child: Text('বিকাশ')),
                      DropdownMenuItem(value: 'nagad', child: Text('নগদ')),
                    ],
                    onChanged: (val) => setDialogState(() => paymentMethod = val ?? 'cash'),
                    decoration: const InputDecoration(labelText: 'কোথা থেকে পরিশোধ হবে'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('তারিখ: ${selectedDate.toIso8601String().split('T')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                onPressed: isSaving
                    ? null
                    : () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('সঠিক টাকার পরিমাণ দিন।')),
                    );
                    return;
                  }
                  if (amount > dueAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('বাকির চেয়ে বেশি টাকা দেওয়া যাবে না।')),
                    );
                    return;
                  }
                  setDialogState(() => isSaving = true);
                  final res = await ApiService.payLoanInstallment(
                    loanId: int.parse(loan['id'].toString()),
                    paymentAmount: amount,
                    paymentDate: selectedDate.toIso8601String().split('T')[0],
                    paymentMethod: paymentMethod,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message']?.toString() ?? 'সম্পন্ন হয়েছে')),
                  );
                  if (res['status'] == true) {
                    _loadLoans();
                  }
                },
                child: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('জমা দিন'),
              ),
            ],
          );
        },
      ),
    );
  }
}
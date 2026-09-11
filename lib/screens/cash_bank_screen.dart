import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CashBankScreen extends StatefulWidget {
  const CashBankScreen({super.key});

  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> {
  bool _loading = true;
  Map<String, dynamic> _balances = {'cash': 0, 'bank': 0, 'bkash': 0, 'nagad': 0};
  List<dynamic> _ledger = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final balances = await ApiService.getCashBankSummary();
    final ledger = await ApiService.getCashBankLedger();
    setState(() {
      _balances = balances;
      _ledger = ledger;
      _loading = false;
    });
  }

  double _num(dynamic v) => double.tryParse(v.toString()) ?? 0;

  String _money(dynamic v) {
    final n = _num(v);
    final isNegative = n < 0;
    final formatted = n.abs().toStringAsFixed(0);
    // হাজার সেপারেটর যুক্ত করা (সাধারণ কমা, বাংলা লাখ-কোটি স্টাইল ছাড়া সরল রাখা হলো)
    final buf = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      final posFromEnd = formatted.length - i;
      buf.write(formatted[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return '${isNegative ? '-' : ''}৳ $buf';
  }

  // cash_bank_ledger.type থেকে মেথড ও ইন/আউট বের করা
  Map<String, dynamic> _parseType(String type) {
    final isIn = type.endsWith('_in') || type == 'bank_deposit';
    String method;
    if (type.startsWith('cash')) {
      method = 'ক্যাশ';
    } else if (type.startsWith('bank')) {
      method = 'ব্যাংক';
    } else if (type.startsWith('bkash')) {
      method = 'বিকাশ';
    } else if (type.startsWith('nagad')) {
      method = 'নগদ';
    } else {
      method = type;
    }
    return {'method': method, 'isCredit': isIn};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ক্যাশ ও ব্যাংক ব্যালেন্স হিসেব', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ৪টা ব্যালেন্স কার্ড: ক্যাশ, ব্যাংক, বিকাশ, নগদ
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 700;
                final cards = [
                  _buildBalanceCard('হাতে নগদ (Cash)', _money(_balances['cash']), Icons.payments, Colors.teal),
                  _buildBalanceCard('ব্যাংক (Bank)', _money(_balances['bank']), Icons.account_balance, Colors.blue),
                  _buildBalanceCard('বিকাশ (bKash)', _money(_balances['bkash']), Icons.phone_android, Colors.pink),
                  _buildBalanceCard('নগদ (Nagad)', _money(_balances['nagad']), Icons.smartphone, Colors.orange),
                ];
                if (isDesktop) {
                  return Row(
                    children: cards
                        .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 15), child: c)))
                        .toList(),
                  );
                }
                return Column(
                  children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 15), child: c)).toList(),
                );
              },
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('সাম্প্রতিক ক্যাশ ও ব্যাংক লেজার হিস্ট্রি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'রিফ্রেশ করুন',
                ),
              ],
            ),
            const SizedBox(height: 15),

            _ledger.isEmpty
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Center(
                child: Text('কোনো লেনদেন পাওয়া যায়নি', style: TextStyle(color: Colors.grey)),
              ),
            )
                : Container(
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
                          DataColumn(label: Text('তারিখ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('বিবরণ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('মেথড', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('প্রকার', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('পরিমাণ', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _ledger.map((tx) {
                          final parsed = _parseType((tx['type'] ?? '').toString());
                          final isCredit = parsed['isCredit'] as bool;
                          final desc = (tx['description'] ?? '').toString();
                          return DataRow(cells: [
                            DataCell(Text((tx['ledger_date'] ?? '').toString())),
                            DataCell(Text(desc.isEmpty ? '—' : desc)),
                            DataCell(Text(parsed['method'] as String)),
                            DataCell(Chip(
                              label: Text(isCredit ? 'জমা (In)' : 'খরচ (Out)', style: const TextStyle(fontSize: 11, color: Colors.white)),
                              backgroundColor: isCredit ? Colors.green : Colors.redAccent,
                            )),
                            DataCell(Text(
                              _money(tx['amount']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCredit ? Colors.green : Colors.red,
                              ),
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

  Widget _buildBalanceCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}
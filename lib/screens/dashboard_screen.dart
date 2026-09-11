import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalIncome = 0;
  double totalExpense = 0;
  // fix: এটা আগে (আয় - ব্যয়) দিয়ে হিসাব হতো এবং "ক্যাশ ব্যালেন্স" নামে
  // দেখানো হতো — কিন্তু ওটা আসলে নিট ব্যালেন্স (হিসাবি লাভ/লোকসান), হাতে
  // থাকা প্রকৃত ক্যাশ না। এখন থেকে cash/bank/bkash/nagad — প্রকৃত ব্যালেন্স
  // ApiService.getCashBankSummary() থেকে সরাসরি আনা হচ্ছে (cash_bank_screen.dart
  // যেভাবে আনে ঠিক সেভাবেই), যাতে দুই জায়গায় দুই রকম সংখ্যা না দেখায়।
  double netBalance = 0;
  double cashBalance = 0;
  double bankBalance = 0;
  double bkashBalance = 0;
  double nagadBalance = 0;

  // চার্টের জন্য: খাতভিত্তিক আয়/ব্যয়ের বিভাজন
  Map<String, double> incomeByCategory = {};
  Map<String, double> expenseByCategory = {};

  // চার্টের জন্য: ঋণ পরিশোধের অবস্থা
  double totalLoanTaken = 0;
  double totalLoanRemaining = 0;
  double get totalLoanPaid => (totalLoanTaken - totalLoanRemaining).clamp(0, double.infinity);

  bool isLoading = true;

  double get totalAssets => cashBalance + bankBalance + bkashBalance + nagadBalance;

  static const List<Color> _chartPalette = [
    Colors.teal,
    Colors.orange,
    Colors.deepPurple,
    Colors.blue,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  double _num(dynamic v) => double.tryParse(v.toString()) ?? 0;

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);

    final incomes = await ApiService.getIncomes();
    final expenses = await ApiService.getExpenses();
    final balances = await ApiService.getCashBankSummary();
    final loans = await ApiService.getLoans();

    double incSum = 0;
    final Map<String, double> incByCat = {};
    for (var item in incomes) {
      final amt = _num(item['amount']);
      incSum += amt;
      final cat = (item['category_name'] ?? 'অন্যান্য').toString();
      incByCat[cat] = (incByCat[cat] ?? 0) + amt;
    }

    double expSum = 0;
    final Map<String, double> expByCat = {};
    for (var item in expenses) {
      final amt = _num(item['amount']);
      expSum += amt;
      final cat = (item['category_name'] ?? 'অন্যান্য').toString();
      expByCat[cat] = (expByCat[cat] ?? 0) + amt;
    }

    double loanTaken = 0;
    double loanRemaining = 0;
    for (var item in loans) {
      loanTaken += _num(item['loan_amount']);
      loanRemaining += _num(item['remaining_amount']);
    }

    setState(() {
      totalIncome = incSum;
      totalExpense = expSum;
      netBalance = incSum - expSum;
      cashBalance = _num(balances['cash']);
      bankBalance = _num(balances['bank']);
      bkashBalance = _num(balances['bkash']);
      nagadBalance = _num(balances['nagad']);
      incomeByCategory = incByCat;
      expenseByCategory = expByCat;
      totalLoanTaken = loanTaken;
      totalLoanRemaining = loanRemaining;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ওভারভিউ ড্যাশবোর্ড', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('মোট আয়', '৳ ${totalIncome.toStringAsFixed(2)}', Colors.green, Icons.arrow_downward)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('মোট ব্যয়', '৳ ${totalExpense.toStringAsFixed(2)}', Colors.red, Icons.arrow_upward)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('নিট ব্যালেন্স', '৳ ${netBalance.toStringAsFixed(2)}', Colors.blueGrey, Icons.trending_up)),
                ],
              ),
              const SizedBox(height: 15),
              // fix: "ক্যাশ ব্যালেন্স" কার্ডটা আগে ভুল করে নিট ব্যালেন্স (আয়-ব্যয়) দেখাতো।
              // এখন cash_bank_screen.dart-এর মতোই getCashBankSummary() থেকে আসা প্রকৃত
              // হাতে-নগদ দেখানো হচ্ছে, আর তার পাশে সব মাধ্যম মিলিয়ে প্রকৃত মোট সম্পদ।
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('ক্যাশ ব্যালেন্স (হাতে নগদ)', '৳ ${cashBalance.toStringAsFixed(2)}', Colors.teal, Icons.account_balance_wallet)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('মোট সম্পদ (ক্যাশ+ব্যাংক+বিকাশ+নগদ)', '৳ ${totalAssets.toStringAsFixed(2)}', Colors.deepPurple, Icons.account_balance)),
                ],
              ),
              const SizedBox(height: 25),
              const Text('চার্ট এনালাইসিস', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 950;
                  final charts = [
                    // fix: শুধু আয়ের চার্টটাই বার চার্টে বদলানো হলো (স্ক্রিনশটে
                    // ইন্ডিকেট করা অংশ) — ব্যয় আর ঋণের চার্ট আগের মতো ডোনাটই থাকলো।
                    _buildIncomeBarCard(
                      title: 'আয়ের খাতভিত্তিক বিভাজন',
                      data: incomeByCategory,
                      emptyText: 'কোনো আয়ের তথ্য নেই',
                    ),
                    _buildPieCard(
                      title: 'ব্যয়ের খাতভিত্তিক বিভাজন',
                      data: expenseByCategory,
                      emptyText: 'কোনো ব্যয়ের তথ্য নেই',
                    ),
                    _buildLoanPieCard(),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: [
                        for (final chart in charts) ...[
                          chart,
                          const SizedBox(height: 15),
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[0]),
                      const SizedBox(width: 15),
                      Expanded(child: charts[1]),
                      const SizedBox(width: 15),
                      Expanded(child: charts[2]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // আয়ের খাতভিত্তিক বিভাজনের জন্য BarChart (fl_chart) — শুধু এই চার্টটাই
  // ডোনাট থেকে বার চার্টে বদলানো হয়েছে, ইউজারের ইন্ডিকেট করা অংশ অনুযায়ী।
  Widget _buildIncomeBarCard({
    required String title,
    required Map<String, double> data,
    required String emptyText,
  }) {
    final total = data.values.fold<double>(0, (a, b) => a + b);

    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, double>> displayEntries = sortedEntries;
    if (sortedEntries.length > 6) {
      final top = sortedEntries.take(5).toList();
      final restSum = sortedEntries.skip(5).fold<double>(0, (a, e) => a + e.value);
      displayEntries = [...top, MapEntry('অন্যান্য', restSum)];
    }

    final maxVal = displayEntries.isEmpty
        ? 0.0
        : displayEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          if (total == 0)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(emptyText, style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else ...[
            SizedBox(
              // fix: বারের উপরে টাকার লেবেলের জন্য একটু বাড়তি উচ্চতা রাখা হলো
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  // fix: লেবেলের জায়গা রাখতে maxY বাড়ানো হলো, নাহলে টাকার
                  // অ্যামাউন্ট চার্টের বাইরে কাটা পড়ে যেত
                  maxY: maxVal * 1.35,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    // fix: এই টুলটিপটাই এখন "সবসময় দৃশ্যমান" লেবেল হিসেবে কাজ করছে
                    // (showingTooltipIndicators-এর কারণে), তাই ব্যাকগ্রাউন্ড স্বচ্ছ করে
                    // শুধু বোল্ড টাকার অ্যামাউন্ট দেখানো হচ্ছে — চ্যাট-বাবল লাগছে না
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = displayEntries[group.x.toInt()];
                        return BarTooltipItem(
                          '৳ ${entry.value.toStringAsFixed(0)}',
                          TextStyle(
                            color: _chartPalette[group.x.toInt() % _chartPalette.length],
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= displayEntries.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(displayEntries.length, (i) {
                    final entry = displayEntries[i];
                    return BarChartGroupData(
                      x: i,
                      // fix: বার সবসময় নিজের টুলটিপ (টাকার অ্যামাউন্ট) দেখাবে,
                      // শুধু ট্যাপ করলে না — এতে প্রতিটা বারের উপরে সরাসরি সংখ্যা দেখা যাবে
                      showingTooltipIndicators: [0],
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: _chartPalette[i % _chartPalette.length],
                          // fix: বার আরেকটু চওড়া করা হলো, কার্ডটা কম ফাঁকা ফাঁকা লাগবে
                          width: 34,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
                swapAnimationDuration: const Duration(milliseconds: 400),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: List.generate(displayEntries.length, (i) {
                final entry = displayEntries[i];
                final percent = (entry.value / total) * 100;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartPalette[i % _chartPalette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${i + 1}. ${entry.key} (৳ ${entry.value.toStringAsFixed(0)}, ${percent.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // ব্যয়ের খাতভিত্তিক বিভাজনের জন্য পাই চার্ট কার্ড (অপরিবর্তিত)
  Widget _buildPieCard({
    required String title,
    required Map<String, double> data,
    required String emptyText,
  }) {
    final total = data.values.fold<double>(0, (a, b) => a + b);

    // ছোট ছোট খাতগুলো "অন্যান্য"-তে মিলিয়ে দেওয়া, যাতে চার্ট এলোমেলো না লাগে
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, double>> displayEntries = sortedEntries;
    if (sortedEntries.length > 6) {
      final top = sortedEntries.take(5).toList();
      final restSum = sortedEntries.skip(5).fold<double>(0, (a, e) => a + e.value);
      displayEntries = [...top, MapEntry('অন্যান্য', restSum)];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (total == 0)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(emptyText, style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: List.generate(displayEntries.length, (i) {
                    final entry = displayEntries[i];
                    final percent = (entry.value / total) * 100;
                    return PieChartSectionData(
                      value: entry.value,
                      color: _chartPalette[i % _chartPalette.length],
                      title: percent >= 6 ? '${percent.toStringAsFixed(0)}%' : '',
                      radius: 55,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: List.generate(displayEntries.length, (i) {
                final entry = displayEntries[i];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartPalette[i % _chartPalette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${entry.key} (৳ ${entry.value.toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // ঋণ পরিশোধিত বনাম বকেয়ার জন্য পাই চার্ট কার্ড (অপরিবর্তিত)
  Widget _buildLoanPieCard() {
    final hasLoan = totalLoanTaken > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ঋণ পরিশোধের অবস্থা', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (!hasLoan)
            SizedBox(
              height: 160,
              child: Center(
                child: Text('কোনো ঋণের তথ্য নেই', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: [
                    PieChartSectionData(
                      value: totalLoanPaid,
                      color: Colors.green,
                      title: totalLoanTaken > 0 ? '${((totalLoanPaid / totalLoanTaken) * 100).toStringAsFixed(0)}%' : '',
                      radius: 55,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: totalLoanRemaining,
                      color: Colors.redAccent,
                      title: totalLoanTaken > 0 ? '${((totalLoanRemaining / totalLoanTaken) * 100).toStringAsFixed(0)}%' : '',
                      radius: 55,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('পরিশোধিত (৳ ${totalLoanPaid.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('বকেয়া (৳ ${totalLoanRemaining.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
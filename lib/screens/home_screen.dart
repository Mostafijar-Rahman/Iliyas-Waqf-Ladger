import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'income_screen.dart';
import 'expense_screen.dart';
import 'cash_bank_screen.dart';
import 'loan_screen.dart';
import 'staff_screen.dart';
import 'partner_screen.dart';
import 'voucher_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- সিস্টেম লক স্ট্যাটাস ---
  bool _isLocked = false;
  String _lockMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLockStatus(); // হোম স্ক্রিন লোড হওয়ার সময় শুধু একবারই চেক হবে
  }

  Future<void> _checkLockStatus() async {
    final result = await ApiService.getSystemStatus();
    final locked = result['is_locked'] == true || result['is_locked'] == 1;
    if (!mounted) return;
    setState(() {
      _isLocked = locked;
      _lockMessage = (result['message'] ?? 'সিস্টেম সাময়িকভাবে বন্ধ রাখা হয়েছে।').toString();
    });
  }

  // ১০টি সম্পূর্ণ কার্যকরী নেভিগেশন মডিউল
  final List<Widget> _pages = const [
    DashboardScreen(),  // ১. ড্যাশবোর্ড
    IncomeScreen(),     // ২. আয়
    ExpenseScreen(),    // ৩. ব্যয়
    CashBankScreen(),   // ৪. ক্যাশ ও ব্যাংক
    LoanScreen(),       // ৫. ঋণ হিসাব
    StaffScreen(),      // ৬. স্টাফ ও বেতন
    PartnerScreen(),    // ৭. অংশীদার ও লাভ বণ্টন
    VoucherScreen(),    // ৮. ভাউচার জেনারেটর
    ReportScreen(),     // ৯. অডিট ও আর্থিক রিপোর্ট
    SettingsScreen(),   // ১০. সিস্টেম লক ও সেটিংস
  ];

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'ড্যাশবোর্ড'},
    {'icon': Icons.add_chart_outlined, 'activeIcon': Icons.add_chart, 'label': 'আয়'},
    {'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag, 'label': 'ব্যয়'},
    {'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet, 'label': 'ক্যাশ ও ব্যাংক'},
    {'icon': Icons.handshake_outlined, 'activeIcon': Icons.handshake, 'label': 'ঋণ হিসাব'},
    {'icon': Icons.people_alt_outlined, 'activeIcon': Icons.people_alt, 'label': 'স্টাফ ও বেতন'},
    {'icon': Icons.groups_outlined, 'activeIcon': Icons.groups, 'label': 'অংশীদার'},
    {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long, 'label': 'ভাউচার'},
    {'icon': Icons.assessment_outlined, 'activeIcon': Icons.assessment, 'label': 'রিপোর্ট'},
    {'icon': Icons.lock_clock_outlined, 'activeIcon': Icons.lock_clock, 'label': 'সিস্টেম লক'},
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return WillPopScope(
      // সিস্টেম লক অবস্থায় ব্যাক বাটনে কিছুই হবে না
      onWillPop: () async => !_isLocked,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text(
                'ওয়াক্‌ফ আল-আওলাদ এস্টেট হিসাবরক্ষণ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            drawer: isMobile
                ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.teal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance, size: 44, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'ওয়াক্‌ফ লেজার সিস্টেম',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(_menuItems.length, (index) {
                    final item = _menuItems[index];
                    return ListTile(
                      leading: Icon(
                        _selectedIndex == index ? item['activeIcon'] : item['icon'],
                        color: _selectedIndex == index ? Colors.teal : Colors.grey[700],
                      ),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.teal : Colors.black87,
                          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedIndex == index,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            )
                : null,
            body: Row(
              children: [
                if (!isMobile)
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 60),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          extended: screenWidth > 1150,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (int index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          backgroundColor: Colors.grey[50],
                          indicatorColor: Colors.teal.shade100,
                          selectedLabelTextStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                          unselectedLabelTextStyle: TextStyle(color: Colors.grey[700]),
                          labelType: screenWidth > 1150 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                          destinations: _menuItems.map((item) {
                            return NavigationRailDestination(
                              icon: Icon(item['icon']),
                              selectedIcon: Icon(item['activeIcon'], color: Colors.teal),
                              label: Text(item['label']),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                if (!isMobile) const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Container(
                    alignment: Alignment.topLeft,
                    color: Colors.grey[100],
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),

          // --- সিস্টেম লক ওভারলে: ডেভেলপার লক করলে পুরো অ্যাপ ঢেকে যাবে ---
          if (_isLocked) _buildLockOverlay(),
        ],
      ),
    );
  }

  // পুরো স্ক্রিন ঢেকে দেওয়া নন-ডিসমিসেবল ওভারলে
  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.92),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(Icons.lock_outline_rounded, size: 38, color: Colors.red.shade700),
                ),
                const SizedBox(height: 20),
                const Text(
                  'সিস্টেম সাময়িকভাবে বন্ধ রাখা হয়েছে',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Text(
                  _lockMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
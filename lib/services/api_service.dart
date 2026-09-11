import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://yourdomain.com/waqf_backend/api/';
  static const int defaultOrgId = 1;

  // ---------------------------------------------------------------------------
  // ১. আয় সংক্রান্ত (Income APIs)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getIncomeCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/income_categories.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Income Categories Fetch Error: $e");
    }
    return [];
  }

  // নতুন: মূল ক্যাটাগরি অথবা সাবক্যাটাগরি (parentId দিলে) তৈরি করে
  static Future<bool> createIncomeCategory(String categoryName, {int? parentId}) async {
    try {
      final body = {
        'organization_id': defaultOrgId,
        'category_name': categoryName,
      };
      if (parentId != null) body['parent_id'] = parentId;

      final response = await http.post(
        Uri.parse('$baseUrl/categories/income_categories.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res['status'] == true;
      }
    } catch (e) {
      print("Create Income Category Error: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getIncomes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/income/list.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Income List Fetch Error: $e");
    }
    return [];
  }

  static Future<bool> createIncome(Map<String, dynamic> data) async {
    try {
      data['organization_id'] = defaultOrgId;
      final response = await http.post(
        Uri.parse('$baseUrl/income/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = json.decode(response.body);
        // ব্যাকএন্ড boolean true রিটার্ন করে, স্ট্রিং 'success' না
        return res['status'] == true;
      }
    } catch (e) {
      print("Create Income Error: $e");
    }
    return false;
  }

  // বিদ্যমান আয় এন্ট্রি এডিট করার জন্য (id আবশ্যক)
  static Future<bool> updateIncome(Map<String, dynamic> data) async {
    try {
      data['organization_id'] = defaultOrgId;
      final response = await http.post(
        Uri.parse('$baseUrl/income/update.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = json.decode(response.body);
        return res['status'] == true;
      }
    } catch (e) {
      print("Update Income Error: $e");
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // ২. ব্যয় সংক্রান্ত (Expense APIs)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getExpenseCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/expense_categories.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Expense Categories Fetch Error: $e");
    }
    return [];
  }

  // নতুন: মূল ক্যাটাগরি অথবা সাবক্যাটাগরি (parentId দিলে) তৈরি করে
  static Future<bool> createExpenseCategory(String categoryName, {int? parentId}) async {
    try {
      final body = {
        'organization_id': defaultOrgId,
        'category_name': categoryName,
      };
      if (parentId != null) body['parent_id'] = parentId;

      final response = await http.post(
        Uri.parse('$baseUrl/categories/expense_categories.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res['status'] == true;
      }
    } catch (e) {
      print("Create Expense Category Error: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expense/list.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Expense List Fetch Error: $e");
    }
    return [];
  }

  static Future<bool> createExpense(Map<String, dynamic> data) async {
    try {
      data['organization_id'] = defaultOrgId;
      final response = await http.post(
        Uri.parse('$baseUrl/expense/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = json.decode(response.body);
        return res['status'] == true;
      }
    } catch (e) {
      print("Create Expense Error: $e");
    }
    return false;
  }

  // বিদ্যমান ব্যয় এন্ট্রি এডিট করার জন্য (id আবশ্যক)
  static Future<bool> updateExpense(Map<String, dynamic> data) async {
    try {
      data['organization_id'] = defaultOrgId;
      final response = await http.post(
        Uri.parse('$baseUrl/expense/update.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = json.decode(response.body);
        return res['status'] == true;
      }
    } catch (e) {
      print("Update Expense Error: $e");
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // ৩. ক্যাশ ও ব্যাংক লেজার (Cash/Bank APIs)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getCashBankLedger() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cash_bank/ledger_list.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Cash/Bank Ledger Fetch Error: $e");
    }
    return [];
  }

  // ক্যাশ, ব্যাংক, বিকাশ, নগদ — চারটার আলাদা আলাদা ব্যালেন্স
  static Future<Map<String, dynamic>> getCashBankSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cash_bank/balance_summary.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          return res['balances'] ?? {};
        }
      }
    } catch (e) {
      print("Cash/Bank Balance Summary Fetch Error: $e");
    }
    return {'cash': 0, 'bank': 0, 'bkash': 0, 'nagad': 0};
  }

  // ---------------------------------------------------------------------------
  // ৪. ঋণ সংক্রান্ত (Loan APIs) — শুধু "গ্রহণ করা ঋণ" (এস্টেট ঋণ নেয়, দেয় না)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getLoans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/loans/list.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Loans List Fetch Error: $e");
    }
    return [];
  }

  // নতুন ঋণ এন্ট্রি (ঋণ গ্রহণ)
  static Future<Map<String, dynamic>> createLoan({
    required String lenderName,
    required double loanAmount,
    required String loanDate,
    String paymentMethod = 'cash',
    String description = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'lender_name': lenderName,
          'loan_amount': loanAmount,
          'loan_date': loanDate,
          'payment_method': paymentMethod,
          'description': description,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Create Loan Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // ঋণ পরিশোধ (কিস্তি বা সম্পূর্ণ)
  static Future<Map<String, dynamic>> payLoanInstallment({
    required int loanId,
    required double paymentAmount,
    required String paymentDate,
    String paymentMethod = 'cash',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans/payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'loan_id': loanId,
          'payment_amount': paymentAmount,
          'payment_date': paymentDate,
          'payment_method': paymentMethod,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Loan Payment Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // ---------------------------------------------------------------------------
  // ৫. রিপোর্ট সংক্রান্ত (Report APIs)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getDailyReport(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/daily.php?organization_id=$defaultOrgId&date=$date'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Daily Report Fetch Error: $e");
    }
    return {};
  }

  // startDate ফরম্যাট: YYYY-MM-DD — সপ্তাহের প্রথম দিন। endDate ব্যাকএন্ড নিজেই স্টার্ট + ৬ দিন হিসাব করে নেয়।
  static Future<Map<String, dynamic>> getWeeklyReport(String startDate) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/weekly.php?organization_id=$defaultOrgId&start_date=$startDate'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Weekly Report Fetch Error: $e");
    }
    return {};
  }

  static Future<Map<String, dynamic>> getMonthlyReport(String month, String year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/monthly.php?organization_id=$defaultOrgId&month=$month&year=$year'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Monthly Report Fetch Error: $e");
    }
    return {};
  }

  static Future<Map<String, dynamic>> getYearlyReport(String year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/yearly.php?organization_id=$defaultOrgId&year=$year'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Yearly Report Fetch Error: $e");
    }
    return {};
  }

  // startDate ও endDate না দিলে সম্পূর্ণ (সব সময়ের) অডিট রিপোর্ট আসবে
  static Future<Map<String, dynamic>> getAuditReport({String? startDate, String? endDate}) async {
    try {
      String url = '$baseUrl/reports/audit.php?organization_id=$defaultOrgId';
      if (startDate != null && endDate != null) {
        url += '&start_date=$startDate&end_date=$endDate';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Audit Report Fetch Error: $e");
    }
    return {};
  }

  // ---------------------------------------------------------------------------
  // ৬. ভাউচার সংক্রান্ত (Voucher APIs)
  // ---------------------------------------------------------------------------
  // voucherType: income/expense/cash/bank/loan_repayment/staff_salary/staff_advance/partner_allowance
  static Future<Map<String, dynamic>> getVoucherList({
    String? voucherType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$baseUrl/vouchers/list.php?organization_id=$defaultOrgId';
      if (voucherType != null && voucherType.isNotEmpty) {
        url += '&voucher_type=$voucherType';
      }
      if (startDate != null && endDate != null) {
        url += '&start_date=$startDate&end_date=$endDate';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Voucher List Fetch Error: $e");
    }
    return {'status': false, 'data': []};
  }

  static Future<Map<String, dynamic>> getVoucherDetails(String voucherNo) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/details.php?voucher_no=$voucherNo'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Voucher Details Fetch Error: $e");
    }
    return {'status': false, 'data': null};
  }

  // ---------------------------------------------------------------------------
  // ৭. সিস্টেম স্ট্যাটাস ও লক (System Security APIs)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system/system_status.php'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("System Status Fetch Error: $e");
    }
    return {'is_locked': 0};
  }

  static Future<bool> toggleSystemLock(bool status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/system/toggle_lock.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_locked': status ? 1 : 0}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Toggle Lock Error: $e");
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // ৭. স্টাফ ও বেতন সংক্রান্ত (Staff & Payroll APIs)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getStaffs({bool includeInactive = false}) async {
    try {
      String url = '$baseUrl/staff/list.php?organization_id=$defaultOrgId';
      if (includeInactive) url += '&include_inactive=1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Staff List Fetch Error: $e");
    }
    return [];
  }

  // active=false দিলে নিষ্ক্রিয় করে (ডিলিট করে না), active=true দিলে আবার সক্রিয় করে
  static Future<Map<String, dynamic>> toggleStaffStatus({
    required int id,
    required bool active,
    String? endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/toggle_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'id': id,
          'active': active,
          'end_date': endDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Toggle Staff Status Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> addStaff({
    required String staffName,
    required double monthlySalary,
    String? designation,
    String? phone,
    String? joinDate, // ফরম্যাট: YYYY-MM-DD, না দিলে ব্যাকএন্ড আজকের তারিখ ধরে নেবে
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/add_staff.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'staff_name': staffName,
          'monthly_salary': monthlySalary,
          'designation': designation ?? '',
          'phone': phone ?? '',
          'join_date': joinDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Add Staff Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> updateStaff({
    required int id,
    required String staffName,
    required double monthlySalary,
    String? designation,
    String? phone,
    String? joinDate, // ফরম্যাট: YYYY-MM-DD, না দিলে আগের join_date-ই থাকবে
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/update_staff.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'id': id,
          'staff_name': staffName,
          'monthly_salary': monthlySalary,
          'designation': designation ?? '',
          'phone': phone ?? '',
          'join_date': joinDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Update Staff Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<List<dynamic>> getSalaryLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/staff/salary_list.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Salary Logs Fetch Error: $e");
    }
    return [];
  }

  // প্রতিটা স্টাফের join_date থেকে বর্তমান মাস পর্যন্ত মাসভিত্তিক Paid/Partial/Unpaid স্ট্যাটাস
  static Future<List<dynamic>> getSalaryStatus({int? staffId}) async {
    try {
      String url = '$baseUrl/staff/salary_status.php?organization_id=$defaultOrgId';
      if (staffId != null) url += '&staff_id=$staffId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Salary Status Fetch Error: $e");
    }
    return [];
  }

  // advanceDeductions: [{"advance_id": 5, "amount": 1000}, ...] — ঐচ্ছিক, অগ্রিম সমন্বয়ের জন্য
  static Future<Map<String, dynamic>> paySalary({
    required int staffId,
    required double paidAmount,
    required String paymentDate,
    required String salaryMonth,
    String paymentMethod = 'cash',
    double dueAmount = 0,
    List<Map<String, dynamic>>? advanceDeductions,
  }) async {
    try {
      final body = {
        'organization_id': defaultOrgId,
        'staff_id': staffId,
        'paid_amount': paidAmount,
        'payment_date': paymentDate,
        'salary_month': salaryMonth,
        'payment_method': paymentMethod,
        'due_amount': dueAmount,
      };
      if (advanceDeductions != null && advanceDeductions.isNotEmpty) {
        body['advance_deductions'] = advanceDeductions;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/staff/pay_salary.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Pay Salary Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> giveAdvance({
    required int staffId,
    required double advanceAmount,
    required String advanceDate,
    String paymentMethod = 'cash',
    String description = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/give_advance.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'staff_id': staffId,
          'advance_amount': advanceAmount,
          'advance_date': advanceDate,
          'payment_method': paymentMethod,
          'description': description,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Give Advance Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // staff_name ও remaining_amount সহ প্রতিটি অগ্রিমের এন্ট্রি রিটার্ন করে
  static Future<List<dynamic>> getAdvances() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/staff/advance_list.php?organization_id=$defaultOrgId'),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Advance List Fetch Error: $e");
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // ৮. অংশীদার ও ভাতা সংক্রান্ত (Partners & Allowance APIs)
  // ---------------------------------------------------------------------------
  // partner_name, monthly_allowance (নির্ধারিত ভাতা), total_paid, total_due, last_payment_date সহ লিস্ট
  static Future<List<dynamic>> getPartners({bool includeInactive = false}) async {
    try {
      String url = '$baseUrl/partners/list.php?organization_id=$defaultOrgId';
      if (includeInactive) url += '&include_inactive=1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Partners List Fetch Error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> togglePartnerStatus({
    required int id,
    required bool active,
    String? endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/toggle_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'id': id,
          'active': active,
          'end_date': endDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Toggle Partner Status Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> addPartner({
    required String partnerName,
    required double monthlyAllowance,
    String? phone,
    String? joinDate, // ফরম্যাট: YYYY-MM-DD, না দিলে ব্যাকএন্ড আজকের তারিখ ধরে নেবে
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/add_partner.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'partner_name': partnerName,
          'monthly_allowance': monthlyAllowance,
          'phone': phone ?? '',
          'join_date': joinDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Add Partner Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> updatePartner({
    required int id,
    required String partnerName,
    required double monthlyAllowance,
    String? phone,
    String? joinDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/update_partner.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'id': id,
          'partner_name': partnerName,
          'monthly_allowance': monthlyAllowance,
          'phone': phone ?? '',
          'join_date': joinDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Update Partner Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // প্রতিটা পার্টনারের join_date থেকে বর্তমান মাস পর্যন্ত মাসভিত্তিক Paid/Partial/Unpaid স্ট্যাটাস
  static Future<List<dynamic>> getAllowanceStatus({int? partnerId}) async {
    try {
      String url = '$baseUrl/partners/allowance_status.php?organization_id=$defaultOrgId';
      if (partnerId != null) url += '&partner_id=$partnerId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Allowance Status Fetch Error: $e");
    }
    return [];
  }

  // allowance_month ফরম্যাট: YYYY-MM-01
  static Future<Map<String, dynamic>> payAllowance({
    required int partnerId,
    required double paidAmount,
    required String paymentDate,
    required String allowanceMonth,
    String paymentMethod = 'cash',
    double dueAmount = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/pay_allowance.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'partner_id': partnerId,
          'paid_amount': paidAmount,
          'payment_date': paymentDate,
          'allowance_month': allowanceMonth,
          'payment_method': paymentMethod,
          'due_amount': dueAmount,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Pay Allowance Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // partnerId না দিলে প্রতিষ্ঠানের সব অংশীদারের ভাতা প্রদানের হিস্ট্রি রিটার্ন করে
  static Future<List<dynamic>> getAllowancePayments({int? partnerId}) async {
    try {
      String url = '$baseUrl/partners/allowance_list.php?organization_id=$defaultOrgId';
      if (partnerId != null) url += '&partner_id=$partnerId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Allowance Payments Fetch Error: $e");
    }
    return [];
  }

  // নির্দিষ্ট মাসের এন্ট্রির (paymentId) বকেয়া আংশিক বা পুরোপুরি পরিশোধ করে
  static Future<Map<String, dynamic>> settleAllowanceDue({
    required int paymentId,
    required double settleAmount,
    required String paymentDate,
    String paymentMethod = 'cash',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/settle_due.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'payment_id': paymentId,
          'settle_amount': settleAmount,
          'payment_date': paymentDate,
          'payment_method': paymentMethod,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Settle Due Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // ---------------------------------------------------------------------------
  // ৯. ইনকাম সোর্স ও আদায়-বকেয়া (Rent/Tenant-type Income Due Tracking APIs)
  // ---------------------------------------------------------------------------
  // একটা ইনকাম ক্যাটাগরিতে (যেমন "দোকান ভাড়া") আদায়-বকেয়া ট্র্যাকিং চালু/বন্ধ করা
  static Future<Map<String, dynamic>> toggleCategoryDueTracking({
    required int categoryId,
    required bool hasDueTracking,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/toggle_due_tracking.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'category_id': categoryId,
          'has_due_tracking': hasDueTracking,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Toggle Category Due Tracking Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // categoryId না দিলে org-এর সব সোর্স রিটার্ন করবে
  static Future<List<dynamic>> getIncomeSources({int? categoryId}) async {
    try {
      String url = '$baseUrl/income_sources/list.php?organization_id=$defaultOrgId';
      if (categoryId != null) url += '&category_id=$categoryId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Income Sources Fetch Error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> addIncomeSource({
    required int categoryId,
    required String sourceName,
    required double monthlyTargetAmount,
    String? phone,
    String? joinDate, // ফরম্যাট: YYYY-MM-DD, না দিলে ব্যাকএন্ড আজকের তারিখ ধরে নেবে
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/income_sources/add_source.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'category_id': categoryId,
          'source_name': sourceName,
          'monthly_target_amount': monthlyTargetAmount,
          'phone': phone ?? '',
          'join_date': joinDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Add Income Source Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> updateIncomeSource({
    required int sourceId,
    required String sourceName,
    required double monthlyTargetAmount,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/income_sources/update_source.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'source_id': sourceId,
          'source_name': sourceName,
          'monthly_target_amount': monthlyTargetAmount,
          'phone': phone ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Update Income Source Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  static Future<Map<String, dynamic>> toggleIncomeSourceStatus({
    required int sourceId,
    required bool isActive,
    String? endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/income_sources/toggle_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'source_id': sourceId,
          'is_active': isActive,
          'end_date': endDate ?? '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Toggle Income Source Status Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // প্রতিটা সোর্সের join_date থেকে বর্তমান মাস পর্যন্ত মাসভিত্তিক Paid/Partial/Unpaid স্ট্যাটাস
  static Future<List<dynamic>> getIncomeSourceStatus({int? categoryId, int? sourceId}) async {
    try {
      String url = '$baseUrl/income_sources/status.php?organization_id=$defaultOrgId';
      if (categoryId != null) url += '&category_id=$categoryId';
      if (sourceId != null) url += '&source_id=$sourceId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res is List ? res : (res['data'] ?? []);
      }
    } catch (e) {
      print("Income Source Status Fetch Error: $e");
    }
    return [];
  }

  // incomeMonth ফরম্যাট: YYYY-MM-01 — একটা নির্দিষ্ট মাসের প্রথম আদায় জমা দেওয়ার জন্য
  static Future<Map<String, dynamic>> payIncomeSource({
    required int sourceId,
    required String incomeMonth,
    required double paidAmount,
    required String paymentDate,
    String paymentMethod = 'cash',
    double? targetAmount,
    double? dueAmount,
  }) async {
    try {
      final body = {
        'organization_id': defaultOrgId,
        'source_id': sourceId,
        'income_month': incomeMonth,
        'paid_amount': paidAmount,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
      };
      if (targetAmount != null) body['target_amount'] = targetAmount;
      if (dueAmount != null) body['due_amount'] = dueAmount;

      final response = await http.post(
        Uri.parse('$baseUrl/income_sources/pay_source.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Pay Income Source Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // আগের কোনো মাসের বকেয়া (income_source_payments এর payment_id) আংশিক বা পুরোপুরি পরিশোধ
  static Future<Map<String, dynamic>> settleIncomeSourceDue({
    required int paymentId,
    required double settleAmount,
    required String paymentDate,
    String paymentMethod = 'cash',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/income_sources/settle_due.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'organization_id': defaultOrgId,
          'payment_id': paymentId,
          'settle_amount': settleAmount,
          'payment_date': paymentDate,
          'payment_method': paymentMethod,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Settle Income Source Due Error: $e");
    }
    return {'status': false, 'message': 'Network or Server Error'};
  }

  // ---------------------------------------------------------------------------
  // Generic Helper Methods (Auth ও অন্যান্য dynamic কল করার জন্য)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("POST Error ($endpoint): $e");
    }
    return {'status': 'error', 'message': 'Network or Server Error'};
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("GET Error ($endpoint): $e");
    }
    return null;
  }
}
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart'
    show
    TextStyle,
    TextSpan,
    TextPainter,
    TextDirection,
    TextAlign,
    FontWeight,
    Color;
import 'package:flutter/services.dart' show rootBundle, FontLoader;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// ------------------------------------------------------------------------
/// বাংলা টেক্সট রেন্ডারিং সম্পর্কে নোট
/// ------------------------------------------------------------------------
/// Dart-এর `pdf` প্যাকেজের নিজস্ব টেক্সট রেন্ডারার কোনো OpenType শেপিং
/// (GSUB/GPOS, HarfBuzz জাতীয় ইঞ্জিন) করে না। তাই প্রতিটা বাংলা স্ট্রিং
/// আগে Flutter-এর নিজস্ব রেন্ডারার (TextPainter/Skia) দিয়ে PNG-তে আঁকা হয়,
/// তারপর সেটা pw.Image() হিসেবে PDF-এ বসানো হয় — এতে যুক্তাক্ষর/মাত্রা
/// কখনো ভাঙে না।
/// ------------------------------------------------------------------------
/// ডিজাইন সিস্টেম
/// ------------------------------------------------------------------------
/// - ব্র্যান্ড রঙ (টিল): অর্গ নাম, ডিভাইডার, ভাউচার ব্যাজ
/// - আয় = সবুজ, ব্যয় = লাল, ঋণ = কমলা, স্টাফ = নীল, অংশীদার = বেগুনি,
///   সাধারণ/অডিট টেবিল = ব্লু-গ্রে — প্রতিটা সেকশন এক নজরে আলাদা বোঝা যায়
/// - সংখ্যায় (দক্ষিণ এশীয় লাখ/কোটি রীতিতে) কমা বসানো হয়
/// - সারিতে জেব্রা-স্ট্রাইপিং, হেডার সারিতে হালকা রঙের ব্যাকগ্রাউন্ড
class PdfService {
  static bool _flutterFontRegistered = false;
  static const String _fontFamily = 'NotoSansBengaliRaster';

  static const double _kPtToLogicalPx = 96 / 72;
  static const double _kRenderScale = 3.0;

  // --- ব্র্যান্ড ও সেকশন রঙ ---
  static const PdfColor _brand = PdfColor.fromInt(0xFF00695C); // টিল
  static const PdfColor _brandBg = PdfColor.fromInt(0xFFE0F2F1);

  static const PdfColor _incomeAccent = PdfColor.fromInt(0xFF2E7D32); // সবুজ
  static const PdfColor _incomeBg = PdfColor.fromInt(0xFFE8F5E9);

  static const PdfColor _expenseAccent = PdfColor.fromInt(0xFFC62828); // লাল
  static const PdfColor _expenseBg = PdfColor.fromInt(0xFFFFEBEE);

  static const PdfColor _loanAccent = PdfColor.fromInt(0xFFEF6C00); // কমলা
  static const PdfColor _loanBg = PdfColor.fromInt(0xFFFFF3E0);

  static const PdfColor _staffAccent = PdfColor.fromInt(0xFF1565C0); // নীল
  static const PdfColor _staffBg = PdfColor.fromInt(0xFFE3F2FD);

  static const PdfColor _partnerAccent = PdfColor.fromInt(0xFF6A1B9A); // বেগুনি
  static const PdfColor _partnerBg = PdfColor.fromInt(0xFFF3E5F5);

  static const PdfColor _neutralAccent = PdfColor.fromInt(0xFF37474F); // ব্লু-গ্রে
  static const PdfColor _neutralBg = PdfColor.fromInt(0xFFECEFF1);

  static const Map<String, String> voucherTypeLabels = {
    'income': 'আয় ভাউচার',
    'expense': 'ব্যয় ভাউচার',
    'cash': 'ক্যাশ ভাউচার',
    'bank': 'ব্যাংক ভাউচার',
    'loan_repayment': 'ঋণ পরিশোধ ভাউচার',
    'staff_salary': 'স্টাফ বেতন ভাউচার',
    'staff_advance': 'স্টাফ অগ্রিম ভাউচার',
    'partner_allowance': 'অংশীদার ভাতা ভাউচার',
  };

  // --- fix ১ ও ২: raw টেবিল-কলামের নাম এবং enum মান-এর বাংলা অনুবাদ ---
  // এগুলো শুধু voucherTypeLabels-এর মতো "ভাউচার হেডার ব্যাজ"-এ নয়,
  // বরং _rawTable-এর প্রতিটা সেল রেন্ডার করার সময়ও ব্যবহার হয়।
  static const Map<String, String> _columnLabels = {
    'lender_name': 'ঋণদাতার নাম',
    'loan_amount': 'ঋণের পরিমাণ',
    'remaining_amount': 'অবশিষ্ট পরিমাণ',
    'loan_date': 'ঋণ গ্রহণের তারিখ',
    'staff_name': 'স্টাফের নাম',
    'salary_month': 'বেতনের মাস',
    'paid_amount': 'পরিশোধিত পরিমাণ',
    'payment_date': 'পরিশোধের তারিখ',
    'partner_name': 'অংশীদারের নাম',
    'allowance_month': 'ভাতার মাস',
    'voucher_no': 'ভাউচার নং',
    'voucher_type': 'ভাউচারের ধরন',
    'amount': 'পরিমাণ',
    'voucher_date': 'ভাউচারের তারিখ',
    'type': 'ধরন',
    'description': 'বিবরণ',
    'transaction_date': 'লেনদেনের তারিখ',
  };

  // "সম্পূর্ণ আয়-ব্যয় লেজার"-এর `type` কলামে Income/Expense আসে —
  // voucherTypeLabels-এর চাবি আলাদা (income/expense ভাউচার-নির্দিষ্ট বাক্য),
  // তাই লেজারের জন্য আলাদা ছোট লেবেল।
  static const Map<String, String> _ledgerTypeLabels = {
    'income': 'আয়',
    'expense': 'ব্যয়',
  };

  static String _columnLabel(String col) => _columnLabels[col] ?? col;

  /// একটা raw টেবিল-সেলের মান বাংলায় রূপান্তর করে:
  /// - amount/paid জাতীয় কলাম হলে ৳-ফরম্যাট
  /// - voucher_type হলে voucherTypeLabels থেকে
  /// - type (লেজার) হলে income/expense -> আয়/ব্যয়
  /// - বাকি সব ক্ষেত্রে যা আছে তাই (null হলে '-')
  static String _translateCellText(String col, dynamic rawValue) {
    if (rawValue == null) return '-';
    if (_isAmountColumn(col)) return _taka(rawValue);
    if (col == 'voucher_type') {
      return voucherTypeLabels[rawValue.toString()] ?? rawValue.toString();
    }
    if (col == 'type') {
      final key = rawValue.toString().toLowerCase();
      return _ledgerTypeLabels[key] ?? rawValue.toString();
    }
    return rawValue.toString();
  }

  // -------------------------------------------------------------------
  // ফন্ট লোড ও টেক্সট-টু-ইমেজ রেন্ডারিং
  // -------------------------------------------------------------------
  static Future<void> _ensureFlutterFontRegistered() async {
    if (_flutterFontRegistered) return;
    final data = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
    final loader = FontLoader(_fontFamily);
    loader.addFont(Future.value(data));
    await loader.load();
    _flutterFontRegistered = true;
  }

  static Future<_RenderedText> _render(
      String text, {
        double fontSize = 11,
        FontWeight fontWeight = FontWeight.normal,
        PdfColor color = PdfColors.black,
      }) async {
    await _ensureFlutterFontRegistered();

    final flutterFontSize = fontSize * _kPtToLogicalPx * _kRenderScale;
    final flutterColor = Color.fromARGB(
      255,
      (color.red * 255).round(),
      (color.green * 255).round(),
      (color.blue * 255).round(),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? ' ' : text,
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: flutterFontSize,
          fontWeight: fontWeight,
          color: flutterColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    )..layout();

    final pixelWidth = painter.width.ceil().clamp(1, 20000);
    final pixelHeight = painter.height.ceil().clamp(1, 20000);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    painter.paint(canvas, ui.Offset.zero);
    final picture = recorder.endRecording();

    final image = await picture.toImage(pixelWidth, pixelHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = byteData!.buffer.asUint8List();

    return _RenderedText(
      bytes: bytes,
      width: pixelWidth / _kRenderScale / _kPtToLogicalPx,
      height: pixelHeight / _kRenderScale / _kPtToLogicalPx,
    );
  }

  static Future<pw.Widget> _text(
      String text, {
        double fontSize = 11,
        FontWeight fontWeight = FontWeight.normal,
        PdfColor color = PdfColors.black,
      }) async {
    final r = await _render(text, fontSize: fontSize, fontWeight: fontWeight, color: color);
    return r.toWidget();
  }

  // একটা সেকশন হেডিং: বোল্ড টেক্সট + নিচে অ্যাকসেন্ট-রঙা আন্ডারলাইন
  static Future<pw.Widget> _sectionHeading(
      String title, {
        PdfColor accent = _neutralAccent,
        double fontSize = 12,
      }) async {
    final titleImg = await _text(title, fontSize: fontSize, fontWeight: FontWeight.bold, color: accent);
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1.2)),
      ),
      child: titleImg,
    );
  }

  static PdfColor _zebra(int index) => index.isEven ? PdfColors.white : PdfColors.grey100;

  // -------------------------------------------------------------------
  // সংখ্যা ফরম্যাটিং — দক্ষিণ এশীয় (লাখ/কোটি) কমা বসানো + ৳ চিহ্ন
  // -------------------------------------------------------------------
  static String _withCommas(String numText) {
    final negative = numText.startsWith('-');
    final clean = negative ? numText.substring(1) : numText;
    final dotIndex = clean.indexOf('.');
    final intPart = dotIndex == -1 ? clean : clean.substring(0, dotIndex);
    final fracPart = dotIndex == -1 ? '' : clean.substring(dotIndex);

    String grouped;
    final len = intPart.length;
    if (len <= 3) {
      grouped = intPart;
    } else {
      final lastThree = intPart.substring(len - 3);
      var remaining = intPart.substring(0, len - 3);
      final groups = <String>[];
      while (remaining.length > 2) {
        groups.insert(0, remaining.substring(remaining.length - 2));
        remaining = remaining.substring(0, remaining.length - 2);
      }
      if (remaining.isNotEmpty) groups.insert(0, remaining);
      grouped = '${groups.join(',')},$lastThree';
    }
    return '${negative ? '-' : ''}$grouped$fracPart';
  }

  static String _taka(dynamic amount) => '৳ ${_withCommas('${amount ?? 0}')}';

  static bool _isAmountColumn(String col) {
    final c = col.toLowerCase();
    return c.contains('amount') || c.contains('paid');
  }

  // -------------------------------------------------------------------
  // ভাউচার
  // -------------------------------------------------------------------
  static Future<void> printVoucher(
      Map<String, dynamic> voucher, {
        String orgName = 'ওয়াক্‌ফ আল-আওলাদ এস্টেট হিসাবরক্ষণ',
      }) async {
    final typeLabel = voucherTypeLabels[voucher['voucher_type']] ?? (voucher['voucher_type']?.toString() ?? '-');

    final doc = pw.Document();

    final orgNameImg = await _text(orgName, fontSize: 16, fontWeight: FontWeight.bold, color: _brand);
    final typeLabelImg = await _text(typeLabel, fontSize: 12, fontWeight: FontWeight.bold, color: _brand);
    final row1 = await _detailRow('ভাউচার নং', voucher['voucher_no']?.toString() ?? '-', isLast: false);
    final row2 = await _detailRow('তারিখ', voucher['voucher_date']?.toString() ?? '-', isLast: false);
    final row3 = await _detailRow('বিবরণ', voucher['remarks']?.toString() ?? '-', isLast: false);
    final row4 = await _detailRow('পরিমাণ', _taka(voucher['amount']), isLast: true);
    final sig1 = await _signatureBlock('প্রদানকারীর স্বাক্ষর');
    final sig2 = await _signatureBlock('অনুমোদনকারীর স্বাক্ষর');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ব্র্যান্ড ঘোষণা ফালি
              pw.Container(height: 4, color: _brand),
              pw.SizedBox(height: 14),
              pw.Center(child: orgNameImg),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _brandBg,
                    border: pw.Border.all(color: _brand, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: typeLabelImg,
                ),
              ),
              pw.SizedBox(height: 22),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(children: [row1, row2, row3, row4]),
              ),
              pw.SizedBox(height: 60),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [sig1, sig2],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    final fileName = 'Voucher_${voucher['voucher_no'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<pw.Widget> _detailRow(String label, String value, {bool isLast = false}) async {
    final labelImg = await _text(label, fontSize: 11, color: PdfColors.grey700);
    final valueImg = await _text(value, fontSize: 11, fontWeight: FontWeight.bold);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: isLast
          ? null
          : const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 85, child: labelImg),
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 6),
            child: pw.Text(':', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          ),
          pw.Expanded(child: valueImg),
        ],
      ),
    );
  }

  static Future<pw.Widget> _signatureBlock(String label) async {
    final labelImg = await _text(label, fontSize: 10, color: PdfColors.grey700);
    return pw.Column(
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Divider(thickness: 0.8, color: _brand),
        ),
        pw.SizedBox(height: 4),
        labelImg,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // রিপোর্ট PDF (দৈনিক/মাসিক/বার্ষিক/অডিট — report_screen.dart-এর ডেটা দিয়ে)
  // ---------------------------------------------------------------------------
  static Future<void> printReport({
    required Map<String, dynamic> report,
    required String periodLabel,
    required Set<String> visibleSections,
    required bool isAudit,
    String orgName = 'ওয়াক্‌ফ আল-আওলাদ এস্টেট হিসাবরক্ষণ',
  }) async {
    final doc = pw.Document();

    final orgNameImg = await _text(orgName, fontSize: 17, fontWeight: FontWeight.bold, color: _brand);
    final periodImg = await _text(periodLabel, fontSize: 12, color: PdfColors.grey700);
    final pageLabelRendered = await _render('পৃষ্ঠা', fontSize: 9, color: PdfColors.grey600);

    final widgets = <pw.Widget>[
      pw.Container(height: 4, color: _brand),
      pw.SizedBox(height: 14),
      pw.Center(child: orgNameImg),
      pw.SizedBox(height: 4),
      pw.Center(child: periodImg),
      pw.SizedBox(height: 12),
      pw.Divider(thickness: 1, color: _brand),
      pw.SizedBox(height: 10),
    ];

    // সারসংক্ষেপ
    final summaryRows = <List<String>>[];
    if (!isAudit) {
      summaryRows.add(['মোট আয়', _taka(report['total_income'])]);
      summaryRows.add(['মোট ব্যয়', _taka(report['total_expense'])]);
      summaryRows.add(['নিট ব্যালেন্স', _taka(report['net_balance'])]);
    }
    summaryRows.add(['ক্যাশ ব্যালেন্স', _taka(report['cash_balance'])]);
    summaryRows.add(['ব্যাংক ব্যালেন্স', _taka(report['bank_balance'])]);
    // fix ৪: report_screen.dart (ইন-অ্যাপ) আগে থেকেই bkash_balance/nagad_balance/
    // total_balance থাকলে দেখাচ্ছিল, কিন্তু PDF-এ এই তিনটা field একদমই বাদ পড়েছিল —
    // ফলে PDF রিপোর্টে বিকাশ/নগদের টাকা এবং সব-মাধ্যম-মিলিয়ে-মোট কখনো দেখা যেত না।
    if (report['bkash_balance'] != null) {
      summaryRows.add(['বিকাশ ব্যালেন্স', _taka(report['bkash_balance'])]);
    }
    if (report['nagad_balance'] != null) {
      summaryRows.add(['নগদ ব্যালেন্স', _taka(report['nagad_balance'])]);
    }
    if (report['total_balance'] != null) {
      summaryRows.add(['মোট ব্যালেন্স (সব মাধ্যম)', _taka(report['total_balance'])]);
    }
    widgets.add(await _summaryTable(summaryRows));
    widgets.add(pw.SizedBox(height: 16));

    if (visibleSections.contains('income') && report['income_by_category'] != null) {
      widgets.add(await _titledSimpleTable('খাতভিত্তিক আয়', report['income_by_category'], 'category_name', 'total',
          accent: _incomeAccent, headerBg: _incomeBg));
    }
    if (visibleSections.contains('expense') && report['expense_by_category'] != null) {
      widgets.add(await _titledSimpleTable('খাতভিত্তিক ব্যয়', report['expense_by_category'], 'category_name', 'total',
          accent: _expenseAccent, headerBg: _expenseBg));
    }
    if (visibleSections.contains('loan') && report['loan_payments'] != null) {
      widgets.add(await _titledSimpleTable('ঋণ পরিশোধ (মোট: ${_taka(report['loan_payment_total'])})',
          report['loan_payments'], 'lender_name', 'amount_paid',
          accent: _loanAccent, headerBg: _loanBg));
    }
    if (isAudit && report['loans'] != null) {
      widgets.add(await _rawTable('ঋণের তালিকা (সব)', report['loans'],
          ['lender_name', 'loan_amount', 'remaining_amount', 'loan_date'],
          accent: _loanAccent, headerBg: _loanBg));
    }
    if (visibleSections.contains('staff_salary') && report['staff_salary_payments'] != null) {
      widgets.add(await _titledSimpleTable('স্টাফ বেতন (মোট: ${_taka(report['staff_salary_total'])})',
          report['staff_salary_payments'], 'staff_name', 'paid_amount',
          accent: _staffAccent, headerBg: _staffBg));
    }
    if (isAudit && report['staff_salary'] != null) {
      widgets.add(await _rawTable('স্টাফ বেতন (সম্পূর্ণ ইতিহাস)', report['staff_salary'],
          ['staff_name', 'salary_month', 'paid_amount', 'payment_date'],
          accent: _staffAccent, headerBg: _staffBg));
    }
    if (visibleSections.contains('partner_allowance') && report['partner_allowance_payments'] != null) {
      widgets.add(await _titledSimpleTable('অংশীদারদের ভাতা (মোট: ${_taka(report['partner_allowance_total'])})',
          report['partner_allowance_payments'], 'partner_name', 'paid_amount',
          accent: _partnerAccent, headerBg: _partnerBg));
    }
    if (isAudit && report['partner_allowance'] != null) {
      widgets.add(await _rawTable('অংশীদার ভাতা (সম্পূর্ণ ইতিহাস)', report['partner_allowance'],
          ['partner_name', 'allowance_month', 'paid_amount', 'payment_date'],
          accent: _partnerAccent, headerBg: _partnerBg));
    }
    if (visibleSections.contains('vouchers') && report['vouchers'] != null) {
      widgets.add(await _rawTable('ভাউচার তালিকা', report['vouchers'],
          ['voucher_no', 'voucher_type', 'amount', 'voucher_date'],
          accent: _neutralAccent, headerBg: _neutralBg));
    }
    if (isAudit && report['audit_trail'] != null) {
      widgets.add(await _rawTable('সম্পূর্ণ আয়-ব্যয় লেজার', report['audit_trail'],
          ['type', 'description', 'amount', 'transaction_date'],
          accent: _neutralAccent, headerBg: _neutralBg));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pageLabelRendered.toWidget(),
              pw.SizedBox(width: 4),
              pw.Text('${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) => widgets,
      ),
    );

    final bytes = await doc.save();
    final fileName = 'Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<pw.Widget> _summaryTable(List<List<String>> rows) async {
    final tableRows = <pw.TableRow>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final labelImg = await _text(r[0], fontSize: 11, color: PdfColors.grey800);
      final valueImg = await _text(r[1], fontSize: 12, fontWeight: FontWeight.bold, color: _brand);
      tableRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: _zebra(i)),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: labelImg),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: valueImg),
        ],
      ));
    }
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
      children: tableRows,
    );
  }

  static Future<pw.Widget> _titledSimpleTable(
      String title,
      List<dynamic> rows,
      String nameKey,
      String amountKey, {
        PdfColor accent = _neutralAccent,
        PdfColor headerBg = _neutralBg,
      }) async {
    final heading = await _sectionHeading(title, accent: accent);

    pw.Widget body;
    if (rows.isEmpty) {
      body = await _text('কোনো ডেটা নেই', fontSize: 10, color: PdfColors.grey600);
    } else {
      final descHeaderImg = await _text('বিবরণ', fontSize: 9, fontWeight: FontWeight.bold, color: accent);
      final amountHeaderImg = await _text('পরিমাণ', fontSize: 9, fontWeight: FontWeight.bold, color: accent);
      final tableRows = <pw.TableRow>[
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: descHeaderImg),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: amountHeaderImg),
          ],
        ),
      ];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final nameImg = await _text('${row[nameKey] ?? '-'}', fontSize: 10);
        final amountImg = await _text(_taka(row[amountKey]), fontSize: 10, fontWeight: FontWeight.bold);
        tableRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: _zebra(i)),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: nameImg),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: amountImg),
          ],
        ));
      }
      body = pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
        children: tableRows,
      );
    }

    // --- fix ৩: হেডিং একা অনাথ (orphan) হয়ে এক পাতায় থেকে যাওয়া ঠেকাতে ---
    // pw.Inseparable হেডিং+টেবিলকে এক ব্লক হিসেবে গণ্য করে: বর্তমান পাতায়
    // পুরোটা ধরলে সেখানেই বসবে, না ধরলে গোটা ব্লকটাই পরের (ফাঁকা) পাতায়
    // যাবে — কিন্তু সেই নতুন পাতাতেও যদি টেবিল বড় হয়ে উপচে যায়, তখন
    // স্বাভাবিক নিয়মেই একাধিক পাতায় ভাগ হতে পারবে (ডেটা হারাবে না)।
    return pw.Inseparable(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [heading, pw.SizedBox(height: 6), body],
        ),
      ),
    );
  }

  static Future<pw.Widget> _rawTable(
      String title,
      List<dynamic> rows,
      List<String> columns, {
        PdfColor accent = _neutralAccent,
        PdfColor headerBg = _neutralBg,
      }) async {
    final heading = await _sectionHeading(title, accent: accent);

    pw.Widget body;
    if (rows.isEmpty) {
      body = await _text('কোনো ডেটা নেই', fontSize: 10, color: PdfColors.grey600);
    } else {
      final headerCells = <pw.Widget>[];
      for (final c in columns) {
        // fix ১: raw কলাম-নামের বদলে বাংলা লেবেল
        final img = await _text(_columnLabel(c), fontSize: 9, fontWeight: FontWeight.bold, color: accent);
        headerCells.add(pw.Padding(padding: const pw.EdgeInsets.all(5), child: img));
      }
      final bodyRows = <pw.TableRow>[
        pw.TableRow(decoration: pw.BoxDecoration(color: headerBg), children: headerCells),
      ];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final cells = <pw.Widget>[];
        for (final c in columns) {
          // fix ২: enum/স্ট্যাটাস মান (voucher_type, type) বাংলায় অনুবাদ
          final cellText = _translateCellText(c, row[c]);
          final img = await _text(cellText, fontSize: 9);
          cells.add(pw.Padding(padding: const pw.EdgeInsets.all(5), child: img));
        }
        bodyRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: _zebra(i)),
          children: cells,
        ));
      }
      body = pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
        children: bodyRows,
      );
    }

    // fix ৩ (একই কারণ/সমাধান _titledSimpleTable-এর মন্তব্য দ্রষ্টব্য)
    return pw.Inseparable(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [heading, pw.SizedBox(height: 6), body],
        ),
      ),
    );
  }
}

/// একটা রেন্ডার করা টেক্সট-ছবির বাইট ও PDF-পয়েন্ট এককে তার প্রদর্শন-সাইজ।
class _RenderedText {
  final Uint8List bytes;
  final double width;
  final double height;
  _RenderedText({required this.bytes, required this.width, required this.height});

  pw.Widget toWidget() => pw.Image(pw.MemoryImage(bytes), width: width, height: height);
}
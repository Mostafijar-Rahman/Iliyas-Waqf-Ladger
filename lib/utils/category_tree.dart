// মাল্টি-লেভেল ক্যাটাগরি ট্রি অনুযায়ী রিপোর্টের সারি সাজানোর হেল্পার।
// ডেটা বদলায় না, শুধু দেখানোর ক্রম ও প্রতি স্তরের মোট হিসাব করে।

class CategoryNode {
  final String name;
  final int depth; // ০ = মূল খাত, ১ = তার সাব, ২ = সাব-সাব ...
  final double total; // নিজের + নিচের সবকিছুর মোট
  const CategoryNode(this.name, this.depth, this.total);
}

class CategoryTreeResult {
  final List<CategoryNode> rows;
  final double grandTotal; // শুধু মূল খাতগুলোর যোগফল (কোনো টাকা দুইবার গোনা হয় না)
  const CategoryTreeResult(this.rows, this.grandTotal);
}

int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

/// categoryTree: ক্যাটাগরি API-র নেস্টেড ট্রি (id, category_name, subcategories)
/// reportRows: রিপোর্টের সারি [{category_id, category_name, total}]
/// ফেরত null হলে (যেমন category_id নেই) পুরোনো ফ্ল্যাট টেবিলেই দেখাতে হবে।
CategoryTreeResult? buildCategoryTreeRows(List<dynamic> categoryTree, List<dynamic> reportRows) {
  if (categoryTree.isEmpty || reportRows.isEmpty) return null;

  final own = <int, double>{};
  final names = <int, String>{};
  for (final row in reportRows) {
    final id = _toInt(row['category_id']);
    if (id == null) return null;
    own[id] = (own[id] ?? 0) + _toDouble(row['total']);
    names[id] = (row['category_name'] ?? '-').toString();
  }

  final out = <CategoryNode>[];
  final seen = <int>{};
  double grand = 0;

  for (final top in categoryTree) {
    final t = _walk(top, 0, own, seen, out);
    if (t != null) grand += t;
  }

  // ট্রিতে নেই এমন ক্যাটাগরি (যেমন মুছে ফেলা) যাতে মোট থেকে বাদ না পড়ে
  for (final e in own.entries) {
    if (!seen.contains(e.key)) {
      out.add(CategoryNode(names[e.key] ?? '-', 0, e.value));
      grand += e.value;
    }
  }

  return CategoryTreeResult(out, grand);
}

double? _walk(dynamic node, int depth, Map<int, double> own, Set<int> seen, List<CategoryNode> out) {
  final id = _toInt(node['id']);
  final name = (node['category_name'] ?? '-').toString();
  final List subs = node['subcategories'] is List ? node['subcategories'] as List : const [];
  if (id != null) seen.add(id);
  final ownTotal = id == null ? null : own[id];

  final index = out.length;
  out.add(CategoryNode(name, depth, 0));

  var sum = ownTotal ?? 0.0;
  var childHadData = false;
  for (final s in subs) {
    final r = _walk(s, depth + 1, own, seen, out);
    if (r != null) {
      sum += r;
      childHadData = true;
    }
  }

  // এই খাত বা এর নিচে কোনো খরচ/আয় নেই: সারিটা বাদ
  if (ownTotal == null && !childHadData) {
    out.removeLast();
    return null;
  }

  // মাঝের স্তরে সরাসরি এন্ট্রি থাকলে আলাদা সারিতে দেখানো, যাতে হিসাব মেলে
  if (ownTotal != null && childHadData) {
    out.insert(index + 1, CategoryNode('সরাসরি এন্ট্রি', depth + 1, ownTotal));
  }

  out[index] = CategoryNode(name, depth, sum);
  return sum;
}
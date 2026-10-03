/// What an entry is for, in the words the company uses.
///
/// Each one points at a ledger account, which is what the accountant reads.
/// The person picks "Software subscriptions"; the books record 6400.
/// Decision 009.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.mainHead,
    required this.direction,
    required this.ledgerCode,
    required this.ledgerName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final ledger = json['ledger'] as Map<String, dynamic>;
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      mainHead: json['mainHead'] as String,
      direction: json['direction'] as String,
      ledgerCode: ledger['code'] as String,
      ledgerName: ledger['name'] as String,
    );
  }

  final int id;
  final String name;

  /// revenue, cost_of_sales, admin, financial, tax, balance_sheet. The picker
  /// groups by this so a long list stays readable.
  final String mainHead;
  final String direction;
  final String ledgerCode;
  final String ledgerName;
}

class CategoryGroup {
  const CategoryGroup({required this.mainHead, required this.categories});

  factory CategoryGroup.fromJson(Map<String, dynamic> json) => CategoryGroup(
        mainHead: json['mainHead'] as String,
        categories: (json['categories'] as List<dynamic>)
            .map((item) => Category.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String mainHead;
  final List<Category> categories;
}

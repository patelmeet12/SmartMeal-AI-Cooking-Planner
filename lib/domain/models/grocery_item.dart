class GroceryItem {
  final String name;
  final double requiredQty;
  final double availableQty;
  final String unit;
  final bool needToBuy;
  final double estimatedCost; // cost for the quantity that needs to be bought

  const GroceryItem({
    required this.name,
    required this.requiredQty,
    required this.availableQty,
    required this.unit,
    required this.needToBuy,
    required this.estimatedCost,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name'] as String,
      requiredQty: (json['requiredQty'] as num).toDouble(),
      availableQty: (json['availableQty'] as num).toDouble(),
      unit: json['unit'] as String,
      needToBuy: json['needToBuy'] as bool,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'requiredQty': requiredQty,
      'availableQty': availableQty,
      'unit': unit,
      'needToBuy': needToBuy,
      'estimatedCost': estimatedCost,
    };
  }
}

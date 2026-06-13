class Meal {
  final String id;
  final String name;
  final String type; // 'breakfast', 'lunch', 'dinner'
  final int calories;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final int prepTime; // in minutes
  final double baseCostPerPerson; // in ₹
  final String dietaryTag; // 'vegetarian', 'vegan', 'high_protein', 'non_vegetarian'
  final Map<String, double> ingredients; // ingredient name -> qty per person
  final Map<String, String> ingredientUnits; // ingredient name -> unit (g, ml, pcs, etc.)
  final List<String> suitableDayTypes;
  final String reasoning;

  const Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.difficulty,
    required this.prepTime,
    required this.baseCostPerPerson,
    required this.dietaryTag,
    required this.ingredients,
    required this.ingredientUnits,
    required this.suitableDayTypes,
    required this.reasoning,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      calories: json['calories'] as int,
      difficulty: json['difficulty'] as String,
      prepTime: json['prepTime'] as int,
      baseCostPerPerson: (json['baseCostPerPerson'] as num).toDouble(),
      dietaryTag: json['dietaryTag'] as String,
      ingredients: Map<String, double>.from(
        (json['ingredients'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      ),
      ingredientUnits: Map<String, String>.from(json['ingredientUnits'] as Map),
      suitableDayTypes: List<String>.from(json['suitableDayTypes'] as List),
      reasoning: json['reasoning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'calories': calories,
      'difficulty': difficulty,
      'prepTime': prepTime,
      'baseCostPerPerson': baseCostPerPerson,
      'dietaryTag': dietaryTag,
      'ingredients': ingredients,
      'ingredientUnits': ingredientUnits,
      'suitableDayTypes': suitableDayTypes,
      'reasoning': reasoning,
    };
  }
}

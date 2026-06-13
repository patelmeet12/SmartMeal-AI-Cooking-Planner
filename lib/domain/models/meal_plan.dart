import 'meal.dart';
import 'grocery_item.dart';
import 'todo_item.dart';

class MealPlan {
  final String dayType;
  final int numPeople;
  final double budget;
  final Meal breakfast;
  final Meal lunch;
  final Meal dinner;
  final List<GroceryItem> groceryList;
  final List<TodoItem> todoList;
  final int totalCalories;
  final double totalGroceryCost;
  final double budgetRemaining;
  final bool isOverBudget;
  final Map<String, String> substitutionsApplied; // e.g. {"Paneer": "Tofu"}
  final List<String> costSavingSuggestions;
  final String recommendationReasoning;

  const MealPlan({
    required this.dayType,
    required this.numPeople,
    required this.budget,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.groceryList,
    required this.todoList,
    required this.totalCalories,
    required this.totalGroceryCost,
    required this.budgetRemaining,
    required this.isOverBudget,
    required this.substitutionsApplied,
    required this.costSavingSuggestions,
    required this.recommendationReasoning,
  });

  MealPlan copyWith({
    String? dayType,
    int? numPeople,
    double? budget,
    Meal? breakfast,
    Meal? lunch,
    Meal? dinner,
    List<GroceryItem>? groceryList,
    List<TodoItem>? todoList,
    int? totalCalories,
    double? totalGroceryCost,
    double? budgetRemaining,
    bool? isOverBudget,
    Map<String, String>? substitutionsApplied,
    List<String>? costSavingSuggestions,
    String? recommendationReasoning,
  }) {
    return MealPlan(
      dayType: dayType ?? this.dayType,
      numPeople: numPeople ?? this.numPeople,
      budget: budget ?? this.budget,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      groceryList: groceryList ?? this.groceryList,
      todoList: todoList ?? this.todoList,
      totalCalories: totalCalories ?? this.totalCalories,
      totalGroceryCost: totalGroceryCost ?? this.totalGroceryCost,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      isOverBudget: isOverBudget ?? this.isOverBudget,
      substitutionsApplied: substitutionsApplied ?? this.substitutionsApplied,
      costSavingSuggestions: costSavingSuggestions ?? this.costSavingSuggestions,
      recommendationReasoning: recommendationReasoning ?? this.recommendationReasoning,
    );
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      dayType: json['dayType'] as String,
      numPeople: json['numPeople'] as int,
      budget: (json['budget'] as num).toDouble(),
      breakfast: Meal.fromJson(json['breakfast'] as Map<String, dynamic>),
      lunch: Meal.fromJson(json['lunch'] as Map<String, dynamic>),
      dinner: Meal.fromJson(json['dinner'] as Map<String, dynamic>),
      groceryList: (json['groceryList'] as List)
          .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      todoList: (json['todoList'] as List)
          .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: json['totalCalories'] as int,
      totalGroceryCost: (json['totalGroceryCost'] as num).toDouble(),
      budgetRemaining: (json['budgetRemaining'] as num).toDouble(),
      isOverBudget: json['isOverBudget'] as bool,
      substitutionsApplied: Map<String, String>.from(json['substitutionsApplied'] as Map),
      costSavingSuggestions: List<String>.from(json['costSavingSuggestions'] as List),
      recommendationReasoning: json['recommendationReasoning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayType': dayType,
      'numPeople': numPeople,
      'budget': budget,
      'breakfast': breakfast.toJson(),
      'lunch': lunch.toJson(),
      'dinner': dinner.toJson(),
      'groceryList': groceryList.map((e) => e.toJson()).toList(),
      'todoList': todoList.map((e) => e.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalGroceryCost': totalGroceryCost,
      'budgetRemaining': budgetRemaining,
      'isOverBudget': isOverBudget,
      'substitutionsApplied': substitutionsApplied,
      'costSavingSuggestions': costSavingSuggestions,
      'recommendationReasoning': recommendationReasoning,
    };
  }
}

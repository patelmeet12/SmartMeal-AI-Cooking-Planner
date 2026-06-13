import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../models/grocery_item.dart';
import '../models/todo_item.dart';

class PlannerService {
  // Substitution rules: original -> substitute name
  static const Map<String, String> substitutionMap = {
    'Paneer': 'Tofu',
    'Milk': 'Almond Milk',
    'Chicken': 'Soy Chunks',
    'Butter': 'Olive Oil',
  };

  // Ingredient costs per unit (in ₹)
  static const Map<String, double> ingredientUnitCosts = {
    'Paneer': 0.8,         // ₹0.8 per g
    'Tofu': 0.35,          // ₹0.35 per g
    'Milk': 0.06,          // ₹0.06 per ml
    'Almond Milk': 0.15,   // ₹0.15 per ml
    'Chicken': 0.7,        // ₹0.7 per g
    'Soy Chunks': 0.2,     // ₹0.2 per g
    'Butter': 0.5,         // ₹0.5 per g
    'Olive Oil': 0.6,      // ₹0.6 per ml
    'Oats': 0.15,          // ₹0.15 per g
    'Banana': 6.0,         // ₹6 per pc
    'Almonds': 1.2,        // ₹1.2 per g
    'Honey': 0.4,          // ₹0.4 per g
    'Poha': 0.08,          // ₹0.08 per g
    'Onion': 10.0,         // ₹10 per pc
    'Peanuts': 0.25,       // ₹0.25 per g
    'Mustard Seeds': 0.1,  // ₹0.1 per g
    'Oil': 0.15,           // ₹0.15 per ml
    'Moong Dal (split)': 0.12, // ₹0.12 per g
    'Green Chillies': 2.0, // ₹2 per pc
    'Coriander': 0.5,      // ₹0.5 per g
    'Eggs': 8.0,           // ₹8 per pc
    'Whole Wheat Bread': 4.0, // ₹4 per pc
    'Black Pepper': 0.5,   // ₹0.5 per g
    'Dosa Batter': 0.12,   // ₹0.12 per ml
    'Potato': 8.0,         // ₹8 per pc
    'Chia Seeds': 1.0,     // ₹1 per g
    'Maple Syrup': 0.8,    // ₹0.8 per ml
    'Peanut Butter': 0.4,  // ₹0.4 per g
    'Flour': 0.05,         // ₹0.05 per g
    'Sugar': 0.05,         // ₹0.05 per g
    'Yellow Lentils': 0.12, // ₹0.12 per g
    'Rice': 0.06,          // ₹0.06 per g
    'Tomato': 8.0,         // ₹8 per pc
    'Spices': 0.5,         // ₹0.5 per g
    'Wheat Flour': 0.05,   // ₹0.05 per g
    'Quinoa': 0.35,        // ₹0.35 per g
    'Capsicum': 15.0,      // ₹15 per pc
    'Soy Sauce': 0.3,      // ₹0.3 per ml
    'Avocado': 60.0,       // ₹60 per pc
    'Lettuce': 0.4,        // ₹0.4 per g
    'Lemon': 5.0,          // ₹5 per pc
    'Basmati Rice': 0.12,  // ₹0.12 per g
    'Carrot': 10.0,        // ₹10 per pc
    'Beans': 0.15,         // ₹0.15 per g
    'Curd': 0.08,          // ₹0.08 per g
    'Cream': 0.3,          // ₹0.3 per ml
    'Tomato Paste': 0.2,   // ₹0.2 per g
    'Chickpeas (boiled)': 0.1, // ₹0.1 per g
    'Cucumber': 10.0,      // ₹10 per pc
    'Broccoli': 0.3,       // ₹0.3 per g
    'Garlic': 0.5,         // ₹0.5 per g
    'Mixed Vegetables': 0.1, // ₹0.1 per g
    'Cumin Seeds': 0.1,    // ₹0.1 per g
    'Mint': 0.5,           // ₹0.5 per g
    'Sweet Potato': 0.1,   // ₹0.1 per g
    'Spinach': 0.2,        // ₹0.2 per g
    'Sesame Dressing': 0.4, // ₹0.4 per ml
    'Mutton': 1.4,         // ₹1.4 per g
    'Paratha (frozen/fresh)': 15.0, // ₹15 per pc
  };

  /// Main entry point to generate a plan
  MealPlan generatePlan({
    required List<Meal> allMeals,
    required String dayType,
    required int numPeople,
    required double budget,
    required String dietaryPreference,
    required List<String> availableIngredients,
    required int cookingTimeAvailable,
  }) {
    // 1. Filter meals by diet and time
    final candidateMeals = allMeals.where((meal) {
      // Dietary checks
      if (dietaryPreference == 'vegan' && meal.dietaryTag != 'vegan') {
        return false;
      }
      if (dietaryPreference == 'vegetarian' &&
          meal.dietaryTag != 'vegetarian' &&
          meal.dietaryTag != 'vegan') {
        return false;
      }
      // Non-veg and High-protein can eat any meal structure, but we filter high_protein tag specifically when scoring.
      
      // Cooking time check
      if (meal.prepTime > cookingTimeAvailable) {
        return false;
      }
      return true;
    }).toList();

    // Split candidates into categories
    final breakfasts = candidateMeals.where((m) => m.type == 'breakfast').toList();
    final lunches = candidateMeals.where((m) => m.type == 'lunch').toList();
    final dinners = candidateMeals.where((m) => m.type == 'dinner').toList();

    // Fallbacks if no meals match (e.g. strict time constraint).
    // We relax prep time constraint if no match in a category.
    final finalBreakfasts = breakfasts.isNotEmpty 
        ? breakfasts 
        : allMeals.where((m) => m.type == 'breakfast' && _matchesDiet(m, dietaryPreference)).toList();
    final finalLunches = lunches.isNotEmpty 
        ? lunches 
        : allMeals.where((m) => m.type == 'lunch' && _matchesDiet(m, dietaryPreference)).toList();
    final finalDinners = dinners.isNotEmpty 
        ? dinners 
        : allMeals.where((m) => m.type == 'dinner' && _matchesDiet(m, dietaryPreference)).toList();

    // Score and select best
    final Meal selectedBreakfast = _selectBestMeal(finalBreakfasts, dayType, dietaryPreference, availableIngredients, budget * 0.2, numPeople);
    final Meal selectedLunch = _selectBestMeal(finalLunches, dayType, dietaryPreference, availableIngredients, budget * 0.4, numPeople);
    final Meal selectedDinner = _selectBestMeal(finalDinners, dayType, dietaryPreference, availableIngredients, budget * 0.4, numPeople);

    // Initial total raw cost based on baseCostPerPerson
    double baseCost = (selectedBreakfast.baseCostPerPerson +
            selectedLunch.baseCostPerPerson +
            selectedDinner.baseCostPerPerson) *
        numPeople;

    // Apply substitution engine if over budget
    bool isOverBudget = baseCost > budget;
    Map<String, String> substitutionsApplied = {};
    List<String> costSavingSuggestions = [];

    // Let's create modifiable versions of the meals if we apply substitutions
    Meal breakfastToUse = selectedBreakfast;
    Meal lunchToUse = selectedLunch;
    Meal dinnerToUse = selectedDinner;

    if (isOverBudget) {
      // Let's try replacing ingredients in order of saving size
      // We will check Paneer -> Tofu (saves ~₹45 * people), Chicken -> Soy Chunks (saves ~₹100 * people), Butter -> Olive Oil (saves ~₹10 * people)
      var currentCost = baseCost;

      // Check Chicken -> Soy Chunks
      if (currentCost > budget && _containsIngredient(breakfastToUse, lunchToUse, dinnerToUse, 'Chicken')) {
        currentCost -= (100.0 * numPeople); // standard chicken saving
        substitutionsApplied['Chicken'] = 'Soy Chunks';
        costSavingSuggestions.add('Replace Chicken with Soy Chunks. Reduces estimated cost by ₹${(100.0 * numPeople).toStringAsFixed(0)}.');
        
        breakfastToUse = _substituteMealIngredient(breakfastToUse, 'Chicken', 'Soy Chunks', 0.2);
        lunchToUse = _substituteMealIngredient(lunchToUse, 'Chicken', 'Soy Chunks', 0.2);
        dinnerToUse = _substituteMealIngredient(dinnerToUse, 'Chicken', 'Soy Chunks', 0.2);
      }

      // Check Paneer -> Tofu
      if (currentCost > budget && _containsIngredient(breakfastToUse, lunchToUse, dinnerToUse, 'Paneer')) {
        currentCost -= (45.0 * numPeople); // standard paneer saving
        substitutionsApplied['Paneer'] = 'Tofu';
        costSavingSuggestions.add('Replace Paneer with Tofu. Reduces estimated cost by ₹${(45.0 * numPeople).toStringAsFixed(0)}.');

        breakfastToUse = _substituteMealIngredient(breakfastToUse, 'Paneer', 'Tofu', 0.35);
        lunchToUse = _substituteMealIngredient(lunchToUse, 'Paneer', 'Tofu', 0.35);
        dinnerToUse = _substituteMealIngredient(dinnerToUse, 'Paneer', 'Tofu', 0.35);
      }

      // Check Butter -> Olive Oil
      if (currentCost > budget && _containsIngredient(breakfastToUse, lunchToUse, dinnerToUse, 'Butter')) {
        currentCost -= (10.0 * numPeople); // standard butter saving
        substitutionsApplied['Butter'] = 'Olive Oil';
        costSavingSuggestions.add('Replace Butter with Olive Oil. Reduces estimated cost by ₹${(10.0 * numPeople).toStringAsFixed(0)}.');

        breakfastToUse = _substituteMealIngredient(breakfastToUse, 'Butter', 'Olive Oil', 0.6);
        lunchToUse = _substituteMealIngredient(lunchToUse, 'Butter', 'Olive Oil', 0.6);
        dinnerToUse = _substituteMealIngredient(dinnerToUse, 'Butter', 'Olive Oil', 0.6);
      }

      // Update over budget status
      baseCost = currentCost;
      isOverBudget = baseCost > budget;
    }

    // If still over budget, suggest cheaper meal swaps
    if (isOverBudget) {
      if (lunchToUse.baseCostPerPerson > 90.0) {
        costSavingSuggestions.add('Alternative option: Swap Lunch ("${lunchToUse.name}") for "Dal Tadka with Steamed Rice" to save ₹${((lunchToUse.baseCostPerPerson - 50.0) * numPeople).toStringAsFixed(0)}.');
      }
      if (dinnerToUse.baseCostPerPerson > 90.0) {
        costSavingSuggestions.add('Alternative option: Swap Dinner ("${dinnerToUse.name}") for "Moong Dal Khichdi with Curd" to save ₹${((dinnerToUse.baseCostPerPerson - 40.0) * numPeople).toStringAsFixed(0)}.');
      }
      costSavingSuggestions.add('Your budget is extremely tight for the selected meals. Consider increasing your budget or scaling down the number of people.');
    }

    // 2. Generate Grocery List
    final groceryList = _generateGroceryList(
      breakfast: breakfastToUse,
      lunch: lunchToUse,
      dinner: dinnerToUse,
      numPeople: numPeople,
      availableIngredients: availableIngredients,
      substitutionsApplied: substitutionsApplied,
    );

    // Sum grocery costs of "Need To Buy" items
    double totalGroceryCost = 0.0;
    for (var item in groceryList) {
      if (item.needToBuy) {
        totalGroceryCost += item.estimatedCost;
      }
    }

    // 3. Generate Cooking To-Do List
    final todoList = _generateTodoList(
      breakfast: breakfastToUse,
      lunch: lunchToUse,
      dinner: dinnerToUse,
      groceryList: groceryList,
      substitutionsApplied: substitutionsApplied,
    );

    // Total metrics
    int totalCalories = (breakfastToUse.calories + lunchToUse.calories + dinnerToUse.calories) * numPeople;
    double budgetRemaining = budget - totalGroceryCost;

    // AI Context-based reasoning summary
    String plannerReasoning = _getRecommendationReasoning(dayType, dietaryPreference, cookingTimeAvailable, substitutionsApplied.isNotEmpty);

    return MealPlan(
      dayType: dayType,
      numPeople: numPeople,
      budget: budget,
      breakfast: breakfastToUse,
      lunch: lunchToUse,
      dinner: dinnerToUse,
      groceryList: groceryList,
      todoList: todoList,
      totalCalories: totalCalories,
      totalGroceryCost: totalGroceryCost,
      budgetRemaining: budgetRemaining,
      isOverBudget: totalGroceryCost > budget,
      substitutionsApplied: substitutionsApplied,
      costSavingSuggestions: costSavingSuggestions,
      recommendationReasoning: plannerReasoning,
    );
  }

  /// Check if meal tags match general dietary requirements
  bool _matchesDiet(Meal meal, String dietaryPreference) {
    if (dietaryPreference == 'vegan') {
      return meal.dietaryTag == 'vegan';
    }
    if (dietaryPreference == 'vegetarian') {
      return meal.dietaryTag == 'vegetarian' || meal.dietaryTag == 'vegan';
    }
    return true;
  }

  /// Score and select the highest matching meal in a category
  Meal _selectBestMeal(
    List<Meal> meals,
    String dayType,
    String dietaryPreference,
    List<String> availableIngredients,
    double targetCategoryBudget,
    int numPeople,
  ) {
    if (meals.isEmpty) {
      throw Exception('Meal list cannot be empty.');
    }

    Meal bestMeal = meals.first;
    double highestScore = -999.0;

    for (var meal in meals) {
      double score = 0.0;

      // 1. Day Type Match
      if (meal.suitableDayTypes.contains(dayType)) {
        score += 15.0;
      }

      // Day Type specific preferences
      if (dayType == 'Busy Workday' || dayType == 'Travel Day') {
        if (meal.prepTime <= 15) score += 10.0;
        if (meal.difficulty == 'Easy') score += 5.0;
      } else if (dayType == 'Weekend') {
        if (meal.prepTime >= 30) score += 8.0; // favor richer meals
      } else if (dayType == 'Gym Day') {
        if (meal.dietaryTag == 'high_protein') score += 20.0;
        // Check if high calories or protein characteristics
        if (meal.calories >= 400 && meal.type != 'breakfast') score += 5.0;
      }

      // 2. Dietary preference matching boost
      if (dietaryPreference == 'high_protein' && meal.dietaryTag == 'high_protein') {
        score += 15.0;
      }

      // 3. Available Ingredients Match
      int matchesCount = 0;
      for (var ing in meal.ingredients.keys) {
        final found = availableIngredients.any(
            (av) => av.trim().toLowerCase() == ing.trim().toLowerCase());
        if (found) {
          score += 6.0; // heavy reward for using available ingredients
          matchesCount++;
        }
      }

      // 4. Budget fit check (within allocated share)
      double mealCost = meal.baseCostPerPerson * numPeople;
      if (mealCost <= targetCategoryBudget) {
        score += 5.0;
      } else {
        // slight penalty if it exceeds target share
        score -= ((mealCost - targetCategoryBudget) / 10.0);
      }

      if (score > highestScore) {
        highestScore = score;
        bestMeal = meal;
      }
    }

    return bestMeal;
  }

  bool _containsIngredient(Meal b, Meal l, Meal d, String name) {
    return b.ingredients.containsKey(name) ||
        l.ingredients.containsKey(name) ||
        d.ingredients.containsKey(name);
  }

  /// Modifies meal properties (cost and ingredient name) to apply substitution local mapping
  Meal _substituteMealIngredient(Meal meal, String original, String substitute, double substituteUnitCost) {
    if (!meal.ingredients.containsKey(original)) {
      return meal;
    }

    // Clone ingredients and units
    final Map<String, double> newIngredients = Map.from(meal.ingredients);
    final Map<String, String> newUnits = Map.from(meal.ingredientUnits);

    final double qty = newIngredients.remove(original)!;
    final String unit = newUnits.remove(original)!;

    newIngredients[substitute] = qty;
    newUnits[substitute] = unit;

    // Recalculate cost savings
    final double originalItemCost = qty * (ingredientUnitCosts[original] ?? 0.0);
    final double substituteItemCost = qty * substituteUnitCost;
    final double costDiff = originalItemCost - substituteItemCost;

    // Ensure cost doesn't go below 0
    final double newBaseCost = double.parse(
        (meal.baseCostPerPerson - costDiff).toStringAsFixed(2)).clamp(0.0, 9999.0);

    return Meal(
      id: meal.id,
      name: meal.name,
      type: meal.type,
      calories: meal.calories,
      difficulty: meal.difficulty,
      prepTime: meal.prepTime,
      baseCostPerPerson: newBaseCost,
      dietaryTag: meal.dietaryTag,
      ingredients: newIngredients,
      ingredientUnits: newUnits,
      suitableDayTypes: meal.suitableDayTypes,
      reasoning: '${meal.reasoning} [Substituted $original with $substitute to save budget]',
    );
  }

  /// Generate Grocery Items categorized by Need to Buy / Already Available
  List<GroceryItem> _generateGroceryList({
    required Meal breakfast,
    required Meal lunch,
    required Meal dinner,
    required int numPeople,
    required List<String> availableIngredients,
    required Map<String, String> substitutionsApplied,
  }) {
    // Map to aggregate required ingredients
    // IngredientName -> {qty, unit}
    final Map<String, _IngredientAmount> aggregated = {};

    void addMealIngredients(Meal meal) {
      meal.ingredients.forEach((ing, qtyPerPerson) {
        final totalQty = qtyPerPerson * numPeople;
        final unit = meal.ingredientUnits[ing] ?? '';
        
        if (aggregated.containsKey(ing)) {
          aggregated[ing]!.quantity += totalQty;
        } else {
          aggregated[ing] = _IngredientAmount(totalQty, unit);
        }
      });
    }

    addMealIngredients(breakfast);
    addMealIngredients(lunch);
    addMealIngredients(dinner);

    final List<GroceryItem> list = [];

    aggregated.forEach((ing, amt) {
      // Check if available (case-insensitive match)
      final bool isAvailable = availableIngredients.any(
          (av) => av.trim().toLowerCase() == ing.trim().toLowerCase());

      double neededQty = amt.quantity;
      double availableQty = isAvailable ? neededQty : 0.0;
      bool needToBuy = !isAvailable;

      // Calculate estimated cost
      double unitCost = ingredientUnitCosts[ing] ?? 0.1; // fallback
      double estimatedCost = needToBuy ? (neededQty * unitCost) : 0.0;

      list.add(GroceryItem(
        name: ing,
        requiredQty: neededQty,
        availableQty: availableQty,
        unit: amt.unit,
        needToBuy: needToBuy,
        estimatedCost: double.parse(estimatedCost.toStringAsFixed(2)),
      ));
    });

    return list;
  }

  /// Generate dynamic checklist of steps
  List<TodoItem> _generateTodoList({
    required Meal breakfast,
    required Meal lunch,
    required Meal dinner,
    required List<GroceryItem> groceryList,
    required Map<String, String> substitutionsApplied,
  }) {
    final List<TodoItem> items = [];
    int idCounter = 1;

    // Helper to add item
    void addItem(String title) {
      items.add(TodoItem(id: 'todo_${idCounter++}', title: title));
    }

    // 1. Initial Checks
    addItem('Verify available ingredients in kitchen cabinets');

    // 2. Shopping
    final needToBuyItems = groceryList.where((item) => item.needToBuy).map((item) => item.name).toList();
    if (needToBuyItems.isNotEmpty) {
      addItem('Buy ingredients from grocery store: ${needToBuyItems.join(", ")}');
    }

    // 3. Substitution checks
    substitutionsApplied.forEach((original, substitute) {
      addItem('Confirm substitution: Prepare $substitute as a replacement for $original');
    });

    // 4. Meal prep & cook
    // Breakfast
    addItem('Prepare breakfast ingredients for "${breakfast.name}"');
    addItem('Cook breakfast: "${breakfast.name}" (${breakfast.prepTime} min)');

    // Lunch
    addItem('Prepare lunch ingredients for "${lunch.name}"');
    if (lunch.difficulty == 'Hard') {
      addItem('Begin early lunch prep: Marinate/soak required items for "${lunch.name}"');
    }
    addItem('Cook lunch: "${lunch.name}" (${lunch.prepTime} min)');

    // Dinner
    addItem('Prepare dinner ingredients for "${dinner.name}"');
    addItem('Cook dinner: "${dinner.name}" (${dinner.prepTime} min)');

    // 5. Cleanup
    addItem('Store dinner leftovers and tidy up the kitchen workspace');

    return items;
  }

  /// Generate AI narrative reasoning text
  String _getRecommendationReasoning(String dayType, String dietaryPreference, int timeLimit, bool subsApplied) {
    String buffer = 'Selected these meals because ';
    if (dayType == 'Busy Workday') {
      buffer += 'you have a busy work schedule, so we prioritized rapid, easy-to-cook meals under ${timeLimit}m.';
    } else if (dayType == 'Gym Day') {
      buffer += 'it is a training day, so we maximized high-protein items to support muscle recovery and nutrition.';
    } else if (dayType == 'Weekend') {
      buffer += 'it is the weekend, so we selected more satisfying, rich meals that you can cook at your leisure.';
    } else if (dayType == 'Travel Day') {
      buffer += 'you are traveling, choosing highly portable, fast, low-effort breakfasts and lunches.';
    } else {
      buffer += 'they match your active schedule and fit within your ${timeLimit}m cooking time limit.';
    }

    if (dietaryPreference != 'non_vegetarian') {
      buffer += ' Filtered strictly for a $dietaryPreference diet.';
    }
    if (subsApplied) {
      buffer += ' Smart substitutions have been applied automatically to fit your budget.';
    }

    return buffer;
  }
}

class _IngredientAmount {
  double quantity;
  final String unit;

  _IngredientAmount(this.quantity, this.unit);
}

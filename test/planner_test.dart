import 'package:flutter_test/flutter_test.dart';
import 'package:smartmeal_ai/domain/models/meal.dart';
import 'package:smartmeal_ai/domain/services/planner_service.dart';

void main() {
  group('SmartMeal AI Planner Service Tests', () {
    late PlannerService plannerService;
    late List<Meal> mockMeals;

    setUp(() {
      plannerService = PlannerService();
      
      mockMeals = [
        // Breakfasts
        const Meal(
          id: 'b1',
          name: 'Vegan Oats',
          type: 'breakfast',
          calories: 300,
          difficulty: 'Easy',
          prepTime: 15,
          baseCostPerPerson: 50.0,
          dietaryTag: 'vegan',
          ingredients: {'Oats': 50, 'Milk': 100},
          ingredientUnits: {'Oats': 'g', 'Milk': 'ml'},
          suitableDayTypes: ['Busy Workday', 'Gym Day'],
          reasoning: 'Quick oats',
        ),
        const Meal(
          id: 'b2',
          name: 'Eggs and Toast',
          type: 'breakfast',
          calories: 350,
          difficulty: 'Easy',
          prepTime: 15,
          baseCostPerPerson: 40.0,
          dietaryTag: 'high_protein',
          ingredients: {'Eggs': 2, 'Bread': 2, 'Butter': 10},
          ingredientUnits: {'Eggs': 'pcs', 'Bread': 'pcs', 'Butter': 'g'},
          suitableDayTypes: ['Gym Day'],
          reasoning: 'Protein breakfast',
        ),
        const Meal(
          id: 'b3',
          name: 'Elaborate Waffles',
          type: 'breakfast',
          calories: 450,
          difficulty: 'Medium',
          prepTime: 30,
          baseCostPerPerson: 60.0,
          dietaryTag: 'vegetarian',
          ingredients: {'Flour': 100, 'Milk': 150},
          ingredientUnits: {'Flour': 'g', 'Milk': 'ml'},
          suitableDayTypes: ['Weekend'],
          reasoning: 'Slow breakfast',
        ),

        // Lunches
        const Meal(
          id: 'l1',
          name: 'Veg Rice',
          type: 'lunch',
          calories: 450,
          difficulty: 'Easy',
          prepTime: 15,
          baseCostPerPerson: 40.0,
          dietaryTag: 'vegan',
          ingredients: {'Rice': 100, 'Onion': 1},
          ingredientUnits: {'Rice': 'g', 'Onion': 'pcs'},
          suitableDayTypes: ['Busy Workday'],
          reasoning: 'Vegan rice',
        ),
        const Meal(
          id: 'l2',
          name: 'Paneer Butter Masala',
          type: 'lunch',
          calories: 600,
          difficulty: 'Medium',
          prepTime: 30,
          baseCostPerPerson: 120.0,
          dietaryTag: 'vegetarian',
          ingredients: {'Paneer': 100, 'Butter': 20, 'Tomato': 1},
          ingredientUnits: {'Paneer': 'g', 'Butter': 'g', 'Tomato': 'pcs'},
          suitableDayTypes: ['Weekend', 'Work From Home'],
          reasoning: 'Paneer lunch',
        ),
        const Meal(
          id: 'l3',
          name: 'Chicken Rice',
          type: 'lunch',
          calories: 550,
          difficulty: 'Easy',
          prepTime: 30,
          baseCostPerPerson: 150.0,
          dietaryTag: 'non_vegetarian',
          ingredients: {'Chicken': 150, 'Rice': 100},
          ingredientUnits: {'Chicken': 'g', 'Rice': 'g'},
          suitableDayTypes: ['Gym Day'],
          reasoning: 'Non-veg protein',
        ),

        // Dinners
        const Meal(
          id: 'd1',
          name: 'Simple Soup',
          type: 'dinner',
          calories: 300,
          difficulty: 'Easy',
          prepTime: 15,
          baseCostPerPerson: 35.0,
          dietaryTag: 'vegan',
          ingredients: {'Brown Lentils': 80},
          ingredientUnits: {'Brown Lentils': 'g'},
          suitableDayTypes: ['Busy Workday', 'Travel Day'],
          reasoning: 'Easy soup',
        ),
        const Meal(
          id: 'd2',
          name: 'Premium Paneer Curry',
          type: 'dinner',
          calories: 500,
          difficulty: 'Medium',
          prepTime: 30,
          baseCostPerPerson: 130.0,
          dietaryTag: 'vegetarian',
          ingredients: {'Paneer': 100, 'Butter': 15},
          ingredientUnits: {'Paneer': 'g', 'Butter': 'g'},
          suitableDayTypes: ['Gym Day', 'Weekend'],
          reasoning: 'Rich dinner',
        ),
        const Meal(
          id: 'd3',
          name: 'Elaborate Mutton',
          type: 'dinner',
          calories: 700,
          difficulty: 'Hard',
          prepTime: 60,
          baseCostPerPerson: 250.0,
          dietaryTag: 'non_vegetarian',
          ingredients: {'Mutton': 150},
          ingredientUnits: {'Mutton': 'g'},
          suitableDayTypes: ['Weekend'],
          reasoning: 'Weekend mutton dinner',
        ),
      ];
    });

    test('1. Meal Planner tag filtering matches dietary preference', () {
      // Vegan diet must only select Vegan meals
      final plan = plannerService.generatePlan(
        allMeals: mockMeals,
        dayType: 'Busy Workday',
        numPeople: 1,
        budget: 1000,
        dietaryPreference: 'vegan',
        availableIngredients: [],
        cookingTimeAvailable: 60,
      );

      expect(plan.breakfast.dietaryTag, equals('vegan'));
      expect(plan.lunch.dietaryTag, equals('vegan'));
      expect(plan.dinner.dietaryTag, equals('vegan'));

      // Vegetarian diet can select vegetarian or vegan, but NOT non_vegetarian
      final planVeg = plannerService.generatePlan(
        allMeals: mockMeals,
        dayType: 'Weekend',
        numPeople: 1,
        budget: 1000,
        dietaryPreference: 'vegetarian',
        availableIngredients: [],
        cookingTimeAvailable: 60,
      );
      expect(planVeg.breakfast.dietaryTag, anyOf(equals('vegan'), equals('vegetarian')));
      expect(planVeg.lunch.dietaryTag, anyOf(equals('vegan'), equals('vegetarian')));
      expect(planVeg.dinner.dietaryTag, anyOf(equals('vegan'), equals('vegetarian')));
    });

    test('2. Cooking time constraints are respected', () {
      // Limit cooking time to 15 mins. Meals exceeding 15 mins should not be selected if possible.
      final plan = plannerService.generatePlan(
        allMeals: mockMeals,
        dayType: 'Busy Workday',
        numPeople: 1,
        budget: 1000,
        dietaryPreference: 'non_vegetarian',
        availableIngredients: [],
        cookingTimeAvailable: 15,
      );

      expect(plan.breakfast.prepTime, lessThanOrEqualTo(15));
      expect(plan.lunch.prepTime, lessThanOrEqualTo(15));
      expect(plan.dinner.prepTime, lessThanOrEqualTo(15));
    });

    test('3. Budget Feasibility Logic flags over-budget status', () {
      // Let's set a tiny budget of ₹50. The raw cost of mockMeals (e.g. Oats ₹50 + Veg Rice ₹40 + Simple Soup ₹35 = ₹125)
      // will be way higher, making it over-budget.
      final plan = plannerService.generatePlan(
        allMeals: mockMeals,
        dayType: 'Busy Workday',
        numPeople: 2,
        budget: 50,
        dietaryPreference: 'vegan',
        availableIngredients: [],
        cookingTimeAvailable: 30,
      );

      // Check budget calculation is correct
      expect(plan.budget, equals(50.0));
      // Grocery total cost scales for 2 people
      expect(plan.isOverBudget, isTrue);
      expect(plan.costSavingSuggestions, isNotEmpty);
    });

    test('4. Grocery list splits Available vs Need To Buy and scales quantities', () {
      // Specify owned ingredients: Oats & Rice
      final plan = plannerService.generatePlan(
        allMeals: mockMeals,
        dayType: 'Busy Workday',
        numPeople: 3, // 3 people scale
        budget: 1000,
        dietaryPreference: 'vegan',
        availableIngredients: ['Oats', 'Rice'],
        cookingTimeAvailable: 30,
      );

      final oatsGrocery = plan.groceryList.firstWhere((e) => e.name == 'Oats');
      final riceGrocery = plan.groceryList.firstWhere((e) => e.name == 'Rice');
      final milkGrocery = plan.groceryList.firstWhere((e) => e.name == 'Milk');

      // Oats and Rice should be marked as already available (needToBuy = false)
      expect(oatsGrocery.needToBuy, isFalse);
      expect(riceGrocery.needToBuy, isFalse);
      
      // Milk was not available, so it is Need to Buy
      expect(milkGrocery.needToBuy, isTrue);

      // Verify scaled quantities: Oats base is 50g per person * 3 people = 150g
      expect(oatsGrocery.requiredQty, equals(150.0));
      expect(milkGrocery.requiredQty, equals(300.0));
    });

    test('5. Smart Substitution Engine swaps expensive items and reduces costs', () {
      // Trigger a situation where budget is slightly tight, forcing Paneer to Tofu substitution.
      // Selected menu: b2 (Eggs & Toast - ₹40), l2 (Paneer Butter Masala - ₹120), d2 (Premium Paneer Curry - ₹130).
      // Base cost for 2 people = (40 + 120 + 130) * 2 = 290 * 2 = ₹580.
      // If we set budget to ₹500, we are over budget.
      // The engine should substitute Paneer with Tofu, which reduces Paneer Butter Masala cost and Premium Paneer Curry cost.
      final plan = plannerService.generatePlan(
        allMeals: mockMeals,
        dayType: 'Weekend',
        numPeople: 2,
        budget: 500.0,
        dietaryPreference: 'vegetarian',
        availableIngredients: [],
        cookingTimeAvailable: 30,
      );

      // Check if substitution was triggered
      expect(plan.substitutionsApplied.containsKey('Paneer'), isTrue);
      expect(plan.substitutionsApplied['Paneer'], equals('Tofu'));
      
      // Paneer is swapped in ingredients list of lunch and dinner to Tofu
      expect(plan.lunch.ingredients.containsKey('Tofu'), isTrue);
      expect(plan.lunch.ingredients.containsKey('Paneer'), isFalse);
      expect(plan.dinner.ingredients.containsKey('Tofu'), isTrue);
      expect(plan.dinner.ingredients.containsKey('Paneer'), isFalse);
    });
  });
}

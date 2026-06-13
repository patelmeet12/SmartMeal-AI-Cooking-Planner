import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/meal_plan.dart';
import '../../domain/models/todo_item.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/planner_repository.dart';
import '../../domain/services/planner_service.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/repositories/planner_repository_impl.dart';
import 'theme_provider.dart';

// State definition
class PlannerState {
  final String dayType;
  final int numPeople;
  final double budget;
  final String dietaryPreference;
  final List<String> availableIngredients;
  final int cookingTimeAvailable;
  final MealPlan? currentPlan;
  final bool isLoading;
  final String errorMessage;
  final int activeTab; // 0: Summary, 1: Meal details, 2: Grocery list, 3: Checklist

  const PlannerState({
    required this.dayType,
    required this.numPeople,
    required this.budget,
    required this.dietaryPreference,
    required this.availableIngredients,
    required this.cookingTimeAvailable,
    this.currentPlan,
    this.isLoading = false,
    this.errorMessage = '',
    this.activeTab = 0,
  });

  PlannerState copyWith({
    String? dayType,
    int? numPeople,
    double? budget,
    String? dietaryPreference,
    List<String>? availableIngredients,
    int? cookingTimeAvailable,
    MealPlan? currentPlan,
    bool? isLoading,
    String? errorMessage,
    int? activeTab,
    bool clearPlan = false,
  }) {
    return PlannerState(
      dayType: dayType ?? this.dayType,
      numPeople: numPeople ?? this.numPeople,
      budget: budget ?? this.budget,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      availableIngredients: availableIngredients ?? this.availableIngredients,
      cookingTimeAvailable: cookingTimeAvailable ?? this.cookingTimeAvailable,
      currentPlan: clearPlan ? null : (currentPlan ?? this.currentPlan),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

// Providers
final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl();
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlannerRepositoryImpl(prefs);
});

final plannerServiceProvider = Provider<PlannerService>((ref) {
  return PlannerService();
});

final plannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  final mealRepo = ref.watch(mealRepositoryProvider);
  final planRepo = ref.watch(plannerRepositoryProvider);
  final service = ref.watch(plannerServiceProvider);
  return PlannerNotifier(mealRepo, planRepo, service);
});

// Notifier Implementation
class PlannerNotifier extends StateNotifier<PlannerState> {
  final MealRepository _mealRepo;
  final PlannerRepository _planRepo;
  final PlannerService _service;

  PlannerNotifier(this._mealRepo, this._planRepo, this._service)
      : super(const PlannerState(
          dayType: 'Busy Workday',
          numPeople: 2,
          budget: 500.0,
          dietaryPreference: 'vegetarian',
          availableIngredients: [],
          cookingTimeAvailable: 30,
        )) {
    loadPersistedPlan();
  }

  void updateDayType(String dayType) {
    state = state.copyWith(dayType: dayType);
  }

  void updateNumPeople(int numPeople) {
    state = state.copyWith(numPeople: numPeople);
  }

  void updateBudget(double budget) {
    state = state.copyWith(budget: budget);
  }

  void updateDietaryPreference(String preference) {
    state = state.copyWith(dietaryPreference: preference);
  }

  void updateCookingTimeAvailable(int minutes) {
    state = state.copyWith(cookingTimeAvailable: minutes);
  }

  void addAvailableIngredient(String ingredient) {
    final clean = ingredient.trim();
    if (clean.isEmpty) return;
    
    // Avoid duplicates
    if (state.availableIngredients.any((e) => e.toLowerCase() == clean.toLowerCase())) {
      return;
    }

    state = state.copyWith(
      availableIngredients: [...state.availableIngredients, clean],
    );
  }

  void removeAvailableIngredient(String ingredient) {
    state = state.copyWith(
      availableIngredients:
          state.availableIngredients.where((e) => e != ingredient).toList(),
    );
  }

  void changeTab(int tabIndex) {
    state = state.copyWith(activeTab: tabIndex);
  }

  /// Run local AI generation and save the result
  void generatePlan() {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final allMeals = _mealRepo.getStaticMeals();
      
      final plan = _service.generatePlan(
        allMeals: allMeals,
        dayType: state.dayType,
        numPeople: state.numPeople,
        budget: state.budget,
        dietaryPreference: state.dietaryPreference,
        availableIngredients: state.availableIngredients,
        cookingTimeAvailable: state.cookingTimeAvailable,
      );

      state = state.copyWith(currentPlan: plan, isLoading: false, activeTab: 0);
      _planRepo.saveCurrentPlan(plan);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Toggle checklist items
  void toggleTodo(String todoId) {
    final currentPlan = state.currentPlan;
    if (currentPlan == null) return;

    final updatedTodos = currentPlan.todoList.map((item) {
      if (item.id == todoId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    final updatedPlan = currentPlan.copyWith(todoList: updatedTodos);
    state = state.copyWith(currentPlan: updatedPlan);
    _planRepo.saveCurrentPlan(updatedPlan);
  }

  /// Clear current plan to generate a new one
  void clearPlan() {
    state = state.copyWith(clearPlan: true, activeTab: 0);
    _planRepo.clearCurrentPlan();
  }

  /// Load plan on startup
  Future<void> loadPersistedPlan() async {
    final plan = await _planRepo.loadCurrentPlan();
    if (plan != null) {
      state = state.copyWith(
        currentPlan: plan,
        dayType: plan.dayType,
        numPeople: plan.numPeople,
        budget: plan.budget,
        // Since we restore the plan, we can populate initial settings from it if available
      );
    }
  }
}

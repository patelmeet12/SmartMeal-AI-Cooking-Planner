import '../models/meal_plan.dart';

abstract class PlannerRepository {
  Future<void> saveCurrentPlan(MealPlan plan);
  Future<MealPlan?> loadCurrentPlan();
  Future<void> clearCurrentPlan();
}

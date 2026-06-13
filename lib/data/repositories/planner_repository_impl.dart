import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/meal_plan.dart';
import '../../domain/repositories/planner_repository.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final SharedPreferences _prefs;
  static const _currentPlanKey = 'current_meal_plan';

  PlannerRepositoryImpl(this._prefs);

  @override
  Future<void> saveCurrentPlan(MealPlan plan) async {
    final jsonStr = jsonEncode(plan.toJson());
    await _prefs.setString(_currentPlanKey, jsonStr);
  }

  @override
  Future<MealPlan?> loadCurrentPlan() async {
    final jsonStr = _prefs.getString(_currentPlanKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return MealPlan.fromJson(jsonMap);
    } catch (_) {
      return null; // Fallback if format is corrupted
    }
  }

  @override
  Future<void> clearCurrentPlan() async {
    await _prefs.remove(_currentPlanKey);
  }
}

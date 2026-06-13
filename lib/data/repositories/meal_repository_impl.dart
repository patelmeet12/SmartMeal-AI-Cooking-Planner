import '../../domain/models/meal.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/static_meals.dart';

class MealRepositoryImpl implements MealRepository {
  @override
  List<Meal> getStaticMeals() {
    return StaticMeals.meals;
  }
}

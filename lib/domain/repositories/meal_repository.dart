import '../models/meal.dart';

abstract class MealRepository {
  List<Meal> getStaticMeals();
}

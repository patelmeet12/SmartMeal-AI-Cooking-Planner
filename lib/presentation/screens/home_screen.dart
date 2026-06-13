import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/planner_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientController = TextEditingController();
  final _budgetController = TextEditingController(text: '500');

  @override
  void dispose() {
    _ingredientController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if there is already a generated plan; if so, redirect immediately to dashboard
    if (state.currentPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'SmartMeal AI',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Semantics(
              label: 'SmartMeal Planner Configuration Form',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Section
                    Text(
                      'Plan your day’s cooking.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.0,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a personalized cooking to-do list, optimized grocery list, and smart substitutions matching your budget.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Setup Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Type
                            const Text(
                              'What does your day look like?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: state.dayType,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Busy Workday', child: Text('Busy Workday (Quick meals)')),
                                DropdownMenuItem(value: 'Office Day', child: Text('Office Day (Packable lunch)')),
                                DropdownMenuItem(value: 'Work From Home', child: Text('Work From Home (Balanced prep)')),
                                DropdownMenuItem(value: 'Weekend', child: Text('Weekend (Elaborate meals)')),
                                DropdownMenuItem(value: 'Gym Day', child: Text('Gym Day (High protein energy)')),
                                DropdownMenuItem(value: 'Travel Day', child: Text('Travel Day (Low prep & simple)')),
                              ],
                              onChanged: (val) {
                                if (val != null) notifier.updateDayType(val);
                              },
                            ),
                            const SizedBox(height: 24),

                            // Numbers of People
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Number of People',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Scales ingredients & costs',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: state.numPeople > 1
                                          ? () => notifier.updateNumPeople(state.numPeople - 1)
                                          : null,
                                    ),
                                    Text(
                                      '${state.numPeople}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: state.numPeople < 10
                                          ? () => notifier.updateNumPeople(state.numPeople + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 32),

                            // Dietary Preference
                            const Text(
                              'Dietary Preference',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildDietOption('vegetarian', 'Veg', Icons.eco_outlined, state, notifier),
                                const SizedBox(width: 8),
                                _buildDietOption('vegan', 'Vegan', Icons.grass_outlined, state, notifier),
                                const SizedBox(width: 8),
                                _buildDietOption('high_protein', 'Protein+', Icons.fitness_center_outlined, state, notifier),
                                const SizedBox(width: 8),
                                _buildDietOption('non_vegetarian', 'Any', Icons.restaurant_outlined, state, notifier),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Cooking Time Available
                            const Text(
                              'Maximum prep/cooking time per meal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildTimeOption(15, '15 min', state, notifier),
                                const SizedBox(width: 8),
                                _buildTimeOption(30, '30 min', state, notifier),
                                const SizedBox(width: 8),
                                _buildTimeOption(60, '60 min', state, notifier),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Budget input
                            const Text(
                              'Daily food budget (₹)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                hintText: 'Enter total budget',
                                helperText: 'Example: ₹500 is common for 2 people',
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Budget is required';
                                final num = double.tryParse(val);
                                if (num == null || num <= 0) return 'Enter a valid amount';
                                return null;
                              },
                              onChanged: (val) {
                                final num = double.tryParse(val);
                                if (num != null) notifier.updateBudget(num);
                              },
                            ),
                            const SizedBox(height: 24),

                            // Available Ingredients
                            const Text(
                              'What ingredients do you already have?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              'We will try to use these to minimize shopping and costs.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ingredientController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g., Rice, Onion, Tomato',
                                    ),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        notifier.addAvailableIngredient(val);
                                        _ingredientController.clear();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_ingredientController.text.trim().isNotEmpty) {
                                      notifier.addAvailableIngredient(_ingredientController.text);
                                      _ingredientController.clear();
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Chip list
                            if (state.availableIngredients.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No ingredients added. (We will assume you need to buy all ingredients).',
                                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.availableIngredients.map((ing) {
                                  return Chip(
                                    label: Text(ing),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () => notifier.removeAvailableIngredient(ing),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: state.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                notifier.generatePlan();
                              }
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Generate Cooking Plan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDietOption(
    String tag,
    String label,
    IconData icon,
    PlannerState state,
    PlannerNotifier notifier,
  ) {
    final isSelected = state.dietaryPreference == tag;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () => notifier.updateDietaryPreference(tag),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
            border: Border.all(
              color: isSelected ? colorScheme.primary : Theme.of(context).dividerColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(
    int minutes,
    String label,
    PlannerState state,
    PlannerNotifier notifier,
  ) {
    final isSelected = state.cookingTimeAvailable == minutes;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () => notifier.updateCookingTimeAvailable(minutes),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
            border: Border.all(
              color: isSelected ? colorScheme.primary : Theme.of(context).dividerColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

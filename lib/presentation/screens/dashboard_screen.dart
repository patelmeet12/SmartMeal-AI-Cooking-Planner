import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/planner_provider.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/grocery_item.dart';
import '../../domain/models/todo_item.dart';
import '../../domain/models/meal_plan.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Redirect to home if there is no current plan
    if (state.currentPlan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = state.currentPlan!;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 900;
          
          if (isLargeScreen) {
            return Row(
              children: [
                // Sidebar Navigation (Desktop)
                _buildSidebar(context, state, notifier, isDark),
                const VerticalDivider(width: 1),
                // Main Content Pane
                Expanded(
                  child: Scaffold(
                    appBar: _buildAppBar(context, state, notifier, isDark, ref, showMenuButton: false),
                    body: _buildSelectedTabContent(context, state, plan),
                  ),
                ),
              ],
            );
          } else {
            // Mobile navigation layout
            return Scaffold(
              appBar: _buildAppBar(context, state, notifier, isDark, ref, showMenuButton: true),
              drawer: Drawer(
                child: _buildSidebar(context, state, notifier, isDark),
              ),
              body: _buildSelectedTabContent(context, state, plan),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: state.activeTab,
                onTap: (idx) => notifier.changeTab(idx),
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                  BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), label: 'Meals'),
                  BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Grocery'),
                  BottomNavigationBarItem(icon: Icon(Icons.checklist_outlined), label: 'Checklist'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PlannerState state,
    PlannerNotifier notifier,
    bool isDark,
    WidgetRef ref, {
    required bool showMenuButton,
  }) {
    String tabTitle = 'Dashboard';
    switch (state.activeTab) {
      case 0:
        tabTitle = 'Overview';
        break;
      case 1:
        tabTitle = 'Meal Plan';
        break;
      case 2:
        tabTitle = 'Grocery List';
        break;
      case 3:
        tabTitle = 'Cooking To-Do';
        break;
    }

    return AppBar(
      title: Text(
        tabTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: showMenuButton
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          tooltip: 'Toggle Theme',
          onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    PlannerState state,
    PlannerNotifier notifier,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      color: isDark ? const Color(0xFF131314) : const Color(0xFFF9FAFB),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sidebar Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'SmartMeal AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Navigation Options
            const SizedBox(height: 16),
            _buildSidebarNavItem(context, 0, 'Overview', Icons.dashboard_outlined, state, notifier),
            _buildSidebarNavItem(context, 1, 'Meal Plan', Icons.restaurant_outlined, state, notifier),
            _buildSidebarNavItem(context, 2, 'Grocery List', Icons.shopping_cart_outlined, state, notifier),
            _buildSidebarNavItem(context, 3, 'Cooking To-Do', Icons.checklist_outlined, state, notifier),

            const Spacer(),
            const Divider(height: 1),

            // Active Config Info Summary
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1F) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE PROFILE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildConfigLabel(Icons.calendar_today, state.dayType),
                    const SizedBox(height: 4),
                    _buildConfigLabel(Icons.people_outline, '${state.numPeople} People'),
                    const SizedBox(height: 4),
                    _buildConfigLabel(Icons.eco_outlined, state.dietaryPreference.toUpperCase()),
                    const SizedBox(height: 4),
                    _buildConfigLabel(Icons.access_time, '${state.cookingTimeAvailable}m max prep'),
                    const SizedBox(height: 4),
                    _buildConfigLabel(Icons.wallet, 'Budget: ₹${state.budget.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),

            // Reset Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  notifier.clearPlan();
                  context.go('/');
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 8),
                    Text('Plan New Day'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarNavItem(
    BuildContext context,
    int index,
    String title,
    IconData icon,
    PlannerState state,
    PlannerNotifier notifier,
  ) {
    final isSelected = state.activeTab == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: InkWell(
        onTap: () {
          notifier.changeTab(index);
          // Close drawer on mobile if open
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(BuildContext context, PlannerState state, MealPlan plan) {
    switch (state.activeTab) {
      case 0:
        return _buildOverviewTab(context, plan);
      case 1:
        return _buildMealPlanTab(context, plan);
      case 2:
        return _buildGroceryTab(context, plan, ref: null); // We will watch from consumer widget logic or pass provider context
      case 3:
        return _buildChecklistTab(context, plan);
      default:
        return const Center(child: Text('Invalid View'));
    }
  }

  // ================= TABS CONTENT IMPLEMENTATIONS =================

  // 1. OVERVIEW TAB
  Widget _buildOverviewTab(BuildContext context, MealPlan plan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverBudget = plan.isOverBudget;
    
    // Status text details
    final statusColor = isOverBudget ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final statusText = isOverBudget ? 'Over Budget' : 'Within Budget';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Reasoning
          Text(
            'Welcome to your day’s plan.',
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      plan.recommendationReasoning,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Dashboard Metrics Cards
          Text(
            'Meal Summary Dashboard',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              final crossAxisCount = width > 600 ? 4 : 2;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: width > 600 ? 1.4 : 1.5,
                ),
                children: [
                  _buildMetricCard(
                    context,
                    'Total Meals',
                    '3 Meals',
                    'B, L, D generated',
                    Icons.restaurant_menu,
                  ),
                  _buildMetricCard(
                    context,
                    'Total Calories',
                    '${plan.totalCalories} kcal',
                    'For ${plan.numPeople} people',
                    Icons.local_fire_department_outlined,
                  ),
                  _buildMetricCard(
                    context,
                    'Grocery Cost',
                    '₹${plan.totalGroceryCost.toStringAsFixed(0)}',
                    'To purchase items',
                    Icons.shopping_bag_outlined,
                  ),
                  _buildMetricCard(
                    context,
                    'Budget Remaining',
                    '₹${plan.budgetRemaining.toStringAsFixed(0)}',
                    isOverBudget ? 'Over limit' : 'Leftover funds',
                    Icons.wallet,
                    valueColor: plan.budgetRemaining < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Budget Feasibility Gauge
          Text(
            'Budget Feasibility Analysis',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BUDGET VS ESTIMATED COST',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grocery Cost: ₹${plan.totalGroceryCost.toStringAsFixed(2)} / Budget: ₹${plan.budget.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: plan.budget > 0 
                          ? (plan.totalGroceryCost / plan.budget).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 12,
                      backgroundColor: theme.dividerColor,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Applied Substitutions / Cost savings suggestions
                  if (plan.substitutionsApplied.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Smart Substitutions Applied (Local AI Engine)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: plan.substitutionsApplied.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.key} → ${entry.value}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (plan.costSavingSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Cost Saving Suggestions:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...plan.costSavingSuggestions.map((sug) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sug,
                                  style: const TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: colorScheme.primary),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 2. MEAL PLAN TAB
  Widget _buildMealPlanTab(BuildContext context, MealPlan plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 800;
          if (isLarge) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMealCard(context, 'Breakfast', plan.breakfast, plan)),
                const SizedBox(width: 16),
                Expanded(child: _buildMealCard(context, 'Lunch', plan.lunch, plan)),
                const SizedBox(width: 16),
                Expanded(child: _buildMealCard(context, 'Dinner', plan.dinner, plan)),
              ],
            );
          } else {
            return Column(
              children: [
                _buildMealCard(context, 'Breakfast', plan.breakfast, plan),
                const SizedBox(height: 16),
                _buildMealCard(context, 'Lunch', plan.lunch, plan),
                const SizedBox(height: 16),
                _buildMealCard(context, 'Dinner', plan.dinner, plan),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, String title, Meal meal, MealPlan plan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Difficulty color coding
    Color difficultyColor;
    switch (meal.difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = const Color(0xFF10B981);
        break;
      case 'medium':
        difficultyColor = const Color(0xFFF59E0B);
        break;
      case 'hard':
        difficultyColor = const Color(0xFFEF4444);
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category title & Difficulty badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: difficultyColor, width: 0.5),
                  ),
                  child: Text(
                    meal.difficulty,
                    style: TextStyle(color: difficultyColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meal Name
            Text(
              meal.name,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Key info (Time, Calories, Cost)
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${meal.prepTime} min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${meal.calories} kcal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.wallet, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('₹${meal.baseCostPerPerson * plan.numPeople} total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),

            // Ingredients Scaled
            const Text(
              'Required Ingredients',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...meal.ingredients.entries.map((entry) {
              String? originalIngredient;
              plan.substitutionsApplied.forEach((key, value) {
                if (value == entry.key) {
                  originalIngredient = key;
                }
              });
              final hasSubApplied = originalIngredient != null;
              final unit = meal.ingredientUnits[entry.key] ?? '';
              final ingredientLabel = hasSubApplied
                  ? '${entry.key} (substituted for $originalIngredient)'
                  : entry.key;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 5, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$ingredientLabel (${(entry.value * plan.numPeople).toStringAsFixed(0)} $unit)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasSubApplied ? FontWeight.bold : FontWeight.normal,
                          color: hasSubApplied ? Colors.orange : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (hasSubApplied)
                      const Text(
                        'SUBSTITUTE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),

            // Selection Reasoning
            const Text(
              'AI Selector Reasoning',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              meal.reasoning,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // 3. GROCERY TAB (Needs consumer to toggle/watch state)
  Widget _buildGroceryTab(BuildContext context, MealPlan plan, {required dynamic ref}) {
    // We wrap inside a Consumer to enable ticking of groceries if needed,
    // though the prompt doesn't strictly require grocery checklist state updates,
    // we want a premium, high-quality visual.
    return Consumer(
      builder: (context, ref, child) {
        final currentPlan = ref.watch(plannerProvider).currentPlan!;
        final available = currentPlan.groceryList.where((e) => !e.needToBuy).toList();
        final toBuy = currentPlan.groceryList.where((e) => e.needToBuy).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scaled Grocery Checklist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Comparing required ingredients scaled by number of people against available items.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Need To Buy Section
              _buildGroceryCategory(
                context,
                'NEED TO BUY',
                toBuy,
                color: const Color(0xFFEF4444),
                icon: Icons.shopping_cart_outlined,
              ),

              const SizedBox(height: 24),

              // Already Available Section
              _buildGroceryCategory(
                context,
                'ALREADY AVAILABLE',
                available,
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroceryCategory(
    BuildContext context,
    String title,
    List<GroceryItem> items, {
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, letterSpacing: 0.5),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No ingredients in this category.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        item.needToBuy ? Icons.radio_button_unchecked : Icons.check_circle,
                        color: item.needToBuy ? Colors.grey : const Color(0xFF10B981),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: item.needToBuy ? null : TextDecoration.lineThrough,
                            color: item.needToBuy ? null : Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        '${item.requiredQty.toStringAsFixed(0)} ${item.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (item.needToBuy) ...[
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '₹${item.estimatedCost.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // 4. CHECKLIST TAB
  Widget _buildChecklistTab(BuildContext context, MealPlan plan) {
    return Consumer(
      builder: (context, ref, child) {
        final currentPlan = ref.watch(plannerProvider).currentPlan!;
        final list = currentPlan.todoList;
        
        final completedCount = list.where((e) => e.isCompleted).length;
        final totalCount = list.length;
        final percent = totalCount > 0 ? (completedCount / totalCount) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step-by-Step Cooking Checklist',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
              ),
              const Text(
                'Check items off as you perform them. Progress is saved locally.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Progress Bar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress: $completedCount of $totalCount steps completed',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                color: Theme.of(context).colorScheme.primary,
                                backgroundColor: Theme.of(context).dividerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Checklist Items
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return CheckboxListTile(
                      value: item.isCompleted,
                      title: Text(
                        item.title,
                        style: TextStyle(
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          color: item.isCompleted ? Colors.grey : null,
                          fontSize: 14,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) {
                        ref.read(plannerProvider.notifier).toggleTodo(item.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

# SmartMeal AI - Cooking Planner

SmartMeal AI is a premium Flutter Web micro-app that functions as a client-side personal cooking assistant. Rather than showing a generic recipe repository, it generates an end-to-end plan (customized meals, interactive checklists, categorized grocery lists, budget metrics, and smart substitutions) tailored specifically to a user's day schedule, budget constraints, dietary parameters, and available ingredients.

---

## 📖 Problem Statement

Cooking at home presents multiple friction points every single day:
1. **Decision Fatigue**: What should I cook today based on whether I am working from home, traveling, or training at the gym?
2. **Time Mismatches**: Recommending elaborate recipes on a busy office workday leads to planning failures.
3. **Financial Constraints**: Recipes rarely scale by head-count or verify if they fit a specific daily monetary budget.
4. **Grocery Waste**: Not matching plan ingredients against already available kitchen supplies leads to redundant purchasing.
5. **No AI APIs / Privacy**: Planning tools should work instantly offline, client-side, and protect user data without relying on heavy backend cloud calls.

---

## 🛠️ Solution Approach

SmartMeal AI addresses these challenges with a client-only local architecture using Flutter Web:
- **Clean Architecture**: Decoupled domain models, interfaces, static catalog data sources, and state management logic.
- **Riverpod State Management**: Full reactive binding for theme toggling, form inputs, dynamic checklist toggling, and tab rendering.
- **Rule-Based Selection & Budgeting Service**: Implements matching algorithms that score meals based on scheduling constraints, available ingredients, and dietary restrictions, then optimizes costs via an ingredient substitution engine.
- **Local Persistence**: Restores state using `SharedPreferences` so that checking off checklist items or refreshing the browser retains the generated day's plans.

---

## 🧠 Decision & Logic Engine

### 1. Meal Planning & Recommendation Logic
The local AI recommendation engine rates and selects Breakfast, Lunch, and Dinner by checking constraints and calculating score weights:
- **Hard Constraints (Pre-filter)**:
  - **Dietary Filter**:
    - `Vegan` $\rightarrow$ Only selects meals tagged `vegan`.
    - `Vegetarian` $\rightarrow$ Selects meals tagged `vegetarian` or `vegan`.
    - `Non-Vegetarian` / `High Protein` $\rightarrow$ Selects any meal.
  - **Prep Time Constraint**: Max prep time must be $\le$ user's available time input (15m, 30m, 60m). If constraints are too tight, the engine relaxes prep times to find a close match.
- **Scoring Weights (+ points)**:
  - **Day Type Matching (+15 pts)**: Matches meal-suitability arrays against the active day type:
    - *Busy Workday / Travel Day*: Favors prep times $\le$ 15m (+10 pts) and "Easy" difficulty (+5 pts).
    - *Gym Day*: Favors high-protein dietary tags (+20 pts).
    - *Weekend*: Favors elaborate preparation times $\ge$ 30m (+8 pts).
  - **Ingredient Match (+6 pts per ingredient)**: Heavily rewards meals that utilize items already available in the user's kitchen, reducing grocery costs.
  - **Budget Share (+5 pts)**: Rewards category meals fitting standard daily allocations (20% Breakfast, 40% Lunch, 40% Dinner).

### 2. Budget Feasibility Logic
- **Cost Scaling**: Daily cost is computed as:
$$\text{Total Raw Cost} = (\text{Breakfast Cost} + \text{Lunch Cost} + \text{Dinner Cost}) \times \text{Number of People}$$
- **Substitution Engine Trigger**: If $\text{Total Raw Cost} > \text{Budget}$:
  - We scan selected meals for premium ingredients (Paneer, Chicken, Butter) and swap them for cheaper alternatives:
    - **Chicken** $\rightarrow$ **Soy Chunks** (saves ₹100/person)
    - **Paneer** $\rightarrow$ **Tofu** (saves ₹45/person)
    - **Butter** $\rightarrow$ **Olive Oil** (saves ₹10/person)
  - Recalculates cost and dynamically updates the grocery list. If the budget is still exceeded, it populates `costSavingSuggestions` recommending lower-cost meal swaps (e.g. swapping Chicken Tikka for Dal Tadka).
  - If the budget remains extremely tight, it provides fallback directions urging the user to adjust budget parameters or scale down headcount.

### 3. Grocery List Classification
Ingredients are grouped into:
- **Already Available**: Items owned by the user (matching input list case-insensitively). Quantities are scaled for display, but cost is ₹0.
- **Need To Buy**: Items not in the kitchen. Quantities are scaled by headcount and costed using mock unit costs.

### 4. Interactive Cooking Checklist
Generates step-by-step checklist tasks covering verification, shopping list checks, substitution preparation, and individual cooking stages. All progress is written synchronously to local storage.

---

## 💻 Setup Instructions

To run the project locally, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

1. **Clone the repository / Navigate to directory**:
   ```bash
   cd smartmeal_ai
   ```
2. **Get Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run Unit Tests**:
   Verify everything compiles and runs correctly:
   ```bash
   flutter test
   ```
4. **Run Web App Locally**:
   Launch a local dev server for Google Chrome:
   ```bash
   flutter run -d chrome
   ```

---

## 🚀 Deployment Instructions

### Build for Production
To generate a production-ready web bundle:
```bash
flutter build web --release
```
The compiled assets will be placed inside the `build/web` folder.

### Deployment Hosting Options
1. **GitHub Pages**:
   Use the `gh-pages` package:
   ```bash
   flutter_pages deploy
   ```
2. **Vercel / Netlify**:
   Drag-and-drop the generated `build/web` directory, or link your git repository using `build/web` as the output directory and the following build command:
   ```bash
   flutter/bin/flutter build web --release
   ```

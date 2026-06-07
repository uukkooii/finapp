You are restructuring and beautifying a Flutter personal finance app ("金库"). Work in /opt/finapp.

## TASK 1: Consolidate 9 tabs → 5 tabs

Current structure (main.dart _MainShellState):
0. HomePage, 1. StatisticsPage, 2. BudgetPage, 3. GoalsPage, 
4. RecurringPage, 5. CreditPage, 6. CashflowPage, 7. FreedomPage, 8. SearchPage

### New 5-tab structure:

**Tab 0: 🏠 首页 (HomePage)** — Keep as is PLUS:
- Add a search bar at the top that filters transactions inline (remove SearchPage tab)
- Show results in a scrollable list below

**Tab 1: 📊 分析 (AnalyticsPage — NEW page)**
- Internal TabBar with 2 sub-tabs: "统计" (from StatisticsPage) + "现金流" (from CashflowPage)
- Both existing pages become widgets embedded in this page
- Import and reuse the existing page widgets, just nest them with DefaultTabController

**Tab 2: 💰 理财 (FinancePage — NEW page)**  
- Internal TabBar with 3 sub-tabs: "预算" (BudgetPage) + "周期" (RecurringPage) + "信用" (CreditPage)
- Import and nest the existing page widgets

**Tab 3: 🎯 目标 (GoalsPage)** — Keep as is

**Tab 4: 🚀 自由 (FreedomPage)** — Keep as is

Implementation:
1. Create `lib/pages/analytics_page.dart` — TabBar with 统计 + 现金流
2. Create `lib/pages/finance_page.dart` — TabBar with 预算 + 周期 + 信用
3. Update `main.dart`: 5 tabs, 5 nav items, remove SearchPage, RecurringPage, CreditPage, CashflowPage from the pages list

## TASK 2: Add Confetti celebration
In `goals_page.dart`, when a goal reaches 100%, show confetti using the `confetti` package:
- Add `import 'package:confetti/confetti.dart'`
- Add a ConfettiController to the state
- When goal progress hits 100%, start the confetti
- Clean up controller in dispose()

## TASK 3: Add flutter_animate effects
Use the `flutter_animate` package (already in pubspec.yaml) on the home page:
- `import 'package:flutter_animate/flutter_animate.dart'`
- Add `.animate().fadeIn(duration: 600.ms).slideY(begin: 0.1)` to the main cards
- Add `.animate().scale(duration: 400.ms, curve: Curves.elasticOut)` to the net worth card
- Keep it subtle, don't over-animate

IMPORTANT:
- Run `flutter analyze` to verify 0 errors
- Don't change functionality of existing pages, just wrap them
- Keep the cute UI style

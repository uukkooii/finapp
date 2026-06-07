You are working on a Flutter personal finance app called 金库 (FinApp). You MUST complete all tasks. Read existing files to understand codebase first.

## 1. GOAL MODEL (lib/models/goal.dart)
Add String? account, String? icon, String? color fields. Update fromMap/toMap/copyWith.

## 2. DATABASE (lib/core/database.dart)
ALTER TABLE goals ADD COLUMN account TEXT, icon TEXT, color TEXT. Use try-catch.

## 3. GOAL AUTO-SYNC (lib/providers/goal_provider.dart)
Add syncGoalWithTransaction(Transaction t): if t.type==income, increment currentAmount for goals where goal.account==t.account. Call notifyListeners.

## 4. TRANSACTION PROVIDER (lib/providers/transaction_provider.dart)
After addTransaction success, call GoalProvider.syncGoalWithTransaction for income transactions. Import goal_provider.

## 5. HOME PAGE REWRITE (lib/pages/home_page.dart)
COMPLETELY REWRITE. Replace everything.

New body: SingleChildScrollView > Column:
- NetWorthCard: total income-expense, "+X% vs last month" in green/red
- GoalRingsRow: horizontal row of CustomPaint rings (top 3 goals), icon+name+%, uses GoalProvider
- MonthlySummary: Income/Expense/Balance in 3 columns with TweenAnimationBuilder
- BudgetCard: progress bar, remaining days, daily budget suggestion
- UpcomingAlerts: goals with deadlines within 30 days, or encouraging message
- RecentTransactions: last 5 with relative dates (今天/昨天/2天前), swipe to delete

REMOVE: quote card, FIRE ring, 写一条想法 button.
ADD: TweenAnimationBuilder on numbers, AnimatedOpacity for cards, shimmer loading placeholders.

## 6. GOALS PAGE (lib/pages/goals_page.dart)  
In add/edit dialog: add account picker dropdown, emoji icon picker grid.
In goal card: show account chip badge, milestone dots on progress bar, celebration when 100%.

## 7. CONSTANTS (lib/core/constants.dart)
Add goalIcons and goalColors lists.

## 8. BUILD
cd /opt/finapp && flutter build apk --debug
Fix all errors. Iterate until BUILD SUCCESSFUL.

RULES: dark theme, gold #D4A574 accent, Chinese text, ¥ amounts, Provider pattern, const where possible. DO NOT modify files not listed.

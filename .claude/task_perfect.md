You are polishing a Flutter personal finance app ("金库") to perfection. Work in /opt/finapp.

## CRITICAL: Fix these in order. Read files before editing.

### 1. LIGHT MODE FULL ADAPTATION
Update these pages to use `context.themeBg`, `context.themeCard`, `context.themeText`, `context.themeSub` instead of hardcoded `bgColor`, `cardColor`, `Colors.white`, `Colors.white54`:

- `pages/add_transaction_page.dart` — replace all hardcoded bgColor/cardColor/Colors.whiteXX
- `pages/goals_page.dart` — same
- `pages/freedom_page.dart` — same  
- `pages/statistics_page.dart` — same
- `pages/budget_page.dart` — same
- `pages/home_page.dart` — same (critical, many cards)
- `pages/finance_page.dart` — TabBar container
- `pages/analytics_page.dart` — TabBar container

Pattern: `bgColor` → `context.themeBg`, `cardColor` → `context.themeCard`, `Colors.white` → `context.themeText`, `Colors.white54` → `context.themeSub`

### 2. RESTORE SEARCH
Add search feature back to home_page.dart:
- Add a search TextField at the top of home_page
- Filter recent transactions from TransactionProvider in real-time
- Show results inline as a dismissible list
- Keep search_page.dart as reference but don't add it as a tab

### 3. ADD CHARTS TO STATISTICS
statistics_page.dart already imports fl_chart (package is installed). Add:
- A pie/donut chart showing category breakdown for current month
- Keep existing stats cards
- Use fl_chart's PieChart widget
- Colors from the categories' assigned colors

### 4. SIMPLIFY RECORDING FURTHER
In add_transaction_page.dart:
- Make the amount input the first thing user sees (auto-focus)
- Show 4 quick-amount buttons: +¥10, +¥50, +¥100, +¥500 for rapid recording
- Category row: only show 6 most-used categories, rest in "更多" dropdown

### 5. ADD EDIT/DELETE TRANSACTION
- Add swipe-to-delete on recent transactions in home_page
- Add edit button that opens a pre-filled recording sheet
- Use TransactionProvider's updateTransaction/deleteTransaction methods

### 6. CLEANUP
- Delete unused search_page.dart (search is now inline on home)
- Extract `_GoalRing` widget into `widgets/goal_ring.dart` since it's used in both home_page and goals_page

### 7. CONFETTI ON GOAL COMPLETION
In goals_page.dart, when goal progress reaches 100%:
- Import 'package:confetti/confetti.dart'
- Show confetti animation for 3 seconds

IMPORTANT:
- Run `flutter analyze` after to verify 0 errors
- Don't break any existing functionality
- Test light mode thoroughly: every page should look good with light background + dark text

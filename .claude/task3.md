You are working on a Flutter personal finance app called 金库 (FinApp). Complete 2 fixes:

## FIX 1: SIMPLIFY ADD TRANSACTION (lib/pages/add_transaction_page.dart) — COMPLETE REWRITE

References: 鲨鱼记账 (open→enter amount→pick category→done), 钱迹 (quick entry)

Redesign as a BOTTOM SHEET instead of full page. The key philosophy: **enter amount, pick category, done**.

### New Layout (bottom-to-top order in bottom sheet):

**Bottom section: Big Number Pad** (always visible, pinned to bottom)
- 4x3 grid: 1-9, ., 0, del(⌫) 
- Tall, easy-to-hit buttons
- Amount shown ABOVE numpad: big text "¥ 0" right-aligned

**Middle section: Category Chips**
- Show ONLY categories for current type (expense or income)
- Each chip: emoji icon + name
- Selected chip glows gold
- 4 columns, 2-3 rows max
- Default selection preset based on type:
  - expense → 餐饮
  - income → 工资

**Top section: Type Toggle**
- Two pill buttons: 支出 | 收入
- Smooth animated switch
- Expense = red when selected, Income = green

**Super top (collapsed):**
- Account & Date in one small row (collapsed, tap to expand)
- Note field (collapsed)
- These are HIDDEN by default, only show when user taps "更多"

### Save behavior:
- BIG SAVE BUTTON at the bottom of numpad area (green for income, red for expense works)
- On save: create Transaction, call addTransaction, close sheet
- Amount must be > 0

### Key differences from current:
- NO AppBar (bottom sheet has drag handle)
- NO separate "保存" button in appbar
- Categories shown BEFORE account/date/note (which are collapsed)
- Account defaults to '银行卡', date to today

## FIX 2: FREEDOM PAGE PERSISTENCE (lib/pages/freedom_page.dart)

Problem: TextEditingControllers reset each time page loads.

Fix using shared_preferences package:
- Add shared_preferences to pubspec.yaml if not already there
- Save _monthlyExpenseCtrl text on change/unfocus
- Save _netAssetsCtrl text on change/unfocus
- Save _annualRateCtrl text on change/unfocus
- Save _monthlySavingsCtrl text on change/unfocus
- Load saved values in initState (before _loadNetAssets)
- Keys: 'freedom_monthly_expense', 'freedom_net_assets', 'freedom_annual_rate', 'freedom_monthly_savings'
- Auto-calculate on load if all values are populated
- Add TextEditingController listeners to save on change

## RULES
- Dark theme: bg #1A1A2E, card #16213E, gold #D4A574
- Chinese text
- ¥ amounts
- Provider pattern
- After changes: flutter build apk --debug, fix any errors

You are working on 金库 (FinApp), a Flutter personal finance app. Dark theme, gold #D4A574 accent.

## BATCH 1: Recurring Bills + Insurance + Subscriptions (Periodic Expenses)

### New Model: lib/models/recurring_bill.dart
Create a RecurringBill class with:
- int? id, String name, double amount, String category, String frequency (monthly/quarterly/yearly/custom), int? customDays, String? nextDueDate, String? account, String? note, String createdAt
- fromMap/toMap/copyWith

### Database: lib/core/database.dart
- CREATE TABLE recurring_bills with all columns
- Add db methods: getRecurringBills(), insertRecurringBill(), updateRecurringBill(), deleteRecurringBill()
- Also getUpcomingBills(int days): SELECT * WHERE nextDueDate BETWEEN today AND today+days

### Provider: lib/providers/recurring_provider.dart
- ChangeNotifier with CRUD methods
- init() to load all bills
- getUpcoming(int daysAhead) method

### New Page: lib/pages/recurring_page.dart
- List of recurring bills with toggle (active/paused)
- Each card shows: name, amount, frequency badge, next due date, category icon
- Swipe to delete
- FAB to add new: name, amount, category picker, frequency dropdown (月/季/年/自定义天), next due date picker, account picker, note
- Empty state with illustration

### Home Page Update: lib/pages/home_page.dart
- The UpcomingAlerts section should use RecurringProvider
- Show bills due within 7 days
- Format: "车险续费 ¥3,600 6月30日"

### Main: lib/main.dart
- Add RecurringProvider
- Add RecurringPage to pages list
- Add nav item: icon(Icons.repeat), label('周期')

### Constants: lib/core/constants.dart
- Add PeriodicCategory if needed

## BATCH 2: Credit Cards & Debt Management

### New Model: lib/models/credit_card.dart
- int? id, String name, String bank, String cardNumber (last 4), double creditLimit, double currentBalance, int billDay (1-28), int paymentDay (1-28), String color, String createdAt
- fromMap/toMap/copyWith
- Computed: availableCredit = creditLimit - currentBalance, utilizationRate = currentBalance/creditLimit

### Database additions
- CREATE TABLE credit_cards
- Full CRUD

### Provider: lib/providers/credit_provider.dart
- CRUD + getUpcomingPayments() — bills due within 15 days
- getTotalDebt() — sum of all currentBalance
- getTotalLimit() — sum of all creditLimit

### New Page: lib/pages/credit_page.dart
- Top card: total debt / total limit with utilization rate ring
- Card list: each card with bank icon, name, balance vs limit progress bar
- Color-coded: green <30%, yellow 30-70%, red >70% utilization
- Payment calendar view: shows payment dates with amounts
- Tap card to edit/delete
- FAB to add new card

### Home Page: 
- Add credit utilization warning if any card >70%
- Show in UpcomingAlerts if payment due within 7 days

### Main integration
- Add CreditProvider, CreditPage, nav item

## BATCH 3: Search & Filter

### New Page: lib/pages/search_page.dart
- Search bar at top (always visible)
- Filter chips: income/expense toggle, month selector, category filter, amount range
- Results list: matching transactions grouped by date
- Each result shows: category icon, category name, note, amount, account
- Tap to edit, swipe to delete
- "No results" empty state
- Recent searches
- Search by: category name, note text, account name

### Main integration  
- Add SearchPage to pages, nav bar with icon(Icons.search)

## BATCH 4: Cash Flow Prediction

### New Page: lib/pages/cashflow_page.dart
- "未来30天" prediction chart (simple bar chart using Containers)
- Shows daily projected balance based on: recurring bills, average daily spend, expected income
- "最低余额" alert: when balance drops below threshold
- "每日可花" — daily disposable income after fixed costs
- "大额消费模拟" — input an amount, see impact on 30-day projection

### Main integration
- Add to nav

## RULES
- Keep dark theme, gold accent, Chinese text, ¥ amounts
- Provider pattern, const where possible
- flutter analyze must pass with 0 issues
- Build: flutter build apk --debug must succeed
- DO NOT modify files unnecessarily — only add new files and update existing ones minimally
- Read existing files before editing

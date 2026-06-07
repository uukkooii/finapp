You are fixing a Flutter personal finance app ("金库"). Work in /opt/finapp. Use Flutter in /usr/local/flutter/bin.

## CRITICAL: Fix ALL of these issues. Read each file fully before editing.

### 1. FIX CASHFLOW SIMULATION (cashflow_page.dart)
The simulation currently subtracts the same amount from every day. It should show a ONE-TIME hit:
- Day 1: balance drops by the full simulation amount
- Days 2-30: balance continues from the new lower baseline (just daily income - daily expense)

Fix the `_applySimulation` method to subtract the full amount only on day 0, not every day.

### 2. INTERCONNECT: Mark Paid → Create Transaction (recurring_provider.dart)
When user taps "mark paid" on a recurring bill, it should:
1. Create an expense Transaction in the TransactionProvider
2. Update the next due date
3. The transaction should use the bill's category, amount, account, and note

Modify RecurringProvider to accept TransactionProvider as a dependency (or pass it to markPaid).

### 3. INTERCONNECT: Credit Card Payments in Cashflow (cashflow_page.dart)
In `_loadData`, also fetch upcoming credit card payments from CreditProvider. Add these as negative line items on their payment dates (like recurring bills). This way credit card debt shows as real future outflows.

Also add a "credit card debt" stat card showing total debt and utilization.

### 4. INTERCONNECT: Budget → Daily Disposable (cashflow_page.dart)
Currently cashflow "daily disposable" is just avgIncome - avgExpense. It should also factor in the monthly budget:
- If budget is set: dailyDisposable = min(avgDailyIncome - avgDailyExpense, remainingBudget / remainingDaysInMonth)
- This gives users a more realistic "how much can I spend today" number

### 5. FIX: Freedom Page Save Bug (freedom_page.dart)
Read the full file, find why saving doesn't work. Fix the root cause. Likely the save logic isn't persisting to database or not reloading properly.

### 6. VERIFY: Search page works (search_page.dart)
Read the file, verify the search logic uses real transaction data from TransactionProvider. Fix any issues.

### 7. INTERCONNECT: Home → Cashflow Alert
In home_page.dart `_UpcomingAlerts`, also check if the 30-day minimum balance from cashflow goes negative. If so, show a warning card like "⚠️ 现金流预警：未来30天预计亏空 ¥xxx".

### 8. After all changes: run `flutter analyze` to verify 0 errors, then build APK with `flutter build apk --debug`

IMPORTANT:
- Use Provider.of<> for accessing other providers
- All colors from constants.dart (goldColor, incomeGreen, expenseRed, accentColor, bgColor, cardColor, lavenderColor)
- All amounts in double (yuan)
- Use the existing cardDecoration() function for card styling
- Keep the cute UI style (emoji, rounded corners, gradients)
- Zero tolerance for compilation errors

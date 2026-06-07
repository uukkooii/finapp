You are fixing bugs in a Flutter personal finance app ("金库"). Work in /opt/finapp.

## Fix these specific bugs:

### BUG 1: Cashflow simulation stats don't update (cashflow_page.dart)
When user enters an amount and taps "模拟", the bar chart updates but the stats (每日可花, 30天最低余额) and the header card still show the original values. 
Fix: pass `simData ?? data` to `_StatsRow` and `_HeaderCard` when simulation is active.

### BUG 2: Freedom page save doesn't work (freedom_page.dart)  
Read the file fully. Find why the save method doesn't persist data. Fix the root cause.

### BUG 3: Mark paid doesn't create transaction (recurring_provider.dart)
When `markPaid` is called, it should also create an expense transaction. 
Modify `markPaid` to accept a TransactionProvider parameter and call it to add a transaction.
The transaction should use the bill's amount, category, account, and note.

### BUG 4: Credit card payments not in cashflow (cashflow_page.dart)
In `_loadData`, add CreditProvider parameter. Fetch upcoming credit card payments and add them as negative line items on their due dates (same as recurring bills).

### BUG 5: Budget not factored into daily disposable (cashflow_page.dart)
If budget is set, dailyDisposable should be: min(avgDailyIncome - avgDailyExpense, remainingBudget / remainingDaysInMonth)

### BUG 6: No cashflow warning on home (home_page.dart)
In `_UpcomingAlerts`, add a cashflow check: if 30-day min balance < 0, show a warning.

IMPORTANT: 
- Run `flutter analyze` after ALL changes to verify 0 errors
- Zero tolerance for compilation errors
- Keep existing UI style

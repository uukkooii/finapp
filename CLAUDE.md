# 金库 (FinApp) — Personal Finance Flutter App

## Architecture
- Flutter mobile app, SQLite local storage (sqflite), Provider state management
- Dark theme: bg #1A1A2E, card #16213E, accent gold #D4A574, income green #4CAF50, expense red #E53935
- 6 tabs: Home, Stats, Budget, Goals, Freedom, Bills

## Structure
- `lib/core/database.dart` — SQLite DB helper
- `lib/core/constants.dart` — Colors, categories, accounts, quotes
- `lib/models/` — Transaction, Goal, Budget models
- `lib/providers/` — ChangeNotifier providers
- `lib/pages/` — Full page widgets
- `lib/main.dart` — App entry, MultiProvider, MainShell with BottomNavigationBar

## Key conventions
- Transactions have: type (income/expense), amount, category, account, note, date
- Goals have: name, targetAmount, currentAmount, deadline, createdAt
- Accounts: 现金, 银行卡, 微信, 支付宝
- Dates stored as 'YYYY-MM-DD' strings
- All amounts in double (yuan)

## Build
- `flutter build apk --debug` to build APK
- Uses flutter_launcher_icons for app icon

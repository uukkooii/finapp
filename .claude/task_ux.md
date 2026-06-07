You are polishing the UX of a Flutter personal finance app ("金库"). Work in /opt/finapp.

## TASK 1: First-time user onboarding
Create `lib/pages/onboarding_page.dart` — a simple 2-3 page swipe intro:
- Page 1: "💰 简单记账" — emoji + quick intro
- Page 2: "📊 掌控财务" — budget/goals overview
- Page 3: "🎯 开始使用" — button to enter app
- Use SharedPreferences to only show once (key: 'onboarding_done')
- In main.dart, check SharedPreferences and show onboarding if needed before MainShell

## TASK 2: Rich empty states
Update empty states in all pages with helpful guidance:
- Home: "👋 开始记账吧！点击下方 + 按钮记录第一笔"
- Budget: "📋 设置月度预算，控制支出不超支"
- Goals: "🎯 设定储蓄目标，让每一分钱有方向"
- Recurring: "🔄 添加房贷、订阅等周期账单，不再忘记"
- Credit: "💳 管理信用卡，追踪额度与还款日"
Each should have a prominent CTA button.

## TASK 3: Pull-to-refresh everywhere
Add RefreshIndicator to BudgetPage, GoalsPage, RecurringPage, CreditPage
- Call the provider's init() method on refresh
- Use goldColor with cardColor background

## TASK 4: Haptic feedback
Add light haptic feedback on these actions:
- Tapping "记 账" button (add_transaction_page)
- Tapping markPaid button (recurring_page)  
- Switching tabs (main.dart)
Import: 'package:flutter/services.dart' → use HapticFeedback.lightImpact()

## TASK 5: Transaction feedback toast
After saving a transaction, show a brief toast/overlay "✅ 已记录" instead of just closing silently.

## TASK 6: Quick category shortcuts on home
On home_page.dart, add a row of 4-5 quick-record icons (🍔餐饮, 🚗交通, 🛒购物, 🎮娱乐) below the monthly summary. Tapping one opens AddTransactionPage with that category pre-selected.

IMPORTANT:
- Run `flutter analyze` after to verify 0 errors
- Keep existing functionality
- Maintain the cute UI style

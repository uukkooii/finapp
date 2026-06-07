You are refactoring a Flutter personal finance app ("金库"). Work in /opt/finapp. Use Flutter in /usr/local/flutter/bin.

## CRITICAL: Consolidate 9 tabs → 5 tabs, then beautify everything.

### PHASE 1: PAGE CONSOLIDATION (9→5 tabs)

#### 1.1 NEW: 首页 (Home) — merge search into it
- Keep existing dashboard cards
- Add a search bar at the top (TextField with search icon)
- Search bar filters recent 20 transactions from TransactionProvider in real-time
- Results show inline below the search bar as a dismissible overlay
- Remove the standalone SearchPage tab

#### 1.2 NEW: 分析 (Analysis) — merge statistics + cashflow
- Create `pages/analysis_page.dart` with internal tab switching (统计数据 / 现金流预测)
- Use TabBar or segmented control at the top
- Tab 1: StatisticsPage content (charts, category breakdown)
- Tab 2: CashflowPage content (30-day projection, simulation)
- Remove standalone CashflowPage tab

#### 1.3 NEW: 理财 (Finance) — merge budget + recurring + credit
- Create `pages/finance_page.dart` with internal tab switching (预算 / 周期账单 / 信用卡)
- Tab 1: BudgetPage content
- Tab 2: RecurringPage content (rename from RecurringPage)
- Tab 3: CreditPage content
- Remove standalone BudgetPage, RecurringPage, CreditPage tabs

#### 1.4 KEEP: 目标 (Goals) — unchanged
#### 1.5 KEEP: 自由 (Freedom) — unchanged

#### 1.6 Update main.dart
- New BottomNavigationBar with 5 items:
  1. 🏠 首页 (HomePage with search)
  2. 📊 分析 (AnalysisPage)
  3. 💰 理财 (FinancePage)
  4. 🎯 目标 (GoalsPage)
  5. 🚀 自由 (FreedomPage)
- Remove all old page imports and entries
- Adjust titles array

### PHASE 2: UI BEAUTIFICATION

#### 2.1 Global polish
- Add smooth page transition animations (SlideTransition or FadeTransition when switching tabs) using AnimatedSwitcher
- Add subtle particle/sparkle effect on the FAB button (use a rotating star icon or pulse animation)
- Add shimmer loading states on all cards that load data (home, analysis, finance, goals, freedom)

#### 2.2 Home page polish
- Net worth card: add a subtle animated gradient that slowly shifts colors
- Monthly summary: number counter animation (count up from 0 to actual value)
- Budget card: add a gradient progress bar (not solid color)
- Upcoming alerts: add a pulsing dot animation on urgent items (due within 3 days)
- Recent transactions: frosted glass effect on each row

#### 2.3 Analysis page polish
- Bar charts: rounded tops, gradient fills, subtle 3D shadow
- Pie/donut chart for category breakdown with gradient segments
- Cashflow bar chart: animate bars growing upward on load
- Add "wave" decoration or subtle background pattern

#### 2.4 Finance page polish
- Tab selector: pill-shaped, gradient background on selected
- Bill cards: glassmorphism style (frosted glass + border glow)
- Budget: circular progress with gradient ring instead of linear bar
- Credit card: show card mockup with gradient background (like a real credit card)

#### 2.5 Goals page polish
- Progress rings: add pulse animation on 100% completion
- Add confetti/celebration effect when a goal is completed (simple particle overlay)
- Goal cards: gradient backgrounds per goal color

#### 2.6 Freedom page polish
- FIRE number: animated counter with gradient text
- Progress bar: gradient fill
- Add inspirational quote with typewriter animation

#### 2.7 Add Transaction page polish
- Category selector: smooth scale animation on selection
- Amount input: large font, gradient text color
- Submit button: gradient + shine animation (sweep effect)

### PHASE 3: CONSTANTS UPDATE
In constants.dart, add more visual constants:
- cardGradient: a reusable gradient for cards
- shimmerGradient: for loading states
- cardShadow: common box shadows
- Add more emoji-配色的 gradient pairs

### CRITICAL RULES:
- All existing functionality MUST work exactly the same
- Use Provider.of<> for data access
- Colors: goldColor, incomeGreen, expenseRed, accentColor, bgColor, cardColor, lavenderColor
- Keep cute style: emoji icons, rounded corners (24px), gradient cards
- Zero tolerance for compilation errors
- Run `flutter analyze` after all changes, fix any errors
- Build APK with `flutter build apk --debug`

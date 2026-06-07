MAKE THE UI PLAYFUL AND CUTE (活泼可爱). Change the whole app look and feel.

## 1. NEW COLOR PALETTE (lib/core/constants.dart)
Replace all colors:
```dart
const Color bgColor = Color(0xFF1E1B2E);      // warm purple dark
const Color cardColor = Color(0xFF2A2540);    // soft purple card
const Color goldColor = Color(0xFFFF8FAB);    // pink primary (replaces gold)
const Color accentColor = Color(0xFFFFB347);  // warm orange accent
const Color incomeGreen = Color(0xFF7BE0AD);  // macaron green
const Color expenseRed = Color(0xFFFF7675);   // coral pink
const Color mintColor = Color(0xFF74B9FF);    // mint blue
const Color lavenderColor = Color(0xFFA29BFE); // lavender purple
const Color peachColor = Color(0xFFFAB1A0);    // peach
```

Add goal ring colors (fun pastels):
const List<int> goalColors = [0xFFFFD93D, 0xFF6BCB77, 0xFF4D96FF, 0xFFFF8FAB, 0xFFA29BFE, 0xFFFAB1A0, 0xFF74B9FF, 0xFFF47373, 0xFFF9D423, 0xFF4CA1AF, 0xFFFF9A9E, 0xFFA18CD1];

## 2. ALL PAGES — UNIVERSAL CHANGES
- ALL Container borderRadius: change 12→24, 8→16, 4→10 (big rounded corners everywhere)
- ALL ElevatedButton: shape RoundedRectangleBorder(borderRadius: 50) — pill/capsule buttons
- ALL cards: add subtle gradient decoration instead of flat color
  ```dart
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [cardColor, cardColor.withValues(alpha:0.7)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [BoxShadow(color: goldColor.withValues(alpha:0.08), blurRadius: 20, offset: Offset(0,8))],
  )
  ```

## 3. HOME PAGE (lib/pages/home_page.dart)
- NetWorthCard: use gradient with warm colors, bigger emoji
- Goal rings: colorful pastel arcs, each ring different color from goalColors
- MonthlySummary: animated numbers with spring curve
- BudgetCard: add "还剩X天 😊" with emoji
- Recent transactions: add more emoji category icons
- Add confetti/splash on pull-to-refresh

## 4. ADD TRANSACTION PAGE (lib/pages/add_transaction_page.dart)
- Category grid: bigger emojis (28px→40px), colorful backgrounds
- Save button: pill shape, gradient, with sparkle icon ✨
- On save success: show animated emoji feedback (💰 for income, 💸 for expense)

## 5. GOALS PAGE (lib/pages/goals_page.dart)
- Goal cards: add emoji icon big and prominent
- Progress bar: gradient fill (not solid), milestone hearts at 25/50/75%
- When 100%: show 🎉 confetti overlay
- Add goal dialog: emoji picker should be BIG (50px emojis), playful grid

## 6. MAIN APP (lib/main.dart)
- BottomNavigationBar: backgroundColor use cardColor, add subtle top border shadow
- Nav items: use more playful icons where possible
- FAB: gradient, bouncy animation on tap, bigger (60px)

## 7. ANIMATIONS (add throughout)
- Use spring animations: `Curves.elasticOut`, `SpringSimulation`
- Page transitions: fade + slight scale
- Number counters: spring bounce
- Pull to refresh: cute loading indicator

## 8. EMOJI EVERYWHERE
- Category names prepend emoji: "🍚 餐饮", "🛒 购物", "🏠 住房" etc.
- Empty states: big cute emoji + encouraging text
- Success messages: emoji-based (not boring snackbar)

## RULES
- Keep all existing functionality — just change visuals
- Keep Chinese text
- Keep Provider pattern
- Keep existing file structure
- After ALL changes: flutter build apk --debug, fix errors, rebuild until success

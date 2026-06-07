You are adding system light/dark theme support to a Flutter personal finance app ("金库"). Work in /opt/finapp.

## Step 1: Add light color variants to constants.dart
At the end of lib/core/constants.dart, add:
```dart
// ── Light mode colors ──
const Color lightBg = Color(0xFFF5F3EE);
const Color lightCard = Color(0xFFFFFFFF);
const Color lightGold = Color(0xFFC8963E);
const Color lightText = Color(0xFF2D2D2D);
const Color lightSubtext = Color(0xFF999999);
const Color lightAccent = Color(0xFF7C5CFC);
const Color lightIncomeGreen = Color(0xFF2E7D32);
const Color lightExpenseRed = Color(0xFFC62828);

// Helper: pick color based on brightness
extension ThemeColors on BuildContext {
  Color get themeBg => Theme.of(this).brightness == Brightness.dark ? bgColor : lightBg;
  Color get themeCard => Theme.of(this).brightness == Brightness.dark ? cardColor : lightCard;
  Color get themeGold => Theme.of(this).brightness == Brightness.dark ? goldColor : lightGold;
  Color get themeText => Theme.of(this).brightness == Brightness.dark ? Colors.white : lightText;
  Color get themeSubtext => Theme.of(this).brightness == Brightness.dark ? Colors.white54 : lightSubtext;
  Color get themeAccent => Theme.of(this).brightness == Brightness.dark ? accentColor : lightAccent;
  Color get themeIncomeGreen => Theme.of(this).brightness == Brightness.dark ? incomeGreen : lightIncomeGreen;
  Color get themeExpenseRed => Theme.of(this).brightness == Brightness.dark ? expenseRed : lightExpenseRed;
  // Keep gold/accent that look good in both modes
  Color get themeGoldColor => goldColor;
  Color get themeLavender => lavenderColor;
}
```

## Step 2: Update main.dart for system theme
Change the MaterialApp to:
```dart
return MaterialApp(
  title: '金库',
  debugShowCheckedModeBanner: false,
  themeMode: ThemeMode.system,
  theme: ThemeData(
    brightness: Brightness.light,
    primaryColor: lightGold,
    scaffoldBackgroundColor: lightBg,
    cardColor: lightCard,
    colorScheme: const ColorScheme.light(
      primary: lightGold,
      secondary: lightIncomeGreen,
      error: lightExpenseRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightCard,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
      ),
    ),
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    primaryColor: goldColor,
    scaffoldBackgroundColor: bgColor,
    cardColor: cardColor,
    colorScheme: const ColorScheme.dark(
      primary: goldColor,
      secondary: incomeGreen,
      error: expenseRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cardColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
      ),
    ),
  ),
  home: const MainShell(),
);
```

## Step 3: Update all pages to use theme-aware colors
In EVERY page that uses `bgColor` directly, replace with:
- `bgColor` → colors are now picked via `context.themeBg`, `context.themeCard`, etc.
- BUT this would be too many changes. Instead, just keep bgColor, cardColor etc for the dark-only screens where they work. The theme extension handles the adaptation.

The KEY places to update are hardcoded `Colors.whiteXX`, `Colors.blackXX`:
- `Colors.white` → `context.themeText`
- `Colors.white60/54/38/24/12` → keep as opacity of `context.themeText`
- `Colors.black` in notes → `context.themeText`

## Step 4: Verify
Run `flutter analyze` to verify 0 errors after all changes.

IMPORTANT: 
- Only modify files that need changes. Don't touch files that already work.
- The `ThemeColors` extension on BuildContext is the central mechanism
- Keep all functionality intact

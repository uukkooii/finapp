import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/recurring_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/asset_provider.dart';
import 'pages/home_page.dart';
import 'pages/analytics_page.dart';
import 'pages/finance_page.dart';
import 'pages/goals_page.dart';
import 'pages/freedom_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/add_transaction_page.dart';
import 'pages/ai_accounting_page.dart';
import 'pages/asset_page.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_done') ?? false);
  runApp(FinApp(showOnboarding: showOnboarding));
}

class FinApp extends StatelessWidget {
  final bool showOnboarding;
  const FinApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalProvider()..init()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()..init()),
        ChangeNotifierProvider(create: (_) => CreditProvider()..init()),
        ChangeNotifierProxyProvider<GoalProvider, TransactionProvider>(
          create: (_) => TransactionProvider()..init(),
          update: (_, gp, tp) {
            tp!.setGoalProvider(gp);
            return tp;
          },
        ),
        ChangeNotifierProxyProvider<TransactionProvider, BudgetProvider>(
          create: (ctx) => BudgetProvider(ctx.read<TransactionProvider>())..init(),
          update: (_, tp, bp) => bp!,
        ),
        ChangeNotifierProvider(create: (_) => AssetProvider()..init()),
      ],
      child: MaterialApp(
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
            secondary: lightGreen,
            error: lightRed,
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
        home: showOnboarding ? const OnboardingPage() : const MainShell(),
        routes: {
          '/home': (_) => const MainShell(),
          '/ai': (_) => const AiAccountingPage(),
          '/assets': (_) => const AssetPage(),
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  final pages = const [
    HomePage(),
    AnalyticsPage(),
    FinancePage(),
    GoalsPage(),
    FreedomPage(),
  ];

  final titles = ['金库 ✨', '分析 📊', '理财 💰', '目标 🎯', '自由 🚀'];

  @override
  Widget build(BuildContext context) {
    final showFab = _index == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/ai'),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 20)),
            ),
          ),
          GestureDetector(
            onTap: () => AddTransactionPage.show(context),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [goldColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: goldColor.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: goldColor,
            unselectedItemColor: context.themeHint,
            backgroundColor: context.themeCard,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 20,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: '分析'),
              BottomNavigationBarItem(icon: Icon(Icons.wallet_rounded), label: '理财'),
              BottomNavigationBarItem(icon: Icon(Icons.stars_rounded), label: '目标'),
              BottomNavigationBarItem(icon: Icon(Icons.rocket_launch_rounded), label: '自由'),
            ],
          ),
        ),
      ),
      floatingActionButton: showFab
          ? ScaleTransition(
              scale: _fabController,
              child: GestureDetector(
                onTapDown: (_) => _fabController.reverse(),
                onTapUp: (_) {
                  _fabController.forward();
                  AddTransactionPage.show(context);
                },
                onTapCancel: () => _fabController.forward(),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [goldColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                ),
              ),
            )
          : null,
    );
  }
}

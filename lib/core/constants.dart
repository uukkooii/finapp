import 'package:flutter/material.dart';

// ── Dark mode palette ──
const Color bgColor = Color(0xFF201A30);
const Color cardColor = Color(0xFF2A2540);
const Color goldColor = Color(0xFFFF8FAB);
const Color accentColor = Color(0xFFFFB347);
const Color incomeGreen = Color(0xFF7BE0AD);
const Color expenseRed = Color(0xFFFF7675);
const Color mintColor = Color(0xFF74B9FF);
const Color lavenderColor = Color(0xFFA29BFE);
const Color peachColor = Color(0xFFFAB1A0);
const Color darkHeader1 = Color(0xFF2D2050);
const Color darkHeader2 = Color(0xFF1B2A4A);
const Color darkCard2 = Color(0xFF332B50);

// ── Light mode palette ──
const Color lightBg = Color(0xFFFAF8F5);
const Color lightCard = Color(0xFFFFFFFF);
const Color lightGold = Color(0xFFFF8FAB);
const Color lightAccent = Color(0xFFFFB347);
const Color lightGreen = Color(0xFF7BE0AD);
const Color lightRed = Color(0xFFFF7675);
const Color lightHeader1 = Color(0xFFFFF0F5);
const Color lightHeader2 = Color(0xFFFFF8F0);
const Color lightCard2 = Color(0xFFFEF5F7);

// ── Theme-aware color helpers (use via context.themeXxx) ──
extension ThemeColors on BuildContext {
  Color get themeBg => Theme.of(this).brightness == Brightness.dark ? bgColor : lightBg;
  Color get themeCard => Theme.of(this).brightness == Brightness.dark ? cardColor : lightCard;
  Color get themeCard2 => Theme.of(this).brightness == Brightness.dark ? darkCard2 : lightCard2;
  Color get themeHeader1 => Theme.of(this).brightness == Brightness.dark ? darkHeader1 : lightHeader1;
  Color get themeHeader2 => Theme.of(this).brightness == Brightness.dark ? darkHeader2 : lightHeader2;
  Color get themeText => Theme.of(this).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D2D2D);
  Color get themeSub => Theme.of(this).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF999999);
  Color get themeHint => Theme.of(this).brightness == Brightness.dark ? Colors.white38 : const Color(0xFFBBBBBB);
  Color get themeDivider => Theme.of(this).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFE8E8E8);

  // Gradients
  List<Color> get themeHeroGradient => Theme.of(this).brightness == Brightness.dark
      ? [const Color(0xFF2D2050), const Color(0xFF1E1B2E), const Color(0xFF1B2A4A)]
      : [const Color(0xFFFFF0F5), const Color(0xFFFFF8F0), const Color(0xFFF0F5FF)];

  List<Color> get themeCardGradient => Theme.of(this).brightness == Brightness.dark
      ? [cardColor, const Color(0xFF332B50)]
      : [lightCard, const Color(0xFFFEF5F7)];

  List<Color> get themeAddButtonGradient => [goldColor, accentColor];

  Decoration themeCardDecoration({Color? glowColor, BorderRadius? radius}) {
    return BoxDecoration(
      color: themeCard,
      borderRadius: radius ?? BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? goldColor).withValues(alpha: Theme.of(this).brightness == Brightness.dark ? 0.08 : 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Theme-aware cardDecoration for use with BuildContext
  BoxDecoration cardDecoration({Color? glowColor, BorderRadius? radius}) {
    return BoxDecoration(
      color: themeCard,
      borderRadius: radius ?? BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? goldColor).withValues(alpha: Theme.of(this).brightness == Brightness.dark ? 0.08 : 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

// ── Static card decoration (for places without BuildContext) ──
BoxDecoration cardDecoration({Color? color, BorderRadius? radius, Color? glowColor}) {
  final base = color ?? cardColor;
  return BoxDecoration(
    color: base,
    borderRadius: radius ?? BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: (glowColor ?? goldColor).withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

// ── Data ──
const List<Map<String, String>> categories = [
  {'name': '餐饮', 'icon': '🍚'},
  {'name': '交通', 'icon': '🚌'},
  {'name': '购物', 'icon': '🛒'},
  {'name': '娱乐', 'icon': '🎮'},
  {'name': '住房', 'icon': '🏠'},
  {'name': '通讯', 'icon': '📱'},
  {'name': '医疗', 'icon': '🏥'},
  {'name': '教育', 'icon': '📚'},
  {'name': '人情', 'icon': '🎁'},
  {'name': '日用', 'icon': '🧴'},
  {'name': '服饰', 'icon': '👕'},
  {'name': '零食', 'icon': '🍿'},
  {'name': '工资', 'icon': '💼'},
  {'name': '副业', 'icon': '💻'},
  {'name': '投资', 'icon': '📈'},
  {'name': '其他', 'icon': '📌'},
];

const List<String> accounts = ['现金', '银行卡', '微信', '支付宝'];

const List<Map<String, String>> quotes = [
  {'text': '不要为了赚钱而工作，要让钱为你工作。', 'author': '《富爸爸穷爸爸》'},
  {'text': '复利是世界第八大奇迹。懂得的人赚取它，不懂的人支付它。', 'author': '爱因斯坦'},
  {'text': '财富不是你赚了多少，而是你留下了多少。', 'author': '《邻家的百万富翁》'},
  {'text': '今天存下的每一块钱，都是未来的你给现在的你打工。', 'author': '匿名'},
  {'text': '如果你不找到让钱为你工作的方法，你会一直为钱工作。', 'author': '沃伦·巴菲特'},
  {'text': '消费是为了活着，但活着不是为了消费。', 'author': '《瓦尔登湖》'},
  {'text': '财务自由不是终点，而是你不再需要为了钱做不想做的事。', 'author': '匿名'},
  {'text': '大多数人高估了一年能做的事，低估了十年能做的事。', 'author': '比尔·盖茨'},
  {'text': '省钱就是赚了两次——一次是没花掉，一次是税后。', 'author': '匿名'},
  {'text': '你花的每一块钱，都在给你想要的世界投票。', 'author': '匿名'},
  {'text': '富有不是拥有很多，而是需要的很少。', 'author': '匿名'},
  {'text': '投资自己，是回报率最高的投资。', 'author': '巴菲特'},
  {'text': '不要让钱支配你的生活，你要学会支配钱。', 'author': '匿名'},
  {'text': '每一笔小钱，乘以时间，都是巨款。', 'author': '匿名'},
  {'text': '记账不是为了限制你，而是让你看清钱的流向。', 'author': '匿名'},
  {'text': '预算不光是约束，更是一种自由——你知道钱去哪了。', 'author': '匿名'},
  {'text': '经济独立，是一个人最大的底气。', 'author': '匿名'},
  {'text': '不记账的人，永远不知道钱去哪了。', 'author': '匿名'},
  {'text': '存钱是一种习惯，就像健身一样需要坚持。', 'author': '匿名'},
  {'text': '你羡慕的生活，都是别人用自律换来的。', 'author': '匿名'},
];

const List<String> goalIcons = [
  '🎯', '🚗', '🏠', '✈️', '💍', '📱', '💻', '🎓',
  '🏋️', '🌏', '💰', '🏖️', '🎨', '📷', '🎸', '🐶',
  '👶', '🏥', '🔑', '⛵', '🎪', '🛒', '💎', '🌟',
];

const List<String> goalColors = [
  'FFD93D', '6BCB77', '4D96FF', 'FF8FAB', 'A29BFE',
  'FAB1A0', '74B9FF', 'F47373', 'F9D423', '4CA1AF',
  'FF9A9E', 'A18CD1',
];

int getDailyQuoteIndex() {
  return DateTime.now().day % quotes.length;
}

Map<String, String> getDailyQuote() {
  return quotes[getDailyQuoteIndex()];
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _finish,
                  child: Text('跳过', style: TextStyle(color: context.themeHint)),
                ),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Slide(emoji: '💰', title: '简单记账', sub: '点击 + 号\n3秒完成一笔记录'),
                  _Slide(emoji: '📊', title: '掌控财务', sub: '预算·目标·现金流\n全面掌握你的财务状况'),
                  _Slide(emoji: '🎯', title: '开始使用', sub: '让每一分钱都有意义', isLast: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(3, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? goldColor : context.themeHint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _page == 2 ? _finish : () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [goldColor, accentColor]),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
                      ),
                      child: Text(_page == 2 ? '开始记账 ✨' : '下一步',
                        style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String emoji, title, sub;
  final bool isLast;
  const _Slide({required this.emoji, required this.title, required this.sub, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: context.themeHeroGradient),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.2), blurRadius: 30)],
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
          ),
          const SizedBox(height: 40),
          Text(title, style: TextStyle(color: context.themeText, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(sub, textAlign: TextAlign.center,
            style: TextStyle(color: context.themeSub, fontSize: 16, height: 1.6)),
        ],
      ),
    );
  }
}

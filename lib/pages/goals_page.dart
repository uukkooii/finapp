import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../core/constants.dart';
import '../providers/goal_provider.dart';
import '../models/goal.dart';

Color _hexToColor(String hex) {
  try { return Color(int.parse('FF$hex', radix: 16)); } catch (_) { return goldColor; }
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _maybeCelebrate(List<Goal> goals) {
    for (final g in goals) {
      if (g.progress >= 1.0) {
        _confettiCtrl.play();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GoalProvider>(context);
    final goals = gp.goals;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate(goals));

    return Stack(children: [
      goals.isEmpty
          ? _EmptyGoals(onAdd: () => _openDialog(context, gp))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildAddButton(context, gp),
                  );
                }
                return _GoalCard(goal: goals[i - 1], provider: gp);
              },
            ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiCtrl,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [goldColor, incomeGreen, accentColor, Colors.amber, Colors.pinkAccent],
          numberOfParticles: 40,
          maxBlastForce: 15,
          minBlastForce: 5,
          gravity: 0.15,
        ),
      ),
    ]);
  }

  Widget _buildAddButton(BuildContext context, GoalProvider gp) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [goldColor, accentColor]),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => _openDialog(context, gp),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('添加目标 ✨', style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ),
        ),
      ),
    );
  }

  static void _openDialog(BuildContext context, GoalProvider gp, [Goal? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final targetCtrl = TextEditingController(
        text: existing != null ? existing.targetAmount.toStringAsFixed(0) : '');
    final currentCtrl = TextEditingController(
        text: existing != null ? existing.currentAmount.toStringAsFixed(0) : '0');
    DateTime? deadline = existing?.deadline != null ? DateTime.parse(existing!.deadline!) : null;
    String? selectedAccount = existing?.account;
    String selectedIcon = existing?.icon ?? goalIcons[0];
    String selectedColor = existing?.color ?? goalColors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: context.themeCard,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing == null ? '🎯 添加目标' : '✏️ 编辑目标',
              style: const TextStyle(color: goldColor, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('选择图标', style: TextStyle(color: context.themeSub, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: goalIcons.map((icon) {
                    final selected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setS(() => selectedIcon = icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: selected ? goldColor.withValues(alpha: 0.2) : context.themeCard,
                          borderRadius: BorderRadius.circular(16),
                          border: selected
                              ? Border.all(color: goldColor, width: 2)
                              : Border.all(color: context.themeDivider),
                        ),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('选择颜色', style: TextStyle(color: context.themeSub, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: goalColors.map((hex) {
                    final color = _hexToColor(hex);
                    final selected = hex == selectedColor;
                    return GestureDetector(
                      onTap: () => setS(() => selectedColor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.transparent, width: 3),
                          boxShadow: selected
                              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _field(context, nameCtrl, '目标名称', '买车、旅行基金...'),
                const SizedBox(height: 12),
                _field(context, targetCtrl, '目标金额', '100000', number: true),
                const SizedBox(height: 12),
                _field(context, currentCtrl, '当前存款', '0', number: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: context.themeBg, borderRadius: BorderRadius.circular(16)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedAccount, isExpanded: true,
                      dropdownColor: context.themeCard,
                      hint: Text('关联账户（可选）', style: TextStyle(color: context.themeHint, fontSize: 14)),
                      style: TextStyle(color: context.themeText, fontSize: 14),
                      items: [
                        DropdownMenuItem<String?>(
                            value: null,
                            child: Text('不关联账户', style: TextStyle(color: context.themeSub))),
                        ...accounts.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
                      ],
                      onChanged: (v) => setS(() => selectedAccount = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: deadline ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(), lastDate: DateTime(2050),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.dark(primary: goldColor)),
                        child: child!,
                      ),
                    );
                    if (d != null) setS(() => deadline = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(color: context.themeBg, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Text('📅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        deadline != null
                            ? '截止：${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}'
                            : '选择截止日期（可选）',
                        style: TextStyle(color: deadline != null ? context.themeText : context.themeHint, fontSize: 14),
                      )),
                      if (deadline != null)
                        GestureDetector(
                          onTap: () => setS(() => deadline = null),
                          child: Icon(Icons.close, color: context.themeHint, size: 16),
                        ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: context.themeSub)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [goldColor, accentColor]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    final name = nameCtrl.text.trim();
                    final target = double.tryParse(targetCtrl.text) ?? 0;
                    final current = double.tryParse(currentCtrl.text) ?? 0;
                    if (name.isEmpty || target <= 0) return;
                    final now = DateTime.now();
                    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                    final dlStr = deadline != null
                        ? '${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}'
                        : null;
                    if (existing == null) {
                      gp.addGoal(Goal(
                        name: name, targetAmount: target, currentAmount: current,
                        deadline: dlStr, createdAt: todayStr, account: selectedAccount,
                        icon: selectedIcon, color: selectedColor,
                      ));
                    } else {
                      gp.updateGoal(existing.copyWith(
                        name: name, targetAmount: target, currentAmount: current,
                        deadline: dlStr, account: selectedAccount,
                        icon: selectedIcon, color: selectedColor,
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(existing == null ? '添加 ✨' : '保存 ✨',
                        style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _field(BuildContext context, TextEditingController ctrl, String label, String hint, {bool number = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: context.themeText),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: context.themeSub),
        hintText: hint, hintStyle: TextStyle(color: context.themeHint),
        filled: true, fillColor: context.themeBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: goldColor)),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final GoalProvider provider;
  const _GoalCard({required this.goal, required this.provider});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final remaining = goal.targetAmount - goal.currentAmount;
    final monthly = goal.id != null ? provider.getMonthlySavingNeeded(goal.id!) : null;
    final isDone = progress >= 1.0;
    final ringColor = goal.color != null ? _hexToColor(goal.color!) : goldColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.themeCard, ringColor.withValues(alpha: 0.07)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: isDone
            ? Border.all(color: incomeGreen, width: 1.5)
            : Border.all(color: ringColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: ringColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ringColor.withValues(alpha: 0.3), ringColor.withValues(alpha: 0.1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(goal.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.themeText)),
            if (goal.account != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: ringColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(goal.account!, style: TextStyle(fontSize: 10, color: ringColor)),
              ),
          ])),
          if (isDone) const Text('🎉', style: TextStyle(fontSize: 22)),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: ringColor, size: 20),
            onPressed: () => _GoalsPageState._openDialog(context, provider, goal),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: expenseRed, size: 20),
            onPressed: () => _confirmDelete(context),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('¥${goal.currentAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ringColor)),
            Text('/ ¥${goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, color: context.themeSub)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: (isDone ? incomeGreen : ringColor).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: isDone ? incomeGreen : ringColor)),
          ),
        ]),
        const SizedBox(height: 12),
        _GradientProgressWithHearts(progress: progress, color: ringColor),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (!isDone)
            Text('还差 ¥${remaining.toStringAsFixed(0)} 🎯',
                style: TextStyle(fontSize: 12, color: context.themeSub))
          else
            const Text('🎊 目标达成！太棒了！',
                style: TextStyle(fontSize: 12, color: incomeGreen, fontWeight: FontWeight.bold)),
          if (monthly != null && !isDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text('每月存 ¥${monthly.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: goldColor)),
            ),
        ]),
        if (goal.deadline != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Text('📅', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text('截止 ${goal.deadline}',
                style: TextStyle(fontSize: 11, color: context.themeHint)),
          ]),
        ],
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('😢 删除目标', style: TextStyle(color: expenseRed)),
        content: Text('确认删除「${goal.name}」？此操作无法撤销。',
            style: TextStyle(color: context.themeText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: context.themeSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: expenseRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
            onPressed: () { provider.deleteGoal(goal.id!); Navigator.pop(ctx); },
            child: Text('删除', style: TextStyle(color: context.themeText)),
          ),
        ],
      ),
    );
  }
}

class _GradientProgressWithHearts extends StatelessWidget {
  final double progress;
  final Color color;
  const _GradientProgressWithHearts({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      const milestones = [0.25, 0.5, 0.75, 1.0];
      return Stack(clipBehavior: Clip.none, children: [
        Container(height: 10,
          decoration: BoxDecoration(color: context.themeDivider, borderRadius: BorderRadius.circular(10))),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: progress >= 1.0
                      ? [incomeGreen, const Color(0xFF00C97A)]
                      : [color.withValues(alpha: 0.7), color],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        ...milestones.map((m) {
          final reached = progress >= m;
          final x = width * m - 9;
          return Positioned(
            left: x.clamp(0.0, width - 18), top: -7,
            child: Text(reached ? '❤️' : '🤍', style: const TextStyle(fontSize: 14, height: 1)),
          );
        }),
      ]);
    });
  }
}

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: const Text('🎯', style: TextStyle(fontSize: 80)),
        ),
        const SizedBox(height: 20),
        Text('还没有财务目标 😊',
            style: TextStyle(fontSize: 20, color: context.themeText, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('设定目标，让每一分钱都有方向 ✨',
            style: TextStyle(color: context.themeHint, fontSize: 13)),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [goldColor, accentColor]),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.transparent, borderRadius: BorderRadius.circular(50),
            child: InkWell(
              borderRadius: BorderRadius.circular(50), onTap: onAdd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                child: Text('🌟 添加第一个目标',
                    style: TextStyle(color: context.themeText, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

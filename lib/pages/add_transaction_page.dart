import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import 'account_manage_page.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? existing;
  final String? initialType;
  const AddTransactionPage({super.key, this.existing, this.initialType});

  static Future<void> show(BuildContext context, {Transaction? edit, String? initialType}) {
    final tp = Provider.of<TransactionProvider>(context, listen: false);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: AddTransactionPage(existing: edit, initialType: initialType),
      ),
    );
  }

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  String _type = 'expense';
  String _amountStr = '0';
  String _selectedCategory = '餐饮';
  String _selectedAccount = '银行卡';
  DateTime _date = DateTime.now();
  bool _showFeedback = false;
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _amountStr = e.amount.toStringAsFixed(e.amount == e.amount.roundToDouble() ? 0 : 2);
      _selectedCategory = e.category;
      _selectedAccount = e.account;
      _date = DateTime.parse(e.date);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _numPress(String key) {
    setState(() {
      if (key == 'del') {
        _amountStr = _amountStr.length > 1
            ? _amountStr.substring(0, _amountStr.length - 1)
            : '0';
      } else if (key == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else if (_amountStr.contains('.')) {
          final decimals = _amountStr.split('.')[1];
          if (decimals.length < 2) _amountStr += key;
        } else {
          _amountStr += key;
        }
      }
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountStr) ?? 0;
    if (amount <= 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('⚠️  请输入有效金额', style: TextStyle(color: context.themeText)),
            ],
          ),
          backgroundColor: expenseRed.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final t = Transaction(
      id: widget.existing?.id,
      type: _type,
      amount: amount,
      category: _selectedCategory,
      account: _selectedAccount,
      date: dateStr,
    );
    final tp = Provider.of<TransactionProvider>(context, listen: false);
    if (widget.existing != null) {
      await tp.updateTransaction(t);
    } else {
      await tp.addTransaction(t);
    }
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _showFeedback = true);
      _feedbackController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final feedbackEmoji = _type == 'income' ? '💰' : '💸';

    return Stack(
      children: [
        Container(
          height: screenHeight * 0.88,
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              _dragHandle(),
              _typeToggle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _categoryGrid(),
                      _moreSection(),
                    ],
                  ),
                ),
              ),
              _amountDisplay(),
              _numpad(),
              _saveButton(),
              SizedBox(height: bottomInset),
            ],
          ),
        ),
        if (_showFeedback)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _feedbackController,
                  builder: (_, __) {
                    final scale = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                            parent: _feedbackController, curve: Curves.elasticOut))
                        .value;
                    final opacity = Tween<double>(begin: 1.0, end: 0.0)
                        .animate(CurvedAnimation(
                            parent: _feedbackController,
                            curve: const Interval(0.5, 1.0)))
                        .value;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Text(
                          feedbackEmoji,
                          style: const TextStyle(fontSize: 90),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: context.themeHint,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _typeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _typeBtn('expense', '💸 支出', expenseRed),
          _typeBtn('income', '💰 收入', incomeGreen),
        ],
      ),
    );
  }

  Widget _typeBtn(String type, String label, Color activeColor) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = type == 'income' ? '工资' : '餐饮';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(46),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? context.themeText : context.themeSub,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    const expenseQuickCats = ['餐饮', '交通', '购物', '娱乐', '住房', '日用', '零食', '其他'];
    const incomeQuickCats = ['工资', '副业', '投资', '其他'];
    final catNames = _type == 'income' ? incomeQuickCats : expenseQuickCats;
    final filtered = categories.where((c) => catNames.contains(c['name'])).toList();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = filtered[i];
          final selected = _selectedCategory == c['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c['name']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56, height: 64,
              decoration: BoxDecoration(
                color: selected ? goldColor.withValues(alpha: 0.2) : context.themeDivider,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? goldColor : context.themeDivider),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(c['name']!, style: TextStyle(fontSize: 9, color: selected ? goldColor : context.themeHint)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _moreSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: _accountDropdown()),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManagePage())),
            child: const Icon(Icons.settings, size: 20, color: goldColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: _datePicker()),
        ],
      ),
    );
  }

  Widget _accountDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAccount,
          dropdownColor: context.themeCard,
          style: TextStyle(color: context.themeText),
          isExpanded: true,
          items: Provider.of<AccountProvider>(context, listen: false).accounts
              .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: (v) => setState(() => _selectedAccount = v!),
        ),
      ),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: goldColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              '${_date.year}/${_date.month}/${_date.day}',
              style: TextStyle(color: context.themeText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountDisplay() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.themeCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _type == 'income' ? '💚 ' : '🔴 ',
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            '¥ $_amountStr',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _numpad() {
    const keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', 'del'],
    ];
    return Container(
      color: context.themeCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: keys
            .map((row) => Row(
                  children: row
                      .map((key) => Expanded(
                            child: InkWell(
                              onTap: () => _numPress(key),
                              borderRadius: BorderRadius.circular(16),
                              splashColor: goldColor.withValues(alpha: 0.2),
                              child: Container(
                                height: 58,
                                alignment: Alignment.center,
                                child: key == 'del'
                                    ? Icon(Icons.backspace_outlined,
                                        color: context.themeSub, size: 22)
                                    : Text(
                                        key,
                                        style: TextStyle(
                                            fontSize: 26, color: context.themeText),
                                      ),
                              ),
                            ),
                          ))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }

  Widget _saveButton() {
    final isIncome = _type == 'income';
    return Container(
      color: context.themeCard,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isIncome
                ? [incomeGreen, const Color(0xFF00C97A)]
                : [goldColor, accentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: (isIncome ? incomeGreen : goldColor).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isIncome ? '💰' : '💸', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(
                    '记 账',
                    style: TextStyle(
                      color: context.themeBg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('✨', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

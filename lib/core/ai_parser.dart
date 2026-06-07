/// AI记账智能解析引擎 —— 离线本地运行，无需联网
/// 支持中文自然语言输入，自动识别类型、金额、分类、账户、日期

class AiAccountParser {
  final Map<String, String> _categoryKeywords;

  AiAccountParser() : _categoryKeywords = _buildKeywords();

  static Map<String, String> _buildKeywords() {
    return {
      // 支出类
      '餐饮': '饭,吃,餐,外卖,食堂,馆子,火锅,烧烤,麻辣烫,面,粉,粥,早餐,午餐,晚餐,夜宵,奶茶,咖啡,饮料,零食,水果,买菜,菜市场',
      '交通': '打车,滴滴,地铁,公交,火车,高铁,飞机,加油,停车,过路费,共享单车,骑行,车票,机票',
      '购物': '买,淘宝,京东,拼多多,衣服,鞋,包,化妆品,护肤品,日用品,超市,便利店,数码,手机,电脑',
      '娱乐': '电影,唱歌,KTV,游戏,旅游,景点,门票,演出,按摩,健身,游泳,打球',
      '住房': '房租,房贷,物业,水电,燃气,暖气,维修,装修',
      '通讯': '话费,流量,宽带,网费',
      '医疗': '医院,药,看病,体检,挂号,牙科',
      '教育': '书,课程,培训,考试,学费',
      '人情': '红包,礼金,礼物,结婚,生日,请客',
      '日用': '纸巾,洗衣,清洁,快递,理发,宠物',
      '服饰': '衣服,裤子,裙子,鞋,帽,首饰',
      '零食': '零食,糖果,巧克力,冰淇淋,饼干,薯片',
      // 收入类
      '工资': '工资,薪水,年终奖,奖金,补贴,报销,加班费',
      '副业': '兼职,副业,接单,外包,稿费,设计,翻译',
      '投资': '股票,基金,理财,利息,分红,房租收入,股息',
      '其他': '',
    };
  }

  ParsedResult parse(String input) {
    if (input.trim().isEmpty) return ParsedResult.empty();

    final text = input.trim();

    // 1. 判断类型
    final type = _detectType(text);

    // 2. 提取金额
    final amount = _extractAmount(text);
    if (amount == null) return ParsedResult.empty();

    // 3. 识别分类
    var category = '';
    if (type == 'income') {
      category = _matchCategory(text, ['工资', '副业', '投资']) ?? '其他';
    } else {
      category = _matchCategory(text, [
        '餐饮', '交通', '购物', '娱乐', '住房', '通讯', '医疗', '教育', '人情', '日用', '服饰', '零食',
      ]) ?? '其他';
    }

    // 4. 提取账户
    final account = _extractAccount(text);

    // 5. 提取备注
    final note = _extractNote(text);

    return ParsedResult(
      type: type,
      amount: amount,
      category: category,
      account: account,
      note: note,
    );
  }

  String _detectType(String text) {
    final incomeKeywords = ['收入', '赚', '入账', '到账', '收到', '工资', '奖金', '报销', '盈利', '分红', '利息', '退款', '返现'];
    for (final kw in incomeKeywords) {
      if (text.contains(kw)) return 'income';
    }
    final expenseKeywords = ['花', '支出', '消费', '付', '买', '买', '缴', '交', '还'];
    for (final kw in expenseKeywords) {
      if (text.contains(kw)) return 'expense';
    }
    // Default: expense
    return 'expense';
  }

  double? _extractAmount(String text) {
    // Match patterns: ¥35 / 35元 / 35块 / 35 / 35.5
    final patterns = [
      RegExp(r'¥\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'(\d+(?:\.\d{1,2})?)\s*元'),
      RegExp(r'(\d+(?:\.\d{1,2})?)\s*块'),
      RegExp(r'花了?\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'用了?\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'支付\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'收入\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'赚了?\s*(\d+(?:\.\d{1,2})?)'),
      // Last resort: find any number
      RegExp(r'(\d+(?:\.\d{1,2})?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final val = double.tryParse(match.group(1)!);
        if (val != null && val > 0 && val < 100000000) return val;
      }
    }
    return null;
  }

  String? _matchCategory(String text, List<String> candidateCategories) {
    for (final cat in candidateCategories) {
      final keywords = _categoryKeywords[cat] ?? '';
      if (keywords.isEmpty) continue;
      for (final kw in keywords.split(',')) {
        if (text.contains(kw.trim())) return cat;
      }
    }
    return null;
  }

  String _extractAccount(String text) {
    const accounts = {
      '微信': ['微信', 'WeChat'],
      '支付宝': ['支付宝', 'Alipay'],
      '银行卡': ['银行卡', '银行', '储蓄卡', '借记卡'],
      '现金': ['现金', '零钱', '钱包'],
    };

    for (final entry in accounts.entries) {
      for (final kw in entry.value) {
        if (text.contains(kw)) return entry.key;
      }
    }
    return '微信'; // default
  }

  String _extractNote(String text) {
    // Remove amount and account info, return the rest as note
    var note = text;
    // Remove ¥xxx / xxx元 / xxx块
    note = note.replaceAll(RegExp(r'¥\s*\d+(?:\.\d{1,2})?'), '');
    note = note.replaceAll(RegExp(r'\d+(?:\.\d{1,2})?\s*[元块]'), '');
    // Remove account keywords
    note = note.replaceAll(RegExp(r'(微信|支付宝|银行卡|现金|零钱|钱包)'), '');
    // Remove type keywords
    note = note.replaceAll(RegExp(r'(花了?|用了?|支付|收入|赚了?|消费)'), '');
    // Trim
    note = note.trim();
    if (note.isEmpty) return '';
    return note;
  }
}

class ParsedResult {
  final String type;
  final double amount;
  final String category;
  final String account;
  final String note;

  const ParsedResult({
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    this.note = '',
  });

  factory ParsedResult.empty() => const ParsedResult(
        type: 'expense',
        amount: 0,
        category: '',
        account: '微信',
      );

  bool get isValid => amount > 0 && category.isNotEmpty;
}

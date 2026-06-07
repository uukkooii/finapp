/// AI记账智能解析引擎 —— 离线本地运行，无需联网
/// 支持中文自然语言输入，自动识别类型、金额、分类、账户、日期

class AiAccountParser {
  final Map<String, String> _categoryKeywords;

  AiAccountParser() : _categoryKeywords = _buildKeywords();

  static Map<String, String> _buildKeywords() {
    return {
      // 支出类
      '零食': '零食,糖果,巧克力,冰淇淋,饼干,薯片,辣条,坚果,瓜子,果冻,蛋糕,面包,甜品',
      '通讯': '话费,流量,宽带,网费,手机费,充值,电话费,套餐',
      '医疗': '医院,看病,体检,挂号,牙科,药店,诊所,感冒药,退烧药,止咳,输液,打针,手术,眼科,体检中心,买药,抓药,开药,拿药',
      '教育': '课程,培训,考试,学费,教材,文具,报名费,网课,得到,知识付费,知乎,买书,购书,书本',
      '交通': '打车,滴滴,地铁,公交,火车,高铁,飞机,加油,停车,过路费,共享单车,骑行,车票,机票,出租车,油费,高速,洗车,保养,修车,4S店,哈喽,青桔,美团单车,曹操出行,T3',
      '住房': '房租,房贷,物业,水电,燃气,暖气,维修,装修,水费,电费,气费,中介费,车位费,交电费,交水费,交物业',
      '娱乐': '电影,唱歌,KTV,游戏,旅游,景点,门票,演出,按摩,健身,游泳,打球,演唱会,音乐节,密室,剧本杀,桌游,游乐场,迪士尼,环球影城,温泉,SPA,网吧,电竞,台球,保龄球',
      '人情': '红包,礼金,礼物,结婚,生日,请客,随礼,份子钱,满月酒,乔迁,白事,压岁钱,孝敬,爸妈,父母,朋友聚会,随份子,请吃饭,请客吃饭,聚餐,请朋友,请了客',
      '服饰': '衣服,裤子,裙子,鞋,首饰,袜子,内衣,围巾,手套,正装,西装,运动鞋,跑鞋,羽绒服,大衣,T恤,衬衫,牛仔裤,包包,买衣服,买鞋,买裤子',
      '日用': '纸巾,洗衣,清洁,理发,剪头,剪发,美发,宠物,狗粮,猫粮,猫砂,日用品,拖把,扫把,垃圾桶,电池,充电线,数据线,手机壳,贴膜,洗衣液,沐浴露,洗发水,牙膏,牙刷,毛巾',
      '购物': '淘宝,京东,拼多多,便利店,数码,电脑,家电,家具,电器,化妆品,护肤品,口红,面膜,香水,代购,海淘,直播,带货,抖音商城,唯品会,苏宁,闲鱼,二手,网购',
      '餐饮': '外卖,食堂,馆子,火锅,烧烤,麻辣烫,粥,早餐,午餐,晚餐,夜宵,奶茶,咖啡,饮料,可乐,雪碧,矿泉水,买菜,菜市场,猪肉,牛肉,鸡肉,鸡蛋,蔬菜,水果,食堂卡,美团外卖,饿了么,麦当劳,肯德基,汉堡王,必胜客,海底捞,西贝,太二,老乡鸡,沙县,兰州拉面,黄焖鸡,杨国福,张亮,茶百道,喜茶,奈雪,蜜雪冰城,CoCo,一点点,星巴克,瑞幸,库迪,霸王茶姬,吃饭,吃面,吃粉,喝咖啡,喝奶茶,喝饮料,买水果,买肉,买鸡蛋,买米,超市买菜,下馆子,撸串,吃火锅,吃烧烤,吃麻辣烫,吃了碗面,吃了个面,吃了碗,吃了饭,吃了顿',
      // 收入类
      '工资': '工资,薪水,年终奖,奖金,补贴,报销,加班费,绩效,提成,底薪,住房公积金',
      '副业': '兼职,副业,接单,外包,稿费,设计,翻译,摄影,剪辑,配音,咨询,家教,代驾,跑腿,摆摊',
      '投资': '股票,基金,理财,利息,分红,房租收入,股息,债券,打新,新股,理财通,余额宝,零钱通',
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
    final incomeKeywords = ['收入', '赚', '入账', '到账', '收到', '工资', '奖金', '报销', '盈利', '分红', '利息', '退款', '返现', '给了', '发了', '转入', '入金', '兼职', '副业', '提成', '补贴'];
    for (final kw in incomeKeywords) {
      if (text.contains(kw)) return 'income';
    }
    final expenseKeywords = ['花', '支出', '消费', '付', '买', '缴', '交', '还', '扣', '用了'];
    for (final kw in expenseKeywords) {
      if (text.contains(kw)) return 'expense';
    }
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
    String? bestCat;
    int bestScore = 0;
    // 电商平台关键词 — 命中表示在购物，需要更高权重
    const platformKeywords = {'淘宝', '京东', '拼多多', '抖音商城', '唯品会', '苏宁', '闲鱼', '代购', '海淘', '直播', '带货', '网购'};
    for (final cat in candidateCategories) {
      final keywords = _categoryKeywords[cat] ?? '';
      if (keywords.isEmpty) continue;
      int score = 0;
      for (final kw in keywords.split(',')) {
        final trimmed = kw.trim();
        if (trimmed.isNotEmpty && text.contains(trimmed)) {
          if (cat == '购物' && platformKeywords.contains(trimmed)) {
            // 电商平台命中：更高权重，确保 淘宝+充电宝 → 购物
            score += 20 + trimmed.length;
          } else if (trimmed.length >= 2) {
            score += 10 + trimmed.length;      // 多字词：正常权重
          } else {
            score += trimmed.length;           // 单字词：极低权重
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCat = cat;
      }
    }
    return bestCat;
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

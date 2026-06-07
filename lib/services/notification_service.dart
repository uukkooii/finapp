import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../pages/add_transaction_page.dart';

/// 通知栏快捷记账服务
/// 在通知栏显示持久通知，点击即可快速记账（类似鲨鱼记账）
class QuickNotifier {
  static final QuickNotifier _instance = QuickNotifier._();
  factory QuickNotifier() => _instance;
  QuickNotifier._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'quick_accounting';
  static const _channelName = '快捷记账';
  static const _notifyId = 1001;

  bool _initialized = false;

  /// 初始化通知插件
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // 创建 Android 通知渠道
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '快捷记账通知，方便随时记录收支',
      importance: Importance.low, // low = 不发出声音
      playSound: false,
      enableVibration: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// 显示通知栏快捷入口
  Future<void> show() async {
    if (!_initialized) await init();

    // Android 13+ 请求通知权限
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '下拉通知栏即可快速记账',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'expense',
          '🔴 支出',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'income',
          '🟢 收入',
          showsUserInterface: true,
        ),
      ],
    );

    await _plugin.show(
      _notifyId,
      '💸 记一笔',
      '点击这里或选择收支类型快速记账',
      NotificationDetails(android: androidDetails),
    );
  }

  /// 取消通知
  Future<void> hide() async {
    await _plugin.cancel(_notifyId);
  }

  /// 点击通知回调 —— 通过全局 navigatorKey 打开页面
  void _onTap(NotificationResponse response) {
    _handleAction(response.actionId ?? response.payload);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    QuickNotifier()._handleAction(response.actionId ?? response.payload);
  }

  void _handleAction(String? type) {
    // 延迟一点确保上下文就绪
    Future.delayed(const Duration(milliseconds: 200), () async {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      if (type == 'income') {
        await AddTransactionPage.show(ctx, initialType: 'income');
      } else {
        await AddTransactionPage.show(ctx, initialType: 'expense');
      }
      // 记账完成后重新显示通知，确保可以反复使用
      show();
    });
  }
}

/// 全局 NavigatorKey，用于从通知回调跳转
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

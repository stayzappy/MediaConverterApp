import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const _channelId = 'conversion_progress';
  static const _channelName = 'Conversion Progress';
  static const _channelDescription = 'Shows media conversion progress';
  static const _notificationId = 1;

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(initSettings);

    // Create the notification channel (Android only)
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high, // Using low importance for ongoing progress notifications
    );

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
  }

  static Future<void> showProgressNotification({
    required int progress,
    required int currentFile,
    required int totalFiles,
    bool isComplete = false,
  }) async {
    if (isComplete) {
      await _notifications.show(
        _notificationId,
        'Conversion Complete',
        'All files have been converted successfully',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            onlyAlertOnce: false,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      return;
    }

    await _notifications.show(
      _notificationId,
      'Converting Files',
      'File $currentFile of $totalFiles ($progress%)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelNotification() async {
    //await _notifications.cancel(_notificationId);
     await _notifications.show(
    _notificationId,
    'Conversion Cancelled',
    'The conversion process was cancelled',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
  }


}
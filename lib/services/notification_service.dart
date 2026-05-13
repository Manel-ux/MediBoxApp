import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // ✅ Initialiser les timezones
    tz.initializeTimeZones();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // ✅ Pas de await — initialize() retourne Future<bool?> 
    // mais on n'en a pas besoin
    _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // ✅ Permission Android 13+ — méthode correcte
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation
          <AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      await androidImpl.requestExactAlarmsPermission();
    }
  }

Future<void> planifierRappelQuotidien({
  required int id,
  required String titre,
  required String corps,
  required TimeOfDay heure,
  bool estAlarme  = false,  // ✅
  int dureeJours  = 0,      // ✅ 0 = infini
}) async {
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, heure.hour, heure.minute);
  if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      estAlarme ? 'alarme_channel' : 'rappels_channel',
      estAlarme ? 'Alarmes Médicales' : 'Rappels Médicaux',
      channelDescription: 'Rappels pour médicaments',
      importance: estAlarme ? Importance.max : Importance.high,
      priority:   estAlarme ? Priority.max   : Priority.high,
      fullScreenIntent: estAlarme,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(
      sound: estAlarme ? 'alarm.aiff' : 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: estAlarme
          ? InterruptionLevel.critical
          : InterruptionLevel.active,
    ),
  );

  if (dureeJours > 0) {
    // ✅ Planifie chaque jour individuellement → s'arrête au bout de N jours
    for (int j = 0; j < dureeJours; j++) {
      final dateJour = scheduled.add(Duration(days: j));
      if (dateJour.isBefore(now)) continue;
      await _plugin.zonedSchedule(
        id + j,
        titre, corps,
        tz.TZDateTime.from(dateJour, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  } else {
    // ✅ Répétition infinie quotidienne
    await _plugin.zonedSchedule(
      id,
      titre, corps,
      tz.TZDateTime.from(scheduled, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

  // ✅ Rappel unique (rendez-vous)
  Future<void> planifierRappelUnique({
    required int id,
    required String titre,
    required String corps,
    required DateTime dateHeure,
  }) async {
    if (dateHeure.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      tz.TZDateTime.from(dateHeure, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rdv_channel',
          'Rappels Rendez-vous',
          channelDescription: 'Rappels pour rendez-vous médicaux',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> annulerRappel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> annulerTous() async {
    await _plugin.cancelAll();
  }

  int genererID() => DateTime.now().millisecondsSinceEpoch % 100000;
}
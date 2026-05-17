import UIKit
import Flutter
import UserNotifications
import flutter_local_notifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ─────────────────────────────────────────────────────────────
    // Required for background isolates (flutter_local_notifications)
    // ─────────────────────────────────────────────────────────────
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // ─────────────────────────────────────────────────────────────
    // iOS notification center delegate
    // ─────────────────────────────────────────────────────────────
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // ─────────────────────────────────────────────────────────────
    // Register Flutter plugins
    // ─────────────────────────────────────────────────────────────
    GeneratedPluginRegistrant.register(with: self)

    // ─────────────────────────────────────────────────────────────
    // IMPORTANT: Enable Firebase messaging auto-handling on iOS
    // ─────────────────────────────────────────────────────────────
    application.registerForRemoteNotifications()

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // ─────────────────────────────────────────────────────────────
  // IMPORTANT: Show notifications while app is in foreground (iOS fix)
  // ─────────────────────────────────────────────────────────────
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Handle notification tap (foreground/terminated fallback)
  // ─────────────────────────────────────────────────────────────
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {

    let userInfo = response.notification.request.content.userInfo

    // Let Firebase handle it if needed
    Messaging.messaging().appDidReceiveMessage(userInfo)

    completionHandler()
  }
}

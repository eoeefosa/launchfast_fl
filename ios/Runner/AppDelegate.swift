import UIKit
import Flutter
import UserNotifications
import flutter_local_notifications
import FirebaseMessaging
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("[iOS][AppDelegate] didFinishLaunchingWithOptions")
    print("[iOS][AppDelegate] FirebaseAppDelegateProxyEnabled = \(Bundle.main.object(forInfoDictionaryKey: "FirebaseAppDelegateProxyEnabled") ?? "nil")")
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("[iOS][AppDelegate] Firebase configured from GoogleService-Info.plist")
    }
    if let firebaseOptions = FirebaseApp.app()?.options {
      print("[iOS][AppDelegate] Firebase configured. projectId=\(firebaseOptions.projectID ?? "nil") appId=\(firebaseOptions.googleAppID)")
    } else {
      print("[iOS][AppDelegate] WARNING: FirebaseApp is not configured yet at launch")
    }

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
      print("[iOS][AppDelegate] UNUserNotificationCenter delegate assigned")
    }

    // ─────────────────────────────────────────────────────────────
    // Register Flutter plugins
    // ─────────────────────────────────────────────────────────────
    GeneratedPluginRegistrant.register(with: self)
    Messaging.messaging().delegate = self
    print("[iOS][AppDelegate] Firebase Messaging delegate assigned")

    // ─────────────────────────────────────────────────────────────
    // IMPORTANT: Enable Firebase messaging auto-handling on iOS
    // ─────────────────────────────────────────────────────────────
    print("[iOS][AppDelegate] Calling registerForRemoteNotifications()")
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
    let userInfo = notification.request.content.userInfo
    print("[iOS][Notifications] willPresent foreground notification userInfo=\(userInfo)")
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
    print("[iOS][Notifications] didReceive response action=\(response.actionIdentifier) userInfo=\(userInfo)")

    // Let Firebase record the message, then forward the tap back to Flutter's
    // delegate chain so firebase_messaging can deliver onMessageOpenedApp /
    // getInitialMessage to Dart.
    Messaging.messaging().appDidReceiveMessage(userInfo)
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("[iOS][APNs] didRegisterForRemoteNotificationsWithDeviceToken token=\(token)")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[iOS][APNs] didFailToRegisterForRemoteNotificationsWithError error=\(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("[iOS][FCM] didReceiveRegistrationToken token=\(fcmToken ?? "nil")")
  }
}

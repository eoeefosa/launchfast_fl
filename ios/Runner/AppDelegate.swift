import UIKit
import Flutter
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Register plugins for background notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // iOS notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}

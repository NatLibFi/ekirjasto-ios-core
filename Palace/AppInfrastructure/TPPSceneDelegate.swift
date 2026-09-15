//
//  TPPSceneDelegate.swift
//  Palace
//
//  Scene-based app lifecycle. Owns the main window; the app-level setup
//  (Firebase, migrations, audiobook lifecycle, appearance, registry, push)
//  stays in TPPAppDelegate.
//

import UIKit

class TPPSceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let newWindow = UIWindow(windowScene: windowScene)
    newWindow.backgroundColor = TPPConfiguration.backgroundColor()
    newWindow.tintColor = TPPConfiguration.mainColor()
    newWindow.tintAdjustmentMode = .normal

    // Publish the window BEFORE building the root view controller. The
    // TPPRootTabBarController singleton constructs its whole tab tree eagerly,
    // and several call sites read `appDelegate.window`; making the window
    // available first preserves the ordering the AppDelegate used to guarantee.
    self.window = newWindow
    if let appDelegate = UIApplication.shared.delegate as? TPPAppDelegate {
      appDelegate.window = newWindow
    }

    newWindow.rootViewController = TPPRootTabBarController.shared()
    newWindow.makeKeyAndVisible()

    // Handle a URL / user activity delivered at launch by forwarding to the
    // existing AppDelegate handlers.
    if let appDelegate = UIApplication.shared.delegate as? TPPAppDelegate {
      if let urlContext = connectionOptions.urlContexts.first {
        _ = appDelegate.application(UIApplication.shared, open: urlContext.url, options: [:])
      }
      if let userActivity = connectionOptions.userActivities.first {
        _ = appDelegate.application(UIApplication.shared, continue: userActivity, restorationHandler: { _ in })
      }
    }
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Moved from applicationDidBecomeActive (not called in scene-based apps).
    TPPErrorLogger.setUserID(TPPUserAccount.sharedAccount().barcode)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url,
          let appDelegate = UIApplication.shared.delegate as? TPPAppDelegate else { return }
    _ = appDelegate.application(UIApplication.shared, open: url, options: [:])
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard let appDelegate = UIApplication.shared.delegate as? TPPAppDelegate else { return }
    _ = appDelegate.application(UIApplication.shared, continue: userActivity, restorationHandler: { _ in })
  }
}

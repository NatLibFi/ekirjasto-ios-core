//
//  TPPAppDelegate.swift
//  Palace
//
//  Created by Vladimir Fedorov on 12/05/2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseDynamicLinks
@main
class TPPAppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  var audiobookLifecycleManager: AudiobookLifecycleManager!
  var reachabilityManager: TPPReachability!
  var notificationsManager: TPPUserNotifications!
  var isSigningIn = false

  // MARK: - Application Lifecycle
  
  func applicationDidFinishLaunching(_ application: UIApplication) {
    FirebaseApp.configure()
    TPPErrorLogger.configureCrashAnalytics()

    // Perform data migrations as early as possible before anything has a chance to access them
    TPPKeychainManager.validateKeychain()
    TPPMigrationManager.migrate()
    
    audiobookLifecycleManager = AudiobookLifecycleManager()
    audiobookLifecycleManager.didFinishLaunching()
    
    TransifexManager.setup()
    
    NotificationCenter.default .addObserver(forName: .TPPIsSigningIn, object: nil, queue: nil, using: signingIn)
    
    // TODO: Remove old reachability functions
    NetworkQueue.shared().addObserverForOfflineQueue()
    reachabilityManager = TPPReachability.shared()
    
    // New reachability notifications
    Reachability.shared.startMonitoring()
    
    // TODO: Refactor this to use SceneDelegate instead
    // If we use SceneDelegate now, the app crashes during TPPRootTabBarController.shared initialization.
    // There can be other places in code that use TPPAppDelegate.window property.
    window = UIWindow()
    window?.tintColor = TPPConfiguration.mainColor()
    window?.tintAdjustmentMode = .normal
    window?.makeKeyAndVisible()
    window?.rootViewController = TPPRootTabBarController.shared()
    
    let safeAreaInsets = window?.safeAreaInsets
    
    
    // UITabBarItemAppearance
    // Customize the appearance of one tab bar item in different states.
    // The tab bar item contains icon image, title text and possible badge
    // States used:
    //   normal   = inactive tab bar item
    //   selected = active tab bar item
    // The appearance we define for the normal state is used as default appearance for tab bar items
    
    let tabBarItemAppearance = UITabBarItemAppearance()
    
    // Set badge position
    // The badge (if appears) is shown in the top right corner of tab bar item
    tabBarItemAppearance.normal.badgePositionAdjustment = UIOffset(
      horizontal: 3.0,
      vertical: 1.0
    )
    
    // Set badge style
    let badgeBackgroundColor = UIColor(named: "ColorEkirjastoRedCircle")
    let badgeForegroundColor = UIColor(named: "ColorEkirjastoAlwaysBlack")!
    let badgeFont = UIFont.boldPalaceFont(ofSize: 11)
    
    tabBarItemAppearance.normal.badgeBackgroundColor = badgeBackgroundColor
    tabBarItemAppearance.normal.badgeTextAttributes = [
      .foregroundColor: badgeForegroundColor,
      .font: badgeFont
    ]
    
    // Set title position
    // Title is shown below the icon in iPhones and on the right side of icon in iPads.
    // Title is positioned with 2 values:
    //    horizontal = positive value moves title to the right, we have set this always to be 5.0
    //    vertical   = positive value moves title downwards, we base this on how much not-used space in bottom we have.
    //    For example in smaller iPhones there is no extra space at bottom (bottomInset is 0.0)
    // iPads have more space so we can set the title font to be even larger than in iPhones.
    let horizontalOffset: CGFloat = 5.0
    
    let verticalOffset: CGFloat
    if let bottomInset = safeAreaInsets?.bottom {
      verticalOffset = CGFloat.minimum(bottomInset, 6.0)
    } else {
      verticalOffset = 6.0
    }

    tabBarItemAppearance.normal.titlePositionAdjustment = UIOffset(
      horizontal: horizontalOffset,
      vertical: verticalOffset
    )
    
    // Set title text style
    let titleFontSize = UIDevice.current.userInterfaceIdiom == .pad ? 18.0 : 12.0
    let ekirjastoFont = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: titleFontSize)
    let systemFont = UIFont.systemFont(ofSize: titleFontSize)

    let titleFont = UIFontMetrics.default.scaledFont(for: ekirjastoFont ?? systemFont)
    
    let titleForegroundColor = TPPConfiguration.compatiblePrimaryColor()
    
    let titleParagraphStyle = NSMutableParagraphStyle()
    titleParagraphStyle.lineBreakMode = .byTruncatingTail
    titleParagraphStyle.allowsDefaultTighteningForTruncation = false
    
    tabBarItemAppearance.normal.titleTextAttributes = [
      .font: titleFont,
      .foregroundColor: titleForegroundColor,
      .paragraphStyle: titleParagraphStyle
    ]
    
    
    // UITabBarAppearance
    // Set the appearance of the tab bar items in tab bar.
    // Use the tabBarItemAppearance we already defined for the one tab bar item
    
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
    tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
    tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
    
    
    // UITabBar
    // Set the appearance of the tab bar (the bottom bar in app)
    // Use the tabBarAppearance already defined for the tab bar
    
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().tintColor = TPPConfiguration.compatiblePrimaryColor()
    UITabBar.appearance().backgroundColor = TPPConfiguration.backgroundColor()
    
    
    // UINavigationBar
    // Set the appearance of the navigation bar (the top bar in app)
    // Two size variations exist:
    //      standardAppearance = used if navigation bar is currently of normal (standard) height
    //      compactAppearance = used if small navigation bar is shown (iPhone in landscape)
    // Standard and compact apperances are used when user is scrolling down the content in view,
    // otherwise the scroll edge apperances are used (for example if there is no scrollable content in view)
    //      scrollEdgeAppearance = used when view is scrolled to top (content top is "touching" the navigation bar)
    
    UINavigationBar.appearance().tintColor = TPPConfiguration.iconColor()
    UINavigationBar.appearance().standardAppearance = TPPConfiguration.defaultAppearance()
    UINavigationBar.appearance().compactAppearance = TPPConfiguration.defaultAppearance()
    UINavigationBar.appearance().scrollEdgeAppearance = TPPConfiguration.defaultAppearance()
    
    if #available(iOS 15.0, *) {
      UINavigationBar.appearance().compactScrollEdgeAppearance = TPPConfiguration.defaultAppearance()
    }

    TPPErrorLogger.logNewAppLaunch()
    
    // Initialize book registry
    _ = TPPBookRegistry.shared
    
    // Push Notificatoins
    NotificationService.shared.setupPushNotifications()
  }
  
  // TODO: This method is deprecated, we should migrate to BGAppRefreshTask in the BackgroundTasks framework instead
  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let startDate = Date()
    if TPPUserNotifications.backgroundFetchIsNeeded() {
      Log.log(String(format: "%@: %@", #function, "[Background Fetch] Starting book registry sync. ElapsedTime=\(-startDate.timeIntervalSinceNow)"))
      TPPBookRegistry.shared.sync { errorDocument, newBooks in
        var result: String
        if errorDocument != nil {
          result = "error document"
          completionHandler(.failed)
        } else if newBooks {
          result = "new ready books available"
          completionHandler(.newData)
        } else {
          result = "no ready books fetched"
          completionHandler(.noData)
        }
        Log.log(String(format: "%@: %@", #function, "[Background Fetch] Completed with \(result). ElapsedTime=\(-startDate.timeIntervalSinceNow)"))
      }
    } else {
      completionHandler(.noData)
    }
  }
  
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    
    
    if let url = userActivity.webpageURL {
      if url.lastPathComponent == "test-login" {
        DLNavigator.shared.navigate(to: url.lastPathComponent,params: [:])
        return true
      }
      
    }
    
    /*if let url = userActivity.webpageURL, DynamicLinks.dynamicLinks().handleUniversalLink(url, completion: { dynamicLink, error in
      if let error {
        // Cannot parse the link
        return
      }
      if let dynamicLink, DLNavigator.shared.isValidLink(dynamicLink) {
        DLNavigator.shared.navigate(to: dynamicLink)
      }
    }) {
      // handleUniversalLink returns true if it receives a link,
      // dynamicLink is processed in the completion handler
    } else if userActivity.activityType == NSUserActivityTypeBrowsingWeb &&
        userActivity.webpageURL?.host == TPPSettings.shared.universalLinksURL.host {
      NotificationCenter.default.post(name: .TPPAppDelegateDidReceiveCleverRedirectURL, object: userActivity.webpageURL)
      return true
    }*/
    return false
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
      if DLNavigator.shared.isValidLink(dynamicLink) {
        DLNavigator.shared.navigate(to: dynamicLink)
      }
      return true
    }
    
    return false
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    TPPErrorLogger.setUserID(TPPUserAccount.sharedAccount().barcode)
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    self.audiobookLifecycleManager.willTerminate()
    NotificationCenter.default.removeObserver(self)
  }
  
  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    self.audiobookLifecycleManager.handleEventsForBackgroundURLSession(for: identifier, completionHandler: completionHandler)
  }
  
  func signingIn(_ notification: Notification) {
    if let boolValue = notification.object as? Bool {
      self.isSigningIn = boolValue
    }
  }
  
}

import UserNotifications

let HoldNotificationCategoryIdentifier = "NYPLHoldToReserveNotificationCategory"
let CheckOutActionIdentifier = "NYPLCheckOutNotificationAction"
let DefaultActionIdentifier = "UNNotificationDefaultActionIdentifier"

@available(iOS 10.0, *)
@objcMembers class TPPUserNotifications: NSObject
{
  typealias DisplayStrings = Strings.UserNotifications
  private let unCenter = UNUserNotificationCenter.current()

  /// If a user has not yet been presented with Notifications authorization,
  /// defer the presentation for later to maximize acceptance rate. Otherwise,
  /// Apple documents authorization to be preformed at app-launch to correctly
  /// enable the delegate.
  func authorizeIfNeeded()
  {
    unCenter.delegate = self
    unCenter.getNotificationSettings { (settings) in
      if settings.authorizationStatus == .notDetermined {
        Log.info(#file, "Deferring first-time UN Auth to a later time.")
      } else {
        self.registerNotificationCategories()
        TPPUserNotifications.requestAuthorization()
      }
    }
  }

  class func requestAuthorization()
  {
    let unCenter = UNUserNotificationCenter.current()
    unCenter.requestAuthorization(options: [.badge,.sound,.alert]) { (granted, error) in
      Log.info(#file, "Notification Authorization Results: 'Granted': \(granted)." +
        " 'Error': \(error?.localizedDescription ?? "nil")")
    }
  }

  /// Create a local notification if a book has moved from the "holds queue" to
  /// the "reserved queue", and is available for the patron to checkout.
  class func compareAvailability(cachedRecord:TPPBookRegistryRecord, andNewBook newBook:TPPBook)
  {
    var wasOnHold = false
    var isNowReady = false
    let oldAvail = cachedRecord.book.defaultAcquisition?.availability
    oldAvail?.matchUnavailable(nil,
                               limited: nil,
                               unlimited: nil,
                               reserved: { _ in wasOnHold = true },
                               ready: nil)
    let newAvail = newBook.defaultAcquisition?.availability
    newAvail?.matchUnavailable(nil,
                               limited: nil,
                               unlimited: nil,
                               reserved: nil,
                               ready: { _ in isNowReady = true })

    if (wasOnHold && isNowReady) {
      createNotificationForReadyCheckout(book: newBook)
    }
  }

  class func updateAppIconBadge(heldBooks: [TPPBook])
  {
    var readyBooks = 0
    for book in heldBooks {
      book.defaultAcquisition?.availability.matchUnavailable(nil,
                                                               limited: nil,
                                                               unlimited: nil,
                                                               reserved: nil,
                                                               ready: { _ in readyBooks += 1 })
    }
    if UIApplication.shared.applicationIconBadgeNumber != readyBooks {
      UIApplication.shared.applicationIconBadgeNumber = readyBooks
    }
  }

  /// Depending on which Notificaitons are supported, only perform an expensive
  /// network operation if it's needed.
  class func backgroundFetchIsNeeded() -> Bool {
    Log.info(#file, "[backgroundFetchIsNeeded] Held Books: \(TPPBookRegistry.shared.heldBooks.count)")
    return TPPBookRegistry.shared.heldBooks.count > 0
  }

  // Notification banner informing the user that a previously reserved book is now available for download
  private class func createNotificationForReadyCheckout(book: TPPBook) {
    let unCenter = UNUserNotificationCenter.current()
    unCenter.getNotificationSettings { (settings) in
      guard settings.authorizationStatus == .authorized else { return }

      let content = UNMutableNotificationContent()
      content.body = String.localizedStringWithFormat(DisplayStrings.readyForDownloadBody, book.title)
      content.title = DisplayStrings.readyForDownloadTitle
      content.sound = UNNotificationSound.default
      content.categoryIdentifier = HoldNotificationCategoryIdentifier
      content.userInfo = ["bookID" : book.identifier]

      let request = UNNotificationRequest.init(identifier: book.identifier,
                                               content: content,
                                               trigger: nil)
      unCenter.add(request) { error in
        if let error = error {
          TPPErrorLogger.logError(error as NSError,
                                   summary: "Error creating notification for ready checkout",
                                   metadata: ["book": book.loggableDictionary()])
        }
      }
    }
  }
  
  // Notification banner informing the user
  // that the book is succesfully added to or removed from user's favorite books
  class func createNotificationBannerForBookSelection(_ book: TPPBook,
                                                      notificationBannerTitle: String,
                                                      notificationBannerMessage: String
  ) {
    
    let center = UNUserNotificationCenter.current()
    
    center.getNotificationSettings {
      settings in
      
      guard settings.authorizationStatus == .authorized else {
        return
      }
      
      let identifier = book.identifier
      
      let content = UNMutableNotificationContent()
      content.title = notificationBannerTitle
      content.body = notificationBannerMessage
      content.sound = UNNotificationSound.default
      content.userInfo = ["bookID": book.identifier]
      
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                      repeats: false)
      
      let request = UNNotificationRequest.init(identifier: identifier,
                                               content: content,
                                               trigger: trigger)
      
      center.add(request) {
        error in
        
        if let error = error {
          TPPErrorLogger.logError(
            error as NSError,
            summary: "Error creating notification banner for book selection",
            metadata: ["book": book.loggableDictionary()])
        }
        
      }
      
    }
    
  }

  private func registerNotificationCategories()
  {
    let checkOutNotificationAction = UNNotificationAction(identifier: CheckOutActionIdentifier,
                                                          title: DisplayStrings.checkoutTitle,
                                                          options: [])
    let holdToReserveCategory = UNNotificationCategory(identifier: HoldNotificationCategoryIdentifier,
                                                       actions: [checkOutNotificationAction],
                                                       intentIdentifiers: [],
                                                       options: [])
    UNUserNotificationCenter.current().setNotificationCategories([holdToReserveCategory])
  }
}

@available(iOS 10.0, *)
extension TPPUserNotifications: UNUserNotificationCenterDelegate
{
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
  {
    completionHandler([.alert])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void)
  {
    if response.actionIdentifier == DefaultActionIdentifier {
      guard let currentAccount = AccountsManager.shared.currentAccount else {
        Log.error(#file, "Error moving to Holds tab from notification; there was no current account.")
        completionHandler()
        return
      }

      if currentAccount.details?.supportsReservations == true {
        if let loansAndHoldsTab = TPPRootTabBarController.shared()?.viewControllers?[1],
           loansAndHoldsTab.isKind(of: LoansAndHoldsViewController.self) {
          TPPRootTabBarController.shared()?.selectedIndex = 1
        } else {
          Log.error(#file, "Error moving to Loans+Holds tab from notification.")
        }
      }
      completionHandler()
    }
    else if response.actionIdentifier == CheckOutActionIdentifier {
      Log.debug(#file, "'Check Out' Notification Action.")
      let userInfo = response.notification.request.content.userInfo
      let downloadCenter = MyBooksDownloadCenter.shared

      guard let bookID = userInfo["bookID"] as? String else {
        Log.error(#file, "Bad user info in Local Notification. UserInfo: \n\(userInfo)")
        completionHandler()
        return
      }
      guard let book = TPPBookRegistry.shared.book(forIdentifier: bookID) else {
          Log.error(#file, "Problem creating book. BookID: \(bookID)")
          completionHandler()
          return
      }

      borrow(book, inBackgroundFrom: downloadCenter, completion: completionHandler)
    }
    else {
      Log.warn(#file, "Unknown action identifier: \(response.actionIdentifier)")
      completionHandler()
    }
  }

  private func borrow(_ book: TPPBook,
                      inBackgroundFrom downloadCenter: MyBooksDownloadCenter,
                      completion: @escaping () -> Void) {
    // Asynchronous network task in the background app state.
    var bgTask: UIBackgroundTaskIdentifier = .invalid
    bgTask = UIApplication.shared.beginBackgroundTask {
      if bgTask != .invalid {
        Log.warn(#file, "Expiring background borrow task \(bgTask.rawValue)")
        completion()
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = .invalid
      }
    }

    Log.debug(#file, "Beginning background borrow task \(bgTask.rawValue)")

    if bgTask == .invalid {
      Log.debug(#file, "Unable to run borrow task in background")
    }

    // bg task body
    downloadCenter.startBorrow(for: book, attemptDownload: false) {
      completion()
      guard bgTask != .invalid else {
        return
      }
      Log.info(#file, "Finishing up background borrow task \(bgTask.rawValue)")
      UIApplication.shared.endBackgroundTask(bgTask)
      bgTask = .invalid
    }
  }
}

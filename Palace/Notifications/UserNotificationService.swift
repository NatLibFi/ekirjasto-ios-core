//
//  UserNotificationService.swift
//

import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - Class UserNotificationService

// Handles Firebase Cloud Messaging (FCM) in the app
// - saving, updating and deleting user's FCM device token
// - receiving push notifications on the user's device send through FCM service

class UserNotificationService:
  NSObject,
  UNUserNotificationCenterDelegate,
  MessagingDelegate
{

  // MARK: - Define data structure for tokens

  // Token Data Overview:
  // - structure is based on the Lyrasis API documentation
  // - token is used to uniquely identify each device for push notifications
  // - if a user has multiple devices with the E-kirjasto app, each device has it's own token
  struct TokenData: Codable {
    let device_token: String
    let token_type: String

    // Creating a TokenData instance.
    // - device_token is received from FCM server.
    // - token_type differentiates Android and iOS devices in backend.
    init(token: String) {
      self.device_token = token
      self.token_type = "FCMiOS"
    }

    // Encoding this TokenData instance to JSON,
    // used in bodies of requests send to backend.
    //  Example:
    //    {
    //      "device_token":"abc123-defghij456789_k10lmnopqrstuvxyz",
    //      "token_type":"FCMiOS"
    //    }
    var data: Data? {
      try? JSONEncoder().encode(self)
    }

  }

  // MARK: - Initialize UserNotificationCenter

  // Create an instance of UNNotificationCenter object
  // to manage notifications within this class
  private let userNotificationCenter = UNUserNotificationCenter.current()

  // Sharing and using only this one UserNotificationService within the app
  static let shared = UserNotificationService()

  // Initializing UserNotificationService instance
  override init() {
    printToConsole(.debug, "Initializing UserNotificationService instance")

    super.init()
    addUserStateObservers()
  }

  // MARK: - Set up FCM notifications

  // Configure the app to receive FCM push notifications
  // - set delegates
  // - request user authorization for notifications.
  // - Parameter completion: Bool, if the user granted permission for notifications
  @objc
  func setupFCMNotifications() {
    printToConsole(.debug, "Setting up push notifications")

    // Set the delegate of the user notification center to this instance
    setupNotificationCenterDelegate()

    // Request authorization for notifications and handle the result
    setupUserPermissions()

    // Set the messaging delegate for FCM service
    setupMessagingDelegate()
  }

  // Set the delegate of the user notification center to handle
  // - incoming notifications
  // - user's responds to the notifications
  private func setupNotificationCenterDelegate() {
    printToConsole(.debug, "Setting the UserNotificationCenter delegate")
    userNotificationCenter.delegate = self
  }

  // Ask for user's permission to show notifications
  // and if given, register for remote notifications
  private func setupUserPermissions() {
    printToConsole(.debug, "UserNotificationCenter requests user's permission to receive notifications")

    let authorizationOptions: UNAuthorizationOptions = [
      .alert,  // display notification alert windows
      .badge,  // display badge on app icon
      .sound,  // play sound
    ]

    // Request authorization for remote AND local notifications
    // Shows the E-kirjasto wants to show you ... window for user
    userNotificationCenter.requestAuthorization(
      options: authorizationOptions
    ) { granted, error in

      // Check if there was an error during the authorization request
      if let error = error {
        printToConsole(.error, "Error requesting notification authorization: \(error.localizedDescription)")
        return
      }

      // granted is
      // - true if user grants authorization for one or more options (alert, badge, sound)
      // - false if user denies authorization or authorization is undetermined
      if granted {
        printToConsole(.debug, "User granted notification authorization.")

        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }

      } else {
        printToConsole(.debug, "User denied notification authorization.")
      }

    }

  }

  // Set the Firebase Cloud Messaging delegate
  private func setupMessagingDelegate() {
    printToConsole(.debug, "Setting the messaging delegate for Firebase Cloud Messaging")

    Messaging.messaging().delegate = self
  }
  
  
  // MARK: - Overview of FCM service and different tokens
  
  // Abbreviations:
  // - APNs = Apple Push Notification service
  // - FCM = Firebase Cloud Messaging
  //
  // Note:
  // - Both services have tokens, but if just "token" is used in this file,
  //   it is used to refer the device's FCM token, not device's APNs token.
  //
  // Differences with iOS and Android devices using FCM service:
  //  1. When user installs E-kirjasto app, user's device registers with the FCM service
  //  2. Device receives tokens from the FCM service
  //      a) iOS device receives 2 tokens:
  //        - FCM token that identifies the device for FCM notifications
  //        - APNs token that is used for delivering notifications on iOS devices
  //      b) Android device receives 1 token:
  //        - FCM token that identifies the device for FCM notifications
  //  3. When the E-kirjasto backend wants to send a notification,
  //       it contacts the FCM server with the specific FCM token
  //   4. How tokens are used in the FCM service
  //     a) iOS devices:
  //        - FCM service uses the APNs token to route the notification through APNs to the user's device
  //     b) Android devices:
  //        - FCM service uses FCM token directly to send notifications to the user's device


  // MARK: - Add observers for user state
  
  // Register observers for notifications
  // related to account change and user logging in events
  // Note: NotificationCenter != UNUserNotificationCenter
  private func addUserStateObservers() {
    
    // Observe when user changes library account in the app
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.TPPCurrentAccountDidChange,
      object: nil,
      queue: nil
    ) { notification in
      self.handleAccountDidChangeStatusChange(notification: notification)
    }
    
    // Observe when user is logging into the app
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.TPPIsSigningIn,
      object: nil,
      queue: nil
    ) { notification in
      self.handleSigningInStatusChange(notification: notification)
    }
    
  }
  
  // Refresh the FCM token when user changes library account
  private func handleAccountDidChangeStatusChange(notification: Notification) {
    // printToConsole(.debug, "User library account has changed, refreshing token.")
    
    // Removed token refresh code from here,
    // because there is no need to refresh token at this point,
    // with the current app initialization and login flow.
    // When the E-kirjasto library account is set, the user is not signed in,
    // and authentication is needed for updating the token.
    // E-kirjasto app is set to use only one library account,
    // and the logged-in user can not change his/her library in the app.
    // Also, accountDidChange notification is send for every book registry sync,
    // and we need to to refresh the FCM token only at login moment.
    
  }
  
  // Refresh the FCM token when user logs in
  private func handleSigningInStatusChange(notification: Notification) {
    
    // Set isSigningIn using the notification object
    guard let isSigningIn = notification.object as? Bool else {
      // Notification object is not a Bool, ignore this notification
      return
    }
    
    if isSigningIn {
      // The user is still logging in so no action is needed at this time.
      printToConsole(.debug, "User is still logging in, no action needed.")
      return
    }
    
    // isSigningIn is false, so the user has completed
    // the signing-in process and we can proceed to refresh the token.
    printToConsole(.debug, "User signing in process has finished, refreshing token.")
    // fetch and save token
  }
  
  
  // MARK: - Fetch FCM token
  
  // Fetch the FCM token for the user's device from the FCM service
  private func fetchFCMTokenFromFCMService(
    completion: @escaping (String?) -> Void
  ) {
    printToConsole(.debug, "Fetching FCM Token from the FCM service...")
    
    // Get FCM token for the device straight from the FCM service
    Messaging.messaging().token { fetchedToken, error in
      
      if let error = error {
        // there was an error fetching the token
        printToConsole(.debug, "Error in fetching FCM token from the FCM service: \(error)")
        
        completion(nil)
      } else if let token = fetchedToken {
        // Successfully fetched the token, return it via the completion handler.
        printToConsole(.debug, "Success in fetching FCM token from the FCM service: \(token)")
        
        completion(token)
      } else {
        // Token is nil for some reason
        printToConsole(.debug, "FCM token is nil, it may not be available yet.")
        
        completion(nil)
      }
      
    }
    
  }
  
  
  // MARK: - For Objective-C compatibility
  
  // Use when UserNotificationService instance is needed in Objective-C code.
  @objc
  static func sharedService() -> UserNotificationService {
    return shared
  }
  
}

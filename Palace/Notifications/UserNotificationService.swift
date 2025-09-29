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


}

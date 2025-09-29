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

}

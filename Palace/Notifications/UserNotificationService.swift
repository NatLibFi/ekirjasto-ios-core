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
  // Code here
}

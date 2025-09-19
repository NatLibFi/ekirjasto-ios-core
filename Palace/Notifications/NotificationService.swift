//
//  NotificationService.swift
//  Palace
//
//  Created by Vladimir Fedorov on 07.10.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import UserNotifications
import FirebaseCore
import FirebaseMessaging

class NotificationService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
  
  /// Token data structure
  /// Based on API documentation
  /// https://www.notion.so/lyrasis/Send-push-notifications-for-reservation-availability-and-loan-expiry-2866943ebe774cbd90b5df81db811648
  ///

  struct TokenData: Codable {
    let device_token: String
    let token_type: String
    
    init(token: String) {
      self.device_token = token
      self.token_type = "FCMiOS"
    }
    
    var data: Data? {
      try? JSONEncoder().encode(self)
    }
    
  }

  private let notificationCenter = UNUserNotificationCenter.current()
  
  static let shared = NotificationService()
  
  override init() {
    super.init()
    
    printToConsole(.debug, "Function init start")
    
    // Update library token when the user changes library account.
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.TPPCurrentAccountDidChange,
      object: nil,
      queue: nil
    ) { _ in
      
      printToConsole(.debug, "TPPCurrentAccountDidChange observed -> updating token")
      
      self.updateToken()
    }
    
    // Update library token when the user signes in (but has already added the library)
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.TPPIsSigningIn,
      object: nil,
      queue: nil
    ) { notification in
      
      if let isSigningIn = notification.object as? Bool, !isSigningIn {
        printToConsole(.debug, "TPPIsSigningIn observed -> updating token")
        
        self.updateToken()
      }
      
    }
  }
  
  @objc
  static func sharedService() -> NotificationService {
    printToConsole(.debug, "Function sharedService start -> return instance of NotificationService")
    
    return shared
  }
  
  /// Runs configuration function, registers the app for remote notifications.
  @objc
  func setupPushNotifications(
    completion: ((_ granted: Bool) -> Void)? = nil
  ) {
    printToConsole(.debug, "Function setupPushNotifications start")
    printToConsole(.debug, "Current permission status for showing notifications: \(UserDefaults.standard.bool(forKey: "granted"))")
    
    notificationCenter.delegate = self
    
    notificationCenter.requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      printToConsole(.debug, "NotificationCenter requested permission to receive notifications, result: \(granted)")
                     
      if granted {
        printToConsole(.debug, "Permission granted -> calling UIApplication.shared.registerForRemoteNotifications() ")
        
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
      
      completion?(granted)
    }
    
    printToConsole(.debug, "Function setupPushNotifications end -> calling Messaging.messaging().delegate = self")
    Messaging.messaging().delegate = self
  }
  
  func getNotificationStatus(completion: @escaping (_ areEnabled: Bool) -> Void) {
    printToConsole(.debug, "Function getNotificationStatus start")
    
    notificationCenter.getNotificationSettings { notificationSettings in
      switch notificationSettings.authorizationStatus {
        case .authorized, .provisional:
            completion(true)
        default:
            completion(false)
        }
    }
    
  }
  
  /// Check if token exists on the server
  /// - Parameters:
  ///   - token: FCM token value
  ///   - completion: `(exists: Bool, error: Error?) -> Void`
  ///
  /// The existence of the token is based on the server response status code:
  /// - 200: exists
  /// - 404 doesn't exist
  /// `exists` is `nil` for any other response status code.
  private func checkTokenExists(
    _ token: String,
    endpointUrl: URL,
    completion: @escaping (Bool?, Error?) -> Void
  ) {
    
    printToConsole(.debug, "Function checkTokenExists start")
    
    guard
      let requestUrl = URL(string: "\(endpointUrl.absoluteString)?device_token=\(token)")
    else {
      return
    }
    
    var request = URLRequest(url: requestUrl)
      
    printToConsole(.debug, "Token check is starting, request URL: \(requestUrl) ")
    
    _ = TPPNetworkExecutor.shared.addBearerAndExecute(request) { result, response, error in
      
      let status = (response as? HTTPURLResponse)?.statusCode
      // Token exists if status code is 200, doesn't exist if 404.
      
      printToConsole(.debug, "Token check is ready, response status: \(status!)")
     
      switch status {
        case 200:
          printToConsole(.debug, "Token exists")
          completion(true, error)
        case 404:
          printToConsole(.debug, "Token does not exist")
          completion(false, error)
        case 401:
          printToConsole(.debug, "We are not authorized for token")
      default: completion(nil, error)
      }
      
    }
    
  }
  
  /// Save token to the server
  /// - Parameter token: FCM token value
  private func saveToken(
    _ token: String,
    endpointUrl: URL
  ) {
    
    printToConsole(.debug, "Function saveToken start")
    
    guard let requestBody = TokenData(token: token).data else {
      return
    }
    
    var request = URLRequest(url: endpointUrl)
    request.httpMethod = "PUT"
    request.httpBody = requestBody
    
    printToConsole(.debug, "Starting saving token, PUT request url: \(endpointUrl)")
    printToConsole(.debug, "Starting saving token, request body: \(String(data: requestBody, encoding: .utf8) ?? "")")
    
    _ = TPPNetworkExecutor.shared.addBearerAndExecute(request) { result, response, error in
      
      if let error = error {
        printToConsole(.debug, "Error in saving token: \(error)")
        
        TPPErrorLogger.logError(error,
                                summary: "Couldn't upload token data",
                                metadata: [
                                  "requestURL": endpointUrl,
                                  "tokenData": String(data: requestBody, encoding: .utf8) ?? "",
                                  "statusCode": (response as? HTTPURLResponse)?.statusCode ?? 0
                                ]
        )
        
      }
      
      printToConsole(.debug, "Success in saving token, result: \(result!)")
      printToConsole(.debug, "Success in saving token, response: \(response!)")
    }
    
  }
  
  /// Sends FCM to the backend
  /// Update token when user account changes
  func updateToken() {
    printToConsole(.debug, "Function updateToken start")
    
    /* We do not currently have this implemented in our backend
    AccountsManager.shared.currentAccount?.getProfileDocument { profileDocument in
      guard let endpointHref = profileDocument?.linksWith(.deviceRegistration).first?.href,
            let endpointUrl = URL(string: endpointHref)
      else {
        return
      }
     */
    
    // just for testing dev!
    let endpointUrl = URL(string: "https://lib-dev.e-kirjasto.fi/ekirjasto/patrons/me/devices/")!
    printToConsole(.debug, "Updating token with endpointUrl: \(endpointUrl)")
      
    // Fetching the push notification token registered for the device
    Messaging.messaging().token { token, _ in
      
      if let token {
        printToConsole(.debug,"Updating token: \(token)")
        
        // Check if token already exists in backend
        self.checkTokenExists(
          token,
          endpointUrl: endpointUrl
        ) { exists, _ in
          
          if let exists = exists, !exists {
            printToConsole(.debug, "Token was not found -> call saveToken")
            
            self.saveToken(token, endpointUrl: endpointUrl)
            //AccountsManager.shared.currentAccount?.hasUpdatedToken = true
          } else {
            printToConsole(.debug, "Token was already saved, do nothing")
            //AccountsManager.shared.currentAccount?.hasUpdatedToken = false
          }
          
        }
      }
      
    //}
    }

  }
    
  private func deleteToken(
    _ token: String,
    endpointUrl: URL
  ) {
    
    printToConsole(.debug, "Function deleteToken from backend start")
    
    guard let requestBody = TokenData(token: token).data else {
      return
    }
    
    var request = URLRequest(url: endpointUrl)
    request.httpMethod = "DELETE"
    request.httpBody = requestBody
    
    printToConsole(.debug, "Starting deleting token, DELETE request url: \(endpointUrl)")
    printToConsole(.debug, "Starting deleting token, request body: \(String(data: requestBody, encoding: .utf8) ?? "")")
    
    _ = TPPNetworkExecutor.shared.addBearerAndExecute(request) { result, response, error in
      
      if let error = error {
        printToConsole(.debug, "Error in deleting token: \(error)")
        
        TPPErrorLogger.logError(error,
                                summary: "Couldn't delete token data",
                                metadata: [
                                  "requestURL": endpointUrl,
                                  "tokenData": String(data: requestBody, encoding: .utf8) ?? "",
                                  "statusCode": (response as? HTTPURLResponse)?.statusCode ?? 0
                                ]
        )
      }
      
      printToConsole(.debug, "Success in deleting token, result: \(result!)")
      printToConsole(.debug, "Success in deleting token, response: \(response!)")
    }
    
  }

  func deleteToken(
    for account: Account
  ) {
    
    printToConsole(.debug, "Function deleteToken from Account start")
    
    account.getProfileDocument { profileDocument in
      guard let endpointHref = profileDocument?.linksWith(.deviceRegistration).first?.href,
            let endpointUrl = URL(string: endpointHref)
      else {
        return
      }
      
      Messaging.messaging().token { token, _ in
        if let token {
          self.deleteToken(token, endpointUrl: endpointUrl)
        }
      }
      
    }
  }
  
  // MARK: - Messaging Delegate
  
  /// Notifies that the token is updated
  public func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    printToConsole(.debug, "Function messaging start -> call updateToken")
    
    updateToken()
  }

  
  // MARK: - Notification Center Delegate Methods
  
  /// Called when the app is in foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    
    printToConsole(.debug, "Function userNotificationCenter willPresent withCompletionHandler start")
    
    // Shows notification banner on screen
    completionHandler([
      .banner,
      .badge,
      .sound
    ])
    
    TPPBookRegistry.shared.sync()
  }
  
  /// Called when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    
    printToConsole(.debug, "Function userNotificationCenter didReceive withCompletionHandler start")
    
    // Shows notification banner on screen
    completionHandler()
    
    // Sync the book registry with server data
    TPPBookRegistry.shared.sync()
  }
  
}

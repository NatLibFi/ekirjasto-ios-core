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

  
  // MARK: - Messaging Delegate Functions
  
  // This function is called when a new FCM registration token is send to the app.
  //
  // FCM token is a String that uniquely identifies the user's device (= app instance on device)
  // and is used for receiving remote (push) notifications.
  //
  // FCM token is send from FCM service to the app automatically
  // after the user's device (= app instance on device) has registered to the FCM service.
  //
  // New FCM token is automatically created for the device when
  // - User installs E-kirjasto app for the device (for the first time or reinstallation after removal)
  // - User restores E-kirjasto app on a new device
  // - User removes E-kirjasto app's app data
  public func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    
    printToConsole(.debug, "Received a device registration token from FCM: \(fcmToken ?? "No FCM token")")
    
    // We need to update the token data stored in our backend FCM token storage,
    // so we can send notifications from our backend to this device using the new token
    updateFCMToken(fcmToken)
  }


  // MARK: - Notification Center Delegate Functions
  
  // This function is called automatically when notification is received on the device
  // and when the app is in the foreground (is currently active).
  // We can define here how the notification is presented to the user,
  // and what else should happen in the app.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (
      UNNotificationPresentationOptions
    ) -> Void
  ) {
    
    printToConsole(.debug, "App will present remote notification to user")
    
    // Define how the notification should be presented to the user.
    let presentationOptions: UNNotificationPresentationOptions = [
      .banner,
      .badge,
      .sound,
    ]
    
    // Call the completion handler with the chosen presentation options,
    // which tells the app to show the notification as a banner,
    // update the icon badge and play a sound
    completionHandler(presentationOptions)
    
    refreshAppData()
  }
  
  // This function is called automatically when the user interacts with the notification,
  // for example if the user opens the app or dismisses the notification.
  // We can define here how to respond to the user's chosen action
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    
    printToConsole(.debug, "User did receive a remote notification")
    
    // User has now selected an action:
    switch response.actionIdentifier {
        
      case UNNotificationDefaultActionIdentifier:
        // The user opened the notification
        printToConsole(.debug, "User opened the nofication")
        
        // Extract the userInfo dictionary from the notification
        let userInfo = response.notification.request.content.userInfo
        printToConsole(.debug, "userInfo: \(userInfo)")
        
        refreshAppData()
        
      case UNNotificationDismissActionIdentifier:
        // The user dismissed the notification
        printToConsole(.debug, "User dismissed the nofication")
        
        // Extract the userInfo dictionary from the notification
        let userInfo = response.notification.request.content.userInfo
        printToConsole(.debug, "userInfo: \(userInfo)")
        
        refreshAppData()
        
      default:
        printToConsole(.debug, "User did something else to the nofication")
        // do nothing
    }
    
    // We must call the completion handler at the end to let the device's system know
    // that we have finished processing the user's action,
    // and the device system can close the notifation.
    completionHandler()
  }


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
    fetchAndAddTokenOnLogin()
  }
  
  
  // MARK: - Refresh FCM token on user login and logout
  
  // Fetches the user's device FCM token from the FCM service
  // and saves it to app's backend storage if it is a new token
  private func fetchAndAddTokenOnLogin() {
    printToConsole(.debug, "Refreshing user's device FCM token...")
    
    // Fetching the token registered for the device from FCM service
    fetchFCMTokenFromFCMService { fetchedToken in
      
      // First check that the token was successfully retrieved
      guard let token = fetchedToken else {
        printToConsole(.debug, "Failed to retrieve FCM token")
        return
      }
      
      // Update the backend storage with retrieved FCM token
      self.updateFCMToken(token)
    }
    
  }
  
  // Fetches the user's device FCM token from the FCM service
  // and deletes it from the app's backend storage if it is found
  func fetchAndRemoveTokenOnLogout(
    completion: @escaping (Bool) -> Void
  ) {
    printToConsole(.debug, "Refreshing user's device FCM token...")
    
    fetchFCMTokenFromFCMService { fetchedToken in
      
      // First check that the token was successfully retrieved
      guard let token = fetchedToken else {
        printToConsole(.debug, "Failed to retrieve FCM token")
        completion(false)
        return
      }
      
      // Clear retrieved FCM token from backend
      self.deleteToken(token) { isDeleted in
        completion(isDeleted)
      }
    }
    
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
  
  
  // MARK: - Create URLs and requests for backend FCM token storage
  
  // Create the base URL for FCM token storage using the user's profile URL.
  // This is the E-kirjasto backend endpoint for app's FCM token related requests.
  // Returns
  // - the created URL
  // - nil, if creating the URL fails
  private func createFCMTokenStorageBaseURL() -> URL? {
    
    // Get the user's profile URL string from the current account
    guard
      let userProfileURLString = AccountsManager.shared.currentAccount?.details?.userProfileUrl,
      let baseURL = URL(string: userProfileURLString),
      var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    else {
      // Note: user account details such as userProfileUrl
      // are only available after the user has logged in
      // so this should always fail before logging in
      printToConsole(.debug, "Could not get acoount's userProfileURL")
      return nil
    }
    
    // Append "devices/" endpoint to the path of the base URL
    components.path += "devices/"
    
    // Check that the constructed URL is valid
    guard let FCMTokenStorageBaseURL = components.url else {
      printToConsole(.debug, "Could not create valid backend FCM token storage URL")
      return nil
    }
    
    return FCMTokenStorageBaseURL
  }
  
  // Create the URL GET request for checking the FCM token.
  private func createCheckTokenRequest(_ token: String) -> URLRequest? {
    
    // Get the base URL for the notification endpoint
    guard let baseURL = createFCMTokenStorageBaseURL() else {
      printToConsole(.debug, "Could not get the backend FCM token storage baseurl.")
      return nil
    }
    
    // Create URL components from the base URL
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    
    // Append the device token as a query parameter
    components?.queryItems = [
      URLQueryItem(
        name: "device_token",
        value: token
      )
    ]
    
    // Check that the url is ok
    guard let requestURL = components?.url else {
      printToConsole(.debug, "Could not create checkTokenRequestURL from components.")
      return nil
    }
    
    // Create the URL request
    var checkTokenRequest = URLRequest(url: requestURL)
    checkTokenRequest.httpMethod = "GET"
    
    printToConsole(.debug, "Request for checking token created: \(checkTokenRequest)")
    
    return checkTokenRequest
  }
  
  // Create the URL PUT request for saving the FCM token.
  private func createSaveTokenRequest(_ token: String) -> URLRequest? {
    
    // Create the base URL for the backend FCM token storage
    guard let FCMTokenStorageBaseURL = createFCMTokenStorageBaseURL() else {
      printToConsole(.debug, "Could not create backend FCM token storage URL")
      return nil
    }
    
    printToConsole(
      .debug,
      "Request URL created for FCM token saving: \(FCMTokenStorageBaseURL)")
    
    // Create the request body from the token data
    guard let requestBody = TokenData(token: token).data
    else {
      printToConsole(.error, "Failed to create request body for token")
      return nil
    }
    
    printToConsole(
      .debug,
      "Request body created for FCM token saving: \(String(describing: String(data: requestBody, encoding: .utf8)))"
    )
    
    // Create the URLRequest object
    var saveTokenRequest = URLRequest(url: FCMTokenStorageBaseURL)
    
    saveTokenRequest.httpMethod = "PUT"
    saveTokenRequest.httpBody = requestBody
    
    return saveTokenRequest
  }
  
  // Create the URL DELETE request for deleting the FCM token.
  private func createDeleteTokenRequest(_ token: String) -> URLRequest? {
    
    // Create the base URL for the backend FCM token storage
    guard let FCMTokenStorageBaseURL = createFCMTokenStorageBaseURL() else {
      printToConsole(.debug, "Could not create backend FCM token storage URL")
      return nil
    }
    
    printToConsole(.debug, "Request URL created for FCM token deletion: \(FCMTokenStorageBaseURL)")
    
    // Create the request body from the token data
    guard let requestBody = TokenData(token: token).data
    else {
      printToConsole(.error, "Failed to create request body for token")
      return nil
    }
    
    printToConsole(
      .debug,
      "Request body created for FCM token deletion: \(String(describing: String(data: requestBody, encoding: .utf8)))"
    )
    
    // Create the URLRequest object
    var deleteTokenRequest = URLRequest(url: FCMTokenStorageBaseURL)
    
    deleteTokenRequest.httpMethod = "DELETE"
    deleteTokenRequest.httpBody = requestBody
    
    return deleteTokenRequest
  }
  
  
  // MARK: - Update FCM token in backend FCM token storage
  
  // Update the FCM token to storage (app backend).
  // If this FCM token is a new token
  //   -> save (create) the token to storage.
  // If this FCM token is already found on storage
  //   -> currently no changes are needed.
  private func updateFCMToken(_ fcmToken: String?) {
    printToConsole(.debug, "Updating FCM token storage...")
    
    guard let token = fcmToken, !token.isEmpty
    else {
      // The FCM token is  nil or empty
      printToConsole(.debug, "Invalid FCM token, cannot update FCM token storage")
      return
    }
    
    // First check if token already exists in our FCM token storage
    checkTokenExists(token) {
      exists, _ in
      
      if let tokenExists = exists {
        // Token existence check was successfully performed
        
        //  Handle the check result
        if tokenExists {
          // FCM token is already stored, no action needed
          printToConsole(.debug, "Token is already stored -> do nothing")
        } else {
          // FCM token was not found, so it is a new token, let's save it
          printToConsole(
            .debug, "Token was not found so it is a new token -> save it")
          self.saveToken(token)
          
          // Update the account status if needed (Palace example code)
          // AccountsManager.shared.currentAccount?.hasUpdatedToken = true
        }
        
      } else {
        // Token existence check failed for some reason
        printToConsole(.debug, "Token check failed -> do nothing")
        
        // Update the account status if needed (Palace example code)
        // AccountsManager.shared.currentAccount?.hasUpdatedToken = false
      }
      
    }
    
  }
  
  // Check if FCM token already exists on the backend FCM token storage.
  // The existence of FCM token is based on the server response status code.
  private func checkTokenExists(
    _ token: String,
    completion: @escaping (Bool?, Error?) -> Void
  ) {
    
    printToConsole(.debug, "Starting token existence check")
    
    guard let request = createCheckTokenRequest(token) else {
      printToConsole(.debug, "Failed to create request for checking token")
      completion(nil, nil)
      return
    }
    
    _ = TPPNetworkExecutor.shared.addBearerAndExecute(request) {
      result, response, error in
      
      // Make sure the response has HTTP status code
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
        printToConsole(.debug,"Check token response is not an HTTP response, no status code.")
        // Return nil for check result and nil for result error
        completion(nil, nil)
        return
      }
      
      // Handle the response from backend
      self.handleTokenCheckReponseStatusCode(
        statusCode,
        error: error,
        completion: completion
      )
      
    }
    
  }
  
  // Handles the HTTP response from the token check request.
  // Returns in completion
  // - true, when FCM token is already found on backend storage (200 OK)
  // - false, when FCM token is not found on backend storage (404 NOT fOUND)
  // Otherwise, returns nil for any other status code.
  // Also returns in completion nil for errors
  private func handleTokenCheckReponseStatusCode(
    _ statusCode: Int,
    error: Error? = nil,
    completion: @escaping (Bool?, Error?) -> Void
  ) {
    
    printToConsole(.debug, "Token check completed with response status: \(String(describing: statusCode))")
    
    // Handle the response status code
    switch statusCode {
      case 200:
        printToConsole(.debug, "FCM token check result: token exists on backend FCM token storage")
        // Return true for token existence + nil for error
        completion(true, nil)
      case 404:
        printToConsole(.debug, "FCM token check result: token does not exist on backend FCM token storage")
        // Return false for token existence + nil for error
        completion(false, nil)
      default:
        printToConsole(.debug, "Token check could not be completed, unexpected response from backend FCM token storage")
        
        // Return nil for token existence + nil for error
        completion(nil, error)  // Return nil for existence and error for error (could be nil)
    }
    
  }
  
  
  // MARK: - Save FCM token to backend FCM token storage
  
  // Save token to the server.
  // - token: FCM token value
  private func saveToken(_ token: String) {
    
    printToConsole(.debug, "Saving FCM token...")
    
    // Create the URL request
    guard
      let saveTokenRequest = createSaveTokenRequest(token)
    else {
      printToConsole(.error, "Failed to create request for saving token")
      return
    }
    
    _ = TPPNetworkExecutor.shared.addBearerAndExecute(saveTokenRequest) {
      _, response, error in
      
      // Check that we have a response
      guard let response = response else {
        // Return false with completion handler, because got no response
        //completion(false)
        return
      }
      
      // Handle the response received from backend
      self.handleTokenSaveResponse(response: response)
      
      // Handle error that occurred during the request
      if let error = error {
        self.handleTokenSaveError(
          error: error,
          request: saveTokenRequest,
          response: response as? HTTPURLResponse,
          tokenData: token
        )
      }
      
    }
  }
  
  // Handle the response received from backend after deleting the FCM token.
  private func handleTokenSaveResponse(response: URLResponse) {
    
    // Extract the HTTP status code from the response
    // use 0 as default if status code is not available
    let responseStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
    
    printToConsole(.debug, "Response status code after sending save token request: \(responseStatusCode)")
    
    switch responseStatusCode {
      case 201:
        // Status code is "201 Created"
        // FCM token saving was successful
        printToConsole(.debug, "FCM token was successfully saved")
      case 200:
        // Status code is "200 OK"
        // FCM token was already found, no need to save
        printToConsole(.debug, "FCM token was already saved")
      case 400:
        // Status code is "400 Bad request"
        // FCM token type was malformatted
        printToConsole(.debug, "FCM token type was wrong for saving")
      default:
        // FCM token save failed for some reason
        printToConsole(.debug, "FCM token save failed")
    }
    
  }
  
  // Handle the error that occured during the token save request
  private func handleTokenSaveError(
    error: Error,
    request: URLRequest,
    response: HTTPURLResponse?,
    tokenData: String
  ) {
    
    // Check that error is not 400
    guard let responseStatusCode = response?.statusCode,
          responseStatusCode != 400
    else {
      // return because 400 is valid known status code
      // for malformatted token
      return
    }
    
    printToConsole(.debug, "Error in saving token: \(error)")
    
    // Short summary message for the error
    let errorSummary = "PUT FCM token request errored"
    
    // Collect error metadata related
    let errorMetadata: [String: Any] = [
      "requestURL": request.url!,
      "tokenData": tokenData,
      "statusCode": response?.statusCode ?? 0,
    ]
    
    TPPErrorLogger.logError(
      error,
      summary: errorSummary,
      metadata: errorMetadata
    )
    
  }
  
  
  // MARK: - Delete FCM token from backend FCM token storage
  
  // Delete the FCM token and call the completion handler with the result.
  // Completion closure returns
  // - true if deletion was success
  // - false otherwise (errors and other failures)
  private func deleteToken(
    _ token: String,
    completion: @escaping (Bool) -> Void
  ) {
    
    printToConsole(.debug, "Deleting FCM token...")
    
    // Create the URL request for deleting the token
    guard let deleteTokenRequest = createDeleteTokenRequest(token) else {
      printToConsole(.error, "Failed to create request for deleting token")
      // Return false, because could not create request
      completion(false)
      return
    }
    
    // Execute the network request to delete the token
    _ = TPPNetworkExecutor.shared.addBearerAndExecute(deleteTokenRequest) {
      _, response, error in
      
      // Check that we have a response
      guard let response = response else {
        // Return false with completion handler, because got no response
        completion(false)
        return
      }
      
      // Handle the response received from backend
      let isDeleted = self.handleTokenDeleteResponse(response: response)
      
      // Handle possible errors that occurred during the request
      if let error = error {
        self.handleTokenDeleteError(
          error: error,
          request: deleteTokenRequest,
          response: response as? HTTPURLResponse,
          tokenData: token
        )
      }
      
      // Return the check result with completion handler,
      // isDeleted could be true or false based on deletion success
      completion(isDeleted)
      
    }
  }
  
  // Handle the response received from backend after deleting the FCM token.
  // Returns
  //  - true if the deletion was successful
  //  - false otherwise
  private func handleTokenDeleteResponse(response: URLResponse) -> Bool {
    
    // Extract the HTTP status code from the response
    // use 0 as default if status code is not available
    let responseStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
    
    printToConsole(.debug, "Response status code after sending delete token request: \(responseStatusCode)")
    
    switch responseStatusCode {
      case 204:
        // Status code is "204 No Content"
        // FCM token was deleted
        printToConsole(.debug, "FCM token was deleted successfully")
        return true
      case 404:
        // Status code is "404 Not Found"
        // FCM token was not found for deletion
        printToConsole(.debug, "FCM token was not found for deletion")
        return false  // should this be true?!
      default:
        // FCM token deletion failed for some reason
        printToConsole(.debug, "FCM token deletion failed")
        
        return false
    }
    
  }
  
  // Handle the error that occured during the FCM token delete request
  private func handleTokenDeleteError(
    error: Error,
    request: URLRequest,
    response: HTTPURLResponse?,
    tokenData: String
  ) {
    
    // Check that error is not 404
    guard let responseStatusCode = response?.statusCode,
          responseStatusCode != 404
    else {
      // return because 404 is valid known status code
      // for token not found on database
      return
    }
    
    printToConsole(.debug, "Error in deleting token: \(error)")
    
    // Short summary message for the error
    let errorSummary = "DELETE FCM token data request errored"
    
    // Collect error metadata related
    let errorMetadata: [String: Any] = [
      "requestURL": request.url!,
      "tokenData": tokenData,
      "statusCode": response?.statusCode ?? 0,
    ]
    
    TPPErrorLogger.logError(
      error,
      summary: errorSummary,
      metadata: errorMetadata
    )
    
  }
  
  // Delete token from account (on library account change).
  // E-kirjasto has only one library, so this is currently never called
  func deleteTokenFromAccount(_ account: Account) {
    // Just commenting this out for now as this function does not work.
    // Also, code related to user changing accounts is not used in current app
    
    /*
     printToConsole(.debug, "Deleting token from account...")
     
     account.getProfileDocument { profileDocument in
     guard let endpointHref = profileDocument?.linksWith(.deviceRegistration).first?.href,
     let endpointUrl = URL(string: endpointHref)
     else {
     return
     }
     
     Messaging.messaging().token { token, _ in
     if let token {
     self.deleteToken(token, FCMTokenStorageBaseURL: endpointUrl)
     }
     }
     
     }
     */
    
  }
  

  // MARK: - Set app icon badge and tab item badge

  // Set the application icon's badge number (value).
  // If the badge value is 0, the badge is automatically hidden.
  func setAppIconBadge(_ badge: Int) {

    // Do update in main thread
    DispatchQueue.main.async {

      if #available(iOS 16.0, *) {
        // For iOS 16 and later,
        // use the user notification center to set the badge count
        self.userNotificationCenter.setBadgeCount(badge)
      } else {
        // For older versions,
        // just set the application icon badge number
        UIApplication.shared.applicationIconBadgeNumber = badge
      }

    }

  }

  // Set the given badge value for specific tab item in the tabbar.
  func setTabItemBadge(_ badge: Int, tabIndex: Int) {

    // Update UI in main thread
    DispatchQueue.main.async {

      // Check that the tab exists
      guard let tab = TPPRootTabBarController.shared().tabBar.items?[tabIndex] else {
        // tab index is not valid, return
        return
      }

      if badge > 0 {
        // if the badge value is greater than 0,
        // set the badge value as a string
        tab.badgeValue = String(badge)
      } else {
        // if the badge value is 0 or negative,
        // set the badge value as nil to hide it.
        tab.badgeValue = nil
      }

    }

  }

  // Updates the app's badges
  // to show the number of books ready to borrow
  func updateAppBadges() {
    printToConsole(.debug, "Starting to update app badges")

    // counter for the number of books that are ready to borrow
    var numberOfBooksReadyToBorrow: Int = 0

    // get all books held by the user from the shared book registry
    let heldBooks = TPPBookRegistry.shared.heldBooks

    for book in heldBooks {
      // first check the availability of the held book
      // then increment the counter if the book is ready to borrow
      book.defaultAcquisition?.availability.matchUnavailable(
        nil,
        limited: nil,
        unlimited: nil,
        reserved: nil,
        ready: {_ in numberOfBooksReadyToBorrow += 1 }
      )

    }

    // update app's icon and loans+holds tab icon
    setAppIconBadge(numberOfBooksReadyToBorrow)
    setTabItemBadge(numberOfBooksReadyToBorrow, tabIndex: 1)

  }


  // MARK: - Show local notification when book is available

  // Display a notification banner to inform the user
  // that a previously reserved book is now available for download
  func showBookIsAvailableNotification(_ book: TPPBook) {

    // First check if the user has granted permission for notifications
    checkNotificationAuthorization { isAuthorized in

      guard isAuthorized else {
        // User has not given permission for notifications
        // just return because we can not show the notification
        return
      }

      // create the actual content for the notification
      // using the book data
      let notificationContent = self.createBookIsAvailableNotificationContent(book)

      // create a new notification request
      // with the book's identifier and the notification content.
      let notificationRequest = self.createRequestForLocalNotification(
        notificationIdentifier: book.identifier,
        notificationContent: notificationContent
      )

      // Schedule the notification to be delivered to the user
      self.scheduleDeliveryForLocalNotification(notificationRequest)
    }

 }

  // Creates the content for the local notification that
  // informs the user that the previously reserved book is now available for download
  private func createBookIsAvailableNotificationContent(_ book: TPPBook) -> UNMutableNotificationContent {

    // add the book identifier to the custom data of the notification
    // so we can identify the book later if necessary.
    let notificationUserInfo: [String: Any] = [
      "identifier": book.identifier
    ]

    let notificationTitle = Strings.UserNotifications.readyForDownloadTitle

    let notificationMessage = String.localizedStringWithFormat(
      Strings.UserNotifications.readyForDownloadBody,
      book.title
    )

    // just play the default sound when notification is delivered
    let notificationSound = UNNotificationSound.default

    // create a new instance of UNMutableNotificationContent
    // that has all the needed notification details (payload)
    let notificationContent = UNMutableNotificationContent()

    // UserInfo contains the custom data added to notifications
    notificationContent.userInfo = notificationUserInfo
    notificationContent.title = notificationTitle
    notificationContent.body = notificationMessage
    notificationContent.sound = notificationSound

    return notificationContent
  }


  // MARK: - Local notifications helper functions

  // Creates a notification request for a local notification
  // using the given parameters.
  // - identifier: unique identifier for the notification
  // - content: the content to be displayed in the notification
  // - trigger: when the notification should be delivered
  //   note: trigger is optional and if it is nil,
  //   then the notification is delivered immediately
  private func createRequestForLocalNotification(
    notificationIdentifier: String,
    notificationContent: UNMutableNotificationContent,
    notificationTrigger: UNNotificationTrigger? = nil
  ) -> UNNotificationRequest {

    printToConsole(.debug, "Creating a local notification")

    // Create the notification request
    let notificationRequest = UNNotificationRequest.init(
      identifier: notificationIdentifier,
      content: notificationContent,
      trigger: notificationTrigger
    )

    return notificationRequest
  }


  // Schedules the delivery of a local notification
  // The delivery is scheduled by adding the request
  // to the user notification center
  private func scheduleDeliveryForLocalNotification(_ notificationRequest: UNNotificationRequest) {

    printToConsole(
      .debug,
      "Scheduling a local notification with identifier: \(notificationRequest.identifier)"
    )

    // notificationRequest has all the information needed
    // for the notification,
    // such as the notification payload and trigger information
    userNotificationCenter.add(notificationRequest) { error in

      // Check if there was an error when adding the notification request
      if let error = error {

        // just log the error
        TPPErrorLogger.logError(
          error as NSError,
          summary: "Error creating notification in app",
          metadata: [
            "book": notificationRequest.content.userInfo
          ]
        )

      } else {
        printToConsole(.debug,"Local notification scheduled succesfully")
      }


    }

  }


  // MARK: - Class helper functions
  
  // Make sure app data is refreshed,
  // especially the book registry
  private func refreshAppData() {
    
    // Sync the book registry with the latest data from the server.
    // This makes sure that the app displays up-to-date book data
    // so that the user does not need to refresh manually
    // to see the data the notification informed of.
    TPPBookRegistry.shared.sync()
    
    // do other app data updates here
  }

  // Checks if the user has granted permission for notifications.
  // Returns true in completion handler if user has allowed notifications
  // otherwise return false in completion
  private func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {

      // Get the user's current notification settings
      // getNotificationSettings is async func
      userNotificationCenter.getNotificationSettings { settings in

        // Check if user has given permission for notifications
        // If the authorization status is .authorized,
        // the user has allowed notifications
        let isAuthorized = settings.authorizationStatus == .authorized

        // Call the completion handler with the authorization status (true or false)
        completion(isAuthorized)

      }

  }


  // MARK: - For Objective-C compatibility
  
  // Use when UserNotificationService instance is needed in Objective-C code.
  @objc
  static func sharedService() -> UserNotificationService {
    return shared
  }
  
}

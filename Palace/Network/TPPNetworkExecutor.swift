//
//  TPPNetworkExecutor.swift
//  The Palace Project
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// Use this enum to express either-or semantics in a result.
enum NYPLResult<SuccessInfo> {
  case success(SuccessInfo, URLResponse?)
  case failure(TPPUserFriendlyError, URLResponse?)
}

/// A class that is capable of executing network requests in a thread-safe way.
/// This class implements caching according to server response caching headers,
/// but can also be configured to have a fallback mechanism to cache responses
/// that lack a sufficient set of caching headers. This fallback cache attempts
/// to use the value found in the `max-age` directive of the `Cache-Control`
/// header if present, otherwise defaults to 3 hours.
///
/// The cache lives on both memory and disk.
@objc class TPPNetworkExecutor: NSObject {
  private let urlSession: URLSession
  private let refreshQueue = DispatchQueue(label: "com.palace.token-refresh-queue", qos: .userInitiated)
  private var isRefreshing = false
  private var retryQueue: [URLSessionTask] = []

  /// The delegate of the URLSession.
  private let responder: TPPNetworkResponder

  /// Designated initializer.
  /// - Parameter credentialsProvider: The object responsible with providing cretdentials
  /// - Parameter cachingStrategy: The strategy to cache responses with.
  /// - Parameter delegateQueue: The queue where callbacks will be called.
  @objc init(credentialsProvider: NYPLBasicAuthCredentialsProvider? = nil,
             cachingStrategy: NYPLCachingStrategy,
             delegateQueue: OperationQueue? = nil) {
    self.responder = TPPNetworkResponder(credentialsProvider: credentialsProvider,
                                          useFallbackCaching: cachingStrategy == .fallback)

    let config = TPPCaching.makeURLSessionConfiguration(
      caching: cachingStrategy,
      requestTimeout: TPPNetworkExecutor.defaultRequestTimeout)
    self.urlSession = URLSession(configuration: config,
                                 delegate: self.responder,
                                 delegateQueue: delegateQueue)
    super.init()
  }

  deinit {
    urlSession.finishTasksAndInvalidate()
  }

  /// A shared generic executor with enabled fallback caching.
  @objc static let shared = TPPNetworkExecutor(cachingStrategy: .fallback)

  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  func GET(_ reqURL: URL,
           useTokenIfAvailable: Bool = true,
           completion: @escaping (_ result: NYPLResult<Data>) -> Void) {
    let req = request(for: reqURL, useTokenIfAvailable: useTokenIfAvailable)
    executeRequest(req, completion: completion)
  }
}

extension TPPNetworkExecutor: TPPRequestExecuting {
  
  
  @discardableResult
  func executeRequestWithToken(_ req: URLRequest, completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask {
     return performDataTask(with: req) { result in
      switch result{
      case .failure(let error, let response):
        if req.hasRetried {
          completion(result)
        }else{
          var updatedRequest = req
          updatedRequest.hasRetried = true
          if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
              self.authenticateWithToken(TPPUserAccount.sharedAccount().authToken!) { status in
                if status == 401 {
                  // User needs to login again, remove user's credentials.
                  TPPUserAccount.sharedAccount().removeAll()
                  
                  EkirjastoLoginViewController.show {
                    if let token = TPPUserAccount.sharedAccount().authToken {
                      updatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                      self.executeRequestWithToken(updatedRequest, completion: completion)
                    }else{
                      completion(result)
                    }

                  }
                }else if status == 200 {

                  if let token = TPPUserAccount.sharedAccount().authToken {
                    updatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    self.executeRequestWithToken(updatedRequest, completion: completion)
                  }else{
                    completion(result)
                  }
                }else {
                  completion(result)
                }
              }
            }else {
              completion(result)
            }
          }else{
            completion(result)
          }
        }

      case .success(_, _):
        completion(result)
      }
    }
  }
  
  /*@discardableResult
  func executeRequest(_ req: URLRequest, completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask {
    var resultTask: URLSessionDataTask?
    
    if let authDefinition = TPPUserAccount.sharedAccount().authDefinition, authDefinition.isSaml {
      resultTask = performDataTask(with: req, completion: completion)
    } else if !TPPUserAccount.sharedAccount().authTokenHasExpired || !req.isTokenAuthorized || req.hasRetried {
      if req.hasRetried {
        let error = NSError(domain: TPPErrorLogger.clientDomain, code: TPPErrorCode.invalidCredentials.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unauthorized HTTP after token refresh attempt"])
        completion(NYPLResult.failure(error, nil))
      } else {
        resultTask = performDataTask(with: req, completion: completion)
      }
    } else {
      handleTokenRefresh(for: req, completion: completion)
    }
    
    return resultTask ?? URLSessionDataTask()
  }*/
  
  /// Executes a given request.
  /// - Parameters:
  ///   - req: The request to perform.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  /// - Returns: The task issueing the given request.
  @discardableResult
  func executeRequest(_ req: URLRequest, completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask {
    var resultTask: URLSessionDataTask?
    
    if let authDefinition = TPPUserAccount.sharedAccount().authDefinition, authDefinition.isSaml {
      resultTask = performDataTask(with: req, completion: completion)
    } else if !TPPUserAccount.sharedAccount().authTokenHasExpired && req.isTokenAuthorized && TPPUserAccount.sharedAccount().authTokenExpirationDate == nil {
      executeRequestWithToken(req, completion: completion)
    } else if !TPPUserAccount.sharedAccount().authTokenHasExpired || !req.isTokenAuthorized || req.hasRetried {
      if req.hasRetried {
        let error = NSError(domain: TPPErrorLogger.clientDomain, code: TPPErrorCode.invalidCredentials.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unauthorized HTTP after token refresh attempt"])
        completion(NYPLResult.failure(error, nil))
      } else {
        resultTask = performDataTask(with: req, completion: { result in
          
          if case .failure(let error, let response) = result {
            if let httpResponse = response as? HTTPURLResponse {
              if httpResponse.statusCode == 401, let authToken = TPPUserAccount.sharedAccount().authToken {
                self.authenticateWithToken(authToken) { status in
                  if status == 401 {
                    // User needs to login again, remove user's credentials.
                    TPPUserAccount.sharedAccount().removeAll()
                    
                    EkirjastoLoginViewController.show {
                      self.executeRequest(req, completion: completion)
                    }
                  }else if status == 200 {
                    self.executeRequest(req, completion: completion)
                  }else{
                    completion(result)
                  }
                }
              } else if httpResponse.statusCode == 401 {
                EkirjastoLoginViewController.show {}
              } else {
                completion(result)
              }
            }else{
              completion(result)
            }
          }else {
            completion(result)
          }

        })
      }
    } else {
      handleTokenRefresh(for: req, completion: completion)
    }
    
    return resultTask ?? URLSessionDataTask()
  }
  
  private func handleTokenRefresh(for req: URLRequest, completion: @escaping (_: NYPLResult<Data>) -> Void) {
    refreshTokenAndResume(task: nil) { [weak self] newToken in
      guard let strongSelf = self else { return }
      
      if let token = newToken {
        var updatedRequest = req
        updatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        updatedRequest.hasRetried = true
        strongSelf.executeRequest(updatedRequest, completion: completion)
      } else {
        let error = NSError(domain: TPPErrorLogger.clientDomain, code: TPPErrorCode.invalidCredentials.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unauthorized HTTP"])
        completion(NYPLResult.failure(error, nil))
      }
    }
  }
  private func performDataTask(with request: URLRequest,
                               completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask {
    let task = urlSession.dataTask(with: request)
    responder.addCompletion(completion, taskID: task.taskIdentifier)
    Log.info(#file, "Task \(task.taskIdentifier): starting request \(request.loggableString)")
    task.resume()
    return task
  }
}

extension TPPNetworkExecutor {
  @objc func request(for url: URL, useTokenIfAvailable: Bool = true) -> URLRequest {

    var urlRequest = URLRequest(url: url,
                                cachePolicy: urlSession.configuration.requestCachePolicy)

    if let authToken = TPPUserAccount.sharedAccount().authToken, useTokenIfAvailable {
      let headers = [
        "Authorization" : "Bearer \(authToken)",
        "Content-Type" : "application/json"
      ]

      headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
    }
    
    var preferredLocalizations:String = Bundle.main.preferredLocalizations[0]
    if Bundle.main.preferredLocalizations.count > 1 {
      preferredLocalizations += ", \(Bundle.main.preferredLocalizations[1]);q=0.9"
    }
    if Bundle.main.preferredLocalizations.count > 2 {
      preferredLocalizations += ", \(Bundle.main.preferredLocalizations[2]);q=0.8"
    }
    
    urlRequest.setValue(preferredLocalizations, forHTTPHeaderField: "Accept-Language")
    return urlRequest
  }

  @objc func clearCache() {
    urlSession.configuration.urlCache?.removeAllCachedResponses()
  }
}

// Objective-C compatibility
extension TPPNetworkExecutor {
  @objc class func bearerAuthorized(request: URLRequest) -> URLRequest {
    let headers: [String: String]
    if let authToken = TPPUserAccount.sharedAccount().authToken, !authToken.isEmpty {
      headers = [
        "Authorization" : "Bearer \(authToken)",
        "Content-Type" : "application/json"]
    } else {
      headers = [
        "Authorization" : "",
        "Content-Type" : "application/json"]
    }

    var request = request
    for (headerKey, headerValue) in headers {
      request.setValue(headerValue, forHTTPHeaderField: headerKey)
    }
    return request
  }

  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func download(_ reqURL: URL,
                      completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDownloadTask {
    let req = request(for: reqURL)
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }

    let task = urlSession.downloadTask(with: req)
    responder.addCompletion(completionWrapper, taskID: task.taskIdentifier)
    task.resume()

    return task
  }

  /// Performs a GET request using the specified URL, if oauth token is available, it is added to the request
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func addBearerAndExecute(_ request: URLRequest,
                     completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDataTask {
    let req = TPPNetworkExecutor.bearerAuthorized(request: request)
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    return executeRequest(req, completion: completionWrapper)
  }

  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func GET(_ reqURL: URL,
                 cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy,
                 completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDataTask {
    var req = request(for: reqURL)
    req.cachePolicy = cachePolicy
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    return executeRequest(req, completion: completionWrapper)
  }

  /// Performs a PUT request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to PUT.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func PUT(_ reqURL: URL,
                 completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDataTask {
    var req = request(for: reqURL)
    req.httpMethod = "PUT"
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    return executeRequest(req, completion: completionWrapper)
  }
    
  /// Performs a POST request using the specified request
  /// - Parameters:
  ///   - request: Request to be posted..
  ///   - completion: Always called when the api call either returns or times out
  @discardableResult
  @objc
  func POST(_ request: URLRequest,
            completion: ((_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void)?) -> URLSessionDataTask {
    
    if (request.httpMethod != "POST") {
      var newRequest = request
      newRequest.httpMethod = "POST"
      return POST(newRequest, completion: completion)
    }
    
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion?(data, response, nil)
      case let .failure(error, response): completion?(nil, response, error)
      }
    }
    
    return executeRequest(request, completion: completionWrapper)
  }
  
  func refreshTokenAndResume(task: URLSessionTask?, completion: ((String?) -> Void)? = nil) {
    refreshQueue.async { [weak self] in
      guard let self = self else { return }
      guard !self.isRefreshing else {
        completion?(nil)
        return
      }
      
      self.isRefreshing = true
      
      guard let username = TPPUserAccount.sharedAccount().username,
            let password = TPPUserAccount.sharedAccount().pin else {
        Log.info(#file, "Failed to refresh token due to missing credentials!")
        self.isRefreshing = false
        completion?(nil)
        return
      }
      
      if let task = task {
        self.retryQueue.append(task)
      }
      
      self.executeTokenRefresh(username: username, password: password) { result in
        defer { self.isRefreshing = false }
        
        switch result {
        case .success:
          var newTasks = [URLSessionTask]()
          
          self.retryQueue.forEach { oldTask in
            guard let originalRequest = oldTask.originalRequest,
                  let url = originalRequest.url else {
              return
            }
            
            let mutableRequest = self.request(for: url)
            let newTask = self.urlSession.dataTask(with: mutableRequest)
            
            self.responder.updateCompletionId(oldTask.taskIdentifier, newId: newTask.taskIdentifier)
            newTasks.append(newTask)
            
            oldTask.cancel()
          }
          
          newTasks.forEach { $0.resume() }
          self.retryQueue.removeAll()
          
          completion?(nil)
          
        case .failure(let error):
          Log.info(#file, "Failed to refresh token with error: \(error)")
          completion?(nil)
        }
      }
    }
  }


  private func retryFailedRequests() {
    while !retryQueue.isEmpty {
      let task = retryQueue.removeFirst()
      guard let request = task.originalRequest else { continue }
      self.executeRequest(request) { _ in
        Log.info(#file, "Task Successfully resumed after token refresh")
      }
    }
  }

  func authenticateWithToken(_ token: String, completion: ((Int?)->Void)? = nil){
    var currentAccount = AccountsManager.shared.currentAccount
    if currentAccount?.authenticationDocument == nil {
      currentAccount = AccountsManager.shared.accounts().first
    }
    let authenticationDocument = currentAccount?.authenticationDocument
    let authentication = authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    let link = authentication?.links?.first(where: {$0.rel == "authenticate"})
    var request = URLRequest(url: URL(string:link!.href)!)
    request.httpMethod = "POST"
    print("token \(token)")
    request.setValue(
      "Bearer \(token)",
      forHTTPHeaderField: "Authorization"
    )
    print("access token \(token)")
    URLSession.shared.dataTask(with: request){ data, response, error in
      
      if(data != nil){
        do {
          if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
            let sharedAccount = TPPUserAccount.sharedAccount()
            
                if let accessToken = json["access_token"] as? String {
                    print("ACCESS TOKEN \(accessToken)")
                    sharedAccount.setAuthToken(accessToken,barcode: nil, pin: nil, expirationDate: nil)

                }
                if let patronInfo = json["patron_info"] as? String {
                    if let patronData = patronInfo.data(using: .utf8) {
                        if let patronObject = try JSONSerialization.jsonObject(with: patronData, options: []) as? [String: Any] {
                            if let patronPermanentId = patronObject["permanent_id"] as? String {
                              sharedAccount.setPatronPermanentId(patronPermanentId)
                              print("PERMANENT ID \(patronPermanentId)")
                            }
                        }
                    }
                }
            TPPSignInBusinessLogic.getShared { logic in
                      logic?.notifySignIn()
              }
            }
          
        } catch {
            print("Virhe JSONin käsittelyssä: \(error.localizedDescription)")
        }

      } else {
        TPPSignInBusinessLogic.getShared { logic in
          DispatchQueue.main.async {
          logic?.performLogOut()
          }
        }
        print("authenticateWithToken error: \(String(describing: error?.localizedDescription)) data: \(String(describing: String(data:data!,encoding: .utf8)))")
      }
      
      if let httpResponse = response as? HTTPURLResponse {
        completion?(httpResponse.statusCode)
      }else{
        completion?(nil)
      }


    }.resume()
    
  }

  func userInfo(_ complete: (String?)->(Void)){

  }

  func revokeToken(_ sessionId: String? = nil){
    
  }
  
  func executeTokenRefresh(username: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
    let account = TPPUserAccount.sharedAccount()
    guard let tokenURL = TPPUserAccount.sharedAccount().authDefinition?.tokenURL else {
      Log.error(#file, "Unable to refresh token, missing credentials")
      completion(.failure(NSError(domain: "Unable to refresh token, missing credentials", code: 401)))
      return
    }

    Task {
      let tokenRequest = TokenRequest(url: tokenURL, username: username, password: password)
      let result = await tokenRequest.execute()
      
      switch result {
      case .success(let tokenResponse):
        TPPUserAccount.sharedAccount().setAuthToken(
          tokenResponse.accessToken,
          barcode: username,
          pin: password,
          expirationDate: tokenResponse.expirationDate
        )
        completion(.success(tokenResponse))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

private extension URLRequest {
  struct AssociatedKeys {
    static var hasRetriedKey = "hasRetriedKey"
  }
  
  var hasRetried: Bool {
    get {
      return objc_getAssociatedObject(self, &AssociatedKeys.hasRetriedKey) as? Bool ?? false
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.hasRetriedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
    }
  }
}

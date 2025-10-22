//
//  TPPMyBookDownloadCenter.swift
//  Palace
//
//  Created by Maurice Carrier on 6/13/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

#if FEATURE_OVERDRIVE
  import OverdriveProcessor
#endif

@objc class MyBooksDownloadCenter: NSObject, URLSessionDelegate {

  @objc static let shared = MyBooksDownloadCenter()

  private var userAccount: TPPUserAccount
  private var reauthenticator: Reauthenticator
  private var bookRegistry: TPPBookRegistryProvider

  private var bookIdentifierOfBookToRemove: String?
  private var broadcastScheduled = false
  private var session: URLSession!

  private var bookIdentifierToDownloadInfo: [String: MyBooksDownloadInfo] = [:]
  private var bookIdentifierToDownloadProgress: [String: Progress] = [:]
  private var bookIdentifierToDownloadTask: [String: URLSessionDownloadTask] = [:]
  private var taskIdentifierToBook: [Int: TPPBook] = [:]
  private var taskIdentifierToRedirectAttempts: [Int: Int] = [:]

  init(
    userAccount: TPPUserAccount = TPPUserAccount.sharedAccount(),
    reauthenticator: Reauthenticator = TPPReauthenticator(),
    bookRegistry: TPPBookRegistryProvider = TPPBookRegistry.shared
  ) {
    self.userAccount = userAccount
    self.bookRegistry = bookRegistry
    self.reauthenticator = reauthenticator

    super.init()

    #if FEATURE_DRM_CONNECTOR
      if !(AdobeCertificate.defaultCertificate?.hasExpired ?? true) {
        NYPLADEPT.sharedInstance().delegate = self
      }
    #else
      NSLog("Cannot import ADEPT")
    #endif

    let backgroundIdentifier = (Bundle.main.bundleIdentifier ?? "") + ".downloadCenterBackgroundIdentifier"

    let configuration = URLSessionConfiguration.background(withIdentifier: backgroundIdentifier)

    self.session = URLSession(
      configuration: configuration,
      delegate: self,
      delegateQueue: .main
    )

  }


  // MARK: - Get, download and reserve a book

  // This function is called when user selects the download book button.
  // Download book button is the button with text 'Get' or 'Download' or "Reserve".
  @objc func startDownload(
    for book: TPPBook,
    withRequest initedRequest: URLRequest? = nil
  ) {

    if isLoginRequired() {
      // User is not currently logged in in the app

      printToConsole(
        .debug,
        "User is not logged in, stop book downloading and show the E-kirjasto login view"
      )

      // show the E-kirjasto login view for the user and return
      EkirjastoLoginViewController.show {}
      return
    }

    var state = bookRegistry.state(for: book.identifier)
    let location = bookRegistry.location(forIdentifier: book.identifier)
    let loginRequired = userAccount.authDefinition?.needsAuth

    // First check the book's state
    switch state {

      case .Unregistered:
        // This state is expected.
        // If book is unregistered it means
        // that the book is not in book registry.

        // This processing function basically checks
        // if this book can be added to book registry
        // without borrowing it (open access for example)

        // The expected new state set here
        // is .Unregistered for E-kirjasto books
        state = processUnregisteredState(
          for: book,
          location: location,
          loginRequired: loginRequired
        )

      case .Downloading:
        // return because this state means
        // that we already downloading the book
        return

      case .DownloadFailed,
        .DownloadNeeded,
        .Holding,
        .SAMLStarted:
        // These states are expected.
        // Break here and continue with rest of this function
        // to proceed with download
        break

      case .DownloadSuccessful,
        .Used,
        .Unsupported:
        // return because these states mean
        // that the book has already been downloaded
        NSLog("Ignoring nonsensical download request.")
        return

    }

    // If we end up here after state check,
    // then the book state is suitable
    // to proceed with the download
    // and user is already logged in in app.
    // Suitable book state is .Unregistered, DownloadFailed,
    // DownloadNeeded or Holding for Ekirjasto books.
    processDownloadWithCredentials(
      for: book,
      withState: state,
      andRequest: initedRequest
    )

  }

  // Function that checks the state of the book in book registry.
  // If the book is not borrowed for the user, proceed with borrowing the book first.
  // Otherwise, the user has already this book on loan, so proceed straight to download
  private func processDownloadWithCredentials(
    for book: TPPBook,
    withState state: TPPBookState,
    andRequest initedRequest: URLRequest?
  ) {

    printToConsole(
      .info,
      "Starting to process download with credentials for book: \(book.loggableShortString())"
    )

    // Not borrowed yet to user,
    // first we need to add the to book registry
    if state == .Unregistered || state == .Holding {
      startBorrow(
        for: book,
        attemptDownload: true,
        borrowCompletion: nil
      )

    } else {

      #if FEATURE_OVERDRIVE
        if book.distributor == OverdriveDistributorKey
          && book.defaultBookContentType == .audiobook
        {
          
          processOverdriveDownload(
            for: book,
            withState: state
          )
          
          return
        }
      #endif

      // Already borrowed and added to book registry,
      // proceed with download
      processRegularDownload(
        for: book,
        withState: state,
        andRequest: initedRequest
      )

    }

  }

  // First gets the book entry
  // and then adds the book to registry
  // and then moves on to download if no problems occur
  func startBorrow(
    for book: TPPBook,
    attemptDownload shouldAttemptDownload: Bool,
    borrowCompletion: (() -> Void)? = nil
  ) {

    printToConsole(
      .info,
      "Starting to borrow the book: \(book.loggableShortString())"
    )

    bookRegistry.setProcessing(true, for: book.identifier)

    // Get the feed with book url
    TPPOPDSFeed.withURL(
      (book.defaultAcquisition)?.hrefURL,
      shouldResetCache: true
    ) { [weak self] feed, error in

      self?.bookRegistry.setProcessing(false, for: book.identifier)

      // Check that a book object can be created
      // from the book entry
      // that was recieved in the feed
      if let feed = feed,
        let borrowedEntry = feed.entries.first as? TPPOPDSEntry,
        let borrowedBook = TPPBook(entry: borrowedEntry)
      {

        let location = self?.bookRegistry.location(forIdentifier: borrowedBook.identifier)

        let selectionState: BookSelectionState = (borrowedEntry.selected != nil)
          ? .Selected
          : .Unselected

        // Add the book to registry first
        self?.bookRegistry.addBook(
          borrowedBook,
          location: location,
          state: .DownloadNeeded,
          selectionState: selectionState,
          fulfillmentId: nil,
          readiumBookmarks: nil,
          genericBookmarks: nil)

        // then proceed to download
        if shouldAttemptDownload {
          self?.startDownloadIfAvailable(book: borrowedBook)
        }

      } else {
        // Some error happened
        // for example with acquisition url or feed
        self?.processBookDownloadError(
          error: error as? [String: Any],
          book: book
        )

      }

      DispatchQueue.main.async {
        // do this only if completion was passed as parameter
        // (the default is nil for borrowCompletion)
        borrowCompletion?()
      }

    }

  }

  // Check if book is available for user
  // if yes, start the download
  private func startDownloadIfAvailable(book: TPPBook) {

    // Create variable downloadAction,
    // which is a closure that
    // calls function startDownload
    let downloadAction = { [weak self] in
      self?.startDownload(for: book)
    }

    // Get the availability data for this book.
    // First checks the availability status of the book using matchUnavailable function
    // and then continues to the closure (to book download),
    // if book is available for user to get
    book.defaultAcquisition?.availability.matchUnavailable(
      nil,
      limited: { _ in downloadAction() },
      unlimited: { _ in downloadAction() },
      reserved: nil,
      ready: { _ in downloadAction() }
    )

  }

  // Function for handling errors occured during book download
  private func processBookDownloadError(
    error: [String: Any]?,
    book: TPPBook
  ) {

    guard let errorType = error?["type"] as? String else {
      // If error does not have a type
      // just show generic alert and return
      showGenericBorrowFailedAlert(for: book)
      return
    }

    // The rest of this function assumes
    // that a problem document dictionary
    // has been received from the backend
    // because error has type.
    let alertTitle = Strings.DownloadBook.borrowFailedTitle
    var alertMessage: String
    var alert: UIAlertController

    switch errorType {

      case TPPProblemDocument.TypeLoanAlreadyExists:
        alertMessage = Strings.DownloadBook.loanAlreadyExistsAlertMessage

        alert = TPPAlertUtils.alert(
          title: alertTitle,
          message: alertMessage
        )

      case TPPProblemDocument.TypeInvalidCredentials:
        // Note for Ekirjasto
        // Missing authentication and recieved error 401
        // is send as an authentication documentation from backend,
        // not as a problem document.
        // It means that we never end up to this case.
        NSLog("Invalid credentials problem when borrowing a book, present sign in VC")

        reauthenticator.authenticateIfNeeded(
          userAccount,
          usingExistingCredentials: false
        ) { [weak self] in
          self?.startDownload(for: book)
        }

        return

      default:
        // Some other problem document type received with error

        alertMessage = String.localizedStringWithFormat(
          Strings.DownloadBook.borrowFailedMessage,
          book.title
        )

        alert = TPPAlertUtils.alert(
          title: alertTitle,
          message: alertMessage)

        if let error = error {
          TPPAlertUtils.setProblemDocument(
            controller: alert,
            document: TPPProblemDocument.fromDictionary(error),
            append: false
          )
        }

    }

    // Finally show the alert for user
    // formed from the problem document
    DispatchQueue.main.async {

      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )

    }

  }

  // Shows alert to user that the borrow failed for book
  // no extra infomation of error is added
  private func showGenericBorrowFailedAlert(for book: TPPBook) {

    let borrowFailedTitle = Strings.DownloadBook.borrowFailedTitle
    let borrowFailedMessage = String.localizedStringWithFormat(
      Strings.DownloadBook.borrowFailedMessage,
      book.title
    )

    let alert = TPPAlertUtils.alert(
      title: borrowFailedTitle,
      message: borrowFailedMessage
    )

    DispatchQueue.main.async {

      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )

    }

  }

  // This function basically just adds the book to book registry
  // if book is open access and no login is needed for user's account
  // For Ekirjasto, this check usually just returns the state .Unregistered
  private func processUnregisteredState(
    for book: TPPBook,
    location: TPPBookLocation?,
    loginRequired: Bool?
  ) -> TPPBookState {

    // Book state is .Unregistered at the start

    // book.defaultAcquisitionIfBorrow
    //  - this is normally not nil for E-kirjasto books
    //    because books have borrow relation
    let isBorrowAcquisitionDefined = book.defaultAcquisitionIfBorrow != nil

    // book.defaultAcquisitionIfOpenAccess
    //  - this is normally nil for E-kirjasto book
    //    because books are not open access, but licensed
    let isOpenAccessAcquisitionDefined =
      book.defaultAcquisitionIfOpenAccess != nil

    // loginRequired (given as parameter)
    //  - user could be either logged in or logged out in Ekirjasto
    //    but at this point the user should already be logged in.
    let userNeedsToLogin = loginRequired ?? false

    if !isBorrowAcquisitionDefined
      && (isOpenAccessAcquisitionDefined || !userNeedsToLogin)
    {

      // We end up here only if book is not borrowable
      // and it is either open access book or user does not need to login

      let selectionState: BookSelectionState = bookRegistry.selectionState(for: book.identifier)

      bookRegistry.addBook(
        book,
        location: location,
        state: .DownloadNeeded,
        selectionState: selectionState,
        fulfillmentId: nil,
        readiumBookmarks: nil,
        genericBookmarks: nil)

      return .DownloadNeeded
    }

    // This return state is expected in Ekirjasto
    return .Unregistered
  }

  // Check if user needs to login in app
  private func isLoginRequired() -> Bool {

    // Check if user account requires authentication for book actions
    // For Ekirjasto true is always expected (also set as default here...)
    let needsAuthentication = userAccount.authDefinition?.needsAuth ?? true

    // Check if user has valid credentials
    // for Ekirjasto users, this is true if user has logged in in app
    let isAuthenticated = userAccount.hasCredentials()

    // User is not logged in AND the account requires it
    // user needs to login so return true
    if !isAuthenticated || needsAuthentication {
      return true
    }

    // Otherwise return false,
    // login is not required
    return false
  }

  // Create the url request for download
  // and add the download task
  private func processRegularDownload(
    for book: TPPBook,
    withState state: TPPBookState,
    andRequest initedRequest: URLRequest?
  ) {

    printToConsole(
      .info,
      "Starting to process regular download for book: \(book.loggableShortString())"
    )

    let request: URLRequest

    if let initedRequest = initedRequest {
      request = initedRequest

    } else if let url = book.defaultAcquisition?.hrefURL {
      request = TPPNetworkExecutor.bearerAuthorized(request: URLRequest(url: url))

    } else {
      logInvalidURLRequest(
        for: book,
        withState: state,
        url: nil,
        request: nil
      )

      return
    }

    guard let _ = request.url else {

      logInvalidURLRequest(
        for: book,
        withState: state,
        url: book.defaultAcquisition?.hrefURL,
        request: request
      )

      return
    }

    if let cookies = userAccount.cookies,
      state != .SAMLStarted
    {

      handleSAMLStartedState(
        for: book,
        withRequest: request,
        cookies: cookies
      )

    } else {

      clearAndSetCookies()
      addDownloadTask(
        with: request,
        book: book
      )

    }

  }

  private func logInvalidURLRequest(
    for book: TPPBook,
    withState state: TPPBookState,
    url: URL?,
    request: URLRequest?
  ) {
    
    bookRegistry.setState(.SAMLStarted, for: book.identifier)
    
    guard let someCookies = self.userAccount.cookies,
      var mutableRequest = request
    else { return }

    DispatchQueue.main.async { [weak self] in
      
      guard let self = self else { return }

      mutableRequest.cachePolicy = .reloadIgnoringCacheData

      let loginCancelHandler: () -> Void = { [weak self] in
        self?.bookRegistry.setState(.DownloadNeeded, for: book.identifier)
        self?.cancelDownload(for: book.identifier)
      }

      let bookFoundHandler:
        (_ request: URLRequest?, _ cookies: [HTTPCookie]) -> Void = {
          [weak self] request, cookies in
          self?.userAccount.setCookies(cookies)
          self?.startDownload(for: book, withRequest: mutableRequest)
        }

      let problemFoundHandler:
        (_ problemDocument: TPPProblemDocument?) -> Void = {
          [weak self] problemDocument in
          guard let self = self else { return }
          self.bookRegistry.setState(.DownloadNeeded, for: book.identifier)

          self.reauthenticator.authenticateIfNeeded(
            self.userAccount, usingExistingCredentials: false
          ) { [weak self] in
            self?.startDownload(for: book)
          }
        }

      let model = TPPCookiesWebViewModel(
        cookies: someCookies,
        request: mutableRequest,
        loginCompletionHandler: nil,
        loginCancelHandler: loginCancelHandler,
        bookFoundHandler: bookFoundHandler,
        problemFoundHandler: problemFoundHandler,
        autoPresentIfNeeded: true
      )
      
      let cookiesVC = TPPCookiesWebViewController(model: model)
      cookiesVC.loadViewIfNeeded()
      
    }
    
  }

  private func handleSAMLStartedState(
    for book: TPPBook,
    withRequest request: URLRequest,
    cookies: [HTTPCookie]
  ) {
    
    bookRegistry.setState(.SAMLStarted, for: book.identifier)

    DispatchQueue.main.async { [weak self] in
      
      var mutableRequest = request
      mutableRequest.cachePolicy = .reloadIgnoringCacheData

      let model = TPPCookiesWebViewModel(
        cookies: cookies, request: mutableRequest, loginCompletionHandler: nil,
        loginCancelHandler: {
          self?.handleLoginCancellation(for: book)
        },
        bookFoundHandler: { request, cookies in
          self?.handleBookFound(
            for: book, withRequest: request, cookies: cookies)
        },
        problemFoundHandler: { problemDocument in
          self?.handleProblem(for: book, problemDocument: problemDocument)
        }, autoPresentIfNeeded: true)

      let cookiesVC = TPPCookiesWebViewController(model: model)
      cookiesVC.loadViewIfNeeded()
      
    }
  }

  private func handleLoginCancellation(for book: TPPBook) {
    bookRegistry.setState(.DownloadNeeded, for: book.identifier)
    cancelDownload(for: book.identifier)
  }

  private func handleBookFound(
    for book: TPPBook,
    withRequest request: URLRequest?,
    cookies: [HTTPCookie]
  ) {
    userAccount.setCookies(cookies)
    
    if let request = request {
      startDownload(
        for: book,
        withRequest: request
      )
    }
    
  }

  private func handleProblem(
    for book: TPPBook,
    problemDocument: TPPProblemDocument?
  ) {
    
    bookRegistry.setState(.DownloadNeeded, for: book.identifier)
    
    reauthenticator.authenticateIfNeeded(
      userAccount,
      usingExistingCredentials: false
    ) {
      self.startDownload(for: book)
    }
    
  }

  private func clearAndSetCookies() {
    let cookieStorage = session.configuration.httpCookieStorage
    cookieStorage?.cookies?.forEach { cookieStorage?.deleteCookie($0) }
    userAccount.cookies?.forEach { cookieStorage?.setCookie($0) }
  }

  @objc func cancelDownload(for identifier: String) {
    
    guard let info = downloadInfo(forBookIdentifier: identifier) else {
      let state = bookRegistry.state(for: identifier)
      if state != .DownloadFailed {
        NSLog("Ignoring nonsensical cancellation request.")
        return
      }

      bookRegistry.setState(.DownloadNeeded, for: identifier)
      return
    }

    #if FEATURE_DRM_CONNECTOR
      if info.rightsManagement == .adobe {
        NYPLADEPT.sharedInstance().cancelFulfillment(withTag: identifier)
        return
      }
    #endif

    info.downloadTask.cancel { [weak self] resumeData in
      self?.bookRegistry.setState(.DownloadNeeded, for: identifier)
      self?.broadcastUpdate()
    }
    
  }

  // This function is not currently used anywhere
  private func requestCredentialsAndStartDownload(for book: TPPBook) {
    
    #if FEATURE_DRM_CONNECTOR
      if AdobeCertificate.defaultCertificate?.hasExpired ?? false {
        // ADEPT crashes the app with expired certificate.
        TPPAlertUtils.presentFromViewControllerOrNil(
          alertController: TPPAlertUtils.expiredAdobeDRMAlert(),
          viewController: nil, animated: true, completion: nil)
      } else {
        TPPAccountSignInViewController.requestCredentials { [weak self] in
          self?.startDownload(for: book)
        }
      }
    #else
      TPPAccountSignInViewController.requestCredentials { [weak self] in
        self?.startDownload(for: book)
      }
    #endif
    
  }

  #if FEATURE_OVERDRIVE
    private func processOverdriveDownload(
      for book: TPPBook,
      withState state: TPPBookState
    ) {
      guard let url = book.defaultAcquisition?.hrefURL else { return }

      let completion: ([AnyHashable: Any]?, Error?) -> Void = {
        [weak self] responseHeaders, error in
        self?.handleOverdriveResponse(
          for: book, url: url, withState: state,
          responseHeaders: responseHeaders, error: error)
      }

      if let token = userAccount.authToken {
        OverdriveAPIExecutor.shared.fulfillBook(
          urlString: url.absoluteString, authType: .token(token),
          completion: completion)
      } else if let username = userAccount.username, let pin = userAccount.PIN {
        OverdriveAPIExecutor.shared.fulfillBook(
          urlString: url.absoluteString,
          authType: .basic(username: username, pin: pin), completion: completion
        )
      }
    }
  #endif

  #if FEATURE_OVERDRIVE
    private func handleOverdriveResponse(
      for book: TPPBook,
      url: URL?,
      withState state: TPPBookState,
      responseHeaders: [AnyHashable: Any]?,
      error: Error?
    ) {
      let summaryWrongHeaders = "Overdrive audiobook fulfillment: wrong headers"
      let nA = "N/A"
      let responseHeadersKey = "responseHeaders"
      let acquisitionURLKey = "acquisitionURL"
      let bookKey = "book"
      let bookRegistryStateKey = "bookRegistryState"

      if let error = error {
        let summary = "Overdrive audiobook fulfillment error"

        TPPErrorLogger.logError(
          error, summary: summary,
          metadata: [
            responseHeadersKey: responseHeaders ?? nA,
            acquisitionURLKey: url?.absoluteString ?? nA,
            bookKey: book.loggableDictionary,
            bookRegistryStateKey: TPPBookStateHelper.stringValue(from: state),
          ])
        self.failDownloadWithAlert(for: book)
        return
      }

      let normalizedHeaders = responseHeaders?.mapKeys {
        String(describing: $0).lowercased()
      }
      let scopeKey = "x-overdrive-scope"
      let patronAuthorizationKey = "x-overdrive-patron-authorization"
      let locationKey = "location"

      guard let scope = normalizedHeaders?[scopeKey] as? String,
        let patronAuthorization = normalizedHeaders?[patronAuthorizationKey]
          as? String,
        let requestURLString = normalizedHeaders?[locationKey] as? String,
        let request = OverdriveAPIExecutor.shared.getManifestRequest(
          urlString: requestURLString, token: patronAuthorization, scope: scope)
      else {
        TPPErrorLogger.logError(
          withCode: .overdriveFulfillResponseParseFail,
          summary: summaryWrongHeaders,
          metadata: [
            responseHeadersKey: responseHeaders ?? nA,
            acquisitionURLKey: url?.absoluteString ?? nA,
            bookKey: book.loggableDictionary,
            bookRegistryStateKey: TPPBookStateHelper.stringValue(from: state),
          ])
        self.failDownloadWithAlert(for: book)
        return
      }

      self.addDownloadTask(with: request, book: book)
    }
  #endif

}

extension MyBooksDownloadCenter {
  
  
  // MARK: - Return, delete or remove a book

  // This function is called when user selects the delete book button.
  // Delete book button is the button with text 'Return' or 'Delete' or "Remove".
  @objc func returnBook(
    withIdentifier identifier: String,
    completion: (() -> Void)? = nil
  ) {

    if isLoginRequired() {
      // User is not currently logged in in the app

      printToConsole(
        .debug,
        "User is not logged in, stop book returning and show the E-kirjasto login view"
      )

      // show the E-kirjasto login view for the user and return
      EkirjastoLoginViewController.show {}
      return
    }

    defer {
      completion?()
    }

    guard let book = bookRegistry.book(forIdentifier: identifier) else {
      // No book to delete, return
      return
    }

    printToConsole(
      .info,
      "Starting to return the book: \(book.loggableShortString())"
    )

    // book is downloaded if it's state is .DownloadSuccessful or .Used
    let state = bookRegistry.state(for: identifier)
    let isDownloaded = (state == .DownloadSuccessful) || (state == .Used)

    // Process Adobe Return
    // Not used in Ekirjasto
    #if FEATURE_DRM_CONNECTOR
      if let fulfillmentId = bookRegistry.fulfillmentId(forIdentifier: identifier),
        userAccount.authDefinition?.needsAuth == true
      {
        NSLog("Return attempt for book. userID: %@", userAccount.userID ?? "")

        NYPLADEPT.sharedInstance().returnLoan(
          fulfillmentId,
          userID: userAccount.userID,
          deviceID: userAccount.deviceID
        ) { success, error in

          if !success {
            NSLog("Failed to return loan via NYPLAdept.")
          }

        }

      }
    #endif

    if book.revokeURL == nil {
      // no book revoke url so we cannot send request to backend
      // so remove the book data locally and return

      removeBookLocally(
        bookIdentifier: identifier,
        bookIsDownloaded: isDownloaded
      )

      return
    }

    processRegularBookReturn(
      book: book,
      bookIdentifier: identifier,
      bookIsDownloaded: isDownloaded
    )

  }

  // Just clear the user's book registry
  // and local data of book
  func removeBookLocally(
    bookIdentifier: String,
    bookIsDownloaded: Bool
  ) {

    printToConsole(
      .info,
      "Removing book locally"
    )

    if bookIsDownloaded {
      deleteLocalContent(for: bookIdentifier)
    }

    bookRegistry.removeBook(forIdentifier: bookIdentifier)
  }

  // Revoke the book (send request to backend)
  // and remove the book from registry
  // and clean local data
  func processRegularBookReturn(
    book: TPPBook,
    bookIdentifier: String,
    bookIsDownloaded: Bool
  ) {

    printToConsole(
      .info,
      "Starting to process regular return for book: \(book.loggableShortString())"
    )

    bookRegistry.setProcessing(true, for: book.identifier)

    TPPOPDSFeed.withURL(
      book.revokeURL,
      shouldResetCache: false
    ) { feed, error in

      self.bookRegistry.setProcessing(false, for: book.identifier)

      if let feed = feed,
        feed.entries.count == 1,
        let entry = feed.entries[0] as? TPPOPDSEntry
      {

        if bookIsDownloaded {
          self.deleteLocalContent(for: bookIdentifier)
        }

        if let returnedBook = TPPBook(entry: entry) {
          self.bookRegistry.updateAndRemoveBook(returnedBook)
        } else {
          printToConsole(
            .debug,
            "Failed to create book from entry. Book not removed from registry."
          )
        }

      } else {

        self.processBookReturnError(
          error: error as? [String: Any],
          book: book,
          bookIsDownloaded: bookIsDownloaded,
          bookIdentifier: bookIdentifier
        )

      }

    }

  }

  // Function for handling errors occured during book return
  func processBookReturnError(
    error: [String: Any]?,
    book: TPPBook,
    bookIsDownloaded: Bool,
    bookIdentifier: String
  ) {

    printToConsole(
      .info,
      "Processing book return error for book: \(book.loggableShortString())"
    )

    guard let errorType = error?["type"] as? String else {
      // If error does not have a type
      // just show generic alert and return
      showGenericReturnFailedAlert(book: book)
      return
    }

    let alertTitle: String
    var alertMessage: String
    var alert: UIAlertController

    switch errorType {

      case TPPProblemDocument.TypeNoActiveLoan:

        if bookIsDownloaded {
          self.deleteLocalContent(for: bookIdentifier)
        }

        self.bookRegistry.removeBook(forIdentifier: bookIdentifier)

        // do not show alert to user, just return
        return

      case TPPProblemDocument.TypeInvalidCredentials:

        self.reauthenticator.authenticateIfNeeded(
          self.userAccount,
          usingExistingCredentials: false
        ) { [weak self] in
          self?.returnBook(withIdentifier: bookIdentifier)
        }

        // do not show alert to user, just return
        return

      default:

      alertTitle = Strings.ReturnBook.returnFailedTitle

        alertMessage = String.localizedStringWithFormat(
          Strings.ReturnBook.returnFailedMessage,
          book.title
        )

        alert = TPPAlertUtils.alert(
          title: alertTitle,
          message: alertMessage
        )

        if let error = error as? Decoder,
          let document = try? TPPProblemDocument(from: error)
        {
          TPPAlertUtils.setProblemDocument(
            controller: alert,
            document: document,
            append: true
          )
        }

    }

    DispatchQueue.main.async {

      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )

    }

  }

  func showGenericReturnFailedAlert(book: TPPBook) {

    printToConsole(
      .info,
      "Showing generic return failed alert for user"
    )

    let returnFailedTitle = Strings.ReturnBook.returnFailedTitle
    
    let returnFailedMessage = String.localizedStringWithFormat(
      Strings.ReturnBook.returnFailedMessage,
      book.title
    )

    let alert = TPPAlertUtils.alert(
      title: returnFailedTitle,
      message: returnFailedMessage
    )

    DispatchQueue.main.async {

      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )

    }

  }

  // Checks the book type (eBook, audiobook, PDF etc.)
  // and proceeds with correct deletion approach.
  // Note: deleteLocalContent function is also called from book registry
  func deleteLocalContent(
    for identifier: String,
    account: String? = nil
  ) {
    
    printToConsole(
      .info,
      "Start deletion of book local content"
    )

    guard let book = bookRegistry.book(forIdentifier: identifier) else {
      // Book is not found in book registry, return
      return
    }

    guard let currentAccountId = AccountsManager.shared.currentAccountId,
      let bookURL = fileUrl(for: identifier, account: currentAccountId)
    else {
      // Use currentAccountId to determine the book path.
      // It represents the UUID of the library in circulation managed.

      // Return if book file url could not be formed
      NSLog("WARNING: Could not find book to delete local content.")
      return
    }

    do {
      
      switch book.defaultBookContentType {

        case .epub:
            try FileManager.default.removeItem(at: bookURL)

        case .audiobook:
          deleteLocalContentForAudiobook(
            audiobook: book,
            bookURL: bookURL
          )

        case .pdf:
            try FileManager.default.removeItem(at: bookURL)

            #if LCP
              try LCPPDFs.deletePdfContent(url: bookURL)
            #endif

        case .unsupported:
          break

        }

    } catch {

      NSLog("Failed to remove local content for download: \(error.localizedDescription)")

    }

  }

  // This function is called from normal deleteLocalContent function
  // and used only for audiobooks
  func deleteLocalContentForAudiobook(
    audiobook: TPPBook,
    bookURL: URL
  ) {

    printToConsole(
      .info,
      "Deleting local content for an audiobook"
    )

    guard let data = try? Data(contentsOf: bookURL) else {
      // could not get the data to be deleted
      // using the given book url, return
      return
    }

    var dict = [String: Any]()

    #if FEATURE_OVERDRIVE
      if book.distributor == OverdriveDistributorKey {
        if let json = try? JSONSerialization.jsonObject(with: data, options: [])
          as? [String: Any]
        {
          dict = json ?? [String: Any]()
        }

        dict["id"] = audiobook.identifier
      }
    #endif

    #if LCP
    if LCPAudiobooks.canOpenBook(audiobook) {

        let lcpAudiobooks = LCPAudiobooks(for: bookURL)

        lcpAudiobooks?.contentDictionary { dict, error in

          if error != nil {
            // LCPAudiobooks logs this error
            return
          }

          if let dict = dict {
            // Delete decrypted content for the book
            let mutableDict = dict.mutableCopy() as? [String: Any]
            AudiobookFactory.audiobook(mutableDict ?? [:])?.deleteLocalContent()
          }

        }

        // Delete LCP book file
        if FileManager.default.fileExists(atPath: bookURL.path) {

          do {
            try FileManager.default.removeItem(at: bookURL)
          } catch {
            TPPErrorLogger.logError(
              error, summary: "Failed to delete LCP audiobook local content",
              metadata: ["book": audiobook.loggableShortString()])
          }

        }

      } else {
        // Not an LCP book
        AudiobookFactory.audiobook(dict)?.deleteLocalContent()
      }
    #else
      AudiobookFactory.audiobook(dict)?.deleteLocalContent()
    #endif

    cleanAllDecryptedFiles()

  }

  /// - Parameter url: URL to check
  /// - Returns: Whether the URL corresponds to a decrypted file of this task
  /// Cleans all decrypted files from the cache directory, even when audiobook is not available
  func cleanAllDecryptedFiles() {

    printToConsole(
      .info,
      "Cleaning all decrypted files from cache directory"
    )

    guard
      let cacheDirectory = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
      ).first
    else {
      ATLog(.error, "Could not find caches directory.")
      return
    }

    do {
      
      let fileManager = FileManager.default
      
      let cachedFiles = try fileManager.contentsOfDirectory(
        at: cacheDirectory,
        includingPropertiesForKeys: nil
      )

      var filesRemoved = 0

      for file in cachedFiles {
        let fileName = file.lastPathComponent
        let fileExtension = file.pathExtension.lowercased()
        let nameWithoutExtension = file.deletingPathExtension().lastPathComponent

        // Check if the file name is a SHA-256 hash (64 characters hex)
        let isHashedFile = nameWithoutExtension.count == 64
          && nameWithoutExtension.range(of: "^[A-Fa-f0-9]{64}$", options: .regularExpression) != nil
        
        // Check if it's an audio file
        let isAudioFile = ["mp3", "m4a", "m4b"].contains(fileExtension)

        if isHashedFile && isAudioFile {
          
          do {
            try fileManager.removeItem(at: file)
            filesRemoved += 1
            ATLog(.debug, "Removed cached file: \(fileName)")
          } catch {
            ATLog(.warn, "Could not delete cached file: \(fileName)", error: error)
          }
          
        }
        
      }

      ATLog(.debug, "Cache cleanup completed. Removed \(filesRemoved) files.")

    } catch {
      ATLog(.error, "Error accessing cache directory", error: error)
    }
    
  }
  
}


extension MyBooksDownloadCenter: URLSessionDownloadDelegate {
  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didResumeAtOffset fileOffset: Int64,
    expectedTotalBytes: Int64
  ) {
    NSLog("Ignoring unexpected resumption.")
  }
  
  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    let key = downloadTask.taskIdentifier
    guard let book = taskIdentifierToBook[key] else {
      return
    }
    
    if bytesWritten == totalBytesWritten {
      guard let mimeType = downloadTask.response?.mimeType else { return }
      
      switch mimeType {
      case ContentTypeAdobeAdept:
        bookIdentifierToDownloadInfo[book.identifier] =
        downloadInfo(forBookIdentifier: book.identifier)?.withRightsManagement(.adobe)
      case ContentTypeReadiumLCP:
        bookIdentifierToDownloadInfo[book.identifier] =
        downloadInfo(forBookIdentifier: book.identifier)?.withRightsManagement(.lcp)
      case ContentTypeEpubZip:
        bookIdentifierToDownloadInfo[book.identifier] =
        downloadInfo(forBookIdentifier: book.identifier)?.withRightsManagement(.none)
      case ContentTypeBearerToken:
        bookIdentifierToDownloadInfo[book.identifier] =
        downloadInfo(forBookIdentifier: book.identifier)?.withRightsManagement(.simplifiedBearerTokenJSON)
#if FEATURE_OVERDRIVE
      case "application/json":
        bookIdentifierToDownloadInfo[book.identifier] =
        downloadInfo(forBookIdentifier: book.identifier)?.withRightsManagement(.overdriveManifestJSON)
#endif
      default:
        if TPPOPDSAcquisitionPath.supportedTypes().contains(mimeType) {
          NSLog("Presuming no DRM for unrecognized MIME type \"\(mimeType)\".")
          if let info = downloadInfo(forBookIdentifier: book.identifier)?.withRightsManagement(.none) {
            bookIdentifierToDownloadInfo[book.identifier] = info
          }
        } else {
          NSLog("Authentication might be needed after all")
          downloadTask.cancel()
          bookRegistry.setState(.DownloadFailed, for: book.identifier)
          broadcastUpdate()
          return
        }
      }
    }
  
    let rightsManagement = downloadInfo(forBookIdentifier: book.identifier)?.rightsManagement ?? .none
    if rightsManagement != .adobe && rightsManagement != .simplifiedBearerTokenJSON && rightsManagement != .overdriveManifestJSON {
      if totalBytesExpectedToWrite > 0 {
        bookIdentifierToDownloadInfo[book.identifier] =
        downloadInfo(forBookIdentifier: book.identifier)?
          .withDownloadProgress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        broadcastUpdate()
      }
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let book = taskIdentifierToBook[downloadTask.taskIdentifier] else {
      return
    }
    
    taskIdentifierToRedirectAttempts.removeValue(forKey: downloadTask.taskIdentifier)
    
    var failureRequiringAlert = false
    var failureError = downloadTask.error
    var problemDoc: TPPProblemDocument?
    let rights = downloadInfo(forBookIdentifier: book.identifier)?.rightsManagement ?? .unknown
    
    if let response = downloadTask.response, response.isProblemDocument() {
      do {
        let problemDocData = try Data(contentsOf: location)
        problemDoc = try TPPProblemDocument.fromData(problemDocData)
      } catch let error {
        TPPErrorLogger.logProblemDocumentParseError(error as NSError, problemDocumentData: nil, url: location, summary: "Error parsing problem doc downloading \(String(describing: book.distributor)) book", metadata: ["book": book.loggableShortString])
      }
      
      try? FileManager.default.removeItem(at: location)
      failureRequiringAlert = true
    }
    
    if !book.canCompleteDownload(withContentType: downloadTask.response?.mimeType ?? "") {
      try? FileManager.default.removeItem(at: location)
      failureRequiringAlert = true
    }
    
    if failureRequiringAlert {
      logBookDownloadFailure(book, reason: "Download Error", downloadTask: downloadTask, metadata: ["problemDocument": problemDoc?.dictionaryValue ?? "N/A"])
    } else {
      TPPProblemDocumentCacheManager.sharedInstance().clearCachedDoc(book.identifier)
      
      switch rights {
      case .unknown:
        logBookDownloadFailure(book, reason: "Unknown rights management", downloadTask: downloadTask, metadata: nil)
        failureRequiringAlert = true
      case .adobe:
#if FEATURE_DRM_CONNECTOR
        if let acsmData = try? Data(contentsOf: location),
           let acsmString = String(data: acsmData, encoding: .utf8),
           acsmString.contains(">application/pdf</dc:format>") {
          let msg = NSLocalizedString("\(book.title) is an Adobe PDF, which is not supported.", comment: "")
          failureError = NSError(domain: TPPErrorLogger.clientDomain, code: TPPErrorCode.ignore.rawValue, userInfo: [NSLocalizedDescriptionKey: msg])
          logBookDownloadFailure(book, reason: "Received PDF for AdobeDRM rights", downloadTask: downloadTask, metadata: nil)
          failureRequiringAlert = true
        } else if let acsmData = try? Data(contentsOf: location) {
          NSLog("Download finished. Fulfilling with userID: \(userAccount.userID ?? "")")
          NYPLADEPT.sharedInstance().fulfill(withACSMData: acsmData, tag: book.identifier, userID: userAccount.userID, deviceID: userAccount.deviceID)
        }
#endif
      case .lcp:
        fulfillLCPLicense(fileUrl: location, forBook: book, downloadTask: downloadTask)
      case .simplifiedBearerTokenJSON:
        if let data = try? Data(contentsOf: location) {
          if let dictionary = TPPJSONObjectFromData(data) as? [String: Any],
             let simplifiedBearerToken = MyBooksSimplifiedBearerToken.simplifiedBearerToken(with: dictionary) {
            let mutableRequest = NSMutableURLRequest(url: simplifiedBearerToken.location)
            mutableRequest.setValue("Bearer \(simplifiedBearerToken.accessToken)", forHTTPHeaderField: "Authorization")
            
            let task = session.downloadTask(with: mutableRequest as URLRequest)
            bookIdentifierToDownloadInfo[book.identifier] = MyBooksDownloadInfo(
              downloadProgress: 0.0,
              downloadTask: task,
              rightsManagement: .none,
              bearerToken: simplifiedBearerToken
            )
            book.bearerToken = simplifiedBearerToken.accessToken
            taskIdentifierToBook[task.taskIdentifier] = book
            task.resume()
          } else {
            logBookDownloadFailure(book, reason: "No Simplified Bearer Token in deserialized data", downloadTask: downloadTask, metadata: nil)
            failDownloadWithAlert(for: book)
          }
        } else {
          logBookDownloadFailure(book, reason: "No Simplified Bearer Token data available on disk", downloadTask: downloadTask, metadata: nil)
          failDownloadWithAlert(for: book)
        }
      case .overdriveManifestJSON:
        failureRequiringAlert = !replaceBook(book, withFileAtURL: location, forDownloadTask: downloadTask)
      case .none:
        failureRequiringAlert = !moveFile(at: location, toDestinationForBook: book, forDownloadTask: downloadTask)
      }
    }
    
    if failureRequiringAlert {
      DispatchQueue.main.async {
        let hasCredentials = self.userAccount.hasCredentials()
        let loginRequired = self.userAccount.authDefinition?.needsAuth ?? false
        if downloadTask.response?.indicatesAuthenticationNeedsRefresh(with: problemDoc) == true || (!hasCredentials && loginRequired) {
          self.reauthenticator.authenticateIfNeeded(
            self.userAccount,
            usingExistingCredentials: hasCredentials,
            authenticationCompletion: nil
          )
        }
        self.alertForProblemDocument(problemDoc, error: failureError, book: book)
      }
      bookRegistry.setState(.DownloadFailed, for: book.identifier)
    }
    
    broadcastUpdate()
  }

  @objc func downloadInfo(forBookIdentifier bookIdentifier: String) -> MyBooksDownloadInfo? {
    bookIdentifierToDownloadInfo[bookIdentifier]
  }

  private func broadcastUpdate() {
    guard !broadcastScheduled else { return }
    
    broadcastScheduled = true
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.broadcastUpdateNow()
    }
  }

  private func broadcastUpdateNow() {
    broadcastScheduled = false
    
    NotificationCenter.default.post(
      name: Notification.Name.TPPMyBooksDownloadCenterDidChange,
      object: self
    )
  }
}

extension MyBooksDownloadCenter: URLSessionTaskDelegate {
  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
      let handler = TPPBasicAuth(credentialsProvider: userAccount)
      handler.handleChallenge(challenge, completion: completionHandler)
    }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    let maxRedirectAttempts: UInt = 10
    
    var redirectAttempts = self.taskIdentifierToRedirectAttempts[task.taskIdentifier] ?? 0
    
    if redirectAttempts >= maxRedirectAttempts {
      completionHandler(nil)
      return
    }
    
    redirectAttempts += 1
    self.taskIdentifierToRedirectAttempts[task.taskIdentifier] = redirectAttempts
    
    let authorizationKey = "Authorization"

    // Since any "Authorization" header will be dropped on redirection for security
    // reasons, we need to again manually set the header for the redirected request
    // if we originally manually set the header to a bearer token. There's no way
    // to use URLSession's standard challenge handling approach for bearer tokens.
    if let originalAuthorization = task.originalRequest?.allHTTPHeaderFields?[authorizationKey],
       originalAuthorization.hasPrefix("Bearer") {
      // Do not pass on the bearer token to other domains.
      if task.originalRequest?.url?.host != request.url?.host {
        completionHandler(request)
        return
      }
      
      
      // Prevent redirection from HTTPS to a non-HTTPS URL.
      if task.originalRequest?.url?.scheme == "https" && request.url?.scheme != "https" {
        completionHandler(nil)
        return
      }
      
      var mutableAllHTTPHeaderFields = request.allHTTPHeaderFields ?? [:]
      mutableAllHTTPHeaderFields[authorizationKey] = originalAuthorization
      
      var mutableRequest = URLRequest(url: request.url!)
      mutableRequest.allHTTPHeaderFields = mutableAllHTTPHeaderFields
      
      completionHandler(mutableRequest)
    } else {
      completionHandler(request)
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    guard let book = self.taskIdentifierToBook[task.taskIdentifier] else {
      return
    }
    
    self.taskIdentifierToRedirectAttempts.removeValue(forKey: task.taskIdentifier)
    
    if let error = error as NSError?, error.code != NSURLErrorCancelled {
      //If the error is CannotDecodeRawData error, most likely the book format is one we can't handle, so inform user
      if(error.code == NSURLErrorCannotDecodeRawData){
        logBookDownloadFailure(book, reason: "unsupported book format", downloadTask: task, metadata: ["urlSessionError" : error])
        failDownloadWithAlert(for: book, withMessage: "Unsupported book format.")
      } else {
        //Else throw a generic error without a message
        logBookDownloadFailure(book, reason: "networking error", downloadTask: task, metadata: ["urlSessionError": error])
        failDownloadWithAlert(for: book)
      }
      return
    }
  }

  private func  addDownloadTask(with request: URLRequest, book: TPPBook) {
    let task = self.session.downloadTask(with: request)
    
    self.bookIdentifierToDownloadInfo[book.identifier] =
    MyBooksDownloadInfo(downloadProgress: 0.0,
                           downloadTask: task,
                           rightsManagement: .unknown)

    self.taskIdentifierToBook[task.taskIdentifier] = book
    task.resume()

    let selectionState: BookSelectionState = bookRegistry.selectionState(for: book.identifier)

    bookRegistry.addBook(book,
                         location: bookRegistry.location(forIdentifier: book.identifier),
                         state: .Downloading,
                         selectionState: selectionState,
                         fulfillmentId: nil,
                         readiumBookmarks: nil,
                         genericBookmarks: nil)

    NotificationCenter.default.post(name: .TPPMyBooksDownloadCenterDidChange, object: self)
  }
}

extension MyBooksDownloadCenter {
  private func logBookDownloadFailure(_ book: TPPBook, reason: String, downloadTask: URLSessionTask, metadata: [String: Any]?) {
    let rights = downloadInfo(forBookIdentifier: book.identifier)?.rightsManagementString ?? ""
    let bookType = TPPBookContentTypeConverter.stringValue(of: book.defaultBookContentType)
    let context = "\(String(describing: book.distributor)) \(bookType) download fail: \(reason)"

    var dict: [String: Any] = metadata ?? [:]
    dict["book"] = book.loggableDictionary
    dict["rightsManagement"] = rights
    dict["taskOriginalRequest"] = downloadTask.originalRequest?.loggableString
    dict["taskCurrentRequest"] = downloadTask.currentRequest?.loggableString
    dict["response"] = downloadTask.response ?? "N/A"
    dict["downloadError"] = downloadTask.error ?? "N/A"

    TPPErrorLogger.logError(withCode: .downloadFail, summary: context, metadata: dict)
  }
  
  func fulfillLCPLicense(fileUrl: URL, forBook book: TPPBook, downloadTask: URLSessionDownloadTask) {
#if LCP
    let lcpService = LCPLibraryService()
    let licenseUrl = fileUrl.deletingPathExtension().appendingPathExtension(lcpService.licenseExtension)
    
    do {
      _ = try FileManager.default.replaceItemAt(licenseUrl, withItemAt: fileUrl)
    } catch {
      TPPErrorLogger.logError(error, summary: "Error renaming LCP license file", metadata: [
        "fileUrl": fileUrl.absoluteString,
        "licenseUrl": licenseUrl.absoluteString,
        "book": book.loggableDictionary
      ])
      failDownloadWithAlert(for: book, withMessage: error.localizedDescription)
      return
    }

    let lcpProgress: (Double) -> Void = { [weak self] progressValue in
      guard let self = self else { return }
      self.bookIdentifierToDownloadInfo[book.identifier] = self.downloadInfo(forBookIdentifier: book.identifier)?.withDownloadProgress(progressValue)
      self.broadcastUpdate()
    }
    
    let lcpCompletion: (URL?, Error?) -> Void = { [weak self] localUrl, error in
      guard let self = self else { return }
      if let error = error {
        let summary = "\(String(describing: book.distributor)) LCP license fulfillment error"
        TPPErrorLogger.logError(error, summary: summary, metadata: [
          "book": book.loggableDictionary,
          "licenseURL": licenseUrl.absoluteString,
          "localURL": localUrl?.absoluteString ?? "N/A"
        ])
        let errorMessage = "Fulfilment Error: \(error.localizedDescription)"
        self.failDownloadWithAlert(for: book, withMessage: errorMessage)
        return
      }
      
      guard let localUrl = localUrl,
            let license = TPPLCPLicense(url: licenseUrl),
            self.replaceBook(book, withFileAtURL: localUrl, forDownloadTask: downloadTask)
      else {
        let errorMessage = "Error replacing license file with file \(localUrl?.absoluteString ?? "")"
        self.failDownloadWithAlert(for: book, withMessage: errorMessage)
        return
      }
      
      self.bookRegistry.setFulfillmentId(license.identifier, for: book.identifier)
      
      if book.defaultBookContentType == .pdf,
         let bookURL = self.fileUrl(for: book.identifier) {
        self.bookRegistry.setState(.Downloading, for: book.identifier)
        LCPPDFs(url: bookURL)?.extract(url: bookURL) { _, _ in
          self.bookRegistry.setState(.DownloadSuccessful, for: book.identifier)
        }
      }
    }
    
    let fulfillmentDownloadTask = lcpService.fulfill(licenseUrl, progress: lcpProgress, completion: lcpCompletion)
    if let fulfillmentDownloadTask = fulfillmentDownloadTask {
      self.bookIdentifierToDownloadInfo[book.identifier] = MyBooksDownloadInfo(downloadProgress: 0.0, downloadTask: fulfillmentDownloadTask, rightsManagement: .none)
    }
#endif
  }
  
  func failDownloadWithAlert(
    for book: TPPBook,
    withMessage message: String? = nil
  ) {

    let location = bookRegistry.location(forIdentifier: book.identifier)

    let selectionState: BookSelectionState = .SelectionUnregistered

    bookRegistry.addBook(
      book,
      location: location,
      state: .DownloadFailed,
      selectionState: selectionState,
      fulfillmentId: nil,
      readiumBookmarks: nil,
      genericBookmarks: nil
    )

    let downloadFailedTitle = Strings.DownloadBook.downloadFailedTitle
    let downloadFailedMessage = String.localizedStringWithFormat(
      Strings.DownloadBook.downloadFailedMessageWithBookTitle,
      book.title
    )

    let detailedErrorMessage: String

    if let message = message {
      // If some error message is given,
      // show the message in the alert for extra information
      // the error message might not be localised,
      // so this String is formatted with that in mind
      detailedErrorMessage = String.localizedStringWithFormat(
        Strings.ErrorInformation.errorInformationAvailable,
        message
      )
    } else {
      // otherwise let the user know, that there is no further info about the error
      detailedErrorMessage = Strings.ErrorInformation.noErrorInformationAvailable
    }

    let alert = TPPAlertUtils.alert(
      title: downloadFailedTitle,
      message: "\(downloadFailedMessage)\n\n\(detailedErrorMessage)"
    )

    DispatchQueue.main.async {

      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )

    }

    broadcastUpdate()
  }

  func alertForProblemDocument(
    _ problemDoc: TPPProblemDocument?,
    error: Error?,
    book: TPPBook
  ) {

    // forward problemdoc details
    if let problemDoc = problemDoc {
      handleProblemDocumentAndAlert(
        problemDoc,
        book: book
      )

      return
    }

    // forward error details
    if let error = error {
      failDownloadWithAlert(
        for: book,
        withMessage: error.localizedDescription
      )

      return
    }

    // otherwise just show basic alert without details
    failDownloadWithAlert(for: book)

  }

  func handleProblemDocumentAndAlert(
    _ problemDoc: TPPProblemDocument,
    book: TPPBook
  ) {
    
    let downloadFailedTitle = Strings.DownloadBook.downloadFailedTitle
    let downloadFailedMessage = String.localizedStringWithFormat(
      Strings.DownloadBook.downloadFailedMessageWithBookTitle,
      book.title
    )
    
    let alert = TPPAlertUtils.alert(
      title: downloadFailedTitle,
      message: downloadFailedMessage
    )
    
    TPPProblemDocumentCacheManager.sharedInstance().cacheProblemDocument(
      problemDoc,
      key: book.identifier
    )
    
    TPPAlertUtils.setProblemDocument(
      controller: alert,
      document: problemDoc,
      append: true
    )

    if problemDoc.type == TPPProblemDocument.TypeNoActiveLoan {
      bookRegistry.removeBook(forIdentifier: book.identifier)
    }

    DispatchQueue.main.async {

      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )

     }

   }

  func moveFile(at sourceLocation: URL, toDestinationForBook book: TPPBook, forDownloadTask downloadTask: URLSessionDownloadTask) -> Bool {
    var removeError: Error?
    var moveError: Error?
    
    guard let finalFileURL = fileUrl(for: book.identifier) else { return false }
    
    do {
      try FileManager.default.removeItem(at: finalFileURL)
    } catch {
      removeError = error
    }
    
    var success = false
    
    do {
      try FileManager.default.moveItem(at: sourceLocation, to: finalFileURL)
      success = true
    } catch {
      moveError = error
    }
    
    if success {
      bookRegistry.setState(.DownloadSuccessful, for: book.identifier)
    } else if let moveError = moveError {
      logBookDownloadFailure(book, reason: "Couldn't move book to final disk location", downloadTask: downloadTask, metadata: [
        "moveError": moveError,
        "removeError": removeError?.localizedDescription ?? "N/A",
        "sourceLocation": sourceLocation.absoluteString,
        "finalFileURL": finalFileURL.absoluteString
      ])
    }
    
    return success
  }
  
  private func replaceBook(_ book: TPPBook, withFileAtURL sourceLocation: URL, forDownloadTask downloadTask: URLSessionDownloadTask) -> Bool {
    guard let destURL = fileUrl(for: book.identifier) else { return false }
    do {
      let _ = try FileManager.default.replaceItemAt(destURL, withItemAt: sourceLocation, options: .usingNewMetadataOnly)
      bookRegistry.setState(.DownloadSuccessful, for: book.identifier)
      return true
    } catch {
      logBookDownloadFailure(book,
                             reason: "Couldn't replace downloaded book",
                             downloadTask: downloadTask,
                             metadata: [
                              "replaceError": error,
                              "destinationFileURL": destURL as Any,
                              "sourceFileURL": sourceLocation as Any
                             ])
    }
    
    return false
  }

  @objc func fileUrl(for identifier: String) -> URL? {
    return fileUrl(for: identifier, account: AccountsManager.shared.currentAccountId)
  }
  
  func fileUrl(for identifier: String, account: String?) -> URL? {
    guard let book = bookRegistry.book(forIdentifier: identifier) else {
      return nil
    }
    
    let pathExtension = pathExtension(for: book)
    let contentDirectoryURL = self.contentDirectoryURL(account)
    let hashedIdentifier = identifier.sha256()
    
    return contentDirectoryURL?.appendingPathComponent(hashedIdentifier).appendingPathExtension(pathExtension)
  }
  
  func contentDirectoryURL(_ account: String?) -> URL? {
    guard let directoryURL = TPPBookContentMetadataFilesHelper.directory(for: account ?? "")?.appendingPathComponent("content") else {
      NSLog("[contentDirectoryURL] nil directory.")
      return nil
    }
    
    var isDirectory: ObjCBool = false
    if !FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
      do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        NSLog("Failed to create directory.")
        return nil
      }
    }
    
    return directoryURL
  }

  
  func pathExtension(for book: TPPBook?) -> String {
#if LCP
    if let book = book {
      if LCPAudiobooks.canOpenBook(book) {
        return "lcpa"
      }
      
      if LCPPDFs.canOpenBook(book) {
        return "zip"
      }
    }
#endif
    return "epub"
  }
}

extension MyBooksDownloadCenter: TPPBookDownloadsDeleting {
  func reset(_ libraryID: String!) {
    reset(account: libraryID)
  }

  func reset(account: String) {
    if AccountsManager.shared.currentAccountId == account {
      reset()
    } else {
      deleteAudiobooks(forAccount: account)
      do {
        if let url = contentDirectoryURL(account) {
          try FileManager.default.removeItem(at: url)
        }
      } catch {
        // Handle error, if needed
      }
    }
  }
  
  func reset() {
    guard let currentAccountId = AccountsManager.shared.currentAccountId else {
      return
    }
    
    deleteAudiobooks(forAccount: currentAccountId)
    
    for info in bookIdentifierToDownloadInfo.values {
      info.downloadTask.cancel(byProducingResumeData: { _ in })
    }
    
    bookIdentifierToDownloadInfo.removeAll()
    taskIdentifierToBook.removeAll()
    bookIdentifierOfBookToRemove = nil
    
    do {
      if let url = contentDirectoryURL(currentAccountId) {
        try FileManager.default.removeItem(at: url)
      }
    } catch {
      // Handle error, if needed
    }
    
    broadcastUpdate()
  }

  func deleteAudiobooks(forAccount account: String) {
    bookRegistry.with(account: account) { registry in
      let books = registry.allBooks
      for book in books {
        if book.defaultBookContentType == .audiobook {
          deleteLocalContent(for: book.identifier, account: account)
        }
      }
    }
  }

  @objc func downloadProgress(for bookIdentifier: String) -> Double {
    Double(self.downloadInfo(forBookIdentifier: bookIdentifier)?.downloadProgress ?? 0.0)
  }
}

#if FEATURE_DRM_CONNECTOR
extension MyBooksDownloadCenter: NYPLADEPTDelegate {
  
  func adept(_ adept: NYPLADEPT, didFinishDownload: Bool, to adeptToURL: URL?, fulfillmentID: String?, isReturnable: Bool, rightsData: Data, tag: String, error adeptError: Error?) {
    guard let book = bookRegistry.book(forIdentifier: tag),
          let rights = String(data: rightsData, encoding: .utf8) else { return }
    
    var didSucceedCopying = false
    
    if didFinishDownload {
      guard let fileURL = fileUrl(for: book.identifier) else { return }
      let fileManager = FileManager.default
      
      do {
        try fileManager.removeItem(at: fileURL)
      } catch {
        print("Remove item error: \(error)")
      }
      
      guard let destURL = fileUrl(for: book.identifier), let adeptToURL = adeptToURL else {
        TPPErrorLogger.logError(withCode: .adobeDRMFulfillmentFail, summary: "Adobe DRM error: destination file URL unavailable", metadata: [
          "adeptError": adeptError ?? "N/A",
          "fileURLToRemove": adeptToURL ?? "N/A",
          "book": book.loggableDictionary,
          "AdobeFulfilmmentID": fulfillmentID ?? "N/A",
          "AdobeRights": rights,
          "AdobeTag": tag
        ])
        self.failDownloadWithAlert(for: book)
        return
      }
      
      do {
        try fileManager.copyItem(at: adeptToURL, to: destURL)
        didSucceedCopying = true
      } catch {
        TPPErrorLogger.logError(withCode: .adobeDRMFulfillmentFail, summary: "Adobe DRM error: failure copying file", metadata: [
          "adeptError": adeptError ?? "N/A",
          "copyError": error,
          "fromURL": adeptToURL,
          "destURL": destURL,
          "book": book.loggableDictionary,
          "AdobeFulfilmmentID": fulfillmentID ?? "N/A",
          "AdobeRights": rights,
          "AdobeTag": tag
        ])
      }
    } else {
      TPPErrorLogger.logError(withCode: .adobeDRMFulfillmentFail, summary: "Adobe DRM error: did not finish download", metadata: [
        "adeptError": adeptError ?? "N/A",
        "adeptToURL": adeptToURL ?? "N/A",
        "book": book.loggableDictionary,
        "AdobeFulfilmmentID": fulfillmentID ?? "N/A",
        "AdobeRights": rights,
        "AdobeTag": tag
      ])
    }
    
    if !didFinishDownload || !didSucceedCopying {
      self.failDownloadWithAlert(for: book)
      return
    }
    
    guard let rightsFilePath = fileUrl(for: book.identifier)?.path.appending("_rights.xml") else { return }
    do {
      try rightsData.write(to: URL(fileURLWithPath: rightsFilePath))
    } catch {
      print("Failed to store rights data.")
    }
    
    if isReturnable, let fulfillmentID = fulfillmentID {
      bookRegistry.setFulfillmentId(fulfillmentID, for: book.identifier)
    }
    
    bookRegistry.setState(.DownloadSuccessful, for: book.identifier)
    
    self.broadcastUpdate()
  }
  
  
  func adept(_ adept: NYPLADEPT, didUpdateProgress progress: Double, tag: String) {
    self.bookIdentifierToDownloadInfo[tag] = self.downloadInfo(forBookIdentifier: tag)?.withDownloadProgress(progress)
    self.broadcastUpdate()
  }
  
  func adept(_ adept: NYPLADEPT, didCancelDownloadWithTag tag: String) {
    bookRegistry.setState(.DownloadNeeded, for: tag)
    self.broadcastUpdate()
  }
  
  func didIgnoreFulfillmentWithNoAuthorizationPresent() {
    // NOTE: This is cut and pasted from a previous implementation:
    // "This handles a bug that seems to occur when the user updates,
    // where the barcode and pin are entered but according to ADEPT the device
    // is not authorized. To be used, the account must have a barcode and pin."
    self.reauthenticator.authenticateIfNeeded(userAccount, usingExistingCredentials: true, authenticationCompletion: nil)
  }
}
#endif

//
//  MyBooksSelectionCenter.swift
//

import Foundation

@objc
class MyBooksSelectionCenter: NSObject {

  @objc static let shared = MyBooksSelectionCenter()

  private var userAccount: TPPUserAccount
  private var bookRegistry: TPPBookRegistryProvider

  init(
    userAccount: TPPUserAccount = TPPUserAccount.sharedAccount(),
    bookRegistry: TPPBookRegistryProvider = TPPBookRegistry.shared
  ) {
    self.userAccount = userAccount
    self.bookRegistry = bookRegistry

    super.init()
  }

  // MARK: - Select book functions: adding book to favorites

  @objc func startBookSelect(
    for book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

    if !bookHasIdentifier(book) {
      // if book has no identifier
      // do not proceed with selecting
      showGenericSelectionFailedAlert(book)
      return
    }

    let selectionState: BookSelectionState = bookRegistry.selectionState(
      for: book.identifier)
    let selectionStateAsString: String = BookSelectionStateHelper.stringValue(
      from: selectionState)

    printToConsole(
      .info,
      "Start book select for book "
        + "with title: '\(book.title)' "
        + "and selection state: \(selectionStateAsString)"
    )

    startProcessing(book)

    if isLoginRequired() == true {
      // user is not logged in
      // stop book processing and
      // show the login view for user
      stopProcessing(book)
      EkirjastoLoginViewController.show {}
    } else {
      // user is logged in
      // proceed with selecting book
      sendSelectBookRequestAndUpdateBookRegistry(
        book: book,
        completion: completion
      )
    }
  }

  private func sendSelectBookRequestAndUpdateBookRegistry(
    book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

    guard let alternateURL: URL = book.alternateURL else {
      // if book has no alternateUrl
      // do not proceed with selecting
      self.showGenericSelectionFailedAlert(book)
      return
    }

    // We use function withURL here
    // so we can update the book registry with
    // the latest book data we have on server
    // (book data in app could already be stale)
    printToConsole(
      .info,
      "Start GET request for book \(book.title) to refresh book record data"
    )

    TPPOPDSFeed.withURL(
      alternateURL,
      shouldResetCache: true
    ) {
      [weak self] feed, error in

      if let feed = feed,
        let selectedEntry = feed.entries.first as? TPPOPDSEntry,
        let selectedBook = TPPBook(entry: selectedEntry)
      {

        printToConsole(
          .info,
          "Start POST request and book registry update for selected book: "
            + "\(selectedBook.loggableDictionary())"
        )

        // send select book request to backend
        self?.sendSelectBookRequest(
          book: selectedBook,
          selectionState: .Selected
        )

      } else {
        // maybe an error
        // stop book processing
        // and show alert to user
        self?.handleUnexpectedBookSelectionError(book)
      }

    }

  }

  private func sendSelectBookRequest(
    book: TPPBook,
    selectionState: BookSelectionState
  ) {

    printToConsole(
      .info,
      "Sending POST request to select book \(book.title)"
    )

    let selectBookURL: URL = createSelectBookURL(book)
    let selectBookRequest: URLRequest = createSelectBookRequest(selectBookURL)

    _ = TPPNetworkExecutor.shared.addBearerAndExecute(selectBookRequest) {
      _, response, error in

      self.bookRegistry.setProcessing(false, for: book.identifier)

      if let error = error {

        self.logErrorInSendingBookSelectionRequest(
          response: response as? HTTPURLResponse,
          error: error,
          requestURL: selectBookURL
        )

        self.showGenericSelectionFailedAlert(book)
      }

      if let response = response {

        let responseStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        printToConsole(
          .debug,
          "Response status code after sending select book request: '\(responseStatusCode)'"
        )

        if responseStatusCode == 200 {
          // update book registry with selected book record
          self.updateBookRegistryWithSelectedBook(book)

          // show notification of successful addition to favorites
          self.showAddedToFavoritesSuccessNotification(book)

        } else {
          self.showGenericSelectionFailedAlert(book)
        }

      }

    }

  }

  private func updateBookRegistryWithSelectedBook(_ book: TPPBook) {

    if self.bookIsAlreadyRegistered(book) {
      self.updateBookAsSelectedInBookRegistry(book)
      return
    }

    if self.bookIsNew(book) {
      self.addBookAsSelectedToBookRegistry(
        book,
        location: bookRegistry.location(forIdentifier: book.identifier)
      )
      return
    }

    handleUnexpectedBookSelectionError(book)
  }

  private func updateBookAsSelectedInBookRegistry(_ book: TPPBook) {
    bookRegistry.updateBook(
      book,
      selectionState: .Selected
    )
  }

  private func addBookAsSelectedToBookRegistry(
    _ book: TPPBook,
    location: TPPBookLocation? = nil
  ) {

    bookRegistry.addBook(
      book,
      location: location,
      state: .Unregistered,
      selectionState: .Selected,
      fulfillmentId: nil,
      readiumBookmarks: nil,
      genericBookmarks: nil
    )

  }

  private func createSelectBookRequest(_ selectBookURL: URL) -> URLRequest {
    var selectBookRequest = URLRequest(url: selectBookURL)
    selectBookRequest.httpMethod = "POST"

    return selectBookRequest
  }

  private func createSelectBookURL(_ book: TPPBook) -> URL {
    var selectBookURL: URL
    let alternateURL: URL = book.alternateURL!

    if #available(iOS 16.0, *) {
      selectBookURL = alternateURL.appending(path: "select_book")
    } else {
      selectBookURL = alternateURL.appendingPathComponent("select_book")
    }

    return selectBookURL
  }

  private func showAddedToFavoritesSuccessNotification(_ book: TPPBook) {
    let title: String = String.localizedStringWithFormat(
      Strings.UserNotifications.bookAddedToFavoritesNotificationBannerTitle)
    let message: String = String.localizedStringWithFormat(
      Strings.UserNotifications.bookAddedToFavoritesNotificationBannerMessage,
      book.title)

    TPPUserNotifications.createNotificationBannerForBookSelection(
      book,
      notificationBannerTitle: title,
      notificationBannerMessage: message)
  }

  // MARK: - Unselect book functions: removing book from favorites

  @objc func startBookUnselect(
    for book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

    if bookHasIdentifier(book) == false {
      // if book has no identifier
      // do not proceed with unselecting
      showGenericSelectionFailedAlert(book)
      return
    }

    let selectionState: BookSelectionState = bookRegistry.selectionState(
      for: book.identifier)
    let selectionStateAsString: String = BookSelectionStateHelper.stringValue(
      from: selectionState)

    printToConsole(
      .info,
      "Start book unselect for book "
        + "with title: '\(book.title)' "
        + "and selection state: \(selectionStateAsString)"
    )

    startProcessing(book)

    if isLoginRequired() == true {
      // user is not logged in
      // stop book processing and
      // show the login view for user
      stopProcessing(book)
      EkirjastoLoginViewController.show {}
    } else {
      // user is logged in
      // proceed with unselecting book
      sendUnselectBookRequestAndUpdateBookRegistry(
        book: book,
        completion: completion
      )
    }

  }

  private func sendUnselectBookRequestAndUpdateBookRegistry(
    book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

    guard let alternateURL: URL = book.alternateURL else {
      // if book has no alternateUrl
      // do not proceed with unselecting
      self.showGenericSelectionFailedAlert(book)
      return
    }

    // We use function withURL here
    // so we can update the book registry with
    // the latest book data we have on server
    // (book data in app could already be stale)
    printToConsole(
      .info,
      "Start GET request for book \(book.title) to refresh book record data"
    )

    TPPOPDSFeed.withURL(
      alternateURL,
      shouldResetCache: true
    ) {
      [weak self] feed, error in

      if let feed = feed,
        let unselectedEntry = feed.entries.first as? TPPOPDSEntry,
        let unselectedBook = TPPBook(entry: unselectedEntry)
      {

        printToConsole(
          .info,
          "Start unselect request and book registry update for unselected book: "
            + "\(unselectedBook.loggableDictionary())"
        )

        // send unselect book request to backend
        self?.sendUnselectBookRequest(
          book: unselectedBook,
          selectionState: .Selected
        )

      } else {
        // maybe an error
        // stop book processing
        // and show alert to user
        self?.handleUnexpectedBookSelectionError(book)
      }

    }

  }

  private func sendUnselectBookRequest(
    book: TPPBook,
    selectionState: BookSelectionState
  ) {

    let unselectBookURL: URL = createUnselectBookURL(book)
    let unselectBookRequest: URLRequest = createUnselectBookRequest(
      unselectBookURL)

    printToConsole(
      .info,
      "Sending DELETE request for unselecting book \(book.title)"
    )

    _ = TPPNetworkExecutor.shared.addBearerAndExecute(unselectBookRequest) {
      _, response, error in

      self.bookRegistry.setProcessing(false, for: book.identifier)

      if let error = error {

        self.logErrorInSendingBookSelectionRequest(
          response: response as? HTTPURLResponse,
          error: error,
          requestURL: unselectBookURL
        )

        self.showGenericSelectionFailedAlert(book)
      }

      if let response = response {

        let responseStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        printToConsole(
          .debug,
          "Response status code after sending unselect book request: '\(responseStatusCode)'"
        )

        if responseStatusCode == 200 {
          // update book registry with unselected book record
          self.updateBookRegistryWithUnselectedBook(book)

          // show notification of successful removal from favorites
          self.showRemovedFromFavoritesSuccessNotification(book)

        } else {
          self.showGenericSelectionFailedAlert(book)
        }

      }

    }

  }

  private func updateBookRegistryWithUnselectedBook(_ book: TPPBook) {

    if self.bookIsAlreadyRegistered(book) == true {
      // favorite book should alredy be in book registry
      // so we can just update the book record
      self.updateBookAsUnselectedInBookRegistry(book)
    } else {
      // if book for some reason is not in registry
      // there is something wrong, do not proceed
      stopProcessing(book)
      showGenericSelectionFailedAlert(book)
    }

  }

  private func updateBookAsUnselectedInBookRegistry(_ book: TPPBook) {
    bookRegistry.updateBook(
      book,
      selectionState: .Unselected
    )
  }

  private func createUnselectBookRequest(_ unselectBookURL: URL) -> URLRequest {
    var unselectBookRequest = URLRequest(url: unselectBookURL)
    unselectBookRequest.httpMethod = "DELETE"

    return unselectBookRequest
  }

  private func createUnselectBookURL(_ book: TPPBook) -> URL {
    var unselectBookURL: URL
    let alternateURL: URL = book.alternateURL!

    if #available(iOS 16.0, *) {
      unselectBookURL = alternateURL.appending(path: "unselect_book")
    } else {
      unselectBookURL = alternateURL.appendingPathComponent("unselect_book")
    }

    return unselectBookURL
  }

  private func showRemovedFromFavoritesSuccessNotification(_ book: TPPBook) {
    let title: String = String.localizedStringWithFormat(
      Strings.UserNotifications.bookRemovedFromFavoritesNotificationBannerTitle)
    let message: String = String.localizedStringWithFormat(
      Strings.UserNotifications
        .bookRemovedFromFavoritesNotificationBannerMessage, book.title)

    TPPUserNotifications.createNotificationBannerForBookSelection(
      book,
      notificationBannerTitle: title,
      notificationBannerMessage: message)
  }

  // MARK: - Helper functions for book selection functions

  private func bookHasIdentifier(_ book: TPPBook) -> Bool {
    if book.identifier.isEmpty {
      return false
    }

    return true
  }

  private func bookIsAlreadyRegistered(_ book: TPPBook) -> Bool {
    let bookRecord = bookRegistry.book(forIdentifier: book.identifier)

    if bookRecord != nil {
      return true
    }

    return false
  }

  private func bookIsNew(_ book: TPPBook) -> Bool {
    let bookRecord = bookRegistry.book(forIdentifier: book.identifier)

    if bookRecord == nil {
      return true
    }

    return false
  }

  private func startProcessing(_ book: TPPBook) {
    bookRegistry.setProcessing(true, for: book.identifier)
  }

  private func stopProcessing(_ book: TPPBook) {
    bookRegistry.setProcessing(false, for: book.identifier)
  }

  private func isLoginRequired() -> Bool {
    let needsAuthentication = userAccount.authDefinition?.needsAuth ?? true
    let isAuthenticated = userAccount.hasCredentials()

    if !isAuthenticated || needsAuthentication {
      return true
    }

    return false
  }

  private func handleUnexpectedBookSelectionError(_ book: TPPBook) {
    stopProcessing(book)
    showGenericSelectionFailedAlert(book)
  }

  private func logErrorInSendingBookSelectionRequest(
    response: HTTPURLResponse?,
    error: Error,
    requestURL: URL
  ) {

    TPPErrorLogger.logError(
      error,
      summary:
        "Could not send POST for selecting or DELETE request unselecting a book",
      metadata: [
        "requestURL": requestURL,
        "statusCode": response?.statusCode ?? 0,
      ])

  }

  private func showGenericSelectionFailedAlert(_ book: TPPBook) {
    let alert = createFavoritesAlert(book)
    showFavoritesAlertToUser(alert)
  }

  private func createFavoritesAlert(_ book: TPPBook) -> UIAlertController {
    let title: String = String.localizedStringWithFormat(
      Strings.Error.bookFavoriteActionFailedNotificationAlertTitle)
    let message: String = String.localizedStringWithFormat(
      Strings.Error.bookFavoriteActionFailedNotificationAlertMessage, book.title
    )

    let alert = TPPAlertUtils.alert(
      title: title,
      message: message
    )

    return alert
  }

  private func showFavoritesAlertToUser(_ alert: UIAlertController) {
    DispatchQueue.main.async {
      TPPAlertUtils.presentFromViewControllerOrNil(
        alertController: alert,
        viewController: nil,
        animated: true,
        completion: nil
      )
    }
  }

}

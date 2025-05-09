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
      return
    }

    let selectionState: BookSelectionState = bookRegistry.selectionState(
      for: book.identifier)
    let selectionStateAsString: String = BookSelectionStateHelper.stringValue(
      from: selectionState)

    ATLog(
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
      return
    }

    // We use function withURL here
    // so we can update the book registry with
    // the latest book data we have on server
    // (book data in app could already be stale)
    TPPOPDSFeed.withURL(
      alternateURL,
      shouldResetCache: true
    ) {
      [weak self] feed, error in

      if let feed = feed,
        let selectedEntry = feed.entries.first as? TPPOPDSEntry,
        let selectedBook = TPPBook(entry: selectedEntry)
      {

        ATLog(
          .info,
          "Start POST request and book registry update for selected book: "
            + "\(selectedBook.loggableDictionary())"
        )

        // send select book request to backend
        // update book registry with selected book record

      } else {
        // maybe an error
        // stop book processing
        // and show alert to user
        self?.stopProcessing(book)
        self?.showGenericSelectionFailedAlert(book)
      }

    }

  }

  // MARK: - Unselect book functions: removing book from favorites

  @objc func startBookUnselect(
    for book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

    if bookHasIdentifier(book) == false {
      // if book has no identifier
      // do not proceed with unselecting
      return
    }

    let selectionState: BookSelectionState = bookRegistry.selectionState(
      for: book.identifier)
    let selectionStateAsString: String = BookSelectionStateHelper.stringValue(
      from: selectionState)

    ATLog(
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

  func sendUnselectBookRequestAndUpdateBookRegistry(
    book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

    guard let alternateURL: URL = book.alternateURL else {
      // if book has no alternateUrl
      // do not proceed with unselecting
      return
    }

    // We use function withURL here
    // so we can update the book registry with
    // the latest book data we have on server
    // (book data in app could already be stale)
    TPPOPDSFeed.withURL(
      alternateURL,
      shouldResetCache: true
    ) {
      [weak self] feed, error in

      if let feed = feed,
        let unselectedEntry = feed.entries.first as? TPPOPDSEntry,
        let unselectedBook = TPPBook(entry: unselectedEntry)
      {

        ATLog(
          .info,
          "Start POST request and book registry update for unselected book: "
            + "\(unselectedBook.loggableDictionary())"
        )

        // send unselect book request to backend
        // update book registry with unselected book record

      } else {
        // maybe an error
        // stop book processing
        // and show alert to user
        self?.stopProcessing(book)
        self?.showGenericSelectionFailedAlert(book)
      }

    }

  }

  // MARK: - Helper functions for book selection functions

  private func bookHasIdentifier(_ book: TPPBook) -> Bool {
    if book.identifier.isEmpty {
      return false
    }

    return true
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

  private func showGenericSelectionFailedAlert(_ book: TPPBook) {
    let alert = createFavoritesAlert(book)
    showFavoritesAlertToUser(alert)
  }

  private func createFavoritesAlert(_ book: TPPBook)
    -> UIAlertController
  {
    let title: String = "Error in favorite action"  //TODO: just a placeholder for actual localised title

    let message: String = String(
      format: "Could not update favorite status of book '%@'.",
      book.title
    )  //TODO: just a placeholder for actual localised message

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

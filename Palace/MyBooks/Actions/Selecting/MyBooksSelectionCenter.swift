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
    // send select book request
    // if success, update book registry
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
    // send unselect book request
    // if success, update book registry
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

}

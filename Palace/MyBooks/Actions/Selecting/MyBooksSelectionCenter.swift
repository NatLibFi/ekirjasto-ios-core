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

    bookRegistry.setProcessing(true, for: book.identifier)

    // check if user is logged in in app
    // update book registry with selected book record
    // send select request to backend
    // show notification to user
  }

  // MARK: - Unselect book functions: removing book from favorites
  @objc func startBookUnselect(
    for book: TPPBook,
    completion: (() -> Void)? = nil
  ) {

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

    bookRegistry.setProcessing(true, for: book.identifier)

    // check if user is logged in in app
    // update book registry with unselected book record
    // send unselect request to backend
    // show notification to user
  }

}

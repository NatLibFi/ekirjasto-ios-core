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

}

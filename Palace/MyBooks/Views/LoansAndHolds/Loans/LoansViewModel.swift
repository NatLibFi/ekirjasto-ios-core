//
//  LoansViewModel.swift
//  Palace
//
//  Created by Maurice Carrier on 12/23/22.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Combine
import Foundation

enum Group: Int {
  case groupSortBy
}

@MainActor
class LoansViewModel: ObservableObject {

  @Published var alert: AlertModel?
  @Published var books = [TPPBook]()
  @Published var isLoading = false
  @Published var userHasBooksOnLoan = false
  @Published var userIsLoggedIn = false
  @Published var showSearchSheet = false

  var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

  var activeFacetSort: Facet {
    didSet {
      sortData()
    }
  }

  let facetViewModel: FacetViewModel = FacetViewModel(
    groupName: Strings.MyBooksView.sortBy,
    facets: [.title, .author]
  )

  var observers = Set<AnyCancellable>()

  init() {
    activeFacetSort = Facet.author
    registerForPublishers()
    registerForNotifications()
    loadData()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func loadData() {
    DispatchQueue.main.async {
      self.books =
        Reachability.shared.isConnectedToNetwork()
        ? TPPBookRegistry.shared.loans
        : TPPBookRegistry.shared.loans.filter { !$0.isExpired }
      self.sortData()
    }
  }

  private func sortData() {

    switch activeFacetSort {
    case .author:
      books.sort {
        let aString = "\($0.authors!) \($0.title)"
        let bString = "\($1.authors!) \($1.title)"
        return aString < bString
      }
    case .title:
      books.sort {
        let aString = "\($0.title) \($0.authors!)"
        let bString = "\($1.title) \($1.authors!)"
        return aString < bString
      }
    }

  }

  private func registerForPublishers() {
    facetViewModel.$activeSort
      .assign(to: \.activeFacetSort, on: self)
      .store(in: &observers)

  }

  private func registerForNotifications() {

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(bookRegistryDidChange),
      name: .TPPBookRegistryDidChange,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(bookRegistryStateDidChange),
      name: .TPPBookRegistryDidChange,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(syncBegan),
      name: .TPPSyncBegan,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(syncEnded),
      name: .TPPSyncEnded,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(stopLoading(_:)),
      name: .TPPBookProcessingDidChange,
      object: nil)

  }

  @objc private func stopLoading(_ notification: Notification) {

    guard let userInfo = notification.userInfo,
      let bookProcessingBookID = userInfo[
        TPPNotificationKeys.bookProcessingBookIDKey] as? String,
      let bookProcessingValue = notification.userInfo?[
        TPPNotificationKeys.bookProcessingValueKey] as? Bool
    else {
      // return, as we do not have enough information in notification
      // to update the Loans view based on book processing
      return
    }

    guard
      self.books.contains(where: { book in
        book.identifier == bookProcessingBookID
      })
    else {
      // return, as this book is not currently in Loans view
      // so no need to update view based on book processing
      return
    }

    DispatchQueue.main.async {
      self.isLoading = bookProcessingValue
    }

  }

  @objc private func bookRegistryDidChange() {
    self.loadData()
    DispatchQueue.main.async {
      self.userIsLoggedIn =
        !TPPUserAccount.sharedAccount().needsAuth
        && TPPUserAccount.sharedAccount().hasCredentials()
      self.userHasBooksOnLoan = self.books.count > 0
    }
  }

  @objc private func bookRegistryStateDidChange() {}
  @objc private func syncBegan() {}
  @objc private func syncEnded() {
    self.loadData()
  }

  func reloadData() {
    defer {
      loadData()
    }

    if TPPUserAccount.sharedAccount().needsAuth
      && !TPPUserAccount.sharedAccount().hasCredentials()
    {
      TPPAccountSignInViewController.requestCredentials(completion: nil)
    } else {
      TPPBookRegistry.shared.sync()
    }
  }

  func refresh() {
    if AccountsManager.shared.currentAccount?.loansUrl != nil {
      reloadData()
    }
  }

  func authenticateAndLoad(_ account: Account) {
    account.loadAuthenticationDocument { success in
      guard success else {
        return
      }

      DispatchQueue.main.async {
        if !TPPSettings.shared.settingsAccountIdsList.contains(account.uuid) {
          TPPSettings.shared.settingsAccountIdsList =
            TPPSettings.shared.settingsAccountIdsList + [account.uuid]
        }

        self.loadAccount(account)
      }
    }
  }

  func loadAccount(_ account: Account) {
    var workflowsInProgress = false

    #if FEATURE_DRM_CONNECTOR
      if !(AdobeCertificate.defaultCertificate?.hasExpired ?? true) {
        workflowsInProgress =
          NYPLADEPT.sharedInstance().workflowsInProgress
          || TPPBookRegistry.shared.isSyncing
      } else {
        workflowsInProgress = TPPBookRegistry.shared.isSyncing
      }
    #else
      workflowsInProgress = TPPBookRegistry.shared.isSyncing
    #endif

    if workflowsInProgress {
      alert = AlertModel(
        title: Strings.MyBooksView.accountSyncingAlertTitle,
        message: Strings.MyBooksView.accountSyncingAlertTitle)
    } else {
      self.updateFeed(account)
    }
  }

  private func updateFeed(_ account: Account) {
    AccountsManager.shared.currentAccount = account
    (TPPRootTabBarController.shared().viewControllers?.first
      as? TPPCatalogNavigationController)?
      .updateFeedAndRegistryOnAccountChange()
  }

  @objc func dismissSearchSheet() {
    showSearchSheet.toggle()
  }

}

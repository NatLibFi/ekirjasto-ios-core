//
//  TPPBookRegistry.swift
//  Palace
//
//  Created by Vladimir Fedorov on 13.10.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation
import UIKit

protocol TPPBookRegistryProvider {

  // Getters:
  func book(forIdentifier bookIdentifier: String) -> TPPBook?
  func fulfillmentId(forIdentifier bookIdentifier: String) -> String?
  func location(forIdentifier identifier: String) -> TPPBookLocation?
  func state(for bookIdentifier: String) -> TPPBookState
  func selectionState(for bookIdentifier: String) -> BookSelectionState

  // Setters:
  func setFulfillmentId(_ fulfillmentId: String, for bookIdentifier: String)
  func setLocation(
    _ location: TPPBookLocation?, forIdentifier identifier: String)
  func setProcessing(_ processing: Bool, for bookIdentifier: String)
  func setSelectionState(
    _ selectionState: BookSelectionState, for bookIdentifier: String)
  func setState(_ state: TPPBookState, for bookIdentifier: String)

  // Modifiers
  func addBook(
    _ book: TPPBook,
    location: TPPBookLocation?,
    state: TPPBookState,
    selectionState: BookSelectionState,
    fulfillmentId: String?,
    readiumBookmarks: [TPPReadiumBookmark]?,
    genericBookmarks: [TPPBookLocation]?
  )
  func removeBook(forIdentifier bookIdentifier: String)
  func updateBook(_ book: TPPBook, selectionState: BookSelectionState)
  func compareBookAvailabilityAndNotifyUser(bookInRegistry: TPPBook, bookFromFeed: TPPBook)
  func isBackgroundFetchNeeded() -> Bool
  func updateAndRemoveBook(_ book: TPPBook)

  // Account related:
  func with(
    account: String,
    perform block: (_ registry: TPPBookRegistry) -> Void
  )

  // Bookmarks related:
  func add(_ bookmark: TPPReadiumBookmark, forIdentifier identifier: String)
  func delete(_ bookmark: TPPReadiumBookmark, forIdentifier identifier: String)
  func replace(
    _ oldBookmark: TPPReadiumBookmark,
    with newBookmark: TPPReadiumBookmark,
    forIdentifier identifier: String
  )
  func genericBookmarksForIdentifier(_ bookIdentifier: String)
    -> [TPPBookLocation]
  func addOrReplaceGenericBookmark(
    _ location: TPPBookLocation, forIdentifier bookIdentifier: String)
  func addGenericBookmark(
    _ location: TPPBookLocation, forIdentifier bookIdentifier: String)
  func deleteGenericBookmark(
    _ location: TPPBookLocation, forIdentifier bookIdentifier: String)
  func replaceGenericBookmark(
    _ oldLocation: TPPBookLocation, with newLocation: TPPBookLocation,
    forIdentifier: String)
  func readiumBookmarks(forIdentifier identifier: String)
    -> [TPPReadiumBookmark]

}

typealias TPPBookRegistryData = [String: Any]

extension TPPBookRegistryData {

  func value(for key: TPPBookRegistryKey) -> Any? {
    return self[key.rawValue]
  }

  mutating func setValue(_ value: Any?, for key: TPPBookRegistryKey) {
    self[key.rawValue] = value
  }

  func object(for key: TPPBookRegistryKey) -> TPPBookRegistryData? {
    self[key.rawValue] as? TPPBookRegistryData
  }

  func array(for key: TPPBookRegistryKey) -> [TPPBookRegistryData]? {
    self[key.rawValue] as? [TPPBookRegistryData]
  }

}

enum TPPBookRegistryKey: String {
  case records = "records"
  case book = "metadata"
  case state = "state"
  case selectionState = "selectionState"
  case fulfillmentId = "fulfillmentId"
  case location = "location"
  case readiumBookmarks = "bookmarks"
  case genericBookmarks = "genericBookmarks"

}

fileprivate class BoolWithDelay {
  private var switchBackDelay: Double
  private var resetTask: DispatchWorkItem?
  private var onChange: ((_ value: Bool) -> Void)?
  init(
    delay: Double = 5,
    onChange: ((_ value: Bool) -> Void)? = nil
  ) {
    self.switchBackDelay = delay
    self.onChange = onChange
  }

  var value: Bool = false {
    willSet {
      if value != newValue {
        onChange?(newValue)
      }
    }
    didSet {
      resetTask?.cancel()
      if value {
        let task = DispatchWorkItem { [weak self] in
          self?.value = false
        }
        resetTask = task
        DispatchQueue.main.asyncAfter(
          deadline: .now() + switchBackDelay,
          execute: task
        )
      }
    }
  }
}

@objcMembers
class TPPBookRegistry: NSObject, TPPBookRegistrySyncing {

  @objc
  enum RegistryState: Int {
    case unloaded, loading, loaded, syncing
  }

  private let registryFolderName = "registry"
  private let registryFileName = "registry.json"

  // Reloads book registry when library account is changed.
  private var accountDidChange = NotificationCenter.default.publisher(
    for: .TPPCurrentAccountDidChange
  )
  .receive(on: RunLoop.main)
  .sink { _ in
    TPPBookRegistry.shared.load()
    TPPBookRegistry.shared.sync()
  }

  /// Book registry with book identifiers as keys.
  private var registry = [String: TPPBookRegistryRecord]() {
    didSet {
      NotificationCenter.default.post(
        name: .TPPBookRegistryDidChange,
        object: nil,
        userInfo: nil
      )
    }
  }

  private var coverRegistry = TPPBookCoverRegistry()

  /// Book identifiers that are being processed.
  private var processingIdentifiers = Set<String>()

  static let shared = TPPBookRegistry()

  /// Identifies that the synchronsiation process is going on.
  private(set) var isSyncing: Bool {
    get {
      syncState.value
    }
    set {}
  }

  /// `syncState` switches back after a delay to prevent locking in synchronization state
  private var syncState = BoolWithDelay { value in
    if value {
      NotificationCenter.default.post(
        name: .TPPSyncBegan,
        object: nil,
        userInfo: nil
      )
    } else {
      NotificationCenter.default.post(
        name: .TPPSyncEnded,
        object: nil,
        userInfo: nil
      )
    }
  }

  private(set) var state: RegistryState = .unloaded {
    didSet {
      syncState.value = state == .syncing
      NotificationCenter.default.post(
        name: .TPPBookRegistryStateDidChange,
        object: nil,
        userInfo: nil
      )
    }
  }

  /// Keeps loans URL of current synchronisation process.
  /// TPPBookRegistry is a shared object,
  /// this value is used to cancel synchronisation callback when the user changes library account.
  private var syncUrl: URL?

  private override init() {
    super.init()

  }

  fileprivate init(account: String) {
    super.init()
    load(account: account)
  }

  /// Performs a block of operations on the provided account.
  /// - Parameters:
  ///   - account: Library account identifier.
  ///   - block: Provides registry object for the provided account.
  func with(
    account: String,
    perform block: (_ registry: TPPBookRegistry) -> Void
  ) {
    block(TPPBookRegistry(account: account))
  }

  /// Registry file URL.
  /// - Parameter account: Library account identifier.
  /// - Returns: Registry file URL.
  func registryUrl(for account: String) -> URL? {
    TPPBookContentMetadataFilesHelper.directory(for: account)?
      .appendingPathComponent(registryFolderName)
      .appendingPathComponent(registryFileName)
  }

  /// Loads the book registry for the provided library account.
  /// - Parameter account: Library account identifier.
  func load(account: String? = nil) {

    guard let account = account ?? AccountsManager.shared.currentAccountId,
      let registryFileUrl = self.registryUrl(for: account)
    else {
      return
    }

    state = .loading
    registry.removeAll()

    if FileManager.default.fileExists(atPath: registryFileUrl.path),
      let registryData = try? Data(contentsOf: registryFileUrl),
      let jsonObject = try? JSONSerialization.jsonObject(with: registryData),
      let registryObject = jsonObject as? TPPBookRegistryData
    {
      if let records = registryObject.array(for: .records) {
        for recordObject in records {
          guard let record = TPPBookRegistryRecord(record: recordObject) else {
            continue
          }
          if record.state == .Downloading || record.state == .SAMLStarted {
            record.state = .DownloadFailed
          }
          self.registry[record.book.identifier] = record
        }
      }
    }

    state = .loaded
  }

  /// Removes registry data.
  /// - Parameter account: Library account identifier.
  func reset(_ account: String) {
    state = .unloaded
    registry.removeAll()
    if let registryUrl = registryUrl(for: account) {
      do {
        try FileManager.default.removeItem(at: registryUrl)
      } catch {
        Log.error(
          #file, "Error deleting registry data: \(error.localizedDescription)")
      }
    }
  }

  /// Helper for completion handler parameter type
  /// - Parameter errorDocument: error document for error handling
  /// - Parameter newBooks: boolean value indicating the presence of books available for download.
  typealias completionType = (
     _ errorDocument: [AnyHashable: Any]?,
     _ newBooks: Bool
    ) -> Void

  /// Synchronizes local registry data and current loans+holds data and selected books data.
  /// Function first syncs loans+holds data, and after that syncs selected books data.
  /// - Parameter completion: compeltion handler
  func sync(completion: completionType? = nil) {

    // Syncing loans+holds and selected needs some group work
    let dispatchGroup = DispatchGroup()

    var syncError: [AnyHashable: Any]? = nil
    var newBooksAvailable: Bool = false

    // First asyncronous task starts
    // We are entering the group!
    dispatchGroup.enter()

    // Let's first do a sync for book registry with loans+holds data
    syncLoansAndHolds { errorDocument, newReadyBooks in

      // If error document is produced in function syncLoans...
      if let errorDocument = errorDocument {
        // ...set it as syncError.
        syncError = errorDocument
      }

      // Keeping tabs if we have new reserved books, ready for user to be borrow and download
      // True, if there are new books
      // False, otherwise
      newBooksAvailable = newReadyBooks

      // First asyncronous task has ended
      // We are leaving the group!
      dispatchGroup.leave()
    }

    // We send a notification to the group,
    // that tells us we have now completed the first task.
    // We are ready to move on!
    dispatchGroup.notify(queue: .main) {

      // If syncError was set in first task...
      guard syncError == nil else {
        // ...call completion handler...

        completion?(syncError, newBooksAvailable)
        // ...and do not proceed further.
        return
      }

      // Second asyncronous task starts
      // We are entering the group again!
      dispatchGroup.enter()

      // Second sync for book registry with favorites data
      self.syncSelected { errorDocument, newBooks in

        if let errorDocument = errorDocument {
          syncError = errorDocument
        }

        newBooksAvailable = newBooksAvailable || newBooks

        // Second asyncronous task has ended
        // We are leaving the group (again!)
        dispatchGroup.leave()
      }

      // We notify the group that the second task has ended...
      dispatchGroup.notify(queue: .main) {

        // ... and then finally call completionHandler
        completion?(syncError, newBooksAvailable)
      }

    }

  }

  /// Synchronizes local registry data and current loans+holds data.
  /// This function
  ///   - adds, updates and removes books in book registry
  ///   - updates app icon badge and loans+holds tab badge with number of new books
  /// - Parameters:
  ///   - completion: a completion handler
  func syncLoansAndHolds(
    completion: completionType? = nil
  ) {
    printToConsole(
      .info,
      "Book registry starting loans+holds sync..."
    )

    // if loansURL is not found, return
    guard let loansUrl = AccountsManager.shared.currentAccount?.loansUrl else {
      printToConsole(
        .info,
        "Book registry aborting loans+holds sync, no URL for loans+holds feed"
      )
      completion?(nil, false)
      return
    }

    // if already synced with this URL, return
    if syncUrl == loansUrl {
      printToConsole(
        .info,
        "Book registry skipping loans+holds sync, already synced"
      )
      completion?(nil, false)
      return
    }

    // setting state and syncUrl for book registry syncing
    state = .syncing
    syncUrl = loansUrl
    printToConsole(
      .info,
      "[LOANS+HOLDS SYNC START] book registry state: \(self.state) and syncURL: \(syncUrl as URL?)"
    )

    TPPOPDSFeed.withURL(loansUrl, shouldResetCache: true) {
      feed, errorDocument in

      // Async: schedules a work item for immediate execution and returns immediately.
      DispatchQueue.main.async {

        // The stuff inside defer is done just before the end of this scope
        defer {
          self.state = .loaded
          self.syncUrl = nil
          printToConsole(
            .info,
            "[LOANS+HOLDS SYNC END] book registry state: \(self.state) and syncURL: \(self.syncUrl as URL?)"
          )
        }

        // return as it is not the right time to do sync
        if self.syncUrl != loansUrl {
          printToConsole(
            .info,
            "Book registry aborting loans+holds sync, syncURL mismatch"
          )
          completion?(nil, false)
          return
        }

        // If fetching resulted in error,
        // call completion with
        // - the error document
        // - and no number of ready books (false)
        // and return
        if let errorDocument = errorDocument {
          printToConsole(
            .info,
            "Book registry aborting loans+holds sync, errorDocument created"
          )
          completion?(errorDocument, false)
          return
        }

        // If no feed,
        // call completion with
        // - no error document (nil)
        // - and no number of ready books (false)
        // and return.
        guard let feed = feed else {
          printToConsole(
            .info,
            "Book registry aborting loans+holds sync, no feed"
          )
          completion?(nil, false)
          return
        }

        // Check and set licensor
        if let licensor = feed.licensor as? [String: Any] {
          TPPUserAccount.sharedAccount().setLicensor(licensor)
        }

        // Find records currently in book registry that should be removed

        // First get all current books in registry...
        var recordsToDelete = Set<String>(
          self.registry.keys.map { $0 as String })

        // ...then go trough all the entries in feed...
        for entry in feed.entries {
          // ..and create a book object for the entry in feed
          guard let opdsEntry = entry as? TPPOPDSEntry,
                let book = TPPBook(entry: opdsEntry)
          else {
            continue
          }

          printToConsole(
            .info,
            "Book in loans+holds feed: \(book.title)"
          )

          // This book is still in feed so it is still valid.
          // We take the book off from the books to be deleted
          recordsToDelete.remove(book.identifier)

          // Then continue to handle this book that is valid.

          // If the book can be found in registry already...
          if self.registry[book.identifier] != nil {
            // ...then just update the book record with book details.
            // As this is book in loans+holds feed,
            // the selection state is safe to set as .Unselected at this point.
            self.updateBook(
              book,
              selectionState: .Unselected
            )
          } else {
            // ...otherwise add the book as new book record.
            // As this is a book in loans+holds feed,
            // the selection state is safe to set as .Unselected at this point.
            self.addBook(
              book,
              state: .DownloadNeeded,
              selectionState: .Unselected
            )
          }
        }

        // Now the list of books to be removed from our registry is up to date.
        // Let's go through every book record to be deleted...
        recordsToDelete.forEach {
          // ...if book record can be found from registry and it has a state,
          // and if the state is DownloadSuccessful or Used...
          if let state = self.registry[$0]?.state,
             state == .DownloadSuccessful || state == .Used
          {
            // ...then clear the downloaded book data from the device...
            MyBooksDownloadCenter.shared.deleteLocalContent(for: $0)
          }

          // ...and make it nil in book registry
          self.registry[$0] = nil
        }

        // Then save the registry.
        self.save()

        // Find out how many new books there are in registry,
        // so we can check if any previously reserved book is ready to be loaned,
        // and then we can also update the badge
        // and return info for user that some books are ready to borrow.
        var readyBooks = 0

        // First get the books from registry that the user has on hold
        for book in self.heldBooks {
          printToConsole(
            .info,
            "Book on hold: \(book.title)"
          )

          book.defaultAcquisition?.availability.matchUnavailable(
            nil,
            limited: nil,
            unlimited: nil,
            reserved: nil,
            ready: { _ in
              readyBooks += 1
            }
          )
        }

        // If we have more ready books then previously,
        // then the numbers do not match.
        // We need to update the notification badge to let the user know,
        // that his/her reservation is ready to be borrowed
        if UIApplication.shared.applicationIconBadgeNumber != readyBooks {
          printToConsole(
            .info,
            "Number of new books ready to be borrowed: \(readyBooks)"
          )

          UserNotificationService.shared.setAppIconBadge(readyBooks)

          // Loans & Holds tab's index is currently 1...
          UserNotificationService.shared.setTabItemBadge(readyBooks, tabIndex: 1)
        }

        // And we are done with the loans+holds sync!
        // We call completion with
        // - no error document (nil) and
        // - true if there are books ready to be loaned
        completion?(nil, readyBooks > 0)

        // And finally we go to defer and do the stuff in there
      }
    }
  }

  /// Synchronizes local registry data and current selected (favorites) data.
  /// This selected books sync only adds or updates selected books in book registry.
  /// syncSelected is otherwise quite similar to syncLoansAndHolds
  /// - Parameter completion: a completion handler
  func syncSelected(
    completion: completionType? = nil
  ) {
    printToConsole(
      .info,
      "Starting selected sync..."
    )

    guard let selectionUrl = AccountsManager.shared.currentAccount?.selectionUrl
    else {
      printToConsole(
        .info,
        "Book registry aborting selected sync, no URL for selection feed"
      )
      completion?(nil, false)
      return
    }

    if syncUrl == selectionUrl {
      printToConsole(
        .info,
        "Book registry skipping selected sync, already synced"
      )
      completion?(nil, false)
      return
    }

    state = .syncing
    syncUrl = selectionUrl

    printToConsole(
      .info,
      "[SELECTED SYNC START] book registry state: \(self.state) and syncURL: \(syncUrl as URL?)"
    )

    TPPOPDSFeed.withURL(selectionUrl, shouldResetCache: true) {
      feed, errorDocument in

      DispatchQueue.main.async {
        defer {
          self.state = .loaded
          self.syncUrl = nil

          printToConsole(
            .info,
            "[SELECTED SYNC END] book registry state: \(self.state) and syncURL: \(self.syncUrl as URL?)"
          )
        }

        if self.syncUrl != selectionUrl {
          printToConsole(
            .info,
            "Book registry aborting selected sync, syncURL mismatch"
          )
          completion?(nil, false)
          return
        }

        if let errorDocument = errorDocument {
          printToConsole(
            .info,
            "Book registry aborting loans+holds sync, errorDocument created"
          )
          completion?(errorDocument, false)
          return
        }

        guard let feed = feed else {
          printToConsole(
            .info,
            "Book registry aborting selected sync, no feed"
          )
          completion?(nil, false)
          return
        }

        for entry in feed.entries {
          guard let opdsEntry = entry as? TPPOPDSEntry,
                let book = TPPBook(entry: opdsEntry)
          else {
            continue
          }

          printToConsole(
            .info,
            "Book in selected feed: \(book.title)"
          )

          if self.registry[book.identifier] != nil {
            // The selected book already exists in the book registry,
            // and the book is in selected feed,
            // lets just update the selection state as .Selected.
            // and not do other changes to book record.
            self.updateBook(
              self.registry[book.identifier]!.book,
              selectionState: .Selected
            )
          } else {
            // Book is a new book to book regisry,
            // which means that it was not introduced in loans+holds feed,
            // so let's add a book record as an unregistered book
            // that has selection state .Selected.
            self.addBook(
              book,
              state: .Unregistered,
              selectionState: .Selected
            )
          }
        }

        self.save()

        completion?(nil, false)
      }
    }
  }

  /// Saves book registry data
  /// and posts notification to observers that the registry has changed
  /// (this usually triggers the views load new data and refresh)
  private func save() {

    guard let account = AccountsManager.shared.currentAccount?.uuid,
      let registryUrl = registryUrl(for: account)
    else {
      return
    }

    do {
      if !FileManager.default.fileExists(atPath: registryUrl.path) {
        try FileManager.default.createDirectory(
          at: registryUrl.deletingLastPathComponent(),
          withIntermediateDirectories: true)
      }

      let registryValues = registry.values.map { $0.dictionaryRepresentation }  //.withNullValues() }
      let registryObject = [TPPBookRegistryKey.records.rawValue: registryValues]
      let registryData = try JSONSerialization.data(withJSONObject: registryObject,
                                                    options: .fragmentsAllowed)

      try registryData.write(to: registryUrl,
                             options: .atomic)

      NotificationCenter.default.post(name: .TPPBookRegistryDidChange,
                                      object: nil,
                                      userInfo: nil)

    } catch {
      Log.error(
        #file, "Error saving book registry: \(error.localizedDescription)")
    }
  }

  // For Objective-C code
  func load() {
    load(account: nil)
  }
  func sync() {
    sync(completion: nil)
  }

  // MARK: - Books

  /// Returns all books in book registry (= registered books)
  var allBooks: [TPPBook] {
    registry
      .map { $0.value }
      .filter { TPPBookStateHelper.allBookStates().contains($0.state.rawValue) }
      .map { $0.book }
  }

  /// Returns all registered books that are on hold.
  var heldBooks: [TPPBook] {
    registry
      .map { $0.value }
      .filter { $0.state == .Holding }
      .map { $0.book }
  }

  /// Returns all registered books that are on loan (and not on hold)
  var loans: [TPPBook] {
    let matchingStates: [TPPBookState] = [
      .DownloadNeeded,
      .Downloading,
      .SAMLStarted,
      .DownloadFailed,
      .DownloadSuccessful,
      .Used,
    ]
    return
      registry
      .map { $0.value }
      .filter { matchingStates.contains($0.state) }
      .map { $0.book }
  }

  /// Returns all registered books that are selected (= books that are favorites).
  var selectedBooks: [TPPBook] {
    return
      registry
      .map { $0.value }
      .filter { $0.selectionState == .Selected }
      .map { $0.book }
  }

  /// Adds a book to the book registry until it is manually removed. It allows the application to
  /// present information about obtained books when offline. Attempting to add a book already present
  /// will overwrite the existing book as if `updateBook` were called. The location may be nil. The
  /// state provided must be one of `TPPBookState` and must not be `TPPBookState.Unregistered`,
  /// unless the book is added from the selected feed.
  func addBook(
    _ book: TPPBook,
    location: TPPBookLocation? = nil,
    state: TPPBookState = .DownloadNeeded,
    selectionState: BookSelectionState,
    fulfillmentId: String? = nil,
    readiumBookmarks: [TPPReadiumBookmark]? = nil,
    genericBookmarks: [TPPBookLocation]? = nil
  ) {

    coverRegistry.pinThumbnailImageForBook(book)

    printToConsole(
      .info,
      "Adding book to book registry "
        + "with title: '\(book.title)' and "
        + "with state: \(TPPBookStateHelper.stringValue(from: state)) and "
        + "with selectionState: \(BookSelectionStateHelper.stringValue(from: selectionState))"
    )

    registry[book.identifier] = TPPBookRegistryRecord(
      book: book,
      location: location,
      state: state,
      selectionState: selectionState,
      fulfillmentId: fulfillmentId,
      readiumBookmarks: readiumBookmarks,
      genericBookmarks: genericBookmarks
    )

    save()
  }

  /// Given an identifier, this method removes a book from the registry
  /// if the book is not selected as favorite
  func removeBook(forIdentifier bookIdentifier: String) {

    if registry[bookIdentifier]?.selectionState == .Selected {
      // favorite books should not be removed
      // just update the book state to unregistered
      // and otherwise keep the book in registry
      registry[bookIdentifier]?.state = .Unregistered
    } else {
      // as the book is not a favorite book
      // it is safe to remove from book registry
      coverRegistry.removePinnedThumbnailImageForBookIdentifier(bookIdentifier)
      registry.removeValue(forKey: bookIdentifier)
    }

    save()
  }

  /// This method should be called whenever new book information is retrieved from a server. Doing so
  /// ensures that once the user has seen the new information, they will continue to do so when
  /// accessing the application off-line or when viewing books outside of the catalog. Attempts to
  /// update a book not already stored in the registry will simply be ignored, so it's reasonable to
  /// call this method whenever new information is obtained regardless of a given book's state.
  func updateBook(
    _ book: TPPBook,
    selectionState: BookSelectionState
  ) {

    guard let record = registry[book.identifier] else {
      return
    }

    // Check if a book on hold
    // is now ready to be downloaded
    // and notify the user immediately
    compareBookAvailabilityAndNotifyUser(
      bookInRegistry: record.book,
      bookFromFeed: book
    )

    printToConsole(
      .info,
      "Updating book in book registry "
        + "with title: '\(book.title)' and "
        + "with state: \(TPPBookStateHelper.stringValue(from: record.state)) and "
        + "with selectionState: \(BookSelectionStateHelper.stringValue(from: selectionState))"
    )

    // TPPBookRegistryRecord.init() contains logics for correct record updates
    registry[book.identifier] = TPPBookRegistryRecord(
      book: book,
      location: record.location,
      state: record.state,
      selectionState: selectionState,
      fulfillmentId: record.fulfillmentId,
      readiumBookmarks: record.readiumBookmarks,
      genericBookmarks: record.genericBookmarks
    )

  }

  /// Updates book metadata (e.g., from OPDS feed) in the registry and returns the updated book.
  func updatedBookMetadata(_ book: TPPBook) -> TPPBook? {
    guard let bookRecord = registry[book.identifier] else {
      return nil
    }
    let updatedBook = bookRecord.book.bookWithMetadata(from: book)
    registry[book.identifier]?.book = updatedBook
    save()
    return updatedBook
  }

  /// This will update the book like updateBook does, but will also set its state to unregistered, then
  /// broadcast the change, then remove the book from the registry (if it's not a favorite book).
  /// This gives any views using the book a chance to update their copy with the new one,
  /// without having to keep it in the registry after.
  func updateAndRemoveBook(_ book: TPPBook) {

    guard registry[book.identifier] != nil else {
      return
    }

    if registry[book.identifier]?.selectionState == .Selected {
      // Updating and removing a favorite book
      registry[book.identifier]?.book = book
      registry[book.identifier]?.state = .Unregistered
    } else {
      // Not a favorite book
      // so we can do more cleanup
      coverRegistry.removePinnedThumbnailImageForBookIdentifier(book.identifier)
      registry[book.identifier]?.book = book
      registry[book.identifier]?.state = .Unregistered
    }

    save()
  }

  /// Returns the book for a given identifier if it is registered, else nil.
  func book(forIdentifier bookIdentifier: String) -> TPPBook? {
    registry[bookIdentifier]?.book
  }

  /// Returns the fulfillmentId of a book given its identifier.
  func fulfillmentId(forIdentifier bookIdentifier: String) -> String? {
    registry[bookIdentifier]?.fulfillmentId
  }

  /// Returns whether a book is processing something, given its identifier.
  func processing(forIdentifier bookIdentifier: String) -> Bool {
    processingIdentifiers.contains(bookIdentifier)
  }

  /// Returns the selection state of a book given its identifier.
  func selectionState(for bookIdentifier: String) -> BookSelectionState {
    return registry[bookIdentifier]?.selectionState ?? .SelectionUnregistered
  }

  /// Returns the state of a book given its identifier.
  func state(for bookIdentifier: String) -> TPPBookState {
    return registry[bookIdentifier]?.state ?? .Unregistered
  }

  /// Sets the fulfillmentId for a book previously registered given its identifier.
  func setFulfillmentId(
    _ fulfillmentId: String,
    for bookIdentifier: String
  ) {
    registry[bookIdentifier]?.fulfillmentId = fulfillmentId
    save()
  }

  /// Sets the processing flag for a book previously registered given its identifier.
  func setProcessing(_ processing: Bool, for bookIdentifier: String) {
    if processing {
      processingIdentifiers.insert(bookIdentifier)
    } else {
      processingIdentifiers.remove(bookIdentifier)
    }
    NotificationCenter.default.post(
      name: .TPPBookProcessingDidChange,
      object: nil,
      userInfo: [
        TPPNotificationKeys.bookProcessingBookIDKey: bookIdentifier,
        TPPNotificationKeys.bookProcessingValueKey: processing,
      ])
  }

  /// Sets the selection state for a book previously registered given its identifier.
  func setSelectionState(
    _ selectionState: BookSelectionState,
    for bookIdentifier: String
  ) {
    registry[bookIdentifier]?.selectionState = selectionState
    save()
  }

  /// Sets the state for a book previously registered given its identifier.
  func setState(
    _ state: TPPBookState,
    for bookIdentifier: String
  ) {
    registry[bookIdentifier]?.state = state
    save()
  }

  /// Show a notification to user if the user's book
  /// has moved from the "holds queue" to the "reserved queue",
  /// and is now available for the user to checkout.
  func compareBookAvailabilityAndNotifyUser(
    bookInRegistry: TPPBook,
    bookFromFeed: TPPBook
  ) {

    var bookWasOnHold = false
    var bookIsNowReady = false

    let oldAvailability = bookInRegistry.defaultAcquisition?.availability

    oldAvailability?.matchUnavailable(
      nil,
      limited: nil,
      unlimited: nil,
      reserved: { _ in bookWasOnHold = true },
      ready: nil
    )

    let newAvailability = bookFromFeed.defaultAcquisition?.availability

    newAvailability?.matchUnavailable(
      nil,
      limited: nil,
      unlimited: nil,
      reserved: nil,
      ready: { _ in bookIsNowReady = true }
    )

    if (bookWasOnHold && bookIsNowReady) {
      UserNotificationService.shared.showBookIsAvailableNotification(bookFromFeed)
    }

  }

  // Check if background fetch is necessary
  // and fetch new book data only if it's really needed.
  // We want to circulate the books efficiently
  // but also avoid unnecessary network operations on user's app.
  func isBackgroundFetchNeeded() -> Bool {

    // First check if the user is waiting for some books
    if heldBooks.count > 0 {

      printToConsole(
        .debug,
        "User has books on hold: background fetch is needed"
      )

      // if user has one or more books on hold,
      // then a background fetch is needed
      // so we can update the books' status more quickly
      return true
    }

    printToConsole(
      .debug,
      "User has no books on hold: background fetch is not needed"
    )

    // user has no books on hold,
    // no need to get new data quickly
    return false
  }


  // MARK: - Book Cover

  /// Immediately returns the cached thumbnail if available, else nil. Generated images are not
  /// returned. The book does not have to be registered in order to retrieve a cover.
  func cachedThumbnailImage(for book: TPPBook) -> UIImage? {
    return coverRegistry.cachedThumbnailImageForBook(book)
  }

  /// Returns cover image if it exists, or falls back to thumbnail image load.
  func coverImage(
    for book: TPPBook,
    handler: @escaping (_ image: UIImage?) -> Void
  ) {
    coverRegistry.coverImageForBook(book, handler: handler)
  }

  /// Returns the thumbnail for a book via a handler called on the main thread. The book does not have
  /// to be registered in order to retrieve a cover.
  func thumbnailImage(
    for book: TPPBook,
    handler: @escaping (_ image: UIImage?) -> Void
  ) {
    coverRegistry.thumbnailImageForBook(book, handler: handler)
  }

  /// The dictionary passed to the handler maps book identifiers to images.
  /// The handler is always called on the main thread.
  /// The books do not have to be registered in order to retrieve covers.
  func thumbnailImages(
    forBooks books: Set<TPPBook>,
    handler: @escaping (_ bookIdentifiersToImages: [String: UIImage]) -> Void
  ) {
    coverRegistry.thumbnailImagesForBooks(books, handler: handler)
  }

}

// MARK: - TPPBookRegistry extension

extension TPPBookRegistry: TPPBookRegistryProvider {

  /// Returns the location of a book given its identifier.
  func location(forIdentifier bookIdentifier: String) -> TPPBookLocation? {
    registry[bookIdentifier]?.location
  }

  /// Sets the location for a book previously registered given its identifier.
  func setLocation(
    _ location: TPPBookLocation?,
    forIdentifier bookIdentifier: String
  ) {
    registry[bookIdentifier]?.location = location
    save()
  }

  // MARK: - Readium Bookmarks

  /// Returns the bookmarks for a book given its identifier.
  func readiumBookmarks(forIdentifier bookIdentifier: String)
    -> [TPPReadiumBookmark]
  {
    registry[bookIdentifier]?.readiumBookmarks?
      .sorted { $0.progressWithinBook < $1.progressWithinBook } ?? []
  }

  /// Adds bookmark for a book given its identifier
  func add(
    _ bookmark: TPPReadiumBookmark,
    forIdentifier bookIdentifier: String
  ) {
    guard registry[bookIdentifier] != nil else {
      return
    }
    if registry[bookIdentifier]?.readiumBookmarks == nil {
      registry[bookIdentifier]?.readiumBookmarks = [TPPReadiumBookmark]()
    }
    registry[bookIdentifier]?.readiumBookmarks?.append(bookmark)
    save()
  }

  /// Deletes bookmark for a book given its identifer.
  func delete(
    _ bookmark: TPPReadiumBookmark,
    forIdentifier bookIdentifier: String
  ) {
    registry[bookIdentifier]?.readiumBookmarks?.removeAll { $0 == bookmark }
    save()
  }

  /// Replace a bookmark with another, given its identifer.
  func replace(
    _ oldBookmark: TPPReadiumBookmark,
    with newBookmark: TPPReadiumBookmark,
    forIdentifier bookIdentifier: String
  ) {
    registry[bookIdentifier]?.readiumBookmarks?.removeAll { $0 == oldBookmark }
    registry[bookIdentifier]?.readiumBookmarks?.append(newBookmark)
    save()
  }

  // MARK: - Generic Bookmarks

  /// Returns the generic bookmarks for a any renderer's bookmarks given its identifier
  func genericBookmarksForIdentifier(_ bookIdentifier: String)
    -> [TPPBookLocation]
  {
    registry[bookIdentifier]?.genericBookmarks ?? []
  }

  /// Adds a generic bookmark (book location) for a book given its identifier
  func addGenericBookmark(
    _ location: TPPBookLocation,
    forIdentifier bookIdentifier: String
  ) {
    guard registry[bookIdentifier] != nil else {
      return
    }

    if registry[bookIdentifier]?.genericBookmarks == nil {
      registry[bookIdentifier]?.genericBookmarks = [TPPBookLocation]()
    }
    registry[bookIdentifier]?.genericBookmarks?.append(location)
    save()
  }

  func addOrReplaceGenericBookmark(
    _ location: TPPBookLocation,
    forIdentifier bookIdentifier: String
  ) {
    guard
      let existingBookmark = registry[bookIdentifier]?.genericBookmarks?.first(
        where: { $0 == location })
    else {
      addGenericBookmark(location, forIdentifier: bookIdentifier)
      return
    }

    replaceGenericBookmark(
      existingBookmark, with: location, forIdentifier: bookIdentifier)
  }

  /// Deletes a generic bookmark (book location) for a book given its identifier
  func deleteGenericBookmark(
    _ location: TPPBookLocation,
    forIdentifier bookIdentifier: String
  ) {
    registry[bookIdentifier]?.genericBookmarks?.removeAll {
      $0.isSimilarTo(location)
    }
    save()
  }

  func replaceGenericBookmark(
    _ oldLocation: TPPBookLocation,
    with newLocation: TPPBookLocation,
    forIdentifier bookIdentifier: String
  ) {
    deleteGenericBookmark(oldLocation, forIdentifier: bookIdentifier)
    registry[bookIdentifier]?.genericBookmarks?.append(newLocation)
    save()
  }
}

// MARK: - TPPBookLocation extension

extension TPPBookLocation {

  func locationStringDictionary() -> [String: Any]? {
    guard let data = locationString.data(using: .utf8),
      let dictionary = try? JSONSerialization.jsonObject(
        with: data, options: .allowFragments) as? [String: Any]
    else { return nil }

    return dictionary
  }

  func isSimilarTo(_ location: TPPBookLocation) -> Bool {
    guard renderer == location.renderer,
      let locationDict = locationStringDictionary(),
      let otherLocationDict = location.locationStringDictionary()
    else { return false }

    var areEqual = true

    for (key, value) in locationDict {
      if key == "lastSavedTimeStamp" { continue }

      if let otherValue = otherLocationDict[key] {
        if "\(value)" != "\(otherValue)" {
          areEqual = false
          break
        }
      } else {
        areEqual = false
        break
      }
    }

    return areEqual
  }
}

//
//  BookButtonState.swift
//  Palace
//
//  Created by Maurice Carrier on 2/2/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

enum BookButtonState {
  case canBorrow
  case canHold
  case holding
  case holdingFrontOfQueue
  case downloadNeeded
  case downloadSuccessful
  case used
  case downloadInProgress
  case downloadFailed
  case unsupported
}

extension BookButtonState {
  func buttonTypes(book: TPPBook) -> [BookButtonType] {
    var buttons = [BookButtonType]()
  
    switch self {
    case .canBorrow:
      buttons = [.get, book.isAudiobook ? .audiobookSample : .sample]
    case .canHold:
      buttons = [.reserve, book.isAudiobook ? .audiobookSample : .sample]
    case .holding:
      buttons = [.remove, book.isAudiobook ? .audiobookSample : .sample]
    case .holdingFrontOfQueue:
      buttons = [.get, .remove]
    case .downloadNeeded:
      if let authDef = TPPUserAccount.sharedAccount().authDefinition,
         authDef.needsAuth || book.defaultAcquisitionIfOpenAccess != nil {
        buttons = [.download, .return]
      } else {
        buttons = [.download, .remove]
      }
    case .downloadSuccessful, .used:
      switch book.defaultBookContentType {
      case .audiobook:
        buttons.append(.listen)
      case .pdf, .epub:
        buttons.append(.read)
      case .unsupported:
        break
      }

      if let authDef = TPPUserAccount.sharedAccount().authDefinition,
         authDef.needsAuth ||
          book.defaultAcquisitionIfOpenAccess != nil {
        buttons.append(.return)
      } else {
        buttons.append(.remove)
      }
    case .downloadInProgress:
      buttons = [.cancel]
    case .downloadFailed:
      buttons = [.cancel, .retry]
    case .unsupported:
      return []
    }

    if !book.supportsDeletion(for: self) {
      buttons = buttons.filter {
        $0 != .return || $0 != .remove
      }
    }

    return buttons
  }
}

extension BookButtonState {

  init?(_ book: TPPBook) {
    let bookState = TPPBookRegistry.shared.state(for: book.identifier)
    switch bookState {
    case .Unregistered, .Holding:
      guard let buttonState = Self.init(book.defaultAcquisition?.availability) else {
        TPPErrorLogger.logError(withCode: .noURL, summary: "Unable to determine BookButtonsViewState because no Availability was provided")
        return nil
      }

      self = buttonState
    case .DownloadNeeded:
      self = .downloadNeeded
    case .DownloadSuccessful:
      self = .downloadSuccessful
    case .SAMLStarted, .Downloading:
      // SAML started is part of download process, in this step app does authenticate user but didn't begin file downloading yet
      // The cell should present progress bar and "Requesting" description on its side
      self = .downloadInProgress
    case .DownloadFailed:
      self = .downloadFailed
    case .Used:
      self = .used
    case .Unsupported:
      self = .unsupported
    }
  }

  init?(_ availability: TPPOPDSAcquisitionAvailability?) {
    guard let availability = availability else {
      return nil
    }

    var state: BookButtonState = .unsupported
    availability.matchUnavailable { _ in
      state = .canHold
    } limited: { _ in
      state = .canBorrow
    } unlimited: { _ in
      state = .canBorrow
    } reserved: { _ in
      state = .holdingFrontOfQueue
    }

    self = state
  }
}

extension TPPBook {
  func supportsDeletion(for state: BookButtonState) -> Bool {
    var fullfillmentRequired = false
    #if FEATURE_DRM_CONNECTOR
      fullfillmentRequired = state == .holding && self.revokeURL != nil
    #endif
    
    let hasFullfillmentId = TPPBookRegistry.shared.fulfillmentId(forIdentifier: self.identifier) != nil
    let isFullfiliable = !(hasFullfillmentId && fullfillmentRequired) && self.revokeURL != nil
    let needsAuthentication = self.defaultAcquisitionIfOpenAccess == nil && TPPUserAccount.sharedAccount().authDefinition?.needsAuth ?? false
    
    return isFullfiliable && !needsAuthentication
  }
}

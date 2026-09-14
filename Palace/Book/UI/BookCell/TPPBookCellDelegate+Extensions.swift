//
//  TPPBookCellDelegate+Extensions.swift
//  Palace
//
//  Created by Maurice Carrier on 4/12/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//
import Foundation
import PalaceAudiobookToolkit

@objc extension TPPBookCellDelegate {
  public func saveListeningPosition(at location: String, completion: ((_ serverID: String?) -> Void)? = nil) {
    // Route through the bookmark business logic so the position is posted
    // in the cross-platform v2 locator format when possible.
    if let businessLogic = audiobookBookmarkBusinessLogic {
      businessLogic.saveListeningPosition(at: location, completion: completion)
    } else {
      TPPAnnotations.postListeningPosition(forBook: self.book.identifier, selectorValue: location, completion: completion)
    }
  }
}

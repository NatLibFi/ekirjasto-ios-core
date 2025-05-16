//
//  BookButtonType.swift
//  Palace
//
//  Created by Maurice Carrier on 2/17/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

enum BookButtonType: String {
  case get
  case reserve
  case download
  case read
  case listen
  case retry
  case cancel
  case remove
  case `return`
  case select
  case unselect

  var localizedTitle: String {
    NSLocalizedString(
      self.rawValue.capitalized, comment: "Book Action Button title")
  }

  var displaysIndicator: Bool {
    switch self {
    case .read, /*.remove,*/ .get, .download, .listen:
      return true
    default:
      return false
    }
  }

  var isDisabled: Bool {
    switch self {
    case .read, .listen, .remove:
      return false
    default:
      return !Reachability.shared.isConnectedToNetwork()
    }
  }
}

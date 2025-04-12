//
//  BookSelectionState.swift
//  E-kirjasto
//

import Foundation

let SelectedKey = "selected"
let UnselectedKey = "unselected"
let SelectionUnregisteredKey = "selectionUnregistered"

@objc public enum BookSelectionState: Int, CaseIterable {
  case Selected
  case Unselected
  case SelectionUnregistered

  init?(_ stringValue: String) {
    switch stringValue {
    case SelectedKey:
      self = .Selected
    case UnselectedKey:
      self = .Unselected
    case SelectionUnregisteredKey:
      self = .SelectionUnregistered
    default:
      return nil
    }
  }

  func stringValue() -> String {
    switch self {
    case .Selected:
      return SelectedKey
    case .Unselected:
      return UnselectedKey
    case .SelectionUnregistered:
      return SelectionUnregisteredKey
    }
  }
}

class BookSelectionStateHelper: NSObject {

  @objc(stringValueFromBookSelectionState:)
  static func stringValue(from bookSelectionState: BookSelectionState) -> String {
    return bookSelectionState.stringValue()
  }

  @objc(bookSelectionStateFromStringValue:)
  static func bookSelectionState(from stringValue: String) -> NSNumber? {
    guard let selectionState = BookSelectionState(stringValue) else {
      return nil
    }

    return NSNumber(integerLiteral: selectionState.rawValue)
  }

}

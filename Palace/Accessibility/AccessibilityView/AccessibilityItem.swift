//
//  AccessibilityItem.swift
//

import Foundation

struct AccessibilityItem: Hashable, Identifiable {
  let id = UUID()
  let name: String
  let value: String?
  
  // init with default value for value
  init(name: String, value: String? = nil) {
    self.name = name
    self.value = value
  }
  
}

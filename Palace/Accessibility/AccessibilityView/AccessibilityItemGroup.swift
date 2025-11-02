//
//  AccessibilityItemGroup.swift
//

import Foundation

struct AccessibilityItemGroup: Identifiable {
  let id = UUID()
  let name: String
  let accessibilityItems: [AccessibilityItem]
}

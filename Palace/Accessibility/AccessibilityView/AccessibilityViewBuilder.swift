//
//  AccessibilityViewBuilder.swift
//

import Foundation
import SwiftUI


class AccessibilityViewBuilder {
  
  
  func buildAccessibilityItemGroups(_ book: TPPBook) -> [AccessibilityItemGroup] {
    
    guard let bookAccessibility: BookAccessibility = book.bookAccessibility else {
      return []
    }
    
    printToConsole(
      .debug,
      "bookAccessibility: \(bookAccessibility.loggableBookAccessibility())"
    )
    
    return accessibilityItemGroups(bookAccessibility)
  }
  
  // Main function to create accessibility sections (item groups)
  private func accessibilityItemGroups(_ bookAccessibility: BookAccessibility) -> [AccessibilityItemGroup] {
    
    var accessibilityItemGroups: [AccessibilityItemGroup] = []
    
    // Create Conformance section
    if let conformanceItemGroup = createConformanceItemGroup(bookAccessibility.conformance) {
      accessibilityItemGroups.append(conformanceItemGroup)
    }
    
    // Create Ways of Reading section
    if let waysOfReadingItemGroup = createWaysOfReadingItemGroup(bookAccessibility.waysOfReading) {
      accessibilityItemGroups.append(waysOfReadingItemGroup)
    }
    
    return accessibilityItemGroups
  }
  
  
  // Helper function to create the Conformance group
  private func createConformanceItemGroup(_ bookConformance: BookAccessibility.Conformance) -> AccessibilityItemGroup? {
    
    let conformanceName = bookConformance.localisation
    
    var conformanceItems: [AccessibilityItem] = []
    
    // Check if 'conformsTo' is not nil and add it to the accessibility items
    if let conformsTo = bookConformance.conformsTo {
      conformanceItems.append(
        AccessibilityItem(
          name: conformsTo
        )
      )
    }
    
    // Use guard to check if there are items
    guard !conformanceItems.isEmpty else {
      return nil // Return nil if no items are available
    }
    
    // Create and return the conformance group
    return AccessibilityItemGroup(
      name: conformanceName,
      accessibilityItems: conformanceItems
    )
    
  }
  
  
  // Helper function to create the Ways of Reading grouo
  private func createWaysOfReadingItemGroup(_ bookWaysOfReading: BookAccessibility.WaysOfReading) -> AccessibilityItemGroup? {
    
    let waysOfReadingName = bookWaysOfReading.localisation
    
    var waysOfReadingItems: [AccessibilityItem] = []
    
    if let features = bookWaysOfReading.features, !features.isEmpty {
      
      for feature in features {
        waysOfReadingItems.append(
          AccessibilityItem(
            name: feature
          )
        )
      }
    }
    
    // Use guard to check if there are items
    guard !waysOfReadingItems.isEmpty else {
      return nil // Return nil if no items are available
    }
    
    return AccessibilityItemGroup(
      name: waysOfReadingName,
      accessibilityItems: waysOfReadingItems
    )
    
  }
  
}

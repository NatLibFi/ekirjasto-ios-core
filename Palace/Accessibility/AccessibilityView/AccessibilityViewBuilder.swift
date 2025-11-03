//
//  AccessibilityViewBuilder.swift
//

import Foundation
import SwiftUI


// MARK: - AccessibilityViewBuilder class

// This class builds accessibility related information for books.
// This info is needed in the AccessibilityView
// For example: accessibility labels and custom structs
class AccessibilityViewBuilder {
  
  
  // MARK: - Public functions
  
  // Build accessibility label for the item group given as parameter.
  // Function returns a string containing all the information
  // of the group: title for group and all the items and their possible values
  // This is done to help screen reader users
  func buildAccessibilityLabel(_ itemGroup: AccessibilityItemGroup) -> String {
    
    let items = itemGroup.accessibilityItems
    let groupName = itemGroup.name
    
    // create string of item names
    // and also of their values if available
    let itemNamesAndValues: String = items
    // map all items to strings
      .map { item in
        
        if let value = item.value {
          // because item has value
          
          // return both name and value
          return "\(item.name) \(value)"
        } else {
          // just return the name if there is no value
          return item.name
        }
        
      }
    // separate resulted strings with comma
      .joined(separator: ", ")
    
    // return the constructed accessiblity label
    return groupName + ": " + itemNamesAndValues
  }
  
  
  // Build accessibility item groups from the book given as parameter
  // return a list of books all accessibility info as AccessibilityItemGroups
  func buildAccessibilityItemGroups(_ book: TPPBook) -> [AccessibilityItemGroup] {
    
    // first make sure that the book has accessibility information
    guard let bookAccessibility: BookAccessibility = book.bookAccessibility else {
      // no bookAccessibility property
      // so return fast with empty array
      return []
    }
    
    printToConsole(
      .debug,
      "bookAccessibility: \(bookAccessibility.loggableBookAccessibility())"
    )
    
    var accessibilityItemGroups: [AccessibilityItemGroup] = []
    
    // create Conformance section
    if let conformanceItemGroup = createConformanceItemGroup(bookAccessibility.conformance) {
      accessibilityItemGroups.append(conformanceItemGroup)
    }
    
    // create Ways of Reading section
    if let waysOfReadingItemGroup = createWaysOfReadingItemGroup(bookAccessibility.waysOfReading) {
      accessibilityItemGroups.append(waysOfReadingItemGroup)
    }
    
    // return the filled array holding all accessiblity item groups
    return accessibilityItemGroups
  }
  
  
  // MARK: - Private helper functions
  
  
  // Create Conformance accessibility item group
  // from the book's accessibility information.
  // Returns one AccessibilityItemGroup
  // containing the conformance data such as
  // localisation and conformsTo string.
  // (or returns nil, if there was no valid conformance data)
  private func createConformanceItemGroup(_ bookConformance: BookAccessibility.Conformance) -> AccessibilityItemGroup? {
    
    let conformanceName = bookConformance.localisation
    
    var conformanceItems: [AccessibilityItem] = []
    
    // check if 'conformsTo' is not nil
    // and add it to the accessibility items
    if let conformsTo = bookConformance.conformsTo {
      conformanceItems.append(
        AccessibilityItem(
          name: conformsTo
        )
      )
    }
    
    // make sure that there are items
    guard !conformanceItems.isEmpty else {
      // just return nil because no items are available
      return nil
    }
    
    // create and return the whole
    // conformance group for view
    return AccessibilityItemGroup(
      name: conformanceName,
      accessibilityItems: conformanceItems
    )
    
  }
  
  
  // Create WaysOfReading accessibility item group
  // from the book's accessibility information
  // Returns one AccessibilityItemGroup
  // containing the ways of reading data such as
  // localisation and list of features.
  // (or returns nil, if there was no valid way of reading data)
  private func createWaysOfReadingItemGroup(_ bookWaysOfReading: BookAccessibility.WaysOfReading) -> AccessibilityItemGroup? {
    
    let waysOfReadingName = bookWaysOfReading.localisation
    
    var waysOfReadingItems: [AccessibilityItem] = []
    
    // first check that there are features available and
    // then add them as items
    if let features = bookWaysOfReading.features, !features.isEmpty {
      
      for feature in features {
        // create an AccessibilityItem for each feature
        waysOfReadingItems.append(
          AccessibilityItem(
            name: feature
          )
        )
      }
    }
    
    // check that there are now valid items
    guard !waysOfReadingItems.isEmpty else {
      // return nil because no items are available
      return nil
    }
    
    // create and return the whole
    // waysofreading group for view
    return AccessibilityItemGroup(
      name: waysOfReadingName,
      accessibilityItems: waysOfReadingItems
    )
    
  }
  
}

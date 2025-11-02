//
//  BookAccessibility.swift
//

import Foundation


// MARK: - BookAccessibility class for book's accessibility information

@objc
public class BookAccessibility: NSObject {
  // This class represents the accessibility information of a book
  // such as information about the book's conformance and ways of reading
  
  
  // MARK: - Properties

  // BookAccessibility has properties
  // that hold the actual accessibility metadata
  let conformance: Conformance
  let waysOfReading: WaysOfReading
  
  
  // MARK: - Initializer

  // inits a BookAccessibility instance
  // using the accessibility dictionary given as parameter
  init(_ accessibilityDictionary: AccessibilityDictionary) {
    
    // create instances for accessibility information
    // and set them as properties
    self.conformance = Conformance(accessibilityDictionary)
    self.waysOfReading = WaysOfReading(accessibilityDictionary)
  }
  
  
  // MARK: - Public helper functions
  
  // this function returns the book accessibility instance
  // a a loggable String
  @objc
  public func loggableBookAccessibility() -> String {
    
    return """
        \n
          \(conformanceAsString())
          \(waysOfReadingAsString())
        \n
      """
  }
  
}

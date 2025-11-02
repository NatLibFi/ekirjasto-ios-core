//
//  BookAccessibility+Conformance.swift
//


// MARK: - Extension of BookAccessibility class

extension BookAccessibility {
  // this class extension adds functionality to BookAccessibility class

  
  // MARK: - Conformance structure

  struct Conformance {
    // this structure handles all the accessibility details of the book
    // related to conformance that are available in book accessibility metadata
    // example of the feed:
    //  <conformance>
    //    <conformsTo>This publication meets accepted accessibility standards</conformsTo>
    //  </conformance>
    
    
    // MARK: - Properties for Conformance
    
    // localisation is localised string for "Conformance"
    // conformsTo is optional String for a standard
    let localisation: String
    let conformsTo: String?
    
    
    // MARK: - Initialisation for Conformance
    
    // get's the accessibility dictionary as parameter
    // and extracts the way of reading data from it
    init(_ accessibilityDictionary: AccessibilityDictionary) {
      
      // get the localized string
      let localisation = Strings.Accessibility.conformance
      
      // define some known dictionary keys
      let conformanceKey = "conformance"
      let conformsToKey = "conformsTo"
      
      var conformsTo: String?
      
      // try to get the dictionary associated with the conformanceKey
      if let conformanceDictionary = accessibilityDictionary[conformanceKey] as? AccessibilityDictionary,
         let conformsToArray = conformanceDictionary[conformsToKey] as? [String]
      {
        // conformsTo should be the only String in the array
        conformsTo = conformsToArray.first
      }

      self.localisation = localisation
      self.conformsTo = conformsTo
    }
    
  }
  
  
  // MARK: - Public helper functions
  
  // this function returns the conformance structure as loggable String
  func conformanceAsString () -> String {
    let localisationString = self.conformance.localisation
    
    let conformsToString = self.conformance.conformsTo ?? ""
    
    return "\(localisationString): \(conformsToString)"
  }
  
}

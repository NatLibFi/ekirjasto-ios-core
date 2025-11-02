//
//  BookAccessibility+WaysOfReading.swift
//


// MARK: - Extension of BookAccessibility class

extension BookAccessibility {
  // this class extension adds functionality to BookAccessibility class
  
  
  // MARK: - WaysOfReading structure

  struct WaysOfReading {
    // this structure handles all the accessibility details of the book
    // related to way of reading that are available in book accessibility metadata
    // example of the feed:
    //  <waysOfReading>
    //    <feature>Appearance can be modified</feature>
    //    <feature>Has alternative text</feature>
    //    <feature>Not fully readable in read aloud or dynamic braille</feature>
    //    <feature>Readable in read aloud or dynamic braille</feature>
    //   </waysOfReading>
    
    // MARK: - Properties for WaysOfReading
    
    // localisation is localised string for "Ways of reading"
    // features is optional array for different ways of reading
    // example
    let localisation: String
    let features: [String]?
    
    
    // MARK: - Initialisation for WaysOfReading
    
    // get's the accessibility dictionary as parameter
    // and extracts the way of reading data from it
    init(_ accessibilityDictionary: AccessibilityDictionary) {
      
      // get the localized string
      let localisation = Strings.Accessibility.waysOfReading
      
      // define some known dictionary keys
      let waysOfReadingKey = "waysOfReading"
      let featureKey = "feature"
      
      // initialise list of features
      var features: [String] = []
      
      // first try to get the value linked to
      // the key "waysOfReading" from the dictionary.
      // the expected value is also a dictionary
      // and it should hold array of strings with key "feature"
      if let waysOfReadingDictionary = accessibilityDictionary[waysOfReadingKey] as? AccessibilityDictionary,
         let featureArray = waysOfReadingDictionary[featureKey] as? [String]
      {
        features = featureArray
      }
      
      self.localisation = localisation
      self.features = features
    }
    
  }
  
  
  // MARK: - Public helper functions
  
  // this function returns the ways of reading structure as loggable String
  func waysOfReadingAsString() -> String {
    
    let localisationString: String = self.waysOfReading.localisation
    
    var featuresString: String = ""
    if let features = self.waysOfReading.features, !features.isEmpty {
      featuresString = features.joined(separator: ", ")
    }
    
    return "\(localisationString): \(featuresString)"
  }
  
}

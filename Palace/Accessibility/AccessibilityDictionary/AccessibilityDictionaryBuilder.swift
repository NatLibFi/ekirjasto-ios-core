//
//  AccessibilityDictionaryBuilder.swift
//

import Foundation

// MARK: - AccessibilityDictionaryBuilder Class

// just define a Swift typealias for the accessibility dictionary's type
typealias AccessibilityDictionary = [String: Any]


@objcMembers
class AccessibilityDictionaryBuilder: NSObject {
  // Class that handles building an accessibility dictionary from given XML
  
  
  // MARK: - Public functions

  // Function to build an accessibility dictionary from the provided XML entry
  @objc
  func buildAccessibilityDictionary(from entryXML: TPPXML) -> AccessibilityDictionary {

    printToConsole(
      .debug,
      "Starting to build accessibility dictionary from entryXML"
    )

    // extract the accessibility fields from the entryXML
    // accessibility fields means the <accessibility> ... </accessibility> XML element
    guard let accessibilityXML = entryXML.firstChild(withName: "accessibility")
    else {

      printToConsole(
        .debug,
        "No <accessibility> field in entryXML"
      )

      // just return an empty dictionary immediately
      // if the <accessibility> tag was not found
      return [:]
    }

    // call the helper function
    // to build the accessibility dictionary from the accessibility XML
    // and then return the result (the new accessibility dictionary)
    return createDictionaryFromChildElements(accessibilityXML)
  }

  // MARK: - Private functions

  // Helper function that builds a dictionary
  // from the child elements of the provided XML element.
  // Note: this function is used recursively if needed
  private func createDictionaryFromChildElements(_ parent: TPPXML) -> AccessibilityDictionary {

    // first initialize a dictionary
    // the dictionary will finally hold all the fields
    // that are extracted from the parent XML element
    var dictionary: AccessibilityDictionary = [:]

    // loop through all child elements of the parent
    // note: the child is an XML element also
    for child in parent.children {

      // set the child and child's name
      guard let child = child as? TPPXML,
        let childName = child.name
      else {
        // skip to the next child
        // if the child's type is not TPPXML
        // or if does not have name
        continue
      }

      // this checks if the child itself has any child elements
      // note: child could also have a value
      // but we are not interested in text values
      // if there are also child elements present.
      // (and mixed content is not usually supported
      // in e-kirjasto's default feed xml schema)
      let hasChildElements: Bool = child.children.count > 0

      if hasChildElements {

        // create a dictionary
        // for all the child's child elements
        // note: recursive call of function
        let subDictionary = createDictionaryFromChildElements(child)

        // check that the dictionary was successfully created
        // from the child elements (of the child)
        guard !subDictionary.isEmpty else {
          // skip to next child because no subdictionary to add
          continue
        }

        // add the child's dictionary to the main dictionary
        dictionary[childName] = subDictionary

      } else {
        // we end up here if the child
        // does not have any child elements
        // it means that the child should have an actual value

        // trim the child's value just in case
        let value = child.value.trimmingCharacters(in: .whitespacesAndNewlines)

        // check that the childValue is not empty string
        guard !value.isEmpty else {
          // skip to next child if the value is just ""
          continue
        }

        // first check if a list for the child
        // already exists in the dictionary
        if dictionary[childName] == nil {

          // if not, then create and add a new list
          // using the child's name as the key
          dictionary[childName] = NSMutableArray()

        }

        // then fetch the list from the dictionary
        if let listOfValues = dictionary[childName] as? NSMutableArray {

          // and add the child's value to the list
          listOfValues.add(value)

        }

      }

    }

    // return the collected accessibility fields
    // in a dictionary format
    return dictionary

  }

}

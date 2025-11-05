//
//  AccessibilityViewController.swift
//

import SwiftUI

class AccessibilityViewController: NSObject {
  
  @MainActor @objc
  func createAccessibilityViewController(book: TPPBook) -> UIViewController {
    let accessibilityView = AccessibilityView(book: book)
    
    return UIHostingController(rootView: accessibilityView)
  }
  
}

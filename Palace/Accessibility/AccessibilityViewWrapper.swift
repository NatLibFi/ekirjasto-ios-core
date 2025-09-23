//
//  AccessibilityViewWrapper.swift
//

import SwiftUI

class AccessibilityViewWrapper: NSObject {
  
  @MainActor @objc func makeAccessibilityViewUI(book: TPPBook) -> UIViewController {
    let accessibilityView = AccessibilityView(book: book)
    
    return UIHostingController(rootView: accessibilityView)
  }
  
}

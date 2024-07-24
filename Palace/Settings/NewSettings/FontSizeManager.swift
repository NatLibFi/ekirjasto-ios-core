//
//  FontSizeManager.swift
//  Ekirjasto
//
//  Created by Kuivalahti, Kaisa K on 24.7.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI

// A ViewModel to manage the font size
class FontSizeManager: ObservableObject {
  static let shared = FontSizeManager()
  
  @Published var fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize
  
  func fontSize(for textStyle: UIFont.TextStyle) -> CGFloat {
      let preferredSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
      let scaleFactor = preferredSize / UIFont.preferredFont(forTextStyle: .body).pointSize
      return fontSize * scaleFactor
  }}

struct FontSizeAdjustView: View {
    @ObservedObject var fontSizeManager = FontSizeManager.shared

    var body: some View {
        VStack {
            // Slider to adjust font size (for demonstration purposes)
            Slider(value: $fontSizeManager.fontSize, in: 10...100, step: 1)
            
            // Display the current font size
            Text("Font Size: \(Int(fontSizeManager.fontSize))")
        }
        .padding()
    }
}

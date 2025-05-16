//
//  UIFont+Ekirjasto.swift
//  Ekirjasto
//
//  Created by Nianzu on 19.6.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

extension UIFont {

    /**
     The below three functions return a dynamically scaled custom font for the specified text style and weight. If the user has changed the font size in the app, it won't allow system font size changes, and vice versa.

     - Parameters:
       - textStyle: The text style to use for the font (e.g., `.body`, `.headline`).
       - weight: The weight of the font. Defaults to `.regular`.
     - Returns: A dynamically scaled custom font.
     */

  @objc class func palaceFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {

    // Retrieve the user-selected font size adjustment (if any)
    let fontSizeAdjusted = UserDefaults.standard.bool(forKey: "enablePreferences")
    
    // Retrieve the multiplier to be applied to given font
    var fontMultiplier = UserDefaults.standard.double(forKey: "fontMultiplier")
    if fontMultiplier == 0.0 {
      fontMultiplier = 1.0
    }
    
    if fontSizeAdjusted {
      // Apply user font size adjustment to the given font size
      let baseFontSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
      let setFontSize: CGFloat
      setFontSize = baseFontSize * fontMultiplier
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: setFontSize) ?? UIFont.systemFont(ofSize: setFontSize, weight: weight)
      return font
      // Apply system font size adjustment to the given size
    } else {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) ?? UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
      return UIFontMetrics.default.scaledFont(for: font)
    }
  }

  @objc class func semiBoldPalaceFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
    
    // Retrieve the user-selected font size adjustment (if any)
    let fontSizeAdjusted = UserDefaults.standard.bool(forKey: "enablePreferences")
    
    // Retrieve the multiplier to be applied to given font
    var fontMultiplier = UserDefaults.standard.double(forKey: "fontMultiplier")
    if fontMultiplier == 0.0 {
      fontMultiplier = 1.0
    }
    
    if fontSizeAdjusted {
      // Apply user font size adjustment to the given font size
      let baseFontSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
      let setFontSize: CGFloat
      setFontSize = baseFontSize * fontMultiplier
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: setFontSize) ?? UIFont.systemFont(ofSize: setFontSize, weight: weight)
      return font
      // Apply system font size adjustment to the given size
    } else {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) ?? UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
      return UIFontMetrics.default.scaledFont(for: font)
    }
  }

  @objc class func boldPalaceFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
    
    // Retrieve the user-selected font size adjustment (if any)
    let fontSizeAdjusted = UserDefaults.standard.bool(forKey: "enablePreferences")
    
    // Retrieve the multiplier to be applied to given font
    var fontMultiplier = UserDefaults.standard.double(forKey: "fontMultiplier")
    if fontMultiplier == 0.0 {
      fontMultiplier = 1.0
    }
    
    if fontSizeAdjusted {
      // Apply user font size adjustment to the given font size
      let baseFontSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
      let setFontSize: CGFloat
      setFontSize = baseFontSize * fontMultiplier
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: setFontSize) ?? UIFont.systemFont(ofSize: setFontSize, weight: weight)
      return font
      // Apply system font size adjustment to the given size
    } else {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) ?? UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
      return UIFontMetrics.default.scaledFont(for: font)
    }
  }
  
    /**
     These three functions below return a dynamically scaled custom font for the specified size. If the user has changed the font size in the app, it won't allow system font size changes, and vice versa.

     - Parameters:
       - fontSize: The size of the font.
     - Returns: A dynamically scaled custom font.
     */

  @objc class func palaceFont(ofSize fontSize: CGFloat) -> UIFont {
    
    // Retrieve the user-selected font size adjustment (if any)
    let fontSizeAdjusted = UserDefaults.standard.bool(forKey: "enablePreferences")
    
    // Retrieve the multiplier to be applied to given font
    var fontMultiplier = UserDefaults.standard.double(forKey: "fontMultiplier")
    if fontMultiplier == 0.0 {
      fontMultiplier = 1.0
    }


    let setFontSize: CGFloat

    if fontSizeAdjusted {
      // Apply user font size adjustment to the given font size
      setFontSize = fontSize * fontMultiplier
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: setFontSize) ?? UIFont.systemFont(ofSize: setFontSize)
      return font
    // Apply system font size adjustment to the given size
    } else {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      return UIFontMetrics.default.scaledFont(for: font)
    }
  }


  @objc class func semiBoldPalaceFont(ofSize fontSize: CGFloat) -> UIFont {
    
    // Retrieve the user-selected font size adjustment (if any)
    let fontSizeAdjusted = UserDefaults.standard.bool(forKey: "enablePreferences")
    
    // Retrieve the multiplier to be applied to given font
    var fontMultiplier = UserDefaults.standard.double(forKey: "fontMultiplier")
    if fontMultiplier == 0.0 {
      fontMultiplier = 1.0
    }


    let setFontSize: CGFloat

    if fontSizeAdjusted {
      // Apply user font size adjustment to the given font size
      setFontSize = fontSize * fontMultiplier
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: setFontSize) ?? UIFont.systemFont(ofSize: setFontSize)
      return font
    // Apply system font size adjustment to the given size
    } else {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      return UIFontMetrics.default.scaledFont(for: font)
    }
  }


  @objc class func boldPalaceFont(ofSize fontSize: CGFloat) -> UIFont {
    
    // Retrieve the user-selected font size adjustment (if any)
    let fontSizeAdjusted = UserDefaults.standard.bool(forKey: "enablePreferences")
    
    // Retrieve the multiplier to be applied to given font
    var fontMultiplier = UserDefaults.standard.double(forKey: "fontMultiplier")
    if fontMultiplier == 0.0 {
      fontMultiplier = 1.0
    }


    let setFontSize: CGFloat

    if fontSizeAdjusted {
      // Apply user font size adjustment to the given font size
      setFontSize = fontSize * fontMultiplier
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: setFontSize) ?? UIFont.systemFont(ofSize: setFontSize)
      return font
    // Apply system font size adjustment to the given size
    } else {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      return UIFontMetrics.default.scaledFont(for: font)
    }
  }
}

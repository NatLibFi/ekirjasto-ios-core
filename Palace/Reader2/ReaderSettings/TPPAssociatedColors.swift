//
//  TPPAssociatedColors.swift
//  Palace
//
//  Created by Vladimir Fedorov on 17.02.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation
import ReadiumShared
import ReadiumNavigator
import UIKit

struct TPPAppearanceColors {
  let backgroundColor: UIColor
  let backgroundMediaOverlayHighlightColor: UIColor
  let textColor: UIColor
  let navigationColor: UIColor
  let foregroundColor: UIColor
  let selectedForegroundColor: UIColor
  let tintColor: UIColor

  /// Black text on white background set of colors
  static var blackOnWhiteColors: TPPAppearanceColors {
    TPPAppearanceColors(
      backgroundColor: TPPConfiguration.readerBackgroundColor(),
      backgroundMediaOverlayHighlightColor: TPPConfiguration.backgroundMediaOverlayHighlightColor(),
      textColor: .black,
      navigationColor: .black,
      foregroundColor: .black,
      selectedForegroundColor: .white,
      tintColor: .darkGray
    )
  }

  /// Black text on sepia background set of colors
  static var blackOnSepiaColors: TPPAppearanceColors {
    TPPAppearanceColors(
      backgroundColor: TPPConfiguration.readerBackgroundSepiaColor(),
      backgroundMediaOverlayHighlightColor: TPPConfiguration.backgroundMediaOverlayHighlightSepiaColor(),
      textColor: .black,
      navigationColor: .black,
      foregroundColor: .black,
      selectedForegroundColor: .white,
      tintColor: .darkGray
    )
  }

  /// White text on black background set of colors
  static var whiteOnBlackColors: TPPAppearanceColors {
    TPPAppearanceColors(
      backgroundColor: TPPConfiguration.readerBackgroundDarkColor(),
      backgroundMediaOverlayHighlightColor: TPPConfiguration.backgroundMediaOverlayHighlightDarkColor(),
      textColor: .white,
      navigationColor: .white,
      foregroundColor: .white,
      selectedForegroundColor: .black,
      tintColor: .white
    )
  }

}

class TPPAssociatedColors {

  static let shared = TPPAssociatedColors()

  /// Current theme, updated when user opens a book or changes settings
  var currentTheme: Theme?

  /// Colors for selected appearance
  var appearanceColors: TPPAppearanceColors {
    return TPPAssociatedColors.colors(forTheme: currentTheme)
  }

  /// Get associated colors for a specific theme.
  static func colors(forTheme theme: Theme? = nil) -> TPPAppearanceColors {
    switch theme {
    case .sepia:
      return .blackOnSepiaColors
    case .dark:
      return .whiteOnBlackColors
    default:
      return .blackOnWhiteColors
    }
  }

}

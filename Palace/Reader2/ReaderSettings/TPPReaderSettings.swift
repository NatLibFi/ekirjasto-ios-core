//
//  TPPReaderSettings.swift
//  Palace
//
//  Created by Vladimir Fedorov on 02.02.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import SwiftUI
import ReadiumShared
import ReadiumNavigator

class TPPReaderSettings: ObservableObject {

  /// Font size as percentage (e.g. 1.0 = 100%)
  @Published var fontSize: Double = 1.0

  /// Minimum font size
  private let minFontSize: Double = 0.75

  /// Maximum font size
  private let maxFontSize: Double = 2.50

  /// Increase/decrease step
  private let fontSizeStep: Double = 0.125

  @Published var fontFamilyIndex: Int = 0

  @Published var appearanceIndex: Int = 0

  @Published var screenBrightness: Double {
    didSet {
      if UIScreen.main.brightness != screenBrightness {
        UIScreen.main.brightness = screenBrightness
      }
    }
  }

  @Published var textColor: UIColor = .black

  @Published var backgroundColor: UIColor = .white

  private(set) var preferences: EPUBPreferences
  private weak var delegate: TPPReaderSettingsDelegate?

  /// Font family options matching the legacy Readium CSS defaults
  static let fontFamilies = ["Original", "Helvetica Neue", "Iowan Old Style", "Athelas", "Seravek", "OpenDyslexic", "AccessibleDfA", "IA Writer Duospace"]

  /// Appearance themes
  static let themes: [Theme?] = [.light, .sepia, .dark]

  init(preferences: EPUBPreferences, delegate: TPPReaderSettingsDelegate) {
    self.preferences = preferences
    self.delegate = delegate

    // Font size
    self.fontSize = preferences.fontSize ?? 1.0

    // Font family. The picker is driven by TPPReaderFont, so the stored index
    // must be in that (4-item) space — not the separate 8-item fontFamilies
    // list, which is what caused the picker to highlight/select the wrong font.
    if let family = preferences.fontFamily?.rawValue,
       let index = TPPReaderFont.allCases.firstIndex(where: { $0.rawValue == family }) {
      self.fontFamilyIndex = index
    }

    // Appearance/theme
    if let theme = preferences.theme,
       let index = TPPReaderSettings.themes.firstIndex(of: theme) {
      self.appearanceIndex = index
    }

    // Colors
    let colors = TPPAssociatedColors.colors(forTheme: preferences.theme)
    self.backgroundColor = colors.backgroundColor
    self.textColor = colors.textColor

    screenBrightness = UIScreen.main.brightness
  }

  /// Convenience init for previews
  init() {
    preferences = .empty
    screenBrightness = UIScreen.main.brightness
  }

  /// Increase font size
  func increaseFontSize() {
    fontSize = min(fontSize + fontSizeStep, maxFontSize)
    preferences.fontSize = fontSize
    delegate?.submitPreferences(preferences)
  }

  /// Decrease font size
  func decreaseFontSize() {
    fontSize = max(fontSize - fontSizeStep, minFontSize)
    preferences.fontSize = fontSize
    delegate?.submitPreferences(preferences)
  }

  /// Indicates whether `fontSize` property can be increased
  var canIncreaseFontSize: Bool {
    fontSize + fontSizeStep <= maxFontSize
  }

  /// Indicates whether `fontSize` property can be decreased
  var canDecreaseFontSize: Bool {
    fontSize - fontSizeStep >= minFontSize
  }

  /// Changes selected appearance/theme
  func changeAppearance(appearanceIndex: Int) {
    self.appearanceIndex = appearanceIndex
    let theme = TPPReaderSettings.themes[appearanceIndex]
    preferences.theme = theme
    delegate?.submitPreferences(preferences)
    delegate?.setUIColor(for: theme)
    let colors = TPPAssociatedColors.colors(forTheme: theme)
    backgroundColor = colors.backgroundColor
    textColor = colors.textColor
  }

  /// Changes selected font family
  func changeFontFamily(fontFamilyIndex: Int) {
    self.fontFamilyIndex = fontFamilyIndex
    guard TPPReaderFont.allCases.indices.contains(fontFamilyIndex) else {
      return
    }
    let readerFont = TPPReaderFont.allCases[fontFamilyIndex]
    if readerFont == .original {
      preferences.fontFamily = nil
      preferences.publisherStyles = true
    } else {
      // Use the selected picker item's own font name. This previously indexed a
      // separate 8-item list, so selecting "OpenDyslexic" (index 3) resolved to
      // "Athelas" — the wrong font.
      preferences.fontFamily = FontFamily(rawValue: readerFont.rawValue)
      preferences.publisherStyles = false
    }
    delegate?.submitPreferences(preferences)
  }
}

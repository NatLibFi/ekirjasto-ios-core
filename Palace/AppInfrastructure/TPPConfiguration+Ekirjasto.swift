//
//  TPPConfiguration+Ekirjasto.swift
//  Ekirjasto
//
//  Created by Nianzu on 1.6.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

extension TPPConfiguration {
  
  static let registryHashKey = "registryHashKey"
  
  //static let betaUrl = URL(string: "https://registry.palaceproject.io/libraries/qa")!
  //static let prodUrl = URL(string: "https://registry.palaceproject.io/libraries")!
  
  #if CONF_ELLIBS
  private static let feedFileUrlBase = "Ekirjasto_Catalog_Feed_ellibs"
  #elseif CONF_DEV
  private static let feedFileUrlBase = "Ekirjasto_Catalog_Feed_dev"
  #elseif CONF_BETA
  private static let feedFileUrlBase = "Ekirjasto_Catalog_Feed_beta"
  #else
  private static let feedFileUrlBase = "Ekirjasto_Catalog_Feed_production"
  #endif
  
  private static let feedFileUrl = URL(fileURLWithPath:
    Bundle.main.path(forResource: feedFileUrlBase,
                     ofType: "json")!)
  
  private static let testFeedFileUrl = URL(fileURLWithPath:
    Bundle.main.path(forResource: "TestLogin_Catalog_Feed",
                     ofType: "json")!)
  
  private static let feedFileUrlHash = feedFileUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  private static let testFeedFileUrlHash = testFeedFileUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  static var prodUrl = feedFileUrl
  static var testUrl = testFeedFileUrl
  
  
  //static let betaUrlHash = betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  //static let prodUrlHash = prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  static let prodUrlHash = feedFileUrlHash
  static let testUrlHash = testFeedFileUrlHash
  
  static func customUrl() -> URL? {
    guard let server = TPPSettings.shared.customLibraryRegistryServer else { return nil }
    return URL(string: "https://\(server)/libraries/qa")
  }
  
  
  /// Checks if registry changed
  @objc
  static var registryChanged: Bool {
    (UserDefaults.standard.string(forKey: registryHashKey) ?? "") != (useTestEnv ? testUrlHash : prodUrlHash)
  }
  
  @objc
  static var useTestEnv: Bool {
    get {
      return UserDefaults.standard.bool(forKey: "useTestKey")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "useTestKey")
    }
  }
  
  /// Updates registry key
  @objc
  static func updateSavedeRegistryKey() {
    UserDefaults.standard.set(useTestEnv ? testUrlHash : prodUrlHash, forKey: registryHashKey)
  }
  
  
  
  static func customUrlHash() -> String? {
    customUrl()?.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  }
  
  @objc static func mainColor() -> UIColor {
    UIColor.defaultLabelColor()
  }
  
  @objc static func palaceRed() -> UIColor {
    if #available(iOS 13, *) {
      if let color = UIColor(named: "PalaceRed") {
        return color
      }
    }
    
    return UIColor(red: 248.0/255.0, green: 56.0/255.0, blue: 42.0/255.0, alpha: 1.0)
  }

  @objc static func iconLogoBlueColor() -> UIColor {
    if #available(iOS 13, *) {
      if let color = UIColor(named: "ColorIconLogoBlue") {
        return color
      }
    }

    return UIColor(red: 17.0/255.0, green: 50.0/255.0, blue: 84.0/255.0, alpha: 1.0)
  }

  @objc static func iconLogoGreenColor() -> UIColor {
    UIColor(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0)
  }

  static func cardCreationEnabled() -> Bool {
    return true
  }
  
  @objc static func iconColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoBlack")!
    } else {
      return .black
    }
  }
  
  @objc static func inactiveIconColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoLightestGreen")!
    } else {
      return .lightGray
    }
  }
  
  @objc static func compatiblePrimaryColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoLabel")!
    } else {
      return .black
    }
  }
  
  @objc static func compatibleTextColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorInverseLabel")!
    } else {
      return .white;
    }
  }
  
  @objc static func ekirjastoFontName() -> String {
    return "Asap-Regular"
  }

  @objc static func ekirjastoFontNameBold() -> String {
    return "Asap-Bold"
  }
  
  @objc static func ekirjastoYellow() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoYellow")!
    } else {
      return .lightGray
    }
  }
  
  @objc static func ekirjastoBlack() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoAlwaysBlack")!
    } else {
      return .lightGray
    }
  }

  @objc static func ekirjastoLightGrey() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoLightGrey")!
    } else {
      return .lightGray
    }
  }
  
  @objc static func normalTabBarItemTitleColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoGrey")!
    } else {
      return .lightGray
    }
  }
  
  @objc static func selectedTabBarItemTitleColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoLabel")!
    } else {
      return .lightGray
    }
  }
  
  @objc static func catalogSegmentedControlBackgroundColorNormal() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoFilterButtonBackgroundNormal")!
    } else {
      return .lightGray
    }
  }
  
}

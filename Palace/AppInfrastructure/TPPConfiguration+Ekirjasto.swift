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
  
  static let betaUrl = URL(string: "https://registry.palaceproject.io/libraries/qa")!
  //static let prodUrl = URL(string: "https://registry.palaceproject.io/libraries")!
  
  
  private static let feedFileUrl = URL(fileURLWithPath:
    Bundle.main.path(forResource: "Ellibs_Catalog_Feed",
                     ofType: "json")!)
  private static let feedFileUrlHash = feedFileUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  static var prodUrl = feedFileUrl

  static let betaUrlHash = betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  //static let prodUrlHash = prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  static let prodUrlHash = feedFileUrlHash
  
  static func customUrl() -> URL? {
    guard let server = TPPSettings.shared.customLibraryRegistryServer else { return nil }
    return URL(string: "https://\(server)/libraries/qa")
  }
  
  
  /// Checks if registry changed
  @objc
  static var registryChanged: Bool {
    (UserDefaults.standard.string(forKey: registryHashKey) ?? "") != prodUrlHash
  }
  
  /// Updates registry key
  @objc
  static func updateSavedeRegistryKey() {
    UserDefaults.standard.set(prodUrlHash, forKey: registryHashKey)
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
      return UIColor(named: "ColorEkirjastoIcon")!
    } else {
      return .black
    }
  }
  
  @objc static func inactiveIconColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor(named: "ColorEkirjastoLighterGreen")!
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
}

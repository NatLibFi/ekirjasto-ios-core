import Foundation
import UIKit
import Darwin

@objc protocol NYPLUniversalLinksSettings: NSObjectProtocol {
  /// The URL that will be used to redirect an external authentication flow
  /// back to the our app. This URL will need to be provided to the external
  /// service. For example, Clever authentication uses this URL to redirect
  /// to the app after authenticating in Safari.
  var universalLinksURL: URL { get }
}

@objc protocol NYPLFeedURLProvider {
  var accountMainFeedURL: URL? { get set }
}

/**
 Returns a string with the device model
 - Returns: String with the device model
 */
func deviceModel() -> String {
  // Declare length that will store the length of the CChar that stores the device model
  // and "hw.machine" is "the ASCII name of the requested attribute", which is the device model.
  // You can read more about sysctlbyname here: https://developer.apple.com/documentation/kernel/1387446-sysctlbyname
  var length = 0
  let name = "hw.machine"

  // If hw.machine is not set then return early here to prevent a fatal error
  // This sets the length to match the device model code that will be returned
  // so for "iPhone1,1" it will be 10 (because of the null terminating character)
  if sysctlbyname(name, nil, &length, nil, 0) == -1 {
    return name + " is not set"
  }

  // sysctlbyname writes the model name into modelChars and modelName casts it
  // to an immutable String so we don't accidentally overwrite it or something
  var modelChars = [CChar](repeating: 0, count: length)
  sysctlbyname(name, &modelChars, &length, nil, 0)
  let modelName = String(cString: modelChars)

  // If you find an obfuscated name like iPhoneN,N you can add a full name here.
  // You can check the consumer facing name by replacing the iphone12,1 part of
  // the following URL with the codename:
  // https://regulatoryinfo.apple.com/rfexposure/iphone12,1
  // There is a possibly complete list that might be under the MIT license here:
  // https://github.com/InderKumarRathore/DeviceGuru/blob/master/Sources/DeviceList.plist
  let names = [
    "arm64": "simulator (arm64)",
    "iPhone1,1": "iPhone 2G",
    "iPhone1,2": "iPhone 3G",
    "iPhone3,1": "iPhone 4",
    "iPhone3,2": "iPhone 4",
    "iPhone3,3": "iPhone 4",
    "iPhone4,1": "iPhone 4s",
    "iPhone5,1": "iPhone 5",
    "iPhone5,2": "iPhone 5",
    "iPhone5,4": "iPhone 5c",
    "iPhone6,1": "iPhone 5s",
    "iPhone6,2": "iPhone 5s",
    "iPhone7,1": "iPhone 6 Plus",
    "iPhone7,2": "iPhone 6",
    "iPhone8,1": "iPhone 6s",
    "iPhone8,2": "iPhone 6s Plus",
    "iPhone8,4": "iPhone SE",
    "iPhone9,1": "iPhone 7",
    "iPhone9,2": "iPhone 7 Plus",
    "iPhone10,1": "iPhone 8",
    "iPhone10,2": "iPhone 8 Plus",
    "iPhone10,4": "iPhone 8",
    "iPhone10,5": "iPhone 8 Plus",
    "iPhone10,3": "iPhone X",
    "iPhone10,6": "iPhone X",
    "iPhone11,2": "iPhone XS",
    "iPhone12,1": "iPhone 11",
    "iPhone12,3": "iPhone 11 Pro",
    "iPhone12,5": "iPhone 11 Pro Max",
    "iPhone12,8": "iPhone SE (2nd gen)",
    "iPhone13,1": "iPhone 12 mini",
    "iPhone13,2": "iPhone 12",
    "iPhone13,3": "iPhone 12 Pro",
    "iPhone13,4": "iPhone 12 Pro Max",
    "iPhone14,2": "iPhone 13 Pro",
    "iPhone14,3": "iPhone 13 Pro Max",
    "iPhone14,4": "iPhone 13 mini",
    "iPhone14,5": "iPhone 13",
    "iPhone14,6": "iPhone SE (3rd gen)",
    "iPhone14,7": "iPhone 14",
    "iPhone14,8": "iPhone 14 Plus",
    "iPhone15,2": "iPhone 14 Pro",
    "iPhone15,3": "iPhone 14 Pro Max",
    "iPhone15,4": "iPhone 15",
    "iPhone15,5": "iPhone 15 Plus",
    "iPhone16,1": "iPhone 15 Pro",
    "iPhone16,2": "iPhone 15 Pro Max",
  ]

  // Map the modelName, such as "iPhone1,1" to the consumer-friendly name like "iPhone 2G"
  if let name = names[modelName] {
    return name
  }

  // If the modelName isn't found in the names list then we just return the
  // obfuscated name which will look something like "iPhone12,1"
  return String(cString: modelChars)
}

/**
 Returns the software version name
 - Returns: A String that describes the software version name, i.e. "1.0.29" or an error message if not found
 */
func versionName() -> String {
  if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
    return version
  }

  // If CFBundleShortVersionString isn't set on some new device then this
  // should make it pretty obvious that there is something quite wrong
  return "ERROR: Could not get iOS app software version name"
}

/**
 Returns the software version code
 - Returns: A String that describes the software version code, i.e. "161" or an error message if it could not be found
 */
func versionCode() -> String {
  if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
    return version
  }

  // If CFBundleVersion isn't set on some new device then this
  // should make it pretty obvious that there is something very wrong
  return "ERROR: Could not get iOS app software version code"
}

/**
 Constructs the feedback url out of components and adds the necessary query params,
 because e.g. a formatted string might result in "...?device_model=iPhone 5",
 which breaks because it contains a regular space rather than "%20"

 The base of the URL (without parameters) can also be found in the file
 Palace/EkirjastoConfig/Ekirjasto_Catalog_Feed.json
 Reading it from there instead of hard coding it here might be a good idea,
 but no obvious method for doing so was found.
 - Returns: feedback URL with parameters as a String
 */
func feedbackURL(appLanguage: String!) -> String {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "lib.e-kirjasto.fi"
  components.path = "/palaute"

  // Set the query parameters here because we want them in the final URL
  components.queryItems = [
    URLQueryItem(name: "lang", value: appLanguage),
    URLQueryItem(name: "version_name", value: versionName()),
    URLQueryItem(name: "version_code", value: versionCode()),
    URLQueryItem(name: "device_manufacturer", value: "Apple"),
    URLQueryItem(name: "device_model", value: deviceModel()),
  ]

  // Return the created url as a string or default to a parameterless link (because I can't think of a better default value here)
  if let url = components.url {
    return url.absoluteString
  }
  return "https://lib.ekirjasto.fi/palaute"
}

@objcMembers class TPPSettings: NSObject, NYPLFeedURLProvider, TPPAgeCheckChoiceStorage {
  static let shared = TPPSettings()

  @objc class func sharedSettings() -> TPPSettings {
    return TPPSettings.shared
  }
  
  // The language the user has chosen for the application (not device language)
  //    - returns the short alphabetical language code as a string
  //    - current possible E-kirjasto app language codes: fi, sv, en
  static let appLanguage = Locale.current.languageCode
  
  // The URL origin shared with remote NatLibFi HTML pages accessed through application
  //    - the application language code is part of the URL string ('fi' is set as default)
  //    - with the application language code the user is directed to the corresponding language version of the web page
  //    - example URL origin: 'https://www.kansalliskirjasto.fi/sv/e-kirjasto'
  static let ekirjastoURLOrigin = "https://www.kansalliskirjasto.fi/\(appLanguage ?? "fi")/e-kirjasto"

  static let TPPAboutPalaceURLString = "http://thepalaceproject.org/"
  static let TPPUserAgreementURLString = "\(ekirjastoURLOrigin)/e-kirjaston-kayttoehdot"
  static let TPPPrivacyPolicyURLString = "\(ekirjastoURLOrigin)/e-kirjaston-tietosuoja-ja-rekisteriseloste"
  static let TPPFeedbackURLString = feedbackURL(appLanguage: appLanguage)
  static let TPPAccessibilityURLString = "\(ekirjastoURLOrigin)/e-kirjaston-saavutettavuusseloste"
  static let TPPFAQURLString = "\(ekirjastoURLOrigin)/e-kirjaston-usein-kysytyt-kysymykset"

  static private let customMainFeedURLKey = "NYPLSettingsCustomMainFeedURL"
  static private let accountMainFeedURLKey = "NYPLSettingsAccountMainFeedURL"
  static private let userPresentedAgeCheckKey = "NYPLUserPresentedAgeCheckKey"
  static let userHasAcceptedEULAKey = "NYPLSettingsUserAcceptedEULA"
  static private let userSeenFirstTimeSyncMessageKey = "userSeenFirstTimeSyncMessageKey"
  static private let useBetaLibrariesKey = "NYPLUseBetaLibrariesKey"
  static let settingsLibraryAccountsKey = "NYPLSettingsLibraryAccountsKey"
  static private let versionKey = "NYPLSettingsVersionKey"
  static private let customLibraryRegistryKey = "TPPSettingsCustomLibraryRegistryKey"
  static private let enterLCPPassphraseManually = "TPPSettingsEnterLCPPassphraseManually"
  static let showDeveloperSettingsKey = "showDeveloperSettings"
  
  // When the test login flow is active, the welcome screen whould not be opened on top of it
  var testLoginFlowActive = false
  
  // Set to nil (the default) if no custom feed should be used.
  var customMainFeedURL: URL? {
    get {
      return UserDefaults.standard.url(forKey: TPPSettings.customMainFeedURLKey)
    }
    set(customUrl) {
      if (customUrl == self.customMainFeedURL) {
        return
      }
      UserDefaults.standard.set(customUrl, forKey: TPPSettings.customMainFeedURLKey)
      NotificationCenter.default.post(name: Notification.Name.TPPSettingsDidChange, object: self)
    }
  }
  
  var accountMainFeedURL: URL? {
    get {
      return UserDefaults.standard.url(forKey: TPPSettings.accountMainFeedURLKey)
    }
    set(mainFeedUrl) {
      if (mainFeedUrl == self.accountMainFeedURL) {
        return
      }
      UserDefaults.standard.set(mainFeedUrl, forKey: TPPSettings.accountMainFeedURLKey)
      NotificationCenter.default.post(name: Notification.Name.TPPSettingsDidChange, object: self)
    }
  }

  /// Whether the user has seen the welcome screen or completed tutorial
  var userHasSeenWelcomeScreen: Bool {
    get {
      UserDefaults.standard.bool(forKey: TPPSettings.userHasSeenWelcomeScreenKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: TPPSettings.userHasSeenWelcomeScreenKey)
    }
  }
  
  var userPresentedAgeCheck: Bool {
    get {
      UserDefaults.standard.bool(forKey: TPPSettings.userPresentedAgeCheckKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: TPPSettings.userPresentedAgeCheckKey)
    }
  }
  
  var userHasAcceptedEULA: Bool {
    get {
      UserDefaults.standard.bool(forKey: TPPSettings.userHasAcceptedEULAKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: TPPSettings.userHasAcceptedEULAKey)
    }
  }

  var userHasSeenFirstTimeSyncMessage: Bool {
    get {
      UserDefaults.standard.bool(forKey: TPPSettings.userSeenFirstTimeSyncMessageKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: TPPSettings.userSeenFirstTimeSyncMessageKey)
    }
  }
  
  var useBetaLibraries: Bool {
    get {
      UserDefaults.standard.bool(forKey: TPPSettings.useBetaLibrariesKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: TPPSettings.useBetaLibrariesKey)
      NotificationCenter.default.post(name: NSNotification.Name.TPPUseBetaDidChange,
                                      object: self)
    }
  }

  var appVersion: String? {
    get {
      UserDefaults.standard.string(forKey: TPPSettings.versionKey)
    }
    set(versionString) {
      UserDefaults.standard.set(versionString, forKey: TPPSettings.versionKey)
    }
  }
  
  var customLibraryRegistryServer: String? {
    get {
      UserDefaults.standard.string(forKey: TPPSettings.customLibraryRegistryKey)
    }
    set(customServer) {
      UserDefaults.standard.set(customServer, forKey: TPPSettings.customLibraryRegistryKey)
    }
  }

  var enterLCPPassphraseManually: Bool {
    get {
      UserDefaults.standard.bool(forKey: TPPSettings.enterLCPPassphraseManually)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: TPPSettings.enterLCPPassphraseManually)
    }
  }
  
}

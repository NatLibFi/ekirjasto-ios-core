import Foundation

private enum StorageKey: String {
  // .barcode, .PIN, .authToken became legacy, as storage for those types was moved into .credentials enum

  case authorizationIdentifier = "TPPAccountAuthorization"
  case barcode = "TPPAccountBarcode" // legacy
  case PIN = "TPPAccountPIN" // legacy
  case adobeToken = "TPPAccountAdobeTokenKey"
  case licensor = "TPPAccountLicensorKey"
  case patron = "TPPAccountPatronKey"
  case authToken = "TPPAccountAuthTokenKey" // legacy
  case adobeVendor = "TPPAccountAdobeVendorKey"
  case provider = "TPPAccountProviderKey"
  case userID = "TPPAccountUserIDKey"
  case deviceID = "TPPAccountDeviceIDKey"
  case credentials = "TPPAccountCredentialsKey"
  case authDefinition = "TPPAccountAuthDefinitionKey"
  case cookies = "TPPAccountAuthCookiesKey"
  case patronPermanentId = "TPPPatronPermanentId"

  func keyForLibrary(uuid libraryUUID: String?) -> String {
    guard
      // historically user data for NYPL has not used keys that contain the
      // library UUID.
      let libraryUUID = libraryUUID,
      libraryUUID != AccountsManager.shared.tppAccountUUID else {
        return self.rawValue
    }

    return "\(self.rawValue)_\(libraryUUID)"
  }
}

@objc protocol TPPUserAccountProvider: NSObjectProtocol {
  var needsAuth:Bool { get }
  
  static func sharedAccount(libraryUUID: String?) -> TPPUserAccount
}

class TPPUserAccountAuthentication: ObservableObject {
  static public let shared = TPPUserAccountAuthentication()
  
  @Published public var isAuthenticated = TPPUserAccount.sharedAccount().authToken != nil
  
}

@objcMembers class TPPUserAccount : NSObject, TPPUserAccountProvider {
  static private let shared = TPPUserAccount()
  private let accountInfoLock = NSRecursiveLock()
  private lazy var keychainTransaction = TPPKeychainVariableTransaction(accountInfoLock: accountInfoLock)
  private var notifyAccountChange: Bool = true

  private var libraryUUID: String? {
    didSet {
      guard libraryUUID != oldValue else { return }
      let variables: [StorageKey: Keyable] = [
        StorageKey.authorizationIdentifier: _authorizationIdentifier,
        StorageKey.adobeToken: _adobeToken,
        StorageKey.licensor: _licensor,
        StorageKey.patron: _patron,
        StorageKey.adobeVendor: _adobeVendor,
        StorageKey.provider: _provider,
        StorageKey.userID: _userID,
        StorageKey.deviceID: _deviceID,
        StorageKey.credentials: _credentials,
        StorageKey.authDefinition: _authDefinition,
        StorageKey.cookies: _cookies,
        StorageKey.patronPermanentId: _patronPermanentId,

        // legacy
        StorageKey.barcode: _barcode,
        StorageKey.PIN: _pin,
        StorageKey.authToken: _authToken,
      ]

      for (key, var value) in variables {
        value.key = key.keyForLibrary(uuid: libraryUUID)
      }
    }
  }

  var authDefinition: AccountDetails.Authentication? {
    get {
      guard let read = _authDefinition.read() else {
        if let libraryUUID = self.libraryUUID {
          return AccountsManager.shared.account(libraryUUID)?.details?.auths.first
        }
            
        return AccountsManager.shared.currentAccount?.details?.auths.first
      }
      return read
    }
    set {
      guard let newValue = newValue else { return }
      _authDefinition.write(newValue)

      DispatchQueue.main.async {
        var mainFeed = URL(string: AccountsManager.shared.currentAccount?.catalogUrl ?? "")
        let resolveFn = {
          TPPSettings.shared.accountMainFeedURL = mainFeed
          UIApplication.shared.delegate?.window??.tintColor = TPPConfiguration.mainColor()

          if self.notifyAccountChange {
            NotificationCenter.default.post(name: NSNotification.Name.TPPCurrentAccountDidChange, object: nil)
          }

          self.notifyAccountChange = true

        }

        if self.needsAgeCheck {
          AccountsManager.shared.ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: self,
                                                                             currentLibraryAccountProvider: AccountsManager.shared) { [weak self] meetsAgeRequirement in
            DispatchQueue.main.async {
              mainFeed = self?.authDefinition?.coppaURL(isOfAge: meetsAgeRequirement)
              resolveFn()
            }
          }
        } else {
          resolveFn()
        }
      }

      notifyAccountDidChange()
    }
  }

  var credentials: TPPCredentials? {
    get {
      var credentials = _credentials.read()

      if credentials == nil {
        // if there are no credentials in memory, try to migrate from legacy storage keys
        if let barcode = legacyBarcode, let pin = legacyPin {
          // barcode and pin was used previously
          credentials = .barcodeAndPin(barcode: barcode, pin: pin)

          // remove legacy storage and save into new place
          keychainTransaction.perform {
            _credentials.write(credentials)
            _barcode.write(nil)
            _pin.write(nil)
          }
        } else if let authToken = legacyAuthToken {
          // auth token was used previously
          credentials = .token(authToken: authToken, barcode: legacyBarcode, pin: legacyPin)

          // remove legacy storage and save into new place
          keychainTransaction.perform {
            _credentials.write(credentials)
            _authToken.write(nil)
          }
        
        }
      }

      return credentials
    }
    set {
      guard let newValue = newValue else {
        
        if Thread.isMainThread {
          TPPUserAccountAuthentication.shared.isAuthenticated = false
        }else {
          DispatchQueue.main.async {
            TPPUserAccountAuthentication.shared.isAuthenticated = false
          }
        }
        
        return
      }

      _credentials.write(newValue)

      // make sure to set the barcode related to the current account (aka library)
      // not the one we just signed in to, because we could have signed in into
      // library A, but still browsing the catalog of library B.
      if case let .barcodeAndPin(barcode: userBarcode, pin: _) = newValue {
        TPPErrorLogger.setUserID(userBarcode)
      }

      notifyAccountDidChange()
      if Thread.isMainThread {
        TPPUserAccountAuthentication.shared.isAuthenticated = true
      }else {
        DispatchQueue.main.async {
          TPPUserAccountAuthentication.shared.isAuthenticated = true
        }
      }
      
    }
  }

  @objc class func sharedAccount() -> TPPUserAccount {
    // Note: it's important to use `currentAccountId` instead of
    // `currentAccount.uuid` because the former is immediately available
    // (being saved into the UserDefaults) while the latter is only available
    // after the app startup sequence is complete (i.e. authentication
    // document has been loaded.
    return sharedAccount(libraryUUID: AccountsManager.shared.currentAccountId)
  }
    
  class func sharedAccount(libraryUUID: String?) -> TPPUserAccount {
    shared.accountInfoLock.lock()
    defer {
      shared.accountInfoLock.unlock()
    }

    shared.libraryUUID = libraryUUID

    return shared
  }

  func setAuthDefinitionWithoutUpdate(authDefinition: AccountDetails.Authentication?) {
    notifyAccountChange = false
    self.authDefinition = authDefinition
  }

  private func notifyAccountDidChange() {
    NotificationCenter.default.post(
      name: Notification.Name.TPPUserAccountDidChange,
      object: self
    )
  }

  // MARK: - Storage
  private lazy var _authorizationIdentifier: TPPKeychainVariable<String> = StorageKey.authorizationIdentifier
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _adobeToken: TPPKeychainVariable<String> = StorageKey.adobeToken
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _licensor: TPPKeychainVariable<[String:Any]> = StorageKey.licensor
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _patron: TPPKeychainVariable<[String:Any]> = StorageKey.patron
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _adobeVendor: TPPKeychainVariable<String> = StorageKey.adobeVendor
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _provider: TPPKeychainVariable<String> = StorageKey.provider
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _userID: TPPKeychainVariable<String> = StorageKey.userID
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _deviceID: TPPKeychainVariable<String> = StorageKey.deviceID
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _credentials: TPPKeychainCodableVariable<TPPCredentials> = StorageKey.credentials
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainCodableVariable(with: accountInfoLock)
  private lazy var _authDefinition: TPPKeychainCodableVariable<AccountDetails.Authentication> = StorageKey.authDefinition
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainCodableVariable(with: accountInfoLock)
  private lazy var _cookies: TPPKeychainVariable<[HTTPCookie]> = StorageKey.cookies
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _patronPermanentId: TPPKeychainVariable<String> = StorageKey.patronPermanentId
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)

  // Legacy
  private lazy var _barcode: TPPKeychainVariable<String> = StorageKey.barcode
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _pin: TPPKeychainVariable<String> = StorageKey.PIN
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _authToken: TPPKeychainVariable<String> = StorageKey.authToken
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)

  // MARK: - Check
    
  func hasBarcodeAndPIN() -> Bool {
    if let credentials = credentials, case TPPCredentials.barcodeAndPin = credentials {
      return true
    }
    return false
  }
  
  func hasAuthToken() -> Bool {
    if let credentials = credentials, case TPPCredentials.token = credentials {
      return true
    }
    return false
  }
  
  func hasAdobeToken() -> Bool {
    return adobeToken != nil
  }
  
  func hasLicensor() -> Bool {
    return licensor != nil
  }
  
  func hasCredentials() -> Bool {
    return hasAuthToken() || hasBarcodeAndPIN()
  }

  // Oauth requires login to load catalog
  var catalogRequiresAuthentication: Bool {
    return authDefinition?.catalogRequiresAuthentication ?? false
  }

  // MARK: - Legacy
  
  private var legacyBarcode: String? { return _barcode.read() }
  private var legacyPin: String? { return _pin.read() }
  var legacyAuthToken: String? { _authToken.read() }

  // MARK: - GET

  /// The barcode of this user; for NYPL, this is either an actual barcode
  /// or a username.
  /// You should be able to use either one as authentication with the
  /// circulation manager and platform.nypl.org, because they both pass auth
  /// information to the ILS, which is the source of truth. The ILS will
  /// validate credentials the same whether the patron identifier is a
  /// username or one of their barcodes. However, it's possible that some
  /// features of platform.nypl.org will work if you give them a 14-digit
  /// barcode but not a 7-letter username or a 16-digit NYC ID.
  var barcode: String? {
    guard let credentials = credentials else { return nil }

    switch credentials {
    case let TPPCredentials.barcodeAndPin(barcode: barcode, pin: _):
      return barcode
    case let TPPCredentials.token(_, barcode, _, _):
      return barcode
    default:
      return nil
    }
  }

  /// For any library but the NYPL, this identifier can be anything they want.
  ///
  /// For NYPL, this is *a* barcode, either a 14-digit NYPL-issued barcode, or
  /// a 16-digit "NYC ID" barcode issued by New York City. It's in fact
  /// possible for NYC residents to get a NYC ID and set that up **as a**
  /// NYPL barcode, even if they already have a NYPL card. We use
  /// authorization_identifier to mean the "number that's probably on the
  ///  piece of plastic the patron uses as their library card".
  /// - Note: A patron can have multiple barcodes, because patrons may lose
  /// their library card and get a new one with a different barcode.
  /// Authenticating with any of those barcodes should work.
  /// - Note: This is NOT the unique ILS ID. That's internal-only and it's not
  /// exposed to the public.
  var authorizationIdentifier: String? { _authorizationIdentifier.read() }

  var PIN: String? {
    guard let credentials = credentials else { return nil }
    
    switch credentials {
    case let TPPCredentials.barcodeAndPin(barcode: _, pin: pin):
      return pin
    case let TPPCredentials.token(_, _, pin, _):
      return pin
    default:
      return nil
    }
  }

  var needsAuth:Bool {
    let authType = authDefinition?.authType ?? .none
    return authType == .basic || authType == .oauthIntermediary || authType == .saml || authType == .token
  }

  var needsAgeCheck:Bool {
    return authDefinition?.authType == .coppa
  }

  var deviceID: String? { _deviceID.read() }
  /// The user ID to use with Adobe DRM.
  var userID: String? { _userID.read() }
  var adobeVendor: String? { _adobeVendor.read() }
  var provider: String? { _provider.read() }
  var patron: [String:Any]? { _patron.read() }
  var adobeToken: String? { _adobeToken.read() }
  var licensor: [String:Any]? { _licensor.read() }
  var cookies: [HTTPCookie]? { _cookies.read() }

  var authToken: String? {
    if let credentials = credentials, case let TPPCredentials.token(authToken: token) = credentials {
      return token.authToken
    }
    return nil
  }
  
  var authTokenHasExpired: Bool {
    
    if let credentials = credentials {
      if case let TPPCredentials.token(authToken: token) = credentials {
        if let expirationDate = token.expirationDate {
          return expirationDate > Date()
        }else{//no expiration date, will ask user to re-login when token is no longer accepted
          return false
        }
      }
    }
    return false
    
  }
  
  var authTokenExpirationDate: Date?{
    if let credentials = credentials {
      if case let TPPCredentials.token(authToken: token) = credentials {
        return token.expirationDate
      }
    }
    return nil
  }
  
  var patronPermantId: String? { _patronPermanentId.read() }

  
  var patronFullName: String? {
    if let patron = patron,
      let name = patron["name"] as? [String:String]
    {
      var fullname = ""
      
      if let first = name["first"] {
        fullname.append(first)
      }
      
      if let middle = name["middle"] {
        if fullname.count > 0 {
          fullname.append(" ")
        }
        fullname.append(middle)
      }
      
      if let last = name["last"] {
        if fullname.count > 0 {
          fullname.append(" ")
        }
        fullname.append(last)
      }
      
      return fullname.count > 0 ? fullname : nil
    }
    
    return nil
  }



  // MARK: - SET
  @objc(setBarcode:PIN:)
  func setBarcode(_ barcode: String, PIN: String) {
    credentials = .barcodeAndPin(barcode: barcode, pin: PIN)
  }
    
  @objc(setAdobeToken:patron:)
  func setAdobeToken(_ token: String, patron: [String : Any]) {
    keychainTransaction.perform {
      _adobeToken.write(token)
      _patron.write(patron)
    }

    notifyAccountDidChange()
  }
  
  @objc(setAdobeVendor:)
  func setAdobeVendor(_ vendor: String) {
    _adobeVendor.write(vendor)
    notifyAccountDidChange()
  }
  
  @objc(setAdobeToken:)
  func setAdobeToken(_ token: String) {
    _adobeToken.write(token)
    notifyAccountDidChange()
  }
  
  @objc(setLicensor:)
  func setLicensor(_ licensor: [String : Any]) {
    _licensor.write(licensor)
  }

  /// This authorization identifier is returned by the circulation manager
  /// upon successful sign-in.
  /// - parameter identifier: For NYPL, this can either be
  /// a 14-digit NYPL-issued barcode, or a 16-digit "NYC ID"
  /// barcode issued by New York City. For other libraries,
  /// this can be any string they want.
  @objc(setAuthorizationIdentifier:)
  func setAuthorizationIdentifier(_ identifier: String) {
    _authorizationIdentifier.write(identifier)
  }
  
  @objc(setPatron:)
  func setPatron(_ patron: [String : Any]) {
    _patron.write(patron)
    notifyAccountDidChange()
  }
  
  @objc(setAuthToken::::)
  func setAuthToken(_ token: String, barcode: String?, pin: String?, expirationDate: Date?) {
    credentials = .token(authToken: token, barcode: barcode, pin: pin, expirationDate: expirationDate)
  }


  @objc(setCookies:)
  func setCookies(_ cookies: [HTTPCookie]) {
    _cookies.write(cookies)
    notifyAccountDidChange()
  }

  @objc(setProvider:)
  func setProvider(_ provider: String) {
    _provider.write(provider)
    notifyAccountDidChange()
  }

  /// - parameter id: The user ID to use for Adobe DRM.
  @objc(setUserID:)
  func setUserID(_ id: String) {
    _userID.write(id)
    notifyAccountDidChange()
  }
  
  @objc(setDeviceID:)
  func setDeviceID(_ id: String) {
    _deviceID.write(id)
    notifyAccountDidChange()
  }
  
  @objc(setPatronPermanentId:)
  func setPatronPermanentId(_ identifier: String) {
    _patronPermanentId.write(identifier)
    print("TPPUserAccount patronPermanentId has been set")
  }
    
  // MARK: - Remove

  func removeAll() {
    keychainTransaction.perform {
      _adobeToken.write(nil)
      _patron.write(nil)
      _adobeVendor.write(nil)
      _provider.write(nil)
      _userID.write(nil)
      _deviceID.write(nil)

      keychainTransaction.perform {
        _authDefinition.write(nil)
        _credentials.write(nil)
        _cookies.write(nil)
        _authorizationIdentifier.write(nil)

        // remove legacy, just in case
        _barcode.write(nil)
        _pin.write(nil)
        _authToken.write(nil)
        _patronPermanentId.write(nil)

        notifyAccountDidChange()
        
        if Thread.isMainThread {
          TPPUserAccountAuthentication.shared.isAuthenticated = false
        }else {
          DispatchQueue.main.async {
            TPPUserAccountAuthentication.shared.isAuthenticated = false
          }
        }

        NotificationCenter.default.post(name: Notification.Name.TPPDidSignOut,
                                        object: nil)
      }
    }
  }
}

extension TPPUserAccount: TPPSignedInStateProvider {
  func isSignedIn() -> Bool {
    return hasCredentials()
  }
}

extension TPPUserAccount: NYPLBasicAuthCredentialsProvider {
  var username: String? {
    return barcode
  }
  
  var pin: String? {
    return PIN
  }
}

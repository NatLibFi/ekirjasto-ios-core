//
//  PasskeyLogin.swift
//  Palace
//
//  Created by Joni Salmela on 22.1.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation
import AuthenticationServices
import SwiftUI



class PasskeyManager : NSObject, ASAuthorizationControllerPresentationContextProviding {

  struct TokenResponse: Codable {
    let token: String
    let exp: Int?
  }

  struct RegisterStartResponse: Codable {
    struct User : Codable {
      let id : String
      //var name : String
      //var displayName : String
    }
    struct PublicKey : Codable {
      let challenge : String
      let user : User
    }
    
    let publicKey : PublicKey
    
  }
  
  struct LoginStartResponse: Codable {

    struct AllowCredential: Codable {
      let type: String
      let id: String
      let transports: [String]
    }

    struct PublicKey: Codable {
      let challenge: String
      let timeout: Int
      let rpId: String
      let allowCredentials: [AllowCredential]
      let userVerification: String
    }

    let publicKey: PublicKey
  }


  struct LoginCompleteData: Codable {
    struct Response: Codable {
      let clientDataJSON: String
      let authenticatorData: String
      let signature: String
      let userHandle: String

      init(cred: ASAuthorizationPlatformPublicKeyCredentialAssertion){
        clientDataJSON = cred.rawClientDataJSON.toBase64URL()
        authenticatorData = cred.rawAuthenticatorData.toBase64URL()
        signature = cred.signature.toBase64URL()
        userHandle = String(decoding: cred.userID, as: UTF8.self)
      }
    }
    var type = "public-key"
    let id: String
    let rawId: String
    let response: Response

    init(cred: ASAuthorizationPlatformPublicKeyCredentialAssertion){
      id = cred.credentialID.toBase64URL()
      rawId = cred.credentialID.toBase64URL()
      response = Response(cred: cred)
    }


  }


  struct RegisterCompleteData: Codable {
    struct Response : Codable {
      let clientDataJSON : String
      let attestationObject: String

      init(cred: ASAuthorizationPlatformPublicKeyCredentialRegistration){
        clientDataJSON = cred.rawClientDataJSON.toBase64URL()
        attestationObject = cred.rawAttestationObject!.toBase64URL()
      }
    }

    var type = "public-key"
    let id: String
    let rawId: String
    let response: Response

    init(cred: ASAuthorizationPlatformPublicKeyCredentialRegistration){
      id = cred.credentialID.toBase64URL()
      rawId = cred.credentialID.toBase64URL()
      response = Response(cred: cred)

    }

  }

  class RegisterAttempt : NSObject, ASAuthorizationControllerDelegate {
    let completion : (RegisterCompleteData?)->(Void)

    public init(completion: @escaping (RegisterCompleteData?)->(Void)){
      self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
      switch authorization.credential {
      case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:

        completion(RegisterCompleteData(cred:credentialRegistration))
        break
      default:
        completion(nil)
      }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
      print("auth error: \(error)")
      completion(nil)
    }
  }

  class LoginAttempt : NSObject, ASAuthorizationControllerDelegate {
    let completion : (LoginCompleteData?)->(Void)

    public init(completion: @escaping (LoginCompleteData?)->(Void)){
      self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
      switch authorization.credential {
      case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:

        completion(LoginCompleteData(cred:credentialAssertion))
        break
      default:
        completion(nil)
      }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
      print("auth error: \(error)")
      completion(nil)
    }
  }

  private var auth : OPDS2AuthenticationDocument.Authentication

  let anchor : ASPresentationAnchor
  //have to keep the object here to keep it alive
  private var attempt : Any?
  
  static func windowBy(vc: UIViewController) -> UIWindow? {
      var responder = vc.next
      if responder == nil {
          responder = vc.navigationController
      }
      if responder == nil {
          responder = vc.presentingViewController
      }
      while responder != nil {
          if responder!.isKind(of: UIWindow.self) {
              return responder as? UIWindow
          }
          responder = responder?.next
      }
      return nil
  }
  
  public init(_ authentication : OPDS2AuthenticationDocument.Authentication){
    auth = authentication
    anchor = PasskeyManager.windowBy(vc: TPPRootTabBarController.shared())!
  }
  deinit {
      print("deinit!")
  }
  
  
  public func login(_ username : String, completion : @escaping (String?) -> Void){
    
    let start = auth.links?.first(where: {$0.rel == "passkey_login_start"})
    var startRequest = URLRequest(url:URL(string:start!.href)!)
    startRequest.httpMethod = "POST"
    startRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    startRequest.setValue("application/json", forHTTPHeaderField: "accept")
    let content = "{ \"username\" : \"\(username)\" }"
    startRequest.httpBody = Data(content.utf8)

    URLSession.shared.dataTask(with: startRequest) { data, response, error in
      print("passkey start error: \(error.debugDescription))")
      print("passkey start result: \(String(bytes: data!.bytes, encoding: .utf8))")
      
      let httpResponse = response as! HTTPURLResponse

      let startResponse = try? JSONDecoder().decode(LoginStartResponse.self, from: data!)

      //can we check for 200 code from response?
      if httpResponse.statusCode == 200, let startResponse = startResponse {
        self.performPassKeyLogin(username, startResponse.publicKey) { data in
          if let data = data {
            self.finishLogin(data) { token in
              completion(token)
            }
          }else{
            completion(nil)
          }
          
        }
      }else{
        completion(nil)
      }
      
    }.resume()
  }
  
  var authController : ASAuthorizationController? = nil
  private func performPassKeyRegister(_ username: String, _ pk : RegisterStartResponse.PublicKey, completion : @escaping (RegisterCompleteData?) -> Void){

    let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "e-kirjasto.loikka.dev")

    let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: try! Data.fromBase64Url(pk.challenge)!,name: username, userID: pk.user.id.data(using: .utf8)!)
    let registerAttempt = RegisterAttempt(completion: completion)
    attempt = registerAttempt
    authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
    authController!.delegate = registerAttempt
    authController!.presentationContextProvider = self

    
    authController!.performRequests()

    
  }
  
  private func performPassKeyLogin(_ username: String, _ pk : LoginStartResponse.PublicKey, completion : @escaping (LoginCompleteData?) -> Void){
    let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "e-kirjasto.loikka.dev")

    let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: try! Data.fromBase64Url(pk.challenge)!)

    let loginAttempt = LoginAttempt(completion: completion)
    attempt = loginAttempt
    authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
    authController!.delegate = loginAttempt
    authController!.presentationContextProvider = self


    authController!.performRequests()
  }

  private func finishLogin(_ data : LoginCompleteData, completion : @escaping (String?) -> Void){


    
    let finish = auth.links?.first(where: {$0.rel == "passkey_login_finish"})
    var finishRequest = URLRequest(url:URL(string:finish!.href)!)
    finishRequest.httpMethod = "POST"
    finishRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    finishRequest.setValue("application/json", forHTTPHeaderField: "accept")

    let dataJson = try! String(data: JSONEncoder().encode(data),encoding: .utf8)
    let content = "{ \"id\" : \"\(data.id)\" ,\"data\" : \(dataJson!) }"
    finishRequest.httpBody = Data(content.utf8)
    print("login content: \(content)")
    URLSession.shared.dataTask(with: finishRequest) { _data,_response,_error in
      print("passkey finish error: \(_error.debugDescription))")
      print("passkey finish result: \(String(bytes: _data!.bytes, encoding: .utf8))")
      
      if let data = _data {
        let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data)
        completion(tokenResponse?.token ?? nil)
      }else {
        completion(nil)
      }

    }.resume()
  }
  
  
  public func register(_ username : String,_ token : String, completion : @escaping (String?) -> Void){
    let start = auth.links?.first(where: {$0.rel == "passkey_register_start"})
    let register  = "\(start!.href)"
    var startRequest = URLRequest(url:URL(string:register)!)
    startRequest.httpMethod = "POST"
    startRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    let authorization = "Bearer \(token)"
    //startRequest.addValue("application/json", forHTTPHeaderField: "Accept")
    startRequest.addValue(authorization, forHTTPHeaderField: "authorization")
    print("auth: \(authorization)")
    let content = "{ \"username\" : \"\(username)\" }"
    startRequest.httpBody = Data(content.utf8)
    
    URLSession.shared.dataTask(with: startRequest) { data, response, _error in

      let _resp = response as! HTTPURLResponse

      print("passkey register start error: \(_error.debugDescription) \(_resp.statusCode)")
      print("passkey register start result: \(String(bytes: data!.bytes, encoding: .utf8))")

      let startResponse = try? JSONDecoder().decode(RegisterStartResponse.self, from: data!)

      //can we check for 200 code from response?
      if _error == nil, let startResponse = startResponse {
        self.performPassKeyRegister(username, startResponse.publicKey) { cred in
          self.finishRegister(username,token, cred!, completion: completion)
        }
      }else{
        completion(nil)
      }
      
    }.resume()
  }
  
  private func finishRegister(_ username : String, _ token: String, _ data : RegisterCompleteData, completion : @escaping (String?) -> Void){
    let finish = auth.links?.first(where: {$0.rel == "passkey_register_finish"})
    var finishRequest = URLRequest(url:URL(string:finish!.href)!)
    finishRequest.httpMethod = "POST"
    finishRequest.addValue("application/json", forHTTPHeaderField: "content-type")
    finishRequest.addValue("application/json", forHTTPHeaderField: "accept")
    let authorization = "Bearer \(token)"
    print("register finish url:\(finish!.href)")
    finishRequest.setValue(authorization, forHTTPHeaderField: "authorization")
    let dataJson = try! String(data: JSONEncoder().encode(data),encoding: .utf8)
    let content = "{ \"username\" : \"\(username)\" ,\"data\" : \(dataJson!) }"
    print("content: \(content)")
    finishRequest.httpBody = Data(content.utf8)
    print("token: \(token)")

    URLSession.shared.dataTask(with: finishRequest) { _data,_response,_error in

      let _resp = _response as! HTTPURLResponse

      print("passkey register finish error: \(_error.debugDescription) \(_resp.statusCode)")
      print("passkey register finish result: \(String(bytes: _data!.bytes, encoding: .utf8))")

      if let data = _data {
        let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data)
        completion(tokenResponse?.token ?? nil)
      }else {
        completion(nil)
      }
    }.resume()
  }
 
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return anchor
  }

}

//copy pasted from flutter passkey swift wrapper
extension Data {

  static func fromBase64(_ encoded: String) -> Data? {
      // Prefixes padding-character(s) (if needed).
      var encoded = encoded
      let remainder = encoded.count % 4
      if remainder > 0 {
          encoded = encoded.padding(
              toLength: encoded.count + 4 - remainder,
              withPad: "=", startingAt: 0
          )
      }

      // Finally, decode.
      return Data(base64Encoded: encoded)
  }

  static func fromBase64Url(_ encoded: String) -> Data? {
      let base64String = base64UrlToBase64(base64Url: encoded)
      return fromBase64(base64String)
  }

  private static func base64UrlToBase64(base64Url: String) -> String {
      let base64 = base64Url
          .replacingOccurrences(of: "-", with: "+")
          .replacingOccurrences(of: "_", with: "/")

      return base64
  }

    func toBase64URL() -> String {
        let current = self

        var result = current.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}

public extension String {
    static func fromBase64(_ encoded: String) -> String? {
        if let data = Data.fromBase64(encoded) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

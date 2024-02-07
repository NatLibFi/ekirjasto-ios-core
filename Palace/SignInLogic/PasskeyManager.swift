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



class PasskeyManager : NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
 
  struct PasskeyLoginStartResponse: Codable {
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
  
  private var auth : OPDS2AuthenticationDocument.Authentication
  
  let placholderKey = "passkey!!#4423"
  let anchor : ASPresentationAnchor
  
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
  
  
  
  public func login(_ username : String, completion : @escaping (String?) -> Void){
    
    let start = auth.links?.first(where: {$0.rel == "passkey_login_start"})
    var startRequest = URLRequest(url:URL(string:start!.href)!)
    startRequest.httpMethod = "POST"
    startRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    let content = "{ \"username\" : \"\(username)\" }"
    startRequest.httpBody = Data(content.utf8)

    URLSession.shared.dataTask(with: startRequest) { data, response, error in
      print("passkey start error: \(error.debugDescription))")
      print("passkey start result: \(String(bytes: data!.bytes, encoding: .utf8))")
      
      //can we check for 200 code from response?
      if error == nil {
        self.finishLogin(data) { token in
          completion(token)
        }
      }else{
        completion(nil)
      }
      
    }.resume()
  }
  
  
  private func performLogin(_ username: String, _ pk : PasskeyLoginStartResponse.PublicKey, completion : @escaping (String?) -> Void){
    
    let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "e-kirjasto.loikka.dev?mode=developer")
    
    let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: pk.challenge.data(using: .utf8)!,
                                                                                              name: username, userID: pk.user.id.data(using: .utf8)!)
    
    let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
    authController.delegate = self
    authController.presentationContextProvider = self
    
    authController.performRequests()

    
  }
  
  private func finishLogin(_ data : Data?, completion : @escaping (String?) -> Void){
    

    
    let finish = auth.links?.first(where: {$0.rel == "passkey_login_finish"})
    var finishRequest = URLRequest(url:URL(string:finish!.href)!)
    finishRequest.httpMethod = "POST"
    finishRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    let content = "{ \"id\" : \"e49GVAdrgOuWORHxnPrRqvQoXtSOgm9s3hsBp5qnP621RG5mf8T5BBd4LJEnBUDz\" ,\"data\" : \"\(placholderKey)\" }"
    finishRequest.httpBody = Data(content.utf8)
    
    URLSession.shared.dataTask(with: finishRequest) { _data,_response,_error in
      print("passkey finish error: \(_error.debugDescription))")
      print("passkey finish result: \(String(bytes: _data!.bytes, encoding: .utf8))")
      
      completion(nil)
    }.resume()
  }
  
  
  public func register(_ username : String, completion : @escaping (String?) -> Void){
    let start = auth.links?.first(where: {$0.rel == "passkey_register_start"})
    var startRequest = URLRequest(url:URL(string:start!.href)!)
    startRequest.httpMethod = "POST"
    startRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    let content = "{ \"username\" : \"\(username)\" }"
    startRequest.httpBody = Data(content.utf8)
    
    URLSession.shared.dataTask(with: startRequest) { data, response, _error in
      print("passkey register start error: \(_error.debugDescription))")
      print("passkey register start result: \(String(bytes: data!.bytes, encoding: .utf8))")
      
      //let decoder = JSONDecoder()
     // decoder.keyDecodingStrategy = .
      do {
        let startResponse = try JSONDecoder().decode(PasskeyLoginStartResponse.self, from: data!)
        
        self.performLogin(username, startResponse.publicKey) { cred in
          
        }
      }catch {
        print("abc \(error)")
      }
      //can we check for 200 code from response?
      if _error == nil {
       completion(nil)
        // self.finishRegister(username,self.placholderKey) { token in
       //   completion(token)
       // }
      }else{
        completion(nil)
      }
      
    }.resume()
  }
  
  private func finishRegister(_ username : String, _ data : String, completion : @escaping (String?) -> Void){
    let finish = auth.links?.first(where: {$0.rel == "passkey_register_finish"})
    var finishRequest = URLRequest(url:URL(string:finish!.href)!)
    finishRequest.httpMethod = "POST"
    finishRequest.setValue("application/json", forHTTPHeaderField: "content-type")
    let content = "{ \"username\" : \"\(username)\" ,\"data\" : \"\(placholderKey)\" }"
    finishRequest.httpBody = Data(content.utf8)
    
    URLSession.shared.dataTask(with: finishRequest) { _data,_response,_error in
      print("passkey register finish error: \(_error.debugDescription))")
      print("passkey register finish result: \(String(bytes: _data!.bytes, encoding: .utf8))")
      completion(nil)
    }.resume()
  }
 
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return anchor
  }
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    print("auth: \(authorization)")
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    print("auth error: \(error)")
  }
  
}

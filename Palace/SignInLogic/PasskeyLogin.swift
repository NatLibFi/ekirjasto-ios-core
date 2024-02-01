//
//  PasskeyLogin.swift
//  Palace
//
//  Created by Joni Salmela on 22.1.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation


class PasskeyLogin {
  
  private var auth : OPDS2AuthenticationDocument.Authentication
  
  let placholderKey = "passkey!!#4423"
  
  public init(_ authentication : OPDS2AuthenticationDocument.Authentication){
    auth = authentication
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
        self.finishLogin(self.placholderKey) { token in
          completion(token)
        }
      }else{
        completion(nil)
      }
      
    }.resume()
  }
  
  private func finishLogin(_ data : String, completion : @escaping (String?) -> Void){
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
    
    URLSession.shared.dataTask(with: startRequest) { data, response, error in
      print("passkey register start error: \(error.debugDescription))")
      print("passkey register start result: \(String(bytes: data!.bytes, encoding: .utf8))")
      
      //can we check for 200 code from response?
      if error == nil {
        self.finishRegister(username,self.placholderKey) { token in
          completion(token)
        }
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
  
}

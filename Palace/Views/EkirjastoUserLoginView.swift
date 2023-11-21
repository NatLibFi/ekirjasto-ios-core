//
//  EkirjastoUserLoginView.swift
//  Ekirjasto
//
//  Created by Joni Salmela on 8.11.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct EkirjastoUserLoginView: View {
    
    @State var showBrowser = false
  
    var body: some View {
      if showBrowser {
        SuomiIdentificationWebView(closeWebView: {
          showBrowser = false
        })
      }else{
        VStack{
          GoogleSignInButton(style: .wide) {
            loginGoogle()
          }.frame(width: 300, height: 40)
          SignInWithAppleButton(.signIn){ request in
            request.requestedScopes = [.fullName, .email]
          } onCompletion: { result in
            switch result {
            case .success(let authResult):
              loginApple(authResult)
              break
            case .failure(let error):
              print(error.localizedDescription)
              break
            }
          }.signInWithAppleButtonStyle(.black)
            .frame(width: 300, height: 40)
          
          /*Label {
            Text("Sign in with Suomi.fi e-identification").foregroundColor(Color.white)
          } icon: {
            Image("Placeholder").frame(maxWidth: 10, maxHeight: 10)
          }*/
          Label("Sign in with Suomi.fi e-identification",image:"").foregroundColor(Color.white).frame(height: 40).onTouchDownUp { down, value in
            if !down {
              loginSuomi()
            }
            
          }
          Label("Sign in with passkey",image:"").foregroundColor(Color.white).frame(height: 40)
          Label("Sign in with email",image:"").foregroundColor(Color.white).frame(height: 40)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("ColorEkirjastoGreen"))
      }

    }
  
  func sendAuthCodeGoogle(_ authCode:String){
    
    var request = URLRequest(url:URL(string:"https://e-kirjasto.loikka.dev/v1/auth/google")!)
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    let content = "{ \"code\" : \"\(authCode)\" }"
    request.httpBody = Data(content.utf8)
    request.httpMethod = "POST"

    URLSession.shared.dataTask(with: request){ data, response, error in
      if error != nil {
        print("dataTask error: \(error.debugDescription)")
      }else{
        print("auth result: \(String(bytes: data!.bytes, encoding: .utf8))")
        let json = try? JSONSerialization.jsonObject(with: data!)
        let jsonRoot = json as? [String: Any]
        var _request = URLRequest(url:URL(string:"https://e-kirjasto.loikka.dev/v1/auth/userinfo")!)
        _request.httpMethod = "GET"
        print("token \(jsonRoot!["token"] ?? "")")
        _request.setValue( //3
          "Bearer \(jsonRoot!["token"] ?? "")",
          forHTTPHeaderField: "Authorization"
        )
        URLSession.shared.dataTask(with: _request){ data, response, error in
          print("user error: \(error.debugDescription))")
          print("user result: \(String(bytes: data!.bytes, encoding: .utf8))")
        }.resume()
      }
    }.resume()
  }
  
  func sendAuthCodeApple(_ authCode:String, _ idToken:String ){
    
    var request = URLRequest(url:URL(string:"https://e-kirjasto.loikka.dev/v1/auth/apple")!)
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    let content = "{ \"code\" : \"\(authCode)\", \"id_token\" : \"\(idToken)\" }"
    request.httpBody = Data(content.utf8)
    request.httpMethod = "POST"

    URLSession.shared.dataTask(with: request){ data, response, error in
      if error != nil {
        print("dataTask error: \(error.debugDescription)")
      }else{
        print("auth result: \(String(bytes: data!.bytes, encoding: .utf8))")
        let json = try? JSONSerialization.jsonObject(with: data!)
        let jsonRoot = json as? [String: Any]
        var _request = URLRequest(url:URL(string:"https://e-kirjasto.loikka.dev/v1/auth/userinfo")!)
        _request.httpMethod = "GET"
        print("token \(jsonRoot!["token"] ?? "")")
        _request.setValue(
          "Bearer \(jsonRoot!["token"] ?? "")",
          forHTTPHeaderField: "Authorization"
        )
        URLSession.shared.dataTask(with: _request){ data, response, error in
          print("user error: \(error.debugDescription))")
          print("user result: \(String(bytes: data!.bytes, encoding: .utf8))")
        }.resume()
      }
    }.resume()
  }
  
  func loginSuomi(){
    showBrowser = true
  }
  
  func loginApple(_ auth : ASAuthorization){
    let credential = auth.credential as? ASAuthorizationAppleIDCredential
    
    sendAuthCodeApple(String(bytes: credential!.authorizationCode!.bytes, encoding: .utf8)! , String(bytes: credential!.identityToken!.bytes, encoding: .utf8)!)
    
    let redirectUri = "https://e-kirjasto.loikka.dev/api/auth/apple"
    
    
    
  }
  
  func loginGoogle(){
    let viewController = UIApplication.shared.windows.last?.rootViewController
    GIDSignIn.sharedInstance.signIn(withPresenting: viewController!){ signInResult, error in
      guard let signInResult = signInResult else {
        print("Error! \(String(describing: error))")
        return
      }
      sendAuthCodeGoogle(signInResult.serverAuthCode! )
      print("user server auth code: \(signInResult.serverAuthCode)")
      
      
      
    }
  }
  
}

struct EkirjastoUserLoginView_Previews: PreviewProvider {
    static var previews: some View {
        EkirjastoUserLoginView()
    }
}

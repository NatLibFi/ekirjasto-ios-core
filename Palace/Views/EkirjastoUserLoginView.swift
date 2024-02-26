//
//  EkirjastoUserLoginView.swift
//  Ekirjasto
//
//  Created by Joni Salmela on 8.11.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI
import AuthenticationServices

struct EkirjastoUserLoginView: View {
    
  var dismissView: () -> Void
  
  @State var passKeyLogin : PasskeyManager? = nil
  @State var _loginSuomi = false
  @State var _passKey = 0
  @State var authDoc : OPDS2AuthenticationDocument? = nil
  
  var body: some View {
    if _loginSuomi {
      SuomiIdentificationWebView(closeWebView: {
        _loginSuomi = false
        self.dismissView()
      }, authenticationDocument: authDoc)
    }else if _passKey != 0 {
      passkeyEmail
    }else{
      VStack{

        Label("Sign in with Suomi.fi e-identification",image:"").foregroundColor(Color.white).frame(height: 40).onTouchDownUp { down, value in
          if !down {
            loginSuomi()
          }
          
        }
        Label("Register with passkey",image:"").foregroundColor(Color.white).frame(height: 40).onTouchDownUp{ down, value in
          if !down {
            showPasskey(1)
          }
        }
        Label("Sign in with passkey",image:"").foregroundColor(Color.white).frame(height: 40).onTouchDownUp{ down, value in
          if !down {
            showPasskey(2)
          }
        }
        
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))
    }
  


  }
  
  @State var passkeyUserName = ""
  
  private var passkeyEmail: some View {
    VStack{
      TextField("Username", text: $passkeyUserName)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button(action: {if _passKey == 1 { self.registerPasskey() } else if _passKey == 2 { self.loginPasskey() }}){
        Text("Continue")
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))

  }
  
  func fetchAuthDoc(completion: @escaping (_ doc: (OPDS2AuthenticationDocument?))->Void){
    if let currentAccount = AccountsManager.shared.currentAccount {
      completion(currentAccount.authenticationDocument!)
    }else if let account = AccountsManager.shared.accounts().first {
      account.loadAuthenticationDocument(completion: { Bool in
        DispatchQueue.main.async {
          completion(account.authenticationDocument!)
        }
      })
    }else{
      completion(nil)
    }
  }

  
  func showPasskey(_ mode: Int){
    if authDoc == nil {
      fetchAuthDoc { doc in
        authDoc = doc!
        _passKey = mode
      }
    }else{
      _passKey = mode
    }
  }
  
  
  func loginPasskey(){
    let authentication = authDoc?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    self.passKeyLogin = PasskeyManager(authentication!)
    
    self.passKeyLogin!.login(passkeyUserName) { loginToken in
      if let token = loginToken, !token.isEmpty{
        TPPNetworkExecutor.shared.authenticateWithToken(token)
      }
    }
    
  }
  
  func registerPasskey(){
    let authentication = authDoc?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    self.passKeyLogin = PasskeyManager(authentication!)
    
    if let savedToken = TPPUserAccount.sharedAccount().authToken {
      self.passKeyLogin!.register(passkeyUserName,savedToken) { registerToken in
        if let token = registerToken, !token.isEmpty{
          TPPNetworkExecutor.shared.authenticateWithToken(token)
          
        }
      }
    }
    
    
  }
  
  
  func loginSuomi(){
    if authDoc == nil {
      fetchAuthDoc { doc in
        authDoc = doc!
        _loginSuomi = true
      }
    }else{
      _loginSuomi = true
    }
  }
  
}

struct EkirjastoUserLoginView_Previews: PreviewProvider {
    static var previews: some View {
      EkirjastoUserLoginView(dismissView: {
        
      })
    }
}

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
  @State var _passKey = false
  @State var authDoc : OPDS2AuthenticationDocument? = nil
  
  var body: some View {
    if _loginSuomi {
      SuomiIdentificationWebView(closeWebView: {
        _loginSuomi = false
        self.dismissView()
      }, authenticationDocument: authDoc)
    }else if _passKey {
      passkeyEmail
    }else{
      VStack{

        Label("Sign in with Suomi.fi e-identification",image:"").foregroundColor(Color.white).frame(height: 40).onTouchDownUp { down, value in
          if !down {
            loginSuomi()
          }
          
        }
        Label("Sign in with passkey",image:"").foregroundColor(Color.white).frame(height: 40).onTouchDownUp{ down, value in
          if !down {
            showPasskey()
          }
        }
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))
    }
  


  }
  
  @State var passkeyUserEmail = ""
  
  private var passkeyEmail: some View {
    VStack{
      TextField("Email", text: $passkeyUserEmail)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button(action: loginPasskey){
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

  
  func showPasskey(){
    if authDoc == nil {
      fetchAuthDoc { doc in
        authDoc = doc!
        _passKey = true
      }
    }else{
      _passKey = true
    }
  }
  
  
  func loginPasskey(){
    let authentication = authDoc?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    self.passKeyLogin = PasskeyManager(authentication!)
    
    self.passKeyLogin!.login(passkeyUserEmail) { loginToken in
      //let savedToken = TPPUserAccount.sharedAccount().authToken
      if loginToken == nil, let savedToken = TPPUserAccount.sharedAccount().authToken {
        self.passKeyLogin!.register(passkeyUserEmail,savedToken) { registerToken in
          
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

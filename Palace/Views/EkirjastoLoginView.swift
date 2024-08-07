//
//  EkirjastoLoginView.swift
//  Ekirjasto
//
//  Created by Nianzu on 11.7.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import SwiftUI

struct EkirjastoLoginView: View {
  typealias DisplayStrings = Strings.Settings
  
  var dismissView: (() -> Void)?
  var navController: UINavigationController? = nil
  

  @State var authDoc : OPDS2AuthenticationDocument? = nil
  
    var body: some View {

        NavigationView{
          VStack {
            Image("LaunchImageLogo")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 200)
            
            Image("introPhones")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 300)
              .padding(.vertical, 50)
            if authDoc != nil {
              buttonsSection()
            }else{
              ProgressView()
            }
            
          }
        }.navigationViewStyle(.stack)
          .onAppear{
            AccountsManager.fetchAuthDoc { doc in
              authDoc = doc
          }
        }
    }
  
  @ViewBuilder func buttonsSection() -> some View{

    Section{
      
      NavigationLink(destination: {
        SuomiIdentificationWebView(closeWebView: {
          self.dismissView?()
        }, authenticationDocument: authDoc)
      }, label: {
        Text(DisplayStrings.loginSuomiFi).foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        Image("ArrowRight")
          .padding(.leading, 10)
          .foregroundColor(Color("ColorEkirjastoGreen"))
      }).frame(width: 300, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(Color("ColorEkirjastoLightestGreen"))
      
      Button(action: {
        
        let passkey = PasskeyManager(authDoc!)
        
        passkey.login { loginToken in

          if let token = loginToken, !token.isEmpty{
            TPPNetworkExecutor.shared.authenticateWithToken(token) { status in
              DispatchQueue.main.async {
                self.dismissView?()
              }
            }
            
          }

        }
      }, label: {
        Text(DisplayStrings.loginPasskey).foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        Image("ArrowRight")
          .padding(.leading, 10)
          .foregroundColor(Color("ColorEkirjastoGreen"))
      }).frame(width: 300, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(Color("ColorEkirjastoLightestGreen"))
      
      
      Button(action: {self.dismissView?()}) {
        Text(DisplayStrings.continueWithoutSigning).foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        Image("ArrowRight")
          .padding(.leading, 10)
          .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
      }
      .frame(width: 300, height: 40)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .background(Color("ColorEkirjastoYellow"))
    }

    

  }

}

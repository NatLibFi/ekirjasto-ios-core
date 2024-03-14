//
//  EkirjastoLoginView.swift
//  Ekirjasto
//
//  Created by Nianzu on 11.7.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import SwiftUI

struct EkirjastoLoginView: View {
  var dismissView: () -> Void
  var navController: UINavigationController? = nil
  
  @State var displaySuomiIdentificationWebView = false
  @State var showLoginView = false
  
    var body: some View {
      ZStack {
        if(showLoginView){
          EkirjastoUserLoginView(dismissView: {
            self.dismissView()
          })
        }else{
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
            
            Button(action: {/*self.dismissView();*/ self.signIn()}) {
              Text("Kirjaudu palveluun").foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
              Image("ArrowRight")
                .padding(.leading, 10)
                .foregroundColor(Color("ColorEkirjastoGreen"))
            }
            .frame(width: 300, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .background(Color("ColorEkirjastoLightestGreen"))
            
            Button(action: {self.signUp()}) {
              Text("Rekisteröidy palveluun").foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
              Image("ArrowRight")
                .padding(.leading, 10)
                .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
            }
            .frame(width: 300, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .background(Color("ColorEkirjastoGreen"))
          }
        }
      }.sheet(isPresented: $displaySuomiIdentificationWebView, content: {
        //SuomiIdentificationWebView(closeWebView: {
          //displaySuomiIdentificationWebView = false
          //self.dismissView()
        //})
      })
        
    }
  
  func signIn(){
    EkirjastoLoginViewController.show(navController: navController) {
      self.dismissView()
    }
    //showLoginView = true
  }
  func signUp(){
    //workaround to skip regular login. and to get to simple login
    self.dismissView()
    //displaySuomiIdentificationWebView = true
  }
}

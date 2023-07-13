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
  
    var body: some View {
      ZStack {
        VStack {
          Image("LaunchImageLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 300)
          
          Button(action: {self.dismissView(); self.signIn()}) {
            Text("Kirjaudu palveluun")
          }
          .frame(width: 300, height: 50)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .background(Color("ColorEkirjastoLighterGreen"))
          
          Button(action: {self.dismissView(); self.signUp()}) {
            Text("Rekisteröidy palveluun")
          }
          .frame(width: 300, height: 50)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .background(Color("ColorEkirjastoGreen"))
        }
      }
    }
  
  func signIn(){
    
  }
  func signUp(){
    
  }
}

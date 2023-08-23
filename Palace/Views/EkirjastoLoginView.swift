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
            Image("ArrowRight")
              .padding(.leading, 10)
              .foregroundColor(Color("ColorEkirjastoGreen"))
          }
          .frame(width: 300, height: 50)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .background(Color("ColorEkirjastoLightestGreen"))
          
          Button(action: {self.dismissView(); self.signUp()}) {
            Text("Rekisteröidy palveluun")
            Image("ArrowRight")
              .padding(.leading, 10)
          }
          .frame(width: 300, height: 50)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .background(Color("ColorEkirjastoLighterGreen"))
        }
      }
    }
  
  func signIn(){
    
  }
  func signUp(){
    
  }
}

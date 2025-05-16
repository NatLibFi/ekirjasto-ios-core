//
//  TestLoginUI.swift
//  Palace
//
//  Created by Joni Salmela on 26.4.2024.
//  Copyright © 2024 Kansalliskirjasto. All rights reserved.
//

import Foundation
import SwiftUI


struct TestLoginUI : View {
  
  var completion : (Bool)->()
  @State var username = ""
  @State var pin = ""
  @State var errorText = ""
  
  private static let CORRECT_USERNAME = "AppReview"
  private static let CORRECT_PIN = "8682511741"
  
  var body: some View {
    return VStack{
      Text("E-kirjasto test login").bold()
      HStack {
        Text("Username:").frame(width: 90, alignment: .leading)
        TextField("Username", text: $username)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .textContentType(.username)
          .padding(5)
          .background(RoundedRectangle(cornerRadius: 10).fill(Color("ColorEkirjastoLightestGreen")))
      }
      HStack {
        Text("PIN code:").frame(width: 90, alignment: .leading)
        TextField("PIN code", text: $pin)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .textContentType(.password)
          .padding(5)
          .background(RoundedRectangle(cornerRadius: 10).fill(Color("ColorEkirjastoLightestGreen")))
      }.padding([.bottom], 10)
      HStack {
        Button(action: {
          if (username == TestLoginUI.CORRECT_USERNAME) && (pin == TestLoginUI.CORRECT_PIN) {
            completion(true)
          }
          else {
            errorText = "Incorrect test login credentials"
          }
        }){
          Text("Login").foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        }.padding(5)
          .background(RoundedRectangle(cornerRadius: 10).fill(Color("ColorEkirjastoLightestGreen")))
        Button(action: {
          completion(false)
        }){
          Text("Cancel").foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        }.padding(5)
          .background(RoundedRectangle(cornerRadius: 10).fill(Color("ColorEkirjastoLightGrey")))
      }
      Text(errorText).foregroundColor(.red).frame(height: 40)
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(40)
      .background(Color("ColorEkirjastoGreen"))
      .navigationBarBackButtonHidden(false)
  }
}

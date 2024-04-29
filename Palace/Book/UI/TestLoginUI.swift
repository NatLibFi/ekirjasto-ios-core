//
//  TestLoginUI.swift
//  Palace
//
//  Created by Joni Salmela on 26.4.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI


struct TestLoginUI : View {
  
  var completion : (Bool)->()
  @State var username = ""
  @State var pin = ""
  
  private static let CORRECT_PIN = "1234"
  private static let CORRECT_USERNAME = "test"
  
  var body: some View {
    return VStack{
      TextField("Username", text: $username)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textContentType(.username)
      TextField("Pin", text: $pin)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textContentType(.password)
      Button(action: {
        if username == TestLoginUI.CORRECT_USERNAME && pin == TestLoginUI.CORRECT_PIN {
          completion(true)
        }else {
          completion(false)
        }
      }){
        Text("Continue")
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))
      .navigationBarBackButtonHidden(false)
  }
}

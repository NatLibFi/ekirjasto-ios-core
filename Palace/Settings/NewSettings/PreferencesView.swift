//
//  PreferencesView.swift
//  Palace
//
//  Created by Kupe, Joona on 3.8.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import SwiftUI
import Combine

struct PreferencesView: View {
  typealias tsx = Strings.Preferences
  var language = [tsx.en, tsx.fi, tsx.sv]
  var fontSize = [tsx.fontNormal, tsx.fontMedium, tsx.fontLarge]
  @State private var selectSize = "100%"
  @State private var selectLang = "English"
  @State private var langPreference = "fi"
  @State private var toggleState = false
  @State private var setFontSize = 18
  @State private var showAlert = false
  
  var body: some View {
    List {
      Section {
        Toggle(isOn: $toggleState) {
          Text(Strings.Preferences.togglePref)
            .onChange(of: toggleState) { newValue in
                UserDefaults.standard.set(newValue, forKey: "enablePreferences")
            }
        }
        
//        //TODO: remove preferences if toggle is set to false
//        
//        .font(.system(size: CGFloat(setFontSize)))
//        .accessibilityLabel(tsx.selectEnable)
//        
//        /*
//        //construct alert message
//        .alert(isPresented: $showAlert) {
//          Alert(title: Text(tsx.restartTitle), message: Text(tsx.restartText), dismissButton: .default(Text("OK")))
//                }
//         */
//        
//        //before view appears, get saved values
//        .onAppear {
//          toggleState = UserDefaults.standard.bool(forKey: "enablePreferences")
//          setFontSize = UserDefaults.standard.integer(forKey: "fontPreferences")
//          if let savedselectSize = UserDefaults.standard.string(forKey: "selectSize"){
//            selectSize = savedselectSize
//          }else{
//            selectSize = "100%"
//          }
//          if let savedLangPreference = UserDefaults.standard.string(forKey: "langPreference") {
//                  selectLang = savedLangPreference
//              } else {
//                  selectLang = "Finnish"
//              }
//          
//          print(toggleState)
//          print(setFontSize)
//          print(selectLang)
//          
//        }
//        VStack{
//          //Picker for language
//          Picker(tsx.langButton, selection: $selectLang) {
//              ForEach(language, id: \.self) {
//                  Text($0)
//              }
//          }
//          .font(.system(size: CGFloat(setFontSize)))
//          .onChange(of: selectLang) { newValue in
//            
//            UserDefaults.standard.set(selectLang, forKey: "langPreference")
//            
//            //save lang preference when value changes
//            switch selectLang {
//            case tsx.fi:
//              UserDefaults.standard.set(["fi"], forKey: "AppleLanguages")
//              print("selected: ", selectLang)
//              //Bundle.main.load()
//            case tsx.sv:
//              UserDefaults.standard.set(["sv"], forKey: "AppleLanguages")
//              print("selected: ", selectLang)
//            case tsx.en:
//              UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
//              
//              print("selected: ", selectLang)
//            default:
//              print("Language set to default")
//              print("selected: ", selectLang)
//              UserDefaults.standard.set(["fi"], forKey: "AppleLanguages")
//            }
//            //just to make sure value is saved
//            UserDefaults.standard.synchronize()
//            print(newValue)
//            
//          }
//          .font(.system(size: CGFloat(setFontSize)))
//          .accessibilityLabel(tsx.selectL)
//          
//          //Picker for Font Size
//          Picker(tsx.fontSizeButton, selection: $selectSize){
//            ForEach(fontSize, id: \.self){
//              Text($0)
//            }
//          }
//          .font(.system(size: CGFloat(setFontSize)))
//            .onChange(of: selectSize) { newValue in
//                print(newValue)
//              UserDefaults.standard.set(selectSize, forKey: "selectSize")
//              if newValue == tsx.fontLarge{
//                setFontSize = 30
//                print(setFontSize)
//                UserDefaults.standard.set(setFontSize, forKey: "fontPreferences")
//                
//              }else if newValue == tsx.fontMedium {
//                setFontSize = 24
//                print(setFontSize)
//                UserDefaults.standard.set(setFontSize, forKey: "fontPreferences")
//              }else{
//                setFontSize = 18
//                print(setFontSize)
//                UserDefaults.standard.set(setFontSize, forKey: "fontPreferences")
//                }
//              }
//            .font(.system(size: CGFloat(setFontSize)))
//          .accessibilityLabel(tsx.selectS)
//        }
//        .disabled(toggleState == false)
      }
    }
  }
}
//#Preview {
//    PreferencesView()
//}

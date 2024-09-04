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
  var fontSizeList = [tsx.hundred, tsx.oneTwentyFive, tsx.oneFifty, tsx.oneSeventyFive, tsx.twoHundred]
  @State private var selectLang = "English"
  @State private var langPreference = "fi"
  @State private var toggleState = false
  @State private var setFontSize: Double = 18.0
  @State private var showAlert = false
  
  // The values saved to userDefaults
  @AppStorage("fontMultiplier") private var fontMultiplier: Double = 1.0
  @AppStorage("fontPercent") private var selectPercent: String = "100%"
  @AppStorage("enablePreferences") private var enablepreferences: Bool = false
  
  var body: some View {
    List {
      Section {
        Toggle(isOn: $toggleState) {
          Text(tsx.togglePref)
            .font(.system(size: CGFloat(setFontSize)))
          // Store the new value of the toggle and save it to userDefaults
            .onChange(of: toggleState) { newValue in
              print("toggle state: \(toggleState) and newValue: \(newValue)")
              enablepreferences = newValue
              print(enablepreferences)
              print(setFontSize)
              print(fontMultiplier)
              print(selectPercent)
              
              // Set default values to userDefaults if disabled
              if toggleState == false {
                selectPercent = "100%"
                fontMultiplier = 1.0
                print("setting to defaults")
              }
            }
        }
        .padding(.vertical, 5)
        
        //TODO: remove preferences if toggle is set to false
        
        .font(.system(size: CGFloat(setFontSize)))
        .accessibilityLabel(tsx.selectEnable)
        
        /*
        //construct alert message
        .alert(isPresented: $showAlert) {
          Alert(title: Text(tsx.restartTitle), message: Text(tsx.restartText), dismissButton: .default(Text("OK")))
                }
         */
        
        //before view appears, get saved values
        .onAppear {
          toggleState = enablepreferences
          
          if let savedLangPreference = UserDefaults.standard.string(forKey: "langPreference") {
                  selectLang = savedLangPreference
              } else {
                  selectLang = "Finnish"
              }
          
          print("toggle state: \(toggleState)")
          print("setFontSize: \(setFontSize)")
          print("multiplier: \(fontMultiplier)")
          print("percent: \(selectPercent)")
          print(selectLang)
          
        }

//          VStack{
//            //Picker for language
//            Picker(tsx.langButton, selection: $selectLang) {
//              ForEach(language, id: \.self) {
//                Text($0)
//                  .font(.system(size: setFontSize))
//              }
//            }
//            .font(.system(size: CGFloat(setFontSize)))
//            .pickerStyle(.inline)
//            .onChange(of: selectLang) { newValue in
//              
//              UserDefaults.standard.set(selectLang, forKey: "langPreference")
//              
//              //save lang preference when value changes
//              switch selectLang {
//              case tsx.fi:
//                UserDefaults.standard.set(["fi"], forKey: "AppleLanguages")
//                print("selected: ", selectLang)
//                //Bundle.main.load()
//              case tsx.sv:
//                UserDefaults.standard.set(["sv"], forKey: "AppleLanguages")
//                print("selected: ", selectLang)
//              case tsx.en:
//                UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
//                
//                print("selected: ", selectLang)
//              default:
//                print("Language set to default")
//                print("selected: ", selectLang)
//                UserDefaults.standard.set(["fi"], forKey: "AppleLanguages")
//              }
//              //just to make sure value is saved
//              UserDefaults.standard.synchronize()
//              print(newValue)
//              
//            }
//            .font(.system(size: CGFloat(setFontSize)))
//            .accessibilityLabel(tsx.selectL)
//          }
//          .disabled(toggleState == false)
      }

    }
    Text(tsx.fontSizeButton)
      .font(.system(size: CGFloat(setFontSize)))
        .padding(.leading, 30)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
  
    // Forcing the slider to the bottom of the screen so that when texts are bigger, it stays where it is
    ZStack(alignment: .bottom) {
      VStack {
        HStack {
          Text("A")
            .font(.system(size: CGFloat(20)))
          Slider(value: $fontMultiplier, in: 1.0...2.0, step: 0.25) // The multiplier is saved directly to userDefaults when the value changes
          Text("A")
            .font(.system(size: CGFloat(40)))
        }
        .onChange(of: fontMultiplier) { newValue in
          print("new value: \(newValue)")
          if newValue == 1.25 {
            selectPercent = tsx.oneTwentyFive
          }
          else if newValue == 1.5 {
            selectPercent = tsx.oneFifty
          }
          else if newValue == 1.75 {
            selectPercent = tsx.oneSeventyFive
          }
          else if newValue == 2.0 {
            selectPercent = tsx.twoHundred
          }
          else {
            selectPercent = tsx.hundred
          }
          setFontSize = 16.0 * newValue
          print(setFontSize)
          print(selectPercent)
        }
        Text(selectPercent)
          .font(.system(size: CGFloat(16)))
      }
      .accessibilityLabel(tsx.selectS)
    }
    .disabled(toggleState == false)
    .padding(.bottom, 50)
    .padding(.horizontal, 40)
  }
}
//#Preview {
//    PreferencesView()
//}

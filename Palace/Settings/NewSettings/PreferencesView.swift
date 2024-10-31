//
//  PreferencesView.swift
//  Palace
//
//  Created by Kupe, Joona on 3.8.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Combine
import SwiftUI

struct PreferencesView: View {
  typealias tsx = Strings.Preferences
  var fontSizeList = [tsx.hundred, tsx.oneTwentyFive, tsx.oneFifty, tsx.oneSeventyFive, tsx.twoHundred]
  @State private var toggleState = false
  @State private var setFontSize: Double = 18.0
  @State private var showAlert = false
  
  // The values saved to userDefaults
  @AppStorage("fontMultiplier") private var fontMultiplier: Double = 1.0
  @AppStorage("fontPercent") private var selectPercent: String = "100%"
  @AppStorage("enablePreferences") private var enablepreferences: Bool = false
  
  var body: some View {
    List {
      enablePreferencesSection
      
      languagePreferencesSection
        .disabled(toggleState == false)
    }
    
    textSizePreferencesSection
      .disabled(toggleState == false)
  }
  
  @ViewBuilder private var enablePreferencesSection: some View {
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
      // TODO: remove preferences if toggle is set to false
      .font(.system(size: CGFloat(setFontSize)))
      .accessibilityLabel(tsx.selectEnable)
      // before view appears, get saved values
      .onAppear {
        toggleState = enablepreferences
        
        print("toggle state: \(toggleState)")
        print("setFontSize: \(setFontSize)")
        print("multiplier: \(fontMultiplier)")
        print("percent: \(selectPercent)")
      }
    }
  }
  
  @ViewBuilder private var languagePreferencesSection: some View {
    Section {
      Button {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
      } label: {
        HStack {
          Text(tsx.langButton)
            .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }
      .accessibilityLabel(tsx.selectL)
    }
  }
  
  @ViewBuilder private var textSizePreferencesSection: some View {
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
          Slider(value: $fontMultiplier, in: 1.0 ... 2.0, step: 0.25) // The multiplier is saved directly to userDefaults when the value changes
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
    .padding(.bottom, 50)
    .padding(.horizontal, 40)
  }
}

// #Preview {
//    PreferencesView()
// }

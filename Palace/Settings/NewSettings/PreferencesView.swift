//
//  PreferencesView.swift
//  Palace
//
//  Created by Kupe, Joona on 3.8.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Combine
import SwiftUI

// View for the user to set application prefences for the E-kirjasto app
struct PreferencesView: View {
  typealias tsx = Strings.Preferences
  
  @State private var toggleState = false
  @State private var setFontSize: Double = 16.0
  
  // The values saved to userDefaults
  @AppStorage("fontMultiplier") private var fontMultiplier: Double = 1.0
  @AppStorage("fontPercent") private var selectPercent: String = "100%"
  @AppStorage("enablePreferences") private var enablePreferences: Bool = false
  
  // View that lists all available application preferences for the user
  // and the setting for the user to enable the use of these preferences in the application
  var body: some View {
    List {
      // The toggle button to enable or disable app preferences
      enablePreferencesSection
      
      // If user has disabled the app preferences
      // the language preferences cannot be accessed straight from app.
      // However, the app specific language can be changed from device system settings
      languagePreferencesSection
        .disabled(toggleState == false)
    }
    
    // If user has disabled the app preferences
    // the text size preferences cannot be accessed straight from app.
    // However, the app specific text size can be changed from device control center
    textSizePreferencesSection
      .disabled(toggleState == false)
  }
  
  // User can enable the application prefences for the device.
  // App prefences are disabled by default.
  // The user's setting for using preferences (or not) is stored in the AppStorage (UserDefaults)
  // and it will be remembered the next time the application is used.
  @ViewBuilder private var enablePreferencesSection: some View {
    Section {
      Toggle(isOn: $toggleState) {
        Text(tsx.togglePref)
          .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      }
      .onChange(of: toggleState) { newValue in
        // User has now toggled the "Enable prefences" button
        
        print("[PreferencesView] Current toggle state is \(toggleState) and the new value of toggle is \(newValue)")
        
        // Store the new value of the toggle
        // and save it to AppStorage
        enablePreferences = newValue
        
        print(
          enablePreferences
            ? "[PreferencesView] App preferences enabled"
            : "[PreferencesView] App prefences disabled"
        )
        
        printCurrentTextSizePrefences()
        
        // If user disables using app preferences
        // reset userDefaults to app defaults
        if toggleState == false {
          resetAppPrefences()
        }
      }
      .padding(.vertical, 5)
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      .accessibilityLabel(tsx.selectEnable)
      .onAppear {
        // The moment the toggle button and the rest of the preferencess view appears
        
        // Get the stored value for using (or not using) app prefences from AppStorage
        // and restore the toggle state
        toggleState = enablePreferences
        
        print("[PreferencesView] Restoring this toggle state for view: \(toggleState)")
      }
    }
  }
  
  // Shortcut button for the user to navigate to device system settings
  // User can select different language for the app than the device language
  // Changing language starts the app from main screen
  @ViewBuilder private var languagePreferencesSection: some View {
    // This is the link to E-kirjasto settings in iOS system settings
    // You can also navigate to Settings -> Apps -> E-kirjasto
    let appSystemSettingsURL = URL(string: UIApplication.openSettingsURLString)!
    
    Section {
      Button {
        UIApplication.shared.open(appSystemSettingsURL)
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
  
  // Slider for user to select the text size for the app
  // User can only make text bigger than default, not smaller
  @ViewBuilder private var textSizePreferencesSection: some View {
    Text(tsx.fontSizeButton)
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      .padding(.leading, 30)
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity, alignment: .leading)
      
    // Forcing the slider to the bottom of the screen
    // so that when texts are bigger, it stays where it is
    ZStack(alignment: .bottom) {
      VStack {
        HStack {
          Text("A")
            .font(.system(size: CGFloat(20)))
          
          // The multiplier is saved directly to userDefaults when the value changes
          Slider(value: $fontMultiplier, in: 1.0 ... 2.0, step: 0.25)
          
          Text("A")
            .font(.system(size: CGFloat(40)))
        }
        .onChange(of: fontMultiplier) { newValue in
          // User has changed the position of the slider
          print("[PreferencesView] New value of text size slider: \(newValue)")
          
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
          printCurrentTextSizePrefences()
        }
        Text(selectPercent)
          .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      }
      .accessibilityLabel(tsx.selectS)
    }
    .padding(.bottom, 50)
    .padding(.horizontal, 40)
  }
  
  func resetAppPrefences() {
    print("[PreferencesView] Resetting app preferences to defaults")
    resetLanguageToDefault()
    resetTextSizeToDefault()
  }
  
  func resetLanguageToDefault() {
    // Currently we do not reset language
  }
  
  func resetTextSizeToDefault() {
    print("[PreferencesView] Set text size to default")
    selectPercent = "100%"
    fontMultiplier = 1.0
  }
  
  func printCurrentTextSizePrefences() {
    print(
      """
      [PreferencesView] Current setFontSize: \(setFontSize)
      [PreferencesView] Current fontMultiplier: \(fontMultiplier)
      [PreferencesView] Current selectPercent: \(selectPercent)
      """
    )
  }
}

// #Preview {
//    PreferencesView()
// }

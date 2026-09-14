//
//  TPPReaderSettingsVC.swift
//  Palace
//
//  Created by Vladimir Fedorov on 02.02.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import UIKit
import SwiftUI
import ReadiumNavigator
import ReadiumShared

protocol TPPReaderSettingsDelegate: AnyObject {
    func getPreferences() -> EPUBPreferences
    func submitPreferences(_ preferences: EPUBPreferences)
    func setUIColor(for theme: Theme?)
}

class TPPReaderSettingsVC: UIViewController {
  static func makeSwiftUIView(preferences: EPUBPreferences, delegate: TPPReaderSettingsDelegate) -> UIViewController {
    let readerSettings = TPPReaderSettings(preferences: preferences, delegate: delegate)
    let controller = UIHostingController(rootView: TPPReaderSettingsView(settings: readerSettings))
    return controller
  }
}

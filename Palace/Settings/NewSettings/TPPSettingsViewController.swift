//
//  TPPSettingsViewController.swift
//  Palace
//
//  Created by Maurice Carrier on 12/2/21.
//  Copyright © 2021 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI

class TPPSettingsViewController: NSObject {
  
  @objc static func makeSwiftUIView(dismissHandler: @escaping (() -> Void)) -> UIViewController {
    let controller = UIHostingController(rootView: TPPSettingsView())
    controller.title = Strings.Settings.settingsNavTitle
    controller.tabBarItem.image = UIImage(named: "Settings")
    controller.tabBarItem.selectedImage = UIImage(named: "SettingsSelected")
    controller.tabBarItem.imageInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)
    controller.navigationItem.backButtonTitle = Strings.Settings.settingsNavTitle
    
    // On iPad iOS 26+, the floating tab bar already shows the title,
    // so the extra label is redundant.
    if #available(iOS 26, *) {
      // On iOS 26, use standard nav bar title (no custom label needed)
    } else {
      let titleViewLabel = UILabel()
      titleViewLabel.text = Strings.Settings.settingsNavTitle
      titleViewLabel.font = UIFont.palaceFont(ofSize: 16)
      titleViewLabel.accessibilityTraits = .header
      controller.navigationItem.titleView = titleViewLabel
    }
   
    let navigationController = UINavigationController(rootViewController: controller)
    return navigationController
  }
  
}

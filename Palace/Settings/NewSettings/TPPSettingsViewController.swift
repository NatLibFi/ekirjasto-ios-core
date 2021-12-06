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
  @objc static func makeSwiftUIVIew(dismissHandler: @escaping (() -> Void)) -> UINavigationController {
    let controller = UIHostingController(rootView: TPPSettingsView())
    controller.title = NSLocalizedString("Settings", comment: "")
    controller.tabBarItem.image = UIImage(named: "Settings")
    let navigationController = UINavigationController(rootViewController: controller)

    return navigationController
  }
}

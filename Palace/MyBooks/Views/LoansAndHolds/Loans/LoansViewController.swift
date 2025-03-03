//
//  LoansViewController.swift
//  Palace
//
//  Created by Maurice Carrier on 1/4/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI

class LoansViewController: NSObject {
  @MainActor @objc static func makeSwiftUIView(dismissHandler: @escaping (() -> Void)) -> UIViewController {
    let controller = UIHostingController(rootView: LoansView(loansViewModel: LoansViewModel()))
    controller.title = Strings.MyBooksView.navTitle
    controller.tabBarItem.image = UIImage(named: "MyBooks")
    controller.tabBarItem.selectedImage = UIImage(named: "MyBooksSelected")
    controller.tabBarItem.imageInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0);
    controller.navigationItem.backButtonTitle = NSLocalizedString("Back", comment: "Back button")
    controller.navigationItem.titleView?.tintColor = UIColor(named: "ColorEkirjastoBlack")
    return UINavigationController(rootViewController: controller)
  }
}

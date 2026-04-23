//
//  EkirjastoMagazineNavigationController.swift
//  Ekirjasto
//
//  Created by Johannes Ylönen on 18.3.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

class EkirjastoMagazineNavigationController: TPPLibraryNavigationController {

  override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)

    navigationBar.isHidden = true

    // On iPad iOS 26, add extra top inset so the web content clears
    // the floating tab bar. The web app renders its own navigation UI.
    if #available(iOS 26, *), UIDevice.current.userInterfaceIdiom == .pad {
      rootViewController.additionalSafeAreaInsets = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
    }
    
    tabBarItem.title = NSLocalizedString("Magazines", comment: "")
    tabBarItem.image = UIImage(named: "Magazines")
    tabBarItem.selectedImage = UIImage(named: "MagazinesSelected")
    tabBarItem.imageInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)
    
    NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged), name: NSNotification.Name(rawValue: NSNotification.TPPCurrentAccountDidChange.rawValue), object: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func popToRoot() {
    guard let vc = self.visibleViewController as? DigitalMagazineBrowserViewController else {
      return
    }
    
    vc.popToRoot()
  }
  
  @objc func currentAccountChanged() {
    if !Thread.isMainThread {
      DispatchQueue.main.async {
        self.popToRootViewController(animated: false)
      }
    } else {
      self.popToRootViewController(animated: false)
    }
  }
}

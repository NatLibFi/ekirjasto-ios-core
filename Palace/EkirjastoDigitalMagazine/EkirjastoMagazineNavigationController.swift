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
    
    tabBarItem.title = NSLocalizedString("Magazines", comment: "")
    tabBarItem.image = UIImage(named: "Magazines")
    tabBarItem.selectedImage = UIImage(named: "MagazinesSelected")
    tabBarItem.imageInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: -8.0, right: 0.0)
    
    NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged), name: NSNotification.Name(rawValue: NSNotification.TPPCurrentAccountDidChange.rawValue), object: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
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

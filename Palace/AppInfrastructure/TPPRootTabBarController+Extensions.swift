//
//  TPPRootTabBarController+Extensions.swift
//

import UIKit

@objc extension TPPRootTabBarController {
  
  // Called when app user interface environment has changed
  @objc(handleTraitCollectionChange:)  //<- objc name for the function
  func handleTraitCollectionChange(previousTraitCollection: UITraitCollection) {
    
    if appAppearanceHasChanged() {
      printToConsole(.info, "App appearance was toggled")
      handleUserInterfaceStyleChange()
    }
    
    // other trait collection changes could also
    // be checked and handled here
    // besides the user interface change
    
    
    // MARK: - Trait collection change handlers
    
    // User has switched between dark and light mode
    // which means that the user interface style has changed
    func handleUserInterfaceStyleChange() {
      
      // Logging the current appearance, just info for developer
      logCurrentAppAppearance()
      
      // Always update the tab bar appearance after toggling
      updateTabBarAppearance()
    }
    
    // MARK: - Helpers for app appearance (UI style change)
    
    
    // Tab bar is the bottom navigation bar in app,
    // currently only tab bar item icons need to be updated
    func updateTabBarAppearance() {
      printToConsole(.info, "Updating tab bar appearance")
      
      // Mapping the tab bar item's index number with correct image set.
      // Needs to be updated if tabs, tab order, or the icon names ever change...
      let tabBarItemImages: [Int: (image: String, selectedImage: String)] = [
        0: ("Catalog", "CatalogSelected"),
        1: ("LoansAndHolds", "LoansAndHoldsSelected"),
        2: ("Favorites", "FavoritesSelected"),
        3: ("Magazines", "MagazinesSelected"),
        4: ("Settings", "SettingsSelected"),
      ]
      
      // Handle all the tabs in tab bar one by one
      for (index, tabBarItem) in self.tabBar.items!.enumerated() {
        
        // Get the icon images for this tab bar item
        if let itemIcons = tabBarItemImages[index] {
          
          // and set one icon for the tab when it's default icon is visible
          tabBarItem.image = UIImage(named: itemIcons.image)?.withRenderingMode(
            .alwaysOriginal)
          
          // and another icon that appears when the tab is the selected tab
          tabBarItem.selectedImage = UIImage(named: itemIcons.selectedImage)?
            .withRenderingMode(.alwaysOriginal)
        }
        
      }
      
    }
    
    // If the trait collection change concerns the UI style,
    // then app appearance has changed
    func appAppearanceHasChanged() -> Bool {
      return self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle
    }
    
    // Possible appearance styles are light, dark and unspecified
    func logCurrentAppAppearance() -> Void {
      switch self.traitCollection.userInterfaceStyle {
        case .dark:
          printToConsole(.info, "App appearance set to dark mode")
        case .light:
          printToConsole(.info, "App appearance set to light mode")
        case .unspecified:
          printToConsole(.info, "App appearance set to unspecified mode")
      }
      
    }
    
  }
  
}

//
//  TPPRootTabBarController+Extensions.swift
//
//  Tab bar is the main navigation bar in app.

import UIKit

@objc extension TPPRootTabBarController {

  // Called when app user interface environment has changed.
  @objc(handleTraitCollectionChange:)  //<- objc name for the function
  func handleTraitCollectionChange(previousTraitCollection: UITraitCollection) {

    // Logging the current appearance and traits for development
    // logCurrentAppAppearance()
    // logCurrentDeviceTraits()

    handleUserInterfaceStyleChange()

    // MARK: - Functions to modify app appearance

    // User has switched between dark and light mode
    // which means that the user interface style has changed
    func handleUserInterfaceStyleChange() {

      if appAppearanceHasChanged() {
        printToConsole(.info, "App appearance was toggled")

        // Always update the tab bar appearance after toggling
        updateTabBarAppearance()
      }

    }

    // MARK: - Helpers for app appearance (UI style)

    // This is a temporary fix that forces tab bar icons to update
    // after toggling to device to dark mode and vice versa
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

    // MARK: - Boolean helpers

    // If the trait collection change concerns the UI style,
    // then app appearance has changed
    func appAppearanceHasChanged() -> Bool {
      return self.traitCollection.userInterfaceStyle
        != previousTraitCollection.userInterfaceStyle
    }

    // MARK: - Logging helpers

    // Possible appearance styles are light, dark and unspecified
    func logCurrentAppAppearance() {
      switch self.traitCollection.userInterfaceStyle {
        case .dark:
          printToConsole(.info, "App appearance set to dark mode")
        case .light:
          printToConsole(.info, "App appearance set to light mode")
        case .unspecified:
          printToConsole(.info, "App appearance set to unspecified mode")
        }
    }

    // Logs info about current device
    func logCurrentDeviceTraits() {
      logDeviceModel()
      logDeviceSystemAndVersion()
      logDeviceHorizontalSizeClass()
      logDeviceInterfaceType()
    }

    // Logs iOS version, for example 18.5
    func logDeviceSystemAndVersion() {
      #if os(iOS)
        printToConsole(.info, "Current device operating system: iOS")
      #else
        printToConsole(.info, "Current device operating system: not iOS")
      #endif

      printToConsole(.info, "Current device system version: \(UIDevice.current.systemVersion)")
    }

    // Logs name for the Apple device, such as iPhone or iPad
    func logDeviceModel() {
      printToConsole(.info, "Current device model: \(UIDevice.current.model)")
    }

    // Logs the horizontal space currently available to the app.
    // Pads normally use regular, but can change to compact,
    // for example if screen is split in iPad with other applications.
    func logDeviceHorizontalSizeClass() {
      switch self.traitCollection.horizontalSizeClass {
      case .compact:
        printToConsole(.info, "Current device horizontal size class: compact")
      case .regular:
        printToConsole(.info, "Current device horizontal size class: regular")
      case .unspecified:
        printToConsole(
          .info, "Current device horizontal size class: unspecified")
      }
    }

    // Logs the type of interface used, such as pad or phone
    func logDeviceInterfaceType() {
      switch UIDevice.current.userInterfaceIdiom {
      case .pad:
        printToConsole(.info, "Current device interface type: pad")
      case .phone:
        printToConsole(.info, "Current device interface type: phone")
      default:
        printToConsole(
          .info,
          "Current device interface type: mac, tv, vision, carPlay or unspecified"
        )
      }
    }

  }

}

//
//  FavoritesMainView.swift
//

import SwiftUI

struct FavoritesMainView: View {

  @State private var orientation: UIDeviceOrientation = UIDevice.current
    .orientation
  @ObservedObject var favoritesViewModel: FavoritesViewModel

  let backgroundColor: Color = Color(TPPConfiguration.backgroundColor())

  var body: some View {

    ContentView
      .navigationBarItems(leading: EKirjastoButton)
      .navigationBarTitle(Strings.MyBooksView.favoritesAndReadNavTitle)
      .onReceive(
        NotificationCenter.default.publisher(
          for: UIDevice.orientationDidChangeNotification)
      ) { _ in
        self.orientation = UIDevice.current.orientation
      }

  }

  @ViewBuilder private var ContentView: some View {

    FavoritesSubview

  }

  @ViewBuilder private var EKirjastoButton: some View {
    Button {
      TPPRootTabBarController.shared().showAndReloadCatalogViewController()
    } label: {
      ImageProviders.MyBooksView.myLibraryIcon
        .accessibilityLabel(
          Strings.MyBooksView.accessibilityShowAndReloadCatalogTab)
    }
  }

  @ViewBuilder private var FavoritesSubview: some View {
    FavoritesView(favoritesViewModel: favoritesViewModel)
  }

}

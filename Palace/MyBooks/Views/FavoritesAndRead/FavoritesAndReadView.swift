//
//  FavoritesAndReadView.swift
//

import SwiftUI

struct FavoritesAndReadView: View {

  @State private var orientation: UIDeviceOrientation = UIDevice.current
    .orientation
  @ObservedObject var favoritesViewModel: FavoritesViewModel
  /* Code for future feature: read books
  @ObservedObject var readViewModel: ReadViewModel
  */

  /* Code for future feature: read books
  var subviews = ["Favorites", "Read"]
  @State private var selectedSubview = "Favorites"
  */

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

   /* Code for future feature: read books
    SegmentedPicker

    switch selectedSubview {
      case "Favorites":
        FavoritesSubview
      case "Read":
        ReadSubview
      default:
        FavoritesSubview
    }
    */

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

  /* Code for future feature: read books
     Remove top padding from facet view in favorites view,
     if picker is used
  @ViewBuilder private var SegmentedPicker: some View {
    VStack {
      Picker(
        "View list of books added to favorites",
        selection: $selectedSubview
      ) {
        ForEach(subviews, id: \.self) {
          Text($0)
        }
      }
      .pickerStyle(.segmented)
      .padding(15)
    }
    .background(backgroundColor)
  }
  */

  @ViewBuilder private var FavoritesSubview: some View {
    FavoritesView(favoritesViewModel: favoritesViewModel)
  }

  /* Code for future feature: read books
  @ViewBuilder private var ReadSubview: some View {
    ReadView(readViewModel: readViewModel)
  }
  */

}

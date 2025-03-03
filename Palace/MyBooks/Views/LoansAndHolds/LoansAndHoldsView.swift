//
//  LoansAndHoldsView.swift
//

import SwiftUI

struct LoansAndHoldsView: View {

  @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
  @ObservedObject var loansViewModel: LoansViewModel

  var subviews = ["Loans", "Holds"]
  @State private var selectedSubview = "Loans"

  var body: some View {

    ContentView
      .navigationBarItems(leading: EKirjastoButton)
      .navigationBarTitle(Strings.MyBooksView.navTitle)
      .onReceive(
        NotificationCenter.default.publisher(
          for: UIDevice.orientationDidChangeNotification)
      ) { _ in
        self.orientation = UIDevice.current.orientation
      }

  }
  

  @ViewBuilder private var ContentView: some View {

    SegmentedPicker

    switch selectedSubview {
    case "Loans":
      LoansSubview
    case "Holds":
      HoldsSubview
    default:
      LoansSubview
    }

  }

  
  @ViewBuilder private var EKirjastoButton: some View {
    Button {
      TPPRootTabBarController
        .shared()
        .showAndReloadCatalogViewController()
    } label: {
      ImageProviders.MyBooksView.myLibraryIcon
    }
  }

  
  @ViewBuilder private var SegmentedPicker: some View {
    VStack {
      Picker(
        "View list of books on loan or list of books on hold",
        selection: $selectedSubview
      ) {
        ForEach(subviews, id: \.self) {
          Text($0)
        }
      }
      .pickerStyle(.segmented)
    }
  }

  
  @ViewBuilder private var LoansSubview: some View {
    LoansView(loansViewModel: loansViewModel)
  }

  
  @ViewBuilder private var HoldsSubview: some View {
    HoldsControllerRepresentable()
  }

  
}


extension View {
  func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
    overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
  }
}

struct EdgeBorder: Shape {
  var width: CGFloat
  var edges: [Edge]

  func path(in rect: CGRect) -> Path {
    var path = Path()
    for edge in edges {
      var x: CGFloat {
        switch edge {
        case .top, .bottom, .leading: return rect.minX
        case .trailing: return rect.maxX - width
        }
      }

      var y: CGFloat {
        switch edge {
        case .top, .leading, .trailing: return rect.minY
        case .bottom: return rect.maxY - width
        }
      }

      var w: CGFloat {
        switch edge {
        case .top, .bottom: return rect.width
        case .leading, .trailing: return width
        }
      }

      var h: CGFloat {
        switch edge {
        case .top, .bottom: return width
        case .leading, .trailing: return rect.height
        }
      }
      path.addRect(CGRect(x: x, y: y, width: w, height: h))
    }
    
    return path
  }
  
}

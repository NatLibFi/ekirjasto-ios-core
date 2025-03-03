//
//  FacetView.swift
//  Palace
//
//  Created by Maurice Carrer on 12/23/22.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import SwiftUI
import Combine

struct FacetView: View {
  @ObservedObject var facetViewModel: FacetViewModel
  @State private var showAlert = false

  var body: some View {
    VStack(alignment: .leading) {
      dividerView
      HStack(alignment: .center) {
        titleLabel
        sortView
      }
      .padding(.leading)
      .actionSheet(isPresented: $showAlert) { alert }
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
      dividerView
      //accountLogoView
      //  .horizontallyCentered() //Disabled by Ellibs
    }
  }

  private var titleLabel: some View {
    Text(facetViewModel.groupName)
  }

  private var sortView: some View {
    Button(action: {
      showAlert = true
    }) {
      Text(facetViewModel.activeSort.localizedString)
        .font(Font(uiFont: UIFont.boldPalaceFont(ofSize: 13)))
      Image("ArrowDown")
        .resizable()
        .scaledToFill()
        .frame(width: 19, height: 19)
        .foregroundColor(Color("ColorEkirjastoGreen"))
        .padding(EdgeInsets(top: 1, leading: -8, bottom: -1, trailing: 8))
    }
    //.frame(width: 65, height: 30)
    //.border(Color(TPPConfiguration.mainColor()), width: 1)
    //.cornerRadius(2)
  }
  
  private var dividerView: some View {
    Rectangle()
      .fill(Color("ColorEkirjastoLightestGreen"))
      .frame(height: 1.0)
      .edgesIgnoringSafeArea(.horizontal)
  }

  private var alert: ActionSheet {
    var buttons = [ActionSheet.Button]()

    if let secondaryFacet = facetViewModel.facets.first(where: { $0 != facetViewModel.activeSort }) {
      buttons.append(ActionSheet.Button.default(Text(secondaryFacet.localizedString)) {
        self.facetViewModel.activeSort = secondaryFacet
      })

      buttons.append(Alert.Button.default(Text(facetViewModel.activeSort.localizedString)) {
        self.facetViewModel.activeSort = facetViewModel.activeSort
      })
    } else {
      buttons.append(ActionSheet.Button.cancel(Text(Strings.Generic.cancel)))
    }

    return ActionSheet(title: Text(""), message: Text(""), buttons:buttons)
  }
  
  @ViewBuilder private var accountLogoView: some View {
    if let account = facetViewModel.currentAccount {
      Button {
        facetViewModel.showAccountScreen = true
      } label: {
          HStack {
            Image(uiImage: facetViewModel.logo ?? UIImage())
              .resizable()
              .aspectRatio(contentMode: .fit)
              .square(length: 50)
            Text(account.name)
              .fixedSize(horizontal: false, vertical: true)
              .font(Font(uiFont: UIFont.boldSystemFont(ofSize: 18.0)))
              .foregroundColor(.gray)
              .multilineTextAlignment(.center)
          }
          .padding()
          .background(Color(TPPConfiguration.readerBackgroundColor()))
          .frame(height: 70.0)
          .cornerRadius(35)
        }
    }
  }
}

//
//  FacetView.swift
//  Palace
//
//  Created by Maurice Carrer on 12/23/22.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Combine
import SwiftUI

struct FacetView: View {
  @ObservedObject var facetViewModel: FacetViewModel
  @State private var showAlert = false

  var body: some View {

    VStack(alignment: .leading) {
      HStack(alignment: .center) {
        titleLabel
        sortView
      }
      .padding(.leading)
      .actionSheet(isPresented: $showAlert) { alert }
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
    }

  }

  private var titleLabel: some View {
    Text(facetViewModel.groupName)
  }

  private var sortView: some View {

    //Create the button with the active sort option shown
    Button(action: {
      showAlert = true
    }) {
      Text(facetViewModel.activeSort.localizedString)
        .font(Font(uiFont: UIFont.boldPalaceFont(ofSize: 13)))
        .accessibilityHint(String.localizedStringWithFormat(Strings.FacetView.facetHint, facetViewModel.groupName))
      Image("ArrowDown")
        .resizable()
        .scaledToFill()
        .frame(width: 19, height: 19)
        .foregroundColor(Color("ColorEkirjastoBlack"))
        .padding(EdgeInsets(top: 1, leading: -8, bottom: -1, trailing: 8))
    }

  }

  private var alert: ActionSheet {
    var buttons = [ActionSheet.Button]()

    if let secondaryFacet = facetViewModel.facets.first(where: {
      $0 != facetViewModel.activeSort
    }) {
      buttons.append(
        ActionSheet.Button.default(Text(secondaryFacet.localizedString)) {
          self.facetViewModel.activeSort = secondaryFacet
        })

      buttons.append(
        ActionSheet.Button.default(Text(facetViewModel.activeSort.localizedString)) {
          self.facetViewModel.activeSort = facetViewModel.activeSort
        })
    }

    buttons.append(ActionSheet.Button.cancel(Text(Strings.Generic.cancel)))

    return ActionSheet(
      title: Text(Strings.MyBooksView.sortBy), buttons: buttons)
  }

}

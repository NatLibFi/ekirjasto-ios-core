//
//  ButtonView.swift
//  Palace
//
//  Created by Maurice Carrier on 2/8/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import SwiftUI

struct ButtonView: View {

  var title: String
  var indicatorDate: Date? = nil
  var backgroundFill: Color? = nil
  var action: () -> Void

  private var accessiblityString: String {
    guard let untilDate = indicatorDate?.timeUntilString(suffixType: .long)
    else {
      return title
    }

    return "\(title).\(untilDate) remaining"
  }

  var body: some View {
    Button(action: action) {
      HStack(alignment: .center, spacing: 5) {
        //indicatorView
        Text(title)
      }
      .padding(8)
      .frame(minWidth: 0, maxWidth: .infinity)
    }
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 14)))
    .foregroundColor(indicatorDate != nil
        ? Color("ColorEkirjastoButtonTextWithBackground")
        : Color("ColorEkirjastoLabel")
    )
    .buttonStyle(
      AnimatedButton(backgroundColor: indicatorDate != nil
        ? Color("ColorEkirjastoLightestGreen")
        : backgroundFill)
    )
    .accessibilityLabel(accessiblityString)
  }

  /*
   This view is not currently used in My books views,
   as loan time is shown separately and
   not as a small clock indicator inside "Read" or "Download" button
   */
  @ViewBuilder private var indicatorView: some View {
    if let endDate = indicatorDate?.timeUntilString(suffixType: .short) {
      VStack(spacing: 2) {
        ImageProviders.MyBooksView.clock
          .resizable()
          .square(length: 14)
          .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        Text(endDate)
          .font(Font(uiFont: UIFont.palaceFont(ofSize: 9)))
          .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
      }
    }
  }
}

struct IconButtonView: View {

  var buttonImageForSelectedBook: Image = ImageProviders.MyBooksView.selectionIconCheck
  var buttonImageForUnselectedBook: Image = ImageProviders.MyBooksView.selectionIconPlus
  var title: String
  var indicatorDate: Date? = nil
  var backgroundFill: Color? = nil
  var action: () -> Void

  var body: some View {
    Button(action: action) {

      HStack(alignment: .center) {
        if title == "Select" {
          buttonImageForUnselectedBook
            .resizable()
            .square(length: 25)
            .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        } else if title == "Unselect" {
          buttonImageForSelectedBook
            .resizable()
            .square(length: 25)
            .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
        } else {
          EmptyView()
        }
      }
    }
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 14)))
    .fixedSize()
    .foregroundColor(
      indicatorDate != nil
        ? Color("ColorEkirjastoButtonTextWithBackground")
        : Color("ColorEkirjastoLabel")
    )
    .buttonStyle(
      AnimatedButtonWithoutOverlay(
        backgroundColor: indicatorDate != nil
          ? Color("ColorEkirjastoLightestGreen")
          : backgroundFill)
    )
    .accessibilityLabel(
      title == "Select"
      ? Strings.BookCell.removeFromFavoritesButtonLabel
      : Strings.BookCell.addToFavoritesButtonLabel
    )
  }
}

struct AnimatedButton: ButtonStyle {
  var backgroundColor: Color? = nil

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(height: 35)
      .buttonStyle(.plain)
      .background(backgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: 3)
          .stroke(Color("ColorEkirjastoGreen"), lineWidth: 1)
      )
      .opacity(configuration.isPressed ? 0.5 : 1.0)
  }
}

struct AnimatedButtonWithoutOverlay: ButtonStyle {
  var backgroundColor: Color? = nil

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(height: 35)
      .buttonStyle(.plain)
      .background(backgroundColor)
      .opacity(configuration.isPressed ? 0.5 : 1.0)
  }
}

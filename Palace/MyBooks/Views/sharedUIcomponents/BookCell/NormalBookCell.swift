//
//  NormalBookCell.swift
//  Palace
//
//  Created by Maurice Carrier on 2/8/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Combine
import SwiftUI

struct NormalBookCell: View {
  @ObservedObject var model: BookCellModel
  private let cellHeightWithInfoText: CGFloat = 240
  private let cellHeightWithoutInfoText: CGFloat = 210
  private let imageViewWidth: CGFloat = 100

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        unreadImageView
        titleCoverImageView
        VStack(alignment: .leading) {
          bookInfoView
          Spacer()
        }
        .padding(.leading, 8)
        .alert(item: $model.showAlert) { alert in
          Alert(
            title: Text(alert.title),
            message: Text(alert.message),
            primaryButton: .default(
              Text(alert.buttonTitle ?? ""), action: alert.primaryAction),
            secondaryButton: .cancel(alert.secondaryAction)
          )
        }
      }
      primaryButtonsView
      bookStateInfoView
      Spacer()
    }
    .multilineTextAlignment(.leading)
    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
    .frame(
      height: bookHasInfoText()
        ? cellHeightWithInfoText
        : cellHeightWithoutInfoText
    )
    .onDisappear { model.isLoading = false }
  }

  @ViewBuilder private var unreadImageView: some View {
    VStack {
      ImageProviders.MyBooksView.unreadBadge
        .resizable()
        .frame(width: 10, height: 10)
        .foregroundColor(Color(TPPConfiguration.accentColor()))
      Spacer()
    }
    .opacity(0.0)
  }

  @ViewBuilder private var titleCoverImageView: some View {
    ZStack {
      Image(uiImage: model.image)
        .resizable()
        .scaledToFit()
        .frame(height: 125, alignment: .top)
      audiobookIndicator
    }
    .frame(width: imageViewWidth)
    .padding(.trailing, 2)

  }

  @ViewBuilder private var bookInfoView: some View {
    VStack(alignment: .leading) {
      Text(model.title)
        .lineLimit(2)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 17)))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(
          model.book.defaultBookContentType == .audiobook
            ? "\(model.book.title). Audiobook."
            : model.book.title)
      Text(model.authors)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
    }.padding(.leading, 10)
  }

  @ViewBuilder private var primaryButtonsView: some View {
    GeometryReader { geometry in
      HStack {
        ForEach(model.buttonTypes, id: \.self) { type in
          ButtonView(
            title: type.localizedTitle,
            indicatorDate: model.indicatorDate(for: type),
            action: { model.callDelegate(for: type) }
          )
          .frame(minWidth: 0, maxWidth: geometry.size.width / 2)
          .disabled(type.isDisabled)
          .opacity(type.isDisabled ? 0.5 : 1.0)
        }
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 10)
      .padding(.top, 10)
    }
  }

  @ViewBuilder private var bookStateInfoView: some View {

    let infoText: String = getInfoText()
    let infoBackgroundColor: Color = getInfoBackgroundColor()

    if infoText.isEmpty {
      EmptyView()
    } else {
      VStack(alignment: .leading) {
        Text(infoText)
          .foregroundColor(Color("ColorEkirjastoButtonTextWithBackground"))
          .font(Font(uiFont: UIFont.palaceFont(ofSize: 15)))
      }
      .frame(height: 35)
      .frame(minWidth: 0, maxWidth: .infinity)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .background(infoBackgroundColor)
      .padding(.leading, 10)
      .padding(.top, 5)
      .padding(.bottom, 5)

    }
  }

  @ViewBuilder private var audiobookIndicator: some View {
    if model.book.defaultBookContentType == .audiobook {
      ImageProviders.MyBooksView.audiobookBadge
        .resizable()
        .frame(width: 30, height: 30)
        .background(Color(UIColor(named: "ColorEkirjastoIcon")!))
        .border(
          width: 1.5, edges: [.top, .bottom, .leading, .trailing],
          color: Color.white
        )
        .bottomrRightJustified()
        .padding(.trailing, -6)
        .padding(.bottom, 32)
    }
  }

  /// Helper functions

  private func bookHasInfoText() -> Bool {
    let infoText: String = getInfoText()
    return !infoText.isEmpty
  }

  private func getInfoText() -> String {
    let bookButtonState: BookButtonState = model.bookCellBookButtonState(
      book: model.book)

    switch bookButtonState {

    case .holding:
      return getHoldPositionInfoText()

    case .holdingFrontOfQueue:
      return getAvailableToBorrowInfoText()

    case .downloadNeeded, .downloadSuccessful:
      return getLoanTimeLeftInfoText()

    default:
      return ""
    }

  }

  private func getInfoBackgroundColor() -> Color {
    let bookButtonState: BookButtonState = model.bookCellBookButtonState(
      book: model.book)

    switch bookButtonState {

    case .holding:
      return Color("ColorEkirjastoLightGrey")

    case .holdingFrontOfQueue:
      return Color("ColorEkirjastoYellow")

    case .downloadNeeded, .downloadSuccessful:
      return Color("ColorEkirjastoYellow")

    default:
      return Color.clear

    }
  }

  private func getLoanTimeLeftInfoText() -> String {
    let timeUntilString: String =
      model.indicatorDate(for: .read)?.timeUntilString(suffixType: .long) ?? ""

    let loanTimeInfoText: String =
      timeUntilString.isEmpty
      ? Strings.BookCell.loanTimeNotAvailable
      : String.localizedStringWithFormat(
        Strings.BookCell.loanTimeRemaining, timeUntilString)

    return loanTimeInfoText
  }

  private func getHoldPositionInfoText() -> String {
    var holdPositionInfoText: String = ""
    var holdPosition: UInt?
    //var copiesTotal: TPPOPDSAcquisitionAvailabilityCopies?

    model.book.defaultAcquisition?.availability.matchUnavailable(
      nil,
      limited: nil,
      unlimited: nil,
      reserved: { reservedAvailability in
        holdPosition = reservedAvailability.holdPosition
        //copiesTotal = reservedAvailability.copiesTotal
      },
      ready: nil
    )

    // use copiesTotal here, if number of book copies is needed in infoText
    if let bookHoldPosition = holdPosition {
      holdPositionInfoText = String.localizedStringWithFormat(
        Strings.BookCell.bookHoldPosition, String(bookHoldPosition))
    } else {
      holdPositionInfoText = Strings.BookCell.bookIsOnHoldForUser
    }

    return holdPositionInfoText
  }

  private func getAvailableToBorrowInfoText() -> String {
    return Strings.BookCell.bookIsAvailableToBorrow
  }

}

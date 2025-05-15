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
  private let normalCellHeightForPhone: CGFloat = 200
  private let largerCellHeightForPhone: CGFloat = 250
  private let largestCellHeightForPhone: CGFloat = 275
  private let normalCellHeightForPad: CGFloat = 250
  private let largerCellHeightForPad: CGFloat = 275
  private let imageViewWidth: CGFloat = 100
  private let fontMultiplier: CGFloat = UserDefaults.standard.double(forKey: "fontMultiplier")

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        //unreadImageView
        titleCoverImageView
        VStack(alignment: .leading) {
          HStack(alignment: .top) {
            bookInfoView
            Spacer()
            secondaryButtonsView
          }
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
      .padding(.top, 10)
      primaryButtonsView
      Spacer()
      bookStateInfoView
      Spacer()
    }
    .multilineTextAlignment(.leading)
    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
    .frame(
      height: bookCellHeight()
    )
    .onDisappear { model.isLoading = false }
  }

  // This unread indicator view (=small blue badge besides book cover image)
  // is not currently used in app
  @ViewBuilder private var unreadImageView: some View {
    VStack {
      ImageProviders.MyBooksView.unreadBadge
        .resizable()
        .frame(width: 10, height: 10)
        .foregroundColor(Color(TPPConfiguration.accentColor()))
      Spacer()
    }
    .opacity(model.showUnreadIndicator ? 1.0 : 0.0)
  }

  @ViewBuilder private var titleCoverImageView: some View {
    ZStack {
      Image(uiImage: model.image)
        .resizable()
        .scaledToFit()
        .frame(height: 125, alignment: .top)
      audiobookIndicator
    }
    .frame(width: imageViewWidth, alignment: .topLeading)
    .padding(.leading, 15)
    .padding(.trailing, 2)

  }

  // Note! No subtitle visible in My books view, only title, format and authors
  @ViewBuilder private var bookInfoView: some View {
    VStack(alignment: .leading) {
      Text(model.title)
        .lineLimit(fontMultiplier > 1 ? 1 : 3)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 18)))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(
          model.book.defaultBookContentType == .audiobook
            ? "\(model.book.title). Audiobook."
            : model.book.title
        )
        .padding(.bottom, 2)
      Text(model.book.generalBookFormat)
        .lineLimit(1)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 14)))
        .padding(.bottom, 2)
      Text(model.authors)
        .lineLimit(fontMultiplier > 1 ? 1 : 2)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
        .padding(.bottom, 2)
    }
    .padding(.leading, 10)
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
      .padding(.bottom, 5)
    }
  }

  @ViewBuilder private var secondaryButtonsView: some View {
    HStack {
      ForEach(model.secondaryButtonTypes, id: \.self) { type in
        IconButtonView(
          title: type.localizedTitle,
          indicatorDate: model.indicatorDate(for: type),
          action: { model.callDelegate(for: type) }
        )
        .disabled(type.isDisabled)
        .opacity(type.isDisabled ? 0.5 : 1.0)
      }
    }
    .padding(.leading, 10)
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
        .padding(.trailing, -10)
        .padding(.bottom, 13)
    }
  }

  /// Helper functions

  private func bookCellHeight() -> CGFloat {
    let device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    let infoText: String = getInfoText()

    switch device {

      case .pad:
        return (fontMultiplier > 1)
        ? largerCellHeightForPad
        : normalCellHeightForPad

      case .phone:

        return (fontMultiplier > 1)
        // user has increased font size,
        // show even larger book cells
        ? (infoText.isEmpty
            ? largerCellHeightForPhone
            : largestCellHeightForPhone)
        // user has the default font size
        : (infoText.isEmpty
            ? normalCellHeightForPhone
            : largerCellHeightForPhone)

      default:
        return 250
    }

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

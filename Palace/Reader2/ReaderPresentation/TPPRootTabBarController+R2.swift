//
//  TPPRootTabBarController+R2.swift
//  The Palace Project
//
//  Created by Ettore Pasquini on 3/4/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

@objc
extension TPPRootTabBarController {

  func presentBook(_ book: TPPBook) {

    guard
      let libraryService = r2Owner?.libraryService,
      let readerModule = r2Owner?.readerModule
    else {
      return
    }

    libraryService.openBook(
      book,
      sender: self
    ) { [weak self] result in

      guard let navVC = self?.selectedViewController as? UINavigationController
      else {
        preconditionFailure("No navigation controller, unable to present reader")
      }

      switch result {

        case .success(let publication):
          readerModule.presentPublication(
            publication,
            book: book,
            in: navVC,
            forSample: false
          )

        case .cancelled:
          // .cancelled is returned when publication has restricted access
          // to its resources and can't be rendered

          TPPErrorLogger.logError(
            nil,
            summary: "Error accessing book resources",
            metadata: [
              "book": book.loggableDictionary
            ]
          )

          let alertTitle = Strings.OpenBook.unableToOpenBookAlertTitle

          let alertMessage = String.localizedStringWithFormat(
            Strings.OpenBook.unableToOpenBookAlertMessage,
            book.title
          )

          let alertController = TPPAlertUtils.alert(
            title: alertTitle,
            message: alertMessage
          )

          TPPAlertUtils.presentFromViewControllerOrNil(
            alertController: alertController,
            viewController: self,
            animated: true,
            completion: nil
          )

        case .failure(let error):
          // .failure is retured for an error raised while trying to unlock publication
          // error is supposed to be visible to users,
          // it is defined by ContentProtection error property

          TPPErrorLogger.logError(
            error,
            summary: "Error accessing book resources",
            metadata: [
              "book": book.loggableDictionary
            ]
          )

          let alertTitle = Strings.OpenBook.unableToOpenBookAlertTitle

          let alertMessage = String.localizedStringWithFormat(
            Strings.OpenBook.unableToOpenBookAlertMessage,
            book.title
          )

          let errorMessage = String.localizedStringWithFormat(
            Strings.ErrorInformation.errorInformationAvailable,
            error.localizedDescription
          )

          let alertController = TPPAlertUtils.alert(
            title: alertTitle,
            message: "\(alertMessage)\n\n\(errorMessage)"
          )

          TPPAlertUtils.presentFromViewControllerOrNil(
            alertController: alertController,
            viewController: self,
            animated: true,
            completion: nil
          )

      }

    }

  }

  // Note: book samples are not currently used in E-kirjasto
  func presentSample(
    _ book: TPPBook,
    url: URL
  ) {

    guard
      let libraryService = r2Owner?.libraryService,
      let readerModule = r2Owner?.readerModule
    else {
      return
    }

    libraryService.openSample(
      book,
      sampleURL: url,
      sender: self
    ) { [weak self] result in

      guard let navVC = self?.selectedViewController as? UINavigationController
      else {
        preconditionFailure("No navigation controller, unable to present reader")
      }

      switch result {

        case .success(let publication):
          readerModule.presentPublication(
            publication,
            book: book,
            in: navVC,
            forSample: true
          )

        case .cancelled:
          // .cancelled is returned when publication has
          // restricted access to its resources and can't be rendered

          TPPErrorLogger.logError(
            nil,
            summary: "Error accessing book resources",
            metadata: [
              "book": book.loggableDictionary
            ]
          )

          let alertTitle = Strings.OpenSample.unableToOpenSampleAlertTitle

          let alertMessage = String.localizedStringWithFormat(
            Strings.OpenSample.unableToOpenSampleAlertMessage,
            book.title
          )

          let alertController = TPPAlertUtils.alert(
            title: alertTitle,
            message: alertMessage
          )

          TPPAlertUtils.presentFromViewControllerOrNil(
            alertController: alertController,
            viewController: self,
            animated: true,
            completion: nil
          )

        case .failure(let error):
          // .failure is retured for an error raised while trying to unlock publication
          // error is supposed to be visible to users,
          // it is defined by ContentProtection error property

          TPPErrorLogger.logError(
            error,
            summary: "Error accessing book resources",
            metadata: [
              "book": book.loggableDictionary
            ]
          )

          let alertTitle = Strings.OpenSample.unableToOpenSampleAlertTitle

          let alertMessage = String.localizedStringWithFormat(
            Strings.OpenSample.unableToOpenSampleAlertMessage,
            book.title
          )

          let errorMessage = String.localizedStringWithFormat(
            Strings.ErrorInformation.errorInformationAvailable,
            error.localizedDescription
          )

          let alertController = TPPAlertUtils.alert(
            title: alertTitle,
            message: "\(alertMessage)\n\n\(errorMessage)"
          )

          TPPAlertUtils.presentFromViewControllerOrNil(
            alertController: alertController,
            viewController: self,
            animated: true,
            completion: nil
          )

      }

    }

  }

}

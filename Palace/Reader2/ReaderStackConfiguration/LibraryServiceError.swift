//
//  LibraryServiceError.swift
//  The Palace Project
//
//  Created by Mickaël Menu on 12.06.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import ReadiumShared

#if LCP
  import ReadiumLCP
#endif

/// Errors that can occur while retrieving or opening a book publication.
///
/// This enum type helps to show more user-friendly application-level
/// error message in alerts
/// instead of errors produced by Readium or the underlying DRM services.
/// Used when presentBook or presentSample functions result in error.
enum LibraryServiceError: LocalizedError {

  /// The book is missing a valid URL
  /// or cannot be represented as a readable asset.
  case invalidBook

  /// Opening the book failed
  /// and the related error contains the underlying cause.
  case openFailed(Error)

  /// Formats a status date using the app's selected language and a long date style.
  private func localizedDateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: TPPSettings.appLanguage)
    formatter.dateStyle = .long
    formatter.timeStyle = .none

    return formatter.string(from: date)
  }

  /// Returns the localized message shown
  /// when the error is presented to the user in an alert.
  var errorDescription: String? {
    switch self {

    case .invalidBook:
      return Strings.Error.invalidBookError

    case .openFailed(let error):
      #if LCP
        guard
          let lcpError = error as? LCPError,
          case .licenseStatus(let statusError) = lcpError
        else {
          // not an LCP error or no status error available
          // just return default "sorry, open failed" error
          return Strings.Error.openFailedError
        }

        switch statusError {

        // the user has already returned the book
        case .returned(let date):
          let formattedDate = localizedDateString(date)

          return String.localizedStringWithFormat(
            Strings.Error.bookAlreadyReturned,
            formattedDate
          )

        // the loan time has already expired
        case .expired(_, let endDate):
          let formattedDate = localizedDateString(endDate)

          return String.localizedStringWithFormat(
            Strings.Error.bookLoanExpired,
            formattedDate
          )

        // the loan is cancelled before activation
        // for example user downloaded the book,
        // but never opened it for reading
        // and then returned it
        case .cancelled(let date):
          let formattedDate = localizedDateString(date)

          return String.localizedStringWithFormat(
            Strings.Error.bookLoanCancelled,
            formattedDate
          )

        // the access to the loan has been revoked
        // (by the service for example)
        case .revoked(let date, _):
          let formattedDate = localizedDateString(date)

          return String.localizedStringWithFormat(
            Strings.Error.bookAccessRevoked,
            formattedDate
          )
        }
      #else
        let errorDescription = error.localizedDescription
        return String(format: Strings.Error.openFailedError, errorDescription)
      #endif
    }
  }

}

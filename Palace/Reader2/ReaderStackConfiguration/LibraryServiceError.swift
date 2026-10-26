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

/// Errors that can occur while retrieving or opening a book publication.
///
/// This enum type helps to show more user-friendly application-level
/// error message in alerts,
/// instead of errors produced by Readium or the underlying DRM services.
enum LibraryServiceError: LocalizedError {

  /// The book is missing a valid URL
  /// or cannot be represented as a readable asset.
  case invalidBook

  /// Opening the book failed
  /// and the related error contains the underlying cause.
  case openFailed(Error)

  /// Returns the localized message shown
  /// when the error is presented to the user in an alert.
  var errorDescription: String? {
    switch self {

    case .invalidBook:
      return Strings.Error.invalidBookError

    case .openFailed(let error):
      let errorDescription = error.localizedDescription
      return String(format: Strings.Error.openFailedError, errorDescription)

    }
  }

}

//
//  LibraryService.swift
//  The Palace Project
//
//  Created by Mickaël Menu on 20.02.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit
import ReadiumShared
import ReadiumStreamer

/// The LibraryService makes a book ready for presentation without dealing
/// with the specifics of how a book should be presented.
///
/// It sets up the various components necessary for presenting a book,
/// such as the publication opener, DRM systems.  Presentation
/// itself is handled by the `ReaderModule`.
final class LibraryService: Loggable {

  let httpClient: HTTPClient
  let assetRetriever: AssetRetriever
  private let publicationOpener: PublicationOpener
  private var drmLibraryServices = [DRMLibraryService]()

  private lazy var documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

  init() {
    httpClient = DefaultHTTPClient()
    assetRetriever = AssetRetriever(httpClient: httpClient)

    #if LCP
    drmLibraryServices.append(LCPLibraryService())
    #endif

    #if FEATURE_DRM_CONNECTOR
    drmLibraryServices.append(AdobeDRMLibraryService())
    #endif

    let contentProtections = drmLibraryServices.compactMap { $0.contentProtection }

    publicationOpener = PublicationOpener(
      parser: DefaultPublicationParser(
        httpClient: httpClient,
        assetRetriever: assetRetriever,
        pdfFactory: DefaultPDFDocumentFactory()
      ),
      contentProtections: contentProtections
    )
  }


  // MARK: Opening

  /// Opens the Readium 2 Publication for the given `book`.
  func openBook(_ book: TPPBook,
                sender: UIViewController,
                completion: @escaping (Result<Publication, LibraryServiceError>) -> Void) {

    guard let bookUrl = book.url else {
      completion(.failure(.invalidBook))
      return
    }

    Task {
      await openAndPresent(url: bookUrl, bookIdentifier: book.identifier, allowUserInteraction: true, sender: sender, completion: completion)
    }
  }

  func openSample(_ book: TPPBook,
                  sampleURL: URL,
                sender: UIViewController,
                completion: @escaping (Result<Publication, LibraryServiceError>) -> Void) {
    Task {
      await openAndPresent(url: sampleURL, bookIdentifier: book.identifier, allowUserInteraction: true, sender: sender, completion: completion)
    }
  }

  private func openAndPresent(url: URL, bookIdentifier: String, allowUserInteraction: Bool, sender: UIViewController?, completion: @escaping (Result<Publication, LibraryServiceError>) -> Void) async {
    do {
      guard let fileUrl = FileURL(url: url) else {
        completion(.failure(.invalidBook))
        return
      }
      let asset = try await assetRetriever.retrieve(url: fileUrl).get()
      let publication = try await publicationOpener.open(asset: asset, allowUserInteraction: allowUserInteraction, sender: sender).get()

      guard !publication.isRestricted else {
        stopOpeningIndicator(identifier: bookIdentifier)
        if let error = publication.protectionError {
          completion(.failure(.openFailed(error)))
        } else {
          completion(.failure(.openFailed(NSError(domain: "LibraryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Publication is restricted"]))))
        }
        return
      }

      completion(.success(publication))
    } catch {
      stopOpeningIndicator(identifier: bookIdentifier)
      completion(.failure(.openFailed(error)))
    }
  }

  /// Stops activity indicator on the`Read` button.
  private func stopOpeningIndicator(identifier: String) {
    let userInfo: [String: Any] = [
      TPPNotificationKeys.bookProcessingBookIDKey: identifier,
      TPPNotificationKeys.bookProcessingValueKey: false
    ]
    NotificationCenter.default.post(name: NSNotification.TPPBookProcessingDidChange, object: nil, userInfo: userInfo)
  }

}

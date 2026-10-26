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
/// such as the publication opener, DRM systems.
/// Presentation itself is handled by the `ReaderModule`.
final class LibraryService: Loggable {

  /// Performs the network requests needed to retrieve publication assets.
  let httpClient: HTTPClient

  /// Retrieves the book asset that will be opened as a Readium publication.
  let assetRetriever: AssetRetriever

  /// Opens retrieved assets as Readium publications
  /// and applies configured DRM protections.
  private let publicationOpener: PublicationOpener

  /// DRM services enabled for the current build configuration.
  private var drmLibraryServices = [DRMLibraryService]()

  /// Keep strong references to the current asset and publication so
  /// the underlying container stays alive while the reader is open.
  var currentAsset: Asset?
  var currentPublication: Publication?

  private lazy var documentDirectory = try! FileManager.default.url(
    for: .documentDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
  )


  // MARK: Initializing

  /// Initializes the network, asset retrieval, DRM and publication-opening services.
  ///
  /// DRM content protections are registered conditionally based on the enabled build features.
  init() {

    // Create the shared network client
    // and use it to retrieve publication assets.
    httpClient = DefaultHTTPClient()
    assetRetriever = AssetRetriever(httpClient: httpClient)

    // Register the DRM services enabled for this build.
    // Note: only LCP is currently used with E-kirjasto (10/2026)
    #if LCP
      drmLibraryServices.append(LCPLibraryService())
    #endif

    #if FEATURE_DRM_CONNECTOR
      drmLibraryServices.append(AdobeDRMLibraryService())
    #endif

    // Extract the content protection handlers used by the publication opener.
    let contentProtections = drmLibraryServices.compactMap {
      $0.contentProtection
    }

    // Configure the publication opener with the parser and enabled protections.
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

  /// Opens the given book as a Readium 2 publication.
  ///
  /// The book URL is validated before the asynchronous opening process starts.
  /// The completion is called with either the opened publication or an opening error.
  /// - Parameters:
  ///   - book: The book to open.
  ///   - sender: The view controller that initiated the opening flow.
  ///   - completion: Called with the opened publication or an opening error.
  func openBook(
    _ book: TPPBook,
    sender: UIViewController,
    completion: @escaping (Result<Publication, LibraryServiceError>) -> Void
  ) {

    guard let bookUrl = book.url else {
      completion(.failure(.invalidBook))
      return
    }

    Task {
      await openAndPresent(
        url: bookUrl,
        bookIdentifier: book.identifier,
        allowUserInteraction: true,
        sender: sender,
        completion: completion
      )
    }

  }

  /// Opens a sample URL as a Readium publication for the given book.
  /// Note: samples are not currently used in E-kirjasto (10/2026)
  ///
  /// The sample uses the same asynchronous opening pipeline as a full book,
  /// but its URL is provided separately.
  /// - Parameters:
  ///   - book: The book associated with the sample.
  ///   - sampleURL: The URL of the sample asset to open.
  ///   - sender: The view controller that initiated the opening flow.
  ///   - completion: Called with the opened publication or an opening error.
  func openSample(
    _ book: TPPBook,
    sampleURL: URL,
    sender: UIViewController,
    completion: @escaping (Result<Publication, LibraryServiceError>) -> Void
  ) {

    Task {
      await openAndPresent(
        url: sampleURL,
        bookIdentifier: book.identifier,
        allowUserInteraction: true,
        sender: sender,
        completion: completion
      )
    }

  }

  /// Retrieves and opens a book asset as a Readium publication.
  ///
  /// The completion is always called on the main actor because callers may update UIKit.
  /// Restricted or invalid publications are returned as failures.
  /// - Parameters:
  ///   - url: The URL of the book asset to retrieve.
  ///   - bookIdentifier: The identifier used to stop the book-opening indicator.
  ///   - allowUserInteraction: Whether the publication opener may interact with the user.
  ///   - sender: The view controller that initiated the opening flow.
  ///   - completion: Called with the opened publication or an opening error.
  private func openAndPresent(
    url: URL,
    bookIdentifier: String,
    allowUserInteraction: Bool,
    sender: UIViewController?,
    completion: @escaping (Result<Publication, LibraryServiceError>) -> Void
  ) async {

    do {

      // Convert the external URL to Readium's file URL representation
      // before opening it.
      guard let fileUrl = FileURL(url: url) else {
        completion(.failure(.invalidBook))
        return
      }

      // Retain the asset for as long as the publication is in use,
      // its container must remain open.
      let asset = try await assetRetriever.retrieve(url: fileUrl).get()
      self.currentAsset = asset

      Log.debug(#file, "Asset retrieved: \(asset)")

      // Open the asset as a Readium publication.
      // This may perform asynchronous work
      // and may return an LCP or other publication-opening error.
      let publication = try await publicationOpener.open(
        asset: asset,
        allowUserInteraction: allowUserInteraction,
        sender: sender
      ).get()

      Log.debug(
        #file,
        "Publication opened: \(publication.metadata.title), baseURL: \(publication.baseURL?.string ?? "nil"), readingOrder: \(publication.readingOrder.count) items"
      )

      // Restricted publications cannot be presented to the reader.
      guard !publication.isRestricted else {
        stopOpeningIndicator(identifier: bookIdentifier)

        if let error = publication.protectionError {
          completion(.failure(.openFailed(error)))
        } else {
          completion(
            .failure(
              .openFailed(
                NSError(
                  domain: "LibraryService",
                  code: -1,
                  userInfo: [
                    NSLocalizedDescriptionKey: "Publication is restricted"
                  ]
                )
              )
            )
          )
        }

        return
      }

      self.currentPublication = publication
      await MainActor.run {
        completion(.success(publication))
      }
    } catch {
      stopOpeningIndicator(identifier: bookIdentifier)
      await MainActor.run {
        completion(.failure(.openFailed(error)))
      }
    }

  }
  
  // MARK: Helpers

  /// Stops the activity indicator displayed on the `Read button.
  ///
  /// Notifies interested UI components that opening has finished for the given book.
  /// - Parameter identifier: The identifier of the book whose indicator should stop.
  private func stopOpeningIndicator(identifier: String) {

    let userInfo: [String: Any] = [
      TPPNotificationKeys.bookProcessingBookIDKey: identifier,
      TPPNotificationKeys.bookProcessingValueKey: false,
    ]

    NotificationCenter.default.post(
      name: NSNotification.TPPBookProcessingDidChange,
      object: nil,
      userInfo: userInfo
    )

  }

}

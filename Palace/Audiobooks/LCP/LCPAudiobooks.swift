//
//  LCPAudiobooks.swift
//  The Palace Project
//
//  Created by Vladimir Fedorov on 16.11.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#if LCP

import Foundation
import ReadiumShared
import ReadiumStreamer
import ReadiumLCP
import PalaceAudiobookToolkit

/// LCP Audiobooks helper class
@objc class LCPAudiobooks: NSObject {

  private let audiobookUrlKey = "audiobookUrl"
  private let audioFileHrefKey = "audioFileHref"
  private let destinationFileUrlKey = "destinationFileUrl"
  private static let expectedAcquisitionType = "application/vnd.readium.lcp.license.v1.0+json"

  private let audiobookUrl: URL
  private let lcpService = LCPLibraryService()
  private let httpClient: HTTPClient
  private let assetRetriever: AssetRetriever
  private let publicationOpener: PublicationOpener

  /// Initialize for an LCP audiobook
  /// - Parameter audiobookUrl: must be a file with `.lcpa` extension
  @objc init?(for audiobookUrl: URL) {
    // Check contentProtection is in place
    guard let contentProtection = lcpService.contentProtection else {
      TPPErrorLogger.logError(nil, summary: "Uninitialized contentProtection in LCPAudiobooks")
      return nil
    }
    self.audiobookUrl = audiobookUrl
    self.httpClient = DefaultHTTPClient()
    self.assetRetriever = AssetRetriever(httpClient: httpClient)
    self.publicationOpener = PublicationOpener(
      parser: DefaultPublicationParser(
        httpClient: httpClient,
        assetRetriever: assetRetriever,
        pdfFactory: DefaultPDFDocumentFactory()
      ),
      contentProtections: [contentProtection]
    )
  }

  /// Content dictionary for `AudiobookFactory`
  /// The completion handler is always called on the main thread.
  @objc func contentDictionary(completion: @escaping (_ json: NSDictionary?, _ error: NSError?) -> ()) {
    Task {
      do {
        guard let url = FileURL(url: audiobookUrl) else {
          await Self.finish(completion, nil, NSError(domain: "LCPAudiobooks", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
          return
        }
        let asset = try await assetRetriever.retrieve(url: url, mediaType: .lcpProtectedAudiobook).get()
        let publication = try await publicationOpener.open(asset: asset, allowUserInteraction: false).get()
        // Readium 3.x publications only serve links listed in the manifest,
        // so manifest.json itself can no longer be fetched as a resource.
        // The opened publication carries the parsed manifest instead.
        if let manifestString = publication.jsonManifest,
           let manifestData = manifestString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: manifestData, options: []) as? NSDictionary {
          await Self.finish(completion, json, nil)
        } else {
          await Self.finish(completion, nil, NSError(domain: "LCPAudiobooks", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse manifest"]))
        }
      } catch {
        TPPErrorLogger.logError(error, summary: "Error opening LCP audiobook", metadata: [self.audiobookUrlKey: self.audiobookUrl])
        await Self.finish(completion, nil, LCPAudiobooks.nsError(for: error))
      }
    }
  }

  /// Delivers the completion on the main thread; callers feed UI flows.
  @MainActor
  private static func finish(_ completion: @escaping (NSDictionary?, NSError?) -> (), _ json: NSDictionary?, _ error: NSError?) {
    completion(json, error)
  }

  /// Check if the book is LCP audiobook
  /// - Parameter book: audiobook
  /// - Returns: `true` if the book is an LCP DRM protected audiobook, `false` otherwise
  @objc static func canOpenBook(_ book: TPPBook) -> Bool {
    guard let defualtAcquisition = book.defaultAcquisition else { return false }
    return book.defaultBookContentType == .audiobook && defualtAcquisition.type == expectedAcquisitionType
  }

  /// Creates an NSError for Objective-C code
  /// - Parameter error: Error object
  /// - Returns: NSError object
  private static func nsError(for error: Error) -> NSError {
    let description = error.localizedDescription
    return NSError(domain: "SimplyE.LCPAudiobooks", code: 0, userInfo: [
      NSLocalizedDescriptionKey: description,
      "Error": error
    ])
  }
}

/// DRM Decryptor for LCP audiobooks
extension LCPAudiobooks: DRMDecryptor {

  /// Decrypt protected file
  func decrypt(url: URL, to resultUrl: URL, completion: @escaping (Error?) -> Void) {
    Task {
      do {
        guard let assetUrl = FileURL(url: audiobookUrl) else {
          completion(NSError(domain: "LCPAudiobooks", code: -1))
          return
        }
        let asset = try await assetRetriever.retrieve(url: assetUrl, mediaType: .lcpProtectedAudiobook).get()
        let publication = try await publicationOpener.open(asset: asset, allowUserInteraction: false).get()
        let resourceLink = publication.linkWithHREF(AnyURL(string: "/" + url.path)!) ?? publication.linkWithHREF(AnyURL(string: url.path)!)
        if let resourceLink = resourceLink, let resource = publication.get(resourceLink) {
          let data = try await resource.read().get()
          try data.write(to: resultUrl)
          completion(nil)
        } else {
          completion(NSError(domain: "LCPAudiobooks", code: -1, userInfo: [NSLocalizedDescriptionKey: "Resource not found"]))
        }
      } catch {
        TPPErrorLogger.logError(error, summary: "Error decrypting LCP audio file", metadata: [
          self.audiobookUrlKey: self.audiobookUrl,
          self.audioFileHrefKey: url,
          self.destinationFileUrlKey: resultUrl
        ])
        completion(error)
      }
    }
  }
}

#endif

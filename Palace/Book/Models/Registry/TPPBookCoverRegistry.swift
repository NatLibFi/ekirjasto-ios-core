//
//  TPPBookCoverRegistry.swift
//  Palace
//
//  Created by Vladimir Fedorov on 26.10.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation

class TPPBookCoverRegistry {

  /// Returns a cached thumbnail, downloads one when needed, or uses a placeholder.
  /// - Parameters:
  ///   - book: The book whose thumbnail image should be loaded, TPPBook object
  ///   - handler: Called with the cached, downloaded, or placeholder image
  func thumbnailImageForBook(
    _ book: TPPBook,
    handler: @escaping (_ image: UIImage?) -> Void
  ) {

    guard
      let imagePath = pinnedThumbnailImageUrlOfBookIdentifier(book.identifier)?
        .path
    else {
      handler(self.getPlaceholderBookCoverImage())
      return
    }

    // a pinned book is saved in the user's local book registry.
    let isPinned =
      TPPBookRegistry.shared.book(forIdentifier: book.identifier) != nil

    if isPinned {

      if let image = UIImage(contentsOfFile: imagePath) {
        handler(image)
      } else if let thumbnailUrl = book.imageThumbnailURL,
        let fileUrl = self.pinnedThumbnailImageUrlOfBookIdentifier(
          book.identifier
        )
      {
        self.getBookCoverImage(
          url: thumbnailUrl,
          fileUrl: fileUrl,
          handler: handler
        )
      } else {
        handler(self.getPlaceholderBookCoverImage())
      }

    } else {

      if let thumbnailUrl = book.imageThumbnailURL {
        self.getBookCoverImage(
          url: thumbnailUrl,
          fileUrl: nil,
          handler: handler
        )
      } else {
        handler(self.getPlaceholderBookCoverImage())
      }

    }

  }

  /// Downloads cover image for the provided book.
  /// - Parameters:
  ///   - book: `TPPBook` object.
  ///   - handler: completion handler.
  func coverImageForBook(
    _ book: TPPBook,
    handler: @escaping (_ image: UIImage?) -> Void
  ) {

    thumbnailImageForBook(book, handler: handler)

    guard let imageUrl = book.imageURL else {
      return
    }

    urlSession.dataTask(with: URLRequest(url: imageUrl)) {
      imageData,
      response,
      error in
      if let imageData = imageData, let image = UIImage(data: imageData) {
        DispatchQueue.main.async {
          handler(image)
        }
      }
    }.resume()

  }

  /// Downloads thumbnail images for the provided set of books.
  /// Uses the placeholder image when a thumbnail is unavailable.
  /// - Parameters:
  ///   - books: The books whose thumbnail images should be loaded, a set of `TPPBook` objects
  ///   - handler: Called once with an image for each book, completion handler
  func thumbnailImagesForBooks(
    _ books: Set<TPPBook>,
    handler: @escaping (_ bookIdentifiersToImages: [String: UIImage]) -> Void
  ) {

    // Complete immediately if there are no books to load.
    guard !books.isEmpty else {
      handler([:])
      return
    }

    // Collect one image for each requested book.
    // Note: thread safety should be checked,
    // URLSession callbacks may update this dictionary concurrently
    var result: [String: UIImage] = [:] {
      didSet {
        // Notify the caller after all requested images are available.
        if _books.count == result.keys.count {
          DispatchQueue.main.async {
            handler(result)
          }
        }
      }
    }

    var _books: [TPPBook] = []

    // Keep only one book for each identifier.
    for b in books {
      if !_books.contains(where: { book in
        book.identifier == b.identifier
      }) {
        _books.append(b)
      }
    }

    // Load a thumbnail or use the placeholder when no URL is available.
    _books.forEach { book in

      guard let thumbnailUrl = book.imageThumbnailURL else {
        DispatchQueue.main.async {
          result[book.identifier] = self.getPlaceholderBookCoverImage()
        }

        return
      }

      // Download the thumbnail asynchronously.
      urlSession.dataTask(with: URLRequest(url: thumbnailUrl)) {
        imageData,
        response,
        error in
        if let imageData = imageData, let image = UIImage(data: imageData) {
          // Store the downloaded image.
          result[book.identifier] = image
        } else {
          // Use the placeholder when the download or image decoding fails.
          DispatchQueue.main.async {
            result[book.identifier] = self.getPlaceholderBookCoverImage()
          }

        }
      }.resume()

    }

  }

  /// Immediately returns the cached thumbnail if available, else nil. Generated images are not returned.
  /// - Parameter book: book
  /// - Returns: cover image, if one is available.
  func cachedThumbnailImageForBook(_ book: TPPBook) -> UIImage? {

    guard let thumbnailUrl = book.imageThumbnailURL,
      let cachedData = urlSession.configuration.urlCache?.cachedResponse(
        for: URLRequest(url: thumbnailUrl)
      )?.data
    else {
      return nil
    }

    return UIImage(data: cachedData)
  }

  /// Saves cover image of the book.
  /// - Parameter book: `TPPBook` object.
  func pinThumbnailImageForBook(_ book: TPPBook) {

    guard let thumbnailUrl = book.imageThumbnailURL,
      let fileUrl = pinnedThumbnailImageUrlOfBookIdentifier(book.identifier)
    else {
      return
    }

    try? Data().write(to: fileUrl, options: .atomic)

    urlSession.dataTask(with: URLRequest(url: thumbnailUrl)) {
      imageData,
      response,
      error in
      if let imageData = imageData {
        do {
          try imageData.write(to: fileUrl, options: .atomic)
        } catch {
          Log.error(
            #file,
            "Error saving thumbnail file: \(error.localizedDescription)"
          )
        }
      }
    }.resume()

  }

  /// Deletes cover image of a book with `bookIdentifier`.
  /// - Parameter bookIdentifier: book identifier.
  func removePinnedThumbnailImageForBookIdentifier(_ bookIdentifier: String) {

    guard let fileUrl = pinnedThumbnailImageUrlOfBookIdentifier(bookIdentifier)
    else {
      return
    }

    do {
      try FileManager.default.removeItem(at: fileUrl)
    } catch {
      Log.error(
        #file,
        "Error removeing thumbnail file: \(error.localizedDescription)"
      )
    }

  }

  /// Deletes book cover directory
  func removeAllPinnedThumbnailImages() {

    do {
      if let url = pinnedThumbnailImageDirectoryURL {
        try FileManager.default.removeItem(at: url)
      }
    } catch {
      Log.error(
        #file,
        "Error removing thumbnail directory: \(error.localizedDescription)"
      )
    }

  }

  private lazy var urlSession: URLSession = {
    let diskCacheInMegabytes = 16
    let memoryCacheInMegabytes = 2

    let configuration = URLSessionConfiguration.default
    configuration.httpCookieStorage = nil
    configuration.httpMaximumConnectionsPerHost = 8
    configuration.httpShouldUsePipelining = true
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 30
    configuration.urlCache?.diskCapacity = 1024 * 1024 * diskCacheInMegabytes
    configuration.urlCache?.memoryCapacity = 1024 * 1024 * memoryCacheInMegabytes
    configuration.urlCredentialStorage = nil

    return URLSession(configuration: configuration)
  }()

  /// Returns the directory for locally saved thumbnail images.
  /// Creates the directory when it does not exist.
  /// This property performs file system I/O and may return nil.
  private var pinnedThumbnailImageDirectoryURL: URL? {

    // resolve the directory for the currently active user account.
    guard let accountsDirectoryUrl =
        TPPBookContentMetadataFilesHelper.currentAccountDirectory()
    else {
      Log.error(#file, "currentAccountDirectory is nil")
      return nil
    }

    do {
      // store thumbnails in the current user's local on-device account data,
      // the folder name is "pinned-thumbnail-images"
      let pinnedThumbnailsFolderUrl =
        accountsDirectoryUrl.appendingPathComponent("pinned-thumbnail-images")

      // create the thumbnail directory on first use
      if !FileManager.default.fileExists(atPath: pinnedThumbnailsFolderUrl.path)
      {
        try FileManager.default.createDirectory(
          at: pinnedThumbnailsFolderUrl,
          withIntermediateDirectories: true
        )
      }

      return pinnedThumbnailsFolderUrl
    } catch {
      Log.error(
        #file,
        "Failed to create pinned thumbnail images folder: \(error.localizedDescription)"
      )
    }

    return nil
  }

  /// URL for pinned thumbnail image
  /// - Parameter bookIdentifier: book identifier
  /// - Returns: cover image file URL
  private func pinnedThumbnailImageUrlOfBookIdentifier(_ bookIdentifier: String) -> URL?
  {

    pinnedThumbnailImageDirectoryURL?.appendingPathComponent(
      bookIdentifier.sha256()
    )

  }

  /// Downloads book cover image.
  /// - Parameters:
  ///   - url: URL for the books cover image
  ///   - fileUrl: file URL for storing the cover image.
  ///   - handler: completion handler.
  private func getBookCoverImage(
    url: URL,
    fileUrl: URL?,
    handler: @escaping (_ image: UIImage?) -> Void
  ) {

    urlSession.dataTask(with: URLRequest(url: url)) {
      imageData,
      response,
      error in
      if let imageData = imageData, let image = UIImage(data: imageData) {
        DispatchQueue.main.async {
          handler(image)

          if let fileUrl = fileUrl {
            do {
              try imageData.write(to: fileUrl, options: .atomic)
            } catch {
              // log error
            }
          }

        }
      } else {
        DispatchQueue.main.async {
          handler(self.getPlaceholderBookCoverImage())
        }
      }
    }.resume()

  }

  /// Returns the placeholder image used when a book has no available cover.
  private func getPlaceholderBookCoverImage() -> UIImage? {
    ImageProviders.MyBooksView.bookPlaceholder
  }
}
